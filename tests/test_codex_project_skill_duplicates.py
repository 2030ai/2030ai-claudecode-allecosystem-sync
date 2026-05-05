import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "check-codex-project-skill-duplicates.py"


def write_skill(path, frontmatter=True):
    path.mkdir(parents=True)
    if frontmatter:
        body = "---\nname: %s\ndescription: test skill\n---\n" % path.name
    else:
        body = "---\ndescription: missing name\n---\n"
    (path / "SKILL.md").write_text(body, encoding="utf-8")


class CodexProjectSkillDuplicateTest(unittest.TestCase):
    def run_checker(self, projects_root):
        return subprocess.run(
            [sys.executable, str(CHECKER), "--projects-root", str(projects_root)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_reports_duplicate_valid_project_skill(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root / "app" / ".codex" / "skills" / "grade")
            write_skill(root / "app" / ".agents" / "skills" / "grade")

            result = self.run_checker(root)

        self.assertEqual(result.returncode, 1)
        self.assertIn("DUPLICATE_CODEX_PROJECT_SKILL app/grade", result.stdout)

    def test_ignores_invalid_manifests(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root / "app" / ".codex" / "skills" / "grade", frontmatter=False)
            write_skill(root / "app" / ".agents" / "skills" / "grade", frontmatter=False)

            result = self.run_checker(root)

        self.assertEqual(result.returncode, 0)
        self.assertIn("OK no project-local Codex skill duplicates", result.stdout)


if __name__ == "__main__":
    unittest.main()
