# Retrospective: llm-gateway

**Dates**: 2026-05-26 → 2026-06-14
**Skills package version used**: n/a (this project IS the founding extraction)
**Outcome**: shipped (CLI tool, 132 tests, all 7 spec phases complete)
**Stack**: Python 3.11+, httpx, click, sqlite3, SSE for streaming

---

## TL;DR
Built a unified LLM proxy CLI across DeepSeek/OpenAI/Anthropic with caching, streaming, budget enforcement, and sessions. Used a four-model agent pipeline (Sonnet plan → Pro implement → Opus review → Sonnet fix). The pipeline worked, but every phase exposed at least one failure mode worth codifying into a reusable skill. Project zero's main deliverable isn't the gateway — it's the skills package extracted from it.

---

## What worked

- **Spec-first discipline** — every phase updated `spec.md` before any code. Whenever planner/implementer/reviewer disagreed, the spec was the tiebreaker. Without this, the workflow would have descended into contradictions by Phase 3.
- **Adversarial Opus review** — caught real bugs on every phase it ran. Phase 6 streaming review found 5 critical issues the implementer missed. Phase 7 review found 4 criticals including the double-close `ProgrammingError`. Friendly review wouldn't have caught these.
- **Atomic spec sections per phase** — numbered §11 (OpenAI), §12 (streaming), §13 (sessions). Each section became the contract for its phase. Made review trivial: "does the code match §13?"
- **Multi-model split (Sonnet plan / Pro implement / Opus review)** — different models bring different biases. Same model planning and reviewing would have shared blind spots.

## What failed

- **Phase 4: whole-file rewrite regression**. Implementer rewrote `cli.py` for caching and silently dropped a Phase 3 dashboard import fix. Tests failed, required a hot-fix. Root cause: implementer treated the plan as the complete file spec, not as a delta on existing state.
- **Phase 4: cache TTL=0 only disabled reads, not writes**. Spec said "TTL=0 disables caching." Implementer made `cache_get` return None when TTL=0 but `cache_put` still wrote rows. The cache table grew despite being "disabled."
- **Phase 6: silent token truncation**. Pro output stopped mid-test-file. No error, no warning. Caught by manual inspection. Required hand-writing the truncated tests.
- **Phase 7: same truncation again**. Despite knowing about Phase 6's truncation, the workflow didn't yet have infrastructure to detect or prevent it.
- **Phase 7: falsy-None cache bypass bug**. Implementer wrote `if history:` instead of `if history is not None:`. First-turn session (no prior history → `None`) bypassed the bypass. Opus review caught it.
- **Phase 7: `session_delete` double-close**. Early-return `conn.close()` plus `finally: conn.close()` produced guaranteed `ProgrammingError` on missing sessions.
- **Phase 7: `--provider`/`--model` declared `required=True`** blocked the spec-intended UX of "continue session without re-specifying provider." Reviewer caught it.

---

## Bugs caught after shipping

(Bugs found by manual demo at end of project, after main work done.)

| Bug | Skill that should have caught it | Existed? | Why it didn't fire |
|-----|----------------------------------|----------|--------------------|
| DeepSeek streaming `AttributeError: 'NoneType' object has no attribute 'get'` because `chunk["usage"]` was None | adversarial-review (null-payload patterns) | partial | Streaming SSE payload edge case not in the review pattern checklist |

Only one post-ship bug, found via the manual demo step rather than tests. Suggests the test suite was good but missed a real provider edge case (intermediate chunks with `"usage": null`).

---

## Friction log review

(No formal friction log was kept during this project — the workflow was being invented as we went. These are reconstructed from the retrospective and conversation history.)

- [missing-skill] No formal "before any code, check existing file for defensive patterns" rule. Required reactive fix after Phase 4.
- [vague-skill] Early plans didn't enumerate every disable-flag path. Caused TTL=0 bug.
- [missing-skill] No truncation detection. Pro output silently incomplete twice.
- [missing-skill] No agent journaling. Implementer made judgment calls (falsy-None, `required=True`) that it knew were ambiguous but didn't surface.
- [vague-skill] Adversarial-review prompt didn't enumerate specific failure patterns. Reviewer's coverage improved when given explicit pattern checklist mid-project.

---

## Skills used this project

(Backfilled for the skill-audit ritual. This project is the founding extraction — every v0.1.0 skill traces here, so the citations list IS the v0.1.0 skill list.)

- workflow/spec-first
- workflow/decision-log
- workflow/scope-cut-list
- workflow/agent-journal
- workflow/retrospective
- engineering/defensive-defaults
- engineering/boring-tech
- engineering/preserve-existing
- engineering/disable-flag-both-paths
- quality/good-enough-rubric
- quality/adversarial-review
- quality/non-negotiable-paths

---

## Skills changes proposed

Since this project is the founding extraction, every skill in v0.1.0 traces here. Listing them with their incident origins:

### New skills (all of v0.1.0)

**workflow/**
- `spec-first` — multiple phases proved this was the load-bearing discipline
- `decision-log` — implementer made architectural choices (caching strategy, session schema) without surfacing them; user only learned at review time
- `scope-cut-list` — Phase 4 implementer added unrequested features ("graceful degradation" on cache miss) that weren't in spec
- `agent-journal` — would have caught the Phase 7 `if history:` bug at write-time, not review-time
- `retrospective` — the meta-discipline; without it, none of these lessons would persist

**engineering/**
- `defensive-defaults` — the timeout/transaction/logging rules came from Phase 4 cache code that lacked them initially
- `boring-tech` — Phase 5 implementer suggested async DB pool; switched to plain sqlite3 connection per call; saved complexity
- `preserve-existing` — direct response to Phase 4 dashboard import regression
- `disable-flag-both-paths` — direct response to Phase 4 TTL=0 write-path bug

**quality/**
- `good-enough-rubric` — Phase 6 implementer over-engineered SSE buffering; reviewer flagged but had no rubric to point at
- `adversarial-review` — formalized after Phase 6 review found 5 criticals; pattern checklist added based on actual finds
- `non-negotiable-paths` — sessions and caching both qualify; would have triggered the full pipeline even for "small" changes

**process/**
- `split-run-implementation` — direct response to Phase 6 and Phase 7 token truncation; infrastructure built in final session

### Modify existing
n/a — initial version

### Delete
n/a — initial version

---

## Time spent

(Estimates; this project ran across multiple sessions over ~3 weeks.)

- **Total dev hours**: ~40 hours equivalent
- **Hours saved by skills**: n/a — skills were being created, not applied
- **Hours spent on skill ceremony**: ~6 hours (writing plans, running reviews, retros)
- **Net for THIS project**: ceremony was pure cost
- **Net for next project**: skills should save 5-10 hours of bug-fix time per project

The investment only pays back on project 2 and beyond. Project zero is always at a deficit.

---

## What I'd do differently next project

- Keep a `friction.md` from day one. Reconstructing it after the fact lost detail.
- Run the adversarial review with the specific pattern checklist from the start, not figured out mid-project.
- Use the split-run implementer from day one for any phase with >5 files.
- Add the agent-journal requirement to the implementer system prompt before the first phase, not after.

---

## Notes for future me

- The Sonnet → Pro → Opus → Sonnet pipeline is overkill for projects under ~10 files total. Use the lightweight workflow described in `boring-tech` / `good-enough-rubric` for small projects.
- The most surprising lesson: every "obvious" bug Opus caught was something the implementer *could have* flagged in an agent journal but didn't. Surfacing uncertainty proactively is cheaper than catching it adversarially.
- The skills are interlocking. `preserve-existing` alone wouldn't have prevented Phase 4's regression — it needed `spec-first` (so the implementer had a clear scope) and `agent-journal` (so unclear deletions would surface). The package is a system, not a checklist.
- Token cost compounded harder than expected. By Phase 7, each Pro run injected ~2500 lines of baseline. Future projects should add a `--context` flag for selective injection.

---

## Refinement ritual completed?

- [x] Bug archaeology done (mapped each shipped bug to a skill or skill gap)
- [x] Friction audit done (reconstructed retroactively)
- [x] Skill files created (v0.1.0)
- [x] CHANGELOG.md created with v0.1.0 entry
- [x] VERSION file at 0.1.0
- [x] Validated changes: every shipped bug from Phases 4/6/7 would have been caught by at least one skill in v0.1.0
