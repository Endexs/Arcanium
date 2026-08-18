# Skill: Second Opinion

> **Scope — this skill vs `[[model-fusion]]`.** They are split by job, and do not overlap:
>
> | You need | Skill | Why |
> |---|---|---|
> | to **decide** between options | **this one** | the value is in the divergence; merging destroys it |
> | a single **artifact** (architecture, design, plan) | `[[model-fusion]]` | you cannot act on three designs, so N≥3 merges to a quorum |
>
> Borrow from `[[model-fusion]]`, don't duplicate: the distinct-family rule, the
> divergence-classification table, and the tiebreaker all apply here and are documented there.
> Escalate to it when two answers deadlock on a point no probe can settle — its tiebreaker sends that
> *one* contested point to a third family, which is the only sound way to break a 1-1 tie.

## Rule

Before recording a decision that changes a public interface, a schema, an auth/authz or payments path, or that picks between viable designs, call the `second_opinion` tool. Check the trigger list; do not first judge whether the decision is important enough. Being able to answer it yourself is not a reason to skip it. `second_opinion` is opinion, not validation: it never satisfies `Validated = yes` in `[[decision-log]]`, because two models agreeing is two guesses that match, not evidence the thing works.

## Why this exists

The agent decides when to consult, and that judgment is the weakest link. Measured behaviour, same underlying decision, same tool, two phrasings:

| Prompt | Consulted? |
|---|---|
| "…hard to reverse… public API decision… commit to a design" | yes |
| "Should transliteration go inside slugify() or should callers normalize first?" | **no** |

Identical decision. The model was pattern-matching the *vocabulary* of importance, not the stakes. A model confident enough to answer is confident enough to skip a judgement call about its own importance — but it cannot skip a checklist. That is why the triggers below are structural (does this change a schema?) rather than semantic (is this important?).

## How to apply

### Triggers — check the list, don't judge

Call it if **any** is true:

- changes a public interface, API shape, schema, or data format others depend on
- touches authentication, authorization, payments, or user data
- picks between two or more viable designs, libraries, or migration strategies
- would be expensive to undo once code depends on it
- you are about to write a `workflow/decision-log` entry, an ADR, or a plan step
- your own confidence is anything less than **high**
- the change touches a path in `quality/non-negotiable-paths`
- the user said architecture, security, design, migration, or trade-off

Do **not** call it when the question has one findable answer — what the code does, how an API is spelled, why a test fails, syntax, naming. If reading a file or running a command settles it, do that: execution is ground truth, opinion is not, and it is free. See `workflow/feasibility-first`.

### Ask well

The models cannot see your conversation. State the options under consideration, the constraints that matter, and what a good answer must address. Pass `focus: "architecture"` or `"security"`. Put ruled-out options and prior decisions in `context`. A vague question wastes both calls.

### Read the divergence, not the consensus

Both answers come back in a fixed shape: RECOMMENDATION / WHY / KEY RISKS / WHAT WOULD CHANGE MY MIND / CONFIDENCE.

- **They agree** → two independent votes, not proof. Both may share a training blind spot. Proceed, and note in the decision entry that agreement was cheap.
- **They disagree** → this is the finding. Diff the two **WHAT WOULD CHANGE MY MIND** sections. They identify the assumption the two models actually differ on, and that assumption is usually the real decision. Then classify the divergence using `[[model-fusion]]`'s table — a **factual** split is settled by reading the code, an **empirical** one by the cheapest probe (`[[feasibility-first]]`), and only a genuine **values call** goes to the user. Resolving it with a probe is the only move that converts opinion into ground truth.
- **They deadlock on something you cannot probe** → do not average and do not flip a coin. Escalate that *one* contested point to a third family per `[[model-fusion]]`'s tiebreaker, which converts N=2 to N=3 for that decision alone.
- **One failed** → you have one opinion, not two. Say so; do not present it as corroborated.

Never average the two into a mushy middle. Decide, and record what the rejected option was better at.

### Feed it into the decision log

`workflow/decision-log` STOPs on **Low/Medium confidence + Hard reversibility**. That cell is the primary trigger for this tool: consult *before* writing the entry, so the user reviews an informed decision instead of an uncertain one.

In the entry, record: that a second opinion was taken, whether the two converged, and the one assumption they differed on. Confidence may rise after consulting. **`Validated` may not** — only a probe or a passing gate moves that axis.

## What this prevents

- Load-bearing decisions made by one model that was confidently wrong, with no second look because it never felt uncertain.
- The inverse failure: burning $1 and two minutes on questions a `grep` would have answered.
- Laundering agreement into false confidence — two models concurring recorded as if the design were validated.
