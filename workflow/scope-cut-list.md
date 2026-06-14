# Skill: Scope Cut List

## Rule
Every plan must explicitly list features the agent considered and **excluded**. Default bias: ship the smallest version that delivers user value.

## Why this exists
Agents trained on production code over-engineer by default — they add abstractions, configuration options, edge case handlers, and "future flexibility" that aren't required. The scope cut list converts this tendency into a feature: the agent surfaces options, the user rejects most of them.

For solo devs racing to ship, shipping the minimal version is almost always the right call. You don't know what users want until you have users.

## How to apply

### Format
Every plan ends with:

```markdown
## Scope cut list
The following were considered and explicitly excluded from this implementation:

- **<feature>** — <one-sentence reason for cutting>
- **<feature>** — <reason>
- ...
```

### Examples of good cuts
- "Retry logic with exponential backoff — single retry is enough for v1; add if errors are common"
- "Admin dashboard — defer until we have data worth monitoring"
- "Bulk import CSV — single record entry covers the first 100 users"
- "Email notifications — log to console for now; wire SendGrid when needed"
- "Rate limiting — defer until we see abuse"

### Examples of bad cuts (don't cut these)
- Input validation
- Authentication on protected routes
- Database transactions on multi-step writes
- Error logging
- Anything in `engineering/defensive-defaults.md`

### User workflow
The user skims the cut list. For each item:
- If it's actually important: say so, agent adds it
- If it's the right call: silence = approval

This is faster than reviewing the full plan and asking "did you remember X?"

## What this prevents
- Building a feature-complete v1 that takes 3 months instead of a v0.1 that takes 2 weeks
- Premature abstractions that calcify before you know what they should do
- Agent gold-plating that delays shipping
- Building things users will never ask for

## Anti-pattern
Adding features to the cut list that you intend to build in this iteration. The cut list is for things you're NOT building. If it's in scope, put it in the plan; if it's out of scope, put it on the cut list. No middle ground.
