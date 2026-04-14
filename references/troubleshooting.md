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
# Re-create pointing to current location
ln -sf ~/.claude/skills/broken-skill ~/.cursor/skills-cursor/broken-skill
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
1. **Symlinks never created:** Run `/ecosystem-sync sync` — it creates `<project>/.codex/skills/<name>` and `<project>/.cursor/skills/<name>` symlinks pointing to the Claude source.
2. **Worktree false positives:** If the doctor audit shows hundreds of MISSING project skills from `agent-*` directories, update to the latest ecosystem-doctor.sh which excludes `.claude/worktrees/` paths.
3. **Codex not reading AGENTS.md:** Ensure `~/.codex/config.toml` has `project_doc_fallback_filenames = ["claude.md", "agents.md"]` — without `agents.md`, Codex won't load project instructions that reference skills.
4. **Verify manually:**
   ```bash
   ls -la <project>/.codex/skills/
   # Should show symlinks pointing to <project>/.claude/skills/<name>
   ```

## MCP Servers

### HTTP MCP not working in Codex

**This is expected.** Codex CLI does not support HTTP transport for MCP servers. Only stdio (command-based) servers work in Codex. The ecosystem-sync skill skips HTTP servers for Codex and shows a warning.

**Workaround:** If you need the HTTP MCP's functionality in Codex, check if the server also offers a stdio transport option (some servers support both).

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

# For MCP: manually edit the config file and remove added entries
# ~/.cursor/mcp.json — remove entries from mcpServers
# ~/.codex/config.toml — remove [mcp_servers.*] sections
```
