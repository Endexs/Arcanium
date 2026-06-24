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
