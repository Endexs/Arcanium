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

**Race conditions**
- Check-then-act patterns (TOCTOU)
- Shared mutable state without locks
- Note: usually low severity for single-user CLI tools, higher for web services

**Off-by-one and falsy-zero**
- Loop bounds that exclude an edge case
- `if x:` where `x == 0` is a valid value
- Index calculations on empty collections

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
