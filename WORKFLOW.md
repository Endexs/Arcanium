# The Workflow — what actually runs, and where

A map of the moving parts. Three systems are in play and **they do not overlap**. Most confusion
about this package comes from conflating them.

| System | What it is | Where it's active |
|---|---|---|
| **A. Session context** | Skills/plugins/MCP loaded into *your Claude Code session* | Every session, everywhere |
| **B. Project pipeline** | The planner→implementer→reviewer→fixer relay | Only inside a project made by `arcanium-new` |
| **C. Improvement loop** | Retrospective → skill change → version bump | Between projects (`LOOP.md`) |

---

## ⚠️ First, the thing that confuses everyone

**Arcanium's skills are not active while you edit Arcanium.**

This repo has no root `CLAUDE.md` and no `.claude/`. Skills are **vendored and frozen** into each
generated project at bootstrap — they are not a global install. So the package you are editing has
no effect on the session you are editing it in, and a change here does **not** propagate to any
existing project (that's deliberate: a v0.12.0 change shouldn't retroactively break a project that
worked under v0.11.0). To re-sync one project on purpose:

```bash
./install.sh --local /path/to/project --force
```

---

## System A — what's hot-loaded in a session

Skills and MCP tools load **on demand**, not up front — which is why dozens of skills cost only a
few thousand tokens of context.

| Layer | Source | Notes |
|---|---|---|
| Global memory | `~/.claude/CLAUDE.md` | Always on. Inlines the rigor-triage + compact-or-clear essentials so they apply without being invoked |
| User skills | `~/.claude/skills/` | Personal copies, currently `rigor-triage` + `compact-or-clear` |
| Plugins | `~/.claude/settings.json` → `enabledPlugins` | e.g. `stripe`, `frontend-design` — each ships its own skills and sometimes agents |
| Built-in skills | Claude Code itself | `dataviz`, `run`, `review`, `security-review`, `loop`, `schedule`, … |
| Project config | `<project>/CLAUDE.md` + `<project>/.claude/` | **This is where Arcanium lands** — only in generated projects |
| MCP servers | `~/.claude.json` / project `.mcp.json` | Tools appear as `mcp__<server>__<tool>` |

**Check reality, don't assume:** `/context` shows what's loaded, `/mcp` shows server auth state.
An MCP server that only exposes `authenticate` / `complete_authentication` is **not connected yet** —
those stubs are the login prompt, not the feature.

---

## System B — the project pipeline

Created by `arcanium-new <name>`, which vendors `./skills/`, `spec/spec.md`, `agents/planner/`,
`agents/reviewer/`, `.claude/agents/fixer.md`, a model wrapper in `.claude/bin/`, `components/`,
`tests/`, a `.venv`, and an initial commit.

**Agents hand off through files on disk, never through your chat.** That's the core design: the
implementer reads `phaseN-plan.md`, not the conversation. Artifacts are the interface.

```
0. TRIAGE       you + agent     rigor-triage  → Vibe | Standard | Full   (how much process?)
                                model-routing → T1 | T2 | T3            (which model?)
                                Full ⇒ every step below is mandatory
        ↓
1. PM           you (async)     agents/planner/pm-checklist.md
                                spec-coach fills PM-owned spec §s Socratically; never invents
        ↓
2. PLAN         planner         agents/planner/phaseN-plan.md
                                + decision-log entries + scope-cut-list
                                ↳ high-stakes fork? → model-fusion (sideways, not inline)
        ↓
  ─ GATE ─      validator       gate-first-validation: author gate, prove RED, freeze
        ↓
3. IMPLEMENT    implementer     code — reads the plan file
                                implementer-handoff blocks; mind the thinking-token floor
        ↓
  ─ GATE ─      run             green → step 4 · red → failure diff feeds back to 3
                                halt after N=3 → surface to human
        ↓
4. REVIEW       reviewer        agents/reviewer/phaseN-review.md — Critical/Major/Minor
                (adversarial)   + security-review if public surface + money/auth/PII
        ↓
5. FIX          fixer           code (.claude/agents/fixer.md)
```

### Why the roles use different models
Planning is heavier reasoning than its cost suggests. Implementation is bulk generation. Review must
be **independent** of the implementer — different context, and a different model family — or it
inherits the bug it's meant to catch. Fixing is mechanical.

The pipeline table gives each role a **tier floor**; `model-routing` picks the actual tier per task
and may only route *up* from it. The rule that keeps this safe: **route down only when something
will catch a failure** (a frozen gate, a test suite, a type checker). No gate ⇒ no down-tiering.

Models are named in **one** place — the **Model roster** in the project `CLAUDE.md`. Behind a single
gateway that's one wrapper plus a list of model ids; the skills themselves name roles, never vendors.

### The two sideways skills
- **`gate-first-validation`** wraps step 3 — it is not a step, it's a bracket around one.
- **`model-fusion`** fires at step 2 on high-stakes forks only, and returns a merged answer with
  provenance that becomes part of the plan. It costs 2–3×, so it is budgeted, not default.

---

## System C — the improvement loop

Full ritual in `LOOP.md`. Short version:

```
during project  →  friction.md          (capture, don't fix)
end of project  →  retrospective        (bug archaeology: which skill should have caught this?)
                →  skill change         (a retro that changes nothing is theater)
                →  domain root cause?   → components/<domain>/ANTIPATTERNS.md
                →  VERSION + CHANGELOG  (every entry cites its source)
                →  commit
```

Guardrails that keep the package from bloating: cap ~6 skills per category, delete anything that
hasn't fired in two projects, every skill traces to a real incident, and project-specific tweaks
live in the project's `CLAUDE.md` — never in the global skills.

`lifecycle/skill-audit` is the review-time instrument for this, run off the **"Skills used this
project"** section every retrospective must carry. That section is the audit's only real input —
when it's missing, the audit degrades to vibes, which the skill explicitly forbids.

---

## Where to look when something's unclear

| Question | File |
|---|---|
| What is each skill and why does it exist? | `README.md` |
| How do skills improve over time? | `LOOP.md` |
| What changed, when, and why? | `CHANGELOG.md` |
| What does a new project get? | `starter/` |
| How do I bootstrap / retrofit? | `bin/README.md`, `install.sh --help` |
| What has actually broken in this domain? | `components/<domain>/ANTIPATTERNS.md` |
