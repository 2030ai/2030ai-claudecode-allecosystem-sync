#!/usr/bin/env python3
"""Report project-local Codex skills visible from both legacy and current roots."""

import argparse
import sys
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--projects-root", default="~/Developer")
    return parser.parse_args()


def expand(path):
    return Path(path).expanduser()


def has_valid_frontmatter(manifest):
    try:
        text = manifest.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    if not text.startswith("---"):
        return False
    parts = text.split("---", 2)
    if len(parts) < 3:
        return False
    header = "\n%s" % parts[1]
    return "\nname:" in header and "\ndescription:" in header


def iter_projects(projects_root):
    if not projects_root.exists():
        return
    for project in sorted(projects_root.iterdir(), key=lambda p: p.name.lower()):
        if project.is_dir():
            yield project


def skill_entries(root):
    if not root.exists():
        return set()
    return {
        entry.name
        for entry in root.iterdir()
        if (entry.is_dir() or entry.is_symlink())
        and has_valid_frontmatter(entry / "SKILL.md")
    }


def main():
    args = parse_args()
    projects_root = expand(args.projects_root)
    duplicates = []

    for project in iter_projects(projects_root):
        legacy = skill_entries(project / ".codex" / "skills")
        current = skill_entries(project / ".agents" / "skills")
        for name in sorted(legacy & current):
            duplicates.append((project.name, name, project))

    if duplicates:
        for project_name, name, project in duplicates:
            print(
                "DUPLICATE_CODEX_PROJECT_SKILL "
                "%s/%s codex=%s agents=%s"
                % (
                    project_name,
                    name,
                    project / ".codex" / "skills" / name,
                    project / ".agents" / "skills" / name,
                )
            )
        return 1

    print("OK no project-local Codex skill duplicates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
