# Skill: Rigor Triage

## Rule
Before starting any change, the agent picks how much process it deserves — and says which and why. Match rigor to **blast radius × reversibility × criticality**, never to lines of code. Three tiers:

- **Vibe (one-shot):** cosmetic, local, easily reversible, touches no critical surface → just build it, then smoke-test. Skip the heavy pipeline.
- **Standard:** normal feature/logic → spec touch + a short plan + tests + self-review.
- **Full pipeline:** any `[[non-negotiable-paths]]` path (auth, money, data deletion, migrations, secrets, public contracts, bulk-user) → plan → implement → **adversarial review** → fix, regardless of size.

When a change is genuinely ambiguous between two tiers, **round up**.

## Why this exists
Two failure modes, opposite directions. Over-process everything and you smother a CSS tweak in ceremony and never ship — the trap `[[good-enough-rubric]]` warns about. Under-process and you one-shot a "quick" pricing tweak straight into a money bug. Solo devs need a fast, explicit gate at the *front* of each task so the agent doesn't silently apply the wrong amount of rigor. This skill is the router; `[[non-negotiable-paths]]` is the floor it routes the top tier into, and `[[good-enough-rubric]]` is the ceiling it routes the bottom tier into.

## How to apply

### Step 1 — criticality pre-check (any "yes" → NOT vibe)
Ask, in order:
- Money? (charges, refunds, pricing, billing, currency)
- Auth / authz / sessions / tokens / secrets?
- Deletes, migrates, or overwrites data? Affects many users/records at once?
- Exposes PII, or parses untrusted external input (SSRF, injection surface)?
- **Irreversible side effect** (sends a real email, charges a card, publishes, external API write)?
- A correctness **invariant** others rely on (no-double-booking, idempotency, a public API/webhook shape)?

Any yes → **Standard at minimum**, and if it's on the `[[non-negotiable-paths]]` list → **Full pipeline**. All no → eligible for **Vibe**.

### Step 2 — route to a tier

| Tier | Use when | What it includes |
|------|----------|------------------|
| **Vibe (one-shot)** | Cosmetic / presentational / local + reversible: layout, styling, copy, static content, a demo script, a README, a log line. No critical pre-check hits. | Just write it. **Still** run/eyeball it once (vibe ≠ blind). One commit. |
| **Standard** | Real behavior that isn't on the non-negotiable list: a CRUD endpoint, a form, a filter, a non-money calculation, refactors. | Spec touch if behavior changes · short plan / decision note for anything hard-to-reverse (`[[decision-log]]`) · tests for the logic · self-review. |
| **Full pipeline** | Any `[[non-negotiable-paths]]` path, or anything with catastrophic + hard-to-reverse blast radius. | Plan → implement → **separate adversarial review** → fix → tests. Encode invariants as `raise RuntimeError`, never `assert`. No skipping steps even under "it's one line." |

### The dial applies to the change, not the file
A one-line edit to the charge amount is **Full pipeline**. A 300-line pure-CSS redesign with no logic is **Vibe**. Size is not the signal — what breaks if it's wrong is.

### Round-up triggers (escalate a tier)
- You're unsure which tier → round up.
- The change leans on an **unverified external capability** → resolve via `[[feasibility-first]]` before proceeding (that unknown alone is Standard+).
- "It's just a small change" to critical code → that sentence is a red flag, not a downgrade.
- A vibe change starts reaching into logic/state → stop, re-triage as Standard.

### State the call
Open the task with one line: **"Rigor: <tier> — <reason>."** e.g. *"Rigor: Vibe — hero-section layout only, no logic/state."* or *"Rigor: Full — touches refund flow (money, non-negotiable)."* This makes the choice reviewable instead of implicit, and lets the user override before work starts.

## What this prevents
- Vibe-coding a payment/auth/deletion change into a catastrophic, hard-to-reverse bug.
- The opposite waste: a full plan + adversarial review for a button-color change.
- Silent, implicit rigor decisions the user never got to veto.
- "Small change" reasoning smuggling a critical edit past the review it needed.

## Anti-pattern
Letting the tier be argued *down* by effort or deadline ("just ship it, it's fine"). Criticality is a property of what the code touches, not of how busy you are. The tier can always be argued *up*, never down past the non-negotiable floor.
