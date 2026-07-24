# agents/planner/

Plans and PM checklists. The planner runs first in every phase and produces the artifacts the implementer reads.

## Files

- `pm-checklist.md` — Phase 1 PM checklist (already created from the starter)
- `phaseN-plan.md` — per-phase plans you write as the project progresses
- `plan-template.md` — copy this when starting a new phase plan

## Workflow

1. **Phase 1**: user fills `pm-checklist.md`, agent reads it and writes `phase1-plan.md`
2. **Phase 2+**: agent writes a smaller phase-specific PM checklist (`phaseN-pm-checklist.md`) with a Carry-forward block, user fills it, agent writes `phaseN-plan.md`
3. Plans are read by the implementer (the T2 model via `.claude/bin/omni-send`) — no human runs them

## Model

Planning uses **Opus**, not Sonnet. Planning is a heavier reasoning task than the cost suggests.
