# Platform Feature Matrix

Complete comparison of Claude Code CLI, Codex CLI, and Cursor for ecosystem sync purposes.

All paths use `~` as the user's home directory. On Windows this means `%USERPROFILE%`; on macOS/Linux it means `$HOME`. Shell commands in examples are illustrative; agents should use platform-native operations.

## Skills

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Skills directory | `~/.claude/skills/` (global source of truth) | `~/.codex/skills/` | `~/.cursor/skills-cursor/` |
| Sync mechanism | N/A (source) | Symlinks → CLI | Symlinks → CLI |
| Skill file format | `SKILL.md` (uppercase!) | `SKILL.md` | `SKILL.md` (uppercase required) |
| Native skills | None (all user-installed) | ~13 built-in | ~10 built-in |
| Project skills | `<project>/.claude/skills/` (project source of truth) | `<project>/.agents/skills/` | `<project>/.cursor/skills/` |

Project-local skill parity convention:
- Claude project skill: `<project>/.claude/skills/<name>/`
- Cursor project skill: `<project>/.cursor/skills/<name>` → symlink to Claude source
- Codex project skill: `<project>/.agents/skills/<name>` → symlink to Claude source
- Project-local skills stay scoped to their repository and are not promoted into global skill directories

**Important:** The skill file MUST be named `SKILL.md` (uppercase). Codex discovery is case-sensitive and Cursor parity assumes uppercase; lowercase-only `skill.md` is treated as non-canonical.

Codex project-local legacy note:
- `<project>/.codex/skills/` is legacy. Future sync runs must not create project-local skills there.
- Ordinary sync reports legacy entries but does not remove them.
- If both `.agents/skills/<name>` and `.codex/skills/<name>` contain valid manifests, report `DUPLICATE_CODEX_PROJECT_SKILL`.
- If `.codex/skills/<name>` has no matching valid `.claude/skills/<name>/SKILL.md`, report `ORPHAN_LEGACY_CODEX_SKILL`.
- Helper: `python3 scripts/check-codex-project-skill-duplicates.py --projects-root <SCAN_ROOT>` reports duplicate valid Codex project-local skills.

Canonical project-local count:
- Count only `<SCAN_ROOT>/<project>/.claude/skills/<name>/SKILL.md` where `<project>` is a top-level project directory.
- The manifest must have frontmatter with at least `name` and `description`.
- Report nested workspace, lowercase-only, missing-frontmatter, and broken manifests separately.

## MCP Servers (Global)

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Config file | `~/.claude.json` | `~/.codex/config.toml` | `~/.cursor/mcp.json` |
| Config format | JSON | TOML | JSON |
| stdio transport | Supported | Supported | Supported |
| HTTP transport | Supported | Supported (`url` + `http_headers`) | Supported |
| Config key | `mcpServers.<name>` | `[mcp_servers.<name>]` | `mcpServers.<name>` |

## MCP Servers (Per-Project)

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Config file | `.mcp.json` | `.codex/config.toml` | `.cursor/mcp.json` |
| Format | JSON | TOML | JSON |

## Project-Local Skill Conflict Policy

Project-local skill names should not collide with global skill names in `~/.claude/skills/<name>`, because Codex can surface duplicate slash-command entries.

Default behavior:
- If `<project>/.claude/skills/<name>` conflicts with `~/.claude/skills/<name>`, do not mirror it automatically.
- Suggest renaming the local skill (for example `pullrequest-<project>`) or moving project-specific guidance into `AGENTS.md`.

Allowlisted conflicts:
- Any project directory matching `*-template/`; template repositories intentionally ship same-name local skills.
- Additional project-specific exceptions only when the user explicitly provides them in the prompt, project instructions, or a repository-maintained policy file.

Repository visibility policy:
- Private maintainer repositories may commit `.cursor/skills/` and `.agents/skills/` symlinks.
- Public or third-party repositories should usually `.gitignore` `.cursor/skills/` and `.agents/skills/` and keep mirrors local.

## Project Instructions

| Aspect | Claude Code CLI/Desktop | Codex CLI | Cursor |
|--------|------------------------|-----------|--------|
| Instructions file | `CLAUDE.md` + `AGENTS.md` | Controlled by `project_doc_fallback_filenames` in `config.toml` | `.cursorrules` |
| Global instructions | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | — |
| Inheritance | Global → Project → Memory | Global AGENTS.md + project fallback files | `.cursorrules` only |

**Codex project docs:** Codex reads project instructions via the `project_doc_fallback_filenames` array in `~/.codex/config.toml`. It searches for these filenames (case-insensitive on macOS) in the project root. Recommended setting: `project_doc_fallback_filenames = ["claude.md", "agents.md"]` to match Claude Code CLI behavior where both `CLAUDE.md` and `AGENTS.md` are loaded.

**Recommended pattern:** Make `CLAUDE.md` a symlink to `AGENTS.md` in every project. This ensures all platforms that read `claude.md` (Codex via `project_doc_fallback_filenames`, Cursor via `.cursorrules` import) get the full project instructions from the single source of truth. On Windows, use a platform-native symbolic link operation and report permission blockers instead of copying the file.

**Note:** Project instructions are NOT synced automatically — they have different semantics per platform. The symlink pattern above is the recommended approach for cross-platform parity.

## Platform-Only Features

These features exist in one platform only. They cannot be synced and are listed here for awareness:

| Feature | Claude Code CLI | Codex CLI | Cursor |
|---------|----------------|-----------|--------|
| Hooks (PostToolUse, etc.) | Yes | No | No |
| Auto memory (MEMORY.md) | Yes | No equivalent | No equivalent |
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
[projects."/path/to/my-project"]
trust_level = "trusted"
```

Without this, Codex will prompt for trust confirmation every time. The ecosystem-sync skill audits missing and stale trust entries, but does not auto-add or remove them (requires explicit user confirmation).

## What Gets Synced (Summary)

| Component | Synced? | Mechanism | Notes |
|-----------|---------|-----------|-------|
| Custom skills (global) | Yes | Symlinks CLI → Cursor/Codex | Skip native skills |
| Custom skills (project-local) | Yes | Symlinks project Claude → project Cursor/`.agents` | Keep repo scope; `.codex/skills` is legacy |
| Global MCP (stdio) | Yes | Config entry conversion | JSON ↔ TOML |
| Global MCP (HTTP) | Yes | Config entry conversion | Claude/Cursor JSON headers → Codex TOML `http_headers` |
| Per-project MCP | Yes | Config entry conversion | Same rules as global |
| Project instructions | No | Manual | Different formats per platform |
| Plugins | No | N/A | Platform-specific |
| Hooks | No | N/A | CLI-only feature |
| Memory/context | Audit only | Report and suggest promotion to `AGENTS.md` or project docs | Claude auto-memory has no direct Codex/Cursor equivalent |
| Trusted projects | Audit only | Report gaps | Codex-only, needs manual confirm |
