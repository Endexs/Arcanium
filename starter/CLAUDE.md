# {{PROJECT_NAME}} — project conventions

Bootstrapped from Arcanium starter on {{TODAY}}.

This file tells Claude Code (and any sub-agents) how to work on this project. It is the **first** file the agent reads on every session. Keep it current.

## What this project is

> One paragraph. Replace this. See `spec/spec.md` §1 for the canonical version once you've written it.

## Active Arcanium skills

Skills live at `/home/developer/projects/solo-dev-agent-skills/`. Read each before you start contributing.

### Always active
- `workflow/spec-first` — `spec/spec.md` is the source of truth; update spec before code
- `engineering/defensive-defaults` — validate inputs, set timeouts, log structured
- `engineering/preserve-existing` — never wholesale-rewrite files; preserve undocumented patterns
- `quality/non-negotiable-paths` — auth / money / data deletion always get the full pipeline; load-bearing invariants use `raise RuntimeError(...)`, never `assert`

### Active for medium+ changes
- `engineering/implementer-handoff` — every implementer LLM call must include Names-in-scope, Library-gotchas, Output-budget blocks
- `workflow/decision-log` — surface decisions with confidence + reversibility
- `workflow/scope-cut-list` — every plan explicitly lists features it excluded
- `workflow/pm-checklist` — when a phase has 5+ PM decisions, produce `agents/planner/pm-checklist.md`
- `quality/good-enough-rubric` — five-question review, not perfectionism
- `quality/adversarial-review` — separate agent hunts for bugs (Critical / Major / Minor)

### Active for end-of-project
- `workflow/retrospective` — `solo-dev-agent-skills/retrospectives/YYYY-MM-{{PROJECT_SLUG}}.md`
- `workflow/skill-audit` — list "Skills used this project" in the retrospective

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
