# Phase N review

> Adversarial review per `quality/adversarial-review`. Copy to `phaseN-review.md` and fill in. Assume the code is broken; find specific failure modes.

## Inputs reviewed

- `spec/spec.md` — sections §x, §y
- `agents/planner/phaseN-plan.md`
- Diff: `git diff <prev-phase-tag>..HEAD`

## Review checklist (do not skip patterns)

- [ ] Falsy-None mistakes (`if var:` when `var` can be `None` vs `[]`)
- [ ] Resource cleanup (early-return + finally double-close)
- [ ] Atomicity gaps (multi-step writes without transactions)
- [ ] Asymmetric disable flags (TTL=0 disables reads but not writes)
- [ ] Spec divergence (code says X, spec says Y)
- [ ] Silent error swallowing (`except: pass`)
- [ ] Off-by-one and falsy-zero (`if x:` where `x == 0` is valid)
- [ ] Numerical formulas from library metrics (re-derive from docs — squared L2 vs cosine, etc.)
- [ ] `assert` in non-test code for load-bearing checks (promote to `RuntimeError`)
- [ ] Positional CLI args taking user prose (need `nargs=-1`)
- [ ] Hallucinated names (function/class names that don't exist in the codebase)

---

## CRITICAL

> Guaranteed crash, data loss, security hole, spec violation, or core feature broken.

### C1. <title>
- **Location**: `file.py:line`
- **Description**: <what's wrong; quote the exact lines>
- **Impact**: <what breaks, who notices, when>
- **Fix**: <specific code change>

---

## MAJOR

> Likely bug in common usage, broken UX in expected scenarios.

### M1. <title>
- **Location**:
- **Description**:
- **Impact**:
- **Fix**:

---

## MINOR

> Edge cases, cosmetic, maintainability, test gaps.

### N1. <title>
- ...

---

## TOP 5 FIXES TO MAKE FIRST

1. **<id> — <title>**: <one-paragraph why this is #1>
2. ...
