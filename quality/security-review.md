# Skill: Security Review

## Rule
For any project with a public attack surface AND money, auth, or PII, run a dedicated
**threat-model** pass — separate from `adversarial-review` — before go-live and on any change to
an auth / payment / PII path. It systematically sweeps the classic web attack surface
(authz/IDOR, session & cookie hardening, injection/XSS, CSRF, SSRF, secret leakage, security
headers) rather than only the bugs this codebase has already hit. Use the built-in
`/security-review` command, or an equivalent multi-agent threat-model fan-out by domain
(auth/authz, payment, injection, data-exposure), and resolve every finding through the normal
pipeline.

## Why this exists
On airbnb-website — a live, public direct-booking site handling real payments, admin auth, and
guest PII — `adversarial-review` was active and passing, the suite was green, and the site went
live with a textbook **enumerable IDOR**: the receipt page `/confirmation/{booking_id}` was keyed
by a sequential primary key with no auth, so anyone could walk `1, 2, 3, …` and read every
guest's name, dates, amount, and payment reference. Adversarial review had even hardened that
exact route *twice* — for unrelated 500s — and never flagged it.

The reason is structural: `adversarial-review` is **correctness-first and example-driven** — its
checklist is a fossil record of bugs the codebase already hit (falsy-None, double-close,
lock-across-network, asymmetric flags). "Walk the sequential id and read every row" is not a
correctness bug; it's a threat-model category, and no active skill was responsible for it. A
green suite and passing adversarial reviews create false confidence *precisely because* they
answer a different question.

`adversarial-review` and `security-review` are different instruments. One asks "is this code
correct?"; the other asks "how does an attacker abuse this?" A project on a public money/auth/PII
path needs both.

## How to apply

### When to run
- **Always before go-live** for any internet-facing app with money, auth, or PII — a hard gate,
  alongside the config/ops go-live checklist.
- **Always** on a change that touches an auth, payment, session, or PII-rendering path.
- **Always** when adding a public route that renders or accepts user/tenant data.
- Skip for: internal/CLI-only tools with no network surface; pure docs/refactor; a project with
  no auth/money/PII (adversarial-review still applies there).

This is a **distinct step** from `adversarial-review` — running one does NOT satisfy the other.
State both explicitly when closing a qualifying task ("security-review: yes/no, because…").

### The sweep — what `adversarial-review` does NOT systematically cover
- **AuthZ / IDOR** — can an unauthenticated or cross-tenant user reach a privileged action or
  read another user's row by guessing/enumerating an id? Any public page keyed by a sequential
  PK is the tell (`components/auth/ANTIPATTERNS.md` #5).
- **Session & cookie hardening** — `Secure`/`HttpOnly`/`SameSite`; is `Secure` derived from the
  environment or from a forgettable opt-in flag? (auth #6)
- **CSRF** — `SameSite=lax` is a same-*site*, not same-*origin* control; state-changing requests
  still need a token. (auth #7)
- **Injection** — XSS (is template autoescape actually on? any `|safe`?), SQLi, SSRF
  (host/protocol control, re-validated per redirect hop), path traversal.
- **Secret & data exposure** — secrets in logs/errors/responses; debug tracebacks; an endpoint
  returning more than the caller should see.
- **Transport / headers** — TLS, `Referrer-Policy` on capability-URL pages, CSP/HSTS.

### How to run
Prefer the built-in `/security-review` over the pending diff. For a whole-app pre-go-live pass,
fan out independent agents by domain (auth/authz, payment, injection, data-exposure) so each is
blind to the others and one blind spot doesn't sink the sweep; then adversarially verify each
finding before fixing. Feed every confirmed failure mode back into
`components/<domain>/ANTIPATTERNS.md` (via negativa) so the next project inherits it.

### Verify the fix is actually deployed, not just merged
A security finding isn't closed when the PR merges — it's closed when the **running** artifact
serves the fix. Long-lived servers (e.g. uvicorn without `--reload`) keep the code they imported
at startup; a merge updates the source, not the process (and templates may hot-reload while
routes do not, which looks like a deploy). Confirm the live process serves the new code (running
version / OpenAPI / health), never infer "shipped" from `git log`. Source: airbnb-website — the
IDOR fix was merged and correct on disk but the live process served the vulnerable route for
~13h until restarted.

## What this prevents
- Enumerable-IDOR and other authz holes that pass every correctness test.
- "It's HTTPS and behind auth, so it's fine" — the specific gaps (cookie flags, CSRF, headers) a
  correctness review never looks for.
- Treating a green suite + a passing adversarial review as a security sign-off. They aren't.

## Relationship to other skills
- `[[adversarial-review]]` — complementary, not a substitute: correctness vs. threat model.
- `[[non-negotiable-paths]]` — the auth/money/PII paths that trigger this skill.
- `[[component-library]]` — this skill's findings become `components/auth` (etc.) antipatterns;
  read those first, feed new ones back.
