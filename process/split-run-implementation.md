# Skill: Split-Run Implementation

## Rule
When a plan generates more than ~6 files, partition it into Parts of 3-4 files each in dependency order. Generate each Part separately, injecting prior Parts as interface context. This eliminates output truncation from token limits.

## Why this exists
On the LLM Gateway project, Phases 6 and 7 both hit silent token truncation. Pro stopped generating partway through `test_cli.py`. No error, no warning — just an incomplete output. The bug was only caught by manual inspection. The Phase 7 test file had to be rewritten by hand.

Output truncation is invisible to the agent. The only solution is to keep each run small enough that truncation can't happen.

## How to apply

### Plan format
Every plan's "Files to output" section uses Part annotations:

```markdown
## Files to output

**Part 1 — library layer**
- `myproject/sessions.py`
- `myproject/storage.py`

**Part 2 — pipeline and CLI**
- `myproject/pipeline.py`
- `myproject/cli.py`

**Part 3 — tests**
- `tests/test_sessions.py`
- `tests/test_cli.py`
```

### Partitioning rules
- **Part 1**: files with no dependencies on other new files in this phase (the foundation)
- **Part 2+**: files that depend on prior Parts' outputs
- **Last Part**: tests, always (they depend on the production code)
- **Target**: 3-4 files per Part, max 6
- **Order**: by dependency, not by importance

### Run sequence
```bash
# Part 1 — no prior context needed
agent --plan plan.md --part 1 --out output-part1.md

# Part 2 — sees Part 1's generated interfaces
agent --plan plan.md --part 2 --prior output-part1.md --out output-part2.md

# Part 3 — sees both prior parts
agent --plan plan.md --part 3 --prior output-part1.md output-part2.md --out output-part3.md

# Apply all parts at once
apply output-part1.md output-part2.md output-part3.md
```

### Prior context injection
When generating Part N, the agent receives:
- The full plan (so it understands the broader intent)
- A "SCOPE FOR THIS RUN" instruction listing only Part N's files
- Each prior Part's `### FILE:` blocks as `### PRIOR FILE:` blocks (treated as already-committed code)

The agent must match exports from prior Parts exactly — function signatures, return types, class names, imports. It does not redefine anything from a prior Part.

### When to skip
For small features (3 files or fewer), just run a single pass. The Part overhead isn't worth it.

## What this prevents
- Silent truncation that ships incomplete code
- Manual rewrites of files the agent failed to generate
- Wasted Pro tokens on runs that don't complete
- Discovery of missing files days later when tests fail

## Implementation requirements
Your agent runner (e.g., `run.py`) needs:
- `--part N` flag that reads Part annotations and scopes output
- `--prior FILE [FILE...]` flag that injects prior outputs as context
- `--list-parts` for a dry-run check of partitioning
- Detection of unclosed code fences as a truncation warning

Your applier (e.g., `apply.py`) needs:
- Accept multiple output files as positional args
- Run tests once at the end, not per Part

## Anti-pattern
Partitioning randomly or by file size rather than by dependency. If Part 2 references a function from Part 1, the agent must see Part 1's output when generating Part 2. Partitioning that breaks this rule defeats the purpose.

## Real example
LLM Gateway Phase 7 (before this skill existed):
- 10 files in one Pro run
- Token limit hit at file 9
- `test_cli.py` truncated silently
- Caught by manual inspection; tests had to be added by hand

After this skill:
- Same 10 files would be partitioned as Part 1 (sessions.py + storage.py), Part 2 (providers x3), Part 3 (pipeline.py + cli.py), Part 4 (test_sessions.py + test_cli.py)
- Each Part runs cleanly within token limits
- No truncation
- Full file list applied atomically at the end
