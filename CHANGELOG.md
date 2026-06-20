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

## v0.3.0 — 2026-06-19
After project: **Cortex / second-brain-v2** (shipped v1.0.0, 52 tests, 4 phases complete)
See `retrospectives/2026-06-cortex.md`

### Added
**engineering/**
- `implementer-handoff` — before invoking the implementer model on a multi-file generation task, extend the handoff prompt with three blocks: **names in scope** (every importable function with current signatures, plus negative assertions for likely-hallucinated names), **library gotchas** (per-library subtle defaults the implementer will pattern-match wrong), and **output budget** (`max-tokens` floor of 65536 for thinking-mode models). Covers three recurring failure modes the implementer cannot detect on its own.

**workflow/**
- `skill-audit` — at every project retrospective, record "Skills used this project"; every 3 retrospectives, audit the aggregate and keep / modify / flag-for-review. Cure-side mirror of the Cortex retrospective's Insight #6 ("same trigger + same action → one skill, multiple bullets"): that insight is **add-time** discipline; this skill is **review-time** discipline against bloat that slips through. Counts surface candidates; the keep/delete call stays human. Source: user concern post-Cortex about preventing future skill bloat — preventive, not curative; package isn't bloated yet (13 skills) but the ritual exists before it matters.

### Modified
- `quality/non-negotiable-paths` — added "Encoding non-negotiables in code: RuntimeError, not assert" section. `assert` is stripped under `python -O`, silently removing load-bearing invariants in optimized builds. Use `raise RuntimeError(...)` instead.
- `quality/adversarial-review` — added three review patterns: numerical formulas derived from library metrics (re-derive from docs, don't trust the obvious shape); `assert` in non-test code for load-bearing checks; positional CLI arguments that accept user prose (`@click.argument("query")` without `nargs=-1` breaks on unquoted input).
- `workflow/pm-checklist` — added "Multi-phase projects: carry-forward and shrinkage" section. Late-phase checklists get an explicit carry-forward block of settled decisions; each phase's checklist should be roughly half the length of the prior.
- `templates/retrospective.md.example` — added "Skills used this project" section between "Friction log review" and "Skills changes proposed". Feeds the `skill-audit` aggregation.
- `retrospectives/2026-06-llm-gateway.md` and `retrospectives/2026-06-cortex.md` — backfilled "Skills used this project" sections so the first audit (3 retrospectives from now) has consistent data.

### Notes
- An earlier draft of this release proposed **four** new skills (`implementer-name-scope`, `library-gotcha-checklist`, `llm-implementer-max-tokens-floor`, `runtime-error-not-assert`). On review, three of the four shared the same trigger ("about to call implementer") and the same action ("extend the handoff prompt"); consolidated to one `implementer-handoff` skill with three sub-blocks. The fourth (`runtime-error-not-assert`) fit inside the existing `non-negotiable-paths` as a paragraph. This is documented as Insight #6 in the retrospective: **same trigger + same action → one skill, multiple bullets, not multiple skills**.
- Cortex used v0.2.0 throughout. The pm-checklist pattern validated mid-project (v0.2.0 entry) held up through Phases 2–4 — used 4 times, shrinkage worked, no rework.
- The implementer name-hallucination pattern (3 incidents across 3 phases) is the highest-leverage thing this release addresses. If `engineering/implementer-handoff` doesn't reduce that rate on the next project, the skill needs structural redesign — possibly an adversarial check ("can the implementer locate this function?") before code generation.

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
