#!/usr/bin/env sh
set -e

# Butler AI - MCP Dependencies Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/arthtyagi/butler-ai/main/scripts/install-mcp.sh | sh

echo "Installing Butler AI MCP dependencies..."

# Claude Code / Claude Desktop (.mcp.json)
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "playwriter": {
      "command": "bunx",
      "args": ["-y", "playwriter@latest"]
    }
  }
}
EOF
echo "  ✓ .mcp.json"

# Cursor (.cursor/mcp.json)
mkdir -p .cursor
cat > .cursor/mcp.json << 'EOF'
{
  "mcpServers": {
    "playwriter": {
      "command": "bunx",
      "args": ["-y", "playwriter@latest"]
    }
  }
}
EOF
echo "  ✓ .cursor/mcp.json"

# Codex CLI (.codex/mcp.json)
mkdir -p .codex
cat > .codex/mcp.json << 'EOF'
{
  "mcpServers": {
    "playwriter": {
      "command": "bunx",
      "args": ["-y", "playwriter@latest"]
    }
  }
}
EOF
echo "  ✓ .codex/mcp.json"

# OpenCode (opencode.jsonc)
cat > opencode.jsonc << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "playwriter": {
      "type": "local",
      "command": ["bunx", "-y", "playwriter@latest"],
      "enabled": true
    }
  }
}
EOF
echo "  ✓ opencode.jsonc"

echo ""
echo "Done. Restart your editor to load MCP servers."
