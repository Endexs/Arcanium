# Solo Dev Agent Skills Package

A set of reusable skills extracted from building the LLM Gateway project with a multi-agent workflow. Tuned for solo developers who want agents to handle most architectural decisions while preventing common failure modes.

**Current version**: see `VERSION`
**Changelog**: see `CHANGELOG.md`
**How to keep this sharp over time**: see `LOOP.md`

## How to use

### Starting a new project — `arcanium-new` (recommended)

One command bootstraps an entire project from the canonical `starter/` scaffold:

```bash
# One-time: put the script on your PATH
sudo ln -s "$(pwd)/bin/arcanium-new" /usr/local/bin/arcanium-new

# Then, from anywhere:
arcanium-new hello-rag
```

What you get at `/home/developer/projects/hello-rag/`:
- Pre-filled `CLAUDE.md` referencing the active Arcanium skills
- `spec/spec.md` skeleton with all 9 §-sections
- `agents/planner/pm-checklist.md` with 10 sections of PM decisions
- `agents/planner/plan-template.md` with `implementer-handoff` blocks ready to fill
- `agents/reviewer/review-template.md` with the Critical/Major/Minor structure
- `.claude/agents/fixer.md` (Haiku subagent for applying review findings)
- `.claude/bin/omni-send` (single-gateway wrapper — every provider via OmniRoute, no Python venv dep)
- `components/{payment,auth,db,concurrency,llm-integration,external-integration}/` (via-negativa domain knowledge — read a domain's
  `ANTIPATTERNS.md` before implementing in it; see `engineering/component-library.md`)
- `tests/conftest.py`, `pyproject.toml`, `.gitignore`, `src/<package>/__init__.py`
- A clean `.venv/` with pytest installed
- `git init` on `main`, one commit

Read `bin/README.md` for full flag reference.

### Adding Arcanium to an existing project — `install.sh`

If you already have a project and want to retrofit the skills into it:

```bash
# Install globally to ~/.claude/skills/ (one-time setup)
./install.sh

# Or install into a specific existing project (skills + templates + components)
./install.sh --all /path/to/your-project

# Other modes
./install.sh --local /path/to/your-project        # skills only
./install.sh --templates /path/to/your-project    # templates only
./install.sh --components /path/to/your-project   # domain components only (payment/auth/db)
./install.sh --dry-run --all /tmp/preview         # preview without writing
./install.sh --help                               # see all options
```

The installer is idempotent — re-running skips existing files unless you pass `--force`.

### Using with Pi

This package was built for Claude Code, but two of its three layers carry over to
[Pi](https://pi.dev) directly, and the third converts with one command:

- **Context files** — `templates/CLAUDE.md.example` works unmodified. Pi loads `CLAUDE.md`/`AGENTS.md`
  natively from cwd, parent directories, and `~/.pi/agent/AGENTS.md` (global), same as Claude Code.
  No conversion needed; just `cp templates/CLAUDE.md.example <project>/CLAUDE.md` (or use
  `install.sh --templates`).
- **Skills** — Pi's skill loader requires YAML frontmatter (`name` + `description`) per the
  [Agent Skills standard](https://agentskills.io/specification); this package's `workflow/`,
  `engineering/`, `quality/`, `process/`, `lifecycle/` files are plain prose without it, so Pi can't
  discover them as-is. Convert + install with:
  ```bash
  ./install.sh --pi                       # global: ~/.pi/agent/skills/<category>/<name>/SKILL.md
  ./install.sh --pi-local /path/to/project  # project-local: <project>/.pi/skills/...
  ./install.sh --pi --dry-run             # preview without writing
  ```
  This runs `bin/convert-skills-to-pi.py`, which copies each skill's body verbatim into its own
  `<name>/SKILL.md` and derives `description` from the file's `## Rule` section. Restart `pi` (or
  run `/reload`) afterward. If you also use Claude Code, point Pi at your existing `~/.claude/skills`
  instead of duplicating (see Pi's `docs/skills.md`, "Using Skills from Other Harnesses") — just be
  aware the two won't be byte-identical unless you regenerate.
- **Agent pipeline (planner → implementer → reviewer → fixer)** — Pi has no built-in sub-agents by
  design. Since this package's pipeline already hands off through files on disk rather than chat
  (see `WORKFLOW.md`), it maps onto separate `pi -p` invocations per role instead of Claude Code
  subagents: e.g. `pi --model <planner-model> -p "Read spec/spec.md, write agents/planner/phase1-plan.md"`,
  then a fresh `pi --model <implementer-model> -p "Implement agents/planner/phase1-plan.md"`, etc.
  `.claude/agents/fixer.md` becomes a prompt template (`--append-system-prompt` or `.pi/prompts/`)
  rather than a Claude Code subagent definition.
- **MCP** — not required by this package; skip it. Pi has no MCP client by design (see Pi's README
  "Philosophy" section) but skills/extensions can add one if a project needs it.

### Manual install

For a global skills library referenced by all your projects:
```
~/.claude/skills/          ← copy categorized folders here
```

Then reference them in your project's CLAUDE.md (see `templates/CLAUDE.md.example`).

## Categories

### workflow/ — meta-process for working with agents
Skills that shape how you and the agent collaborate. Apply these regardless of what you're building.

- **feasibility-first.md** — prove the project's load-bearing external dependency before writing the spec, not after shipping a phase
- **spec-first.md** — write intent before code; spec is the source of truth
- **rigor-triage.md** — at the start of a task, pick full-pipeline vs standard vs one-shot vibe-code by criticality (blast radius × reversibility), not by size
- **model-routing.md** — then pick the model tier by complexity and verifiability: complexity sets the floor, criticality only raises it, and you may route down only when a gate or test will catch the failure
- **gate-first-validation.md** — on Full-tier work, author an executable acceptance gate *before* implementing, prove it red, freeze it, then loop build→gate until green or a bounded halt
- **model-fusion.md** — on a high-stakes fork, N models (2–3, distinct families) solve the same problem in parallel and a blind merger reconciles them with consensus/divergence provenance
- **spec-coach.md** — Socratic loop that auto-invokes on empty PM-owned spec sections; helps user fill blanks well without inventing
- **pm-checklist.md** — when a spec has 5+ PM-owned decisions, produce a checklist file instead of asking inline
- **decision-log.md** — agent surfaces decisions with confidence + reversibility, and names the specific risky lines
- **scope-cut-list.md** — every plan explicitly lists features it excluded

### engineering/ — reflexive code-level conventions
Defensive patterns the implementer should apply without being asked.

- **defensive-defaults.md** — input validation, timeouts, transactions, logging
- **boring-tech.md** — bias toward proven, widely-used choices
- **preserve-existing.md** — never wholesale rewrite files; preserve undocumented patterns
- **disable-flag-both-paths.md** — TTL=0, --no-cache, feature flags apply to read AND write
- **implementer-handoff.md** — pre-handoff prompt blocks: names in scope, library gotchas, output budget
- **component-library.md** — before payment/auth/db work, read that domain's `components/<domain>/ANTIPATTERNS.md` first; a pattern may only be added in direct response to a cited antipattern

### quality/ — review and verification standards
Rubrics the reviewer (or you) apply to judge "is this good enough to ship?"

- **good-enough-rubric.md** — 5 questions instead of perfectionism
- **adversarial-review.md** — specific failure modes to hunt for
- **non-negotiable-paths.md** — code paths that always get full review

### process/ — operational practices
Tactical patterns for running the agent fleet efficiently.

- **split-run-implementation.md** — partition large changes to avoid token truncation
- **compact-or-clear.md** — advise when to `/clear` vs `/compact` vs keep going, so long sessions don't bleed tokens + latency

### lifecycle/ — making knowledge durable
Skills that fire *around* the work rather than during it: capturing what was learned so it survives
the session and improves the package. `workflow/` is what you do on a task; `lifecycle/` is what
outlives it.

- **persist-load-bearing-findings.md** — a live-incident root cause or operational gotcha gets written to CLAUDE.md/memory the same turn it's discovered, not just explained in chat
- **retrospective.md** — capture failures so they don't repeat across projects
- **skill-audit.md** — periodic pruning ritual to keep the package slim

### components/ — domain knowledge, via negativa first
A different kind of artifact than the process skills above: recurring, sourced knowledge about
*specific* subsystems (payment, auth, database) every project rebuilds from scratch. Each domain
is a pair of files, and the order is the discipline — `ANTIPATTERNS.md` (what has actually
broken, and why — written first) and `PATTERNS.md` (the reference shape, written second, only in
direct response to a cited antipattern). See `components/README.md` and
`engineering/component-library.md` for the full rule and how new entries get added.

- **payment/** — gateway integration, refunds, idempotency, money-amount computation
- **auth/** — credential verification, session signing, constant-time comparison
- **db/** — schema evolution, transaction/locking discipline, test-fixture connection sharing
- **concurrency/** — DB locks across network calls, blocking I/O in async routes, single-writer
  guards, and how to tell whether a concurrency test can actually fail
- **llm-integration/** — token-truncation floors, vector-similarity conventions, grounding/
  citation gates, streaming-response defensiveness, provider-swap architecture
- **external-integration/** — validating a third-party dependency before building on it, redirect
  re-validation, webhook signature verification

### templates/ — starting points for new projects
- **CLAUDE.md.example** — composable project-level skill reference
- **spec.md.example** — minimal spec structure
- **system-prompt-implementer.md** — implementer agent system prompt
- **system-prompt-reviewer.md** — adversarial reviewer agent system prompt
- **retrospective.md.example** — end-of-project template (feeds the improvement loop)
- **friction.md.example** — during-project scratchpad for capturing skill gaps

### retrospectives/ — per-project lessons learned
One file per project, named `YYYY-MM-<project>.md`. These are the inputs to skill changes — every CHANGELOG entry references a retrospective. See `retrospectives/2026-06-llm-gateway.md` for an example of what good looks like.

**Retrospectives are local-only by default.** `retrospectives/.gitignore` keeps every retro on your machine except `README.md` and the project-zero example. This lets you write candidly about sensitive projects (clients, business reasoning, internal bugs) without committing to making it public. The CHANGELOG still references retros by filename — the trail of "we learned X, so we changed Y" stays visible even when the source documents don't. To publish a specific retro, add a `!filename.md` line to `retrospectives/.gitignore`.

## Starter recommendation

Don't activate all skills on day one. Start with these five:

1. **engineering/defensive-defaults** — prevents the bugs you can't diagnose
2. **engineering/preserve-existing** — prevents agent-induced regressions
3. **workflow/spec-first** — gives you a source of truth
4. **quality/good-enough-rubric** — prevents gold-plating, helps you ship
5. **quality/non-negotiable-paths** — tells you when to slow down

Add more only when you hit a problem the existing skills didn't prevent.

## Continuous improvement

This package is designed to absorb lessons from every project you ship. After each project:

1. Copy `templates/retrospective.md.example` to `retrospectives/YYYY-MM-<project>.md`
2. Fill it in honestly — especially "what failed" and "skills changes proposed"
3. If a root cause is domain-specific (payment, auth, db, ...), append the sourced antipattern
   to `components/<domain>/ANTIPATTERNS.md` **as part of this step**, before it's considered
   proposed-changes-applied — see `engineering/component-library.md`
4. Apply the proposed changes to skill files
5. Bump `VERSION` and add a `CHANGELOG.md` entry referencing the retrospective
6. Commit

The full ritual is in `LOOP.md`. The short version: every bug that ships is a test you didn't write — and every retrospective without a skill change is theater.

## What this package is NOT

- Not a framework. These are conventions, not code.
- Not exhaustive. Add your own skills as you learn from your own failures.
- Not opinionated about tech stack. Skills apply to Python, Node, Go, etc.
- Not a substitute for judgment. Agents follow these rules; you decide when to override them.

## Provenance

Every skill in this package came from a real bug or workflow problem encountered while building the LLM Gateway project. See each skill's "Why this exists" section for the specific incident that motivated it.
