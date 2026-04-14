---
name: ecosystem-sync
description: "Cross-platform sync for Claude Code ecosystem. Audit, sync, or set up skills and MCP servers across Claude Code CLI/Desktop, Codex CLI, and Cursor. Use when the user asks to sync their ecosystem, check cross-platform setup, audit skills/MCP across platforms, set up Cursor or Codex to match Claude Code, or mentions ecosystem-sync."
user-invocable: true
---

# Ecosystem Sync

Synchronize your skills and MCP servers across Claude Code CLI, Codex CLI, and Cursor.

**Source of truth:** Claude Code CLI (`~/.claude/`).
- Global skills: `~/.claude/skills/` → `~/.cursor/skills-cursor/` and `~/.codex/skills/`
- Project-local skills: `<project>/.claude/skills/` → `<project>/.cursor/skills/` and `<project>/.codex/skills/`
- MCP: Claude config remains the source; Cursor and Codex receive additive config entries

**Authority boundary:**
- This `SKILL.md` is the source of truth for sync behavior and safety rules
- `scripts/ecosystem-doctor.sh` is an audit helper only; it must mirror this skill, not define policy

**Three modes:**
- **audit** — scan and report gaps (read-only, safe to run anytime)
- **sync** — create missing symlinks and config entries (additive only)
- **setup** — guided first-time walkthrough with explanations

**Default:** If the user doesn't specify a mode, run `audit`.

## Safety Rules

These are HARD GATES — never violate them:

- ADDITIVE ONLY: never delete files, symlinks, directories, or config entries
- Never overwrite native/built-in skills (see `references/native-skills-registry.md`)
- Never log, display, or write tokens/API keys — always show as `<TOKEN>`
  - Token patterns: strings containing `sk-`, `Bearer `, `AQ.`, bot tokens matching `\d+:AA`, long hex/base64 strings
- Never modify `~/.codex/auth.json`
- If a config file cannot be parsed, STOP and report the error — do not attempt repair
- Replace absolute home paths with `~/` in all displayed output
- Ask user for permission before writing to any config file (show what will be added)

---

## Step 1: Platform Detection

Check which platforms are installed:

```bash
# Claude Code CLI (required)
[ -d ~/.claude/skills ] && echo "claude: YES" || echo "claude: NO"

# Cursor
[ -d ~/.cursor ] && echo "cursor: YES" || echo "cursor: NO"

# Codex CLI
[ -d ~/.codex ] && echo "codex: YES" || echo "codex: NO"
```

- Claude Code CLI is **required** — if `~/.claude/skills/` doesn't exist, stop and explain how to install Claude Code.
- Cursor and Codex are optional — skip their operations if not installed.
- Create target directories if they don't exist: `~/.cursor/skills-cursor/`, `~/.codex/skills/`.

Report detected platforms to the user before proceeding.

---

## Step 2: Skills Audit

### 2a. List global CLI skills (source of truth)

```bash
ls -la ~/.claude/skills/
```

Enumerate all entries. Each entry is a skill (directory or symlink to a directory containing `SKILL.md`).

### 2b. List project-local CLI skills

```bash
find ~/Developer -path "*/.claude/skills/*/SKILL.md" -not -path "*/.claude/worktrees/*" -type f 2>/dev/null
```

> **Note:** The `-not -path "*/.claude/worktrees/*"` filter excludes temporary agent worktree copies (`.claude/worktrees/agent-*/`) which clone the project's `.claude/` directory and are not real projects.

For each match:
- Skill source dir = `<project>/.claude/skills/<name>/`
- Project root = parent of `.claude/`
- Treat every `SKILL.md` as one project-local skill
- Keep project-local skills scoped to the same project; never promote them into `~/.codex/skills/` or `~/.cursor/skills-cursor/`

### 2c. Load native skills lists

Read `references/native-skills-registry.md` from this skill's directory. Extract:
- `CURSOR_NATIVE`: list of Cursor native skill names
- `CODEX_NATIVE`: list of Codex native skill names

### 2d. Check each platform

For each **global** CLI skill name:

**Cursor check:**
- If name is in CURSOR_NATIVE → status = `native-skip`
- Else check: `ls -la ~/.cursor/skills-cursor/<name>` 
  - Exists and is valid symlink to `~/.claude/skills/<name>` → `synced`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

**Codex check:**
- If name is in CODEX_NATIVE → status = `native-skip`
- Else check: `ls -la ~/.codex/skills/<name>`
  - Exists and is valid symlink to `~/.claude/skills/<name>` → `synced`
  - Exists but points elsewhere → `wrong-target`  
  - Doesn't exist → `MISSING`

For each **project-local** CLI skill name in project `<project>`:

**Cursor check:**
- If name is in CURSOR_NATIVE → status = `native-skip`
- Else check: `ls -la <project>/.cursor/skills/<name>`
  - Exists and is valid symlink to `<project>/.claude/skills/<name>` → `synced`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

**Codex check:**
- If name is in CODEX_NATIVE → status = `native-skip`
- Else check: `ls -la <project>/.codex/skills/<name>`
  - Exists and is valid symlink to `<project>/.claude/skills/<name>` → `synced`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

### 2e. Report

Display a table:

```
## Skills Audit

### Global
| Skill | CLI | Cursor | Codex |
|-------|-----|--------|-------|
| my-skill | ✅ | ✅ synced | MISSING |
| atlas | ✅ | ✅ synced | native-skip |
...

Summary: N global skills, M gaps (K Cursor + L Codex)
```

```
### Project-Local
| Project | Skill | Claude | Cursor | Codex |
|---------|-------|--------|--------|-------|
| notes-transcriber | pipelineall | ✅ | MISSING | ✅ synced |
...

Summary: N project-local skills, M gaps
```

---

## Step 3: MCP Audit (Global)

### 3a. Read configs

```bash
# CLI — JSON
cat ~/.claude.json
# → parse mcpServers section

# Cursor — JSON (may not exist yet)
cat ~/.cursor/mcp.json 2>/dev/null || echo "{}"

# Codex — TOML
cat ~/.codex/config.toml 2>/dev/null || echo ""
# → find all [mcp_servers.*] section names
```

### 3b. Classify each CLI MCP server

For each server in CLI's `mcpServers`:
- Has `command` field → **stdio**
- Has `url` field or `type: "http"` → **HTTP**

### 3c. Check each platform

For each CLI MCP server:

**Cursor check:**
- Server name exists in Cursor's `mcpServers` → `synced`
- Doesn't exist → `MISSING`

**Codex check:**
- HTTP server → `unsupported` (not `MISSING`)
- stdio server exists in Codex's `[mcp_servers.*]` → `synced`
- stdio server doesn't exist → `MISSING`

### 3d. Report

```
## MCP Servers Audit (Global)

| Server | Type | CLI | Cursor | Codex |
|--------|------|-----|--------|-------|
| playwright | stdio | ✅ | ✅ synced | MISSING |
| my-api | HTTP | ✅ | MISSING | unsupported |
...

Summary: N servers, M gaps
```

---

## Step 4: MCP Audit (Per-Project)

### 4a. Scan projects

```bash
find ~/Developer -maxdepth 2 -name ".mcp.json" -type f 2>/dev/null
```

### 4b. For each project with `.mcp.json`

Check if corresponding platform configs exist:
- `<project>/.cursor/mcp.json`
- `<project>/.codex/config.toml`

### 4c. Report

```
## MCP Servers Audit (Per-Project)

| Project | CLI (.mcp.json) | Cursor | Codex |
|---------|-----------------|--------|-------|
| my-project | ✅ 3 servers | MISSING | MISSING |
...
```

---

## Step 4b: CLAUDE.md Symlink Audit

For cross-platform compatibility, `CLAUDE.md` should be a symlink to `AGENTS.md` in every project that has `AGENTS.md`. This ensures Codex (which reads `claude.md` via `project_doc_fallback_filenames`) gets the full project instructions.

### 4b-1. Scan projects

```bash
for project_dir in ~/Developer/*/; do
  [ -f "$project_dir/AGENTS.md" ] || continue
  # Check if CLAUDE.md is a symlink to AGENTS.md
done
```

### 4b-2. Classify each project

- `CLAUDE.md` is symlink → `AGENTS.md`: **symlinked**
- `CLAUDE.md` is symlink → other target: **WRONG-TARGET**
- `CLAUDE.md` exists but is a regular file: **not-symlinked**
- `CLAUDE.md` doesn't exist: **MISSING**

### 4b-3. Report

```
## CLAUDE.md → AGENTS.md Symlink
| Project | Status |
|---------|--------|
| my-project | symlinked |
| old-project | not-symlinked |
...

Summary: N projects, M gaps
```

---

## Step 5: Summary

Combine all audit results:

```
## Ecosystem Audit Summary

Platforms: Claude Code CLI ✅, Cursor ✅, Codex ✅

Skills (global): N total, M synced, K gaps
Skills (project-local): N total, M synced, K gaps
MCP (global): N total, M synced, K gaps, L unsupported (HTTP in Codex)
MCP (per-project): N projects, M synced, K gaps
CLAUDE.md symlink: N total, M gaps

→ Run `/ecosystem-sync sync` to fix N gaps
   (or `/ecosystem-sync sync --dry-run` to preview)
```

If mode is `audit`, STOP HERE.

---

## Step 6: Sync Skills

### 6a. Global skills

For each global skill with status `MISSING` or `wrong-target`:

**Cursor:**
```bash
mkdir -p ~/.cursor/skills-cursor
ln -sf ~/.claude/skills/<name> ~/.cursor/skills-cursor/<name>
```

**Codex:**
```bash
mkdir -p ~/.codex/skills
ln -sf ~/.claude/skills/<name> ~/.codex/skills/<name>
```

Verify each symlink after creation:
```bash
ls -la ~/.cursor/skills-cursor/<name>
# Should show: <name> -> /Users/.../.claude/skills/<name>
```

### 6b. Project-local skills

For each project-local skill `<project>/.claude/skills/<name>` with status `MISSING` or `wrong-target`:

**Cursor:**
```bash
mkdir -p <project>/.cursor/skills
ln -sf <project>/.claude/skills/<name> <project>/.cursor/skills/<name>
```

**Codex:**
```bash
mkdir -p <project>/.codex/skills
ln -sf <project>/.claude/skills/<name> <project>/.codex/skills/<name>
```

Verification:
```bash
ls -la <project>/.codex/skills/<name>
# Should show: <name> -> /Users/.../<project>/.claude/skills/<name>
```

Rules:
- Keep scope symmetric: project-local Claude skills stay project-local in Cursor and Codex
- Never export project-local skills into `~/.codex/skills/` or `~/.cursor/skills-cursor/`
- Native skill names still win; skip them rather than shadowing built-ins

---

## Step 7: Sync MCP (Global)

Read conversion rules from `references/mcp-format-guide.md`.

### 7a. CLI → Cursor

For each MISSING CLI MCP in Cursor:

1. Read current `~/.cursor/mcp.json` (create `{"mcpServers":{}}` if doesn't exist)
2. For each missing server:
   - **stdio:** Copy the entry as-is from CLI config
   - **HTTP:** Copy the entry but REMOVE the `type` field
3. Show the user what will be added (with tokens masked as `<TOKEN>`)
4. After user confirms, write the updated JSON (pretty-printed, 2-space indent)

### 7b. CLI → Codex

For each MISSING stdio CLI MCP in Codex:

1. Read current `~/.codex/config.toml`
2. For each missing stdio server, generate TOML section:
   ```
   [mcp_servers.<name>]
   command = "<command>"
   args = [<args as TOML array>]
   ```
   - If `env` is present and non-empty: add `[mcp_servers.<name>.env]` sub-section
   - If `cwd` is present: add `cwd = "<value>"`
3. For HTTP servers: skip with warning `⚠️ <name>: HTTP MCP not supported in Codex CLI`
4. Show the user what will be added
5. After user confirms, append new sections to the TOML file
   - Insert BEFORE `[notice]` section if it exists, otherwise append to end

---

## Step 8: Sync MCP (Per-Project)

For each project with `.mcp.json` but missing platform configs:

### Cursor
1. Read `<project>/.mcp.json`
2. Generate `<project>/.cursor/mcp.json` using same format conversion as global (Step 7a)
3. If file already exists: only add missing server entries

### Codex
1. Read `<project>/.mcp.json`
2. Generate `<project>/.codex/config.toml` with `[mcp_servers.*]` sections
3. Skip HTTP servers with warning

---

## Step 8b: Sync CLAUDE.md Symlinks

For each project with `AGENTS.md` where `CLAUDE.md` has status `MISSING` or `not-symlinked`:

1. If `CLAUDE.md` is a regular file containing only `@AGENTS.md` reference and comments:
   ```bash
   rm <project>/CLAUDE.md
   ln -s AGENTS.md <project>/CLAUDE.md
   ```
2. If `CLAUDE.md` has unique content beyond `@AGENTS.md`: skip with note — manual migration needed
3. If `CLAUDE.md` doesn't exist:
   ```bash
   ln -s AGENTS.md <project>/CLAUDE.md
   ```

Verification:
```bash
ls -la <project>/CLAUDE.md
# Should show: CLAUDE.md -> AGENTS.md
```

---

## Step 9: Final Report

After sync completes, run a quick re-audit and display:

```
## Sync Complete

Skills synced: +N Cursor, +N Codex
MCP synced: +N Cursor, +N Codex
Skipped: N (HTTP in Codex), N (native skills)

Remaining gaps: N (if any, explain why)
```

---

## Dry Run Mode

If the user says "dry run", "preview", "--dry-run", or "what would change":

- Execute all audit and scan steps normally
- For each action that WOULD write/create:
  - Prefix with `[DRY RUN]`
  - Show the exact command or content that would be written
  - Do NOT execute the command or write the file
- End with summary of planned changes

---

## Setup Mode (Guided Walkthrough)

When user says "setup" or this is clearly a first-time configuration:

1. **Welcome:** Explain the concept in 2-3 sentences — Claude Code CLI is source of truth, other platforms get synced via symlinks (skills) and config entries (MCP)

2. **Platform Detection:** Run Step 1, explain what each platform is:
   - Claude Code CLI/Desktop: the main AI coding assistant
   - Cursor: AI-powered code editor (fork of VS Code)
   - Codex CLI: OpenAI's coding assistant in terminal

3. **Audit:** Run Steps 2-5, but after each section explain WHY:
   - Skills use symlinks so that updating a skill in CLI automatically updates it everywhere
   - MCP configs differ because Codex uses TOML format and doesn't support HTTP transport
   - Native skills are built into each platform and would break if overwritten

4. **Confirm:** Ask user if they want to proceed with sync

5. **Sync:** Run Steps 6-8

6. **Final Report:** Run Step 9

7. **Next Steps:** Suggest:
   - Run `/ecosystem-sync audit` periodically (after installing new skills or MCP servers)
   - Check `references/troubleshooting.md` if something doesn't work
   - Update `references/native-skills-registry.md` after platform updates

---

## Error Handling

- **Platform not found:** Skip gracefully, note in summary
- **Config file malformed:** Report file path and error, do NOT attempt repair
- **Symlink target missing:** Report as `broken-symlink`, suggest re-running sync
- **Permission denied:** Report the file and suggest `chmod 644`
- **Empty mcpServers:** Not an error — user may not have MCP servers configured yet
