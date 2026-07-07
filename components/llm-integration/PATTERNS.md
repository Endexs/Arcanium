# LLM Integration — Patterns

Each pattern responds to a cited antipattern in `ANTIPATTERNS.md` — read that first.

---

### 1. A stated `max-tokens` floor for thinking-mode models, not a guess
**Responds to:** #1.
`max-tokens` **65536 minimum** for any thinking-mode implementer or user-facing call (DeepSeek
V4 Pro, o-series). This is a numeric floor, not a rule of thumb to re-derive per project — see
`engineering/implementer-handoff.md` Block 3, which carries the same floor for implementer
handoffs specifically. For long-running non-streaming calls, prefer streaming +
`get_final_message()` so a large budget doesn't also trip an SDK-side timeout guard.

### 2. Verify the distance/similarity formula against the library's actual documented behavior
**Responds to:** #2.
Before trusting a derived similarity score, compute it by hand for two vectors with a known
relationship (identical → similarity 1.0; orthogonal → similarity 0.0) and confirm the library's
raw distance output round-trips through your formula to the expected value. See
`db/PATTERNS.md` #5 for the same rule applied at the data-layer.

### 3. Two independent grounding gates: quote verification AND answer-content verification
**Responds to:** #3.

```python
# Gate 1: the cited quote must appear verbatim in the source — proves SOMETHING real was cited.
verified = _verify_citations(result.citations, documents)

# Gate 2: the answer's own distinctive content must independently trace back to the knowledge
# base — proves the answer is ABOUT what was cited, not just accompanied by something real.
grounded = _answer_grounded_in_kb(result.text, kb_vocabulary(documents))

if not verified or not grounded:
    return refuse_with_fallback()   # neither gate alone is sufficient
```
Gate 1 alone is what most "grounded" implementations stop at, and it is exactly the gap in
antipattern #3. Prefer a provider's native per-claim citation feature (e.g. Claude's Citations
API, which ties a citation to the specific block it supports) when available — it closes this
gap more strongly than a bolt-on quote-verification check. When the provider has no such feature,
gate 2 is a heuristic mitigation, not a proof: state that limitation explicitly rather than
letting "added a second check" read as "solved."

### 4. Defensive access on every field of a streamed/chunked response
**Responds to:** #4.

```python
usage = chunk.get("usage") or {}          # never assume populated on every chunk
total = usage.get("total_tokens")          # None on intermediate chunks — handle it
if total is not None:
    running_total += total
```
Treat every field on an intermediate chunk as optional unless the API docs explicitly guarantee
otherwise for that field. Add at least one test that exercises a chunk with the metadata field
absent/`None` — the happy-path "final chunk" test alone won't catch this.

### 5. Gateway behind an ABC + dependency-injected real/fake split, generalized to any provider
**Responds to:** #5.
The same shape documented in `payment/PATTERNS.md` #1 — an abstract interface, one real
implementation per provider, one fake for tests, one factory function selecting by config —
applies directly to LLM providers. Isolate provider-specific capabilities (citations vs. JSON-
mode, streaming event shapes) behind the interface so a provider swap is a new implementation of
the same interface, not a rewrite of the calling code. Proven to generalize: the same project
that established this pattern for a payment gateway (`payment_gateway.py`) reused it verbatim for
an LLM gateway (`chatbot_gateway.py`) with no changes to the underlying shape.
