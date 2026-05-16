# Troubleshooting

Common issues and solutions when syncing the Claude Code ecosystem.

## Skills

### Skill not visible after sync

**Symptom:** Created symlink but the skill doesn't appear in the platform.

**Causes & Fixes:**
1. **Wrong filename:** Skill file must be `SKILL.md` (uppercase), not `skill.md`. Cursor specifically requires uppercase.
2. **Broken symlink:** Run `ls -la ~/.cursor/skills-cursor/<name>` — if the target doesn't exist, the source was moved. Re-run sync.
3. **Restart needed:** Some platforms need a restart to pick up new skills. Close and reopen the app or terminal session.

### Broken symlink after moving skills

**Symptom:** `ls -la` shows symlink pointing to non-existent path.

**Fix:**
```bash
# Remove broken symlink
rm ~/.cursor/skills-cursor/broken-skill
# Re-create pointing to current location (POSIX example)
ln -s ~/.claude/skills/broken-skill ~/.cursor/skills-cursor/broken-skill
```

Or just re-run `/ecosystem-sync sync`.

### Native skill overwritten

**Symptom:** Platform-native skill stopped working after sync.

**Fix:**
```bash
# Remove the incorrect symlink
rm ~/.codex/skills/atlas  # example: atlas is Codex-native
# Codex will restore its native skill on next launch
```

This should not happen with ecosystem-sync (it skips native skills), but if you manually created symlinks, remove them.

### Project-local skills not appearing in Codex or Cursor

**Symptom:** Skills in `<project>/.claude/skills/` exist but Codex/Cursor in that project don't see them.

**Causes & Fixes:**
1. **Symlinks never created:** Run `/ecosystem-sync sync` — it creates `<project>/.agents/skills/<name>` and `<project>/.cursor/skills/<name>` symlinks pointing to the Claude source.
2. **Old Codex root:** `<project>/.codex/skills/` is legacy for project-local skills. New sync runs create only `<project>/.agents/skills/`.
3. **Codex not reading AGENTS.md:** Ensure `~/.codex/config.toml` has `project_doc_fallback_filenames = ["claude.md", "agents.md"]` — without `agents.md`, Codex won't load project instructions that reference skills.
4. **Global-name conflict:** If a project-local skill has the same name as a global skill, ecosystem-sync skips it unless allowlisted to avoid duplicate slash-command entries.
5. **Verify manually:**
   ```bash
   ls -la <project>/.agents/skills/
   # Should show symlinks like: <name> -> ../../.claude/skills/<name>
   ```

### Duplicate Codex project-local skill

**Symptom:** Audit reports `DUPLICATE_CODEX_PROJECT_SKILL`.

**Cause:** The same valid project-local skill is visible from both current `<project>/.agents/skills/<name>` and legacy `<project>/.codex/skills/<name>`.

**Fix:** Verify the `.agents/skills/<name>` symlink resolves to `<project>/.claude/skills/<name>`. Then handle legacy cleanup explicitly outside normal sync. Ordinary `/ecosystem-sync sync` reports legacy entries but does not remove them.

## MCP Servers

### HTTP MCP not working in Codex

Codex supports HTTP MCP servers through TOML `url` and `http_headers` fields. If an HTTP server works in Claude Code but not Codex, check the generated Codex section:

```toml
[mcp_servers.my-server]
url = "https://api.example.com/mcp"
http_headers = { "Authorization" = "Bearer <TOKEN>" }
```

**Fixes:**
1. Ensure `url` exists and matches the Claude `url`.
2. Ensure Claude `headers` were converted to Codex `http_headers`.
3. Ensure CLI-only `type = "http"` was not copied into Codex TOML.

### Codex MCP server fails to start

**Symptom:** Server works in Claude Code CLI but fails in Codex with protocol errors.

**Likely cause:** The server writes non-MCP output (logs, banners) to `stdout` before the protocol handshake. Codex's strict stdio client rejects this.

**Fix:** Create a wrapper script that redirects stray output to `stderr`. See `references/mcp-format-guide.md` → "Wrapper Pattern for Noisy Servers".

### Config file won't parse

**Symptom:** Error reading `~/.cursor/mcp.json` or `~/.codex/config.toml`.

**Fix:**
1. Validate the file manually:
   ```bash
   # JSON validation
   python3 -c "import json; json.load(open('$HOME/.cursor/mcp.json'))"
   
   # TOML validation (if Python has tomllib)
   python3 -c "import tomllib; tomllib.load(open('$HOME/.codex/config.toml', 'rb'))"
   ```
2. Look for: trailing commas in JSON, unescaped special characters in TOML strings, duplicate keys.
3. Fix the syntax error manually — ecosystem-sync will NOT attempt to repair malformed configs.

### MCP server works in one platform but not another

**Check:**
1. **Command path:** Ensure the `command` binary (`npx`, `node`, `python3`) is in PATH for all platforms. Some platforms may use different shell initialization.
2. **Environment variables:** Compare `env` sections between platform configs. A missing env var can cause silent failures.
3. **Working directory:** If the server uses relative paths, the `cwd` field might be needed.

## Hooks, Commands, Subagents, Memory

### Claude hook was not migrated automatically

**Cause:** Codex supports hooks, but hook event coverage, matcher behavior, blocking semantics, and trusted-hook review differ from Claude Code.

**Fix:** Treat the hook as `hook-partial` until reviewed. Migrate only command hooks that have a clear Codex event/matcher target, and place them in one Codex hook representation per config layer: either `hooks.json` or inline `[hooks]`.

### Claude slash command appears in audit

**Policy:** Do not recreate it as a slash command. Convert behavior into a skill when it is still useful.

**Fix:** Create a `SKILL.md` with a clear trigger description and preserve unsupported command runtime assumptions as caveats, such as argument interpolation, shell expansion, or tool hints.

### Claude subagent does not map cleanly

**Cause:** Codex supports custom agents, but Claude tool permissions, hooks, memory, background behavior, and routing assumptions may not map exactly.

**Fix:** Create a Codex custom agent only after review. Keep unsupported Claude-only semantics as notes in `developer_instructions` instead of pretending they are enforced.

### MEMORY.md exists but Codex does not use it

Codex Memories are not a direct file replacement for Claude `MEMORY.md`. They are a local recall layer when enabled and available.

**Fix:**
1. Move durable project/team rules into `AGENTS.md` or checked-in docs after review.
2. Put personal recurring preferences in `~/.codex/AGENTS.md` only if they must always apply.
3. Suggest enabling Codex Memories for helpful recall, but do not write directly into `~/.codex/memories/`.
4. Ignore or archive stale/sensitive memory entries instead of promoting them.

### Recent Claude sessions need to carry over

Prefer the Codex app import flow for recent sessions. If that is not available or the user wants selective migration, summarize only user-selected sessions into project docs or `AGENTS.md`. Do not bulk-copy transcript files into Codex.

## Configs

### Permission denied writing config

**Symptom:** Cannot write to `~/.cursor/mcp.json` or `~/.codex/config.toml`.

**Fix:**
```bash
# Check ownership
ls -la ~/.cursor/mcp.json
ls -la ~/.codex/config.toml

# Fix if needed
chmod 644 ~/.cursor/mcp.json
chmod 644 ~/.codex/config.toml
```

On Windows, use file properties, ACL tools, or an elevated shell instead of `chmod`.

### Tokens visible in output

**Symptom:** API keys or tokens displayed during audit.

**This is a bug.** The ecosystem-sync skill should always mask tokens with `<TOKEN>`. If you see raw tokens:
1. Clear your terminal output
2. Report the issue
3. Verify no tokens were written to files or logs

## General

### Only 1 platform detected

**Not an error.** The skill works with any combination of platforms. If you only have Claude Code CLI and Cursor (no Codex), all Codex operations are simply skipped.

### Sync runs but nothing changes

**Likely cause:** Everything is already in sync. Run `audit` mode to verify — all items should show `synced` status.

### How to completely undo a sync

All sync operations are additive (symlinks and config entries). To undo:

```bash
# Remove skill symlinks (example for Cursor)
for link in ~/.cursor/skills-cursor/*; do
  [ -L "$link" ] && rm "$link"
done

# Remove project-local mirrors (example for one project)
for link in <project>/.cursor/skills/* <project>/.agents/skills/*; do
  [ -L "$link" ] && rm "$link"
done

# For MCP: manually edit the config file and remove added entries
# ~/.cursor/mcp.json — remove entries from mcpServers
# ~/.codex/config.toml — remove [mcp_servers.*] sections
```
