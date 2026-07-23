# Mid-project lesson — Cortex (second-brain RAG), Phase 1

> **Scope of this entry**: a single workflow lesson validated mid-project. NOT a full retrospective — Cortex is still in progress. The full retro lands when v1 ships.
>
> **Why a mid-project entry**: Per LOOP.md, retros are normally end-of-project. This is an exception because one specific pattern was explicitly validated by the user mid-project and the validation signal would lose context if deferred to end-of-project (months from now).
>
> **Date**: 2026-06-17
> **Project**: Cortex (personal RAG / second-brain CLI), Phase 1 of 4 shipped
> **Skills package version after this lesson**: 0.2.0
>
> **Excluded from `lifecycle/skill-audit` counting** — it carries no "Skills used this project"
> section by design, and the Cortex usage it would report is already counted by
> `2026-06-cortex.md`. Counting both would double-weight one project in the 3-project window.

---

## The setup

After drafting `spec/spec.md` for Cortex, there were ~25 small decisions the user (acting as PM) needed to make: command names, flag names, citation format, error message tone, default chunk size, default top-k, source paths, privacy patterns, success criteria, non-negotiable invariants, phase acceptance gates.

Without a structured way to surface these, the conversation was heading toward 20+ sequential inline questions — slow, hard to track, easy for one decision to depend on another in non-obvious ways.

## What was tried

I produced a single file — `agents/planner/pm-checklist.md` — with:

- 10 numbered sections grouping related decisions (Naming, UX, Scope Review, Defaults, Privacy, Success Criteria, Phase Acceptance)
- One checkbox per decision, each with a default stated explicitly (silence = accept default)
- An explicit separation: *"Items YOU (the product owner) need to decide. Engineering items are deliberately omitted — those are mine."*
- High-leverage callouts: "If you only do two sections today, do Section 5 (scope) and Section 9 (success criteria)."

The user filled it out async, marked some boxes done with notes, left some blank, overrode 3 defaults explicitly.

## The validation

After Phase 1 shipped, the user said unprompted: *"I really like the pm-checklist, it makes decisions more clear and less convoluted."*

That's the signal. Not a single message of feedback during the back-and-forth — silence-as-agreement is harder to interpret. The explicit post-hoc validation is the real test.

## Why it worked

Three properties seem to be doing the work:

1. **Defaults as the no-op**. Every checkbox stated the default I'd pick if they didn't override. The user only had to engage with items they wanted to change. Section 7 (default values) took the user about 30 seconds — they ticked all the defaults. Section 5 (scope) took longer because it's where the real product calls live.

2. **Ownership separation up front**. Labeling decisions as PM vs engineering up front meant the user wasn't second-guessing schema choices and I wasn't second-guessing product instincts. Each side stayed in its lane.

3. **Async + parallel**. A checklist lets the user think about all decisions at once instead of one per chat round-trip. They can move through it at their pace, skip to the hard ones first, come back to defaults later.

## What would have happened without it

Best guess: 20–30 message ping-pong where decisions are scattered, easy to lose track of which are open, and the user gets fatigued and starts saying "just pick something." That's the failure mode: the agent silently making product calls because the human gave up engaging.

## The skill change

Promoted the pattern to `workflow/pm-checklist.md`. Trigger: 5+ PM-shaped decisions OR a long sequence of inline questions that's about to start.

It composes with `spec-first` (the checklist anchors on a spec that already exists) and `scope-cut-list` (one section walks the cut list to confirm keep / promote / abandon each item).

## Open questions for the full Cortex retro

The end-of-project retrospective should address:

- Did the pm-checklist still pay off in Phases 2–4, or only at Phase 1 when the spec was fresh?
- Did any decisions in the checklist need to be re-opened mid-implementation (signal that the defaults were wrong)?
- Are there OTHER patterns from Cortex worth promoting that I haven't noticed yet?
- Were any existing skills underused or misused during Cortex?

That entry will live at `retrospectives/2026-XX-cortex.md` when v1 ships.
