# Skill: Spec Coach

## Rule
When working on `spec/spec.md` or `agents/planner/pm-checklist.md` and a PM-owned section is empty or too thin to plan against, the agent runs a **Socratic loop**: asks open, pointed questions, records the user's answers progressively into the spec as `[DRAFT FROM COACH SESSION]`, and **never invents content**. The coach is the cure side of [[spec-first]]'s gap discipline: gap-discipline refuses to invent on a blank; coach helps the user fill the blank well.

This skill defaults to ON. Whenever the agent encounters an empty PM-owned section (§1 What this is, §2 User stories, §6 Non-negotiables, §8 Success criteria), it invokes the coach loop unless the user explicitly says "skip" or "I'll fill it later."

## Why this exists
Solo dev with weak PM/principal-engineer experience writes specs that are technically valid but practically underwritten: hand-wavy "what this is" sections, missing non-negotiables, success criteria that default to "users like it." Gap-discipline catches the empties but doesn't help the user fill them. Without coaching, the user fills `[GAP]` markers with whatever they can think of unaided — the exact input the methodology was designed to interrogate.

The coach exists to bracket invention from both sides: the gap-discipline rule blocks the agent from inventing content; this rule helps the user produce real content. Together they prevent both "agent confabulates a §1" and "user writes a vague §1 because nothing pushed them to be specific."

Source: user feedback during Arcanium v0.5.x usage — *"me just writing it by myself I don't think is that effective without the necessary technical knowledge."*

## How to apply

### When to invoke (default behavior)
- Empty PM-owned spec section encountered during session-start review
- Section content is present but vague ("a tool for productivity," "make it easy to use," "be reliable") — coach treats vague as a soft blank
- User says: `coach me on §X`, `grill me on §X`, `help me tighten §X`, `I don't know what to write here`

### When NOT to invoke
- User has clear answers already → just transcribe per `[[pm-checklist]]`
- User says `skip §X` or `I'll fill it later` → keep as `[GAP]`, move on
- Engineering-owned sections (§3 Architecture, §4 Data model, §5 Interface) → draft strawman per gap-discipline, don't grill
- Collaborative sections (§7 Phase plan, §9 Out of scope) → propose options, don't grill
- User is in execute mode for an existing well-spec'd project

### The loop

1. **Pick ONE section.** Don't grill multiple sections in parallel. Start with the most upstream (§1 → §2 → §6 → §8).
2. **Ask 1-2 questions at a time.** Not 5. Cognitive bandwidth matters.
3. **Open questions, never leading.** "What would have to be true for X?" not "isn't X important?" The coach asks; the user decides.
4. **After each answer, restate what you heard** so the user can correct. *"I'm hearing that the primary user is someone who already takes notes in markdown and wants retrieval over them — confirm?"*
5. **Write the answer progressively into spec.md** marked `[DRAFT FROM COACH SESSION]`. User sees the spec build in real time and can edit inline.
6. **Soft cap at 5 question rounds per section.** After round 5, ask: *"Want to keep refining or lock this section and move on?"* User decides. Default is move on.
7. **Stop conditions** (any one triggers stop):
   - User says "locked"
   - 5-round soft cap reached and user picks "move on"
   - Section passes the sniff test (see below)
   - User says "skip" or "I'll fill it later"

### Sniff test for "tight enough to plan against"

A PM-owned section is tight enough when an implementer reading it cold could:
- §1: name the project's load-bearing job in one sentence
- §2: identify the first thing a user does and the result they expect
- §6: list at least one specific constraint that would fail a build
- §8: state a measurable signal for "we shipped"

If the section content doesn't pass this, you're not done — but you may stop anyway if the user explicitly says so.

### Anti-leading discipline

The coach is forbidden from:
- Recommending what the user *should* want ("most projects pick X")
- Filling in answers with "based on similar projects, you probably want Y"
- Inferring intent from project name or repo hints
- Pushing toward any specific stack, architecture, or feature

Allowed:
- Asking open questions
- Restating what was heard (verbatim or close)
- Pointing out internal inconsistencies (*"§2 says X but §1 says Y — which is true?"*)
- Surfacing implied constraints (*"§6 says 'low latency' — slower than what threshold breaks the user's workflow?"*)
- Confirming the user's stated decisions (transcription is not invention)

### Question banks

Ship-defaults; the agent improvises within these patterns. Pick 1-2 per round.

#### §1 — What this is
- Describe a specific 30-second moment when someone reaches for this. Who, where, what just happened?
- What's the *worst* word someone could use to describe what this does? Why is that wrong?
- If this tool didn't exist tomorrow, what's the next-best thing the user would do?
- What's the one sentence you'd put on the README's first line?
- Who is this explicitly NOT for?

#### §2 — User stories
- Walk me through the first 5 minutes of a new user's experience.
- What's the user doing *before* they reach for this? What are they doing *after*?
- Name three users by job title or role. Are their needs different enough to matter?
- What's the user story you almost wrote but cut? Why did you cut it?

#### §6 — Non-negotiables
- What would embarrass you if it shipped this way?
- What does your tool guarantee that other tools in this space don't?
- What does it cost — for the user, for you, financially or in trust — when this guarantee fails?
- Is there a guarantee you want to make but can't enforce in code? (That's a non-goal, not a non-negotiable.)
- Can you write this as a single `raise RuntimeError(...)` line? If not, sharpen it.

#### §8 — Success criteria
- How will you know in 30 days whether to keep building?
- What's the smallest possible "yes, this works"?
- If only one user uses this — you — what does success look like at 1-week, 1-month, 6-months?
- What's the failure mode that would make you abandon the project?

## What this prevents
- Specs that pass gap-discipline (no blanks) but are still too thin to plan against — the "I filled it but I don't know what I meant" failure mode
- Solo devs ending Phase 1 still uncertain what they're building
- Wasted Phase 1 work on a spec that should have been refined first
- The skill gap that traps users without PM/principal-engineer experience from getting the most out of the methodology

## Anti-pattern

**Grilling forever for the sake of thoroughness.** Diminishing returns hit fast. The soft cap exists because 5 well-aimed questions usually beats 15 mediocre ones. If round 5 hasn't gotten you to "tight enough," ask whether the section is the right question, or whether the user's idea is still too vague to specify at all (and may need to incubate longer before bootstrapping).

**Leading the witness.** A coach that subtly steers the user toward predictable answers ("most projects choose X") fails the rule. The coach's value is asking questions the user wouldn't think of themselves, not nudging them toward conclusions the agent prefers.

**Composing the coach with a checklist that's already filled.** If the user has answered the PM checklist, those answers ARE the section content. Transcribe, don't re-interrogate. The coach is for when the checklist itself is too thin.

## Related skills
- `[[spec-first]]` — coach fills the gaps; gap-discipline (in CLAUDE.md) blocks invention. Two halves of the same loop.
- `[[pm-checklist]]` — checklist is for *"I know what I want, just record it."* Coach is for *"I don't yet."* Different moments, complementary use.
- `[[feasibility-first]]` — one §6 coach question is *"what external dependency does this rely on?"* — the answer feeds the feasibility probe directly.
- `[[scope-cut-list]]` — §9 cut-list questions can use coach techniques but aren't grilled by default (collaborative section, propose options instead).
