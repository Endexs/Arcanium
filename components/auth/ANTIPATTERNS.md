# Auth — Antipatterns (via negativa)

Read this before writing or reviewing any login, session, or credential-comparison code.

---

### 1. A credential check that authenticates anyway when the expected secret is missing
**Evidence: designed against as an explicit non-negotiable, before an incident occurred.**
If the "correct" password/secret comes from configuration (an env var, a settings row) and that
configuration is unset or empty, a naive comparison can accidentally succeed — an empty
candidate against an empty expected value, or a falsy-check bug that skips verification
entirely when there's "nothing to compare against."
**Source:** airbnb-website spec §6 non-negotiable ("Admin auth fails closed") — login must
`raise RuntimeError` when the configured password is unset/empty, and must never authenticate a
blank password. The rationale, stated up front rather than discovered after a breach: "a bug
here means strangers reading other users' data."
**Fix:** treat "expected secret unconfigured" as a hard failure of the whole auth path, not as
an edge case of the comparison.

### 2. Non-constant-time comparison of a secret/token
**Evidence: designed against, standard practice applied consistently in this project.**
Using `==` (or any comparison that short-circuits on the first mismatched byte) to check a
password, session token, or API key leaks timing information in principle that can narrow a
brute-force search.
**Source:** airbnb-website `auth.py` (`secrets.compare_digest` for the admin password) and
`app.py`'s iCal export token check (same function, different secret) — the same primitive used
everywhere a secret is compared, not just at login.

### 3. Constant-time compare called on the wrong input type/encoding
**Evidence: fixed after a real incident.**
`secrets.compare_digest` raises `TypeError` if its two arguments aren't the same type and, for
strings, both ASCII. An unvalidated, arbitrary user-supplied token (e.g. from a public URL path
segment) compared this way can hit that `TypeError` and surface as an unhandled 500 — which is
also a worse failure mode than a clean "wrong token" response, because a distinguishable error
class can be used as an oracle by an attacker probing the endpoint.
**Source:** airbnb-website `calendar_export` route — guarded with `token.isascii()` before the
digest compare specifically so a non-ASCII garbage token gets the same clean 404 as any other
wrong token, not a 500.
**Fix:** validate the *shape* of untrusted input (encoding, length, character set) before handing
it to a constant-time comparison primitive that assumes well-formed input.

### 4. A signing/session key that's ephemeral by accident rather than by explicit choice
**Evidence: designed against, generalizing from operational experience across this project.**
If a session-signing secret isn't configured, silently generating a random one at process start
means every restart invalidates every existing session — "getting logged out for no reason" is
the only visible symptom, and it can go undiagnosed for a while if the fallback is silent.
**Source:** airbnb-website `app.py` — an unset `ADMIN_SECRET_KEY` falls back to
`secrets.token_hex(32)` per-process, but paired with an explicit `logger.warning(...)` every time
this happens.
**Note the asymmetry with #1 deliberately:** a missing *password* must hard-fail (money/data at
stake behind it); a missing *session-signing key* can gracefully degrade (log loudly, keep
serving, sessions just don't survive a restart) because the failure mode is inconvenience, not a
security hole. Which failure mode fits depends on what's actually at risk — don't reflexively
apply the harder failure mode everywhere, or the softer one everywhere; decide per secret.
