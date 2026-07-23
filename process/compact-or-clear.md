# Skill: Compact or Clear

## Rule
Every turn re-sends the **entire** conversation to the model, so context size sets both the **cost** and the **latency** of every message. When a session gets long, the agent should proactively tell the user whether to **`/clear`** (wipe context), **`/compact`** (summarize and continue), or **keep going** — and name the one checkpoint to save first. Don't wait to be asked, and don't silently let a bloated session bleed tokens on every turn.

## Why this exists
Agentic sessions accumulate dead weight fast: full-file reads, long command output, pasted logs, and several finished tasks all pile up in one thread. The user keeps paying for that history on *every* subsequent message — in dollars and in wait time — usually without noticing, because the cost is invisible and gradual. Auto-compact eventually fires, but at a random point mid-thought and on the tool's terms, not the user's. A cheap, deliberate reset at the right moment is one of the highest-leverage habits for a solo dev running long agent sessions. This is the session-level sibling of `[[split-run-implementation]]` (which keeps a *single* large change from blowing the token budget).

## How to apply

### The call
When the session feels long/slow, a task just finished, or the user asks "should I compact or clear?", give **one** recommendation — don't recite the rules:

| Situation | Recommend | Why |
|-----------|-----------|-----|
| Task done; next work is **unrelated** | **`/clear`** | Old history has zero bearing on what's next; full reset is cheapest + fastest. |
| Same task continuing, but history is **bloated** (big reads, long logs, many iterations) | **`/compact`** | Keep the thread alive, drop the dead weight. |
| Context **> ~80%** used and task **not** done | **`/compact` now** | Deliberate beat > auto-compact firing at a random point mid-thought. |
| Context **> ~80%** and task **is** done | **`/clear`** | No reason to summarize finished work. |
| Context still modest (**< ~50%**), mid-flow | **keep going** | Resetting now just discards useful working memory. |
| Mid **critical reasoning** a summary could corrupt | **checkpoint first**, then reset | A summary is lossy — protect load-bearing detail before shrinking. |

Exact token counts aren't visible from inside the conversation: ask the user to run **`/context`** for a precise %, and treat "auto-compact already fired once" as a strong "it's big" signal.

### Signals it's time (any 2+ → act)
- `/context` > ~70–80%, or auto-compact has already fired this session.
- Replies feel slower than they did early in the session (latency tracks context size).
- Several **distinct, completed** tasks stacked in one thread.
- Large one-off artifacts linger that you no longer need (full-file reads, long diffs, big logs).
- The user is **switching topics** — new feature/bug/area unrelated to the thread → prefer **`/clear`**.

### Checkpoint before resetting
`/clear` loses everything; `/compact` keeps only what the summary captures. Before either, persist anything you'd hate to re-derive:
- **Commit** code (or state plainly what's left uncommitted).
- Write open decisions / TODOs / the **exact next step** to the plan doc, a scratch file, or memory — so a fresh or compacted context resumes cleanly. (This pairs with `[[persist-load-bearing-findings]]`: anything you'd hate to re-derive goes to a file *before* the reset, because chat text does not survive `/clear`.)
- `/compact` accepts focus hints — e.g. `/compact keep the auth decisions and the failing test` — to steer what survives.

### Prevention (so resets are rarer)
- **Delegate big searches/reads to subagents.** The raw dumps stay in the subagent; only the conclusion returns to the main thread.
- **Write intermediate results to files**, not into the transcript.
- **One session per task** — starting unrelated work in the same thread is the #1 source of bloat. Clear and start fresh instead.
- Keep durable facts in **memory files** so a `/clear` costs nothing.

### Quick heuristic
> **Task done + new topic → `/clear`. Same task but heavy → checkpoint, `/compact`. Still lean → keep going.**

## What this prevents
- Paying full-context cost and latency on every turn of a session that's 80% stale history.
- Auto-compact firing at the worst possible moment and summarizing away a detail you needed.
- Losing in-progress decisions to a reset because nothing was checkpointed first.
- Threads that sprawl across three unrelated tasks, each slowing the others down.
