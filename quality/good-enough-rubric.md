# Skill: Good Enough Rubric

## Rule
Review code against five questions, not against perfectionist standards. If the answers are acceptable, ship it. The goal is "delivers user value safely," not "passes a senior architect's design review."

## Why this exists
Agents trained on production code apply production standards reflexively. Solo devs shipping a v1 don't need production standards — they need to ship and get user feedback. The rubric protects against gold-plating without abandoning quality.

## The five questions

### 1. Will it work for the first 100 users?
Not a million. A hundred.

For 100 users:
- SQLite is fine. You don't need Postgres.
- A single-process backend is fine. You don't need Kubernetes.
- Synchronous request handling is fine. You don't need queues.
- An in-memory cache is fine. You don't need Redis.

If the answer is "it will scale to a million users," that's gold-plating. If the answer is "it will fall over at 1000 concurrent users," that's fine for now.

### 2. If it breaks, will users lose data?
Data loss is the only truly unrecoverable failure. Everything else, you can fix and redeploy.

Check:
- Are user-facing writes wrapped in transactions?
- Are destructive operations confirmed or undoable?
- Are backups happening (even daily, even manual)?

If yes to all: good enough. If no: fix before shipping.

### 3. If it breaks, can I see what broke from logs?
You will have bugs. The question is whether you can diagnose them at 2am without recreating the user's exact session.

Check:
- Does every error log include: operation name, inputs (redacted of secrets), full stack trace, user ID if applicable?
- Are logs searchable (Axiom, Logtail, or even `grep` works)?
- Can you tell from logs alone what the user was trying to do?

If yes: good enough.

### 4. Can I delete this and rewrite it in a day if it turns out wrong?
The best code is code you can throw away.

Check:
- Is this module small enough to rewrite in a sitting?
- Does it have a clear interface that other code uses (so a rewrite doesn't ripple)?
- Are there enough tests to verify a rewrite preserves behavior?

If yes: ship it, even if it's ugly. If no: spend more time on the design now.

### 5. Is this on the critical path to revenue/users?
The critical path: signup, the core feature that delivers value, payment.

For the critical path: do not compromise. Test it. Review it. Polish it.

For everything else: ship the cheapest version that works.

## How to apply

In the reviewer system prompt:

> Review code against the five questions in `good-enough-rubric.md`. Do NOT flag issues that are purely about elegance, future flexibility, or theoretical scaling problems. Only flag issues that affect one of the five answers.

In the implementer system prompt:

> Optimize for "good enough" by the five-question rubric. Do not add abstractions, configuration options, or future-proofing that aren't needed to pass the rubric.

### Review template
```markdown
## Good-enough review

1. **Works for 100 users?** Yes / No — <reason>
2. **Data loss risk?** None / Low / Medium / High — <details>
3. **Diagnosable from logs?** Yes / Partial / No — <gaps>
4. **Throwaway-friendly?** Yes / No — <coupling concerns>
5. **Critical path?** Yes / No — <if yes, raise the bar>

**Ship/hold decision**: ship | hold
**If hold**: <specific blockers, only the ones that matter>
```

## What this prevents
- Spending months on infrastructure for users you don't have
- Reviewer feedback that's all style, no substance
- Building "scalable" systems that never get traffic
- Refactoring loops that delay shipping

## Anti-pattern
Treating the rubric as permission to ship buggy code. "Good enough" means: works, doesn't lose data, can be debugged. It does NOT mean: skip testing, skip error handling, skip defensive defaults. Those are baseline, not gold-plating.

## When to raise the bar
Use stricter standards (closer to traditional review) when:
- The code is on the critical path (question 5)
- The code is in `non-negotiable-paths.md` (auth, money, data deletion)
- The code is hard to change later (database schemas, public APIs)

For everything else: ship, get feedback, iterate.
