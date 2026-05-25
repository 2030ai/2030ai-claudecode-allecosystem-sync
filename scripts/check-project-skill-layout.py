#!/usr/bin/env python3
"""Validate project-local skill source and platform mirror layout."""

import argparse
import os
import sys
from pathlib import Path


MIRROR_ROOTS = (".claude", ".codex", ".cursor")


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
    if (projects_root / ".agents" / "skills").exists():
        yield projects_root
    for project in sorted(projects_root.iterdir(), key=lambda p: p.name.lower()):
        if project.is_dir():
            yield project


def canonical_skills(project):
    root = project / ".agents" / "skills"
    if not root.exists():
        return set()
    return {
        entry.name
        for entry in root.iterdir()
        if (entry.is_dir() or entry.is_symlink())
        and has_valid_frontmatter(entry / "SKILL.md")
    }


def resolved(path):
    try:
        return path.resolve(strict=True)
    except OSError:
        return None


def validate_project(project):
    findings = []
    source_root = project / ".agents" / "skills"
    for name in sorted(canonical_skills(project)):
        source = source_root / name
        source_resolved = resolved(source)
        for root_name in MIRROR_ROOTS:
            mirror = project / root_name / "skills" / name
            expected = os.path.relpath(source, mirror.parent)
            if not mirror.exists() and not mirror.is_symlink():
                findings.append(
                    (
                        "MISSING_PROJECT_SKILL_MIRROR",
                        project.name,
                        name,
                        "%s expected -> %s" % (mirror, expected),
                    )
                )
                continue
            if not mirror.is_symlink():
                findings.append(
                    (
                        "NON_SYMLINK_PROJECT_SKILL_MIRROR",
                        project.name,
                        name,
                        str(mirror),
                    )
                )
                continue
            if resolved(mirror) != source_resolved:
                findings.append(
                    (
                        "BROKEN_PROJECT_SKILL_MIRROR",
                        project.name,
                        name,
                        "%s -> %s expected %s"
                        % (mirror, os.readlink(mirror), expected),
                    )
                )
    return findings


def main():
    args = parse_args()
    projects_root = expand(args.projects_root)
    findings = []

    for project in iter_projects(projects_root):
        findings.extend(validate_project(project))

    if findings:
        for code, project_name, skill_name, detail in findings:
            print("%s %s/%s %s" % (code, project_name, skill_name, detail))
        return 1

    print("OK project-local skill layouts are valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
