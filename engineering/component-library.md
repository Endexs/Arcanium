# Skill: Component Library (Via Negativa)

## Rule
Before implementing or reviewing any code in a domain covered by `components/` (payment, auth,
db, and any domain added later), read that domain's `ANTIPATTERNS.md` first — as a checklist of
failure modes to explicitly rule out in your specific context — and only then consult
`PATTERNS.md` for a reference shape. A `PATTERNS.md` entry may never be written or accepted
without at least one `ANTIPATTERNS.md` entry it is a direct response to.

## Why this exists
Every other skill in this package captures *process* lessons — how to plan, review, retro. This
one captures *domain* lessons — the specific, recurring shapes of payment/auth/db code that get
rebuilt from scratch on every new project, at the same real cost each time: airbnb-website hit a
Stripe-lock-across-network-call bug, a refund race, an SDK-shape assumption, and a migration gap
that all had close cousins already documented in other projects' retrospectives — none of which
were reachable from a fresh project's starting point.

Via negativa (Nassim Taleb's framing, adopted here deliberately): improvement by *removal* is
more robust than improvement by *addition*. A list of "here's what's broken and why" is falsifiable
and sourced — you can check whether your code reproduces the conditions that broke something
before. A list of "here's best practice" invites pattern-matching on familiarity ("this looks
like the tutorial, ship it") without checking whether your context is actually safe.

## How to apply

### Before implementing
1. Identify which `components/<domain>/` your change touches (a new gateway integration → 
   `payment/`; a new login/session mechanism → `auth/`; a schema change or new query pattern →
   `db/`).
2. Read that domain's `ANTIPATTERNS.md` in full. For each entry, ask explicitly: "does my
   context reproduce the conditions that caused this?" — not "have I heard of this before."
3. Read `PATTERNS.md` for a reference shape, noting which antipattern each pattern responds to.
   If your shape differs from the pattern, that's fine — but re-check it against every
   antipattern in the domain before calling it done.

### In review
The reviewer checks the same list independently — per `quality/adversarial-review.md`, a
separate agent/model, assuming bugs exist. A review of payment/auth/db code that doesn't
explicitly check the relevant `ANTIPATTERNS.md` has skipped ground truth, not just a nice-to-have.

### Adding a new entry (the discipline that keeps this file honest)
1. **Antipattern first, always.** When a retrospective's root cause is domain-specific, append
   to that domain's `ANTIPATTERNS.md` — cite the source project + retrospective, and tag the
   evidence tier: "fixed after a real incident" (something broke, here's the fix) vs. "designed
   against, before an incident occurred" (an explicit non-negotiable a project committed to
   proactively, with its own stated rationale). Both are valid; don't blur them into each other.
2. **Pattern second, only in direct response.** A `PATTERNS.md` addition must name which
   antipattern(s) it closes. If you can't point to one, it doesn't belong here yet — it's either
   `engineering/boring-tech.md` material (a good general default with no specific incident behind
   it) or not ready to generalize.
3. **New domains** are created the same way — one incident can be enough to seed a domain if it's
   severe (e.g. a first security finding in a `crypto/` or `webhook/` domain), but the domain
   starts with `ANTIPATTERNS.md`, never `PATTERNS.md` alone.

### Distribution
Vendored the same frozen-at-bootstrap way as skills — never live-referenced back to the central
package. `./install.sh --components <project>` (or `--all`). See `components/README.md`.

### Relationship to the retrospective/skill-audit cycle
`lifecycle/retrospective.md` names this as an explicit step: when a phase's root cause is
domain-specific, the antipattern entry is written to `components/<domain>/ANTIPATTERNS.md`
*before* the retrospective entry is considered complete — not as an optional follow-up. This
keeps the component library fed from the same ritual that already produces skill changes, rather
than requiring a second, separately-remembered process.

## What this prevents
- Rebuilding the same payment/auth/db bugs from scratch on every new project
- "Best practice" entries that are really just familiar-looking code, unchecked against any real
  failure
- A component library that silently drifts into generic advice because nobody enforced the
  antipattern-before-pattern ordering
- Treating "green tests" or "looks like the tutorial" as evidence in exactly the domains where
  that has already been proven insufficient (`quality/non-negotiable-paths.md`)

## Anti-pattern
Writing a `PATTERNS.md` entry because it's good design, without a cited antipattern behind it.
This is the single failure mode that would turn this file's own subject into exactly the kind of
unfalsifiable best-practice advice via negativa exists to replace. If you're not sure an entry
qualifies, it doesn't yet — wait for the incident, or don't add it.

## Related skills
- `[[non-negotiable-paths]]` — payment, auth, and db are three of that skill's named
  non-negotiable path categories; this skill is the domain-knowledge complement to its
  process-rigor rule.
- `[[adversarial-review]]` — the reviewer's independent pass is where a missed antipattern is
  most likely to be caught if the implementer skipped this skill.
- `[[retrospective]]` — the feeding mechanism: a domain-specific root cause becomes an
  `ANTIPATTERNS.md` entry as part of writing the retrospective, not after.
- `[[disable-flag-both-paths]]` and `[[defensive-defaults]]` — general engineering skills that
  overlap with domain-specific antipatterns (e.g. a payment gateway's fail-closed check is a
  specific instance of `disable-flag-both-paths`'s general rule); when both apply, cite both.
