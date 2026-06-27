# Skill: Decision Log

## Rule
For every meaningful technical choice, the agent must produce a decision entry the user can react to before code is written. The user evaluates only the high-stakes entries; the rest are auto-approved.

## Why this exists
Solo devs without deep system design experience can't reliably evaluate every architectural choice an agent makes. But they CAN evaluate "is this hard to reverse?" and "is the agent confident?" The decision log surfaces those two signals for every choice.

## How to apply

### Format
Every plan must include a "Decisions" section with entries like:

```markdown
## Decision: <one-line description>
**Recommended approach**: <one sentence>
**Why this over alternatives**: <2-3 sentences>
**What this costs if wrong**: <one sentence>
**Confidence**: high | medium | low
**Reversibility**: easy | hard
**Validated** (external-facing decisions only): yes (cite source) | no | n/a
```

The **Validated** axis applies to any decision that depends on a system you don't control — a third-party API, a platform behavior, an integration you assume exists. "Validated: yes" requires a verification source (a probe, a header check, an API response); "the user wants it" is not validation — that's confidence in the goal, not proof the capability exists. Use `n/a` for self-contained decisions (schema, module layout, error format).

### What to log
Log decisions about:
- Database choice and schema design
- API contract shape (request/response structure)
- Authentication and authorization model
- External dependencies (libraries, services)
- File/module organization
- Error handling strategy
- Concurrency model (sync vs async, queues, etc.)

### What NOT to log
Don't log every trivial choice — that creates noise. Skip:
- Variable names
- Code formatting
- Choice between equivalent stdlib functions
- Test framework configuration
- Anything reversible in <30 minutes

### User review heuristic
The user reviews only entries where **both** confidence is low/medium AND reversibility is hard. Everything else is auto-approved.

| Confidence | Reversibility | Action |
|-----------|---------------|--------|
| High | Easy | Auto-approve |
| High | Hard | Skim, usually approve |
| Low/Med | Easy | Auto-approve (cheap to fix later) |
| Low/Med | Hard | **STOP** — user must review |

### The validated-and-load-bearing override

The confidence/reversibility table is not enough on its own. A decision can be **high confidence and easy to reverse** and still sink the project — if it depends on an external capability nobody checked. That's the airbnb-llm-chat failure: confidence in the goal (send replies into Airbnb) was high and "swap the send mechanism later" felt reversible, so the table auto-approved it — but the capability didn't exist.

Override rule, evaluated **before** the table:

> If `Validated = no` **and** the project depends on this capability → **automatic STOP**, regardless of confidence or reversibility.

The fix on a STOP here is not "user reviews the wording" — it's "go run the cheapest probe that proves the capability exists" (see `[[feasibility-first]]`), then come back and set `Validated: yes` with a source. An unvalidated, load-bearing external assumption is the one decision class that confidence cannot buy a pass on.

## What this prevents
- Burning weeks on a wrong architectural choice the user could have flagged in 30 seconds
- Agents quietly making decisions the user didn't realize they were delegating
- "Why did we choose Postgres again?" questions 3 months later with no answer
- Building an entire phase on an external capability that was never verified to exist (the validated-and-load-bearing override catches this when `feasibility-first` was skipped)
