#!/usr/bin/env bash
# install.sh — CortexHub installer
# Sets up ~/.ai-core/ and Claude Code wrappers via symlinks.
# Safe to re-run (idempotent). Detects conflicts before acting.
#
# Usage:
#   ./install.sh                     — full install (core + Claude wrapper)
#   ./install.sh --cursor            — also install Cursor commands
#   ./install.sh --opencode          — also install OpenCode + Ollama gateway
#   ./install.sh --mcp               — also install MCP server
#   ./install.sh --dry-run           — show what would be done, no changes
#   ./install.sh --uninstall [flags] — remove what was installed
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$REPO_DIR/core"
CLAUDE_WRAPPER="$REPO_DIR/wrappers/claude"
CURSOR_WRAPPER="$REPO_DIR/wrappers/cursor"
MCP_WRAPPER="$REPO_DIR/wrappers/mcp"
OPENCODE_WRAPPER="$REPO_DIR/wrappers/opencode"

DRY_RUN=false
UNINSTALL=false
INSTALL_MCP=false
INSTALL_CURSOR=false
INSTALL_OPENCODE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --mcp)       INSTALL_MCP=true ;;
    --cursor)    INSTALL_CURSOR=true ;;
    --opencode)  INSTALL_OPENCODE=true ;;
    *) printf "Unknown option: %s\nUsage: install.sh [--dry-run|--uninstall|--cursor|--opencode|--mcp]\n" "$arg"; exit 1 ;;
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

  printf "\nRemoving ~/.claude/agents wrappers\n"
  for agent in "$CLAUDE_WRAPPER/agents/"*.md; do
    name="$(basename "$agent")"
    remove_symlink "$HOME/.claude/agents/$name"
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

  if $INSTALL_OPENCODE; then
    printf "\nRemoving ~/.config/opencode/opencode.json (if installed by CortexHub)\n"
    OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
    if [ -L "$OPENCODE_CONFIG" ]; then
      remove_symlink "$OPENCODE_CONFIG"
    elif [ -f "$OPENCODE_CONFIG" ] && grep -q '"cortexhub"' "$OPENCODE_CONFIG" 2>/dev/null; then
      if $DRY_RUN; then
        log_dry "remove $OPENCODE_CONFIG (CortexHub-managed)"
      else
        rm "$OPENCODE_CONFIG"
        log_ok "removed $OPENCODE_CONFIG"
      fi
    else
      log "skip: $OPENCODE_CONFIG not managed by CortexHub"
    fi
    printf "\nRemoving ~/.local/bin/oc symlink\n"
    remove_symlink "$HOME/.local/bin/oc"
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

printf "\n4. Claude agents wrappers\n"
mkdir -p "$HOME/.claude/agents"
for agent in "$CLAUDE_WRAPPER/agents/"*.md; do
  name="$(basename "$agent")"
  make_symlink "$agent" "$HOME/.claude/agents/$name"
done

printf "\n6. MEMORY-BANK-GUIDE.md\n"
make_symlink "$CORE_DIR/docs/MEMORY-BANK-GUIDE.md" "$HOME/.claude/MEMORY-BANK-GUIDE.md"

printf "\n7. CLAUDE.md snippet\n"
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

printf "\n8. Claude hook (suggest-skill)\n"
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

printf "\n9. providers.json\n"
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

if $INSTALL_OPENCODE; then
  printf "\n9. OpenCode + Ollama gateway\n"
  OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
  OPENCODE_CONFIG_DEST="$OPENCODE_CONFIG_DIR/opencode.json"

  if $DRY_RUN; then
    log_dry "chmod +x opencode-start.sh"
    log_dry "copy $OPENCODE_WRAPPER/opencode.json → $OPENCODE_CONFIG_DEST (if not exists)"
    log_dry "symlink ~/.local/bin/oc → $OPENCODE_WRAPPER/opencode-start.sh"
  else
    chmod +x "$OPENCODE_WRAPPER/opencode-start.sh"
    log_ok "opencode-start.sh marked executable"
    mkdir -p "$OPENCODE_CONFIG_DIR"
    if [ -f "$OPENCODE_CONFIG_DEST" ]; then
      log_ok "$OPENCODE_CONFIG_DEST already exists — skipping (merge manually if needed)"
      log "Reference: $OPENCODE_WRAPPER/opencode.json"
    else
      cp "$OPENCODE_WRAPPER/opencode.json" "$OPENCODE_CONFIG_DEST"
      log_ok "opencode.json installed at $OPENCODE_CONFIG_DEST"
    fi

    mkdir -p "$HOME/.local/bin"
    make_symlink "$OPENCODE_WRAPPER/opencode-start.sh" "$HOME/.local/bin/oc"
    printf "\n"
    log "Usage: oc \"describe your task\"   (routes to the right Ollama model)"
    log "       oc                          (default: code profile)"
    log "See $OPENCODE_WRAPPER/MODELS.md for available profiles and models to pull"
    if [ ! -f "$HOME/.ai-core/mcp/server.js" ]; then
      printf "\n"
      log_err "MCP server not installed — session tools won't be available in OpenCode"
      log     "Run: ./install.sh --mcp"
    fi
  fi
fi

if $INSTALL_MCP; then
  printf "\n10. MCP server\n"
  if $DRY_RUN; then
    log_dry "pnpm install in $MCP_WRAPPER"
    log_dry "symlink ~/.ai-core/mcp → $MCP_WRAPPER"
  else
    if ! command -v node &>/dev/null; then
      log_err "Node.js not found — install Node 24+ and re-run with --mcp"
    elif ! command -v pnpm &>/dev/null; then
      log_err "pnpm not found — run 'corepack enable' then re-run with --mcp"
    else
      (cd "$MCP_WRAPPER" && pnpm install --silent)
      log_ok "pnpm install done"
      make_symlink "$MCP_WRAPPER" "$HOME/.ai-core/mcp"
      printf "\n"
      log "To connect to Claude Code, run:"
      log "  claude mcp add cortexhub -- node \$HOME/.ai-core/mcp/server.js"
    fi
  fi
fi

printf "\nDone%s.\n" "$(if $DRY_RUN; then printf " (dry-run — no changes made)"; fi)"
