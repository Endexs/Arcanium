# Skill: PM Checklist

## Rule
When a spec has many decisions the user (not the agent) owns — product positioning, UX, scope cuts, defaults, success criteria — produce a single PM-style checklist file rather than asking inline questions one at a time.

## Why this exists
On the Cortex (second-brain-v2) project, after I'd drafted the spec, there were ~25 small decisions the user needed to make: command names, flag names, citation format, error message tone, default top-k, default chunk size, source paths, privacy patterns, success criteria, non-negotiables, phase acceptance.

Without a checklist, this becomes a 20-message ping-pong over chat:
- Agent asks one question at a time
- User has to context-switch back into product-thinking for each answer
- The full decision surface is invisible — no way to see "here's everything you need to call"
- It's hard to track which decisions are still open
- Easy defaults get the same airtime as hard scope calls

The checklist converts this into one async pass. The user sees every decision at once, ticks the obvious ones (defaults are stated, silence = accept-default), and spends real attention only on the hard product calls. The user explicitly validated this pattern: *"I really like the pm-checklist, it makes decisions more clear and less convoluted."*

## How to apply

### When to use it
- A fresh spec needs PM sign-off and has **5 or more PM-shaped decisions**
- You would otherwise ask a long sequence of clarifying questions
- The user has positioned themselves as the product owner (e.g., *"I feel more like a PM in my role"*)

### When NOT to use it
- Single isolated decision (just ask inline)
- The user has said *"just pick something reasonable"* or is in execute mode
- Engineering-only choices where the user has no PM stake
- The user has already filled out a recent checklist and you're just iterating

### Where to put it
Save as a file in the planning artifacts (e.g., `agents/planner/pm-checklist.md`). Not inline in chat. The file is the work surface; chat is just the handoff.

### Structure
1. **Header**: scope of the checklist, instruction that silence = accept-default
2. **Numbered sections** grouping related decisions (Naming, UX, Scope Review, Defaults, Privacy/Safety, Success Criteria, Phase Acceptance — typical set)
3. **One checkbox per decision**, with:
   - Plain-English question
   - The default you'd pick if they don't override (stated explicitly)
   - Trade-offs only if non-obvious
4. **High-leverage flag**: identify 1-2 sections worth doing first (usually Scope Review + Success Criteria)
5. **Approval gate at the bottom**: when boxes are ticked, what happens next

### Separation of ownership
At the top of the file, explicitly separate **PM ownership** (UX, scope, success criteria, defaults to validate, non-negotiables) from **engineering ownership** (schemas, retry semantics, internal APIs). Say *"Engineering items are deliberately omitted — those are mine."* This stops the user from over-engaging in implementation choices they don't want to make, and stops you from punting product decisions back to them.

### After the user fills it out
1. Read every checked item AND every unchecked item (silence = accept-default)
2. Flag **pushbacks**: decisions you'd argue against, with reasoning. Don't just rubber-stamp.
3. Flag **clarifications needed**: items where their answer is ambiguous or absent
4. Sync confirmed decisions back into `spec.md` and `CLAUDE.md`
5. Move to the next phase

### Multi-phase projects: carry-forward and shrinkage

After Phase 1, every subsequent phase's checklist gets a **Carry-forward** section at the top — a one-paragraph summary of decisions from prior phases that still apply. The implementer reads this and treats those items as settled; the user doesn't re-litigate them.

```
## Carry-forward (from Phase 1)
- Citation format: `[N]` footnote markers, listed under a `Sources:` block (Section 3.2)
- Default top-k: 5 (Section 5.1)
- Source-attribution non-negotiable: every `ok` answer cites ≥1 source (Section 9)
- Tone: terse over chatty; refuse to fabricate over guess (Section 4.3)
```

**Why**: Without this, late-phase checklists either (a) silently drop earlier decisions, leaving the implementer guessing, or (b) re-ask them, costing the user attention they already spent. The carry-forward block makes settled decisions explicit and the new checklist visibly shorter.

**Heuristic for shrinkage**: Phase-N checklist should have roughly half the decisions of Phase-(N-1). If Phase 3's checklist is the same length as Phase 1's, something is wrong — either you're re-litigating settled questions, or the spec wasn't really specified up front. Investigate before continuing.

**Source**: Cortex (second-brain RAG) Phase 2–4. Phase 1 checklist had ~25 decisions; Phase 2 had ~12; Phase 3 had ~6; Phase 4 had ~4. The shrinkage came from explicit carry-forward of settled decisions, not from cutting the checklist quality.

## What this prevents
- Decision churn during implementation (no "wait, what did we decide about X?")
- The agent silently making product calls the user owned
- Inline question fatigue that pushes the user to disengage and let you decide
- Sequential question dependencies ("if you said X to question 3, then question 5 becomes...") that make backtracking expensive
- Mixing product and engineering decisions in the same conversation

## Anti-pattern
Filling the checklist out for the user "to save them time." The whole point is that *they* make the product calls — that's why the file exists. If you find yourself ticking the boxes, stop and ask whether the task actually needs a PM checklist at all. If it doesn't, just make the call yourself and own it. If it does, the user has to do the work.

A second anti-pattern: turning every spec review into a checklist. If the spec is small enough that you have 1-2 questions, the checklist ceremony costs more than it saves. The bar is real: 5+ PM-shaped decisions, or a clear signal that the user is in product-owner mode and wants the full surface visible.

## Related skills
- `[[spec-first]]` — the checklist makes sense only when a spec already exists to anchor the decisions
- `[[scope-cut-list]]` — one section of the PM checklist is typically "walk each cut-list item and confirm keep / promote / abandon"
- `[[decision-log]]` — the checklist captures the *user's* decisions; the decision log captures the *agent's*. They feed different audiences but are complementary
