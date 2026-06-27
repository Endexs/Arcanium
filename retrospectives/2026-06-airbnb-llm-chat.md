# airbnb-llm-chat — Project Retrospective (cancelled after Phase 1)

**Date:** 2026-06-27
**Outcome:** Project wound down. Phase 1 (grounded warm drafts) shipped and is green (26 tests). Phase 2 was planned but not built. The project was cancelled because its core value — automated sending of replies *into Airbnb* — turned out not to be achievable without ToS/maintenance risk (browser automation) or recurring cost (partner API). Reply-by-email, the assumed mechanism, is dead (Airbnb notification `Reply-To` is `noreply@`). Copy-paste was the only zero-risk fallback, and it removes most of the value.

---

## Root Cause Analysis

### 1. The load-bearing external-integration assumption was validated LAST, not FIRST

**Symptom:** A full pipeline ran — spec sync → Phase 1 plan → DeepSeek implementation → adversarial review → fixes → commit — before anyone confirmed the one thing the whole project depended on: that the operator's approved reply could actually reach the guest through Airbnb.

**Actual cause:** The project's entire value proposition was *integration with Airbnb messaging*. That integration was the highest-risk, least-controllable, value-determining part of the system. Yet it was the last thing checked. The feasibility risk was *noticed* early (flagged in the spec and in chat repeatedly) but was **deferred to "Phase 2 planning"** instead of being **gated before any other work**. By the time we ran the 2-minute header check (`Reply-To: noreply@airbnb.com`), Phase 1 was already implemented, reviewed, fixed, and committed.

**Why it happened:** The phase plan deliberately chose "Option A: drafting first, integration second," with the stated rationale *"defer the hardest-to-reverse risk until the core value is proven."* That heuristic is correct for most projects — but it is exactly backwards when the deferred risk **is** the core value. We optimized for "ship value early" on a project where the only real risk was whether the project was viable at all. The agent had the right instinct (it proposed copy-paste in the very first exchange) but did not convert that instinct into a hard gate; it accepted the user's "I want platform integration" as a settled requirement without first proving the requirement was *possible*.

### 2. The spec encoded an unverified third-party capability as a CONFIRMED fact

**Symptom:** §1/§3/§5 described "replies to that email via SMTP so Airbnb relays it to the guest" as settled architecture, stamped `[CONFIRMED 2026-06-26]`.

**Actual cause:** "CONFIRMED" conflated two different things: *the user confirmed they want this* (PM decision) and *this is technically possible* (feasibility). Only the first was true. There was no verification source behind the integration claim, but it carried the same confidence tag as decisions that were genuinely settled (model choice, grounding rule).

**Why it happened:** The spec-sync discipline distinguishes PM-owned vs engineering-owned sections, but has no separate bar for claims that depend on an **external system we don't control**. Those need a verification citation, not a confidence stamp.

### 3. When the core mechanism died, we re-planned a degraded phase instead of running a go/no-go

**Symptom:** The moment reply-by-email was confirmed dead, work flowed straight into re-syncing the spec and writing a complete Phase 2 copy-paste plan — a meaningful chunk of effort — before stepping back to ask whether a copy-paste tool was still worth building.

**Actual cause:** A feasibility check that *invalidates the core value* should trigger an explicit viability gate ("given this, is the project still worth doing?"), not an automatic re-scope to the nearest fallback. The user ultimately made the right call (cancel), but only after the degraded plan was written.

**Why it happened:** No "viability gate" step exists between "a feasibility finding came back negative" and "re-plan around it." The default motion is to keep moving forward.

---

## Infrastructure Improvements

**P1 (high) — New skill: `workflow/feasibility-first` (validate load-bearing external assumptions before the spec).**
Before spec sync, identify the project's load-bearing external dependency — the capability that, if unavailable, makes the project pointless. Validate it with the cheapest possible probe (a header inspection, an API ping, a 10-line spike) as **Phase 0**, before any spec or implementation work. Rule of thumb: *if the project's value depends on a third-party capability you don't control, proving that capability exists is the first task, not a deferred one.* This single skill would have killed this project in 2 minutes on day one instead of after a full implemented-and-reviewed phase.

**P1 (high) — Amend phase-ordering guidance (in the planner prompt / a note on `decision-log`).**
"Ship value early, defer the hard integration" is the right default **except** when the deferred risk is existential. Add an explicit check to phase planning: *"Is the riskiest deferred item something the whole project depends on? If yes, front-load it regardless of the ship-value-early heuristic."* The decision-log's two axes (confidence, reversibility) should gain a third for external-facing work: **validated? (yes/no)** — an unvalidated assumption that the project depends on is an automatic STOP, like Low-confidence + Hard-to-reverse.

**P2 (medium) — Sharpen `workflow/spec-first`: separate "PM-confirmed" from "feasibility-confirmed".**
A `[CONFIRMED]` tag on any claim that touches an external system must carry a verification source (e.g. "verified 2026-06-26: header check"). "The user wants X" is never sufficient to mark an external capability CONFIRMED. Without a source, the tag is `[ASSUMED — unverified]`.

**P3 (low) — Add a "viability gate" beat to `retrospective`/planning.**
When a feasibility check returns negative on a core assumption, the next action is an explicit go/no-go with the user, not an automatic re-scope to a fallback. One sentence in the planning flow.

---

## Skills used this project
- workflow/spec-first
- workflow/decision-log
- workflow/scope-cut-list
- workflow/pm-checklist (worked from the existing checklist; no new one generated)
- workflow/retrospective
- workflow/skill-audit
- engineering/implementer-handoff (Phase 1 + Phase 2 plans; held up well — zero hallucinated names)
- engineering/preserve-existing (minimal-diff edits, esp. the fixer pass)
- engineering/defensive-defaults (always-active; surfaced the missing-timeout finding M1)
- engineering/boring-tech (argparse, JSON-file persistence)
- quality/non-negotiable-paths (§6.2 grounding tests, RuntimeError not assert)
- quality/adversarial-review (Phase 1 review: 2C/2M/9N, all real)

**Not used (honest):** quality/good-enough-rubric — never ran the five-question review explicitly.

**Skill-audit note:** This is the project's first/only retrospective; no aggregate 3-project audit triggered. The standout positive citation is `implementer-handoff` (no hallucinated names across two handoffs — the negative-assertion technique earned its rent) and `adversarial-review` (every finding was real). The standout *gap* is the absence of a feasibility-first skill — recommend adding it to the package (P1 above) before the next integration-shaped project.

---

## One-line lesson
**If a project's value depends on an external capability you don't control, prove that capability exists before you write the spec — not after you ship a phase.**
