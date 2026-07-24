# Skill: Model Fusion

## Rule
On a **high-stakes fork** — an architecture decision, or any path in `[[non-negotiable-paths]]` —
have **N independent models (N ∈ {2,3})** attempt the *same* problem in parallel, then a separate
**merger** role reconciles their outputs into one result with explicit **provenance**: what they
agreed on (consensus), what only one saw (divergence, preserved not discarded), and what was rejected.
"AND, not OR" — combine the models' cognitive strengths instead of picking one. Because it costs
2–3× a single run, fusion is **budgeted to forks that are expensive to get wrong**, not a default.

## Why this exists
Adapted from the `/fusion` and `/opinion` patterns in the fusion-harness project (external idea,
cited for provenance). Our existing pipeline (plan → implement → review → fix) is a **relay**: each
model hands to the next, and no two ever solve the *same* problem independently. `[[adversarial-review]]`
is one model *critiquing* another's output — valuable, but it inherits the first model's framing.
Fusion is different: N models frame the problem independently, and disagreement between families is
the signal. Two checkpoints of the same family mostly agree; the *divergence* is what surfaces the
option a single model would never have raised.

## The roster (model-agnostic config — the only place a model is named)
The skill reasons about **roles**, never vendors. Actual models resolve from **one** config block in
the project's `CLAUDE.md` (or `.claude/models.md`) — the same **Model roster** that
`[[model-routing]]` reads its tiers from. Update it when the frontier moves; nothing else changes.

```
## Model roster  (update when frontier models change)
FUSION_MODELS:            # 2 or 3 slots, each a model-id string routed by OmniRoute
  - <model-id-A>          # e.g. a frontier reasoning model
  - <model-id-B>          # MUST be a different family than A
  - <model-id-C>          # optional 3rd, a different family again
MERGER: <model-id>        # strongest reasoner; reconciles — see blindness rule below
PER_MODEL_OVERRIDES:      # gateway unifies the endpoint, NOT the params
  <model-id-A>: { max_tokens: 65536, temperature: 0.2 }   # thinking-mode floor still applies
```

### A single gateway makes this one wrapper, not N
Because the gateway fronts every provider behind one OpenAI-compatible endpoint, the per-vendor
wrappers collapse into a single `.claude/bin/omni-send` — one `base_url`, one key, provider chosen
by the `--model` string. The roster is then a plain list of model-id strings. With the Workflow
tool, `parallel()` the roster and pass each id straight through; no vendor is hardcoded in the skill.

Two gateway behaviours bite here specifically:
- **Semantic auto-routes** (`auto/best-coding`, `auto/cheap`, …) are **invalid as fusion slots.** They
  pick and silently fall back across providers, so you cannot know which family answered — which
  makes the distinct-family guard below unenforceable. Pin concrete ids for every slot.
- **Params are not unified even though the endpoint is.** Reasoning models reject a non-default
  `temperature` outright; thinking models need the `max_tokens` floor. Carry both per-model in
  `PER_MODEL_OVERRIDES`, never as one global default.

## Invariants (guards, not suggestions)

### 1. ≥2 distinct model families — enforce it
A single gateway namespace makes family collisions frictionless: `claude-opus` + `claude-sonnet`
*look* like two models but are one family, and fusion's entire value is cross-family disagreement.
Worse, a gateway often exposes the **same** family under two different prefixes (e.g. `claude/*` and
`cc/*` for the same Anthropic models), so a roster can read as two vendors while being one. Guard it
explicitly — the gateway erased the friction (separate keys and wrappers) that used to enforce this
for free:

```
if distinct_families(FUSION_MODELS) < 2:
    raise RuntimeError("fusion roster is single-family — no genuine diversity; add another vendor")
```

### 2. The merger judges content, blind to authorship
Strip or randomize the "which model wrote this" labels before the merger sees the candidates, so it
reconciles on *merit* and doesn't rubber-stamp its own family's answer. The merger is a role; it may
share a model with a builder slot, but never sees which candidate that slot produced.

### 3. A provider blip degrades to N−1, flagged — never a silent single-model answer
Fusion fires N concurrent calls through one gateway: one rate-limit ceiling, one failure point. If a
gateway 429/5xx drops a slot, continue with the survivors **and record it in the provenance** —
"fused from 2 of 3; <model-C> unavailable." Never let an outage collapse fusion to a single model's
answer presented as consensus.

## How to apply

### Two modes
- **`/opinion` (lightweight, decision-only):** N models answer the same question independently; show
  the takes side-by-side for the human. No merge, no code. Use for a fork you'll decide yourself —
  complements `[[decision-log]]`, which surfaces *your* agent's confidence; this adds a second
  family's independent read.
- **`/fusion` (full, with merge):** N models solve with full tools; the merger reconciles into one
  result plus a provenance block. Use when you want a *single* answer to act on.

### Merge output — always carries provenance
```markdown
## Fusion result: <one-line>
**Consensus** (all models agreed): …
**Divergence** (minority takes, preserved): <model> proposed …; kept because …
**Rejected**: … — why discarded
**Quorum**: 2 of 3 agreed on the core approach   ← with N=3
**Degraded?**: no | "fused from 2 of 3; <model> unavailable"
```
With **N=3** the merge is a **quorum**: majority = consensus, the minority take is *preserved and
flagged for the human* (not deleted), and a genuine tiebreak exists. With N=2 you get only
agree/disagree — surface the disagreement to the human rather than having the merger pick a winner.

### Realized with the Workflow tool
`parallel()` the `FUSION_MODELS` (each an `agent()` with the roster's model id + its
`PER_MODEL_OVERRIDES`), then one merge `agent()` with a structured schema for the provenance block.
Feed a confirmed fusion decision into the plan; if the fork is also a build, its acceptance is a
`[[gate-first-validation]]` gate.

## What this prevents
- Betting a non-negotiable path on one model's framing when a second family would have seen the trap.
- Fake diversity from two siblings of the same family (family guard).
- A gateway outage silently downgrading fusion to a single-model answer dressed as consensus.
- The merger laundering its own family's answer (authorship-blind rule).
- Paying 2–3× on low-stakes forks where a single model plus `[[decision-log]]` was enough.
