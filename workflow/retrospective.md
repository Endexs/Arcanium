# Skill: Retrospective

## Rule
After each significant phase, document what went wrong, the root cause, and the infrastructure change that would have prevented it. Update skill files based on findings. Past failures should not repeat across projects.

## Why this exists
The LLM Gateway project hit the same kind of bug multiple times — token truncation in Phase 6 and Phase 7, whole-file rewrites in Phase 4. Each was documented in the retrospective and used to update planner/implementer system prompts. The split-run infrastructure built today came directly from observing these patterns.

Without retrospectives, you re-learn the same lessons in every project.

## How to apply

### When to write
Write a retrospective entry at the end of each:
- Feature phase that hit unexpected bugs
- Phase where an adversarial review caught >2 issues
- Phase that took significantly longer than estimated
- Phase where you had to roll back work

### Format
Append to `journal/retrospective.md`:

```markdown
# Phase X Retrospective

## Root Cause Analysis

### 1. <Short description of what went wrong>
<2-3 paragraphs: what was the symptom, what was the actual cause, why did it happen.>

### 2. <Next root cause>
...

## Infrastructure Improvements
**P1 (high)**: <change to make to skill files, system prompts, or tooling>
**P2 (medium)**: <next change>
**P3 (low)**: <nice-to-have>
```

### What to capture
- **Root causes, not symptoms.** "The test failed" is a symptom; "the implementer's plan template didn't specify the error handling table" is a root cause.
- **The specific failure pattern** in a way that's recognizable next time.
- **The skill file or system prompt change** that would catch this earlier.

### What to skip
- Bug fix recipes (those go in the commit message, not the retrospective)
- "We worked hard this phase" content
- Pure narrative without lessons

### Acting on the retrospective
For each P1 improvement, update the corresponding skill file or system prompt **before starting the next phase**. The retrospective is wasted if it doesn't change behavior.

### Domain-specific root causes feed the component library, before the entry is done
If a root cause is specific to a domain covered by `components/` (payment, auth, db, ...),
appending the sourced antipattern to that domain's `components/<domain>/ANTIPATTERNS.md` is
part of *writing this retrospective entry* — not an optional follow-up, and not something to
batch for later. Via negativa: the failure entry goes in first; a `PATTERNS.md` addition only
follows if there's a reference shape worth generalizing, and only cites the antipattern it
responds to. See `engineering/component-library.md` for the full discipline.

## What this prevents
- Repeating the same mistake on the next project
- "Tribal knowledge" that disappears when you take a break
- Skill files that get stale because nobody updates them

## Anti-pattern
Treating the retrospective as a feel-good summary. If every retrospective says "things went well, no major issues," either you're not looking hard enough or you should be shipping faster. Real projects always have failures worth documenting.
