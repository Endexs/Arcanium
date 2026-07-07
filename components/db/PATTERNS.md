# Database — Patterns

Each pattern responds to a cited antipattern in `ANTIPATTERNS.md` — read that first.

---

### 1. An idempotent, additive-only column-migration guard
**Responds to:** #1 (deployed DB missing a column `create_all` can't add).

```python
def _ensure_columns():
    """Additive only, never drop/rewrite. A no-op on an up-to-date DB — safe to call on
    every startup."""
    wanted = [
        # (table, column, DDL type + default — SQLite can't add NOT NULL without one)
        ("booking", "stripe_session_id", "VARCHAR(255)"),
        ("payment", "provider", "VARCHAR(20) NOT NULL DEFAULT 'simulated'"),
    ]
    with engine.begin() as conn:
        for table, column, ddl in wanted:
            cols = {row[1] for row in conn.exec_driver_sql(f"PRAGMA table_info({table})")}
            if column not in cols:
                conn.exec_driver_sql(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}")

def init_db():
    Base.metadata.create_all(bind=engine)   # creates missing TABLES
    _ensure_columns()                        # adds missing COLUMNS to existing tables
```
Run both on every process start. `create_all` alone is not a migration story for anything beyond
brand-new tables.

### 2. A dedicated legacy-schema test
**Responds to:** #2 (the ALTER path has no coverage otherwise).

```python
def test_migration_adds_missing_column(tmp_db):
    # Build the DB at the OLD schema (either from a captured old CREATE TABLE, or by
    # dropping the column after create_all)
    tmp_db.execute("ALTER TABLE payment DROP COLUMN provider")  # simulate "pre-6A" schema

    init_db()   # the function under test

    # Assert both that the column exists AND that a request touching it doesn't 500
    assert "provider" in columns(tmp_db, "payment")
    resp = client.post("/some/route/that/reads/provider")
    assert resp.status_code == 200
```
This is the *only* test that exercises the ALTER branch — a suite that always builds fresh via
`create_all` will show 100% line coverage on the migration function while never actually running
its interesting branch.

### 3. Commit before any outbound call, full stop
**Responds to:** #3.
Identical pattern to `payment/PATTERNS.md` #2 — restated here as a data-layer rule, not a
payment-specific one: gather every field an outbound call needs, commit (releasing any eager
write lock), make the call, then re-open a transaction to record the result. Applies equally to
a payment gateway call, a webhook fetch, an external feed sync, or an LLM API call — any network
I/O made from a route or handler that might be holding a write-lock transaction.

### 4. Test fixtures override the session/connection dependency instead of opening their own
**Responds to:** #4.

```python
@pytest.fixture
def client(session):
    def _override_get_session():
        yield session   # the SAME session/connection the test uses for its own assertions
    app.dependency_overrides[get_session] = _override_get_session
    with TestClient(app) as c:
        yield c
```
The test and the app share one connection, so there's nothing for the app's write lock to
contend against. Real concurrent-connection behavior gets its own dedicated probe test (see
`quality/adversarial-review.md`'s "two-at-once" guidance) — this fixture pattern is for every
*other* test that doesn't care about concurrency and shouldn't have to fight the lock to run.

### 5. Verify the distance/similarity formula against the library's actual documented behavior
**Responds to:** #5.
Before trusting a derived similarity score, compute it by hand for two vectors with a known
relationship (identical → similarity 1.0; orthogonal → similarity 0.0) and confirm the library's
raw distance output round-trips through your formula to the expected value. Don't infer the
convention from a plausible-sounding variable name in the library's own source.
