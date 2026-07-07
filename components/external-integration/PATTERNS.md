# External Integration — Patterns

Each pattern responds to a cited antipattern in `ANTIPATTERNS.md` — read that first.

---

### 1. Validate the load-bearing external dependency as Phase 0, before the spec
**Responds to:** #1, #2, #3 together.
This is `workflow/feasibility-first.md`'s full discipline, restated here as the domain-specific
entry point — read that skill in full before any project (or any new integration within an
existing project) whose value depends on a specific third-party behavior:
1. Name the load-bearing external dependency explicitly ("what single external capability, if
   absent, makes this worthless?").
2. Run the cheapest possible probe that could *falsify* it (an email header, a real API call, a
   ToS/access-tier read) — before spec or architecture work, not after.
3. Gate on the result: confirmed possible → proceed, with the verification recorded as the
   source. Confirmed impossible/gated → stop and run an explicit go/no-go with the user before
   any re-scoping — don't auto-replan around the nearest fallback.
4. Any `[CONFIRMED]` tag on an external-system claim carries a verification source, or it's
   `[ASSUMED — unverified]` and treated as Phase 0 work, not settled architecture.

### 2. Re-validate the actual target at every redirect hop
**Responds to:** #4.
```python
# Scheme + host checked at registration is NOT enough — the fetch itself must re-check.
resp = requests.get(url, allow_redirects=False)
while resp.is_redirect:
    target = resp.headers["Location"]
    _assert_public_host(target)   # reject private/loopback/link-local IPs on EVERY hop
    resp = requests.get(target, allow_redirects=False)
```
Treat every hop as a fresh untrusted URL, not just the one the user/admin originally supplied.

### 3. Verify webhook signatures before touching the payload, reject outright on failure
**Responds to:** #5.
```python
payload = await request.body()   # raw bytes — required for signature verification
sig = request.headers.get("stripe-signature", "")
try:
    event = gateway.construct_event(payload, sig)   # raises on bad/absent signature
except Exception:
    return JSONResponse(status_code=400, content={"error": "invalid signature"})
    # never partially trust, log as legitimate, or process past this point
# only now is `event` safe to act on
```
An unverified event is not "probably fine" — it is indistinguishable from an attacker-forged
one, and must be rejected the same way regardless of how plausible its payload looks.
