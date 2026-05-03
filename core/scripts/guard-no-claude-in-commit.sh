#!/usr/bin/env bash
# guard-no-claude-in-commit.sh — PreToolUse(Bash) hook for Claude Code
# Blocks git commit commands that include "Claude" or "Co-Authored-By: Claude"
# in the message — enforces the project convention without relying on CLAUDE.md.
set -euo pipefail

# Read hook payload from stdin
payload=$(cat)

# Only act on Bash tool calls
tool=$(printf "%s" "$payload" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")
[ "$tool" != "Bash" ] && exit 0

# Extract the command
cmd=$(printf "%s" "$payload" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# Only inspect git commit commands
printf "%s" "$cmd" | grep -qE "git commit" || exit 0

# Check for forbidden patterns (case-insensitive)
if printf "%s" "$cmd" | grep -qiE "Co-Authored-By: Claude|claude sonnet|claude opus|claude haiku|noreply@anthropic"; then
  python3 -c "
import json
print(json.dumps({
    'decision': 'block',
    'reason': 'Mention de Claude détectée dans le message de commit. Convention du projet : aucune mention de Claude ni Co-Authored-By dans les commits. Retire ces lignes et recommence.'
}))
"
  exit 0
fi

exit 0
