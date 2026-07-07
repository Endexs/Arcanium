# Skill: Non-Negotiable Paths

## Rule
These code paths always get the full review pipeline (planner → implementer → adversarial reviewer → fix) regardless of change size, regardless of time pressure, regardless of "it's just a small change."

For these paths, "good enough" is not good enough.

## Why this exists
Solo devs ship fast by cutting ceremony. That's correct for most code. But a small set of paths have catastrophic blast radius — a single bug costs you users, money, or legal trouble. The skill defines exactly which paths require the heavyweight workflow so you don't have to make the judgment call under pressure.

## The non-negotiable list

### 1. Authentication
- Login, signup, password reset
- Session creation, token generation, token validation
- OAuth integration, SSO callbacks
- Any code that decides "is this user who they claim to be"

**Why**: A bug here means strangers reading other users' data.

### 2. Authorization
- Permission checks ("can this user do X")
- Role assignment
- API endpoint access control
- Resource ownership verification

**Why**: A bug here means users doing things they shouldn't be allowed to.

### 3. Payment and money
- Charging cards
- Subscription management
- Pricing calculation
- Refunds
- Currency conversion
- Anything connected to a payment processor

**Why**: A bug here means real money lost, plus possible legal trouble.

### 4. User data deletion
- Account deletion
- Bulk record deletion
- "Are you sure?" prompts that lead to data loss
- Soft-delete vs hard-delete logic

**Why**: A bug here means users lose data they expected to keep.

### 5. Database schema changes
- Migrations (especially destructive ones)
- Adding NOT NULL columns to populated tables
- Dropping columns or tables
- Changing column types
- Index changes on large tables

**Why**: A bug here means production downtime, possibly data loss.

### 6. Bulk-user changes
- Anything that affects all users at once
- Mass email or notification sending
- Background jobs that touch every record
- Pricing changes that affect existing subscribers

**Why**: A bug here multiplies by your entire user base instantly.

### 7. Public API contracts
- Endpoints other code depends on
- Webhook payloads
- SDK signatures
- Anything where a change breaks external callers

**Why**: A bug here breaks integrations you can't see or fix.

### 8. Security-sensitive serialization
- JWT signing/verification
- Encryption/decryption
- Anything that reads or writes secrets to storage

**Why**: A bug here means credentials leaked or sessions hijacked.

## How to apply

In every project's CLAUDE.md:

> The code paths in `non-negotiable-paths.md` require the full multi-agent workflow (plan → implement → adversarial review → fix → test) regardless of change size. The agent must check whether any modified file or function falls under a non-negotiable path and run the full pipeline if so.

In the implementer system prompt:

> Before starting work, check whether the planned changes touch any path listed in `non-negotiable-paths.md`. If yes, refuse to skip any step of the workflow — even if the user asks. Flag it as a `### GAP:` and stop.

### Pre-check checklist
Before any change, the agent asks:
- Does this touch authentication or session handling?
- Does this touch authorization or permission checks?
- Does this touch billing or money flows?
- Does this delete user data?
- Does this modify the database schema?
- Does this affect more than one user at a time?
- Does this change a public API or webhook contract?
- Does this handle secrets, tokens, or encryption?

If any answer is yes: full pipeline.
If all answers are no: lightweight workflow is fine.

## What this prevents
- Skipping review on a "small auth fix" that turns out to leak sessions
- Treating a "quick migration" the same as a styling change
- Ad-hoc decisions about ceremony under deadline pressure
- The bug that kills your startup

## When you're tempted to override
You will be tempted to say "this is just a one-line change, I don't need the full pipeline."

For non-negotiable paths, the answer is no. One-line changes to auth code are exactly how bugs ship. The cost of the full workflow is hours; the cost of a bug in non-negotiable code is users, money, or both.

## Encoding non-negotiables in code: RuntimeError, not assert

When a non-negotiable is enforced **inside the code itself** — a post-condition that aborts execution if a load-bearing invariant is violated — use `raise RuntimeError(...)` (or a project-specific exception class), never `assert`.

```python
# WRONG — silently stripped under `python -O`
assert len(result.sources) >= 1, "ok answer must carry sources"

# RIGHT — survives optimization, fails loudly in production
if result.status == "ok" and len(result.sources) < 1:
    raise RuntimeError("non-negotiable violated: 'ok' answer must carry sources")
```

**Why this matters**: Python's `-O` flag (used by some production deployments and packagers) strips `assert` statements entirely. Code that relies on `assert` for a load-bearing check has *no* check in production. The bug is invisible until it triggers, and it triggers in exactly the environment you can't easily debug.

**Source**: Cortex (second-brain RAG) Phase 3 adversarial review. The source-attribution invariant was originally encoded as `assert`. Opus review flagged it; promoted to `RuntimeError`. The invariant is the architectural guarantee Cortex makes to its user — "every confident answer cites a real source." A stripped assert would have silently removed that guarantee in any deployment that used `-O` or a packager that did the equivalent.

**Apply when**: encoding any invariant in the non-negotiable list above (auth, authz, payment, deletion, etc.) as a runtime check, OR encoding any product-level guarantee whose silent failure would surprise the user. Use `assert` only for development-time sanity checks you'd be okay losing.

## A green test suite is not evidence of correctness here

On a non-negotiable path, "all tests pass" means almost nothing on its own. On airbnb-website
Phase 6, **7 of 8 `Major` findings were green in the suite** and surfaced only in the mandatory
adversarial review. The reason is structural: a typical suite is single-threaded and mocks the
network, so it *cannot see* the failure modes that dominate money/availability code —
concurrency races, a lock held across a slow network call, an event loop frozen by blocking I/O,
a decision two callers make from the same stale read.

Therefore, for every money/state mutation on a non-negotiable path:
- Do not treat green tests as the gate. **The adversarial review is the gate** (`[[adversarial-review]]`).
- Ship **at least one concurrency/contention probe** alongside the happy-path tests: a
  lock-probe (a second connection grabs the write lock *during* the outbound network call, proving
  the lock was released — see `[[defensive-defaults]]` rule 12a) and a concurrent-mutation case
  (two cancels / a webhook + redirect resolve to exactly one money movement and one ledger row).
  **A probe is only trustworthy once you've watched it fail** — temporarily revert the fix it
  tests and confirm the probe goes red before trusting a green result on the real code. A test
  double (mock, isolated event loop, non-shared connection) can quietly make a "concurrency
  probe" incapable of failing regardless of the real bug's presence — see `[[adversarial-review]]`
  for the airbnb-website Phase 7 instance of exactly this.
- Encode the money invariant in code with `raise RuntimeError` (below), not just in a test.

**Source**: airbnb-website Phase 6A/6B/6D — every concurrency Major passed the suite; the reviewer
caught them by *reasoning* about two-at-once and real latency, which no single-threaded test does.

## Anti-pattern
Adding paths to this list because they feel important. The list should stay short. If everything is non-negotiable, nothing is. Only add paths where a single bug has catastrophic, hard-to-reverse impact.
