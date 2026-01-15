#!/usr/bin/env sh
set -e

# Butler AI - Unified Installer
# Installs skills + MCP dependencies (merges, doesn't overwrite)
# Usage: curl -fsSL https://raw.githubusercontent.com/arthtyagi/butler-ai/main/scripts/install.sh | sh

REPO="arthtyagi/butler-ai"

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required for config merging."
  echo "Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Check for npx
if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx is required for skill installation."
  echo "Install Node.js: https://nodejs.org"
  exit 1
fi

echo "=== Butler AI Installer ==="
echo ""

# --- Skills Installation ---
echo "[1/2] Installing skills..."
npx -y add-skill "$REPO"
echo ""

# --- MCP Configuration ---
echo "[2/2] Configuring MCP dependencies..."

# Playwriter config for standard MCP format
PLAYWRITER_STD='{"command":"bunx","args":["-y","playwriter@latest"]}'

# Playwriter config for OpenCode format
PLAYWRITER_OC='{"type":"local","command":["bunx","-y","playwriter@latest"],"enabled":true}'

merge_mcp_standard() {
  local file="$1"
  local dir=$(dirname "$file")
  
  [ "$dir" != "." ] && mkdir -p "$dir"
  
  if [ -f "$file" ]; then
    jq --argjson pw "$PLAYWRITER_STD" '.mcpServers.playwriter = $pw' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    echo "{\"mcpServers\":{\"playwriter\":$PLAYWRITER_STD}}" | jq . > "$file"
  fi
  echo "  ✓ $file"
}

merge_mcp_opencode() {
  local file="$1"
  
  if [ -f "$file" ]; then
    # Remove comments for jq, merge, then output
    sed 's|//.*||g' "$file" | jq --argjson pw "$PLAYWRITER_OC" '.mcp.playwriter = $pw' > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    echo "{\"\$schema\":\"https://opencode.ai/config.json\",\"mcp\":{\"playwriter\":$PLAYWRITER_OC}}" | jq . > "$file"
  fi
  echo "  ✓ $file"
}

# Claude Code / Claude Desktop
merge_mcp_standard ".mcp.json"

# Cursor
merge_mcp_standard ".cursor/mcp.json"

# Codex CLI
merge_mcp_standard ".codex/mcp.json"

# OpenCode
merge_mcp_opencode "opencode.jsonc"

echo ""
echo "=== Done ==="
echo "Restart your editor to load MCP servers."
