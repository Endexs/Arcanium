# Concurrency — Antipatterns (via negativa)

Read this before writing or reviewing any code with a database write lock, an `async` route, or
a state transition reachable from more than one trigger. This domain consolidates a pattern that
recurred across `payment/` and `db/` in three *separate* incidents — it earns a dedicated domain
rather than staying scattered because the same root shape (a synchronous/blocking operation
executed where concurrent work is expected to proceed) keeps causing the highest-severity,
hardest-to-see bugs in this ecosystem.

---

### 1. A DB write lock held across an outbound network call
**Evidence: fixed after a real incident.**
Any code that opens an eager write-lock transaction (SQLite `BEGIN IMMEDIATE`, `SELECT ... FOR
UPDATE`) and then makes a slow outbound call before committing serializes every other writer for
the duration of that call, under real latency a mocked-network test never reproduces.
**Source:** airbnb-website Phase 6A, Major finding M1 — a Stripe Checkout call made from inside
an open write-lock transaction.

### 2. A blocking network call inside an `async def` route
**Evidence: fixed after a real incident — twice, in two unrelated subsystems.**
FastAPI/Starlette runs `async def` route bodies directly on the event loop, not in a threadpool.
A synchronous, blocking call inside one (raw `urllib`, a synchronous SDK client) freezes the
*entire* event loop for its duration — every other concurrent request (unrelated routes
included) stalls, not just the one making the call.
**Source:** airbnb-website Phase 6B M1 (`urllib.urlopen` inside an `async def` calendar-sync
route) and Phase 7 (a synchronous LLM gateway call inside `async def chat`) — the same bug class,
independently reintroduced in a completely different subsystem four weeks later, by the same
project. Awareness of the first incident did not prevent the second.

### 3. No single-writer guard on a state transition reachable from more than one trigger
**Evidence: fixed after a real incident.**
A handler that re-reads current state, decides an outcome, then writes — without an idempotency
key on any external call AND a compare-and-swap on the local row — lets two concurrent triggers
(a webhook + a redirect, a double-click, two admin tabs) both read the same stale state and
diverge. A bare re-read is not a guard against a second writer landing after your read.
**Source:** airbnb-website Phase 6D M1 — two concurrent cancellations raced; an external refund
executed while the local ledger committed a different (wrong) outcome.

### 4. A concurrency "regression test" that is structurally incapable of failing
**Evidence: fixed after a real incident.**
A test that looks like a legitimate concurrency probe (a background thread hits a slow path,
the main thread times an unrelated path) can still prove nothing if the test harness gives each
concurrent call its own isolated resource (a fresh event loop, a separate connection) instead of
sharing the one the real bug depends on. The test passes identically whether the underlying fix
is present or not — plausible shape, zero evidence.
**Source:** airbnb-website Phase 7 — a concurrency probe for the event-loop-freeze bug (#2, second
occurrence) passed both before and after the fix, because it used a `TestClient` instance that
was never entered as a context manager, so each call got a fresh, non-shared event loop.
