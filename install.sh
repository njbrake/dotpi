#!/usr/bin/env bash
# Symlink pi-config files/dirs into ~/.pi/agent/.
# Idempotent: safe to re-run after edits.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.pi/agent"

mkdir -p "$TARGET"

# Files to symlink (only if present in this repo)
FILES=(
  AGENTS.md
  APPEND_SYSTEM.md
  SYSTEM.md
  settings.json
  models.json
)

DIRS=(
  skills
  prompts
  tools
  themes
)

backup_if_real() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$path" "$backup"
    echo "  backed up existing $path -> $backup"
  fi
}

for f in "${FILES[@]}"; do
  src="$REPO_DIR/$f"
  dst="$TARGET/$f"
  if [ -f "$src" ]; then
    backup_if_real "$dst"
    ln -sfn "$src" "$dst"
    echo "linked: $dst -> $src"
  fi
done

for d in "${DIRS[@]}"; do
  src="$REPO_DIR/$d"
  dst="$TARGET/$d"
  if [ -d "$src" ]; then
    backup_if_real "$dst"
    ln -sfn "$src" "$dst"
    echo "linked: $dst -> $src"
  fi
done

echo
echo "Done. Pi will read from $TARGET on next startup."
echo "Verify with: ls -la $TARGET"
