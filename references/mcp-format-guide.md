# MCP Server Format Conversion Guide

Each platform stores MCP server configuration in a different format. This guide shows exact conversion rules.

## Platform Config Locations

| Platform | File | Format |
|----------|------|--------|
| Claude Code CLI/Desktop | `~/.claude.json` → `mcpServers` | JSON |
| Cursor | `~/.cursor/mcp.json` → `mcpServers` | JSON |
| Codex CLI | `~/.codex/config.toml` → `[mcp_servers.*]` | TOML |

## stdio Server Conversion

### CLI → Cursor (JSON → JSON)

Direct copy. The format is identical.

**CLI (`~/.claude.json`):**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-playwright", "--headless"],
      "env": {}
    }
  }
}
```

**Cursor (`~/.cursor/mcp.json`):**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-playwright", "--headless"],
      "env": {}
    }
  }
}
```

### CLI → Codex (JSON → TOML)

Field-by-field conversion:

**CLI JSON:**
```json
"playwright": {
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-playwright", "--headless"],
  "env": {
    "DISPLAY": ":0"
  }
}
```

**Codex TOML:**
```toml
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@anthropic/mcp-playwright", "--headless"]

[mcp_servers.playwright.env]
DISPLAY = ":0"
```

**Rules:**
- `command` → `command = "value"`
- `args` array → `args = ["val1", "val2"]`
- `env` object (if non-empty) → `[mcp_servers.<name>.env]` sub-section with `KEY = "value"` pairs
- `env` object (if empty `{}`) → omit entirely
- `cwd` → `cwd = "value"` (if present)
- Insert new `[mcp_servers.*]` sections before `[notice]` section if it exists, otherwise append to end of file

## HTTP Server Conversion

### CLI → Cursor (JSON → JSON)

Remove the `type` field. Cursor infers HTTP from the presence of `url`.

**CLI:**
```json
"my-server": {
  "type": "http",
  "url": "https://api.example.com/mcp",
  "headers": {
    "Authorization": "Bearer <TOKEN>"
  }
}
```

**Cursor:**
```json
"my-server": {
  "url": "https://api.example.com/mcp",
  "headers": {
    "Authorization": "Bearer <TOKEN>"
  }
}
```

### CLI → Codex

**Not supported.** Codex CLI does not support HTTP MCP servers — it only handles stdio transport.

When encountering an HTTP MCP server during sync, skip it and report:
```
⚠️ Skipped: my-server (HTTP MCP not supported in Codex CLI)
```

### Codex HTTP Format (Future Reference)

If Codex adds HTTP support in the future, the expected TOML format would be:
```toml
[mcp_servers.my-server]
url = "https://api.example.com/mcp"

[mcp_servers.my-server.http_headers]
Authorization = "Bearer <TOKEN>"
```

## Per-Project MCP

Per-project MCP follows the same conversion rules but lives in different files:

| Platform | File |
|----------|------|
| Claude Code | `<project>/.mcp.json` |
| Cursor | `<project>/.cursor/mcp.json` |
| Codex | `<project>/.codex/config.toml` |

The format inside each file is the same as the global config for that platform.

## Server Type Detection

To determine if an MCP server is stdio or HTTP:

- Has `command` field → **stdio**
- Has `url` field → **HTTP**
- Has `type: "http"` → **HTTP** (explicit marker, CLI-only)

## Wrapper Pattern for Noisy Servers

Some stdio MCP servers write non-MCP output (logs, status messages) to `stdout` before the protocol handshake. This breaks strict stdio clients like Codex CLI.

**Solution:** A wrapper script that redirects stray output to `stderr`:

```javascript
#!/usr/bin/env node
// codex-wrapper.mjs — Redirect console output to stderr for strict MCP clients

const origLog = console.log;
const origInfo = console.info;
const origDebug = console.debug;

console.log = (...args) => process.stderr.write(args.join(' ') + '\n');
console.info = (...args) => process.stderr.write(args.join(' ') + '\n');
console.debug = (...args) => process.stderr.write(args.join(' ') + '\n');

// Suppress dotenv verbose output
process.env.DOTENV_CONFIG_QUIET = 'true';

// Import and start the actual server
await import('./path-to-actual-server/dist/index.js');
```

Then in Codex config:
```toml
[mcp_servers.my-server]
command = "node"
args = ["path/to/codex-wrapper.mjs"]
```

This pattern is only needed when a server's startup behavior is incompatible with Codex. Most well-behaved MCP servers work without a wrapper.

## Known Platform-Specific Divergences

Some MCP servers intentionally have different `command`/`args` across platforms. This is expected — sync checks by server key presence, not by comparing launch parameters.

| Server | Claude Code | Codex | Reason |
|--------|-----------|-------|--------|
| `zvasilpublishbot` | Direct: `node .../dist/index.js` | Wrapper: `node .../codex-wrapper.mjs` | Server writes startup logs to stdout; Codex strict stdio client rejects non-MCP output before handshake |

When auditing, treat these as `synced` (key exists in both configs), not as divergence requiring fix.
