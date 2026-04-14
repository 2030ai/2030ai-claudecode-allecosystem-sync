# Platform Feature Matrix

Complete comparison of Claude Code CLI, Codex CLI, and Cursor for ecosystem sync purposes.

## Skills

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Skills directory | `~/.claude/skills/` (global source of truth) | `~/.codex/skills/` | `~/.cursor/skills-cursor/` |
| Sync mechanism | N/A (source) | Symlinks → CLI | Symlinks → CLI |
| Skill file format | `SKILL.md` (uppercase!) | `SKILL.md` | `SKILL.md` (uppercase required) |
| Native skills | None (all user-installed) | ~13 built-in | ~10 built-in |
| Project skills | `<project>/.claude/skills/` (project source of truth) | `<project>/.codex/skills/` | `<project>/.cursor/skills/` |

Project-local skill parity convention:
- Claude project skill: `<project>/.claude/skills/<name>/`
- Cursor project skill: `<project>/.cursor/skills/<name>` → symlink to Claude source
- Codex project skill: `<project>/.codex/skills/<name>` → symlink to Claude source
- Project-local skills stay scoped to their repository and are not promoted into global skill directories

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
| Instructions file | `CLAUDE.md` + `AGENTS.md` | Controlled by `project_doc_fallback_filenames` in `config.toml` | `.cursorrules` |
| Global instructions | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | — |
| Inheritance | Global → Project → Memory | Global AGENTS.md + project fallback files | `.cursorrules` only |

**Codex project docs:** Codex reads project instructions via the `project_doc_fallback_filenames` array in `~/.codex/config.toml`. It searches for these filenames (case-insensitive on macOS) in the project root. Recommended setting: `project_doc_fallback_filenames = ["claude.md", "agents.md"]` to match Claude Code CLI behavior where both `CLAUDE.md` and `AGENTS.md` are loaded.

**Recommended pattern:** Make `CLAUDE.md` a symlink to `AGENTS.md` in every project (`ln -s AGENTS.md CLAUDE.md`). This ensures all platforms that read `claude.md` (Codex via `project_doc_fallback_filenames`, Cursor via `.cursorrules` import) get the full project instructions from the single source of truth.

**Note:** Project instructions are NOT synced automatically — they have different semantics per platform. The symlink pattern above is the recommended approach for cross-platform parity.

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
| Plugins (marketplace) | Yes (see table below) | Limited (curated) | Limited |

## Plugins

Plugins are platform-specific and NOT synced. Listed here for awareness:

| Plugin | Claude Code | Codex | Cursor | Notes |
|--------|-----------|-------|--------|-------|
| code-review | Yes | No | No | CC-only plugin |
| frontend-design | Yes | No | No | CC-only plugin |
| serena | Yes | No | No | CC-only plugin |
| context7 | Yes (plugin + MCP) | MCP only | MCP only | Functionality via MCP |
| codex (rescue) | Yes (plugin) | Native | No | CC→Codex bridge |
| google-calendar | No | Yes (curated) | No | Codex-only |
| gmail | No | Yes (curated) | No | Codex-only |
| github | No (gh CLI) | Yes (curated) | No | Codex-only |

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
| Custom skills (global) | Yes | Symlinks CLI → Cursor/Codex | Skip native skills |
| Custom skills (project-local) | Yes | Symlinks project Claude → project Cursor/Codex | Keep repo scope |
| Global MCP (stdio) | Yes | Config entry conversion | JSON ↔ TOML |
| Global MCP (HTTP) | Partial | CLI → Cursor only | Codex: not supported |
| Per-project MCP | Yes | Config entry conversion | Same rules as global |
| Project instructions | No | Manual | Different formats per platform |
| Plugins | No | N/A | Platform-specific |
| Hooks | No | N/A | CLI-only feature |
| Memory | No | N/A | CLI-only feature |
| Trusted projects | Audit only | Report gaps | Codex-only, needs manual confirm |
