# Skill: Skill Audit

## Rule
At every end-of-project retrospective, record which skills the project actually used. Every 3 retrospectives, audit the aggregate: **keep** skills cited in any recent project's "What worked"; **modify** skills cited in "What failed" (should have caught X); **flag for review** skills with zero citations across 3 consecutive projects. Decisions are qualitative; counts only surface candidates.

## Why this exists
Skills are markdown files loaded into agent context. Each one costs tokens (read on every invocation that loads it) and attention (the model weighs more things and trusts each one less). A package that only grows degrades both inference efficiency and human navigability over time. Without a pruning ritual, every retrospective adds skills and none ever leave.

The instinct to "keep everything just in case" is real — a skill you delete might be exactly the one you need next quarter. But the cost of carrying dead skills is paid every single agent invocation. The cost of re-deriving a useful-but-deleted skill is paid once, at the next incident, with full retrospective context to motivate it.

**Source**: Cortex (second-brain RAG) retrospective. The over-split / re-merge cycle for the v0.3.0 skills (Insight #6: *"same trigger + same action → one skill, multiple bullets"*) is the prevention-side discipline. This skill is the cure-side mirror — handling bloat that accumulates *despite* discipline at add-time, because the model's read of "useful" shifts as projects shift.

## How to apply

### At every project retrospective: tag usage

The retrospective template includes a **"Skills used this project"** section. List every skill that was:
- Cited in a plan, review, or implementer prompt
- Composed into the project's CLAUDE.md
- Referenced in commits, agent journal entries, or decision logs
- Implicitly applied (i.e., you would have made the same call without the file, but the file was the rule you were following)

One name per line. Takes 2 minutes. Honesty matters more than completeness — a skill you "should have used but didn't" is *not* a usage citation.

```markdown
## Skills used this project
- workflow/spec-first
- workflow/pm-checklist
- engineering/preserve-existing
- engineering/implementer-handoff
- quality/adversarial-review
- quality/non-negotiable-paths
```

### Every 3 retrospectives: aggregate audit

Open the last 3 retrospective files. For each skill in the package, count citations across:

| Where cited | What it means | Verdict |
|------|------|---------|
| "What worked" | Earned its rent | **Keep** |
| "What failed" (should have caught X) | Rule exists but didn't fire / was insufficient | **Modify** — sharpen, add patterns, lower threshold for triggering |
| "Skills used this project" only | Loaded but didn't cause a notable win or loss | **Keep** (load-bearing background) |
| 0 citations across 3 projects | Possible dead weight | **Flag for review** (see below) |

### Reviewing a flagged skill

Flag ≠ delete. Open the file and ask, in order:

1. **Is the source incident still a real failure mode?** Library upgraded, model improved, pattern shifted? If the original bug class no longer exists, the skill probably shouldn't either.
2. **Has the skill become implicit?** Would I apply the rule even without the file? If yes, the file is dead weight — the lesson is internalized.
3. **Has it been superseded?** A newer skill covers the same ground with more nuance? Merge or delete.
4. **Is it a non-negotiable insurance policy?** Some skills (`non-negotiable-paths`, `preserve-existing`) exist because their failure mode is catastrophic when it does fire. Low frequency ≠ low value. **Keep these regardless of citation count.**

Keep, modify, or delete with an **explicit reason recorded in the next CHANGELOG entry** — even when keeping. The reason matters: future-you re-reads the changelog and wants to know "why is this still here."

### Hard delete vs archive

- **Hard delete**: remove the file. Use when the skill is clearly obsolete or duplicated. The retrospective + changelog history is enough provenance.
- **Archive** (move to `archived/` subdirectory): use only when the skill might re-earn its keep — e.g., a defensive pattern that doesn't fire now because the tooling defaults changed, but could return if the tooling regresses.

**Default to hard delete.** Archives accumulate the same bloat the audit is meant to prevent. Use archive sparingly; remember that git history preserves the file even after deletion.

### Cadence

Default: audit every 3 retrospectives. Adjust based on package velocity:

- **High velocity** (3+ new skills per quarter) → audit every 2 retrospectives
- **Steady state** (≤1 new skill per quarter) → audit every 4 retrospectives
- **Stagnant** (no new skills, no recent retrospectives) → still audit quarterly; stagnant packages are often the ones carrying the most dead skills

### Things NOT to use as audit criteria

- **Raw token count** — small skills can be load-bearing (a one-line rule preventing a catastrophic bug class earns its rent regardless of length)
- **"I haven't re-read it lately"** — some skills are reference checklists, not prose for re-reading
- **Polish or word count** — how long or pretty the file is doesn't track value
- **Whether it fired in the most recent project** — single-project gaps are noise; the 3-project window is the smoothing
- **Vibes** — if you can't articulate the reason for deletion, the skill stays

## What this prevents
- Skill bloat that degrades agent context efficiency at the 25+ skill scale
- Skills with no live incident memory ("why is this here? nobody remembers")
- Markdown packages that turn into shrines — visited, never edited
- The opposite of the over-split trap: skills that should have been merged piling up instead

## Anti-pattern

**Auto-deletion by quantitative threshold.** The deletion decision is qualitative — "is the source incident still a real failure mode for my work?" — and needs a human in the loop. Any tooling here is for **aggregation** (counting citations across retrospectives), never for **decision**. Tools that auto-delete will eventually delete `non-negotiable-paths` after one quiet quarter; the cost of that deletion is the next auth bug.

**Aggressive pruning** that deletes skills which haven't fired *yet* because the relevant project hasn't come up. The 3-project window is meant to give skills time to be relevant. Don't shorten it to 1.

**Skipping the audit because the package "feels fine."** That's the signal *to* audit, not the signal to skip. Bloat doesn't announce itself. It accrues quietly until the next agent invocation is twice as expensive as it needs to be.

## Related skills
- `[[retrospective]]` — the audit runs as part of the retrospective ritual; the "Skills used this project" tagging is added to the retrospective template
- `[[non-negotiable-paths]]` — non-negotiables are never deletion candidates regardless of citation count; their value is insurance, not frequency
- The Cortex retrospective's Insight #6 ("same trigger + same action → one skill, multiple bullets") is the **add-time** discipline; this skill is the **review-time** discipline. Both run; one prevents bloat at creation, the other removes bloat that slipped through.
