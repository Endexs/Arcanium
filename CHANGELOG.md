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

## v0.7.0 — 2026-07-02
After: two user-driven requests during airbnb-website (Phase 6 build). (1) Long agentic sessions (multi-phase implement → adversarial review → fix loops) accumulate large tool outputs and several finished tasks in one thread; the user was paying full-context cost + latency on every turn without a clear signal for when to reset. (2) The user wanted an explicit gate for *how much process* a change deserves — full pipeline for payment-grade code, one-shot vibe-code for layout — so rigor stops being an implicit per-task guess.

### Added
- `process/compact-or-clear` — the agent proactively advises **`/clear`** (task done + unrelated next work), **`/compact`** (same task, bloated history — checkpoint first), or **keep going** (still lean), with a `/context`-based threshold (~80%) and a "checkpoint the next step before resetting" rule. Session-level sibling of `split-run-implementation` (which manages tokens *within* one large change).
- `workflow/rigor-triage` — front-of-task router that picks **Vibe (one-shot)** / **Standard** / **Full pipeline** by *blast radius × reversibility × criticality*, not by lines of code. Routes the top tier into `[[non-negotiable-paths]]` (the floor) and keeps the bottom tier out of `[[good-enough-rubric]]`-violating over-process. Rules: criticality pre-check, "the dial is on the change not the file," round-up-when-unsure, and state the call as `Rigor: <tier> — <reason>` so the user can override before work starts.

### Modified
- `starter/CLAUDE.md` + `templates/CLAUDE.md.example` — listed `process/compact-or-clear` under **Always active** (session hygiene applies regardless of change size).
- `README.md` — added to the `process/` catalog.
- `bin/arcanium-new` — vendor loop now includes `process/` (was `workflow engineering quality` only). **Latent-bug fix:** `arcanium-new` never copied `process/` into bootstrapped projects, so `process/split-run-implementation` silently never shipped via the recommended path even though `templates/CLAUDE.md.example` referenced it. Now `process/` ships too.

### Notes
- **Why minor (0.7.0) not patch:** two new skills added. Existing projects don't get them automatically (frozen-at-bootstrap vendor model); pull with `install.sh --local <project> --force`.
- **Category choices:** `compact-or-clear` → `process/` (a token/latency tactic; pairs with `split-run-implementation`). `rigor-triage` → `workflow/` (a collaboration/meta-process gate; it's the router that sits in front of `non-negotiable-paths` and `good-enough-rubric`).
- **Both also ship as slash-invocable skills:** `~/.claude/skills/{compact-or-clear,rigor-triage}/SKILL.md` (Claude Code format) were created user-level so `/compact-or-clear` and `/rigor-triage` work on demand in any project; the Arcanium copies make the *guidance* active-by-default in every bootstrapped project (invoke vs. always-on).
- **`rigor-triage` relationship to existing skills:** it does not replace `non-negotiable-paths` — it *routes into* it. non-negotiable-paths answers "which paths are always Full"; rigor-triage answers "for THIS change, which tier — and it defers to that list for the top tier." good-enough-rubric guards the bottom tier from over-processing.

---

## v0.6.0 — 2026-06-30
After: user-driven gap (not retrospective-driven). User feedback during v0.5.x usage: *"me just writing it by myself I don't think is that effective without the necessary technical knowledge."*

### Added
- `workflow/spec-coach` — Socratic loop that auto-invokes on empty PM-owned spec sections (§1 What this is, §2 User stories, §6 Non-negotiables, §8 Success criteria). Agent asks 1–2 open questions per round, records user answers progressively into `spec.md` as `[DRAFT FROM COACH SESSION]`, never invents content. Soft cap at 5 question rounds per section, then "keep refining or move on?" Ship-default question banks per section; anti-leading discipline explicitly prohibits "most projects pick X" steering. User can `skip §X` to opt out — section reverts to `[GAP — PM input needed]`.

### Modified
- `starter/CLAUDE.md` — gap-discipline rule for PM-owned blanks updated from "flag as `[GAP]`" to "invoke `spec-coach` by default; `[GAP]` only on user opt-out." This is the cure side of gap-discipline: blocking invention is necessary but not sufficient; helping the user fill the blank well closes the loop.
- `templates/CLAUDE.md.example` — same change in the retrofit template.
- `workflow/spec-first` — cross-references `[[spec-coach]]` in the empty-sections subsection; clarifies that gap-discipline + coach bracket invention from both sides.

### Notes
- **Why minor (0.6.0) not patch:** new skill added, plus default agent behavior on empty PM sections changes meaningfully. Existing v0.5.x projects do NOT get this automatically (vendor model — frozen at bootstrap). To pull: `install.sh --local <project> --force`.
- **Default-on, not opt-in:** user explicitly requested default behavior (option 3 in the design proposal), with confidence they would benefit from frequent help. Trade-off: an agent that grills you when you didn't ask for it can feel intrusive. Escape hatch is `skip §X`; if intrusiveness becomes a complaint, downgrade to explicit-invocation-only in v0.7+.
- **Composes with `pm-checklist`:** checklist is for *"I know what I want, just record it."* Coach is for *"I don't yet."* Different moments. Coach explicitly checks for a filled checklist BEFORE grilling — transcribing answers from the checklist is not invention and not coaching.
- **Composes with `feasibility-first`:** one §6 coach question is *"what external dependency does this rely on?"* — the answer feeds the feasibility probe directly. The two skills caught complementary halves of the airbnb-llm-chat failure mode (feasibility caught the un-verified integration; coach would have caught the vague non-negotiable that hid the dependency in the first place).

---

## v0.5.0 — 2026-06-27
After project: airbnb-llm-chat  (see retrospectives/2026-06-airbnb-llm-chat.md)

### Added
- `workflow/feasibility-first` — validate a project's load-bearing external dependency with the cheapest possible probe BEFORE writing the spec. On airbnb-llm-chat the entire value was sending replies into Airbnb; that integration was validated *last*, after a full pipeline (spec → plan → DeepSeek impl → adversarial review → fix → commit Phase 1). A 2-minute email-header check (`Reply-To: noreply@airbnb.com`) would have killed the project on day one. The "ship value early, defer the hard integration" heuristic is backwards when the deferred risk IS the core value.

### Modified
- `workflow/spec-first` — a `[CONFIRMED]` tag on any decision touching an external system now requires a verification source; without one it must be `[ASSUMED — unverified]` and treated as Phase-0 work. Closes the airbnb hole where "replies reach the guest via SMTP" was stamped CONFIRMED on the strength of the user *wanting* it, never a test.
- `workflow/decision-log` — added a third axis, **Validated** (external-facing decisions only), and a validated-and-load-bearing override: if `Validated = no` and the project depends on the capability, it's an automatic STOP regardless of confidence/reversibility. Catches the case the old confidence×reversibility table missed (high confidence + easy reversibility still auto-approved an unverified, load-bearing assumption).

### Notes
- These three changes are defense in depth for one failure mode: `feasibility-first` is the proactive probe; the `spec-first` and `decision-log` edits are the safety nets that catch a skipped probe at spec-writing and planning time respectively.
- Two techniques that worked well and need no change: `engineering/implementer-handoff` (zero hallucinated names across two DeepSeek handoffs — negative assertions earned their rent) and `quality/adversarial-review` (all 2C/2M/9N Phase-1 findings were real). The failure was upstream of the build, in not gating on feasibility.

## v0.4.2 — 2026-06-25
After: in-flight clarification (user-driven, not retrospective-driven).

### Added
- `starter/CLAUDE.md` — new "Spec gap discipline" section. Tells the session-start agent how to handle empty `spec/spec.md` sections: PM-owned blanks get flagged as `[GAP]`, engineering-owned blanks may be drafted as `[DRAFT]`, collaborative blanks propose options rather than decide. Two signals (PM checklist filled? default stated anywhere?) determine whether transcription is allowed vs invention forbidden.
- `templates/CLAUDE.md.example` — same gap discipline section, condensed format, for projects that retrofit Arcanium via `install.sh`.
- `workflow/spec-first` — extended "When the spec is ambiguous" with a new "When the spec has empty sections (start-of-project)" subsection. Skill-index now reflects the discipline; CLAUDE.md remains the canonical session-start location.

### Notes
- Surfaced by a user question: *"if I leave a spec section blank, will the LLM fill it for me?"* Right answer is "no, and it shouldn't" — but the rule wasn't written down anywhere a session-start agent would read it. Writing it down closes the gap.
- Distinct from `workflow/spec-first`'s existing "When the spec is ambiguous" subsection: that one covers ambiguity discovered *during implementation*; this one covers *empty sections at project start*. Different timing, related discipline, separate prompts.
- Why CLAUDE.md is the primary location: agents read CLAUDE.md every session start. Skill files are loaded on demand when referenced. Critical session-time rules earn the always-loaded slot.
- Existing v0.4.1 projects do NOT get this update automatically (vendor model — frozen at bootstrap). To pull it: `install.sh --local <project> --force`.
- This is the third v0.4.x patch in two days. Cadence is unusual for a stable methodology package — it's high because we're using the methodology in earnest for the first time and the gaps are surfacing fast. Expect this rate to drop as the package matures.

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
