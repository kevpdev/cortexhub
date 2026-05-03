#!/usr/bin/env bash
# install.sh — CortexHub installer
# Sets up ~/.ai-core/ and Claude Code wrappers via symlinks.
# Safe to re-run (idempotent). Detects conflicts before acting.
#
# Usage:
#   ./install.sh                     — full install (core + Claude wrapper)
#   ./install.sh --cursor            — also install Cursor commands
#   ./install.sh --continue          — also install Continue.dev config
#   ./install.sh --mcp               — also install MCP server
#   ./install.sh --dry-run           — show what would be done, no changes
#   ./install.sh --uninstall [flags] — remove what was installed
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$REPO_DIR/core"
CLAUDE_WRAPPER="$REPO_DIR/wrappers/claude"
CURSOR_WRAPPER="$REPO_DIR/wrappers/cursor"
CONTINUE_WRAPPER="$REPO_DIR/wrappers/continue"
MCP_WRAPPER="$REPO_DIR/wrappers/mcp"

DRY_RUN=false
UNINSTALL=false
INSTALL_MCP=false
INSTALL_CURSOR=false
INSTALL_CONTINUE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --mcp)       INSTALL_MCP=true ;;
    --cursor)    INSTALL_CURSOR=true ;;
    --continue)  INSTALL_CONTINUE=true ;;
    *) printf "Unknown option: %s\nUsage: install.sh [--dry-run|--uninstall|--mcp|--cursor|--continue]\n" "$arg"; exit 1 ;;
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

  if $INSTALL_CURSOR; then
    printf "\nRemoving ~/.cursor/commands wrappers\n"
    for cmd in "$CURSOR_WRAPPER/commands/"*.md; do
      name="$(basename "$cmd")"
      remove_symlink "$HOME/.cursor/commands/$name"
    done
  fi

  if $INSTALL_CONTINUE; then
    printf "\nNote: ~/.continue/config.ts was not auto-installed via symlink.\n"
    log "Remove CortexHub entries from ~/.continue/config.ts manually."
  fi

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

printf "\n6. Claude hook (suggest-skill)\n"
HOOK_SRC="$CLAUDE_WRAPPER/settings.hook.json"
SETTINGS_DEST="$HOME/.claude/settings.json"
HOOK_MARKER="suggest-skill"

if $DRY_RUN; then
  log_dry "merge hook into $SETTINGS_DEST (if not already present)"
elif grep -qF "$HOOK_MARKER" "$SETTINGS_DEST" 2>/dev/null; then
  log_ok "hook already present in $SETTINGS_DEST"
elif ! command -v jq &>/dev/null; then
  log_err "jq not found — install jq and re-run to add the suggest-skill hook"
else
  if [ -f "$SETTINGS_DEST" ]; then
    tmp=$(mktemp)
    jq -s '.[0] * .[1]' "$SETTINGS_DEST" "$HOOK_SRC" > "$tmp" && mv "$tmp" "$SETTINGS_DEST"
  else
    cp "$HOOK_SRC" "$SETTINGS_DEST"
  fi
  log_ok "hook injected into $SETTINGS_DEST"
fi

printf "\n7. providers.json\n"
PROVIDERS_EXAMPLE="$CORE_DIR/config/providers.json.example"
PROVIDERS_DEST="$CORE_DIR/config/providers.json"
if $DRY_RUN; then
  log_dry "copy providers.json.example → providers.json (if not exists)"
elif [ -f "$PROVIDERS_DEST" ]; then
  log_ok "providers.json already exists — skipping"
else
  cp "$PROVIDERS_EXAMPLE" "$PROVIDERS_DEST"
  log_ok "providers.json created from example"
  log "Edit ~/.ai-core/config/providers.json to configure your models"
fi

if $INSTALL_CURSOR; then
  printf "\n8. Cursor commands (~/.cursor/commands/)\n"
  mkdir -p "$HOME/.cursor/commands"
  for cmd in "$CURSOR_WRAPPER/commands/"*.md; do
    name="$(basename "$cmd")"
    make_symlink "$cmd" "$HOME/.cursor/commands/$name"
  done

  printf "\n   Cursor rules (~/.cursor/rules/)\n"
  mkdir -p "$HOME/.cursor/rules"
  for rule in "$CURSOR_WRAPPER/rules/"*.mdc; do
    [ -f "$rule" ] || continue
    name="$(basename "$rule")"
    make_symlink "$rule" "$HOME/.cursor/rules/$name"
  done
fi

if $INSTALL_CONTINUE; then
  printf "\n9. Continue.dev config (~/.continue/config.ts)\n"
  CONTINUE_DEST="$HOME/.continue/config.ts"
  mkdir -p "$HOME/.continue"
  if $DRY_RUN; then
    log_dry "copy $CONTINUE_WRAPPER/config.ts → $CONTINUE_DEST (if not exists)"
  elif [ -f "$CONTINUE_DEST" ]; then
    log_ok "$CONTINUE_DEST already exists — skipping (merge manually if needed)"
    log "Reference: $CONTINUE_WRAPPER/config.ts"
  else
    cp "$CONTINUE_WRAPPER/config.ts" "$CONTINUE_DEST"
    log_ok "config.ts installed at $CONTINUE_DEST"
  fi
fi

if $INSTALL_MCP; then
  printf "\n10. MCP server\n"
  if $DRY_RUN; then
    log_dry "npm install in $MCP_WRAPPER"
    log_dry "symlink ~/.ai-core/mcp → $MCP_WRAPPER"
  else
    if ! command -v node &>/dev/null; then
      log_err "Node.js not found — install Node 18+ and re-run with --mcp"
    else
      (cd "$MCP_WRAPPER" && npm install --silent)
      log_ok "npm install done"
      make_symlink "$MCP_WRAPPER" "$HOME/.ai-core/mcp"
      printf "\n"
      log "To connect to Claude Code, run:"
      log "  claude mcp add cortexhub -- node \$HOME/.ai-core/mcp/server.js"
    fi
  fi
fi

printf "\nDone%s.\n" "$(if $DRY_RUN; then printf " (dry-run — no changes made)"; fi)"
