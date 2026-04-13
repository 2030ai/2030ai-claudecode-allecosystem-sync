# Platform Feature Matrix

Complete comparison of Claude Code CLI, Codex CLI, and Cursor for ecosystem sync purposes.

## Skills

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Skills directory | `~/.claude/skills/` (source of truth) | `~/.codex/skills/` | `~/.cursor/skills-cursor/` |
| Sync mechanism | N/A (source) | Symlinks → CLI | Symlinks → CLI |
| Skill file format | `SKILL.md` (uppercase!) | `SKILL.md` | `SKILL.md` (uppercase required) |
| Native skills | None (all user-installed) | ~13 built-in | ~10 built-in |
| Project skills | `<project>/.claude/skills/` | — | `<project>/.cursor/skills/` |

**Important:** The skill file MUST be named `SKILL.md` (uppercase). Some platforms (notably Cursor) do not detect `skill.md` (lowercase).

## MCP Servers (Global)

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Config file | `~/.claude.json` | `~/.codex/config.toml` | `~/.cursor/mcp.json` |
| Config format | JSON | TOML | JSON |
| stdio transport | Supported | Supported | Supported |
| HTTP transport | Supported | Not supported | Supported |
| Config key | `mcpServers.<name>` | `[mcp_servers.<name>]` | `mcpServers.<name>` |

## MCP Servers (Per-Project)

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Config file | `.mcp.json` | `.codex/config.toml` | `.cursor/mcp.json` |
| Format | JSON | TOML | JSON |

## Project Instructions

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Instructions file | `CLAUDE.md` + `AGENTS.md` | `claude.md` (lowercase, fallback) | `.cursorrules` |
| Global instructions | `~/.claude/CLAUDE.md` | — | — |
| Inheritance | Global → Project → Memory | — | `.cursorrules` only |

**Note:** Project instructions are NOT synced automatically — they have different semantics per platform. Copy manually if needed.

## Platform-Only Features

These features exist in one platform only. They cannot be synced and are listed here for awareness:

| Feature | Claude Code CLI | Codex CLI | Cursor |
|---------|----------------|-----------|--------|
| Hooks (PostToolUse, etc.) | Yes | No | No |
| Auto memory (MEMORY.md) | Yes | No | No |
| Agent teams | Yes | Yes (multi_agent) | No |
| Plan mode | Yes | No | No |
| Worktrees | Yes | No | No |
| Voice input | Yes | No | No |
| Status line | Yes | No | No |
| Output style (explanatory) | Yes | No | No |
| Language preference | Yes | No | No |
| Plugins (marketplace) | Yes (serena, context7, etc.) | Limited (curated) | Limited |

## Codex-Specific: Trusted Projects

Codex CLI requires explicit trust declarations for each project directory:

```toml
[projects."/Users/you/Developer/my-project"]
trust_level = "trusted"
```

Without this, Codex will prompt for trust confirmation every time. The ecosystem-sync skill can audit for missing trust entries but does not auto-add them (requires user confirmation per project).

## What Gets Synced (Summary)

| Component | Synced? | Mechanism | Notes |
|-----------|---------|-----------|-------|
| Custom skills | Yes | Symlinks CLI → Cursor/Codex | Skip native skills |
| Global MCP (stdio) | Yes | Config entry conversion | JSON ↔ TOML |
| Global MCP (HTTP) | Partial | CLI → Cursor only | Codex: not supported |
| Per-project MCP | Yes | Config entry conversion | Same rules as global |
| Project instructions | No | Manual | Different formats per platform |
| Plugins | No | N/A | Platform-specific |
| Hooks | No | N/A | CLI-only feature |
| Memory | No | N/A | CLI-only feature |
| Trusted projects | Audit only | Report gaps | Codex-only, needs manual confirm |
