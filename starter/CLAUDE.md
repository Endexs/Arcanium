# {{PROJECT_NAME}} — project conventions

Bootstrapped from Arcanium starter on {{TODAY}}.

This file tells Claude Code (and any sub-agents) how to work on this project. It is the **first** file the agent reads on every session. Keep it current.

## What this project is

> One paragraph. Replace this. See `spec/spec.md` §1 for the canonical version once you've written it.

## Active Arcanium skills

Skills are vendored into `./skills/` at bootstrap time — fully self-contained, no external path dependency. Read each before you start contributing.

### Always active
- `skills/workflow/spec-first` — `spec/spec.md` is the source of truth; update spec before code
- `skills/engineering/defensive-defaults` — validate inputs, set timeouts, log structured
- `skills/engineering/preserve-existing` — never wholesale-rewrite files; preserve undocumented patterns
- `skills/quality/non-negotiable-paths` — auth / money / data deletion always get the full pipeline; load-bearing invariants use `raise RuntimeError(...)`, never `assert`

### Active for medium+ changes
- `skills/engineering/implementer-handoff` — every implementer LLM call must include Names-in-scope, Library-gotchas, Output-budget blocks
- `skills/workflow/decision-log` — surface decisions with confidence + reversibility
- `skills/workflow/scope-cut-list` — every plan explicitly lists features it excluded
- `skills/workflow/pm-checklist` — when a phase has 5+ PM decisions, produce `agents/planner/pm-checklist.md`
- `skills/quality/good-enough-rubric` — five-question review, not perfectionism
- `skills/quality/adversarial-review` — separate agent hunts for bugs (Critical / Major / Minor)

### Active for end-of-project
- `skills/workflow/retrospective` — end-of-project lessons; commit to a public or local Arcanium retrospectives folder
- `skills/workflow/skill-audit` — list "Skills used this project" in the retrospective

> **Note on skill updates**: Skills are frozen at the version stamped in `skills/README.md`. A central Arcanium update will NOT propagate to this project. To re-sync: run `install.sh --local "$(pwd)" --force` from your Arcanium checkout. Frozen skills are a feature, not a bug — a v0.5.0 change shouldn't retroactively break a project that worked under v0.4.0.

## Multi-agent pipeline

| Phase | Model | Artifact |
|------|------|------|
| PM decisions | (user, async) | `agents/planner/pm-checklist.md` |
| Plan | Opus | `agents/planner/phaseN-plan.md` |
| Implement | DeepSeek V4 Pro via `.claude/bin/ds-send` | code |
| Review | Opus (adversarial) | `agents/reviewer/phaseN-review.md` |
| Fix | Haiku via `.claude/agents/fixer.md` | code |

`max-tokens` floor of 65536 for any thinking-mode implementer (DeepSeek V4 Pro, o-series). Thinking burns ~24K silently before content; smaller budgets truncate mid-file.

## Project-specific conventions

> Add anything that's specific to this project — coding style, error format, naming conventions. Replace this section.

## Running tests

```bash
source .venv/bin/activate
pytest -x -q
```

## Project structure

```
{{PROJECT_SLUG}}/
├── spec/spec.md              ← source of truth
├── agents/planner/           ← PM checklists + per-phase plans
├── agents/reviewer/          ← adversarial review outputs
├── .claude/agents/fixer.md   ← Haiku subagent for applying review findings
├── .claude/bin/ds-send       ← direct DeepSeek API wrapper
├── src/{{PROJECT_SLUG}}/     ← code
└── tests/                    ← pytest
```
