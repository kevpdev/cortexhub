#!/usr/bin/env bash
# capture.sh "note text"
# Appends a timestamped note to today's capture file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

NOTE="${1:-}"
if [ -z "$NOTE" ]; then
  echo "Usage: capture.sh \"your note\"" >&2
  exit 1
fi

CAPTURES_DIR=$(find_captures_dir)
if [ -z "$CAPTURES_DIR" ]; then
  echo "No memory-bank found. Run: memory-bank-init.sh" >&2
  exit 1
fi

mkdir -p "$CAPTURES_DIR"

TODAY=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
FILE="$CAPTURES_DIR/$TODAY.md"

if [ ! -f "$FILE" ]; then
  printf '# Captures for %s\n\n' "$TODAY" > "$FILE"
fi

# printf avoids echo interpreting flags like -e or -n in NOTE
printf '[%s] %s\n' "$TIME" "$NOTE" >> "$FILE"
printf 'Captured to %s\n' "$FILE"
printf '[%s] %s\n' "$TIME" "$NOTE"
