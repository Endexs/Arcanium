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

## What this prevents
- Agents inventing behavior the user didn't ask for
- Different agents (planner vs implementer vs reviewer) acting on conflicting assumptions
- Scope creep mid-implementation
- Bugs that surface in production because nobody specified the edge case

## Anti-pattern
Treating the spec as documentation written after the code. The spec is a *contract*, not a record. If you find yourself updating the spec to match what you built, you skipped the step.
