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
