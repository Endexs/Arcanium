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

### 5. A page that renders private data, addressed by a guessable sequential id
**Evidence: fixed after a security-review finding on a live, public site.**
An unauthenticated page keyed by an auto-increment integer primary key lets anyone walk
`1, 2, 3, …` and read every row — a textbook IDOR. It's especially easy to ship because the URL
the legitimate owner receives (a confirmation / receipt link) *looks* private and the route
"works," so it sails through a happy-path test and through a correctness-first review that isn't
specifically hunting for enumeration.
**Source:** airbnb-website `/confirmation/{booking_id}` — the receipt page rendered a confirmed
booking's guest name, dates, amount, and Stripe PaymentIntent id, gated only on
`status == "confirmed"` and keyed by the sequential PK. Anyone could enumerate every guest's PII.
Found by `security-review` (a systematic threat-model pass), never by the per-phase adversarial
review that had hardened that same route *twice* for unrelated 500s.
**Fix:** key any page that renders private data on an unguessable per-row capability token
(`secrets.token_urlsafe(32)`), not the PK; look the row up by token; return the *same* 404 for a
wrong token as for a missing row so the endpoint isn't an existence oracle. A sequential id stays
fine on a *session-gated* admin view — the enumeration risk is specifically the
unauthenticated / cross-tenant one. See PATTERNS #4.

### 6. A cookie-`Secure` (or any hardening) flag that defaults OFF and is opt-in per deploy
**Evidence: fixed after a security-review finding; a `disable-flag-both-paths` sibling.**
When the `Secure` flag on a session/auth cookie is driven by an opt-in env var that defaults to
off, *forgetting* that var in a production env file silently ships an auth cookie a network
attacker can capture over any plaintext/downgraded request. The default is the danger: the safe
state depends on an operator remembering a flag, and the failure is invisible — the site works
fine, the cookie just quietly lacks one attribute.
**Source:** airbnb-website `app.py` — `https_only` came from `ADMIN_HTTPS_ONLY` defaulting off; a
prod env that set `APP_ENV=production` but omitted `ADMIN_HTTPS_ONLY=1` served the admin session
cookie without `Secure`.
**Fix:** derive the hardened state from the environment's *own* signal, not a separate opt-in:
`https_only = (APP_ENV == "production") or ADMIN_HTTPS_ONLY_truthy`. Production is Secure by
construction, a missing flag can no longer downgrade it, and a non-prod TLS box can still opt in.
Same shape as `disable-flag-both-paths`: the hardened path is the *default*, and any weakening is
the thing you must explicitly ask for. See PATTERNS #5.

### 7. Treating `SameSite=lax` as CSRF protection for state-changing requests
**Evidence: fixed after a security-review finding.**
`SameSite=lax` blocks classic *cross-site* form/image POSTs, so it's tempting to conclude a
server-rendered admin panel is CSRF-safe with no token. But Lax is a same-***site*** control, not
same-***origin***: a request from any host on the same registrable domain (a marketing subdomain,
a CNAME'd service, a compromised sibling app) counts as same-site and the cookie rides along —
enough to forge a money-moving admin action.
**Source:** airbnb-website admin panel — 16 state-changing admin POSTs relied on `SameSite=lax`
alone with no token; a sibling-subdomain forgery of `/admin/bookings/{id}/cancel` (a real Stripe
refund) or `/admin/listing` was reachable.
**Fix:** add a per-session synchronizer CSRF token to *every* state-changing request (not only the
ones Lax happens to miss), validated constant-time and fail-closed on a missing session token;
check it *after* the auth dependency so an unauthenticated request still redirects to login rather
than leaking a 403. Rotate the session on login (`session.clear()` before setting the
authenticated flag) so a pre-auth, attacker-plantable token can't be fixated into the
authenticated session. See PATTERNS #6.
