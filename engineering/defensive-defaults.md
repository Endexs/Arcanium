# Skill: Defensive Defaults

## Rule
The implementer applies these patterns reflexively, without being asked. The reviewer flags any code that violates them. The user does not have to remember these — they are the safety net for the decisions a solo dev without deep experience can't make.

## Why this exists
Solo devs without years of production experience don't know all the ways code can fail. These defaults catch the common ones. They're boring, but missing one of them is how products lose user data or get breached.

## The defaults

### 1. Input validation at *every* boundary it crosses — not just intake
All input from outside the system (CLI args, HTTP requests, file contents, external API
responses) is validated at the boundary. Internal function calls can trust their callers.
**But "the boundary" is not only the point of entry** — untrusted data keeps crossing trust
boundaries after intake, and each is its own edge to re-check:
- **Redirect hops:** validating a URL's scheme/host at registration is useless if the client
  then follows a `30x` to an unvalidated target. Re-validate every hop (scheme **and** reject
  private/loopback/link-local IPs) — else it's blind SSRF (`302 → http://169.254.169.254/…`).
- **Export sinks:** guest-controlled text written into a CSV/spreadsheet cell is code —
  prefix a leading `= + - @ \t \r` with `'` (CSV formula injection, CWE-1236).
- **Error branches:** a "never raises" / "isolated failure" contract must actually catch the
  full exception family it claims (DB `SQLAlchemyError`, stdlib `http.client`/`socket`), or one
  bad item 500s the caller and aborts the rest.

**Source**: airbnb-website Phase 6B/6C reviews (SSRF via redirect; CSV injection; a feed-sync
`except` narrower than its "never raises" docstring). All three were test-green at intake.

### 2. Parameterized database queries
Never construct SQL by string concatenation. Use parameterized queries always: `execute("SELECT ... WHERE x = ?", (value,))`. This applies to every database, every ORM, every query type.

### 3. Secrets from environment variables only
API keys, database passwords, signing keys, OAuth tokens — all from environment variables. Never in source files. Never in config files committed to git. Use `.env` for local dev (and add `.env` to `.gitignore`).

### 4. Timeouts on all external calls
Every HTTP request, every external API call, every database connection has an explicit timeout. Default: 30s for HTTP, 5s for DB. Never `httpx.get(url)` without `timeout=`. Never `requests.post(url)` without `timeout=`.

### 5. Retry once on transient errors
Network errors, 5xx responses, rate limits: retry once with a 3s backoff, then fail. Don't build complex retry-with-exponential-backoff unless the user feedback demands it.

### 6. Structured logging with context
Every error log includes enough context to debug from the log alone: the operation, the inputs (sanitized of secrets), the error message, the stack trace. Plain `print("error")` is not a log.

### 7. Transactions around multi-step writes
Any database operation that writes more than one row, or writes to more than one table, is wrapped in a transaction with explicit `BEGIN` and `commit()` / `rollback()`. Half-completed writes are bugs.

### 8. Progress reporting on long operations
Any operation that takes >2 seconds reports progress to the user. Bulk imports, file processing, model API streams — print something so the user knows it's not hung.

### 9. Idempotent operations where possible
Operations that could be retried (especially after a network failure) are idempotent. Use natural keys, `INSERT OR REPLACE`, or check-then-set patterns. "Did this succeed?" should always have a clear answer.

### 10. Fail loud, fail early
When an unexpected state is detected, raise an exception with a clear message. Don't silently continue. Don't return `None` and hope the caller checks. The best error message is one that names exactly what went wrong.

### 11. Post-commit side effects must not poison the request transaction
A best-effort side effect that runs **after** the main commit (sending an email, writing an
audit/notification row, firing a webhook) must not be able to break the request it rides on.
On failure it must `rollback()` the shared session (or run on a *separate* session), swallow
the error, and log it — and must not touch a lazily-loaded attribute before the rollback, or
the failed lazy-load re-raises inside the handler. "Best-effort" applies to the session
hygiene, not just the send.

```python
# after the booking is committed:
try:
    notifier.notify_host(session, booking)   # its own DB write may fail
except Exception:
    session.rollback()                        # else next `booking.id` access → PendingRollbackError → 500
    logger.exception("notify failed for booking id=%s", booking_id)  # booking_id captured pre-failure
```

**Source**: airbnb-website Phase 4 adversarial review. A failed `NotificationLog` commit left
the request session in `PendingRollbackError`; the next `booking.id` access would have 500'd
an already-paid, already-confirmed booking. Tests that only failed at the *send* layer missed
it — the session was never dirtied. Force a DB-layer failure to exercise this path.

### 12. Concurrency rules for any money / availability / shared-state handler
Two failures recurred across three Phase-6 slices, all test-green (the suite is single-threaded
and mocks the network, so neither is visible to it). Apply both reflexively:

**(a) Never hold a DB write lock across a network call.** Gather the fields you need, `commit()`
/ release the lock, *then* make the outbound call (payment processor, feed fetch, webhook).
Holding e.g. SQLite's `BEGIN IMMEDIATE` across a multi-second Stripe round-trip serializes every
other writer and 500s them under contention. Corollary: a blocking network call inside an
`async def` route freezes the whole event loop — make such routes a plain `def` so the framework
threadpools them.

**(b) A state mutation reachable from more than one trigger needs an idempotency key AND a
single-writer guard.** "More than one trigger" = webhook + success-redirect, a double-click, two
admin tabs, a ret/retry. A bare re-read is not enough: two callers can both read the old state,
diverge on the decision, and the loser can overwrite the winner. Use an idempotency key on the
external side (so money/effects happen once) **and** a compare-and-swap / set-once claim on the
DB side (`UPDATE … WHERE status='confirmed'`, act only if `rowcount==1`) so exactly one caller
records the outcome and sends the notices.

```python
# release the lock BEFORE the network call
booking = load(...); amount = booking.total; session.commit()   # (a)
res = gateway.refund(pi, amount, idempotency_key=f"refund-{booking.id}")   # (b) money once
finalized = session.execute(                                     # (b) single writer
    update(Booking).where(Booking.id==id, Booking.status=="confirmed")
    .values(status="cancelled", refund_amount=amount)).rowcount
if finalized: write_ledger_row(); notify()
```

**Source**: airbnb-website Phase 6A M1 (Stripe call inside the write lock), 6B M1 (blocking
`urlopen` in `async def` froze the loop), 6D M1 (no CAS on the cancel initiator → concurrent
cancels refunded money while the ledger committed `refund_amount=0`). Test with a lock-probe (a
second connection grabs the lock during the network call) and a concurrent-mutation case.

## How to apply

In the implementer system prompt, include:

> Apply all rules from `defensive-defaults.md` reflexively. The user does not need to ask. If a rule conflicts with the plan, flag it as a gap. If a rule cannot be applied (e.g., the framework handles it), note that in the agent journal.

In the reviewer system prompt, include:

> Check every change against `defensive-defaults.md`. Missing defaults are at least Major severity. SQL string concatenation, missing timeouts, plaintext secrets, and missing input validation are Critical.

## What this prevents
- SQL injection
- Credential leaks via committed config files
- Hung processes waiting on dead network calls
- Half-written database state after a crash
- Silent failures that surface as data corruption weeks later
- Logs that say "error" with no way to diagnose
