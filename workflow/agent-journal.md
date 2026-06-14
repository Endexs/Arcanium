# Skill: Agent Journal

## Rule
At the end of every multi-step agent run, the agent writes a structured reflection on its own uncertainty. The user reads this before reviewing the output.

## Why this exists
On the LLM Gateway project, the implementer made subtle bugs (the `if history:` falsy-None mistake, the double-close in `session_delete`) that the agent *knew* were judgment calls but never surfaced. Agent journaling forces the uncertainty into your view so you can spot the risky areas before they become bugs.

## How to apply

### Format
Append to every output:

```markdown
## Run journal

**What I was certain about:**
- <thing 1>
- <thing 2>

**What I was uncertain about:**
- <thing 1 — and what I chose>
- <thing 2 — and what I chose>

**Where I made judgment calls the plan didn't specify:**
- <decision 1 — and rationale>
- <decision 2 — and rationale>

**What I would ask for clarification on if I could:**
- <question 1>

**What surprised me about the existing code:**
- <observation 1>

**Confidence in this output:** high | medium | low
```

### User workflow
Read the journal BEFORE diffing the code. The journal tells you:
- Which lines to scrutinize (uncertain + judgment calls)
- Which questions the spec didn't answer (gaps to fix)
- Whether the agent had bad assumptions about your codebase

A "medium" or "low" confidence rating is a strong signal to run an adversarial review.

### When the journal is empty
If the agent claims it was certain about everything, treat that as suspicious. Either the task was trivial (fine) or the agent isn't being honest with itself (probe deeper).

## What this prevents
- Subtle bugs in judgment-call code that you don't know to look for
- Spec gaps that compound across phases because nobody noticed
- False confidence in agent output that "looked fine on the diff"

## Example (from a real project)
> **What I was uncertain about:**
> - Whether `if history:` or `if history is not None:` is correct here. Chose `if history:` because it's shorter. If history can be `None` (no prior turns) vs `[]` (empty list), the behavior differs.

That one journal line would have flagged the Phase 7 Critical bug before Opus had to find it.
