# Skills Package Changelog

Every entry documents what changed, why, and which project's retrospective prompted it. The why is the important part — it's how you tell "we improved" from "we just added stuff."

## Format

```
## v<version> — <YYYY-MM-DD>
After project: <project-name>  (see retrospectives/<file>.md)

### Added
- `<category>/<name>` — <one-sentence reason, grounded in a real bug>

### Modified
- `<category>/<name>` — <what changed and why>

### Deleted
- `<category>/<name>` — <why it didn't pull its weight>

### Notes
<optional: any meta observations about the package itself>
```

## Versioning rules

- **Patch (0.1.0 → 0.1.1)**: Wording changes, clarifications, fixes to existing skills.
- **Minor (0.1.x → 0.2.0)**: New skills added, existing skills meaningfully expanded.
- **Major (0.x → 1.0)**: Breaking reorganization that requires updating project CLAUDE.md references.

---

## v0.2.0 — 2026-06-17
After project (mid-flight): **Cortex / second-brain-v2** (Phase 1 only)
See `retrospectives/2026-06-cortex-phase1-pm-checklist.md`

### Added
**workflow/**
- `pm-checklist` — when spec sign-off has 5+ PM-owned decisions, produce a single checklist file (with defaults stated, ownership separated, high-leverage sections flagged) instead of running 20 sequential inline questions. Composes with `spec-first` and `scope-cut-list`.

### Modified
- `README.md` — added pm-checklist to the workflow/ section listing
- `templates/CLAUDE.md.example` — added pm-checklist under "Active for medium+ changes"

### Notes
- This is a mid-project promotion, not the end-of-project ritual. Cortex is still in Phases 2–4. The user explicitly validated the pm-checklist pattern after Phase 1 sign-off: *"I really like the pm-checklist, it makes decisions more clear and less convoluted."*
- The full Cortex retrospective lands when v1 ships and may add or modify further skills. This entry captures only the one validated lesson.
- Per LOOP.md, mid-project promotions should be the exception, not the rule. Justification: explicit user validation in the moment carries more signal than the same validation reconstructed weeks later from memory.

---

## v0.1.0 — 2026-06-14
After project: **llm-gateway** (see `retrospectives/2026-06-llm-gateway.md`)

### Added (initial extraction)
**workflow/**
- `spec-first` — spec as source of truth; intent before code
- `decision-log` — surface decisions with confidence + reversibility
- `scope-cut-list` — every plan lists what was excluded
- `agent-journal` — agent reflects on its own uncertainty
- `retrospective` — capture root causes, not symptoms

**engineering/**
- `defensive-defaults` — input validation, timeouts, transactions, structured logging
- `boring-tech` — prefer proven choices; custom code requires justification
- `preserve-existing` — never wholesale rewrite files; preserve undocumented patterns
- `disable-flag-both-paths` — TTL=0 / --no-cache / feature flags apply to read AND write

**quality/**
- `good-enough-rubric` — five questions instead of perfectionism
- `adversarial-review` — separate agent hunts for bugs with specific patterns
- `non-negotiable-paths` — code paths that always get the full pipeline

**process/**
- `split-run-implementation` — partition large changes to avoid token truncation

### Notes
- Every skill traces to a specific incident in the LLM Gateway retrospective.
- No skills carried over from prior projects — this is the founding extraction.
- Starter recommendation in README.md: activate only 5 skills on the first project, add more as needed.
