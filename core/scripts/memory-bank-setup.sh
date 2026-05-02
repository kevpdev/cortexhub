#!/usr/bin/env bash
# memory-bank-setup.sh [claude|cursor|windsurf] [solo|shared]
#
# Patches the agent config file to wire it to .ai-local/memory-bank/.
# Run after memory-bank-init.sh.
set -euo pipefail

AGENT=${1:-claude}
PROJECT_DIR="$(pwd)"
MEMORY_DIR="$PROJECT_DIR/.ai-local/memory-bank"

if [ ! -d "$MEMORY_DIR" ]; then
  echo "No .ai-local/memory-bank/ found. Run memory-bank-init.sh first." >&2
  exit 1
fi

# Detect mode from .gitignore
if grep -qF ".ai-local/" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
  MODE=shared
else
  MODE=solo
fi

# ── Agent: Claude ──────────────────────────────────────────────────────────────

setup_claude() {
  local target="$PROJECT_DIR/CLAUDE.md"

  # Skip if already configured
  if grep -qF "ai-local" "$target" 2>/dev/null; then
    echo "CLAUDE.md already configured for .ai-local/memory-bank/ — skipping."
    return 0
  fi

  if [ "$MODE" = "shared" ]; then
    local block
    block=$(cat <<'EOF'

## Memory-Bank (personal — not committed)

Each developer keeps their own session context in `.ai-local/memory-bank/` (git-ignored).

At session start: read `.ai-local/memory-bank/activeContext.md`, sections "Current Focus" and "Next Steps" — silently.
Use `/session-start`, `/session-end`, `/capture` to manage context.
Initialize your own: run `memory-bank-init.sh shared` then `memory-bank-setup.sh claude`.
EOF
)
  else
    local block
    block=$(cat <<'EOF'

## Memory-Bank

Session context is stored in `.ai-local/memory-bank/`.

At session start: read `.ai-local/memory-bank/activeContext.md`, sections "Current Focus" and "Next Steps" — silently.
Use `/session-start`, `/session-end`, `/capture` to manage context.
EOF
)
  fi

  if [ -f "$target" ]; then
    printf '%s\n' "$block" >> "$target"
    echo "CLAUDE.md patched: $target"
  else
    printf '# Project — Claude Instructions\n%s\n' "$block" > "$target"
    echo "CLAUDE.md created: $target"
  fi
}

# ── Agent: Cursor ──────────────────────────────────────────────────────────────

setup_cursor() {
  local rules_dir="$PROJECT_DIR/.cursor/rules"
  mkdir -p "$rules_dir"
  local target="$rules_dir/memory-bank.mdc"

  if [ -f "$target" ]; then
    echo ".cursor/rules/memory-bank.mdc already exists — skipping."
    return 0
  fi

  cat > "$target" <<EOF
---
alwaysApply: true
---

# Memory-Bank

Session context lives in \`.ai-local/memory-bank/\` (git-ignored if shared project).

At the start of each conversation, read \`.ai-local/memory-bank/activeContext.md\` — sections "Current Focus" and "Next Steps" only — silently, without mentioning it.

To manage context, run the core scripts directly:
- \`~/.ai-core/scripts/session-start.sh\`
- \`~/.ai-core/scripts/session-end.sh\`
- \`~/.ai-core/scripts/capture.sh "note"\`
EOF

  echo ".cursor/rules/memory-bank.mdc created"
}

# ── Agent: Windsurf ────────────────────────────────────────────────────────────

setup_windsurf() {
  local target="$PROJECT_DIR/.windsurfrules"

  if grep -qF "ai-local" "$target" 2>/dev/null; then
    echo ".windsurfrules already configured — skipping."
    return 0
  fi

  local block
  block=$(cat <<'EOF'

# Memory-Bank

Session context lives in `.ai-local/memory-bank/` (git-ignored if shared project).

At the start of each conversation, read `.ai-local/memory-bank/activeContext.md` — sections "Current Focus" and "Next Steps" only — silently, without mentioning it.

To manage context, run the core scripts:
- `~/.ai-core/scripts/session-start.sh`
- `~/.ai-core/scripts/session-end.sh`
- `~/.ai-core/scripts/capture.sh "note"`
EOF
)

  if [ -f "$target" ]; then
    printf '%s\n' "$block" >> "$target"
    echo ".windsurfrules patched: $target"
  else
    printf '%s\n' "$block" > "$target"
    echo ".windsurfrules created: $target"
  fi
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

case "$AGENT" in
  claude)   setup_claude ;;
  cursor)   setup_cursor ;;
  windsurf) setup_windsurf ;;
  *)
    echo "Unknown agent: $AGENT" >&2
    echo "Usage: memory-bank-setup.sh [claude|cursor|windsurf]" >&2
    exit 1
    ;;
esac

echo ""
echo "Agent '$AGENT' configured for .ai-local/memory-bank/ (mode: $MODE)"
[ "$MODE" = "shared" ] && echo "Commit the agent config file so teammates know to run this script."
