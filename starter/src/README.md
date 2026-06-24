# src/

Your project's code lives here. The starter ships an empty package at `src/{{PROJECT_SLUG_UNDERSCORE}}/__init__.py` so imports work immediately.

## Layout convention

```
src/{{PROJECT_SLUG_UNDERSCORE}}/
├── __init__.py     ← package marker
├── cli.py          ← Click entry point (if this project is a CLI)
├── models.py       ← dataclasses, types
├── storage.py      ← persistence
└── ...
```

Use module names from your spec §3 (Architecture). The names in `engineering/implementer-handoff` blocks should match the actual module names exactly.

If this project is NOT Python (Go, Rust, TS), delete this `src/{{PROJECT_SLUG_UNDERSCORE}}/` package and lay out per that language's conventions. The methodology is language-agnostic; only the starter assumes Python.
