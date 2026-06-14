#!/usr/bin/env bash
#
# install.sh — Install the solo-dev agent skills package
#
# Usage:
#   ./install.sh                          Install globally to ~/.claude/skills/
#   ./install.sh --global                 Same as default
#   ./install.sh --local <project-dir>    Install into <project-dir>/skills/
#   ./install.sh --templates <project>    Copy templates into project root
#   ./install.sh --all <project>          --local AND --templates into project
#   ./install.sh --dry-run [other flags]  Print actions without doing them
#   ./install.sh --force                  Overwrite existing files without prompt
#   ./install.sh --help                   Show this help
#
# What gets installed:
#   - workflow/, engineering/, quality/, process/   → skill libraries
#   - README.md                                      → top-level reference
#   - templates/                                     → only installed via --templates
#                                                       (project-specific starting points)
#
# Exit codes:
#   0  success
#   1  bad arguments
#   2  destination conflict and --force not set
#   3  source files not found

set -euo pipefail

# ── locate the package source ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$SCRIPT_DIR"

CATEGORIES=(workflow engineering quality process)
TEMPLATE_FILES=(
  "templates/CLAUDE.md.example"
  "templates/spec.md.example"
  "templates/system-prompt-implementer.md"
  "templates/system-prompt-reviewer.md"
  "templates/retrospective.md.example"
  "templates/friction.md.example"
)

# ── colors ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32m'; YELLOW='\033[33m'
  RED='\033[31m'; BLUE='\033[34m'; RESET='\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; BLUE=''; RESET=''
fi

info()    { echo -e "${BLUE}==>${RESET} $*"; }
ok()      { echo -e "${GREEN}✓${RESET}   $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}   $*"; }
err()     { echo -e "${RED}✗${RESET}   $*" >&2; }
dim()     { echo -e "${DIM}$*${RESET}"; }

usage() {
  sed -n 's/^# \?//;1,/^set/p' "$0" | sed '$d'
  exit 0
}

# ── parse args ───────────────────────────────────────────────────────────────
MODE=global
DEST=""
DRY_RUN=0
FORCE=0
INSTALL_TEMPLATES=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)      usage ;;
    --dry-run)      DRY_RUN=1; shift ;;
    --force)        FORCE=1; shift ;;
    --global)       MODE=global; shift ;;
    --local)        MODE=local; DEST="${2:-}"; shift 2 ;;
    --templates)    INSTALL_TEMPLATES=1; DEST="${2:-}"; shift 2; MODE=templates_only ;;
    --all)          MODE=local; INSTALL_TEMPLATES=1; DEST="${2:-}"; shift 2 ;;
    *)              err "Unknown argument: $1"; echo "Run with --help for usage."; exit 1 ;;
  esac
done

# ── validate source ──────────────────────────────────────────────────────────
for cat in "${CATEGORIES[@]}"; do
  if [ ! -d "$PKG_DIR/$cat" ]; then
    err "Source directory not found: $PKG_DIR/$cat"
    err "Make sure you run install.sh from inside skills-package/"
    exit 3
  fi
done

# ── resolve destinations ─────────────────────────────────────────────────────
case "$MODE" in
  global)
    SKILLS_DEST="${HOME}/.claude/skills"
    ;;
  local)
    if [ -z "$DEST" ]; then
      err "--local requires a project directory argument"
      exit 1
    fi
    DEST="${DEST/#\~/$HOME}"
    SKILLS_DEST="${DEST}/skills"
    ;;
  templates_only)
    if [ -z "$DEST" ]; then
      err "--templates requires a project directory argument"
      exit 1
    fi
    DEST="${DEST/#\~/$HOME}"
    SKILLS_DEST=""  # not installing skills, only templates
    ;;
esac

if [ "$INSTALL_TEMPLATES" -eq 1 ] && [ "$MODE" != "templates_only" ]; then
  : # DEST already set by --all
fi

# ── print plan ───────────────────────────────────────────────────────────────
info "${BOLD}Solo Dev Agent Skills Package — installer${RESET}"
echo
dim "Source:       $PKG_DIR"
if [ -n "$SKILLS_DEST" ]; then
  dim "Skills dest:  $SKILLS_DEST"
fi
if [ "$INSTALL_TEMPLATES" -eq 1 ]; then
  dim "Templates:    $DEST/"
fi
dim "Dry run:      $([ "$DRY_RUN" -eq 1 ] && echo yes || echo no)"
dim "Force:        $([ "$FORCE" -eq 1 ] && echo yes || echo no)"
echo

# ── helpers ──────────────────────────────────────────────────────────────────
copy_file() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    warn "exists, skipping: $dst"
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    dim "  would copy: $src → $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    ok "$dst"
  fi
  return 0
}

copy_dir() {
  local src="$1" dst="$2"
  local copied=0 skipped=0
  while IFS= read -r -d '' file; do
    local rel="${file#$src/}"
    if copy_file "$file" "$dst/$rel"; then
      copied=$((copied + 1))
    else
      skipped=$((skipped + 1))
    fi
  done < <(find "$src" -type f -name "*.md" -print0)
  if [ $skipped -gt 0 ] && [ "$FORCE" -ne 1 ]; then
    warn "$skipped file(s) skipped in $src (use --force to overwrite)"
  fi
}

# ── install skills ───────────────────────────────────────────────────────────
if [ -n "$SKILLS_DEST" ]; then
  info "Installing skill libraries to: ${BOLD}$SKILLS_DEST${RESET}"
  for cat in "${CATEGORIES[@]}"; do
    copy_dir "$PKG_DIR/$cat" "$SKILLS_DEST/$cat"
  done
  # Top-level README (renamed so it doesn't clobber a global ~/.claude/skills/README if any)
  if [ "$MODE" = "global" ]; then
    copy_file "$PKG_DIR/README.md" "$SKILLS_DEST/SKILLS_PACKAGE_README.md" || true
  else
    copy_file "$PKG_DIR/README.md" "$SKILLS_DEST/README.md" || true
  fi
  echo
fi

# ── install templates ────────────────────────────────────────────────────────
if [ "$INSTALL_TEMPLATES" -eq 1 ]; then
  info "Installing templates to: ${BOLD}$DEST${RESET}"
  for tpl in "${TEMPLATE_FILES[@]}"; do
    rel_name="$(basename "$tpl" .example)"
    # CLAUDE.md and spec.md go to project root; system prompts go under agents/
    case "$rel_name" in
      CLAUDE.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/CLAUDE.md" || true
        ;;
      spec.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/spec/spec.md" || true
        ;;
      system-prompt-implementer.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/agents/implementer/system_prompt.md" || true
        ;;
      system-prompt-reviewer.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/agents/reviewer/system_prompt.md" || true
        ;;
      retrospective.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/retrospective.md" || true
        ;;
      friction.md)
        copy_file "$PKG_DIR/$tpl" "$DEST/friction.md" || true
        ;;
    esac
  done
  echo
fi

# ── summary and next steps ───────────────────────────────────────────────────
if [ "$DRY_RUN" -eq 1 ]; then
  info "${YELLOW}Dry run complete. No files were written.${RESET}"
  echo "Re-run without --dry-run to install."
  exit 0
fi

info "${GREEN}${BOLD}Installation complete.${RESET}"
echo
echo "Next steps:"
case "$MODE" in
  global)
    echo "  1. In any project, add a CLAUDE.md referencing the skills you want active:"
    echo "       cp $SKILLS_DEST/SKILLS_PACKAGE_README.md /tmp/skills-readme.md"
    echo "       cat ~/.claude/skills/SKILLS_PACKAGE_README.md   # read the starter recommendation"
    echo
    echo "  2. Start each project with five skills:"
    echo "       engineering/defensive-defaults"
    echo "       engineering/preserve-existing"
    echo "       workflow/spec-first"
    echo "       quality/good-enough-rubric"
    echo "       quality/non-negotiable-paths"
    ;;
  local)
    echo "  1. Reference the skills in your project's CLAUDE.md."
    echo "  2. Skills are at: $SKILLS_DEST/"
    if [ "$INSTALL_TEMPLATES" -eq 1 ]; then
      echo "  3. Fill out the templated CLAUDE.md and spec/spec.md."
    fi
    ;;
  templates_only)
    echo "  1. Edit $DEST/CLAUDE.md with your project specifics."
    echo "  2. Edit $DEST/spec/spec.md with your intent."
    echo "  3. If you don't have skills installed yet, run:"
    echo "       $0 --global"
    ;;
esac
echo
echo "Documentation: see README.md in the package source."
