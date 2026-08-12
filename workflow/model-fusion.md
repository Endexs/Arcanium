# Skill: Model Fusion

## Rule
Have **N independent models (N ∈ {2,3})** attempt the *same* problem in parallel, then a separate
**merger** role reconciles their outputs into one result with explicit **provenance**: what they
agreed on (consensus), what only one saw (divergence, preserved not discarded), and what was rejected.
"AND, not OR" — combine the models' cognitive strengths instead of picking one. Because it costs
2–3× a single run, fusion is **budgeted to decisions that are expensive to get wrong**, not a default.

## Primary use: project inception (run it FIRST)
The highest-leverage place to spend fusion is the **architecture, at the very start of a project** —
the single most expensive, least reversible decision, which every later phase inherits. Run it once,
up front, via `.claude/bin/fusion-architect`; the merged result becomes spec §3/§4/§5/§7. This is
the headline use, not a niche one — see the Multi-agent pipeline's **Phase 0** in the project
`CLAUDE.md`.

**Fusion amplifies its framing — fuse on HOW, never on WHAT.** The PM-owned spec (§1 what, §2
stories, §6 non-negotiables, §8 success) must be filled *first* (`[[spec-coach]]`). Fuse two models
on *"what should this be?"* and they diverge on the problem itself, producing confident garbage
consensus. `fusion-architect` refuses to run against an unframed spec for exactly this reason. The
order is fixed: `[[feasibility-first]]` probe → PM-owned spec → **architecture fusion** →
`[[gate-first-validation]]` for Phase 1 → build.

The **secondary use** is any later high-stakes fork — a `[[non-negotiable-paths]]` decision mid-project
— run the same way, sideways to phase planning.

## Why this exists
Adapted from the `/fusion` pattern in the fusion-harness project (external idea, cited for
provenance — the upstream slash commands no longer exist; see the realization note below). Our existing pipeline (plan → implement → review → fix) is a **relay**: each
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

### Scope: this skill merges. For a decision, don't use it
N models solve with full tools; the merger reconciles into one result plus a provenance block. Use it
when you need a **single artifact to act on** — an architecture, a design, a plan — because you cannot
act on three.

> **To decide between options, use `[[second-opinion]]` instead.** Two models, both answers returned
> unmerged, the agent judges. That is a different job: a decision's value is in the *divergence*, and
> merging destroys exactly the thing you called for. This skill previously documented that as an
> `/opinion` mode; it now lives in `[[second-opinion]]`, which owns the trigger checklist and the
> `second_opinion` tool. Nothing here duplicates it.

### Handling the divergences — classify, then route (the divergences ARE the value)
Surfacing disagreement is the floor, not the handling. Two models were run precisely so they would
*not* agree; a flat list of "human decide" forwards that signal instead of using it. Every divergence
gets **classified by what can settle it**, and only genuine values-forks reach you:

| Type | Settled by | Reaches you? |
|---|---|---|
| **False** — same decision, different words / one a superset | collapse into consensus | no |
| **Spec-resolved** — one option violates a §6 non-negotiable | the spec (`[[non-negotiable-paths]]`) → moves to Rejected | no |
| **Empirical** — hinges on a measurable fact | a `[[feasibility-first]]` probe — the measurement decides | no |
| **Tiebreaker** — real engineering disagreement, a likely-better answer | a **third family adjudicates that one decision** (`fusion-architect --tiebreak`) | rarely |
| **Values call** — genuine tradeoff, no right answer | **you** — framed with cost-if-wrong + reversibility + a recommended default | yes |

Two things make this more than a taxonomy:
- **The tiebreaker is the fix for N=2's missing quorum.** Two models give agree/disagree with no
  tiebreak, so without this every fork bounces to you. Escalating *one contested decision* to a third
  family — not a whole third architecture — is cheap, and is `[[model-routing]]`'s escalate-don't-retry
  applied to a decision. It converts N=2 to N=3 for that decision alone.
- **When a fork does reach you, it's framed for a 30-second call** via `[[decision-log]]`'s axes
  (cost if wrong, reversibility, recommended default) — not a wall of prose to adjudicate cold.

**Guard against synthetic averaging.** The merger's worst failure is "resolving" a divergence by
inventing a compromise neither model proposed — design-by-committee, an incoherent blend worse than
either coherent position. Rule: the merger may only choose from options actually proposed; a genuinely
new third path is labelled *NEW — unvalidated* and treated as a values call, never presented as resolved.
Two coherent architectures beat one mushy one.

This is `classify-and-recommend`, not auto-route: the merger sorts and recommends, **you pull each
trigger** (run the probe, run `--tiebreak`, make the call). Nothing auto-escalates a decision to a
model you didn't choose — deliberate, because this is the highest-stakes decision in the project.

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
flagged for the human* (not deleted), and a genuine tiebreak exists.

**The merger may consolidate agreement; it may never adjudicate disagreement.** That line is what
keeps a merge honest, and it is why N matters:
- **N≥3** — a majority exists, so calling the majority position consensus is sound. The minority is
  preserved and flagged, never deleted.
- **N=2** (the script's default roster) — there is no majority to have. Every divergence escalates as
  `HUMAN DECISION NEEDED` or to `--tiebreak`; the merger consolidates only what both models already
  agreed on. A merger that picks a winner at N=2 is guessing, and presenting that as fusion is the
  failure this skill exists to prevent.

If what you need is the *decision* rather than the artifact, don't merge at all — use
`[[second-opinion]]` and judge the two answers yourself.

### How it's realized
> Provenance note: upstream fusion-harness was reduced to a single `second_opinion` tool and its
> `/fusion` merge was **removed** — for the reason this skill already encodes at N=2 (a merger cannot
> access which answer is true, so it rewards the more confident one). Our merge survives because it is
> scoped to N≥3, where it is a *quorum* with a preserved minority and a real tiebreaker, and because it
> produces an artifact rather than adjudicating a decision. Cite the pattern, not the commands.

For the **inception architecture fusion**, use `.claude/bin/fusion-architect <spec>` — it fans the
`FUSION_MODELS` out over `omni-send` (true cross-vendor, which the Workflow tool cannot do — its
subagents are one family), strips authorship, shuffles order, merges with the `MERGER`, and writes
`agents/planner/fusion/fusion-result.md`. It bakes in the three guards below and refuses to present
a single-model answer as fusion.

For a **same-session fork** where all candidates can be one family, the Workflow tool also works:
`parallel()` the roster (each an `agent()` with a model id), then one merge `agent()` with a
structured schema. Cross-vendor still needs `fusion-architect`/`omni-send`. Either way: feed the
confirmed decision into the plan; if the fork is also a build, its acceptance is a
`[[gate-first-validation]]` gate.

## What this prevents
- Betting a non-negotiable path on one model's framing when a second family would have seen the trap.
- Fake diversity from two siblings of the same family (family guard).
- A gateway outage silently downgrading fusion to a single-model answer dressed as consensus.
- The merger laundering its own family's answer (authorship-blind rule).
- Paying 2–3× on low-stakes forks where a single model plus `[[decision-log]]` was enough.
