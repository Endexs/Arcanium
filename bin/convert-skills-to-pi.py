#!/usr/bin/env python3
"""
convert-skills-to-pi.py — turn this package's flat skill-per-category .md files
into Pi-native skills: <dest>/<category>/<skill-name>/SKILL.md, each with the
YAML frontmatter (name + description) the Agent Skills standard (and Pi) require.

Pi only auto-loads/lists a skill if it has a non-empty `description` in
frontmatter (see: https://agentskills.io/specification). This package's source
files are plain prose (`# Skill: X` / `## Rule` / ...), so they're invisible to
Pi's skill loader until converted. This script does that conversion losslessly —
body content is copied verbatim, only frontmatter is added.

Usage:
  bin/convert-skills-to-pi.py [--dest DIR] [--dry-run]

  --dest DIR   Output root (default: ~/.pi/agent/skills — global, all projects)
               Use .pi/skills inside a project for a project-local install.
  --dry-run    Print what would be written, don't touch disk.
"""
import argparse
import json
import re
from pathlib import Path

PKG_DIR = Path(__file__).resolve().parent.parent
CATEGORIES = ["workflow", "engineering", "quality", "process", "lifecycle"]
MAX_DESCRIPTION = 1024


def extract_description(body: str, slug: str) -> str:
    """Pull a one-paragraph description out of a skill file's '## Rule' section
    (falling back to the first non-heading paragraph), collapsed to one line."""
    section = None
    m = re.search(r"^##\s*Rule\s*\n(.*?)(?=\n##\s|\Z)", body, re.S | re.M)
    if m:
        section = m.group(1)
    else:
        # fall back: first paragraph after the title that isn't a heading
        paras = [p for p in re.split(r"\n\s*\n", body) if p.strip() and not p.strip().startswith("#")]
        section = paras[0] if paras else ""

    text = " ".join(line.strip() for line in section.strip().splitlines() if line.strip())
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > MAX_DESCRIPTION:
        text = text[: MAX_DESCRIPTION - 1].rsplit(" ", 1)[0] + "…"
    if not text:
        text = f"{slug.replace('-', ' ').capitalize()} — see skill body."
    return text


def convert_file(src: Path, category: str, dest_root: Path, dry_run: bool) -> Path:
    slug = src.stem  # filenames are already valid skill names (lowercase-hyphen)
    body = src.read_text(encoding="utf-8")
    description = extract_description(body, slug)

    frontmatter = (
        "---\n"
        f"name: {slug}\n"
        f"description: {json.dumps(description)}\n"
        f"metadata: {json.dumps({'source': f'{category}/{src.name}', 'package': 'solo-dev-agent-skills'})}\n"
        "---\n\n"
    )

    out_dir = dest_root / category / slug
    out_path = out_dir / "SKILL.md"
    content = frontmatter + body

    if dry_run:
        print(f"would write: {out_path}  (description: {description[:80]}{'…' if len(description) > 80 else ''})")
    else:
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding="utf-8")
        print(f"wrote: {out_path}")
    return out_path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dest", default=str(Path.home() / ".pi" / "agent" / "skills"))
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    dest_root = Path(args.dest).expanduser()
    count = 0
    for cat in CATEGORIES:
        cat_dir = PKG_DIR / cat
        if not cat_dir.is_dir():
            continue
        for src in sorted(cat_dir.glob("*.md")):
            convert_file(src, cat, dest_root, args.dry_run)
            count += 1

    verb = "Would convert" if args.dry_run else "Converted"
    print(f"\n{verb} {count} skills into: {dest_root}")
    if not args.dry_run:
        print("Restart pi (or run /reload in an interactive session) to pick them up.")


if __name__ == "__main__":
    main()
