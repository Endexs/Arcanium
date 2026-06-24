# agents/reviewer/

Adversarial review outputs. Per `quality/adversarial-review`, a separate agent (different context, ideally different model) reviews the implementer's diff as an adversary.

## Files

- `phaseN-review.md` — per-phase review you produce
- `review-template.md` — copy this when starting a new review

## Workflow

1. Implementer's output has landed and tests pass locally
2. Reviewer reads spec + plan + diff
3. Reviewer produces Critical / Major / Minor findings with the Top 5 prioritized
4. Critical findings = ship-blockers (not negotiable)
5. Apply fixes via `.claude/agents/fixer.md` (Haiku) or directly

## Model

Review uses **Opus**, NOT the same model that planned or implemented. Cross-model review catches more.
