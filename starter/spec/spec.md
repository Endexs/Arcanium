# {{PROJECT_NAME}} — specification

> The source of truth. Every disagreement between plan / implementer / reviewer is resolved by reading this file. If the spec is silent, update the spec first, *then* the code.

## §1 — What this is

> One paragraph. State what the project is and who it's for. End with one sentence about what it explicitly is NOT (saves a long argument later).

## §2 — User stories

> 3–5 concrete user moments. Each in the form:
> *"As <role>, I want to <action>, so I can <outcome>."*
>
> Concrete > comprehensive. Each story should map to a phase in §7.

- ...

## §3 — Architecture

> Components and how data flows between them. A diagram is welcome; a list is fine. Name each component as you'll name it in code.

## §4 — Data model

> Schemas, dataclasses, table definitions. Include every field with type. If you have an embedding/vector store, write the distance metric here explicitly (squared L2 vs cosine vs L2 — see Cortex retro for why).

## §5 — Interface

> CLI commands and flags, or API endpoints and request/response shapes. Include error format (status codes, error body) — agents will pattern-match on it.

## §6 — Non-negotiables

> Code-enforceable invariants. Write each so you could turn it into a `raise RuntimeError(...)` line. If you can't, the non-negotiable isn't sharp enough.
>
> Use `raise RuntimeError(...)`, NEVER `assert` — asserts are stripped under `python -O`.

- ...

## §7 — Phase plan

> Phases 1..N. Each phase ships independently (one commit / one PR per phase). Each phase has its own PM checklist and review.

### Phase 1 — <name>
- Goal:
- Spec sections satisfied: §x, §y
- Out of scope for this phase (carry-forward from §9):

### Phase 2 — <name>
- ...

## §8 — Success criteria

> How you know you're done. Concrete and verifiable. "Users like it" is not a success criterion; "I used it personally every day for a week without papercuts" is.

## §9 — Out of scope

> Explicit cut list. Things people might assume you're building that you're NOT. Add to this whenever scope creep tries to push something in. See `workflow/scope-cut-list`.

- ...
