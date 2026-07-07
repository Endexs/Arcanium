# Concurrency — Patterns

Each pattern responds to a cited antipattern in `ANTIPATTERNS.md` — read that first.

---

### 1. Commit before any outbound call, full stop
**Responds to:** #1.

```python
booking = create_pending_booking(session, ...)   # writes, still holding the lock
amount, booking_id = booking.total_price, booking.id
session.commit()                                  # release the lock — BEFORE the network call
checkout = gateway.create_checkout_session(amount=amount, ...)   # now safe to be slow
```
Gather every field the outbound call needs, commit (releasing any eager write lock), make the
call, then re-open a transaction to record the result. This is a general data-layer rule, not
specific to any one call site — see `payment/PATTERNS.md` #2 and `db/PATTERNS.md` #3 for the
same shape applied there.

### 2. Two valid fix shapes for a blocking call inside an async route — pick based on what else the route needs from the event loop
**Responds to:** #2.

**Shape A — make the route a plain `def`.** FastAPI runs synchronous route handlers in a
threadpool automatically; the blocking call no longer touches the event loop at all.
```python
@router.post("/calendar/sync")
def sync_calendars(request: Request, session: Session = Depends(get_session), ...):
    # blocking urllib calls inside here are safe — this whole function runs in a threadpool
    ical_service.sync_all(session, listing.id)
```
Use this when nothing in the route needs to stay on the event loop.

**Shape B — keep `async def`, explicitly offload the blocking part.** Use this when part of the
route (e.g. a fast synchronous check that must run before the slow part, like a rate limiter)
needs to stay on the event loop while the actual blocking work does not.
```python
@router.post("/chat")
async def chat(request: Request, ...):
    if not rate_limit_ok(request):          # fast, synchronous, fine directly on the loop
        return JSONResponse(status_code=429, ...)
    result = await run_in_threadpool(       # offload ONLY the blocking part
        chatbot_service.answer, session, listing, message, gateway
    )
    return JSONResponse(content=result)
```
Both are real, sourced fixes for the same bug class in two different routes in the same project —
the second incident needed shape B specifically because shape A would have moved the rate-limit
check off the event loop too, defeating its purpose.

### 3. Idempotency key + compare-and-swap, together
**Responds to:** #3.

```python
result = session.execute(
    update(Booking).where(Booking.id == booking_id, Booking.status == "confirmed")
    .values(status="cancelled")
)
if result.rowcount != 1:
    raise CancelError("not_confirmed")   # someone else already acted, or it wasn't confirmed

refund = gateway.refund(payment_intent=..., amount=..., idempotency_key=f"cancel-{booking_id}")
```
The idempotency key makes the *external* call safe to retry; it does not stop two local callers
from both deciding to act — that needs the compare-and-swap. Ship both. See `payment/PATTERNS.md`
#3 for the fully-worked example.

### 4. A real concurrency probe: shared resource, and proven to fail first
**Responds to:** #4.

```python
# Use `with TestClient(app) as client:` — an ENTERED context manager — so concurrent calls
# through it share ONE event loop. A bare `TestClient(app)` gives each call its own.
with TestClient(app) as client:
    t = threading.Thread(target=lambda: client.post("/slow-route", ...))
    t.start()
    time.sleep(0.1)                    # let the slow route start and enter its blocking work
    start = time.monotonic()
    client.get("/unrelated-route")     # must NOT be delayed by the slow route above
    assert time.monotonic() - start < 0.4
    t.join()
```
Before trusting a green result from any concurrency/regression probe, temporarily revert the fix
under test and confirm the probe goes red. A probe that passes identically with and without the
fix has proven nothing.
