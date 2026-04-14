# Claude Code Ecosystem Sync

Cross-platform skill and MCP server sync for **Claude Code CLI/Desktop**, **Codex CLI**, and **Cursor**.

Keeps your AI coding ecosystem consistent: Claude Code CLI is the source of truth. Cursor and Codex receive symlinks for both global and project-local skills, plus additive config entries for MCP servers.

Behavior is defined by the `ecosystem-sync` skill itself. The standalone script `scripts/ecosystem-doctor.sh` is audit-only and exists to inspect/report the current state, not to define sync policy.

## Quick Start

### Install

```bash
# Option A: Clone directly into skills directory (recommended)
git clone https://github.com/2030ai/2030ai-claudecode-allecosystem-sync.git \
  ~/.claude/skills/ecosystem-sync

# Option B: Clone elsewhere + symlink
git clone https://github.com/2030ai/2030ai-claudecode-allecosystem-sync.git \
  ~/Developer/ecosystem-sync
ln -sf ~/Developer/ecosystem-sync ~/.claude/skills/ecosystem-sync
```

### Use

In Claude Code CLI or Desktop:

```
/ecosystem-sync audit      # Check what's out of sync (read-only)
/ecosystem-sync sync       # Fix gaps (additive only)
/ecosystem-sync setup      # Guided first-time walkthrough
```

### Standalone Audit (no Claude needed)

```bash
~/.claude/skills/ecosystem-sync/scripts/ecosystem-doctor.sh
# or with JSON output:
~/.claude/skills/ecosystem-sync/scripts/ecosystem-doctor.sh --json
```

Use the script as a diagnostic helper. Treat [`SKILL.md`](SKILL.md) as the canonical definition of what sync should do.

## What Gets Synced

### Skills (via symlinks)

Global custom skills from `~/.claude/skills/` get symlinked to Cursor and Codex global skill directories. Project-local skills from `<project>/.claude/skills/` stay project-local and get mirrored into `<project>/.cursor/skills/` and `<project>/.codex/skills/`. Built-in/native skills for each platform are never touched.

```
~/.claude/skills/my-skill/        ← source of truth
~/.cursor/skills-cursor/my-skill  → symlink to above
~/.codex/skills/my-skill          → symlink to above
```

Project-local parity:

```
~/Developer/my-project/.claude/skills/my-skill/   ← source of truth
~/Developer/my-project/.cursor/skills/my-skill    → symlink to above
~/Developer/my-project/.codex/skills/my-skill     → symlink to above
```

### MCP Servers (via config entries)

| Transport | CLI → Cursor | CLI → Codex |
|-----------|-------------|-------------|
| **stdio** | Direct copy (JSON→JSON) | Format conversion (JSON→TOML) |
| **HTTP** | Copy, drop `type` field | Not supported (skipped with warning) |

### What Does NOT Get Synced

- Project instructions (`CLAUDE.md` vs `.cursorrules` vs `claude.md`) — different semantics
- Plugins — platform-specific
- Hooks, auto memory, plan mode — Claude Code CLI only
- Codex trusted projects — audit only (requires manual confirmation)

## Supported Platforms

| Platform | Config | Skills | MCP Format |
|----------|--------|--------|------------|
| Claude Code CLI/Desktop | `~/.claude.json` | `~/.claude/skills/` | JSON |
| Cursor | `~/.cursor/mcp.json` | `~/.cursor/skills-cursor/` and `<project>/.cursor/skills/` | JSON |
| Codex CLI | `~/.codex/config.toml` | `~/.codex/skills/` and `<project>/.codex/skills/` | TOML |

Works with any combination — if you only use 2 of 3 platforms, the missing one is simply skipped.

## Three Modes

### `audit` (default)

Read-only scan. Shows a table of all skills and MCP servers with their sync status across platforms:

- `synced` — present and correctly linked
- `MISSING` — exists in CLI but not in target platform
- `native-skip` — built-in platform skill, intentionally skipped
- `unsupported` — HTTP MCP in Codex (not supported by platform)

Project-local skills are audited separately from global ones so you can spot parity gaps inside a specific repository without polluting the global skill namespace.

### `sync`

Creates missing symlinks and adds missing config entries. **Additive only** — never deletes anything.

Add `--dry-run` or say "preview" to see what would change without making changes.

### `setup`

Guided walkthrough for first-time setup. Explains each concept, shows current state, asks for confirmation before syncing.

## Safety

- **Additive only:** never deletes files, symlinks, or config entries
- **Native skills protected:** built-in skills for each platform are never modified
- **Tokens masked:** API keys and tokens are never displayed (`<TOKEN>`)
- **Permission required:** all config writes ask for user confirmation first
- **Malformed configs:** reported but never auto-repaired

## Reference Docs

- [`references/platform-matrix.md`](references/platform-matrix.md) — Feature comparison across all platforms
- [`references/mcp-format-guide.md`](references/mcp-format-guide.md) — JSON ↔ TOML conversion rules with examples
- [`references/native-skills-registry.md`](references/native-skills-registry.md) — Do-not-touch skill lists per platform
- [`references/troubleshooting.md`](references/troubleshooting.md) — Common issues and fixes

## Updating

```bash
cd ~/.claude/skills/ecosystem-sync && git pull
```

## FAQ

**Q: I only use Claude Code and Cursor, not Codex.**
A: The skill auto-detects installed platforms. Codex operations are simply skipped.

**Q: Can this break my existing setup?**
A: No. It only adds symlinks and config entries. Nothing is ever deleted or overwritten.

**Q: How often should I run this?**
A: After installing new global skills or MCP servers in Claude Code CLI, after adding/editing project-local skills in a repository, or after platform updates.

**Q: Does this work with Claude Code Desktop?**
A: Yes. Claude Code Desktop uses the same config files as CLI — no separate sync needed.

**Q: What about per-project MCP servers and skills?**
A: The skill audits and syncs both project-level `.mcp.json` files and project-local `.claude/skills/*` directories to Cursor and Codex equivalents.

## Contributing

1. Fork the repository
2. Update native skill lists in `references/native-skills-registry.md` if platforms added new built-in skills
3. Submit a PR

## License

MIT
