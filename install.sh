#!/usr/bin/env bash
# install.sh — CortexHub installer
# Philosophy: add only, never modify, never delete.
# The installer creates symlinks and copies templates. It NEVER overwrites a user
# file, NEVER deletes anything, NEVER auto-merges configs. Conflicts and drift
# are reported; the user resolves them manually.
#
# Usage:
#   ./install.sh                     — install Claude wrappers (default)
#   ./install.sh --cursor            — install Cursor only
#   ./install.sh --opencode          — install OpenCode only
#   ./install.sh --mcp               — also install MCP server
#   ./install.sh --check             — pre-flight report only, no changes
#   ./install.sh --dry-run           — show what would be done, no changes
#   ./install.sh --force             — bypass conflict-abort (still no overwrite)
#   ./install.sh --uninstall [flags] — remove what was installed
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$REPO_DIR/core"
CLAUDE_WRAPPER="$REPO_DIR/wrappers/claude"
CURSOR_WRAPPER="$REPO_DIR/wrappers/cursor"
MCP_WRAPPER="$REPO_DIR/wrappers/mcp"
OPENCODE_WRAPPER="$REPO_DIR/wrappers/opencode"

DRY_RUN=false
CHECK_ONLY=false
FORCE=false
UNINSTALL=false
EXPLICIT_CLAUDE=false
INSTALL_CLAUDE=false
INSTALL_MCP=false
INSTALL_CURSOR=false
INSTALL_OPENCODE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --check)     CHECK_ONLY=true ;;
    --force)     FORCE=true ;;
    --uninstall) UNINSTALL=true ;;
    --claude)    EXPLICIT_CLAUDE=true ;;
    --mcp)       INSTALL_MCP=true ;;
    --cursor)    INSTALL_CURSOR=true ;;
    --opencode)  INSTALL_OPENCODE=true ;;
    *) printf "Unknown option: %s\nUsage: install.sh [--check|--dry-run|--force|--uninstall|--claude|--cursor|--opencode|--mcp]\n" "$arg"; exit 1 ;;
  esac
done

if ! $INSTALL_CURSOR && ! $INSTALL_OPENCODE; then
  INSTALL_CLAUDE=true
fi
if $EXPLICIT_CLAUDE; then
  INSTALL_CLAUDE=true
fi

if ($INSTALL_CLAUDE || $CHECK_ONLY) && ! $UNINSTALL; then
  if ! command -v jq &>/dev/null; then
    printf "  ✗ jq is required for Claude install and --check (install: sudo apt install jq)\n" >&2
    exit 1
  fi
fi

# ── Logging ────────────────────────────────────────────────────────────────────

log()      { printf "  %s\n" "$*"; }
log_ok()   { printf "  ✓ %s\n" "$*"; }
log_dry()  { printf "  ~ %s\n" "$*"; }
log_warn() { printf "  ⚠ %s\n" "$*"; }
log_err()  { printf "  ✗ %s\n" "$*" >&2; }

# ── Pre-flight state ───────────────────────────────────────────────────────────
# Populated by preflight scans, consumed by reporting and gating.
CONFLICTS=()   # blocking: file present where a CortexHub symlink/file should go
ORPHANS=()    # warning: symlink in user dirs points to a missing repo target
DRIFTS=()     # warning: schema/snippet/hook version mismatch
ADDITIONS=()   # info: new symlinks/files that the install would create

record_conflict() { CONFLICTS+=("$1")
}
record_orphan()   { ORPHANS+=("$1"); }
record_drift()    { DRIFTS+=("$1"); }
record_addition() { ADDITIONS+=("$1"); }

# ── Symlink helper ─────────────────────────────────────────────────────────────
# In check or dry-run mode: only records state, does nothing.
# In install mode: refuses to overwrite a non-symlink (records conflict instead).

make_symlink() {
  local target="$1"
  local link="$2"

  # Already correct
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    $CHECK_ONLY || $DRY_RUN || log_ok "$link (already correct)"
    return 0
  fi

  # Existing non-symlink → conflict
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    record_conflict "$link|file present (not a symlink)|mv \"$link\" \"$link.bak\""
    return 0
  fi

  # Existing symlink pointing elsewhere → conflict (don't silently redirect)
  if [ -L "$link" ] && [ "$(readlink "$link")" != "$target" ]; then
    local cur
    cur="$(readlink "$link")"
    record_conflict "$link|symlink points elsewhere ($cur)|rm \"$link\"  # if you don't need the current target"
    return 0
  fi

  # Doesn't exist — addition
  record_addition "$link → $target"
  if $CHECK_ONLY || $DRY_RUN; then
    return 0
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

# ── Drift detection ────────────────────────────────────────────────────────────

# Compare _schema_version between user JSON and template JSON.
# Pre-v1 = key absent. Drift if user version < template version (or absent).
check_schema_version() {
  local user_file="$1"
  local template_file="$2"
  local key="${3:-_schema_version}"

  [ -f "$user_file" ] || return 0     # not yet installed → no drift
  [ -f "$template_file" ] || return 0

  command -v jq >/dev/null || return 0  # silent skip if no jq

  local user_v template_v
  user_v=$(jq -r --arg k "$key" '.[$k] // 0' "$user_file" 2>/dev/null || echo "0")
  template_v=$(jq -r --arg k "$key" '.[$k] // 0' "$template_file" 2>/dev/null || echo "0")

  if [ "$user_v" != "$template_v" ]; then
    record_drift "$user_file|schema v$user_v → template v$template_v|diff \"$user_file\" \"$template_file\"  # then merge manually; see MIGRATIONS.md"
  fi
}

# Compare snippet version marker between user CLAUDE.md and snippet source.
check_snippet_version() {
  local user_file="$1"
  local snippet_file="$2"

  [ -f "$user_file" ] || return 0
  [ -f "$snippet_file" ] || return 0

  local template_v user_v
  template_v=$(grep -oE 'cortexhub:snippet:start v=[0-9]+' "$snippet_file" | head -1 | grep -oE '[0-9]+$' || echo "")
  user_v=$(grep -oE 'cortexhub:snippet:start v=[0-9]+' "$user_file" | head -1 | grep -oE '[0-9]+$' || echo "")

  if [ -z "$template_v" ]; then
    return 0  # no version in template — nothing to compare
  fi

  if [ -z "$user_v" ]; then
    # Snippet not yet versioned in user file (legacy install or no install)
    if grep -qF "## CortexHub" "$user_file" 2>/dev/null; then
      record_drift "$user_file|snippet present but unversioned (legacy)|remove the legacy block, then re-run install to inject v$template_v"
    fi
    return 0
  fi

  if [ "$user_v" != "$template_v" ]; then
    record_drift "$user_file|snippet v$user_v → template v$template_v|edit $user_file: replace block between cortexhub:snippet markers with $snippet_file"
  fi
}

# Compare hook version between user settings.json and template hook.
check_hook_version() {
  local user_file="$1"
  local template_file="$2"

  [ -f "$user_file" ] || return 0
  [ -f "$template_file" ] || return 0
  command -v jq >/dev/null || return 0

  local template_v user_v
  template_v=$(jq -r '._cortexhub_hooks_version // 0' "$template_file" 2>/dev/null || echo "0")
  user_v=$(jq -r '._cortexhub_hooks_version // 0' "$user_file" 2>/dev/null || echo "0")

  if [ "$template_v" != "0" ] && [ "$user_v" != "$template_v" ]; then
    record_drift "$user_file|hooks v$user_v → template v$template_v|review hooks tagged with _cortexhub in $user_file; merge from $template_file"
  fi
}

# ── Orphan scan ────────────────────────────────────────────────────────────────
# Walk known wrapper destinations and report symlinks that point inside $REPO_DIR
# but whose target no longer exists.

scan_orphans_in() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local link target
  while IFS= read -r -d '' link; do
    if [ -L "$link" ]; then
      target="$(readlink "$link")"
      case "$target" in
        "$REPO_DIR"/*)
          if [ ! -e "$target" ]; then
            record_orphan "$link|target gone: $target|rm \"$link\""
          fi
          ;;
      esac
    fi
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
}

scan_all_orphans() {
  scan_orphans_in "$HOME/.claude/skills"
  scan_orphans_in "$HOME/.claude/commands"
  scan_orphans_in "$HOME/.claude/agents"
  scan_orphans_in "$HOME/.cursor/commands"
  scan_orphans_in "$HOME/.cursor/rules"
  # Single-link locations
  for link in "$HOME/.ai-core" "$HOME/.local/bin/oc" "$HOME/.claude/MEMORY-BANK-GUIDE.md" "$HOME/.claude/vault-sync-config-schema.json"; do
    if [ -L "$link" ]; then
      local t; t="$(readlink "$link")"
      case "$t" in
        "$REPO_DIR"/*)
          [ -e "$t" ] || record_orphan "$link|target gone: $t|rm \"$link\""
          ;;
      esac
    fi
  done
}

# ── Snippet/hook injection state ───────────────────────────────────────────────

snippet_present_in_claude_md() {
  local f="$1"
  [ -f "$f" ] || return 1
  grep -qE 'cortexhub:snippet:start v=' "$f" 2>/dev/null
}

# ── Pre-flight: simulate the planned install to populate state ────────────────

preflight_claude() {
  local target="$CORE_DIR" link="$HOME/.ai-core"
  make_symlink "$target" "$link" >/dev/null

  for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
    make_symlink "$CORE_DIR/skills/$skill" "$HOME/.claude/skills/$skill" >/dev/null
  done

  for cmd in "$CLAUDE_WRAPPER/commands/"*.md; do
    [ -f "$cmd" ] || continue
    make_symlink "$cmd" "$HOME/.claude/commands/$(basename "$cmd")" >/dev/null
  done

  for agent in "$CLAUDE_WRAPPER/agents/"*.md; do
    [ -f "$agent" ] || continue
    make_symlink "$agent" "$HOME/.claude/agents/$(basename "$agent")" >/dev/null
  done

  make_symlink "$CORE_DIR/docs/MEMORY-BANK-GUIDE.md" "$HOME/.claude/MEMORY-BANK-GUIDE.md" >/dev/null
  make_symlink "$CORE_DIR/config/vault-sync-config-schema.json" "$HOME/.claude/vault-sync-config-schema.json" >/dev/null

  # Snippet drift
  check_snippet_version "$HOME/.claude/CLAUDE.md" "$CLAUDE_WRAPPER/CLAUDE.md.snippet"

  # Hook drift
  check_hook_version "$HOME/.claude/settings.json" "$CLAUDE_WRAPPER/settings.hook.json"
}

preflight_cursor() {
  for cmd in "$CURSOR_WRAPPER/commands/"*.md; do
    [ -f "$cmd" ] || continue
    make_symlink "$cmd" "$HOME/.cursor/commands/$(basename "$cmd")" >/dev/null
  done
  for rule in "$CURSOR_WRAPPER/rules/"*.mdc; do
    [ -f "$rule" ] || continue
    make_symlink "$rule" "$HOME/.cursor/rules/$(basename "$rule")" >/dev/null
  done
}

preflight_opencode() {
  local cfg="$HOME/.config/opencode/opencode.json"
  if [ -e "$cfg" ] && [ ! -L "$cfg" ]; then
    if ! grep -q '"cortexhub"' "$cfg" 2>/dev/null; then
      record_conflict "$cfg|user-managed config present|review and mv to $cfg.bak; reference: $OPENCODE_WRAPPER/opencode.json"
    fi
  fi
  check_schema_version "$cfg" "$OPENCODE_WRAPPER/opencode.json" "_cortexhub_schema_version"
  make_symlink "$OPENCODE_WRAPPER/opencode-start.sh" "$HOME/.local/bin/oc" >/dev/null
}

preflight_configs() {
  check_schema_version "$CORE_DIR/config/providers.json" "$CORE_DIR/config/providers.json.example"
  check_schema_version "$CORE_DIR/config/agent-routing.json" "$CORE_DIR/config/agent-routing.json.example"
}

run_preflight() {
  $INSTALL_CLAUDE && preflight_claude
  $INSTALL_CURSOR && preflight_cursor
  $INSTALL_OPENCODE && preflight_opencode
  preflight_configs
  scan_all_orphans
}

# ── Reporting ──────────────────────────────────────────────────────────────────

print_report() {
  local n_conflicts=${#CONFLICTS[@]}
  local n_orphans=${#ORPHANS[@]}
  local n_drifts=${#DRIFTS[@]}
  local n_additions=${#ADDITIONS[@]}

  printf "\n=== CortexHub pre-flight report ===\n\n"

  if [ "$n_additions" -gt 0 ]; then
    printf "Additions (%d) — safe, will be applied on install:\n" "$n_additions"
    for a in "${ADDITIONS[@]}"; do
      printf "  + %s\n" "$a"
    done
    printf "\n"
  fi

  if [ "$n_orphans" -gt 0 ]; then
    printf "Orphan symlinks (%d) — wrapper removed/renamed in repo:\n" "$n_orphans"
    for o in "${ORPHANS[@]}"; do
      local path reason action
      IFS='|' read -r path reason action <<<"$o"
      printf "  ⚠ %s\n      reason: %s\n      action: %s\n" "$path" "$reason" "$action"
    done
    printf "\n"
  fi

  if [ "$n_drifts" -gt 0 ]; then
    printf "Drift (%d) — user file out of sync with template:\n" "$n_drifts"
    for d in "${DRIFTS[@]}"; do
      local path reason action
      IFS='|' read -r path reason action <<<"$d"
      printf "  ⚠ %s\n      reason: %s\n      action: %s\n" "$path" "$reason" "$action"
    done
    printf "\n"
  fi

  if [ "$n_conflicts" -gt 0 ]; then
    printf "Conflicts (%d) — block install:\n" "$n_conflicts"
    for c in "${CONFLICTS[@]}"; do
      local path reason action
      IFS='|' read -r path reason action <<<"$c"
      printf "  ✗ %s\n      reason: %s\n      action: %s\n" "$path" "$reason" "$action"
    done
    printf "\n"
  fi

  if [ "$n_conflicts" -eq 0 ] && [ "$n_orphans" -eq 0 ] && [ "$n_drifts" -eq 0 ] && [ "$n_additions" -eq 0 ]; then
    printf "Nothing to do — install is up to date.\n\n"
  fi

  printf "Summary: %d additions, %d orphans, %d drifts, %d conflicts.\n\n" \
    "$n_additions" "$n_orphans" "$n_drifts" "$n_conflicts"
}

# ── Uninstall ──────────────────────────────────────────────────────────────────

if $UNINSTALL; then
  printf "\n=== CortexHub uninstall ===\n\n"

  printf "Removing ~/.ai-core\n"
  remove_symlink "$HOME/.ai-core"

  if $INSTALL_CLAUDE; then
    printf "\nRemoving ~/.claude/skills wrappers\n"
    for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
      remove_symlink "$HOME/.claude/skills/$skill"
    done

    printf "\nRemoving ~/.claude/commands wrappers\n"
    for cmd in "$CLAUDE_WRAPPER/commands/"*.md; do
      [ -f "$cmd" ] || continue
      name="$(basename "$cmd")"
      remove_symlink "$HOME/.claude/commands/$name"
    done

    printf "\nRemoving ~/.claude/agents wrappers\n"
    for agent in "$CLAUDE_WRAPPER/agents/"*.md; do
      [ -f "$agent" ] || continue
      name="$(basename "$agent")"
      remove_symlink "$HOME/.claude/agents/$name"
    done

    printf "\nRemoving ~/.claude config files\n"
    remove_symlink "$HOME/.claude/MEMORY-BANK-GUIDE.md"
    remove_symlink "$HOME/.claude/vault-sync-config-schema.json"

    printf "\nNote: ~/.claude/CLAUDE.md and ~/.claude/settings.json are NOT modified.\n"
    printf "Remove the cortexhub:snippet block and _cortexhub-tagged hooks manually if desired.\n"
  fi

  if $INSTALL_CURSOR; then
    printf "\nRemoving ~/.cursor/commands wrappers\n"
    for cmd in "$CURSOR_WRAPPER/commands/"*.md; do
      [ -f "$cmd" ] || continue
      name="$(basename "$cmd")"
      remove_symlink "$HOME/.cursor/commands/$name"
    done
  fi

  if $INSTALL_OPENCODE; then
    printf "\nRemoving ~/.local/bin/oc symlink\n"
    remove_symlink "$HOME/.local/bin/oc"
    printf "\nNote: ~/.config/opencode/opencode.json is NOT modified — remove manually if desired.\n"
  fi

  printf "\nDone.\n"
  exit 0
fi

# ── Pre-flight ─────────────────────────────────────────────────────────────────

if ! $CHECK_ONLY && ! $DRY_RUN; then
  mkdir -p "$HOME/.claude"
  $INSTALL_CURSOR && mkdir -p "$HOME/.cursor/commands" "$HOME/.cursor/rules"
  $INSTALL_CLAUDE && mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands" "$HOME/.claude/agents"
fi

run_preflight

if $CHECK_ONLY; then
  print_report
  if [ ${#CONFLICTS[@]} -gt 0 ] || [ ${#DRIFTS[@]} -gt 0 ]; then exit 1; fi
  exit 0
fi

if [ ${#CONFLICTS[@]} -gt 0 ] && ! $FORCE; then
  print_report
  printf "Install aborted: resolve the %d conflict(s) above, then re-run.\n" "${#CONFLICTS[@]}"
  printf "Or pass --force to proceed (skips conflicts, never overwrites).\n\n"
  exit 1
fi

if [ ${#ORPHANS[@]} -gt 0 ] || [ ${#DRIFTS[@]} -gt 0 ]; then
  print_report
  printf "Continuing install (orphans and drifts are warnings only).\n\n"
fi

# ── Install ────────────────────────────────────────────────────────────────────
# Reset state arrays so the install pass logs cleanly without re-recording.
CONFLICTS=()
ORPHANS=()
DRIFTS=()
ADDITIONS=()

printf "\n=== CortexHub install%s ===\n\n" "$(if $DRY_RUN; then printf " (dry-run)"; fi)"

printf "1. Core — ~/.ai-core → %s/core\n" "$REPO_DIR"
make_symlink "$CORE_DIR" "$HOME/.ai-core"

if $INSTALL_CLAUDE; then
  printf "\n2. Claude skills wrappers\n"
  for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
    make_symlink "$CORE_DIR/skills/$skill" "$HOME/.claude/skills/$skill"
  done

  printf "\n3. Claude commands wrappers\n"
  for cmd in "$CLAUDE_WRAPPER/commands/"*.md; do
    [ -f "$cmd" ] || continue
    make_symlink "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
  done

  printf "\n4. Claude agents wrappers\n"
  for agent in "$CLAUDE_WRAPPER/agents/"*.md; do
    [ -f "$agent" ] || continue
    make_symlink "$agent" "$HOME/.claude/agents/$(basename "$agent")"
  done

  printf "\n5. Claude config files\n"
  make_symlink "$CORE_DIR/docs/MEMORY-BANK-GUIDE.md" "$HOME/.claude/MEMORY-BANK-GUIDE.md"
  make_symlink "$CORE_DIR/config/vault-sync-config-schema.json" "$HOME/.claude/vault-sync-config-schema.json"

  printf "\n6. CLAUDE.md snippet (versioned, idempotent)\n"
  SNIPPET="$CLAUDE_WRAPPER/CLAUDE.md.snippet"
  CLAUDE_MD="$HOME/.claude/CLAUDE.md"
  if $DRY_RUN; then
    log_dry "inject snippet into $CLAUDE_MD (if not already present at current version)"
  elif snippet_present_in_claude_md "$CLAUDE_MD"; then
    log_ok "snippet already present in $CLAUDE_MD (drift checked separately)"
  else
    [ -f "$CLAUDE_MD" ] || touch "$CLAUDE_MD"
    printf "\n" >> "$CLAUDE_MD"
    cat "$SNIPPET" >> "$CLAUDE_MD"
    log_ok "snippet injected into $CLAUDE_MD"
  fi

  printf "\n7. Claude hooks (merge into settings.json, never overwrite)\n"
  HOOK_SRC="$CLAUDE_WRAPPER/settings.hook.json"
  SETTINGS_DEST="$HOME/.claude/settings.json"
  if $DRY_RUN; then
    log_dry "merge hooks into $SETTINGS_DEST"
  elif ! command -v jq &>/dev/null; then
    log_err "jq not found — install jq to enable hook injection (skipped)"
  elif [ -f "$SETTINGS_DEST" ] && jq -e '._cortexhub_hooks_version' "$SETTINGS_DEST" >/dev/null 2>&1; then
    log_ok "hooks already present in $SETTINGS_DEST (drift checked separately)"
  else
    if [ -f "$SETTINGS_DEST" ]; then
      tmp=$(mktemp)
      jq -s '.[0] * .[1]' "$SETTINGS_DEST" "$HOOK_SRC" > "$tmp" && mv "$tmp" "$SETTINGS_DEST"
    else
      cp "$HOOK_SRC" "$SETTINGS_DEST"
    fi
    log_ok "hooks injected into $SETTINGS_DEST"
  fi
fi

printf "\n8. providers.json\n"
PROVIDERS_EXAMPLE="$CORE_DIR/config/providers.json.example"
PROVIDERS_DEST="$CORE_DIR/config/providers.json"
if $DRY_RUN; then
  log_dry "copy providers.json.example → providers.json (if not exists)"
elif [ -f "$PROVIDERS_DEST" ]; then
  log_ok "providers.json already exists — skipping (drift checked separately)"
else
  cp "$PROVIDERS_EXAMPLE" "$PROVIDERS_DEST"
  log_ok "providers.json created from example"
  log "Edit ~/.ai-core/config/providers.json to configure your models"
fi

printf "\n8b. agent-routing.json\n"
ROUTING_EXAMPLE="$CORE_DIR/config/agent-routing.json.example"
ROUTING_DEST="$CORE_DIR/config/agent-routing.json"
if $DRY_RUN; then
  log_dry "copy agent-routing.json.example → agent-routing.json (if not exists)"
elif [ -f "$ROUTING_DEST" ]; then
  log_ok "agent-routing.json already exists — skipping (drift checked separately)"
else
  cp "$ROUTING_EXAMPLE" "$ROUTING_DEST"
  log_ok "agent-routing.json created from example"
fi

if $INSTALL_CURSOR; then
  printf "\n9. Cursor commands (~/.cursor/commands/)\n"
  for cmd in "$CURSOR_WRAPPER/commands/"*.md; do
    [ -f "$cmd" ] || continue
    make_symlink "$cmd" "$HOME/.cursor/commands/$(basename "$cmd")"
  done

  printf "\n   Cursor rules (~/.cursor/rules/)\n"
  for rule in "$CURSOR_WRAPPER/rules/"*.mdc; do
    [ -f "$rule" ] || continue
    make_symlink "$rule" "$HOME/.cursor/rules/$(basename "$rule")"
  done
fi

if $INSTALL_OPENCODE; then
  printf "\n10. OpenCode + Ollama gateway\n"
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
      log_ok "$OPENCODE_CONFIG_DEST already exists — skipping (drift checked separately)"
    else
      cp "$OPENCODE_WRAPPER/opencode.json" "$OPENCODE_CONFIG_DEST"
      log_ok "opencode.json installed at $OPENCODE_CONFIG_DEST"
    fi
    mkdir -p "$HOME/.local/bin"
    make_symlink "$OPENCODE_WRAPPER/opencode-start.sh" "$HOME/.local/bin/oc"
    if [ ! -f "$HOME/.ai-core/mcp/server.js" ]; then
      printf "\n"
      log_err "MCP server not installed — session tools won't be available in OpenCode"
      log     "Run: ./install.sh --mcp"
    fi
  fi
fi

if $INSTALL_MCP; then
  printf "\n11. MCP server\n"
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
