#!/usr/bin/env sh
set -e

# fix-opencode-skills.sh
# Workaround for OpenCode not loading project-level skills
# This script symlinks skills from .opencode/skill/ to ~/.claude/skills/
#
# Usage:
#   ./scripts/fix-opencode-skills.sh                    # Auto-detect and symlink all
#   ./scripts/fix-opencode-skills.sh zepto-automation   # Symlink specific skill
#   ./scripts/fix-opencode-skills.sh --project /path    # From specific project
#   ./scripts/fix-opencode-skills.sh -y                 # Skip confirmation prompt
#
# Why this is needed:
#   OpenCode has a bug where it only loads skills from ~/.claude/skills/
#   instead of also scanning project-level .opencode/skill/ directories.
#   See: INVESTIGATION-opencode-skill-loading.md

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
PROJECT_DIR=""
SPECIFIC_SKILLS=""
SKIP_CONFIRM=""

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --project|-p)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -y|--yes)
      SKIP_CONFIRM="yes"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [options] [skill-names...]"
      echo ""
      echo "Options:"
      echo "  --project, -p <path>   Project directory to scan for skills"
      echo "  -y, --yes              Skip confirmation prompt"
      echo "  --help, -h             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                          # Symlink all skills from ~/.opencode/skill/"
      echo "  $0 zepto-automation         # Symlink specific skill"
      echo "  $0 --project ./my-project   # Symlink skills from project's .opencode/skill/"
      echo "  $0 -y                       # Auto-confirm (for scripts)"
      exit 0
      ;;
    *)
      SPECIFIC_SKILLS="$SPECIFIC_SKILLS $1"
      shift
      ;;
  esac
done

echo "=== OpenCode Skills Fix ==="
echo ""
echo "This script creates symlinks from your installed skills to"
echo "~/.claude/skills/ where OpenCode can find them."
echo ""
echo "This is a workaround for an OpenCode bug. Symlinks are safe"
echo "and reversible — to undo, just delete the symlink:"
echo "  rm ~/.claude/skills/zepto-automation  (example)"
echo ""

if [ "$SKIP_CONFIRM" != "yes" ] && [ -t 0 ] && [ -t 1 ]; then
  printf "Continue? [y/N] "
  read -r response
  case "$response" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
  echo ""
fi

# Determine source directories to scan
SOURCES=""
if [ -n "$PROJECT_DIR" ]; then
  SOURCES="$PROJECT_DIR/.opencode/skill"
else
  # Default: scan global and current project
  SOURCES="$HOME/.opencode/skill"
  if [ -d ".opencode/skill" ]; then
    SOURCES="$SOURCES $(pwd)/.opencode/skill"
  fi
fi

mkdir -p "$CLAUDE_SKILLS_DIR"

symlink_skill() {
  skill_name="$1"
  skill_path="$2"
  dst="$CLAUDE_SKILLS_DIR/$skill_name"
  
  if [ -L "$dst" ]; then
    existing=$(readlink "$dst" 2>/dev/null || echo "unknown")
    if [ "$existing" = "$skill_path" ]; then
      echo "  ↻ $skill_name (symlink exists, same target)"
    else
      echo "  ⚠ $skill_name (symlink exists → $existing)"
      echo "    To update: rm '$dst' && ln -s '$skill_path' '$dst'"
    fi
  elif [ -d "$dst" ]; then
    echo "  ⚠ $skill_name (directory exists, not a symlink)"
    echo "    To replace: rm -rf '$dst' && ln -s '$skill_path' '$dst'"
  elif [ -f "$dst" ]; then
    echo "  ⚠ $skill_name (file exists, not a directory)"
  else
    ln -s "$skill_path" "$dst"
    echo "  ✓ $skill_name"
    echo "    $skill_path → $dst"
  fi
}

found=0
for src_dir in $SOURCES; do
  if [ ! -d "$src_dir" ]; then
    continue
  fi
  
  echo "Scanning: $src_dir"
  
  for skill_path in "$src_dir"/*; do
    if [ ! -d "$skill_path" ]; then
      continue
    fi
    
    skill_name=$(basename "$skill_path")
    
    # Check if SKILL.md exists
    if [ ! -f "$skill_path/SKILL.md" ]; then
      continue
    fi
    
    # If specific skills requested, filter
    if [ -n "$SPECIFIC_SKILLS" ]; then
      case "$SPECIFIC_SKILLS" in
        *"$skill_name"*) ;;
        *) continue ;;
      esac
    fi
    
    symlink_skill "$skill_name" "$skill_path"
    found=$((found + 1))
  done
done

echo ""
if [ $found -eq 0 ]; then
  echo "No skills found to symlink."
  echo ""
  echo "Checked:"
  for src_dir in $SOURCES; do
    echo "  - $src_dir"
  done
  echo ""
  echo "Make sure skills are installed in .opencode/skill/<skill-name>/SKILL.md"
else
  echo "Done! $found skill(s) processed."
  echo ""
  echo "Restart OpenCode to load the skills."
fi
