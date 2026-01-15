#!/usr/bin/env sh
set -e

# Butler AI - Unified Installer
# Installs skills + MCP dependencies (merges, doesn't overwrite)
# Usage: curl -fsSL https://raw.githubusercontent.com/arthtyagi/butler-ai/main/scripts/install.sh | sh
#        curl ... | sh -s -- --opencode-fix   # Auto-apply OpenCode workaround

REPO="arthtyagi/butler-ai"
SKILLS="zepto-automation"
OPENCODE_FIX=""

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --opencode-fix) OPENCODE_FIX="yes" ;;
    --no-opencode-fix) OPENCODE_FIX="no" ;;
  esac
done

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
npx -y add-skill "$REPO" -y -a claude-code cursor codex opencode -s $SKILLS </dev/null
echo ""

# --- MCP Configuration ---
echo "[2/2] Configuring MCP dependencies..."

# Playwriter config for standard MCP format
PLAYWRITER_STD='{"command":"bunx","args":["-y","playwriter@latest"]}'

# Playwriter config for OpenCode format
PLAYWRITER_OC='{"type":"local","command":["bunx","-y","playwriter@latest"],"enabled":true}'

merge_mcp_standard() {
  file="$1"
  dir=$(dirname "$file")
  
  [ "$dir" != "." ] && mkdir -p "$dir"
  
  if [ -f "$file" ]; then
    jq --argjson pw "$PLAYWRITER_STD" '.mcpServers.playwriter = $pw' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    echo "{\"mcpServers\":{\"playwriter\":$PLAYWRITER_STD}}" | jq . > "$file"
  fi
  echo "  ✓ $file"
}

merge_mcp_opencode() {
  file="$1"
  
  if [ -f "$file" ]; then
    # Strip JSONC comments safely:
    # 1. Remove comment-only lines (^\s*//)
    # 2. Remove trailing comments only if no " follows (preserves URLs in strings)
    sed '/^[[:space:]]*\/\//d; s/[[:space:]]*\/\/[^"]*$//' "$file" | \
      jq --argjson pw "$PLAYWRITER_OC" '.mcp.playwriter = $pw' > "${file}.tmp" && mv "${file}.tmp" "$file"
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

# --- Optional: OpenCode Workaround ---
# OpenCode has a bug where it only loads skills from ~/.claude/skills/
# not from project-level .opencode/skill/ directories
# See: INVESTIGATION-opencode-skill-loading.md

apply_opencode_fix() {
  echo ""
  echo "[Optional] Applying OpenCode workaround..."
  CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
  mkdir -p "$CLAUDE_SKILLS_DIR"

  for skill in $SKILLS; do
    src="$HOME/.opencode/skill/$skill"
    dst="$CLAUDE_SKILLS_DIR/$skill"
    
    if [ -d "$src" ]; then
      if [ -L "$dst" ]; then
        echo "  ↻ $skill (symlink exists)"
      elif [ -d "$dst" ]; then
        echo "  ⚠ $skill (directory exists, skipping)"
      else
        ln -s "$src" "$dst"
        echo "  ✓ $skill → $dst"
      fi
    else
      alt_src="$HOME/.claude/skills/$skill"
      if [ -d "$alt_src" ]; then
        echo "  ✓ $skill (already in ~/.claude/skills/)"
      else
        echo "  ⚠ $skill (source not found)"
      fi
    fi
  done
}

if [ "$OPENCODE_FIX" = "yes" ]; then
  apply_opencode_fix
elif [ "$OPENCODE_FIX" != "no" ]; then
  # Interactive prompt (only if not piped and terminal available)
  if [ -t 0 ] && [ -t 1 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "OpenCode has a known bug where project-level skills"
    echo "are not loaded. A workaround is to symlink skills to"
    echo "~/.claude/skills/ (where OpenCode does look)."
    echo ""
    echo "This creates symlinks, not copies. To undo later:"
    echo "  rm ~/.claude/skills/zepto-automation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "Apply OpenCode workaround? [y/N] "
    read -r response
    case "$response" in
      [yY]|[yY][eE][sS]) apply_opencode_fix ;;
      *) echo "Skipped. Run './scripts/fix-opencode-skills.sh' later if needed." ;;
    esac
  fi
fi

echo ""
echo "=== Done ==="
echo "Restart your editor to load MCP servers."
