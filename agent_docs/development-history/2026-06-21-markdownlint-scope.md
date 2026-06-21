# Markdownlint scope for existing repository

- Scoped markdownlint CI to `CLAUDE.md` and `agent_docs/**/*.md`.
- Reason: existing repository content predates this template baseline and is not lint-clean; broad `**/*.md` would fail on unrelated legacy documents.
