#!/usr/bin/env bash
# session-start.sh [--read | --set-focus "goal" | "goal"]
#
# --read          Print current context (for agent wrappers to display)
# --set-focus X   Update Current Focus in activeContext.md
# "goal"          Shorthand for --set-focus "goal"
# (no args)       Interactive: display context, ask for goal, update
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MEMORY_DIR=$(find_memory_dir)
if [ -z "$MEMORY_DIR" ]; then
  echo "No memory-bank found. Run: memory-bank-init.sh" >&2
  exit 1
fi

ACTIVE="$MEMORY_DIR/activeContext.md"
if [ ! -f "$ACTIVE" ]; then
  echo "activeContext.md not found in $MEMORY_DIR" >&2
  exit 1
fi

NOW=$(date +"%Y-%m-%d %H:%M")  # GNU date and BSD date (macOS) both support this format

# ── Helpers ───────────────────────────────────────────────────────────────────

print_context() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  # Use awk (consistent with other sections) instead of grep -A2 (fragile)
  focus=$(awk '/^## Current Focus/{found=1; next} found && /^## /{exit} found && /[^[:space:]]/{print; exit}' "$ACTIVE" 2>/dev/null || true)
  echo "Focus:  ${focus:-—}"
  echo ""
  echo "Next Steps:"
  awk '/^## Next Steps/{found=1; next} found && /^## /{exit} found{print}' "$ACTIVE" 2>/dev/null \
    | grep -v "^[[:space:]]*$" | head -5 || true
  echo ""
  echo "Challenges:"
  awk '/^## Challenges/{found=1; next} found && /^## /{exit} found{print}' "$ACTIVE" 2>/dev/null \
    | grep -v "^[[:space:]]*$" | head -3 || true
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

set_focus() {
  local goal="$1"
  # Full rewrite via Python — avoids sed -i BSD/GNU incompatibility.
  # Atomic write via temp file — prevents truncation if interrupted.
  # Lambda in re.sub so \1, \\ in goal are never interpreted as backreferences.
  # \Z handles the case where Current Focus is the last section in the file.
  python3 - "$ACTIVE" "$goal" "$NOW" <<'PYEOF'
import sys, re, os, tempfile

path, goal, now = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path, encoding='utf-8').read()
content = re.sub(r'^Last update:.*', f'Last update: {now}', content, flags=re.MULTILINE)
content = re.sub(
    r'(## Current Focus\n).*?(\n## |\Z)',
    lambda m: m.group(1) + goal + '\n' + m.group(2),
    content, flags=re.DOTALL
)
with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=os.path.dirname(os.path.abspath(path)), delete=False, suffix='.tmp') as f:
    f.write(content)
    tmp = f.name
os.replace(tmp, path)
PYEOF
  echo "Focus set: $goal"
  echo "Updated: $ACTIVE"
}

# ── Modes ─────────────────────────────────────────────────────────────────────

ARG=${1:-}

if [ "$ARG" = "--read" ]; then
  print_context
  exit 0
fi

if [ "$ARG" = "--set-focus" ]; then
  if [ -z "${2:-}" ]; then
    echo "Usage: session-start.sh --set-focus \"your goal\"" >&2
    exit 1
  fi
  set_focus "$2"
  exit 0
fi

# Shorthand: bare string argument = goal
if [ -n "$ARG" ] && [[ "$ARG" != --* ]]; then
  set_focus "$ARG"
  exit 0
fi

# Interactive mode
print_context
echo ""
read -rp "What's your goal for this session? " goal
if [ -n "$goal" ]; then
  set_focus "$goal"
fi
echo ""
echo "Session started. Context loaded from $MEMORY_DIR"
