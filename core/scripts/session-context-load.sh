#!/usr/bin/env bash
# session-context-load.sh — SessionStart hook for Claude Code
# Injects Current Focus + Next Steps from activeContext.md at session start.
# Silent (exit 0, no output) when no memory-bank exists — safe on any project.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

MEMORY_DIR=$(find_memory_dir)
[ -z "$MEMORY_DIR" ] && exit 0

ACTIVE="$MEMORY_DIR/activeContext.md"
[ -f "$ACTIVE" ] || exit 0

focus=$(awk '/^## Current Focus/{found=1; next} found && /^## /{exit} found && /[^[:space:]]/{print; exit}' "$ACTIVE" 2>/dev/null || true)
next=$(awk '/^## Next Steps/{found=1; next} found && /^## /{exit} found && /[^[:space:]]/{print}' "$ACTIVE" 2>/dev/null | head -5 || true)

[ -z "$focus" ] && [ -z "$next" ] && exit 0

context="[Contexte de session chargé depuis $ACTIVE]"$'\n'
[ -n "$focus" ] && context+="Focus actuel : $focus"$'\n'
if [ -n "$next" ]; then
  context+="Prochaines étapes :"$'\n'
  while IFS= read -r line; do
    context+="  $line"$'\n'
  done <<< "$next"
fi

python3 -c "
import sys, json
ctx = sys.stdin.read()
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': ctx.strip()
    }
}))
" <<< "$context"
