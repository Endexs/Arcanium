# {{PROJECT_NAME}} — PM checklist (Phase 1)

> **What this is**: items YOU (the product owner) need to decide. Engineering items are deliberately omitted — those are mine.
>
> **How to fill it out**: tick a box and leave a note if you want. Leave blank = accept the stated default. You don't have to engage with items you don't have a strong opinion on.
>
> **If you only do two sections today**: do **§5 Scope** and **§9 Success criteria**. Everything else can default.

---

## §1 — Naming

- [ ] CLI command name? Default: `{{PROJECT_SLUG}}`
- [ ] Repo name? Default: `{{PROJECT_SLUG}}`
- [ ] Tagline (one sentence): _________________________________________

## §2 — UX surface

- [ ] What's the first command a new user runs? Default: `{{PROJECT_SLUG}} --help`
- [ ] Output style — terse or chatty? Default: **terse, no headers unless multi-section**
- [ ] Error tone — apologetic, neutral, or direct? Default: **direct, actionable**

## §3 — Inputs

- [ ] Where does data come from? (folder of files, API, stdin, etc.)
- [ ] What file types / formats are supported?
- [ ] What's the default location for inputs? Default: `~/{{PROJECT_SLUG}}/`

## §4 — Outputs

- [ ] What does the user see when it works? (JSON, prose, table, etc.)
- [ ] What does the user see when it fails? Default: **stderr message + non-zero exit**
- [ ] Persistent state — where does it live? Default: `~/.{{PROJECT_SLUG}}/`

## §5 — Scope (highest leverage section)

- [ ] In scope for v1.0:
  - ...
- [ ] Explicitly out of scope (for the cut list):
  - ...
- [ ] Phase 1 deliverable specifically:

## §6 — Defaults

- [ ] (List 3–6 defaults the agent will pick if you don't override. The agent fills these in as a starting point; you tick or override.)
- [ ] ...

## §7 — Privacy / security

- [ ] Any data that should never be logged or sent to LLMs?
- [ ] API keys / secrets — where do they live? Default: **env vars only, never config files**
- [ ] Multi-user? Default: **single-user (this VPS, this person)**

## §8 — Non-negotiables (code-enforced invariants)

> These will be encoded as `raise RuntimeError(...)` checks. The code refuses to ship without them.

- [ ] Non-negotiable 1: ___________________________________________
- [ ] Non-negotiable 2 (optional): _______________________________

## §9 — Success criteria (highest leverage section)

- [ ] How will you know v1.0 is done?
- [ ] Concrete usage moment (not "users like it"):

## §10 — Phase acceptance

- [ ] What has to be true at end-of-Phase-1 for you to approve moving to Phase 2?
- [ ] What's the maximum acceptable scope creep within a phase? Default: **none — overflow goes to next phase**

---

## What happens when you're done

1. Save the file.
2. Tell the agent "checklist done."
3. The agent reads every checked AND every unchecked item (silence = accept-default).
4. The agent flags pushbacks (decisions to argue against) and clarifications needed.
5. Confirmed decisions get synced into `spec/spec.md`.
6. Move to Phase 1 plan.
