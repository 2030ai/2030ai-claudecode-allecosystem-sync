# Native Skills Registry

These skills are built into each platform and MUST NOT be overwritten, deleted, or symlinked over.
The ecosystem-sync skill skips them automatically during sync operations.

> Last verified: 2026-04-13. These lists change with platform updates — check periodically.

## Cursor Native Skills

Located in `~/.cursor/skills-cursor/` (or `~/.cursor/skills/`):

- `babysit`
- `create-hook`
- `create-rule`
- `create-skill`
- `create-subagent`
- `migrate-to-skills`
- `shell`
- `statusline`
- `update-cli-config`
- `update-cursor-settings`

## Codex CLI Native Skills

Located in `~/.codex/skills/`:

- `.system`
- `atlas`
- `doc`
- `imagegen`
- `pdf`
- `playwright`
- `playwright-interactive`
- `refactor-for-todo`
- `slides`
- `sora`
- `speech`
- `spreadsheet`
- `transcribe`

## How to Verify

Check current native skills on your machine:

```bash
# Cursor: look for non-symlink directories
ls -la ~/.cursor/skills-cursor/ | grep -v "^l"

# Codex: look for non-symlink directories
ls -la ~/.codex/skills/ | grep -v "^l"
```

Native skills are real directories (not symlinks). Custom/synced skills are symlinks pointing to `~/.claude/skills/`.

## Updating This List

If a platform update adds new native skills:
1. Run the check commands above
2. Identify new non-symlink entries
3. Add them to the appropriate list in this file
4. Submit a PR
