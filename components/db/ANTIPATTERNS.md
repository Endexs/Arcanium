# Database — Antipatterns (via negativa)

Read this before writing or reviewing schema changes, migrations, transaction/locking code, or
any code that computes a similarity/distance score from a vector library.

---

### 1. `create_all` never ALTERs an existing table
**Evidence: fixed after a real incident.**
ORM "create all tables" calls (e.g. SQLAlchemy's `Base.metadata.create_all`) create *missing*
tables but never modify an *existing* one. A column added to a model after the DB was first
created is invisible to a deployed database until an explicit migration runs — the first
request that touches the new column 500s.
**Source:** airbnb-website `db.py` (comment: "Regression: this gap shipped in 6C and only
surfaced on the deployed DB") — a Stripe-related column was added to the model, worked
perfectly against every freshly-created test DB, and broke only on the one database that had
existed since before the change.

### 2. The migration/ALTER path has no test coverage unless tested against an *old* schema
**Evidence: fixed after a real incident.**
A test suite that always builds its DB fresh via `create_all` never exercises the "add a column
to an existing table" path at all — that code is dead weight in coverage terms even at 100%
line coverage on a fresh-DB run, because the ALTER branch never fires.
**Source:** airbnb-website Phase 6C retrospective — the `_ensure_columns()` ALTER path "was dead
code in the suite until a legacy-schema test (`test_migration.py`) was added."

### 3. A DB write lock held across a blocking network call
**Evidence: fixed after a real incident.** Canonical treatment now lives in
`components/concurrency/ANTIPATTERNS.md` #1 (this lesson recurred beyond payment specifically —
see that domain for the full citation and the two general fix shapes in its `PATTERNS.md`).
Any code path that opens an eager write-lock transaction (`BEGIN IMMEDIATE`, `SELECT ... FOR
UPDATE`) and then makes a slow outbound call before committing serializes every other writer for
the duration of that call, under real latency that a mocked-network test never reproduces.

### 4. A test that opens a second DB connection while the app holds an eager write lock
**Evidence: fixed after a real incident.**
A test fixture that creates its own SQLAlchemy session/connection, separate from the one the app
under test uses, will intermittently deadlock against an app that takes `BEGIN IMMEDIATE`-style
write locks — the test's connection and the app's connection contend for the same lock, and
which one wins is non-deterministic.
**Source:** airbnb-website Phase 1–5 retrospective — "Phase 3 admin tests intermittently
deadlocked... the test fixture held a second connection open while the app took the lock."

### 5. A similarity/distance score derived from a vector library without checking its actual convention
**Evidence: fixed after a real incident, cross-project.**
Vector-search libraries differ in what they return by default — squared L2 distance, plain L2,
cosine distance, cosine similarity — and the correct conversion to a 0–1 similarity score
depends on exactly which one you have. Guessing from the variable name or a plausible-looking
formula is not verification.
**Source:** `second-brain-v2` (Cortex) Phase 3 adversarial review — `sqlite-vec`'s `vec0` virtual
table returns **squared L2 distance** by default; `similarity = 1 - distance` looked reasonable
and was wrong. For unit-length vectors, `similarity = 1 - distance / 2` is the correct formula
(`squared_L2 = 2 - 2·cosine_similarity`).
