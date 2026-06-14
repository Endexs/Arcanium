# Skill: Disable Flag Both Paths

## Rule
When implementing any disable mechanism (TTL=0, `--no-cache`, feature flag off, `--dry-run`), apply the disable to BOTH the read path AND the write path. A disable that only blocks one side is a bug.

## Why this exists
On the LLM Gateway project, `cache.ttl_seconds = 0` was supposed to fully disable caching. The implementer correctly made `cache_get` return `None` when TTL was 0, but `cache_put` still wrote entries. The cache was "disabled" for reads but accumulating entries forever on writes.

This is a common bug class: disable mechanisms applied to half the system.

## How to apply

### Symmetric checks
Every disable mechanism must have a check at every place it could affect:

```python
# Read path
def cache_get(key, ttl):
    if ttl == 0:
        return None
    # ... query DB

# Write path
def cache_put(key, value, ttl):
    if ttl == 0:
        return  # no-op when disabled
    # ... write to DB
```

Not just one or the other. Both.

### Common disable mechanisms to check
- TTL = 0 or TTL = None → disable cache reads AND writes
- `--no-cache` flag → bypass cache lookup AND cache write
- `--dry-run` → skip all side effects: DB writes, API calls, file modifications, log entries
- Feature flag off → skip the feature entirely on both UI and backend
- `--quiet` → suppress logging on success AND on failure (or document the asymmetry)
- Read-only mode → block all writes everywhere

### Plan format requirement
Plans that introduce a disable mechanism must enumerate every affected path:

```markdown
## Disable: --no-cache
| Path | Behavior when --no-cache |
|------|--------------------------|
| Cache lookup | Skip (do not query) |
| Cache write | Skip (do not insert) |
| Cache event logging | Skip (no "miss" recorded) |
| Stats reporting | Unaffected |
```

The implementer ticks each row. The reviewer verifies.

### Implementer behavior
If the plan only specifies the disable on one path, the implementer:
1. Implements that path as specified
2. Flags a `### GAP:` for every other path that might be affected
3. Does NOT silently apply the disable to other paths (that's a judgment call for the user)

## What this prevents
- "Caching is off but the table keeps growing" bugs
- `--dry-run` that still hits the database
- Feature flags that hide the UI but still execute the backend code
- Read-only mode that allows certain "harmless" writes that turn out not to be harmless

## Anti-pattern
Treating one direction as the "main" path and the other as an afterthought. Reads and writes are equal partners in a disable mechanism. Both must be considered explicitly.

## Real example
Phase 4 of the LLM Gateway:
- Spec: "TTL of 0 disables caching entirely"
- Plan: specified `cache_get` returns None when TTL=0
- Plan: did NOT specify `cache_put` behavior when TTL=0
- Implementer: implemented only what the plan said
- Bug: cache table filled up despite caching being "disabled"

After this skill: the Phase 7 spec for session cache bypass explicitly stated both paths. The plan included a table. The implementer applied both. The reviewer verified both. No bug.
