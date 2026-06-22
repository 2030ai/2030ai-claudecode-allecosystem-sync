---
name: ecosystem-sync
description: "/ecosystem-sync — Cross-platform migration and sync for Claude Code ecosystem. Audit or sync skills, MCP servers, instructions, hooks, subagents, memory/context, recent sessions, and Codex readiness across Claude Code CLI/Desktop, Codex App/CLI, and Cursor. Use when the user links this repository in Codex App, asks to make Claude Code ecosystem work in Codex, checks cross-platform setup, audits skills/MCP across platforms, or mentions ecosystem-sync."
user-invocable: true
---

# /ecosystem-sync

Synchronize your Claude Code ecosystem across Claude Code CLI/Desktop, Codex App/CLI, and Cursor.

**Source of truth:**
- Global skills: Claude Code CLI (`~/.claude/skills/`) → `~/.cursor/skills-cursor/` and `~/.codex/skills/`
- Project-local skills: `<project>/.agents/skills/<name>/SKILL.md` → `<project>/.claude/skills/<name>`, `<project>/.codex/skills/<name>`, and `<project>/.cursor/skills/<name>` symlink mirrors
- MCP: Claude config remains the source; Cursor and Codex receive additive config entries
- Project instructions/context: audit `AGENTS.md`, `CLAUDE.md`, project docs, and Codex trust settings
- Hooks, command sources, subagents, recent sessions, memory, and platform-only features: audit and report how to preserve usable behavior in Codex; migrate only safe additive pieces after review

**Two modes:**
- **audit** — scan and report gaps (read-only, safe to run anytime)
- **sync** — create missing symlinks and config entries (additive only)

**Default:** If the user doesn't specify a mode, run `audit`.

**Design intent:** This is an agent-guided public skill, not a deterministic converter. Use the procedures below to decide what is safe in the user's environment. Helper scripts are optional guardrails, not the migration engine.

## Migration Surface Coverage

Cover the same broad setup areas users expect from a Claude Code → Codex move:

| Source area | Codex target | Default action |
| --- | --- | --- |
| Skills | `~/.codex/skills/` and project-local `.claude`/`.codex`/`.cursor` mirrors | Sync symlinks, skip native/drift |
| MCP | `~/.codex/config.toml` and project `.codex/config.toml` | Add missing entries after confirmation |
| Instructions | `~/.codex/AGENTS.md`, project `AGENTS.md`, `CLAUDE.md` symlink | Audit and propose minimal patches |
| Hooks | `hooks.json` or inline `[hooks]` in Codex config layers | Audit, migrate only reviewed command hooks |
| Claude slash commands | Codex skills | Convert behavior into skills only; do not create slash-command shims |
| Subagents | `~/.codex/agents/*.toml` or `<project>/.codex/agents/*.toml` | Audit and propose custom-agent TOML |
| Recent sessions | Codex app import flow or manual context summary | Audit only; do not bulk-copy transcripts |
| Memory / `MEMORY.md` | `AGENTS.md`, checked-in docs, or Codex Memories | Promote durable rules with review; never write memory internals |

## Direct Codex App Launch

This repository is intended to work without installation. If the user gives Codex App a prompt with a link to this repository:

1. Fetch or read this repository.
2. Read `README.md`, then this `SKILL.md`, then only the relevant files in `references/`.
3. Treat the user's current workspace as the primary project, and use `SCAN_ROOT` only for broader cross-project discovery.
4. Start with `audit`/dry-run unless the user explicitly asks for immediate sync.
5. Before writing any config file, show a short action list and wait for confirmation.
6. Use judgment for paths and project layout. Ask only when proceeding would be risky.

Natural-language requests such as "make my Claude Code ecosystem work in Codex App" mean:
- Audit global user-level setup.
- Audit the current project.
- Audit project-local skills under `SCAN_ROOT` when useful.
- Audit hooks, command sources, subagents, recent sessions, and memory/context sources.
- Sync only safe additive gaps after confirmation.
- Report unsupported or platform-only items with practical Codex equivalents.

## Safety Rules

These are HARD GATES — never violate them:

- ADDITIVE ONLY: never delete files, symlinks, directories, or config entries
- Never overwrite native/built-in skills (see `references/native-skills-registry.md`)
- Never overwrite existing real directories or files at target paths; report them as `native-or-local-skip` or `DRIFT`
- Never log, display, or write tokens/API keys — always show as `<TOKEN>`
  - Token patterns: strings containing `sk-`, `Bearer `, `AQ.`, bot tokens matching `\d+:AA`, long hex/base64 strings
- Never modify `~/.codex/auth.json`
- Never write directly into `~/.codex/memories/`; Codex owns that storage. Propose `AGENTS.md`, checked-in docs, or enabling Codex Memories instead.
- Never create slash-command shims for Claude commands. If a command should survive, convert its behavior into a skill.
- MCP sync checks primarily by server key presence. Only validate required fields for that server type; platform-specific command/args divergences (e.g. wrapper scripts in Codex) are expected and valid
- If a config file cannot be parsed, STOP and report the error — do not attempt repair
- Replace absolute home paths with `~/` in all displayed output
- Ask user for permission before writing to any config file (show what will be added)

## Configuration

Project scan root (override if your projects live elsewhere):

```
SCAN_ROOT: ~/Developer/
```

The skill scans this directory for project-local skills and per-project MCP configs. Adjust if your projects are in a different location (e.g. `~/Projects/`, `~/src/`).

## Cross-Platform Execution

This instruction must work on macOS, Linux, and Windows.

Path rules:
- Interpret `~` as the current user's home directory (`$HOME` on macOS/Linux, `%USERPROFILE%` on Windows).
- Typical config paths are `~/.claude`, `~/.codex`, and `~/.cursor` on every OS, but always verify on disk before acting.
- Treat the current workspace as the primary project. Use `SCAN_ROOT` for broader discovery only after confirming or inferring the correct projects root.
- Good candidate scan roots: current workspace parent, `~/Developer`, `~/Projects`, `~/src`, and on Windows also `~/Documents/GitHub`.

Command rules:
- Bash snippets in this file are examples, not a requirement.
- On Windows, prefer Python `pathlib`/`os` or PowerShell equivalents instead of Bash-only `find`, `grep`, `chmod`, and `ln`.
- Use platform-native path separators when writing config values or showing commands.
- Symlinks are preferred. On Windows, creating directory symlinks may require Developer Mode or elevated permissions. If symlink creation is not permitted, stop and report the required user action; do not silently copy skill directories as a substitute.
- All helper scripts in `scripts/` must remain read-only unless explicitly documented otherwise.

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

## Step 2: Global Skills Audit

### 2a. List global CLI skills (source of truth)

```bash
ls -la ~/.claude/skills/
```

Enumerate all entries. Each entry is a skill (directory or symlink to a directory containing `SKILL.md`).

### 2b. Load native skills lists

Read `references/native-skills-registry.md` from this skill's directory. Extract:
- `CURSOR_NATIVE`: list of Cursor native skill names
- `CODEX_NATIVE`: list of Codex native skill names

### 2c. Check each platform

For each global CLI skill name:
- First verify the source contains canonical `SKILL.md`. If it has only a lowercase manifest filename, report `non-canonical` and do not sync it.

**Cursor check:**
- If name is in CURSOR_NATIVE → status = `native-skip`
- Else check: `ls -la ~/.cursor/skills-cursor/<name>` 
  - Exists and is valid symlink to `~/.claude/skills/<name>` → `synced`
  - Exists as a real directory/file → `native-or-local-skip`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

**Codex check:**
- If name is in CODEX_NATIVE → status = `native-skip`
- Else check: `ls -la ~/.codex/skills/<name>`
  - Exists and is valid symlink to `~/.claude/skills/<name>` → `synced`
  - Exists as a real directory/file → `native-or-local-skip`
  - Exists but points elsewhere → `wrong-target`  
  - Doesn't exist → `MISSING`

### 2d. Report

```
## Global Skills Audit

| Skill | CLI | Cursor | Codex |
|-------|-----|--------|-------|
| my-skill | ✅ | ✅ synced | MISSING |
| atlas | ✅ | ✅ synced | native-skip |
...

Summary: N global skills, M gaps (K Cursor + L Codex)
```

---

## Step 3: Project-Local Skills Audit

### 3a. Scan for project-local skills

```bash
# Canonical project-local skills under SCAN_ROOT:
find <SCAN_ROOT> -maxdepth 5 -path "*/.agents/skills/*/SKILL.md" -type f 2>/dev/null
```

> **Why `-maxdepth 5`:** for `~/Developer/<project>/.agents/skills/<name>/SKILL.md`, the manifest is exactly 5 levels below `~/Developer`. This includes top-level project skills and excludes nested workspace copies such as `temp/`, `_experiments/`, and worktrees.

For each match:
- Skill source dir = `<project>/.agents/skills/<name>/`
- Project root = parent of `.agents/`
- Count it as canonical only when `SKILL.md` has YAML frontmatter with at least `name` and `description`
- Keep project-local skills scoped to the same project; never promote them into `~/.codex/skills/` or `~/.cursor/skills-cursor/`

Also scan for excluded cases and report them separately:

```
Project-local skills: <N> canonical
  + <M> nested workspace (excluded)
  + <K> non-canonical / broken (excluded)
  = <N+M+K> total manifests scanned
```

Excluded cases:
- `nested workspace`: manifests inside nested project workspaces
- `non-canonical`: lowercase-only manifest filename, missing `SKILL.md`, or no frontmatter
- `broken`: `SKILL.md` exists but frontmatter lacks `name` or `description`

### 3b. Check each platform

For each project-local CLI skill name in project `<project>`:
- If `<name>` also exists in `~/.claude/skills/<name>` and is not allowlisted → status = `global-name-conflict`; do not mirror it automatically.
- Allowlisted conflicts:
  - Any project directory matching `*-template/` (templates intentionally ship same-name local skills)
  - Additional project-specific exceptions only when the user explicitly provides them in the prompt, project instructions, or a repository-maintained policy file

**Cursor check:**
- If name is in CURSOR_NATIVE → status = `native-skip`
- Else check: `ls -la <project>/.cursor/skills/<name>`
  - Exists and is valid symlink to `<project>/.agents/skills/<name>` → `synced`
  - Exists as a real directory/file with substantive differences → `DRIFT`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

**Claude project mirror check:**
- Else check: `ls -la <project>/.claude/skills/<name>`
  - Exists and is valid symlink to `<project>/.agents/skills/<name>` → `synced`
  - Exists as a real directory/file with substantive differences → `DRIFT`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`

**Codex check:**
- If name is in CODEX_NATIVE → status = `native-skip`
- Else check: `ls -la <project>/.codex/skills/<name>`
  - Exists and is valid symlink to `<project>/.agents/skills/<name>` → `synced`
  - Exists as a real directory/file with substantive differences → `DRIFT`
  - Exists but points elsewhere → `wrong-target`
  - Doesn't exist → `MISSING`
- If this skill repository's helper scripts are available, run from this skill directory:
  ```bash
  python3 scripts/check-project-skill-layout.py --projects-root <SCAN_ROOT>
  ```

### 3c. Report

```
## Project-Local Skills Audit

| Project | Skill | Claude | Cursor | Codex |
|---------|-------|--------|--------|-------|
| notes-transcriber | pipelineall | ✅ | MISSING | ✅ synced |
...

Summary: N project-local skills, M gaps
```

---

## Step 4: MCP Audit (Global)

### 4a. Read configs

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

### 4b. Classify each CLI MCP server

For each server in CLI's `mcpServers`:
- Has `command` field → **stdio**
- Has `url` field or `type: "http"` → **HTTP**

### 4c. Check each platform

For each CLI MCP server:

**Cursor check:**
- Server name exists in Cursor's `mcpServers` → `synced`
- Doesn't exist → `MISSING`

**Codex check:**
- stdio server exists in Codex's `[mcp_servers.*]` with required `command` and `args` → `synced`
- HTTP server exists in Codex's `[mcp_servers.*]` with required `url` and, when CLI has `headers`, `http_headers` → `synced`
- Server exists but required fields are missing → `INCOMPLETE`
- Server doesn't exist → `MISSING`

### 4d. Report

```
## MCP Servers Audit (Global)

| Server | Type | CLI | Cursor | Codex |
|--------|------|-----|--------|-------|
| playwright | stdio | ✅ | ✅ synced | MISSING |
| my-api | HTTP | ✅ | MISSING | INCOMPLETE |
...

Summary: N servers, M gaps
```

---

## Step 5: MCP Audit (Per-Project)

### 5a. Scan projects

```bash
# Scan SCAN_ROOT:
find <SCAN_ROOT> -maxdepth 2 -name ".mcp.json" -type f 2>/dev/null
```

### 5b. For each project with `.mcp.json`

First, read the file and check if `mcpServers` is empty (`{}`). If empty — skip the project entirely (do NOT create platform configs for empty MCP).

If non-empty, check if corresponding platform configs exist:
- `<project>/.cursor/mcp.json`
- `<project>/.codex/config.toml`

### 5c. Report

```
## MCP Servers Audit (Per-Project)

| Project | CLI (.mcp.json) | Cursor | Codex |
|---------|-----------------|--------|-------|
| my-project | ✅ 3 servers | MISSING | MISSING |
...
```

---

## Step 6: CLAUDE.md Symlink Audit

For cross-platform compatibility, `CLAUDE.md` should be a symlink to `AGENTS.md` in every project that has `AGENTS.md`. This ensures Codex (which reads `claude.md` via `project_doc_fallback_filenames`) gets the full project instructions.

### 6a. Scan projects

```bash
for project_dir in <SCAN_ROOT>/*/; do
  [ -f "$project_dir/AGENTS.md" ] || continue
  # Check if CLAUDE.md is a symlink to AGENTS.md
done
```

### 6b. Classify each project

- `CLAUDE.md` is symlink → `AGENTS.md`: **symlinked**
- `CLAUDE.md` is symlink → other target: **WRONG-TARGET**
- `CLAUDE.md` exists but is a regular file: **not-symlinked**
- `CLAUDE.md` doesn't exist: **MISSING**

### 6c. Report

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

## Step 7: Codex Trusted Projects Audit

Codex CLI requires explicit `trust_level = "trusted"` for each project. Audit for stale and missing entries.

### 7a. Extract project paths from config

```bash
grep -E '^\[projects\.' ~/.codex/config.toml 2>/dev/null | sed 's/\[projects\."\(.*\)"\]/\1/'
```

### 7b. Check each path

For each extracted path:
- Directory exists on disk → `ok`
- Directory does NOT exist → `stale`

### 7c. Check for missing projects

```bash
for dir in <SCAN_ROOT>/*/; do
  [ -e "$dir/.git" ] || continue  # -e, not -d: .git can be a file in worktrees
  # Check if path is in Codex trusted projects
done
```

Projects in SCAN_ROOT with `.git` that are NOT in Codex config → `MISSING`.

### 7d. Report

```
## Codex Trusted Projects
| Project | Status |
|---------|--------|
| ~/Developer/my-project | ok |
| ~/Developer/old-deleted | ⚠️ stale |
| ~/Developer/new-project | MISSING |
...

Summary: N total, M stale, K missing
```

**IMPORTANT:** Do NOT auto-remove stale entries or auto-add missing ones. Report only — adding trust requires user confirmation.

---

## Step 7b: Migration Surface Readiness Audit

Audit the Claude-specific surfaces that do not fit the normal skills/MCP/instructions path cleanly. Codex supports some of them natively, but semantics are not 1:1.

Check, when present:
- Global instructions: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`
- Project instructions: `<project>/AGENTS.md`, `<project>/CLAUDE.md`, `.cursorrules`
- Memory/context sources:
  - Global: `~/.claude/MEMORY.md`, `~/.claude/memory/`, `~/.claude/projects/**/MEMORY.md`, stable sections in `~/.claude/CLAUDE.md`
  - Project: `<project>/MEMORY.md`, `<project>/memory/`, `<project>/.claude/MEMORY.md`, `<project>/.claude/memory/`, `agent_docs/`, `docs/`
- Hooks: `~/.claude/settings.json`, `~/.claude/settings.local.json`, `<project>/.claude/settings.json`, and any plugin/skill hook notes
- Claude command sources: `~/.claude/commands/`, `<project>/.claude/commands/`, plugin `commands/`
- Subagents: `~/.claude/agents/`, `<project>/.claude/agents/`
- Recent sessions: recent Claude transcript/session files such as `~/.claude/projects/**/*.jsonl`
- Other Claude-only features: status line, output style, language preference, plan/worktree assumptions

Rules:
- Do not auto-copy memory files into Codex config or `~/.codex/memories/`.
- Codex Memories are the closest local recall analogue for personal preferences, recurring workflows, tech stacks, conventions, and known pitfalls, but they are off by default in some regions and are not a required-rules store. Durable team/project rules belong in `AGENTS.md` or checked-in docs.
- Do not merge memory into `AGENTS.md` or project docs unless the user explicitly asks and reviews the proposed text.
- If critical project behavior exists only in Claude memory or sessions, report it as `memory-promotion-candidate`.
- If Codex already reads equivalent instructions via `AGENTS.md` or `CLAUDE.md`, report `context-covered`.
- For hooks, report `hook-direct`, `hook-partial`, or `hook-unsupported`. Codex can load hooks from `hooks.json` or inline `[hooks]` config; only migrate reviewed command hooks whose event, matcher, and blocking semantics are understood.
- For Claude commands, report `command-to-skill-candidate`. Convert into `SKILL.md` instructions if the behavior should survive; do not preserve slash-command-specific runtime assumptions as executable behavior.
- For subagents, report `subagent-candidate`. If the user confirms, create additive Codex custom-agent TOML under the appropriate `agents/` directory and preserve tool/permission differences as review notes.
- For recent sessions, report `recent-session-context`. Prefer the Codex app import flow for bulk recent-session migration; otherwise summarize only user-selected sessions.

Report:

```
## Migration Surface Readiness
| Scope | Type | Source | Codex status | Action |
|-------|------|--------|--------------|--------|
| global | memory | ~/.claude/MEMORY.md | memory-promotion-candidate | propose ~/.codex/AGENTS.md or docs patch |
| my-project | memory | memory/MEMORY.md | memory-promotion-candidate | propose AGENTS.md patch |
| my-project | hook | .claude/settings.json PreToolUse | hook-partial | review Codex hooks semantics |
| my-project | command | .claude/commands/release.md | command-to-skill-candidate | convert into a skill |
| my-project | subagent | .claude/agents/reviewer.md | subagent-candidate | propose .codex/agents/reviewer.toml |
| my-project | session | recent Claude transcript | recent-session-context | use Codex import or summarize selected context |
...
```

---

## Step 8: Summary

Combine all audit results:

```
## Ecosystem Audit Summary

Platforms: Claude Code CLI ✅, Cursor ✅, Codex ✅

Skills (global): N total, M synced, K gaps
Skills (project-local): N canonical, M synced, K gaps, L excluded/non-canonical
MCP (global): N total, M synced, K gaps, L incomplete
MCP (per-project): N projects, M synced, K gaps
CLAUDE.md symlink: N total, M gaps
Codex trusted projects: N total, M stale, K missing
Migration surfaces: N covered, M candidates, K manual-review, L unsupported

→ Run `/ecosystem-sync sync` to fix N gaps
   (or `/ecosystem-sync sync --dry-run` to preview)
```

If mode is `audit`, STOP HERE.

---

## Step 9: Sync Skills

### 9a. Global skills

For each global skill with status `MISSING`:

**Cursor:**
```bash
mkdir -p ~/.cursor/skills-cursor
ln -s ~/.claude/skills/<name> ~/.cursor/skills-cursor/<name>
```

**Codex:**
```bash
mkdir -p ~/.codex/skills
ln -s ~/.claude/skills/<name> ~/.codex/skills/<name>
```

Verify each symlink after creation:
```bash
ls -la ~/.cursor/skills-cursor/<name>
# Should show: <name> -> /Users/.../.claude/skills/<name>
```

For `wrong-target`, `native-or-local-skip`, or `DRIFT`, report the path and do not replace it in normal sync.

### 9b. Project-local skills

For each project-local skill `<project>/.agents/skills/<name>` with status `MISSING` and no `global-name-conflict`:

**Claude project mirror:**
```bash
mkdir -p <project>/.claude/skills
ln -s ../../.agents/skills/<name> <project>/.claude/skills/<name>
```

**Cursor:**
```bash
mkdir -p <project>/.cursor/skills
ln -s ../../.agents/skills/<name> <project>/.cursor/skills/<name>
```

**Codex:**
```bash
mkdir -p <project>/.codex/skills
ln -s ../../.agents/skills/<name> <project>/.codex/skills/<name>
```

Verification:
```bash
ls -la <project>/.claude/skills/<name> <project>/.codex/skills/<name> <project>/.cursor/skills/<name>
# Each should show: <name> -> ../../.agents/skills/<name>
```

Rules:
- Keep scope symmetric: project-local Claude skills stay project-local in Cursor and Codex
- Project-local source lives only in `<project>/.agents/skills/`
- `<project>/.claude/skills/`, `<project>/.codex/skills/`, and `<project>/.cursor/skills/` are symlink mirrors to `.agents`
- Never export project-local skills into `~/.codex/skills/` or `~/.cursor/skills-cursor/`
- Native skill names still win; skip them rather than shadowing built-ins
- Global skill names also win unless allowlisted; skip conflicts to avoid duplicate slash-command entries
- For `wrong-target` or `DRIFT`, report the target and do not overwrite it in normal sync

---

## Step 10: Sync MCP (Global)

Read conversion rules from `references/mcp-format-guide.md`.

### 10a. CLI → Cursor

For each MISSING CLI MCP in Cursor:

1. Read current `~/.cursor/mcp.json` (create `{"mcpServers":{}}` if doesn't exist)
2. For each missing server:
   - **stdio:** Copy the entry as-is from CLI config
   - **HTTP:** Copy the entry but REMOVE the `type` field
3. Show the user what will be added (with tokens masked as `<TOKEN>`)
4. After user confirms, write the updated JSON (pretty-printed, 2-space indent)

### 10b. CLI → Codex

For each MISSING or INCOMPLETE CLI MCP in Codex:

1. Read current `~/.codex/config.toml`
2. For each missing stdio server, generate TOML section:
   ```
   [mcp_servers.<name>]
   command = "<command>"
   args = [<args as TOML array>]
   ```
   - If `env` is present and non-empty: add `[mcp_servers.<name>.env]` sub-section
   - If `cwd` is present: add `cwd = "<value>"`
3. For each missing HTTP server, generate TOML section:
   ```
   [mcp_servers.<name>]
   url = "<url>"
   http_headers = { "Authorization" = "Bearer <TOKEN>" }
   ```
   - Copy CLI `headers` to Codex `http_headers`
   - Do not copy CLI `type = "http"`
   - Omit `http_headers` if CLI has no `headers`
4. If the Codex section already exists but required fields are missing, add only the missing fields. Do not rewrite existing command/args/url/header values.
5. Show the user what will be added
6. After user confirms, append new sections or fields to the TOML file
   - Insert BEFORE `[notice]` section if it exists, otherwise append to end

---

## Step 11: Sync MCP (Per-Project)

For each project with `.mcp.json` but missing platform configs:

### Cursor
1. Read `<project>/.mcp.json`
2. Generate `<project>/.cursor/mcp.json` using same format conversion as global (Step 10a)
3. If file already exists: only add missing server entries

### Codex
1. Read `<project>/.mcp.json`
2. Generate `<project>/.codex/config.toml` with `[mcp_servers.*]` sections using the same stdio and HTTP conversion rules as global Codex MCP (Step 10b)
3. If file already exists: only add missing server entries or missing required fields

---

## Step 12: Sync CLAUDE.md Symlinks

For each project with `AGENTS.md`:

1. If `CLAUDE.md` doesn't exist:
   ```bash
   ln -s AGENTS.md <project>/CLAUDE.md
   ```
   On Windows, use a platform-native symbolic link API or PowerShell equivalent. If symlink permission is unavailable, report the blocker instead of copying the file.
2. If `CLAUDE.md` is already a symlink to `AGENTS.md`: `synced`
3. If `CLAUDE.md` is a symlink to another target: report `WRONG-TARGET`; do not replace it in normal sync
4. If `CLAUDE.md` is a regular file, even one that only references `@AGENTS.md`: report `manual-migration-needed`; do not delete it in normal sync

Verification:
```bash
ls -la <project>/CLAUDE.md
# Should show: CLAUDE.md -> AGENTS.md
```

---

## Step 12b: Optional Follow-Up Migrations

Run this only when the user confirms specific items from the readiness audit.

- **Memory/context:** Draft concise patches for `AGENTS.md`, `~/.codex/AGENTS.md`, or checked-in docs. Keep local/user preference material separate from team rules. Suggest enabling Codex Memories for recall, but do not edit `~/.codex/memories/`.
- **Hooks:** Add reviewed Codex hooks to `~/.codex/hooks.json`, `<project>/.codex/hooks.json`, or inline config. Prefer one hook representation per layer. Mark migrated hooks `manual-review` when Claude behavior was broader than Codex behavior.
- **Command sources:** Create or update skills, not slash commands. A Claude command becomes a skill with a clear trigger description, preserved caveats, and any helper references/scripts needed for the workflow.
- **Subagents:** Create additive custom-agent TOML only when the user approves the target scope. Do not overwrite existing agent files. Preserve Claude-only tool restrictions, permission modes, hooks, memory, or background behavior as notes in `developer_instructions` when they cannot be mapped safely.
- **Recent sessions:** Do not bulk-copy transcript files. Use the Codex app import flow for recent sessions when available, or summarize selected sessions into docs after the user chooses them.

---

## Step 13: Final Report

After sync completes, run a quick re-audit and display:

```
## Sync Complete

Skills synced: +N Cursor, +N Codex
MCP synced: +N Cursor, +N Codex
Skipped: N (native/global-name conflict/DRIFT)
Mirror warnings: N missing/broken/non-symlink project-local skill mirrors

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

## Error Handling

- **Platform not found:** Skip gracefully, note in summary
- **Config file malformed:** Report file path and error, do NOT attempt repair
- **Symlink target missing:** Report as `broken-symlink`, suggest re-running sync
- **Permission denied:** Report the file and suggest the platform-appropriate permission fix (`chmod` on POSIX, file properties/ACL/elevated shell on Windows)
- **Empty mcpServers:** Not an error — user may not have MCP servers configured yet
