# Domain Components — via negativa first

This is a different kind of artifact than `workflow/`, `engineering/`, `quality/`, `process/`.
Those are *process* skills — how to work. This directory is *domain* knowledge — the specific,
recurring shapes of payment, auth, database, and (as they accumulate) other cross-cutting
subsystems every project eventually rebuilds from scratch.

Each domain is a pair of files, and **the order is the point**:

```
components/<domain>/
├── ANTIPATTERNS.md   ← written FIRST. What has actually broken, and why.
└── PATTERNS.md        ← written SECOND, only in direct response to a cited antipattern.
```

## The rule: via negativa

**Get rid of what doesn't work before prescribing what does.** A `PATTERNS.md` entry may not
exist without at least one `ANTIPATTERNS.md` entry it is a direct response to — no
speculative best practices, no "this is just good design" additions. If you can't point to a
real incident (a retrospective, a production bug, a security finding) that a pattern prevents,
it doesn't belong here yet. It probably belongs in `engineering/boring-tech.md` instead, or
nowhere.

This mirrors the discipline the rest of this package already uses for skills — every entry in
`CHANGELOG.md` traces to a cited retrospective — applied one level deeper, to domain code
instead of process.

## Why order matters here specifically

Money, auth, and data-layer code are exactly the paths where "I know the standard pattern"
gives false confidence. The standard pattern is usually *correct in isolation* and *wrong in
context* — a payment gateway shaped exactly like every tutorial, called from inside a database
write lock, causes a real production incident (see `payment/ANTIPATTERNS.md`). Reading the
antipattern first forces the question "does my context reproduce the conditions that broke
this before?" — reading the pattern first invites "this looks like the tutorial, ship it."

## How to use this when implementing

1. **Before** writing (or reviewing) any payment/auth/db/etc. code, read that domain's
   `ANTIPATTERNS.md` in full — treat it as a checklist of failure modes to explicitly rule out
   in your specific context, not background reading.
2. **Then** read `PATTERNS.md` for the reference shape — and note which antipattern(s) each
   pattern responds to; that citation is what makes it trustworthy, not its familiarity.
3. If your project's shape doesn't match any existing pattern, that's fine — implement it, but
   re-check it against every antipattern in the domain before calling it done.
4. See `engineering/component-library.md` for the full discipline this plugs into (when a new
   antipattern gets promoted here, how patterns get cited, how this feeds from retrospectives).

## Distribution

Vendored the same way skills are — frozen at bootstrap, never live-referenced:

```
./install.sh --components <project-dir>     # components only
./install.sh --all <project-dir>            # skills + templates + components
```

## Current domains

- `payment/` — external payment gateways, money movement, refunds
- `auth/` — authentication, session/credential handling
- `db/` — schema evolution, transactions, concurrency at the data layer
- `concurrency/` — DB locks across network calls, blocking I/O in async routes, single-writer
  guards; the canonical home for a lesson that recurred across `payment/` and `db/` in three
  separate incidents (see its `ANTIPATTERNS.md` for why it earned its own domain)
- `llm-integration/` — LLM API calls, vector stores, grounding/citation systems
- `external-integration/` — third-party dependencies, webhooks, feed URLs — validate before you
  build on them (see `workflow/feasibility-first.md`, which this domain applies)

New domains are added the same way: when a retrospective's root cause is domain-specific and
recurs (or is severe enough to seed a domain on one incident, per `component-library.md`),
create `components/<domain>/ANTIPATTERNS.md` first, cite the source, and only then consider a
`PATTERNS.md` entry.
