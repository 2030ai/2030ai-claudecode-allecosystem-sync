import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "check-project-skill-layout.py"


def write_skill(path, frontmatter=True):
    path.mkdir(parents=True)
    if frontmatter:
        body = "---\nname: %s\ndescription: test skill\n---\n" % path.name
    else:
        body = "---\ndescription: missing name\n---\n"
    (path / "SKILL.md").write_text(body, encoding="utf-8")


def write_mirror(project, root_name, skill_name):
    mirror_parent = project / root_name / "skills"
    mirror_parent.mkdir(parents=True, exist_ok=True)
    mirror = mirror_parent / skill_name
    mirror.symlink_to(Path("../../.agents/skills") / skill_name)


class ProjectSkillLayoutTest(unittest.TestCase):
    def run_checker(self, projects_root):
        return subprocess.run(
            [sys.executable, str(CHECKER), "--projects-root", str(projects_root)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_accepts_valid_canonical_skill_and_three_mirrors(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            project = root / "app"
            write_skill(project / ".agents" / "skills" / "grade")
            for mirror_root in (".claude", ".codex", ".cursor"):
                write_mirror(project, mirror_root, "grade")

            result = self.run_checker(root)

        self.assertEqual(result.returncode, 0)
        self.assertIn("OK project-local skill layouts are valid", result.stdout)

    def test_reports_missing_mirror_for_valid_canonical_skill(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root / "app" / ".agents" / "skills" / "grade")

            result = self.run_checker(root)

        self.assertEqual(result.returncode, 1)
        self.assertIn("MISSING_PROJECT_SKILL_MIRROR app/grade", result.stdout)

    def test_accepts_project_root_directly(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            write_skill(project / ".agents" / "skills" / "grade")
            for mirror_root in (".claude", ".codex", ".cursor"):
                write_mirror(project, mirror_root, "grade")

            result = self.run_checker(project)

        self.assertEqual(result.returncode, 0)

    def test_ignores_invalid_canonical_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(
                root / "app" / ".agents" / "skills" / "grade",
                frontmatter=False,
            )

            result = self.run_checker(root)

        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
