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
- `skills/workflow/rigor-triage` — at the start of each task, pick the right process: full pipeline for critical code (payment/auth/data), one-shot vibe-code for cosmetic/reversible work (layout/copy); round up when unsure
- `skills/process/compact-or-clear` — tells you when to `/clear` vs `/compact` vs keep going, so long sessions don't bleed tokens + latency
- `skills/workflow/persist-load-bearing-findings` — a live-incident root cause or operational gotcha gets written to CLAUDE.md/memory in the SAME turn it's discovered, not just explained in chat

### Active for medium+ changes
- `skills/engineering/implementer-handoff` — every implementer LLM call must include Names-in-scope, Library-gotchas, Output-budget blocks
- `skills/workflow/decision-log` — surface decisions with confidence + reversibility
- `skills/workflow/scope-cut-list` — every plan explicitly lists features it excluded
- `skills/workflow/pm-checklist` — when a phase has 5+ PM decisions, produce `agents/planner/pm-checklist.md`
- `skills/workflow/spec-coach` — Socratic loop that auto-invokes on empty PM-owned spec sections; helps user fill blanks well without inventing
- `skills/quality/good-enough-rubric` — five-question review, not perfectionism
- `skills/quality/adversarial-review` — separate agent hunts for bugs (Critical / Major / Minor)
- `skills/quality/security-review` — for any project with a public attack surface + money/auth/PII: a dedicated threat-model pass (authz/IDOR, cookie/CSRF hardening, injection, secret leakage), distinct from adversarial-review and a hard gate before go-live. Run `/security-review` or a per-domain agent fan-out
- `skills/engineering/disable-flag-both-paths` — any disable/enable mechanism (feature flag, TTL=0, `--dry-run`) applies to every path it affects, not just the obvious one
- `skills/engineering/boring-tech` — default to widely-used, well-documented, easy-to-swap tools; justify any non-default choice in the decision log
- `skills/workflow/feasibility-first` — before committing to a new external dependency the project's value hinges on, run the cheapest probe to confirm it's usable before building around it
- `skills/workflow/agent-journal` — for non-trivial changes, close with a short reflection (certain vs. uncertain vs. judgment calls) so risky lines get flagged before they become bugs
- `skills/engineering/component-library` — before payment/auth/db/concurrency/llm-integration/external-integration work, read `components/<domain>/ANTIPATTERNS.md` first, then `PATTERNS.md` for the reference shape. See `components/README.md`.

### Active for large features (>6 files)
- `skills/process/split-run-implementation` — partition into dependency-ordered parts of 3–4 files each; avoids silent mid-file token truncation

### Active for end-of-project
- `skills/workflow/retrospective` — end-of-project lessons; commit to a public or local Arcanium retrospectives folder
- `skills/workflow/skill-audit` — list "Skills used this project" in the retrospective

> **Note on skill updates**: Skills are frozen at the version stamped in `skills/README.md`. A central Arcanium update will NOT propagate to this project. To re-sync: run `install.sh --local "$(pwd)" --force` from your Arcanium checkout. Frozen skills are a feature, not a bug — a v0.5.0 change shouldn't retroactively break a project that worked under v0.4.0.

## Spec gap discipline

When working on or reviewing `spec/spec.md`, treat empty sections as **gaps to flag**, not blanks to fill.

| Section type | Empty-section behavior |
|------|------|
| **PM-owned** (§1 What it is, §2 User stories, §6 Non-negotiables, §8 Success criteria) | **Invoke `skills/workflow/spec-coach` by default.** Ask Socratic questions, record user's answers progressively as `[DRAFT FROM COACH SESSION]`, never invent. User can say "skip §X" to opt out — then mark `[GAP — PM input needed]`. Do NOT invent under any circumstance. |
| **Engineering-owned** (§3 Architecture, §4 Data model, §5 Interface) | **Draft a strawman** based on PM-owned answers. Mark `[DRAFT — please review]`. |
| **Collaborative** (§7 Phase plan, §9 Out of scope) | **Propose options.** Don't decide. Output choices for the user to pick. |

### Two signals before deciding "empty section"

1. **Is the PM checklist filled?** If yes, apply stated defaults (silence = accept-default per `pm-checklist`). Transcribing checklist answers into the spec is NOT inventing — it's recording decisions already made.
2. **Is a default stated anywhere?** Checklist, prior conversation, prior spec section. If a default exists, apply it. If no default exists, the section is a true gap.

### What this prevents

- Confabulated §1s ("This is a tool that does <plausible-sounding thing>")
- Invented user stories the user didn't validate
- Made-up non-negotiables that become load-bearing in code
- Phase plans built on quiet inventions; errors compound silently and surface at Phase 3

### Related skills
- `skills/workflow/spec-first` — spec is the source of truth; this is the start-of-project application
- `skills/workflow/pm-checklist` — the explicit mechanism for surfacing PM-owned decisions
- `skills/workflow/spec-coach` — Socratic loop to help the user fill PM-owned blanks well (auto-invoked above)

---

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
├── components/               ← via-negativa domain knowledge (payment/auth/db/concurrency/
│                                llm-integration/external-integration); read ANTIPATTERNS.md
│                                before PATTERNS.md, see skills/engineering/component-library.md
├── src/{{PROJECT_SLUG}}/     ← code
└── tests/                    ← pytest
```
