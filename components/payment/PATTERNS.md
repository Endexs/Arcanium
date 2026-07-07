# Payment — Patterns

Each pattern here exists **in direct response to** one or more antipatterns in
`ANTIPATTERNS.md` — read that file first. The citation under each pattern is what makes it
trustworthy, not its familiarity.

---

### 1. Gateway behind an ABC + dependency-injected real/fake split
**Responds to:** #4 (fake gateway silently serving prod traffic).

```python
class PaymentGateway(ABC):
    @abstractmethod
    def create_checkout_session(self, *, amount, currency, product_name,
                                 success_url, cancel_url, metadata) -> CheckoutSession: ...
    @abstractmethod
    def retrieve_session(self, session_id: str) -> SessionStatus: ...
    @abstractmethod
    def construct_event(self, payload: bytes, sig_header: str) -> dict: ...
    @abstractmethod
    def refund(self, *, payment_intent: str, amount: int, idempotency_key: str) -> RefundResult: ...

class StripeGateway(PaymentGateway): ...   # real, thin wrapper over the SDK
class FakeGateway(PaymentGateway): ...     # in-memory, deterministic, no network — for tests

def get_gateway() -> PaymentGateway:
    key = os.environ.get("STRIPE_SECRET_KEY")
    if key:
        return StripeGateway(key, ...)
    if _is_production():
        raise RuntimeError("STRIPE_SECRET_KEY not set but APP_ENV=production — refusing "
                            "to serve the non-functional FakeGateway.")
    logger.warning("STRIPE_SECRET_KEY not set — using the non-functional FakeGateway.")
    return FakeGateway()

def get_payment_gateway() -> PaymentGateway:
    """FastAPI dependency — shared by every router so tests need one dependency_overrides entry."""
    return get_gateway()
```

**Why this shape specifically:** one factory function, reused across every router that needs
the gateway, means one `dependency_overrides` entry in tests covers the whole app. The fail-
closed check lives in exactly one place. `FakeGateway` can simulate idempotent-refund behavior
(`refunds: dict[idempotency_key, RefundResult]`) so pattern #3 below is testable without a
real Stripe account.

**Source:** `airbnb-website/src/airbnb_website/payment_gateway.py`. Proven to generalize beyond
payment specifically — the same project later mirrored this exact shape (`ChatbotGateway` ABC +
`FakeChatbotGateway` + `get_chatbot_gateway()`) for a completely different external dependency
(an LLM API), with no changes to the underlying pattern.

### 2. Release the write lock before the network call
**Responds to:** #1 (lock held across the gateway round-trip).

```python
booking = create_pending_booking(session, ...)   # writes, still holding the lock
amount, booking_id = booking.total_price, booking.id
session.commit()                                  # release the write lock — BEFORE the network call
checkout = gateway.create_checkout_session(amount=amount, ...)   # now safe to be slow
booking.stripe_session_id = checkout.id
session.commit()
```

Never call out to a payment gateway from inside an open write-lock scope. Gather every field
the call needs, commit, call out, then re-open a transaction to record the result.

### 3. Idempotency key derived from a stable local identifier, paired with a compare-and-swap
**Responds to:** #2 (concurrent triggers racing a state transition).

```python
# 1. Claim the transition — only one caller can win this
result = session.execute(
    update(Booking).where(Booking.id == booking_id, Booking.status == "confirmed")
    .values(status="cancelled")
)
if result.rowcount != 1:
    raise CancelError("not_confirmed")   # someone else already acted, or it wasn't confirmed

# 2. THEN make the external call, keyed so a retry can't double-execute it
refund = gateway.refund(
    payment_intent=booking.stripe_payment_intent,
    amount=refund_cents(...),
    idempotency_key=f"cancel-{booking_id}",   # stable, not random-per-attempt
)
```

The idempotency key alone makes the *Stripe-side* call safe to retry. It does **not** stop two
concurrent local callers from both deciding to act — that needs the compare-and-swap. Ship both,
and ship at least one test that fires the transition twice concurrently and asserts exactly one
refund and one ledger row result.

### 4. One pure function owns the money-amount computation
**Responds to:** #6 (amount computed independently in two places).

```python
def refund_cents(total_price: int, check_in: date, today: date, initiator: str) -> int:
    if initiator == "host":
        return total_price
    if initiator == "guest":
        return total_price if (check_in - today).days >= FREE_CANCELLATION_CUTOFF_DAYS else 0
    raise RuntimeError(f"unknown cancellation initiator {initiator!r}")  # never default silently
```
Call this from BOTH the handler that actually moves money and any UI/preview that shows the
amount beforehand. One function, one source of truth, un-recognized inputs raise rather than
guessing.

### 5. `getattr(obj, name, default)`, never `.get(...)`, on SDK response objects
**Responds to:** #3 (SDK object shape assumption).

```python
pi = getattr(session_obj, "payment_intent", None)
if pi is not None and not isinstance(pi, str):
    pi = getattr(pi, "id", None)   # an expanded object, not a bare id string
```
If a test suite's fake gateway only ever returns plain dicts, this exact bug is invisible to it —
test at least once against the real SDK's actual response shape before trusting the suite.
