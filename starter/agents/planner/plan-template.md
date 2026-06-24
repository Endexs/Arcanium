# Phase N plan: <name>

> Template for a per-phase implementation plan. Copy to `phase1-plan.md` (or whichever phase) and fill in. The implementer reads this end-to-end before writing any code.

## Spec sections satisfied
- §x — <what>
- §y — <what>

## Carry-forward (from prior phases)

> Decisions settled in earlier phases that still apply. The implementer treats these as closed; do not re-litigate.

- ...

## File-by-file changes

> What gets created, modified, or deleted. Include line-level sketches where it matters.

### `src/{{PROJECT_SLUG_UNDERSCORE}}/<file>.py` (new / modify)
- ...

### `tests/test_<file>.py` (new / modify)
- ...

## Names in scope

> Per `engineering/implementer-handoff`: every importable function/class/method the implementer will need, with current signatures. Include negative assertions for names the implementer is likely to invent.

```
From {{PROJECT_SLUG_UNDERSCORE}}.<module>:
  - func_a(arg: Type) -> ReturnType
  - func_b(path: Path) -> None    # NOTE: takes Path, not Connection
  # NOTE: there is no func_c — do not invent one.
```

## Library gotchas

> Per `engineering/implementer-handoff`: per-library defaults the implementer will pattern-match wrong from training data.

**<library>** — <gotcha>

## Output budget

- Implementer model: DeepSeek V4 Pro
- max-tokens: **65536** (thinking mode burns ~24K tokens silently before content; 16K floor is insufficient)
- Expected output: ~N files, ~M lines

## Test strategy

- ...

## Dependencies on prior phases

- ...

## Non-goals for this phase

> Per `workflow/scope-cut-list`: what this phase explicitly does NOT add, even if tempting.

- ...
