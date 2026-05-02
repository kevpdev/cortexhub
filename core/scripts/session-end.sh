#!/usr/bin/env bash
# session-end.sh [--accomplished "..." --next "..." [--challenges "..."]]
#
# (no args)   Interactive: asks questions, writes activeContext.md
# With args:  Non-interactive, used by agent wrappers
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
NOW=$(date +"%Y-%m-%d %H:%M")

# ── Parse args ────────────────────────────────────────────────────────────────

ACCOMPLISHED=""
NEXT=""
CHALLENGES=""

if [ $# -gt 0 ]; then
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --accomplished) ACCOMPLISHED="${2:-}"; shift 2 ;;
      --next)         NEXT="${2:-}";         shift 2 ;;
      --challenges)   CHALLENGES="${2:-}";   shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done
else
  read -rp "What did you accomplish this session? " ACCOMPLISHED
  read -rp "What's the next step for your next session? " NEXT
  read -rp "Any new challenges or blockers? (Enter to skip) " CHALLENGES
fi

if [ -z "$ACCOMPLISHED" ] || [ -z "$NEXT" ]; then
  echo "Error: --accomplished and --next are required." >&2
  exit 1
fi

# ── Write to activeContext.md (atomic) ────────────────────────────────────────
# Lambdas used in re.sub — user strings are never interpreted as regex
# backreferences. \Z handles sections that appear last in the file.

python3 - "$ACTIVE" "$NOW" "$ACCOMPLISHED" "$NEXT" "$CHALLENGES" <<'PYEOF'
import sys, re, os, tempfile

path  = sys.argv[1]
now   = sys.argv[2]
accomplished = sys.argv[3]
next_step    = sys.argv[4]
challenges   = sys.argv[5]

content = open(path, encoding='utf-8').read()

# Timestamp
content = re.sub(r'^Last update:.*', f'Last update: {now}', content, flags=re.MULTILINE)

# Prepend to Recent Changes
content = re.sub(
    r'(## Recent Changes\n)',
    lambda m: m.group(1) + f'[{now}]: {accomplished}\n',
    content
)

# Replace Next Steps — \Z handles last section in file
content = re.sub(
    r'(## Next Steps\n).*?(\n## |\Z)',
    lambda m: m.group(1) + f'1. [ ] {next_step}\n' + m.group(2),
    content, flags=re.DOTALL
)

# Replace Challenges if provided — \Z handles last section in file
if challenges:
    content = re.sub(
        r'(## Challenges\n).*?(\n## |\Z)',
        lambda m: m.group(1) + challenges + '\n' + m.group(2),
        content, flags=re.DOTALL
    )

# Atomic write — prevents file truncation if interrupted mid-write
with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=os.path.dirname(os.path.abspath(path)), delete=False, suffix='.tmp') as f:
    f.write(content)
    tmp = f.name
os.replace(tmp, path)
PYEOF

echo ""
echo "Session saved to $ACTIVE"
echo "  Accomplished: $ACCOMPLISHED"
echo "  Next:         $NEXT"
if [ -n "$CHALLENGES" ]; then echo "  Challenges:   $CHALLENGES"; fi
