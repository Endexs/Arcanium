# Skill: Gate-First Validation

## Rule
For a Full-tier task (see `[[rigor-triage]]`), design an **executable acceptance gate before writing any
implementation**, prove it fails against current code (red baseline), freeze it, then loop
implement → run-gate until it passes green or a bounded halt threshold is reached. The agent that
authors the gate is **not** the agent that builds against it, and the builder may **never** edit the gate.

## Why this exists
Adapted from the `/auto-validate` pattern in the fusion-harness project (external idea, not a
retrospective — cited for provenance). Our existing safety net, `[[adversarial-review]]`, runs
*after* implementation and returns model judgment ("is this good?"). It cannot catch a builder that
quietly redefines "done" to whatever it managed to produce. A gate authored *before* the build, in a
different context, frozen once red, makes "done" objective and un-gameable: the target is fixed before
the builder sees the problem, and the builder cannot move it.

This is TDD lifted to the agent loop — but with two properties ordinary TDD doesn't enforce:
authorship independence (gate author ≠ builder) and a bounded, legible halt instead of an infinite
retry loop that silently burns the token budget.

## When it applies
- **Mandatory** on any path in `[[non-negotiable-paths]]` and any Full-tier task in `[[rigor-triage]]`
  (money, auth/authz, data deletion/migration, bulk-user changes, public API/webhook contracts,
  irreversible side effects, a correctness invariant others rely on).
- **Skip** for Vibe-tier work (layout, copy, a log line) — a gate there is ceremony.
- When unsure, round up, per `[[rigor-triage]]`.

## How to apply

### 1. Author the gate first — and make it executable
A validator agent (a different roster slot than the builder — see `[[model-fusion]]` for the roster
convention) reads the spec/plan and writes a gate that **runs and returns binary pass/fail**:
a test file, a CLI assertion, a `curl … | grep`, a script that exits non-zero on failure. Prose
acceptance criteria do **not** count — if it can't be executed by a machine, it isn't a gate.

### 2. Prove the baseline is red — this step is load-bearing
Run the gate against the current code. It **must fail**.
- A **green baseline is a broken gate**: it tests nothing, or the work already exists. Stop and
  redesign the gate — do not proceed.
- Red baseline is the only thing that makes the eventual green *mean* something.

Encode the red-baseline requirement as a hard check, not a hope:

```
if gate passes before any implementation:
    raise RuntimeError("gate is green at baseline — it proves nothing; redesign it")
```

### 3. Freeze the gate
Once red is confirmed, the gate is **immutable** for this task. The builder cannot touch it. If the
builder believes the gate is wrong, it **escalates to the human** — it does not rewrite the target.
This is the anti-gaming rule; without it the builder "passes" by weakening the test, which is the
single most common failure mode of self-validating agent loops.

### 4. Loop: implement → run gate → feed failure back
Builder implements. Run the frozen gate.
- **Green** ⇒ done; hand off to `[[adversarial-review]]` for what the gate didn't think to encode.
- **Red** ⇒ feed the **gate's own failure output** (assertion diff, stack trace, mismatched value)
  back as the next structured instruction to the builder. Repeat.

### 5. Bounded halt
After **N** iterations without green (default N = 3), **stop** and surface to the human:
the frozen gate, the last failure diff, and the delta between expected and actual. A halt is a
legible handoff, not a wall of retries — never raise N to force a pass.

## Interaction with adversarial-review
They are complementary, not redundant. The gate proves the *pre-agreed spec* is met, objectively and
before the build. `[[adversarial-review]]` then hunts for everything the gate *didn't think to
encode*. Gate = "did we build what we said." Review = "what did we fail to say." Run the gate first;
a red gate means there is nothing yet worth reviewing.

## What this prevents
- A builder silently redefining "done" to match whatever it produced.
- "Passing" by weakening the test (frozen-gate rule).
- Green results that prove nothing because the gate was never red first.
- Infinite self-correction loops that quietly drain the token budget (bounded halt).
