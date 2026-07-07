# Payment — Antipatterns (via negativa)

Read this before writing or reviewing ANY payment/refund/checkout code. Every entry is sourced —
either a real incident that shipped and was fixed, or an explicit non-negotiable invariant a
project committed to *before* an incident, with its own stated rationale. Entries are tagged
with which kind of evidence they are; neither kind is invented for this file.

---

### 1. A DB write lock held across the outbound gateway call
**Evidence: fixed after a real incident.**
`create_checkout_session` / `retrieve_session` (Stripe) called from inside an open `BEGIN
IMMEDIATE`-style write-lock transaction serializes every other writer for the multi-second
duration of the network round-trip. Under a concurrent webhook + success-redirect (the normal
shape of a Stripe Checkout flow — both fire near-simultaneously), the second caller hits lock
contention or an outright `OperationalError`.
**Source:** airbnb-website Phase 6A, Major finding M1 (`journal/retrospective.md`).
**Why it's easy to miss:** a single-threaded, mocked-network test suite cannot see this —
lock contention only manifests under real concurrency and real latency.

### 2. No single-writer guard on a state transition reachable from more than one trigger
**Evidence: fixed after a real incident.**
A cancellation flow that re-reads current state, decides an outcome, then writes — without an
idempotency key on the external call AND a compare-and-swap on the local row — lets two
concurrent triggers (a webhook + a redirect, a double-click, two admin tabs) both read the same
stale state and diverge. In the real incident: two concurrent cancels (one host-initiated =
full refund, one guest-initiated inside the no-refund cutoff = zero refund) raced. Stripe
refunded money on one call; the local ledger committed `refund_amount=0` from the other,
because a bare re-read is not a guard against a second writer landing after your read.
**Source:** airbnb-website Phase 6D, Major finding M1.
**Fix requires both halves:** an idempotency key (the *external* side effect happens once, even
on retry) AND a compare-and-swap / claim on local state (`UPDATE ... WHERE status = 'confirmed'`,
proceed only if exactly one row updated). Either alone is insufficient.

### 3. Trusting the SDK response object's shape without checking the installed version
**Evidence: fixed after a real incident.**
Code that calls `.get(field)` on a payment SDK's response object assumes it behaves like a
dict. Modern `stripe-python` (v15.x) returns a `StripeObject` that is **not** a dict subclass —
`.get(...)` raises `AttributeError`. This shipped clean because the test suite's fake gateway
only ever returned plain dicts, so the incompatibility was invisible until a real Stripe call
happened in production.
**Source:** airbnb-website go-live fixes (`212c9f1` — "StripeGateway.retrieve_session crashed on
real Stripe objects (SDK 15.x)").
**Fix:** use `getattr(obj, "field", None)`, never `.get(...)`, on any object that might be a real
SDK response — and test at least once against the real SDK's actual response type, not only a
hand-rolled dict fake.

### 4. A non-functional simulated/fake gateway silently serving real traffic
**Evidence: designed against as an explicit non-negotiable, before an incident occurred.**
A missing gateway credential (e.g. `STRIPE_SECRET_KEY` unset) that silently falls back to a
fake/simulated gateway *looks* like it works — checkout sessions are created, redirects happen,
confirmations render — but no money ever moves and no guest is actually charged. This is a
worse failure mode than an outright crash, because nothing external signals the problem.
**Source:** airbnb-website non-negotiable + PR "Fail-closed payment gateway in production
(APP_ENV=production)."
**Fix:** gate on an explicit environment signal (e.g. `APP_ENV=production`) and `raise
RuntimeError` rather than silently degrading to the fake gateway in a real deployment; in
non-production modes, still log loudly (at least once per process) so a forgotten key doesn't
go unnoticed in staging either.

### 5. Payment fields (card number, CVV, expiry) persisted or logged, even transiently
**Evidence: designed against as an explicit non-negotiable, before an incident occurred.**
Any code path that could serialize raw payment input to logs, error messages, or storage —
including a debug/traceback mode that renders local variables on an unhandled exception — is a
card-data leak vector, regardless of whether the data is "just passing through."
**Source:** airbnb-website spec §6 non-negotiable ("Never log payment details").
**Fix:** accept payment fields transiently, discard immediately after handing off to the
gateway; guard the discard with `raise RuntimeError` on any path that would serialize them;
keep debug/traceback rendering permanently off in any code that ever touches payment input,
even in the simulated/pre-real-payments phase of a project.

### 6. Refund/charge amount computed ad hoc at each call site instead of one pure function
**Evidence: designed against, generalizing from real incident #2 above.**
When "what should this refund be" is computed independently in the handler that moves money and
in any UI that previews the amount beforehand, the two can drift — especially under a policy
with more than one branch (e.g. host-initiated vs. guest-initiated, or a time-based cutoff).
**Source:** airbnb-website `policy.refund_cents` — one function, called by both the actual
cancel/refund handler and the admin-preview display, so what the host sees before confirming is
guaranteed to match what actually happens. An unrecognized input state raises rather than
silently defaulting to an amount.
