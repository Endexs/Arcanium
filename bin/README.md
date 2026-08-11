# bin/

Scripts that ship with Arcanium.

## `arcanium-new`

Bootstrap a new project from the `../starter/` scaffold.

```bash
arcanium-new <project-slug> [--name "Display Name"] [--dir <parent>] [--force]
```

Examples:

```bash
# Default: creates /home/developer/projects/hello-rag/
arcanium-new hello-rag

# Override the display name (default derives from slug)
arcanium-new hello-rag --name "Hello, RAG"

# Different parent directory
arcanium-new hello-rag --dir /home/leon/code

# Replace an existing directory (DESTRUCTIVE)
arcanium-new hello-rag --force
```

The script:
1. Copies `starter/` into the target
2. Substitutes `{{PROJECT_SLUG}}`, `{{PROJECT_SLUG_UNDERSCORE}}`, `{{PROJECT_NAME}}`, `{{TODAY}}` placeholders
3. Renames the `src/{{PROJECT_SLUG_UNDERSCORE}}/` package directory
4. Creates `.venv/` and installs dev deps (pytest)
5. `git init`, rename to `main`, makes an initial commit
6. Prints next steps

## `arcanium-runs`

Groups subagent tasks into **runs** — "these N tasks were one feature" — and
enforces frozen gates.

The `pi-subagents-j0k3r` extension already logs every task to
`~/.local/share/pi/subagents/subagents-history.sqlite` with tokens, cost, model,
effort and error category. What it has no concept of is a unit of *work*. This
adds one, in a sidecar DB, joined to the extension's log read-only at query
time. The extension is never patched or written to.

```bash
arcanium-runs open "add /health endpoint"   # start; claims tasks from here
arcanium-runs freeze tests/test_health.py   # this gate may not change
arcanium-runs close --accepted              # verdict; refuses if a gate moved
arcanium-runs ls                            # rollup: tasks, tokens, cost
arcanium-runs show <run_id>                 # phase-by-phase
arcanium-runs adopt --gap 20                # cluster old history retroactively
arcanium-runs unbound                       # tasks belonging to no run
arcanium-runs breaches                      # recorded violations
```

### Frozen gates

`freeze` records a sha256. `close --accepted` recomputes it first and **refuses
the verdict** if it changed:

```
REFUSING to accept run_0004 — 1 frozen path(s) changed since freeze:
  ! tests/test_gate.py  (sha d9e7eaa5f5ea -> 21213654bac8)
```

This makes `workflow/gate-first-validation`'s central rule mechanical instead of
a request an LLM is asked to honour. It needs no attribution: a gate that
changed is invalid regardless of who changed it. `--force` overrides, and the
breach is recorded either way.

`snapshot <label>` / `changed <label> --allow 'src/'` cover the broader case,
comparing working-tree *change-sets* so that an agent running `git checkout` to
discard someone else's work registers as `reverted` rather than passing unseen.
These are run-scoped, not per-agent: pi runs subagents in-process, so there is
no boundary at which to attribute an individual write.

## `arcanium-visualize`

Renders run data in the observability UI from
[disler/super-simple-software-factory](https://github.com/disler/super-simple-software-factory),
vendored unmodified at `../vendor/visualizer/`.

That UI reads SSSF's `sssf.db` schema, which is not ours. This builds a
throwaway projection into that shape, so the app stays pristine and re-pullable
from upstream. The projection is not a source of truth — delete and rebuild it
freely.

```bash
arcanium-visualize            # rebuild the projection
arcanium-visualize --serve    # rebuild, then boot api :4600 + ui :4601
```

Requires `bun` (`curl -fsSL https://bun.sh/install | bash`; needs `unzip`).

Mapping: runs → `sessions`, tasks → `phases` (kind `agent`), subagent activity →
`events` (`streaming` rows dropped as noise), task results → `envelopes`,
frozen gates → `gate_results`.

## Installing globally

For ergonomic use from anywhere:

```bash
sudo ln -s "$(pwd)/bin/arcanium-new" /usr/local/bin/arcanium-new
```

Now `arcanium-new my-project` works from any directory.

## Slug validation

The script enforces:
- Lowercase letters, digits, hyphens only
- Must start with a letter
- No spaces, underscores, or capitals

`{{PROJECT_SLUG_UNDERSCORE}}` is auto-derived (hyphens → underscores) for Python package names, since hyphens aren't valid in Python identifiers.

## Safety

- **Refuses to overwrite** an existing target directory unless `--force` is passed
- `--force` does an `rm -rf` on the target before copying — irreversible; double-check the slug
- Initial commit uses your global `git config` user.name / user.email
