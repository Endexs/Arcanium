# {{PROJECT_NAME}}

> One-sentence description. Replace this.

Bootstrapped from Arcanium starter on {{TODAY}}.

## Quick start

```bash
source .venv/bin/activate
pytest -x -q
```

## Where to look

- `spec/spec.md` — what this is, how it's built, and why (source of truth)
- `CLAUDE.md` — agent conventions and the multi-agent pipeline
- `agents/planner/` — PM checklists and per-phase plans
- `agents/reviewer/` — adversarial review outputs
- `src/{{PROJECT_SLUG_UNDERSCORE}}/` — code
- `tests/` — pytest

## Methodology

Built using the [Arcanium](https://github.com/Endexs/Arcanium) skills package and the spec-first multi-agent workflow. The skills it depends on are vendored into `./skills/` — see `skills/README.md` for the source version.
