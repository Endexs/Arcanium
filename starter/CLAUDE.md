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
- `skills/workflow/model-routing` — then pick the model tier (T1/T2/T3) by complexity and verifiability, never by diff size. Complexity sets the floor; criticality only raises it. Route down only when a gate/test will catch failure. State both: `Rigor: Standard · Model: T2 — <reason>`
- `skills/process/compact-or-clear` — tells you when to `/clear` vs `/compact` vs keep going, so long sessions don't bleed tokens + latency
- `skills/lifecycle/persist-load-bearing-findings` — a live-incident root cause or operational gotcha gets written to CLAUDE.md/memory in the SAME turn it's discovered, not just explained in chat

### Active for medium+ changes
- `skills/engineering/implementer-handoff` — every implementer LLM call must include Names-in-scope, Library-gotchas, Output-budget blocks
- `skills/workflow/decision-log` — surface decisions with confidence + reversibility
- `skills/workflow/scope-cut-list` — every plan explicitly lists features it excluded
- `skills/workflow/pm-checklist` — when a phase has 5+ PM decisions, produce `agents/planner/pm-checklist.md`
- `skills/workflow/spec-coach` — Socratic loop that auto-invokes on empty PM-owned spec sections; helps user fill blanks well without inventing
- `skills/quality/good-enough-rubric` — five-question review, not perfectionism
- `skills/quality/adversarial-review` — separate agent hunts for bugs (Critical / Major / Minor)
- `skills/quality/security-review` — for any project with a public attack surface + money/auth/PII: a dedicated threat-model pass (authz/IDOR, cookie/CSRF hardening, injection, secret leakage), distinct from adversarial-review and a hard gate before go-live. Run `/security-review` or a per-domain agent fan-out
- `skills/workflow/gate-first-validation` — Full-tier work only: author an executable acceptance gate BEFORE implementing, prove it fails red, freeze it (the builder may never edit it), then loop build→gate until green or halt after N=3. Runs before adversarial-review, not instead of it
- `skills/workflow/model-fusion` — high-stakes forks only (architecture, non-negotiable paths): 2–3 models from **distinct families** solve the same problem in parallel; an authorship-blind merger reconciles with consensus/divergence provenance. Costs 2–3×, so budget it to forks that are expensive to get wrong. Roster lives in the Model roster block below
- `skills/engineering/disable-flag-both-paths` — any disable/enable mechanism (feature flag, TTL=0, `--dry-run`) applies to every path it affects, not just the obvious one
- `skills/engineering/boring-tech` — default to widely-used, well-documented, easy-to-swap tools; justify any non-default choice in the decision log
- `skills/workflow/feasibility-first` — before committing to a new external dependency the project's value hinges on, run the cheapest probe to confirm it's usable before building around it
- `skills/engineering/component-library` — before payment/auth/db/concurrency/llm-integration/external-integration work, read `components/<domain>/ANTIPATTERNS.md` first, then `PATTERNS.md` for the reference shape. See `components/README.md`.

### Active for large features (>6 files)
- `skills/process/split-run-implementation` — partition into dependency-ordered parts of 3–4 files each; avoids silent mid-file token truncation

### Active for end-of-project
- `skills/lifecycle/retrospective` — end-of-project lessons; commit to a public or local Arcanium retrospectives folder
- `skills/lifecycle/skill-audit` — list "Skills used this project" in the retrospective (this section is the audit's only real input — omitting it makes the project invisible to every future audit)

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

| Phase | Tier (floor) | Artifact |
|------|------|------|
| PM decisions | (user, async) | `agents/planner/pm-checklist.md` |
| Plan | **T3** | `agents/planner/phaseN-plan.md` |
| Gate author | **≥ implementer tier** | the frozen acceptance gate |
| Implement | **T2** (T1 only if verifiable + non-critical; T3 on non-negotiable paths) | code |
| Review | **≥ implementer tier, different family** | `agents/reviewer/phaseN-review.md` |
| Fix | **T1** | code (`.claude/agents/fixer.md`) |

These are **floors**, not fixed assignments — `skills/workflow/model-routing` picks the actual tier
per task from complexity and verifiability, and may only route *up* from here.

### Model roster

The **only** place models are named. Serves `skills/workflow/model-routing` (tiers) and
`skills/workflow/model-fusion` (roster). Update when the frontier moves; the skills themselves name
roles, never vendors. Every id routes through one gateway (OmniRoute) via `.claude/bin/omni-send` —
no per-vendor wrapper. List what's actually available with:

```bash
curl -s http://localhost:20128/v1/models | jq -r '.data[].id' | sort
```

```
MODEL_TIERS:              # routing ladder — see skills/workflow/model-routing
  T1: claude/claude-haiku-4-5-20251001    # cheap/fast — mechanical, specified, verifiable
  T2: deepseek/deepseek-v4-pro            # mid — normal work against a clear plan
  T3: claude/claude-opus-4-8              # frontier — reasoning, ambiguity, critical paths

FUSION_MODELS:            # 2-3 slots, each a DIFFERENT family (see the family rule below)
  - claude/claude-fable-5                 # Anthropic
  - openai/gpt-5.6-sol                    # OpenAI
MERGER: claude/claude-fable-5             # sees candidates with authorship stripped

PER_MODEL_OVERRIDES:      # the gateway unifies the endpoint, NOT the params
  claude/claude-fable-5:    { max_tokens: 65536, temperature: 0.2 }
  claude/claude-opus-4-8:   { max_tokens: 65536, temperature: 0.2 }
  deepseek/deepseek-v4-pro: { max_tokens: 65536, temperature: 0.2 }
  openai/gpt-5.6-sol:       { max_tokens: 65536 }   # reasoning model: NO temperature (rejects it)
```

**This roster runs at N=2**, so there is no quorum and no tiebreak — you get agree/disagree only.
When the two disagree, the merger **surfaces the disagreement to you**; it does not pick a winner.
Add a third family (e.g. `deepseek/deepseek-v4-pro`) if you want majority consensus instead.

`MERGER` shares a family with the first slot. That is permitted — the authorship-blind rule is the
mitigation — but if you want zero family affinity in the merge, point `MERGER` at a third family.

**`max_tokens` floor of 65536** for any thinking-mode model. Thinking burns ~24K silently before
content; smaller budgets truncate mid-file — which reads as a *model* failure but is a *config* one.

**Temperature is not universal.** Reasoning models reject any non-default value outright
(`does not support 0.2 ... only the default (1) value is supported`). `omni-send` therefore omits
temperature unless you pass it — set it per-model here, never globally.

**A tier is not a family.** T1/T2/T3 may all resolve to one vendor's line — fine for routing, but
**not** valid for fusion or for the reviewer's different-family rule. The gateway makes this trap
easy to fall into: `claude/*` and `cc/*` expose the *same* Anthropic models under two prefixes, so a
roster of `claude/claude-opus-4-8` + `cc/claude-sonnet-5` looks like two vendors and is one family.

**Prefer pinned ids over `auto/*` for anything critical.** OmniRoute's `auto/*` routes
(`auto/best-coding`, `auto/cheap`, …) pick a model for you and auto-fall-back across provider tiers.
That is convenient for T1/T2 work a gate will verify, but it directly conflicts with
`model-routing`'s **escalate-never-silently-downgrade** rule: a fallback from a frontier model to a
free-tier one is exactly the silent downgrade the skill forbids, and you cannot satisfy the
distinct-family guard when you don't know which family answered. Pin concrete ids for T3, for the
reviewer, and for every `FUSION_MODELS` slot.

If a tier or provider is unavailable (429/5xx), **escalate — never silently downgrade.** Fusion
continues at N−1 and says so in its provenance block; it never returns one model's answer as
consensus.

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
├── .claude/bin/omni-send     ← OmniRoute gateway wrapper (all providers)
├── components/               ← via-negativa domain knowledge (payment/auth/db/concurrency/
│                                llm-integration/external-integration); read ANTIPATTERNS.md
│                                before PATTERNS.md, see skills/engineering/component-library.md
├── src/{{PROJECT_SLUG}}/     ← code
└── tests/                    ← pytest
```
