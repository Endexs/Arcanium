# Skill: Defensive Defaults

## Rule
The implementer applies these patterns reflexively, without being asked. The reviewer flags any code that violates them. The user does not have to remember these — they are the safety net for the decisions a solo dev without deep experience can't make.

## Why this exists
Solo devs without years of production experience don't know all the ways code can fail. These defaults catch the common ones. They're boring, but missing one of them is how products lose user data or get breached.

## The defaults

### 1. Input validation at boundaries
All input from outside the system (CLI args, HTTP requests, file contents, external API responses) is validated at the boundary. Internal function calls can trust their callers.

### 2. Parameterized database queries
Never construct SQL by string concatenation. Use parameterized queries always: `execute("SELECT ... WHERE x = ?", (value,))`. This applies to every database, every ORM, every query type.

### 3. Secrets from environment variables only
API keys, database passwords, signing keys, OAuth tokens — all from environment variables. Never in source files. Never in config files committed to git. Use `.env` for local dev (and add `.env` to `.gitignore`).

### 4. Timeouts on all external calls
Every HTTP request, every external API call, every database connection has an explicit timeout. Default: 30s for HTTP, 5s for DB. Never `httpx.get(url)` without `timeout=`. Never `requests.post(url)` without `timeout=`.

### 5. Retry once on transient errors
Network errors, 5xx responses, rate limits: retry once with a 3s backoff, then fail. Don't build complex retry-with-exponential-backoff unless the user feedback demands it.

### 6. Structured logging with context
Every error log includes enough context to debug from the log alone: the operation, the inputs (sanitized of secrets), the error message, the stack trace. Plain `print("error")` is not a log.

### 7. Transactions around multi-step writes
Any database operation that writes more than one row, or writes to more than one table, is wrapped in a transaction with explicit `BEGIN` and `commit()` / `rollback()`. Half-completed writes are bugs.

### 8. Progress reporting on long operations
Any operation that takes >2 seconds reports progress to the user. Bulk imports, file processing, model API streams — print something so the user knows it's not hung.

### 9. Idempotent operations where possible
Operations that could be retried (especially after a network failure) are idempotent. Use natural keys, `INSERT OR REPLACE`, or check-then-set patterns. "Did this succeed?" should always have a clear answer.

### 10. Fail loud, fail early
When an unexpected state is detected, raise an exception with a clear message. Don't silently continue. Don't return `None` and hope the caller checks. The best error message is one that names exactly what went wrong.

## How to apply

In the implementer system prompt, include:

> Apply all rules from `defensive-defaults.md` reflexively. The user does not need to ask. If a rule conflicts with the plan, flag it as a gap. If a rule cannot be applied (e.g., the framework handles it), note that in the agent journal.

In the reviewer system prompt, include:

> Check every change against `defensive-defaults.md`. Missing defaults are at least Major severity. SQL string concatenation, missing timeouts, plaintext secrets, and missing input validation are Critical.

## What this prevents
- SQL injection
- Credential leaks via committed config files
- Hung processes waiting on dead network calls
- Half-written database state after a crash
- Silent failures that surface as data corruption weeks later
- Logs that say "error" with no way to diagnose
