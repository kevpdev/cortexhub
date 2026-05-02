#!/usr/bin/env bash
# memory-bank-init.sh [solo|shared]
# Creates .ai-local/memory-bank/ in the current project directory.
# Agent-agnostic — no AI agent config is touched here.
set -euo pipefail

MODE=${1:-}

if [ -z "$MODE" ]; then
  echo "Is this project solo (just you) or shared with a team?"
  echo "  [1] solo   — .ai-local/memory-bank/ (you decide whether to commit it)"
  echo "  [2] shared — .ai-local/memory-bank/ + added to .gitignore"
  read -rp "Choice [1/2]: " choice
  case "$choice" in
    1) MODE=solo ;;
    2) MODE=shared ;;
    *) echo "Invalid choice. Aborting."; exit 1 ;;
  esac
fi

if [[ "$MODE" != "solo" && "$MODE" != "shared" ]]; then
  echo "Usage: memory-bank-init.sh [solo|shared]"
  exit 1
fi

MEMORY_DIR=".ai-local/memory-bank"
TODAY=$(date +%Y-%m-%d)
TEMPLATES_DIR="$HOME/.ai-core/templates/memory-bank"

if [ -d "$MEMORY_DIR" ]; then
  read -rp ".ai-local/memory-bank/ already exists. Overwrite? [y/N] " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

mkdir -p "$MEMORY_DIR/captures"

cp "$TEMPLATES_DIR/projectbrief.md" "$MEMORY_DIR/projectbrief.md"
cp "$TEMPLATES_DIR/techContext.md" "$MEMORY_DIR/techContext.md"
sed "s/{{TODAY}}/$TODAY/" "$TEMPLATES_DIR/activeContext.md" > "$MEMORY_DIR/activeContext.md"

if [ "$MODE" = "shared" ]; then
  if ! grep -qF ".ai-local/" .gitignore 2>/dev/null; then
    echo ".ai-local/" >> .gitignore
    echo ".ai-local/ added to .gitignore"
  fi
fi

echo ""
echo "Memory-bank initialized in .ai-local/memory-bank/ (mode: $MODE)"
echo "  projectbrief.md"
echo "  techContext.md"
echo "  activeContext.md"
echo ""
echo "Next: configure your AI agent to read this memory-bank."
