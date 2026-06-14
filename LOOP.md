# The Continuous Improvement Loop

This document describes how to use this skills package as a living system that gets sharper with every project, instead of a frozen artifact that gradually becomes stale.

## The principle

Every bug that ships is a test you didn't write. Every friction point is feedback the system should absorb. The improvement comes from feeding both back into the skill files — not just from writing them down.

The retrospective is *input* to the refinement. It has zero value on its own. If a retrospective doesn't change a skill, you haven't actually learned anything portable.

---

## The cadence

### During a project: capture frictions
Keep a `friction.md` scratchpad in the project. When something goes wrong that a skill *should* have caught, take 60 seconds to note it. Don't fix the skill mid-project — just capture the input.

Template: `templates/friction.md.example`

### End of project: refinement ritual (~2 hours)
Don't skip this. This is where the skills package actually improves.

**Step 1 — Bug archaeology (30 min)**
For every bug that shipped:
- Which skill *should* have caught it?
- Did that skill exist? Why didn't it fire?
- Is the fix: sharper wording, a new skill, or a missing example?

**Step 2 — Friction audit (30 min)**
For every entry in `friction.md`:
- Missing skill? Add it.
- Too-vague skill? Sharpen the wording.
- Skill that contradicted another? Reconcile them.

**Step 3 — Update the package (30 min)**
- Apply the changes to the skill files
- Update `CHANGELOG.md` with the version bump
- Update `VERSION`
- Commit the changes

**Step 4 — Validate (30 min)**
Take 3 real bugs from the project and check: would the updated skills have caught them? If not, your changes aren't sharp enough. Iterate.

### Annually: the deeper prune
Once a year, do a heavier audit:
- Re-read every skill. Is the language still sharp?
- Re-read the CHANGELOG. Are you adding faster than deleting?
- Pick 3 skills you suspect are weakest. Try a project with them disabled.
- Re-read 3 old retrospectives. Did the skills you added then pay off?

This is refactoring for your process. Without it, the package accumulates cruft.

---

## Hard rules to prevent drift

### Delete aggressively
If a skill hasn't fired in two projects, it's probably wrong or too narrow. Remove it. Bigger packages aren't better packages — sharper ones are.

### Cap categories at ~6 skills
When you'd add a 7th to any category, force yourself to merge or delete. This forcing function prevents bloat better than willpower.

### Every skill traces to an incident
For every skill in the package, you should be able to name the specific bug or friction that motivated it. If you can't, suspect cargo-cult.

### Project-specific tweaks stay in project CLAUDE.md
Never customize the global skills for one project's quirks. Use the project's CLAUDE.md to override. Global skills must stay portable.

### Retrospective without skill change = theater
If you wrote a retrospective and the skills package didn't change, something is wrong. Either:
- The project went truly well (rare; be suspicious)
- You're not looking hard enough at failures
- The retrospective template isn't surfacing actionable items

Fix one of those before moving on.

---

## What to put in retrospectives

Use `templates/retrospective.md.example` as the starting point. Key sections:

- **What worked** — skills that prevented bugs or sped you up
- **What failed** — bugs that shipped, friction the skills didn't address
- **Bugs caught after shipping** — categorize each by which skill *would have* caught it
- **Skills changes proposed** — concrete additions, modifications, deletions
- **Time spent** — rough numbers on hours saved vs hours of ceremony

The "skills changes proposed" section is the bridge between what happened and what changes. Without it, the retrospective is a diary.

---

## What to put in friction.md (during the project)

A running list. One line per friction. Don't fix; just capture.

Example entries:
```
- Implementer added retry-with-backoff logic the plan didn't ask for. Spec was silent. Wasted 20 min reviewing it.
- Reviewer flagged "magic number" — but I'd told it not to in CLAUDE.md. Skill conflict?
- `boring-tech` said SQLite, but I'm building a multi-process queue. Skill needs a "when not to" section.
- No skill caught the missing timeout on the new webhook endpoint. Add to defensive-defaults?
```

Then process this list during the refinement ritual.

---

## The honest meta-point

Most people stop at "I wrote it down." The improvement comes from "I changed how I work because of it."

Compounding is real but slow. Project 1 you ship with okay process. Project 5 you ship with sharp process. Project 20, you have a process that's genuinely better than what most teams use — because every failure fed back into the system.

This is test-driven development, but for your *process* instead of your *code*. The CHANGELOG is your evidence that the loop is closing.
