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
```

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

## What this prevents
- Burning weeks on a wrong architectural choice the user could have flagged in 30 seconds
- Agents quietly making decisions the user didn't realize they were delegating
- "Why did we choose Postgres again?" questions 3 months later with no answer
