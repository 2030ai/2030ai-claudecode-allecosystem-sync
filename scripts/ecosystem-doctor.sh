#!/usr/bin/env bash
# ecosystem-doctor.sh — Standalone audit for Claude Code ecosystem sync
# Checks skills and MCP server sync status across Claude Code CLI, Codex CLI, and Cursor.
#
# Usage: ./ecosystem-doctor.sh [--json]
# Exit:  0 = all synced, 1 = gaps found

set -euo pipefail

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

# Colors (disabled for JSON output)
if $JSON_OUTPUT; then
  GREEN="" RED="" YELLOW="" GRAY="" RESET=""
else
  GREEN="\033[0;32m" RED="\033[0;31m" YELLOW="\033[0;33m" GRAY="\033[0;90m" RESET="\033[0m"
fi

GAPS=0

# --- Platform Detection ---
CLAUDE_OK=false; CURSOR_OK=false; CODEX_OK=false

[ -d "$HOME/.claude/skills" ] && CLAUDE_OK=true
[ -d "$HOME/.cursor" ] && CURSOR_OK=true
[ -d "$HOME/.codex" ] && CODEX_OK=true

if ! $CLAUDE_OK; then
  echo "Error: Claude Code CLI not found (~/.claude/skills/ missing)"
  echo "Install Claude Code CLI first: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

if ! $JSON_OUTPUT; then
  echo "=== Ecosystem Doctor ==="
  echo ""
  printf "Platforms: Claude Code CLI ${GREEN}YES${RESET}"
  $CURSOR_OK && printf ", Cursor ${GREEN}YES${RESET}" || printf ", Cursor ${GRAY}NO${RESET}"
  $CODEX_OK && printf ", Codex ${GREEN}YES${RESET}" || printf ", Codex ${GRAY}NO${RESET}"
  echo ""
  echo ""
fi

# --- Native Skills Lists ---
CURSOR_NATIVE="babysit create-hook create-rule create-skill create-subagent migrate-to-skills shell statusline update-cli-config update-cursor-settings"
CODEX_NATIVE=".system atlas doc imagegen pdf playwright playwright-interactive refactor-for-todo slides sora speech spreadsheet transcribe"

is_native() {
  local name="$1" list="$2"
  for n in $list; do
    [[ "$n" == "$name" ]] && return 0
  done
  return 1
}

# --- Skills Audit ---
SKILLS_TOTAL=0
SKILLS_GAPS=0
PROJECT_SKILLS_TOTAL=0
PROJECT_SKILLS_GAPS=0

if ! $JSON_OUTPUT; then
  echo "--- Skills ---"
  printf "%-30s %-10s %-10s\n" "Skill" "Cursor" "Codex"
  printf "%-30s %-10s %-10s\n" "-----" "------" "-----"
fi

for skill_path in "$HOME"/.claude/skills/*/; do
  [ -d "$skill_path" ] || continue
  name=$(basename "$skill_path")
  SKILLS_TOTAL=$((SKILLS_TOTAL + 1))

  cursor_status="-"
  codex_status="-"

  if $CURSOR_OK; then
    if is_native "$name" "$CURSOR_NATIVE"; then
      cursor_status="native"
    elif [ -L "$HOME/.cursor/skills-cursor/$name" ]; then
      target=$(readlink "$HOME/.cursor/skills-cursor/$name" 2>/dev/null || echo "")
      if [[ "$target" == *"/.claude/skills/$name"* ]]; then
        cursor_status="synced"
      else
        cursor_status="WRONG"
        SKILLS_GAPS=$((SKILLS_GAPS + 1))
      fi
    elif [ -d "$HOME/.cursor/skills-cursor/$name" ]; then
      cursor_status="copy"
    else
      cursor_status="MISSING"
      SKILLS_GAPS=$((SKILLS_GAPS + 1))
    fi
  fi

  if $CODEX_OK; then
    if is_native "$name" "$CODEX_NATIVE"; then
      codex_status="native"
    elif [ -L "$HOME/.codex/skills/$name" ]; then
      target=$(readlink "$HOME/.codex/skills/$name" 2>/dev/null || echo "")
      if [[ "$target" == *"/.claude/skills/$name"* ]]; then
        codex_status="synced"
      else
        codex_status="WRONG"
        SKILLS_GAPS=$((SKILLS_GAPS + 1))
      fi
    elif [ -d "$HOME/.codex/skills/$name" ]; then
      codex_status="copy"
    else
      codex_status="MISSING"
      SKILLS_GAPS=$((SKILLS_GAPS + 1))
    fi
  fi

  if ! $JSON_OUTPUT; then
    c_color="$GREEN"; x_color="$GREEN"
    [[ "$cursor_status" == "MISSING" || "$cursor_status" == "WRONG" ]] && c_color="$RED"
    [[ "$codex_status" == "MISSING" || "$codex_status" == "WRONG" ]] && x_color="$RED"
    [[ "$cursor_status" == "native" ]] && c_color="$GRAY"
    [[ "$codex_status" == "native" ]] && x_color="$GRAY"
    [[ "$cursor_status" == "-" ]] && c_color="$GRAY"
    [[ "$codex_status" == "-" ]] && x_color="$GRAY"
    printf "%-30s ${c_color}%-10s${RESET} ${x_color}%-10s${RESET}\n" "$name" "$cursor_status" "$codex_status"
  fi
done

GAPS=$((GAPS + SKILLS_GAPS))

# --- Project-Local Skills Audit ---
if ! $JSON_OUTPUT; then
  echo ""
  echo "--- Skills (Project-Local) ---"
  printf "%-24s %-24s %-10s %-10s\n" "Project" "Skill" "Cursor" "Codex"
  printf "%-24s %-24s %-10s %-10s\n" "-------" "-----" "------" "-----"
fi

while IFS= read -r skill_file; do
  [ -n "$skill_file" ] || continue

  skill_dir=$(dirname "$skill_file")
  name=$(basename "$skill_dir")
  local_skills_root=$(dirname "$skill_dir")
  claude_dot_dir=$(dirname "$local_skills_root")
  project_dir=$(dirname "$claude_dot_dir")
  project_name=$(basename "$project_dir")

  PROJECT_SKILLS_TOTAL=$((PROJECT_SKILLS_TOTAL + 1))

  cursor_status="-"
  codex_status="-"

  if $CURSOR_OK; then
    if is_native "$name" "$CURSOR_NATIVE"; then
      cursor_status="native"
    elif [ -L "$project_dir/.cursor/skills/$name" ]; then
      target=$(readlink "$project_dir/.cursor/skills/$name" 2>/dev/null || echo "")
      if [[ "$target" == *"/.claude/skills/$name" || "$target" == *"/.claude/skills/$name/" ]]; then
        cursor_status="synced"
      else
        cursor_status="WRONG"
        PROJECT_SKILLS_GAPS=$((PROJECT_SKILLS_GAPS + 1))
      fi
    elif [ -d "$project_dir/.cursor/skills/$name" ]; then
      cursor_status="copy"
    else
      cursor_status="MISSING"
      PROJECT_SKILLS_GAPS=$((PROJECT_SKILLS_GAPS + 1))
    fi
  fi

  if $CODEX_OK; then
    if is_native "$name" "$CODEX_NATIVE"; then
      codex_status="native"
    elif [ -L "$project_dir/.codex/skills/$name" ]; then
      target=$(readlink "$project_dir/.codex/skills/$name" 2>/dev/null || echo "")
      if [[ "$target" == *"/.claude/skills/$name" || "$target" == *"/.claude/skills/$name/" ]]; then
        codex_status="synced"
      else
        codex_status="WRONG"
        PROJECT_SKILLS_GAPS=$((PROJECT_SKILLS_GAPS + 1))
      fi
    elif [ -d "$project_dir/.codex/skills/$name" ]; then
      codex_status="copy"
    else
      codex_status="MISSING"
      PROJECT_SKILLS_GAPS=$((PROJECT_SKILLS_GAPS + 1))
    fi
  fi

  if ! $JSON_OUTPUT; then
    c_color="$GREEN"; x_color="$GREEN"
    [[ "$cursor_status" == "MISSING" || "$cursor_status" == "WRONG" ]] && c_color="$RED"
    [[ "$codex_status" == "MISSING" || "$codex_status" == "WRONG" ]] && x_color="$RED"
    [[ "$cursor_status" == "native" ]] && c_color="$GRAY"
    [[ "$codex_status" == "native" ]] && x_color="$GRAY"
    [[ "$cursor_status" == "-" ]] && c_color="$GRAY"
    [[ "$codex_status" == "-" ]] && x_color="$GRAY"
    printf "%-24s %-24s ${c_color}%-10s${RESET} ${x_color}%-10s${RESET}\n" "$project_name" "$name" "$cursor_status" "$codex_status"
  fi
done < <(find "$HOME/Developer" -path "*/.claude/skills/*/SKILL.md" -not -path "*/.claude/worktrees/*" -type f 2>/dev/null | sort || true)

GAPS=$((GAPS + PROJECT_SKILLS_GAPS))

# --- MCP Audit (Global) ---
MCP_TOTAL=0
MCP_GAPS=0

if ! $JSON_OUTPUT; then
  echo ""
  echo "--- MCP Servers (Global) ---"
fi

# Extract MCP server names from CLI config
if [ -f "$HOME/.claude.json" ]; then
  if command -v jq &>/dev/null; then
    CLI_MCP_NAMES=$(jq -r '.mcpServers // {} | keys[]' "$HOME/.claude.json" 2>/dev/null || echo "")

    if [ -n "$CLI_MCP_NAMES" ]; then
      if ! $JSON_OUTPUT; then
        printf "%-25s %-8s %-10s %-10s\n" "Server" "Type" "Cursor" "Codex"
        printf "%-25s %-8s %-10s %-10s\n" "------" "----" "------" "-----"
      fi

      while IFS= read -r srv; do
        [ -z "$srv" ] && continue
        MCP_TOTAL=$((MCP_TOTAL + 1))

        # Detect type
        has_url=$(jq -r ".mcpServers[\"$srv\"] | has(\"url\")" "$HOME/.claude.json" 2>/dev/null || echo "false")
        has_type_http=$(jq -r ".mcpServers[\"$srv\"].type // \"\"" "$HOME/.claude.json" 2>/dev/null || echo "")

        srv_type="stdio"
        [[ "$has_url" == "true" || "$has_type_http" == "http" ]] && srv_type="HTTP"

        cursor_mcp="-"
        codex_mcp="-"

        # Cursor check
        if $CURSOR_OK && [ -f "$HOME/.cursor/mcp.json" ]; then
          has_key=$(jq -r ".mcpServers // {} | has(\"$srv\")" "$HOME/.cursor/mcp.json" 2>/dev/null || echo "false")
          if [[ "$has_key" == "true" ]]; then
            cursor_mcp="synced"
          else
            cursor_mcp="MISSING"
            MCP_GAPS=$((MCP_GAPS + 1))
          fi
        elif $CURSOR_OK; then
          cursor_mcp="MISSING"
          MCP_GAPS=$((MCP_GAPS + 1))
        fi

        # Codex check
        if $CODEX_OK && [ -f "$HOME/.codex/config.toml" ]; then
          if [[ "$srv_type" == "HTTP" ]]; then
            codex_mcp="unsupported"
          elif grep -q "\[mcp_servers\.$srv\]" "$HOME/.codex/config.toml" 2>/dev/null || \
               grep -q "\[mcp_servers\.\"$srv\"\]" "$HOME/.codex/config.toml" 2>/dev/null; then
            codex_mcp="synced"
          else
            codex_mcp="MISSING"
            MCP_GAPS=$((MCP_GAPS + 1))
          fi
        elif $CODEX_OK; then
          if [[ "$srv_type" == "HTTP" ]]; then
            codex_mcp="unsupported"
          else
            codex_mcp="MISSING"
            MCP_GAPS=$((MCP_GAPS + 1))
          fi
        fi

        if ! $JSON_OUTPUT; then
          c_color="$GREEN"; x_color="$GREEN"
          [[ "$cursor_mcp" == "MISSING" ]] && c_color="$RED"
          [[ "$codex_mcp" == "MISSING" ]] && x_color="$RED"
          [[ "$codex_mcp" == "unsupported" ]] && x_color="$YELLOW"
          [[ "$cursor_mcp" == "-" ]] && c_color="$GRAY"
          [[ "$codex_mcp" == "-" ]] && x_color="$GRAY"
          printf "%-25s %-8s ${c_color}%-10s${RESET} ${x_color}%-10s${RESET}\n" "$srv" "$srv_type" "$cursor_mcp" "$codex_mcp"
        fi

      done <<< "$CLI_MCP_NAMES"
    fi
  else
    if ! $JSON_OUTPUT; then
      echo "  (install jq for MCP audit: brew install jq)"
    fi
  fi
fi

GAPS=$((GAPS + MCP_GAPS))

# --- CLAUDE.md Symlink Audit ---
CLAUDE_SYMLINK_TOTAL=0
CLAUDE_SYMLINK_GAPS=0

if ! $JSON_OUTPUT; then
  echo ""
  echo "--- CLAUDE.md → AGENTS.md Symlink ---"
  printf "%-30s %-15s\n" "Project" "Status"
  printf "%-30s %-15s\n" "-------" "------"
fi

for project_dir in "$HOME"/Developer/*/; do
  [ -d "$project_dir" ] || continue
  project_dir="${project_dir%/}"  # strip trailing slash
  agents_md="$project_dir/AGENTS.md"
  claude_md="$project_dir/CLAUDE.md"

  # Only audit projects that have AGENTS.md
  [ -f "$agents_md" ] || continue
  CLAUDE_SYMLINK_TOTAL=$((CLAUDE_SYMLINK_TOTAL + 1))

  project_name=$(basename "$project_dir")
  status="unknown"

  if [ -L "$claude_md" ]; then
    target=$(readlink "$claude_md" 2>/dev/null || echo "")
    if [[ "$target" == "AGENTS.md" || "$target" == "./AGENTS.md" || "$target" == "$project_dir/AGENTS.md" ]]; then
      status="symlinked"
    else
      status="WRONG-TARGET"
      CLAUDE_SYMLINK_GAPS=$((CLAUDE_SYMLINK_GAPS + 1))
    fi
  elif [ -f "$claude_md" ]; then
    status="not-symlinked"
    CLAUDE_SYMLINK_GAPS=$((CLAUDE_SYMLINK_GAPS + 1))
  else
    status="MISSING"
    CLAUDE_SYMLINK_GAPS=$((CLAUDE_SYMLINK_GAPS + 1))
  fi

  if ! $JSON_OUTPUT; then
    s_color="$GREEN"
    [[ "$status" == "not-symlinked" || "$status" == "WRONG-TARGET" ]] && s_color="$YELLOW"
    [[ "$status" == "MISSING" ]] && s_color="$RED"
    printf "%-30s ${s_color}%-15s${RESET}\n" "$project_name" "$status"
  fi
done

GAPS=$((GAPS + CLAUDE_SYMLINK_GAPS))

# --- Summary ---
if ! $JSON_OUTPUT; then
  echo ""
  echo "=== Summary ==="
  echo "Skills (global): $SKILLS_TOTAL total, $SKILLS_GAPS gaps"
  echo "Skills (project-local): $PROJECT_SKILLS_TOTAL total, $PROJECT_SKILLS_GAPS gaps"
  echo "MCP:    $MCP_TOTAL total, $MCP_GAPS gaps"
  echo "CLAUDE.md symlink: $CLAUDE_SYMLINK_TOTAL total, $CLAUDE_SYMLINK_GAPS gaps"
  echo ""
  if [ $GAPS -eq 0 ]; then
    echo -e "${GREEN}All synced!${RESET}"
  else
    echo -e "${RED}$GAPS total gaps found.${RESET}"
    echo "Run /ecosystem-sync sync in Claude Code to fix."
  fi
else
  cat <<ENDJSON
{
  "platforms": {
    "claude": $CLAUDE_OK,
    "cursor": $CURSOR_OK,
    "codex": $CODEX_OK
  },
  "skills": {
    "total": $SKILLS_TOTAL,
    "gaps": $SKILLS_GAPS
  },
  "project_skills": {
    "total": $PROJECT_SKILLS_TOTAL,
    "gaps": $PROJECT_SKILLS_GAPS
  },
  "mcp": {
    "total": $MCP_TOTAL,
    "gaps": $MCP_GAPS
  },
  "claude_symlink": {
    "total": $CLAUDE_SYMLINK_TOTAL,
    "gaps": $CLAUDE_SYMLINK_GAPS
  },
  "total_gaps": $GAPS
}
ENDJSON
fi

[ $GAPS -eq 0 ] && exit 0 || exit 1
