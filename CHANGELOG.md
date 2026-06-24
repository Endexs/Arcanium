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

## v0.4.1 — 2026-06-24
After: portability bug surfaced minutes after v0.4.0 shipped.

### Fixed
- `bin/arcanium-new` now vendors `workflow/`, `engineering/`, and `quality/` into the new project's `skills/` directory, instead of leaving the project pointing at the central Arcanium checkout. Projects bootstrapped before v0.4.1 had a hardcoded path (`/home/developer/projects/solo-dev-agent-skills/`) in their `CLAUDE.md`, which only resolved on the VPS where Arcanium was installed. Cloning the project elsewhere broke the agent's skill load.
- `starter/CLAUDE.md` updated to reference `skills/<category>/<name>` (project-relative) instead of the central absolute path.
- A `skills/README.md` is generated at bootstrap noting the source Arcanium version and the resync command, so future-you can tell which skill release a given project was built against.

### Design note: vendor vs reference

Considered both:
- **Vendor** (chosen): copy skills into the project at bootstrap; frozen at that version
- **Reference**: project points at the central Arcanium path

Vendor wins for solo dev on multiple machines because: portable, self-contained on clone, and stable against central updates. The "central updates" win for reference is actually a liability — a v0.5.0 skill change shouldn't retroactively affect a v0.4.x project that was working. `install.sh --local --force` is the explicit resync path for projects that want to pull updates.

### Notes
- v0.4.0 was viable for ~hours before the user spotted the portability gap. Patch release, not minor — no new features, just a correctness fix.
- Existing projects bootstrapped under v0.4.0 are NOT auto-migrated. To migrate one: `./install.sh --local /path/to/old-project` then update its `CLAUDE.md` to use `skills/` prefix paths.

---

## v0.4.0 — 2026-06-24
After: in-flight observation (not a project retrospective). See "Notes" below.

### Added
- `starter/` — canonical project scaffold copied wholesale into new projects. Contains a pre-filled `CLAUDE.md` with the active-skills set, a 9-section `spec/spec.md` skeleton, a Phase-1 `pm-checklist.md` skeleton, plan and review templates with the v0.3.0 `engineering/implementer-handoff` blocks baked in, `.claude/agents/fixer.md` and `.claude/bin/ds-send` (the Haiku fixer and DeepSeek wrapper from the Cortex project), basic `tests/conftest.py`, and a `pyproject.toml` skeleton. Placeholders: `{{PROJECT_SLUG}}`, `{{PROJECT_SLUG_UNDERSCORE}}`, `{{PROJECT_NAME}}`, `{{TODAY}}`.
- `bin/arcanium-new` — bootstrap script. `arcanium-new <slug> [--name NAME] [--dir DIR] [--force]` copies `starter/` to the target, substitutes placeholders, renames the `src/{{PROJECT_SLUG_UNDERSCORE}}/` package directory, creates `.venv/`, installs dev deps, `git init`s on `main`, and makes the initial commit. Validates slug as lowercase kebab-case. Refuses to overwrite an existing target unless `--force`.
- `bin/README.md` — bin/ documentation.

### Modified
- (none — this release is purely structural; no skill changes)

### Notes
- This is **not** a release driven by a project retrospective. It's an in-flight observation that the methodology walkthrough we'd been giving to users ("step 1: mkdir, step 2: cp, step 3: ...") was 9 manual steps when it should be one command. Arcanium's purpose is to remove that friction, not just describe it.
- Why a structural release without a skill change: the existing skills already cover the workflow correctly. The gap was infrastructural — a missing front door. **No retrospective is required to motivate infrastructure** — only to motivate skills, which are process rules. Distinction codified here for the next time this question comes up.
- The starter pulls forward two artifacts from the Cortex project: `.claude/bin/ds-send` and `.claude/agents/fixer.md`. Both have been validated through 3 implementation phases of Cortex; promoting them from "thing Cortex has" to "thing every Arcanium project starts with" is the natural next step.
- `bin/arcanium-new` is intentionally bash, not Python. Bootstrapping a Python project from a Python script that requires its own environment is a chicken-and-egg problem; bash + standard utilities works on any POSIX shell with no setup.
- The `bin/` directory is new in this release. Future Arcanium tooling (e.g., `arcanium-retro` to start a retrospective from the template, `arcanium-audit` to run the 3-project skill audit) would live here.

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
