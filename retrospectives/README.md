# Retrospectives

One file per project, named `YYYY-MM-<project-slug>.md`. Created at the end of each project as part of the refinement ritual described in `../LOOP.md`.

## Why this folder exists

These are the inputs to skill changes. Every entry in `../CHANGELOG.md` references the retrospective that motivated it. Without these, the changelog becomes "I added stuff" instead of "I learned this, so I changed that."

## How to use

1. At project end, copy `../templates/retrospective.md.example` to `YYYY-MM-<project>.md`
2. Fill it in honestly — especially the failure sections
3. Convert the "Skills changes proposed" section into actual file edits
4. Update `../CHANGELOG.md` referencing this retrospective by filename
5. Commit

## What good looks like

See `2026-06-llm-gateway.md` — this is project zero, the source of every v0.1.0 skill. Note how each skill in the changelog traces to a specific incident in the retrospective. That linkage is what makes the skills credible later: when you re-read them in two years, you can see *why* they exist.

## Anti-patterns to avoid

- **Retros without skill changes** — theater. Either the project was perfect (suspect this) or the retro wasn't honest enough.
- **Retros that propose vague rules** — "be more careful with X" is not a skill. "When implementing X, do Y because Z bug" is.
- **Skipping retros for small projects** — small projects teach you which skills are overhead. That's valuable signal.
- **Deleting old retros** — they're cheap to keep, and re-reading them annually catches drift.
