# Native Skills Registry

These skills are built into each platform and MUST NOT be overwritten, deleted, or symlinked over.
The ecosystem-sync skill skips them automatically during sync operations.

> Last verified: 2026-05-05. These lists change with platform updates — check periodically.
>
> Safety fallback: even if a name is not listed here, never overwrite an existing non-symlink directory/file in a target skill root. Treat it as `native-or-local-skip` and report it.

## Cursor Native Skills

Located in `~/.cursor/skills-cursor/` (or `~/.cursor/skills/`):

- `babysit`
- `canvas`
- `create-hook`
- `create-rule`
- `create-skill`
- `create-subagent`
- `cursor-sdk`
- `migrate-to-skills`
- `shell`
- `split-to-prs`
- `statusline`
- `update-cli-config`
- `update-cursor-settings`

## Codex CLI Native Skills

Located in `~/.codex/skills/`:

- `.system`
- `atlas`
- `codex-primary-runtime`
- `doc`
- `imagegen`
- `pdf`
- `playwright`
- `playwright-interactive`
- `refactor-for-todo`
- `sora`
- `speech`
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
