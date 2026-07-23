# Skill: Implementer Handoff

## Rule
Before invoking the implementer model (DeepSeek V4 Pro, GPT-5-Pro, o-series, etc.) on a multi-file generation task, extend the handoff prompt with three blocks: **names in scope**, **library gotchas**, and **output budget**. These cover failure modes the implementer cannot detect or recover from on its own.

## Why this exists
On the Cortex (second-brain RAG) project, the implementer hallucinated function names in **every single implementation phase** (3 phases, 4 hallucinated names total: `init_db(conn)` × 2, `chunk_file`, `walk`). On the same project, a numerical-formula bug (`similarity = 1 - distance` where the library returns squared L2 not cosine) shipped past the implementer because it pattern-matched on the obvious formula without checking the library's distance metric. And the implementer model silently truncated mid-file at `max-tokens 16384` because thinking mode burned the budget on reasoning before writing any code — the same failure mode that hit twice on the prior llm-gateway project.

These three failures share a structure: the implementer is reaching for the right shape from training data when the *specific* facts it needs aren't in the prompt. The fix is to put them there.

## How to apply

### When to use it
- Any multi-file implementation handoff to a sub-agent or external implementer model
- Any handoff where the implementer will call functions/classes that live in files it can't read in this turn
- Any handoff using a thinking-mode model for code generation

### When NOT to use it
- Single-line fixes where the implementer is editing one known location
- Plan-only or review-only handoffs (no code generation)
- Conversational refactoring where you can iterate cheaply

### Block 1: Names in scope

The plan must enumerate every importable name the implementer will need to call, **with current signatures**. Pattern:

```
## Names in scope

From cortex.storage:
  - get_db_path() -> Path
  - connect(db_path: Path) -> sqlite3.Connection
  - init_db(db_path: Path) -> None    # NOTE: takes Path, not Connection

From cortex.chunker:
  - chunk_text(text: str, max_tokens: int, file_extension: str) -> list[Chunk]
  # NOTE: function is chunk_text, NOT chunk_file. There is no chunk_file.

From cortex.walker:
  - walk_sources(roots: list[Path], extensions, ignore_patterns, max_size) -> Iterator[Path]
  # NOTE: function is walk_sources, NOT walk.
```

The `# NOTE:` lines are load-bearing. They pre-empt the names the implementer is most likely to guess from training-data priors. If the implementer has hallucinated `chunk_file` once, add the negative assertion — *"There is no chunk_file"* — to the block. Negative assertions catch the failure mode in a way that positive listings don't.

### Block 2: Library gotchas

A per-library cheat sheet of subtle defaults and conventions that pattern-matching from training data will get wrong. Pattern:

```
## Library gotchas

**sqlite-vec**
- Returns SQUARED L2 distance by default, not L2 and not cosine.
- For unit-length vectors (OpenAI embeddings), cosine similarity = 1 - distance/2.
- Do NOT write `similarity = 1 - distance`.

**respx**
- `respx.mock()` defaults to `assert_all_called=True`.
- Any test that mocks a route it expects to NOT be called must use `respx.mock(assert_all_called=False)`.

**pytest**
- Fixture default scope is `function`, not `session`. State leaks between tests if you assume otherwise.

**Starlette / FastAPI** (airbnb-website Phases 1 + 3)
- `Jinja2Templates.TemplateResponse` in this Starlette version takes **request first**:
  `TemplateResponse(request, name, context)`. The old `TemplateResponse(name, context)`
  raises `TypeError: unhashable type: 'dict'`. Recurred across two phases.
- A missing/empty required `Form(...)` field returns **422** (validation, before the
  handler), not 400. Assert the right code in tests.

**money** (airbnb-website Phase 2)
- Never float. Store integer minor units (cents); convert dollars→cents via `Decimal`
  with `ROUND_HALF_UP`; reject non-finite (`nan`/`inf`) before `quantize`.

**env-driven config** (airbnb-website Phase 3)
- Read `os.environ` at **call time**, not import time, so tests can `monkeypatch.setenv`
  and so fail-closed checks re-evaluate per request.
```

Grow the file organically. Every retrospective adds the libraries it tripped on. Don't try to be exhaustive — be specific to the libraries the implementer will actually touch on this handoff.

### Block 3: Output budget

For thinking-mode models, set `max-tokens` to **65536 minimum** for multi-file generation. Thinking burns ~24K tokens of reasoning before user-visible content; defaults of 4096–16384 are dramatically below floor and the failure mode is silent mid-file truncation, not an error.

Pattern in the plan:

```
## Output budget
- Implementer: DeepSeek V4 Pro
- max-tokens: 65536  (thinking mode burns ~24K before content; 16K floor is insufficient)
- Expected output: ~6 files, ~800 lines total
```

For non-thinking models, 16384 is usually fine. The rule is specifically about thinking modes.

### Block 4: Preserve-verbatim (when editing existing files)

For any handoff that touches files which **already exist**, enumerate the symbols that
must survive unchanged, and constrain the implementer to additive/diff-style edits instead
of whole-file regeneration. A model told to "implement Phase N" defaults to emitting whole
files from scratch and will reinvent names it can't see. Pattern:

```
## Preserve-verbatim (do NOT rename, redefine, or drop)
- `db.py`: import `Base` from here — do NOT define a new `Base` in models.py.
- Table names: "listing","photo","review","booking" — do NOT rename.
- `GET /` route and its context keys (`listing`, `price_display`, …) — keep as-is.
- `seed_demo_listing(session)` — keep this name; nothing imports `seed()`.
- Edit these files additively; return a diff, not a rewritten file.
```

This is the negative-assertion discipline of Block 1 applied to symbols the implementer
must *not redefine* (as opposed to must *call*). **Source:** airbnb-website Phase 2/3 — the
implementer redefined `Base`, renamed tables, and rewrote a prior route, forcing hand
merges of every correctness-critical file.

### Verifying the handoff
Before sending the prompt, the planner (or a pre-handoff check) confirms:
- [ ] Every function the implementer will need has a signature in "Names in scope"
- [ ] At least one negative assertion per likely-hallucinated name
- [ ] Every third-party library appears in "Library gotchas" if it has any non-default behavior in play
- [ ] For any pre-existing file being edited, a "Preserve-verbatim" list names the symbols that must survive
- [ ] `max-tokens` is set to floor for thinking models

If any box is unchecked, fix the prompt before the call.

## What this prevents
- Implementer calls `init_db(conn)` when the signature is `init_db(path)` (3 incidents on Cortex)
- Implementer writes `cosine_sim = 1 - distance` when library returns squared L2 (Cortex Phase 3, caught by adversarial review)
- Implementer imports `chunk_file` and `walk` — names that don't exist (Cortex Phase 4)
- Implementer output truncates silently mid-file when thinking mode exceeds default budget (Cortex Phase 2 + llm-gateway Phase 6/7)
- Test code that hard-codes library defaults (`assert_all_called=True`) that conflict with the test's intent

## Anti-pattern
Treating the handoff prompt as a "description of what to build" rather than a "specification of what the implementer needs to be told it doesn't already know." The implementer model already understands what RAG is, what Python is, and what good code looks like. What it doesn't reliably have: the *specific* names, defaults, and budgets of the current project. Those are the only things the handoff needs to add.

A second anti-pattern: bloating "Library gotchas" with everything you might use. The block earns its keep when it's tight enough to be read. Include only libraries the implementer will touch on *this* handoff. The full library knowledge base lives in the team brain, not in every prompt.

## Related skills
- `[[spec-first]]` — the spec is the source of truth for *what* to build; this skill governs the *prompt* used to delegate the building
- `[[preserve-existing]]` — both skills exist because implementer models systematically lose context the orchestrator has; this one prevents missing context, that one prevents removed context
- `[[adversarial-review]]` — when this skill fails (hallucinated name or bad formula sneaks through), the adversarial reviewer is the next line of defense
- `[[decision-log]]` — when the implementer is uncertain about a name or formula, the decision entry is where the doubt gets flagged (with its confidence and the specific risky lines)
