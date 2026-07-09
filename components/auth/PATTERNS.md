# Auth — Patterns

Each pattern responds to a cited antipattern in `ANTIPATTERNS.md` — read that first.

---

### 1. Fail-closed credential verification, checked before any comparison happens
**Responds to:** #1 (auth that succeeds when misconfigured).

```python
def verify_password(candidate: str) -> bool:
    admin_pw = os.environ.get("ADMIN_PASSWORD")   # read at call time, not import time —
                                                    # so tests can monkeypatch it per-case
    if not admin_pw:
        raise RuntimeError("ADMIN_PASSWORD not configured")   # hard stop, not a comparison
    return secrets.compare_digest(candidate, admin_pw)
```
The caller (the login route) catches `RuntimeError`, logs it server-side, and returns the same
generic "incorrect password" response a real wrong-password attempt would get — the failure
mode is invisible to the person trying to log in, loud to whoever reads the logs.

### 2. Constant-time compare everywhere a secret is checked, guarded by an input-shape check first
**Responds to:** #2 and #3 together.

```python
# Guard the shape BEFORE the constant-time compare, so malformed input degrades to the
# same clean "no" as a well-formed wrong answer, not a 500.
if not expected or not token.isascii() or not secrets.compare_digest(token, expected):
    raise HTTPException(status_code=404, detail="Not found")
```
Note the **404**, not 401/403, for a public-but-token-gated endpoint (e.g. a calendar export
feed fetched by a third party without a session) — the point is that "wrong token" and
"resource doesn't exist" must be indistinguishable to anyone probing the URL.

### 3. A session-signing key that degrades loudly instead of failing hard
**Responds to:** #4.

```python
secret_key = os.environ.get("ADMIN_SECRET_KEY")
if not secret_key:
    secret_key = secrets.token_hex(32)
    logger.warning(
        "ADMIN_SECRET_KEY not set — using an ephemeral key; admin sessions reset on restart."
    )
```
Deliberately the *other* failure mode from pattern #1 — this is a convenience/continuity risk,
not a "strangers reading other users' data" risk, so it logs and continues rather than refusing
to start. Decide this per-secret in your own system; don't copy the fail-closed or the
fail-loud-but-open choice reflexively onto every secret without asking what's actually at stake
behind it.

### 4. A private page keyed by an unguessable capability token, not its primary key
**Responds to:** #5 (IDOR via sequential id on a page that renders private data).

```python
# The token is an intrinsic property of the row — a Python-side default so EVERY insert
# path (ORM, service, test) gets one, never left to the caller to remember.
confirmation_token: Mapped[str | None] = mapped_column(
    String(64), default=lambda: secrets.token_urlsafe(32), nullable=True
)

@app.get("/confirmation/{token}")            # {token}, never {booking_id}
async def confirmation(token: str, ...):
    booking = None
    if token:                                # reject a falsy token BEFORE querying, so a
        booking = session.scalars(           # legacy NULL column can never be matched
            select(Booking).where(Booking.confirmation_token == token)
        ).first()
    if not booking or booking.status != "confirmed":
        raise HTTPException(status_code=404)  # same 404 for wrong-token and missing → no oracle
```
The additive migration that introduces the column must **backfill existing rows** with their own
tokens and add a unique index — otherwise legacy rows are orphaned from their own URL. Add
`Referrer-Policy: no-referrer` on the page and redact the token from access logs: a capability in
the URL is a secret. The sequential id stays fine on the *session-gated* admin view.

### 5. Derive cookie hardening from the environment signal, not a per-deploy opt-in flag
**Responds to:** #6 (opt-in `Secure` flag that defaults off).

```python
app_env = os.environ.get("APP_ENV", "").strip().lower()
https_only = (
    app_env == "production"                                      # prod is Secure by construction
    or os.environ.get("ADMIN_HTTPS_ONLY", "").strip().lower() in ("1", "true", "yes")
)
app.add_middleware(SessionMiddleware, ..., same_site="lax", https_only=https_only)
```
A forgotten flag can no longer downgrade production; local http dev (no `APP_ENV=production`)
still works; a TLS staging box can opt in explicitly. The insecure state is the one you have to
ask for, not the one you get by omission.

### 6. Per-session synchronizer CSRF token on every state-changing request
**Responds to:** #7 (`SameSite=lax` mistaken for CSRF protection).

```python
def get_csrf_token(request):                        # mint once per session, stable
    tok = request.session.get("csrf_token")
    if not tok:
        tok = secrets.token_urlsafe(32)
        request.session["csrf_token"] = tok
    return tok

def require_csrf(request, csrf_token: str = Form("")):
    expected = request.session.get("csrf_token")
    if not expected or not secrets.compare_digest(csrf_token, expected):  # fail closed
        raise HTTPException(status_code=403, detail="CSRF token missing or invalid")
```
Wire `require_csrf` **after** the auth dependency on every mutating route (auth first → an
unauthenticated request redirects to login, never leaks a 403). Inject the token into every form
via a template context processor so you can't forget one; `session.clear()` on login to rotate.
Not needed on the login POST (no session yet) or read-only routes. Note `not expected` short-
circuits *before* `compare_digest`, so a never-minted session token fails cleanly rather than
raising on `compare_digest(x, None)`.
