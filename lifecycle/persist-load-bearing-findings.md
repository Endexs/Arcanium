# Skill: Persist Load-Bearing Findings

## Rule
When a turn surfaces a fact that would cause the same mistake again if forgotten — a live
incident's root cause, a non-obvious operational constraint, an environment quirk learned the
hard way — write it to `CLAUDE.md` or memory **before ending that turn**. Explaining it well in
the chat response does not count. Chat text does not survive `/clear`; only files do.

## Why this exists
On airbnb-website, an agent found a process bound to the app's port, assumed it was a stray dev
process, killed it, and restarted it with the local dev launcher instead of the real
systemd-managed service. This silently disabled the production payment gateway and host email
notifications for ~20 minutes before it was caught. The agent diagnosed this correctly, explained
it clearly to the user in chat, and fixed the running process — but never wrote the lesson to
`CLAUDE.md` or memory. The user cleared the session. In the next session, a different task hit
the same login issue, and the agent made the *exact same mistake again*, because the only copy
of the lesson had been prose in a transcript that no longer existed.

The gap wasn't `/clear` — `/clear` did exactly what it's supposed to do. The gap was treating "I
explained this thoroughly" as equivalent to "I persisted this," when they are different actions
with different survival properties.

## How to apply

### Trigger checklist
Before ending a turn, ask whether it involved any of:
- Diagnosing or fixing a live/production incident
- Discovering a non-obvious operational constraint (deployment mechanism, hidden config
  location, environment-specific quirk) that isn't derivable by reading the code
- Learning a "gotcha" through trial and error that existing docs/CLAUDE.md/memory didn't warn
  about
- The user correcting a wrong assumption in a way that would recur on the next similar task

If yes to any: **write it down now**, in the same turn, before moving on. Don't defer it to "I'll
mention it if it comes up again" — that's exactly the failure mode above.

### Where to persist
| Kind of fact | Goes in |
|---|---|
| Durable project convention/constraint someone would need to *act on correctly* (how to deploy, where secrets live, a hard invariant) | `CLAUDE.md` — checked in, human-auditable, loaded every session unconditionally |
| Decision context, incident narrative, the *why* behind a convention | Memory (`project` or `feedback` type) — can be richer/longer than CLAUDE.md should be |
| Both, when the fact is important enough that redundancy is worth it | Both — CLAUDE.md as the operative instruction, memory as the fuller story |

A one-line mention buried in an unrelated CLAUDE.md section doesn't count either — give it a
clear heading so it's findable, not just technically present.

### The actual test
Not "did I explain this well" but: **if this exact conversation vanished right now, would the
next session still know it?** If the honest answer is no, the turn isn't done yet.

## What this prevents
- Repeating an incident because the lesson only existed in a transcript that got cleared
- "I told you this already" friction where the user has to re-teach the same gotcha
- Operational knowledge staying tribal/verbal instead of becoming part of the project's actual
  source of truth

## Anti-pattern
Writing a thorough, well-reasoned chat explanation of a root cause and treating that as done.
Sounding confident and complete in the response is not the same as being durable. If the
knowledge would matter next session, it needs to survive independent of this one.

## Real example
airbnb-website, 2026-07-07/08: an agent restarted a systemd-managed production service by hand,
silently breaking Stripe and email notifications for ~20 minutes. It was caught, fixed, and
explained clearly — twice, in two different sessions, because the first explanation was never
written anywhere. The fix (this skill's actual application) was two files: a `## Deployment`
section added to the project's `CLAUDE.md` stating "check `systemctl status` before touching any
process on this host; secrets live in `/etc/.../airbnb.env`, not the repo's `.env`", plus a
memory file with the fuller incident narrative. Both were written in the same turn the lesson was
identified, not deferred.
