# Skill: Model Routing

## Rule
Before dispatching work to a model, pick a **tier** and state it. Route by **complexity and
verifiability, never by size**. Two invariants govern every routing call:

> **Complexity sets the floor. Criticality only ever raises it, never lowers it.**
> **You may route down only when something will catch a failure. When nothing verifies the output, route up.**

State the choice alongside the rigor tier: `Rigor: Standard · Model: T2 — <reason>`.

## Why this exists
The naive version of this rule — *"simple task, cheap model"* — is actively dangerous, because
"simple" is measured in diff size and the most expensive failures are one-line changes to critical
code. A single-line edit to a session check looks trivial and is exactly where a weaker model's
misunderstanding costs most. `[[rigor-triage]]` already learned this for *process* ("the dial is on
the change, not the file"); this skill is the same lesson for *model choice*.

The economics are asymmetric and usually misread. A cheap model that succeeds saves a fraction of one
call. A cheap model that fails costs its own tokens **plus** the retry, plus reviewer attention, plus
the chance a subtle error survives review and ships. The downside dwarfs the saving, which is why the
tie-break is always **round up** — the same forcing function `[[rigor-triage]]` uses.

## How to apply

### The tier ladder
Tiers are roles, not model names. Resolve them from the **Model roster** block in the project's
`CLAUDE.md` — the single place models are named (see `[[model-fusion]]`). Behind one gateway,
switching a tier is editing one string.

| Tier | For | Shape of work |
|---|---|---|
| **T1** — cheap/fast | Mechanical, fully specified, verifiable | Applying explicit review findings, renames, formatting, boilerplate, scaffolding from a written spec, doc updates |
| **T2** — mid | Normal work against a clear plan | Implementing a well-specified module, a bug fix with a known repro, a refactor inside one file |
| **T3** — frontier | Reasoning, ambiguity, judgment | Planning/architecture, adversarial review, undefined "done", cross-cutting changes, debugging with no repro, security reasoning, anything on a `[[non-negotiable-paths]]` path |

### Read complexity from these signals — not from line count
- **Ambiguity** — is "done" precisely defined? Undefined ⇒ up-tier. This is the strongest signal.
- **Context breadth** — how many files/systems must be held at once to be correct?
- **Novel reasoning vs. pattern application** — deriving an approach is T3 work; applying a stated one is not.
- **Verifiability** — see below. This is what makes routing *down* safe.
- **Criticality** — from `[[rigor-triage]]`. Raises the floor; never lowers it.

### Verifiability is the license to route down
Route down when a failure will be **caught mechanically**: a frozen gate from
`[[gate-first-validation]]`, an existing test suite, a type checker, a linter, a compiler. Strong
verification converts a model mistake from *shipped bug* into *failed check*, which is cheap.

Route up when verification is weak or absent — design decisions, prose, config with no test,
anything where "looks right" is the only available check. **No gate ⇒ no down-tiering.**

This is why the order matters: decide the gate first, *then* route. A task with a red frozen gate
can often run a tier lower than the same task without one.

### Role floors — the pipeline's non-negotiables
Complexity picks a tier; these floors override it downward-never:

| Role | Floor | Why |
|---|---|---|
| Plan | **T3** | Planning is heavier reasoning than its cost suggests; a weak plan poisons every step after it |
| Gate author | **≥ implementer tier** | A gate authored by a weaker model than the builder cannot meaningfully constrain it |
| Implement | **T2** default; T1 only if verifiable *and* non-critical; **T3** on non-negotiable paths | |
| Review | **≥ implementer tier, and a different family** | A reviewer weaker than the implementer cannot catch what the implementer missed. Same family ⇒ shared blind spots |
| Fix | **T1** | Mechanical application of findings that are already explicit |
| Merger (fusion) | **T3** | Reconciling disagreement is the hardest step in `[[model-fusion]]` |

### Escalate on failure — don't retry the same tier
When work fails at tier N — the gate goes red twice, or the model thrashes/contradicts itself —
**escalate to N+1**. Do not spend the retry budget at the tier that already failed; repeated failure
at a tier is evidence the task was mis-triaged, not evidence that one more attempt will land.

Escalation is bounded by `[[gate-first-validation]]`'s halt: if T3 fails the gate, stop and surface
to the human. Record the escalation — a task that needed T3 after being routed T1 is exactly the
signal that sharpens the next triage (and belongs in `friction.md`).

### Gateway notes (single-endpoint routing)
- The gateway unifies the **endpoint, not the params.** Tier changes must carry their own
  `PER_MODEL_OVERRIDES` — thinking-token floors especially. A T3 thinking model starved of
  `max_tokens` truncates mid-file and looks like a *model* failure when it's a *config* one.
- **A tier is not a family.** T1/T2/T3 may all resolve to one vendor's line — fine for routing,
  **not** valid for `[[model-fusion]]` or for the reviewer's different-family rule.
- If a tier is unavailable (429/5xx), **escalate rather than silently downgrade.** Falling back to a
  weaker model to keep the pipeline moving is the one substitution that must never happen quietly.

## Anti-patterns
- **Routing by diff size or file count.** A 300-line CSS change is T1; one line in a payment path is T3.
- **Down-tiering the reviewer to save cost.** This defeats `[[adversarial-review]]` entirely — the
  review's value *is* its independence and strength. Cheapest place to save money, most expensive place to.
- **"It's just a small change" on a critical path.** Same red flag `[[rigor-triage]]` names: a reason to round up.
- **Retrying at the failed tier.** Five T1 attempts cost more than one T3 run and still may not converge.
- **Down-tiering because a task is repetitive, when nothing verifies it.** Repetition without a check
  compounds a single misunderstanding across every instance.

## What this prevents
- Paying frontier prices for mechanical work that a cheap model verifiably completes
- The far costlier inverse: a weak model on an under-specified or critical task, whose failure
  surfaces after review, or after ship
- Silent quality collapse from a reviewer quietly routed below its implementer
- Retry loops that burn more than the escalation they were avoiding
- A gateway outage downgrading tier without anyone noticing

## Related skills
- `[[rigor-triage]]` — runs **first** and answers a different question: *how much process?* This skill
  then answers *which model?*, consuming that criticality verdict as its floor. State both together.
- `[[gate-first-validation]]` — the gate is what licenses down-tiering; decide it before routing
- `[[model-fusion]]` — the escalation beyond T3: when one frontier model isn't enough, use several
- `[[non-negotiable-paths]]` — the list that forces T3 regardless of how simple the change looks
