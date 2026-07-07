# Skill: Adversarial Review

## Rule
A separate agent (different context, ideally a different model) reviews the implementer's output as an adversary. Assume hidden bugs exist. Look for specific failure patterns. Categorize findings as Critical / Major / Minor and prioritize the top 5.

## Why this exists
On the LLM Gateway project, every adversarial Opus review found real bugs the implementer didn't notice. The bugs were subtle: falsy-None checks, double-close patterns, asymmetric disable flags. The implementer was confident the code was correct. The reviewer was paid to assume it wasn't.

Without an adversarial reviewer, these bugs ship.

## How to apply

### When to run
- Always for changes in `non-negotiable-paths.md`
- Always for changes that touch >5 files
- Always for changes that add a new database table or modify a schema
- Always for changes that introduce a new disable mechanism, cache, or auth path
- Skip for: pure refactoring, doc updates, dependency bumps, test additions only

**Before declaring any task done, answer these four explicitly** ("qualifies: yes/no,
because...") — do not substitute a rigor-tier statement (Vibe/Standard/Full) for actually
checking this list. They are different steps: a rigor tier is a vibe, this checklist is a fact
table, and only the fact table is mechanical enough to survive momentum. A task that qualifies
gets the review before it's called finished, full stop — not after the user asks whether it
happened. Source: airbnb-website Phase 7 — a stated "Standard, rounding toward Full" rigor tier
shipped without the review ever running, until the user directly asked "did you one-shot it?"
Also check any change that introduces a new disable/enable mechanism against
`[[disable-flag-both-paths]]` at the same time — the two checklists share a trigger and catch
different halves of the same bug class (see that skill's own real-world hit).

### Review checklist
The reviewer hunts for specific patterns:

**Falsy-None mistakes**
- `if var:` when `var` can be `None` (absent) vs `[]` (empty)
- Should usually be `if var is not None:`
- Example: cache bypass guard treating `history = None` (first turn) as "no session"

**Resource cleanup**
- Early returns inside `try` blocks that close the resource, plus a `finally` that closes it again
- Connections, files, locks not released on exception paths
- Example: `session_delete` double-close `ProgrammingError`

**Atomicity gaps**
- Multi-step writes without transactions
- Operations that can fail halfway and leave inconsistent state
- "Did A succeed? Did B succeed?" without a way to recover

**Asymmetric disable flags**
- TTL=0 disables reads but not writes
- `--no-cache` skips lookup but still records cache events
- Feature flag hides UI but backend still runs

**Spec divergence**
- Implementation doesn't match the spec exactly
- Plan said "exit 1" but implementation exits 0
- Spec said "stderr" but implementation uses stdout

**Silent error swallowing**
- `try/except Exception: pass`
- Errors logged but not propagated
- Functions returning None on error without a clear "did this succeed" signal

**Race conditions** (Major+ on any web money/availability path — the suite can't see these)
- Check-then-act patterns (TOCTOU); shared mutable state without locks
- **Two-at-once probe:** for every state mutation, ask "what if two of these run concurrently
  (webhook + success-redirect, a double-click, two admin tabs)?" A bare re-read is not a guard —
  demand an idempotency key **and** a compare-and-swap / set-once claim.
- **A concurrency/regression probe must be watched to fail before it's trusted** — a probe that
  passes identically with and without the fix has proven nothing.
- Still low severity for a single-user CLI; **high** for anything with money or a webhook.
- Source: airbnb-website 6D M1 (concurrent cancels refunded money while the ledger wrote `0`);
  Phase 7 (a concurrency probe that passed both before and after its fix — see the test-harness
  gotcha below).
- Full incident detail, the idempotency+CAS pattern, and the exact test-harness gotcha that can
  quietly defeat a concurrency probe: `components/concurrency/ANTIPATTERNS.md` #3–#4 and
  `PATTERNS.md` #3–#4.

**A DB lock (or the event loop) held across a network call**
- A network call made *inside* an open DB write transaction (`BEGIN IMMEDIATE` / `SELECT ... FOR
  UPDATE`) serializes every other writer and 500s them under real latency — check that fields
  are gathered + the txn committed *before* the call.
- A blocking network call inside an `async def` route freezes the whole event loop, not just the
  one request making the call.
- Source: airbnb-website 6A M1 (Stripe call inside the write lock), 6B M1 (`urlopen` in
  `async def`), Phase 7 (a synchronous LLM gateway call inside `async def chat` — the same bug
  reintroduced in a third, unrelated subsystem).
- Full citations and both fix shapes (plain `def` vs. explicit `run_in_threadpool`):
  `components/concurrency/ANTIPATTERNS.md` #1–#2 and `PATTERNS.md` #1–#2.

**An `except` narrower than the contract it backs**
- A function documented "never raises" / "isolates per-item failure" whose `except` lists only
  some exception families. Enumerate what the body can actually throw — DB (`SQLAlchemyError`),
  stdlib network (`http.client`, `socket`), parse errors — and confirm each is caught + that the
  failure is isolated (rollback, continue to the next item). Happy-path tests never hit these.
  Source: airbnb-website 6B M2 — a feed-sync `except` missed `SQLAlchemyError`, 500'ing the page.

**Untrusted data crossing a *later* trust boundary**
- Input validated at intake but then following a redirect, landing in a CSV/export sink, or
  flowing into an error message/log unescaped. Escape export cells (a leading `= + - @ \t \r`
  is formula injection, CWE-1236); confirm no user value reaches a log/exception body.
  Source: airbnb-website 6C M1 (CSV formula injection).
- Source (redirect-target re-validation): airbnb-website 6B M3 — a feed URL's scheme was
  checked at registration, but the fetch followed a `302` to an unvalidated target (blind SSRF).
  Full detail and the re-validate-every-hop fix:
  `components/external-integration/ANTIPATTERNS.md` #4 and `PATTERNS.md` #2.

**Off-by-one and falsy-zero**
- Loop bounds that exclude an edge case
- `if x:` where `x == 0` is a valid value
- Index calculations on empty collections

**Numerical formulas derived from third-party library metrics**
- Any line that computes a similarity, distance, probability, or score from a library return value
- Re-derive the formula from the library docs, not from the implementer's commentary
- Common traps: cosine vs L2 vs squared L2; log-probability vs probability; loss vs score; degrees vs radians
- Source: Cortex Phase 3 review — `sqlite-vec` returns squared L2 distance by default;
  `similarity = 1 - distance` is wrong, `1 - distance/2` is correct for unit vectors.
- Full worked example and the verification method: `components/db/ANTIPATTERNS.md` #5 /
  `components/llm-integration/ANTIPATTERNS.md` #2 and their `PATTERNS.md` entries.

**`assert` in non-test code for load-bearing checks**
- Any `assert` outside of `tests/` that enforces a product-level invariant
- `assert` is stripped under `python -O`; promotes silently to "no check at all" in optimized builds
- Should be `raise RuntimeError(...)` or a project-specific exception class
- See `[[non-negotiable-paths]]` for the rule and rationale
- Source: Cortex Phase 3 review — source-attribution invariant encoded as `assert`

**Positional CLI arguments that take user prose**
- Any `@click.argument("query")` (or argparse equivalent) that accepts a user-typed sentence
- Without `nargs=-1`, unquoted multi-word input becomes "unexpected extra argument"
- Default fix: `nargs=-1, required=True` + `" ".join(...)` at the top of the function
- Source: Cortex `lt ask` papercut, caught in first-day real usage

**Evidence-existence ≠ claim-support (any grounding/citation/RAG system)**
- A system that grounds or cites claims must verify the citation actually *supports the
  specific claim it's attached to* — not merely that the citation is real and exists somewhere.
  A generator can pair a fabricated claim with genuine-but-unrelated evidence and pass an
  existence-only check.
- Source: airbnb-website Phase 7 — a support chatbot's grounding check verified quoted spans
  were verbatim in the knowledge base but never tied the quote to the answer text it was
  attached to (e.g. answer "there's a rooftop helipad," cite a real "free parking" line).
- Full incident, the two-gate fix, and the residual-limitation caveat:
  `components/llm-integration/ANTIPATTERNS.md` #3 and `PATTERNS.md` #3.

### Output format

```markdown
# Adversarial Review

## CRITICAL
### C1. <Short title>
- **Location**: file.py:line
- **Description**: <what's wrong, including the exact lines>
- **Impact**: <what breaks, who notices, when>
- **Fix**: <specific code change>

(repeat for C2, C3, ...)

## MAJOR
(M1, M2, ...)

## MINOR
(N1, N2, ...)

## TOP 5 FIXES TO MAKE FIRST
1. **C4 — <title>**: <one-paragraph why this is #1>
2. **C1 — <title>**: ...
3. ...
```

### Severity definitions
- **Critical**: Guaranteed crash, data loss, security hole, or core feature broken
- **Major**: Likely bug in common usage, broken UX in expected scenarios, or spec violation
- **Minor**: Edge case bug, cosmetic, maintainability concern, or test gap

### User workflow
1. Read only the Top 5 list first
2. Apply fixes in order
3. Re-run tests
4. If time permits: address Majors that aren't in the Top 5
5. Minors can wait until next phase

## What this prevents
- Subtle bugs that pass tests but fail in production
- Implementer overconfidence
- Bugs in code patterns the implementer has seen 100 times but doesn't recognize as wrong
- Spec violations the implementer rationalized as "close enough"

## Why "adversarial" matters
A friendly review looks for opportunities to improve. An adversarial review assumes the code is broken and tries to prove it. The framing matters: adversarial reviews find more bugs because they're looking for them.

## Anti-pattern
Treating the reviewer's findings as suggestions. Critical findings are not negotiable. Major findings are presumed to need fixing unless you have a specific reason. Only Minor findings are "yes/no based on context."
