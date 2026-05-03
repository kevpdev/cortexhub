#!/usr/bin/env bash
# doctor.sh — validate CortexHub install for Claude Code
set -euo pipefail

CORE="$HOME/.ai-core"
CLAUDE="$HOME/.claude"

ok=0
fail=0

pass() { printf "  ✓ %s\n" "$*"; ((ok++)) || true; }
fail() { printf "  ✗ %s\n" "$*" >&2; ((fail++)) || true; }

check_symlink() {
  local link="$1" label="$2"
  if [ -L "$link" ] && [ -e "$link" ]; then
    pass "$label"
  elif [ -L "$link" ]; then
    fail "$label (broken symlink → $(readlink "$link"))"
  else
    fail "$label (missing)"
  fi
}

# ── Core ──────────────────────────────────────────────────────────────────────

printf "\nCore\n"
check_symlink "$CORE" "~/.ai-core"

# ── Skills ────────────────────────────────────────────────────────────────────

printf "\nSkills\n"
for skill in backend-architect code-reviewer database-expert frontend-expert security-reviewer; do
  check_symlink "$CLAUDE/skills/$skill" "$skill"
done

# ── Commands ──────────────────────────────────────────────────────────────────

printf "\nCommands\n"
for cmd in capture create-pull-request doctor epct fix-pr-comments memory-bank-init \
           memory-bank-setup plan plan-to-stories run-tasks session-end \
           session-start story-create vault-sync-from-dev watch-ci; do
  check_symlink "$CLAUDE/commands/$cmd.md" "/$cmd"
done

# ── Agents ────────────────────────────────────────────────────────────────────

printf "\nAgents\n"
for agent in doc-writer explore-codebase explore-docs vault-sync websearch; do
  check_symlink "$CLAUDE/agents/$agent.md" "$agent"
done

# ── Docs & config ─────────────────────────────────────────────────────────────

printf "\nDocs & config\n"
check_symlink "$CLAUDE/MEMORY-BANK-GUIDE.md" "MEMORY-BANK-GUIDE.md"
check_symlink "$CLAUDE/vault-sync-config-schema.json" "vault-sync-config-schema.json"

# ── Hooks ─────────────────────────────────────────────────────────────────────

printf "\nHooks (settings.json)\n"
SETTINGS="$CLAUDE/settings.json"
if [ ! -f "$SETTINGS" ]; then
  fail "settings.json not found"
else
  for hook in SessionStart UserPromptSubmit PreToolUse; do
    if grep -qF "\"$hook\"" "$SETTINGS"; then
      pass "$hook"
    else
      fail "$hook (missing from settings.json)"
    fi
  done
fi

# ── CLAUDE.md snippet ─────────────────────────────────────────────────────────

printf "\nCLAUDE.md\n"
MARKER="## Session Auto-Load (Memory-Bank)"
if grep -qF "$MARKER" "$CLAUDE/CLAUDE.md" 2>/dev/null; then
  pass "Memory-Bank snippet present"
else
  fail "Memory-Bank snippet missing — re-run install.sh"
fi

# ── Tools ─────────────────────────────────────────────────────────────────────

printf "\nSystem tools\n"
for tool in git jq bash; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool"
  else
    fail "$tool (not found)"
  fi
done
for tool in node pnpm; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool (optional)"
  else
    printf "  ~ %s (optional — needed for --mcp)\n" "$tool"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────

printf "\n"
if [ "$fail" -eq 0 ]; then
  printf "All checks passed (%d/%d)\n" "$ok" "$((ok + fail))"
else
  printf "%d passed, %d failed\n" "$ok" "$fail"
  printf "Fix: re-run ./install.sh --claude from the cortexhub repo\n"
  exit 1
fi
