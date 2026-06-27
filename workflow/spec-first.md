# Skill: Spec First

## Rule
Before writing any code for a new feature, write or update `spec.md`. The spec documents intent (why, who, what). Code serves the spec, not the other way around.

## Why this exists
On the LLM Gateway project, every phase started with a spec update. This let the planner, implementer, and reviewer all work from the same source of truth. When the implementer made a wrong assumption, the spec was the tiebreaker — not whoever spoke last.

Without a spec, agents drift in ways you can't notice until much later. The spec is cheap insurance.

## How to apply

### When starting a project
Write `spec/spec.md` with these sections:
- **Purpose & Business Intent** — what does this do, who is it for, why does it exist
- **Constraints & Non-Goals** — explicitly out of scope (this is as important as the in-scope list)
- **Interface** — CLI commands, API endpoints, or UI screens at a high level
- **Error handling** — table of scenario → behavior → exit code or status

### When adding a feature
1. Add a new numbered section to `spec.md` describing the feature
2. Include: purpose, interface, data model changes, error handling, test additions
3. Commit the spec change *before* any implementation begins
4. Implementation references the spec section in commit messages and plans

### When the spec is ambiguous
If the agent encounters ambiguity during implementation, it must:
- Stop and flag the gap (do not invent a resolution)
- Propose a spec amendment for user approval
- Resume only after the spec is updated

### When the spec has empty sections (start-of-project)
At project bootstrap, the spec.md template ships with empty placeholder sections. The agent must NOT silently fill them. Apply the **gap discipline** documented in the project's `CLAUDE.md`:
- **PM-owned sections** (purpose, user stories, non-negotiables, success criteria) → output `[GAP — PM input needed]`, do not invent
- **Engineering-owned sections** (architecture, data model, interface) → may draft a strawman from the PM-owned answers, marked `[DRAFT — please review]`
- **Collaborative sections** (phase plan, cut list) → propose options, don't decide unilaterally

Apply stated defaults from the PM checklist (silence = accept-default per `[[pm-checklist]]`). Transcribing a checklist answer is NOT inventing — it's recording a decision already made. Inventing means writing content with no signal from the user.

The full table lives in `CLAUDE.md` so it's read every session; this section keeps the skill index aware of the rule.

### When a decision touches an external system: `[CONFIRMED]` needs a source

A `[CONFIRMED]` tag means a decision is settled. For anything that depends on a system you don't control — a third-party API, a platform behavior, an integration you assume exists — that tag must cite a **verification source**, because "settled" conflates two different claims:
- **PM-confirmed** — the user decided they want this.
- **Feasibility-confirmed** — the capability actually exists.

The user can only give you the first. A `[CONFIRMED]` on an external capability backed only by "the user wants it" is recording desire as if it were proof.

Rule:
- External claim **with** a verification source → `[CONFIRMED 2026-06-26: verified via <probe/header check/API response>]`
- External claim **without** one → `[ASSUMED — unverified]`, and it becomes Phase-0 work (run the probe; see `[[feasibility-first]]`) before it can be promoted to `[CONFIRMED]`.

Source: airbnb-llm-chat. The spec stamped "replies to the notification email reach the guest via SMTP" as `[CONFIRMED]` on the strength of the user wanting platform integration. It was never tested; reply-by-email was dead (`Reply-To: noreply@`). The whole project rested on a desire mislabeled as a fact.

## What this prevents
- Agents inventing behavior the user didn't ask for
- Different agents (planner vs implementer vs reviewer) acting on conflicting assumptions
- Scope creep mid-implementation
- Bugs that surface in production because nobody specified the edge case
- An unverified external capability written into the spec as settled architecture, so every downstream agent treats a guess as a fact

## Anti-pattern
Treating the spec as documentation written after the code. The spec is a *contract*, not a record. If you find yourself updating the spec to match what you built, you skipped the step.
