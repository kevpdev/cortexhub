#!/usr/bin/env bash
# install.sh — CortexHub installer
# Sets up ~/.ai-core/ and Claude Code wrappers via symlinks.
# Safe to re-run (idempotent). Detects conflicts before acting.
#
# Usage:
#   ./install.sh           — full interactive install
#   ./install.sh --dry-run — show what would be done, no changes
#   ./install.sh --uninstall — remove all symlinks created by this script
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$REPO_DIR/core"
CLAUDE_WRAPPER="$REPO_DIR/wrappers/claude"

DRY_RUN=false
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    *) printf "Unknown option: %s\nUsage: install.sh [--dry-run|--uninstall]\n" "$arg"; exit 1 ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────

log()     { printf "  %s\n" "$*"; }
log_ok()  { printf "  ✓ %s\n" "$*"; }
log_dry() { printf "  ~ %s\n" "$*"; }
log_err() { printf "  ✗ %s\n" "$*" >&2; }

make_symlink() {
  local target="$1"
  local link="$2"

  if $DRY_RUN; then
    log_dry "symlink $link → $target"
    return
  fi

  if [ -e "$link" ] && [ ! -L "$link" ]; then
    log_err "CONFLICT: $link exists and is not a symlink — skipping (move it manually)"
    return 1
  fi

  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    log_ok "$link (already correct)"
    return
  fi

  ln -sfn "$target" "$link"
  log_ok "$link → $target"
}

remove_symlink() {
  local link="$1"
  if $DRY_RUN; then
    log_dry "remove symlink $link"
    return
  fi
  if [ -L "$link" ]; then
    rm "$link"
    log_ok "removed $link"
  else
    log "skip (not a symlink): $link"
  fi
}

# ── Uninstall ──────────────────────────────────────────────────────────────────

if $UNINSTALL; then
  printf "\n=== CortexHub uninstall ===\n\n"

  printf "Removing ~/.ai-core\n"
  remove_symlink "$HOME/.ai-core"

  printf "\nRemoving ~/.claude/skills wrappers\n"
  for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
    remove_symlink "$HOME/.claude/skills/$skill"
  done

  printf "\nRemoving ~/.claude/commands wrappers\n"
  for cmd in "$CLAUDE_WRAPPER/commands/"*.md; do
    name="$(basename "$cmd")"
    remove_symlink "$HOME/.claude/commands/$name"
  done

  printf "\nRemoving ~/.claude/MEMORY-BANK-GUIDE.md\n"
  remove_symlink "$HOME/.claude/MEMORY-BANK-GUIDE.md"

  printf "\nDone.\n"
  exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────────

printf "\n=== CortexHub install%s ===\n\n" "$(if $DRY_RUN; then printf " (dry-run)"; fi)"

printf "1. Core — ~/.ai-core → %s/core\n" "$REPO_DIR"
make_symlink "$CORE_DIR" "$HOME/.ai-core"

printf "\n2. Claude skills wrappers\n"
for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
  make_symlink "$CORE_DIR/skills/$skill" "$HOME/.claude/skills/$skill"
done

printf "\n3. Claude commands wrappers\n"
mkdir -p "$HOME/.claude/commands"
for cmd in "$CLAUDE_WRAPPER/commands/"*.md; do
  name="$(basename "$cmd")"
  make_symlink "$cmd" "$HOME/.claude/commands/$name"
done

printf "\n4. MEMORY-BANK-GUIDE.md\n"
make_symlink "$CORE_DIR/docs/MEMORY-BANK-GUIDE.md" "$HOME/.claude/MEMORY-BANK-GUIDE.md"

printf "\n5. CLAUDE.md snippet\n"
SNIPPET="$CLAUDE_WRAPPER/CLAUDE.md.snippet"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
MARKER="## Session Auto-Load (Memory-Bank)"

if $DRY_RUN; then
  log_dry "inject snippet into $CLAUDE_MD (if not already present)"
elif grep -qF "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  log_ok "snippet already present in $CLAUDE_MD"
else
  printf "\n" >> "$CLAUDE_MD"
  cat "$SNIPPET" >> "$CLAUDE_MD"
  log_ok "snippet injected into $CLAUDE_MD"
fi

printf "\nDone%s.\n" "$(if $DRY_RUN; then printf " (dry-run — no changes made)"; fi)"
