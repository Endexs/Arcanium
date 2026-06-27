# Skill: Feasibility First

## Rule
Before writing the spec, identify the project's **load-bearing external dependency** — the third-party capability that, if it doesn't exist or isn't reachable, makes the project pointless — and validate it with the cheapest possible probe as **Phase 0**. If the project's value depends on a capability you don't control, proving that capability exists is the first task, not a deferred one.

## Why this exists
On the airbnb-llm-chat project (2026-06), the entire value proposition was sending guest replies *into Airbnb*. That integration was the riskiest, least-controllable, value-determining part of the system — and it was validated **last**. A full pipeline ran (spec sync → Phase 1 plan → DeepSeek implementation → adversarial review → fixes → commit) before a 2-minute email-header check revealed the assumed send mechanism (reply-by-email) was dead: Airbnb notification emails carry `Reply-To: noreply@airbnb.com`. The official API was gated to partners; the remaining paths were ToS-risky (browser automation) or paid (partner API). The project was cancelled — after an entire phase had been built, reviewed, and committed.

The risk was *noticed* early (flagged in the spec and in conversation) but was *deferred* to "Phase 2 planning." The standard heuristic — "ship value early, defer the hard integration" — is correct for most projects but exactly backwards when the deferred risk **is** the core value. Deferring it means you build everything else before learning the project is non-viable.

## How to apply

### Step 0, before the spec: name the load-bearing dependency
Ask: *"What single external capability, if absent, makes this project worthless?"* Common shapes:
- A third-party API you assume exists / is open (it may be partner-gated, deprecated, or paid)
- A platform behavior you assume (e.g. "replying to the notification email reaches the user")
- A data source you assume is accessible (auth, rate limits, ToS)
- An integration point (webhook, OAuth scope, export format)

If there's no such dependency — the project is self-contained — this skill doesn't apply; proceed normally.

### Run the cheapest probe that could falsify the assumption
The probe should cost minutes, not days:
- Inspect a real artifact (an email header, an API error body, a response shape)
- A 10-line spike script against the real endpoint
- Read the provider's API access tier / ToS for the specific operation
- A single manual round-trip test on a real account

The goal is **falsification**, not a full integration. You're answering "is this even possible?" before "how do we build it?"

### Gate on the result
- **Confirmed possible** → proceed to spec sync, with the verification recorded as the source.
- **Confirmed impossible / gated / risky** → STOP and run a go/no-go with the user *before* re-scoping. Do not auto-replan around the nearest fallback; the fallback may have removed the project's reason to exist (copy-paste, in the airbnb case).

### Phase ordering follows feasibility, not value-first
When planning phases, ask: *"Is the riskiest deferred item something the whole project depends on?"* If yes, **front-load it** regardless of the "ship value early" heuristic. A drafting feature that works is worthless if the integration it feeds can't ship.

### Don't stamp CONFIRMED on unverified external claims
A `[CONFIRMED]` tag on anything touching an external system requires a verification source (e.g. "verified 2026-06-26: header check"). "The user wants X" confirms *desire*, not *feasibility*. Without a source, mark it `[ASSUMED — unverified]` and treat it as Phase 0 work.

## What this prevents
- Building (and reviewing, and committing) an entire phase before discovering the project is non-viable
- Specs that encode an unverified third-party capability as settled architecture
- Phase plans that defer the existential risk in the name of "shipping value early"
- Auto-replanning a degraded fallback when a feasibility check kills the core mechanism

## Anti-pattern
Treating "the user asked for it" as proof it's buildable. The user defines the goal; the world defines what's possible. When those conflict, you find out cheaply at the start or expensively at the end. Also: over-applying this to self-contained projects — a probe ritual on a project with no external dependency is just ceremony.

## Related skills
- `[[spec-first]]` — feasibility-first runs *before* spec-first; the spec should not encode an unverified external capability. spec-first's `[CONFIRMED]` tags gain a verification-source requirement for external claims.
- `[[decision-log]]` — for external-facing work, add a third axis to confidence/reversibility: **validated? (yes/no)**. An unvalidated assumption the project depends on is an automatic STOP, like Low-confidence + Hard-to-reverse.
- `[[scope-cut-list]]` — when the probe forces a fallback, the cut list records what the project is no longer.
