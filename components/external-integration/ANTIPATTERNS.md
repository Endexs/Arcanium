# External Integration — Antipatterns (via negativa)

Read this before writing or reviewing any code that depends on a third-party system's specific
behavior — a webhook contract, a platform's messaging mechanism, an external feed URL, a partner
API tier. This domain's evidence includes the single most severe incident in this ecosystem: an
entire project cancelled after a full phase was built, reviewed, and committed on an assumption
that turned out false.

---

### 1. Building on an assumed third-party mechanism without verifying it first
**Evidence: fixed after a real incident — the project did not survive it.**
A project's core value proposition depended on a specific behavior of a system it did not
control (replying to a platform's notification email would reach the end user through that
platform). That assumption was never checked with a real probe before an entire phase was
planned, implemented, adversarially reviewed, fixed, and committed. A 2-minute check (inspecting
a real email header) would have falsified it on day one.
**Source:** `airbnb-llm-chat`, cancelled 2026-06-27 — the assumed reply-by-email mechanism was
dead (the platform's notification emails carry a `noreply@` `Reply-To`); the official partner
API was gated, and the remaining paths were ToS-risky or paid.
**Rule of thumb:** if a project's value depends on a third-party capability you don't control,
proving that capability exists is the first task, not a deferred one.

### 2. An external-system claim marked "confirmed" without a verification source
**Evidence: fixed after a real incident** (same project as #1).
A spec/decision-log tag like `[CONFIRMED]` was applied to a claim about an external system's
behavior with the same confidence as a genuinely-settled internal decision. "The user wants X"
(a real, confirmed PM decision) and "X is technically possible" (an unverified assumption about
a system you don't control) are different claims and need different evidence bars.
**Fix:** a `[CONFIRMED]` tag on anything touching an external system requires a stated
verification source (e.g. "verified 2026-06-26: email header inspection"). Without one, the
claim is `[ASSUMED — unverified]`, not confirmed.

### 3. Re-scoping around a fallback instead of running a viability check first
**Evidence: fixed after a real incident** (same project as #1).
The moment the core mechanism was confirmed dead, work flowed directly into planning a degraded
fallback — a meaningful chunk of effort — before anyone asked whether the fallback was still
worth building at all.
**Fix:** a feasibility check that invalidates the core value proposition triggers an explicit
go/no-go conversation before any re-scoping work, not an automatic pivot to the nearest
alternative.

### 4. Trusting a redirect target without re-validating it
**Evidence: fixed after a real incident.**
Validating a third-party-supplied URL's scheme/host at registration time is not sufficient if
whatever fetches that URL later follows redirects — a `302` to an unvalidated target is blind
SSRF, including to cloud metadata endpoints.
**Source:** airbnb-website Phase 6B, Major finding M3 — an external calendar feed's URL was
scheme-checked at registration, but the fetch followed `30x` redirects to a target nobody
re-validated.

### 5. Processing an incoming webhook event before its signature is verified
**Evidence: designed against as an explicit non-negotiable, before an incident occurred.**
An incoming webhook is, by definition, a request from the public internet claiming to represent
a trusted third-party event. Acting on its payload before cryptographically verifying it came
from the claimed sender (not just checking the payload "looks right") means anyone who can reach
the endpoint can forge the event.
**Source:** airbnb-website's Stripe webhook handler — every event's signature is verified against
a configured secret before any part of the payload is trusted; an invalid or absent signature is
rejected outright, never partially processed or logged as if legitimate.
