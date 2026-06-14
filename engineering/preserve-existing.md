# Skill: Preserve Existing

## Rule
When modifying an existing file, preserve ALL defensive patterns not explicitly mentioned by the plan. The implementer's job is to insert the planned changes, not to clean up code it doesn't understand.

## Why this exists
On the LLM Gateway project (Phase 4), the implementer rewrote `cli.py` based on the Phase 4 plan. The plan didn't mention the dashboard import, so the implementer removed it — it looked like cruft from outside the plan's scope. This silently broke a Phase 3 fix.

This is the single most expensive failure mode in agent-driven coding. Agents that output whole files will systematically delete patterns they don't recognize as relevant.

## How to apply

### The hard rules
- `try/except` blocks: preserve all of them, even if you don't understand why they're there
- `err=True` on `click.echo`: preserve every instance
- `file=sys.stderr` on `print`: preserve every instance
- Imports inside functions (lazy imports): preserve them; they exist for a reason
- Decorators on functions: preserve them all
- Comments that explain "why": preserve them; comments that explain "what" can be removed if the code is clear

### The plan format that enforces this
When the plan needs to modify a file, it uses `# ... existing code ...` markers:

```python
# ... existing code ...

def new_function():
    return "new"

# ... existing code ...
```

The implementer must reproduce the FULL existing file and insert only the shown changes. Never use the snippet alone as the new file contents.

### When in doubt
If the implementer encounters code in an existing file that the plan doesn't mention, the default is **leave it alone**. If the implementer believes the code should be removed, it must:
1. Note this in the agent journal
2. Flag it as a `### GAP:` in the output
3. Continue without removing it

The user reviews gaps; the agent does not unilaterally clean up.

### apply.py regression warnings
Add post-apply checks that compare old file content vs new:
- `try/except` count dropped → warn
- `err=True` count dropped → warn
- `file=sys.stderr` count dropped → warn
- File line count dropped by >20% → warn

These warnings catch the most common silent regressions even if the agent forgets the rule.

## What this prevents
- Silently regressing previous bug fixes
- Removing defensive patterns the implementer doesn't understand
- The "Phase N broke a Phase N-3 fix" cascade
- Whole-file rewrites that lose accumulated knowledge

## Anti-pattern
Treating the plan as the complete specification of what should be in the file. The plan describes **changes**, not the **final state**. The current file is the baseline; the plan is the delta.

## Real example
Before this skill was codified:
- Phase 3 added: `try: from gateway.dashboard import dashboard ... except ImportError: pass`
- Phase 4 plan said: "rewrite cli.py to add caching commands"
- Phase 4 implementer dropped the dashboard import block (not mentioned in plan)
- Tests failed; bug discovered by accident; required a hot-fix

After this skill: the Phase 7 implementer was given `# ... existing code ...` markers and the rule above. It produced complete files with all defensive patterns intact. No regressions.
