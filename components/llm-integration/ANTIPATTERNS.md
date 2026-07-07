# LLM Integration — Antipatterns (via negativa)

Read this before writing or reviewing code that calls an LLM API, a vector store, or builds a
grounded/citation-based answer system. Sourced across three projects — the recurring theme is
that LLM-adjacent code has failure modes ordinary defensive coding doesn't anticipate: silent
truncation instead of an error, a library's numeric convention that "seems obvious" and is wrong,
and outputs that look confident while being unverifiable.

---

### 1. Silent token truncation in thinking-mode models
**Evidence: fixed after a real incident — recurred across two separate projects, three times.**
Thinking-mode models (DeepSeek V4 Pro, o-series) burn a large amount of token budget (~24K) on
internal reasoning *before* any user-visible content is produced. A `max-tokens` setting that
doesn't account for this silently truncates output mid-file or mid-response — no error, no
warning, just incomplete output.
**Source:** llm-gateway Phase 6 (silent truncation, caught by manual inspection) and Phase 7
("same truncation again," despite the team knowing about Phase 6's incident); Cortex Phase 2
(the identical failure mode, independently rediscovered on a different project with `max-tokens
16384`). Awareness alone did not prevent recurrence — only a stated numeric floor did.

### 2. Guessing a vector library's distance/similarity convention instead of verifying it
**Evidence: fixed after a real incident.**
Vector-search libraries differ in what they return by default — squared L2 distance, plain L2,
cosine distance, cosine similarity — and the correct conversion to a 0–1 similarity score depends
on exactly which one you have. A plausible-looking formula, derived from the variable name rather
than the library's actual documented behavior, is not verification.
**Source:** Cortex Phase 3 adversarial review — `sqlite-vec`'s `vec0` virtual table returns
**squared L2 distance** by default; `similarity = 1 - distance` looked reasonable and was wrong.
For unit-length vectors, `similarity = 1 - distance / 2` is correct.

### 3. Citation/evidence existence conflated with claim support
**Evidence: fixed after a real incident.**
A grounding/citation check that verifies "the model attached at least one real citation" is not
the same as verifying "this specific claim is supported by this specific citation." A generator
can pair a fabricated claim with genuine-but-unrelated evidence and pass an existence-only check.
**Source:** airbnb-website Phase 7 adversarial review — a support chatbot's grounding check
verified that quoted spans were verbatim in the knowledge base, but never tied the quoted span to
the answer text it was attached to. Concretely: answer "there's a rooftop helipad," cite a real,
verbatim "free parking" line — the citation is 100% real, the claim is 100% fabricated, and an
existence-only check says `ok`.

### 4. A streaming/chunked response field assumed present on every chunk
**Evidence: fixed after a real incident (post-ship, caught by manual use, not by tests).**
Metadata fields on a streamed API response (e.g. token-usage counters) are often populated only
on the *final* chunk, `None` or absent on intermediate ones. Code that unconditionally accesses
such a field (`chunk["usage"]["total_tokens"]`) crashes on any intermediate chunk.
**Source:** llm-gateway, found after shipping — `AttributeError: 'NoneType' object has no
attribute 'get'` because `chunk["usage"]` was `None` on a DeepSeek streaming intermediate chunk.
The adversarial-review checklist at the time didn't include this pattern; only a manual demo
surfaced it.

### 5. Assuming a new LLM provider offers equivalent guarantees to the one it replaces
**Evidence: fixed after a real incident.**
Switching providers (e.g. for cost) can silently drop a capability the original architecture
depended on — a citations/grounding feature, a specific streaming event shape, a particular
JSON-mode contract — if the replacement is wired in assuming feature parity rather than checked
against its actual documented capabilities.
**Source:** airbnb-website Phase 7 — switching the chatbot's default provider from Anthropic
(native Citations API) to DeepSeek (no citations feature at all) required re-deriving the entire
grounding mechanism from scratch as a provider-agnostic, application-level check — the original
implementation's guarantee could not simply be "pointed" at the new provider.
