#!/usr/bin/env bash
# suggest-skill.sh — UserPromptSubmit hook for Claude Code
# Reads the user prompt from stdin (JSON payload) and routes to an agent or skill
# based on rules defined in core/config/agent-routing.json.
#
# Behavior:
#   - First matching rule wins (order matters in the JSON).
#   - target.type=agent  → message asks Claude to delegate via the Task tool.
#   - target.type=skill  → message asks Claude to load `/skill <name>`.
#   - force=true         → impératif ("tu DOIS déléguer").
#   - force=false        → suggestion ("expertise disponible").
#   - No match           → silent exit 0, no injection.
#
# Falls back to legacy hardcoded regex if agent-routing.json is missing.
# Requires: jq, python3.
set -euo pipefail

CORE_DIR="${AI_CORE_DIR:-$HOME/.ai-core}"
ROUTING="$CORE_DIR/config/agent-routing.json"
ROUTING_EXAMPLE="$CORE_DIR/config/agent-routing.json.example"

# ── Read prompt from stdin ────────────────────────────────────────────────────

prompt=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', ''))
except Exception:
    print('')
" 2>/dev/null || printf "")

if [ -z "$prompt" ]; then
  exit 0
fi

lower=$(printf "%s" "$prompt" | tr '[:upper:]' '[:lower:]')

# ── Output helper ─────────────────────────────────────────────────────────────

emit() {
  # $1 = additionalContext message
  python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'UserPromptSubmit',
        'additionalContext': sys.argv[1]
    }
}))
" "$1"
}

format_message() {
  # $1=type (agent|skill) $2=name $3=force(true|false) $4=reason
  local type="$1" name="$2" force="$3" reason="$4"
  local prefix verb
  if [ "$force" = "true" ]; then
    prefix="🔧 Délégation requise"
    if [ "$type" = "agent" ]; then
      verb="Tu DOIS lancer le sous-agent \`$name\` (Task tool) pour cette tâche."
    else
      verb="Tu DOIS charger le skill \`$name\` avec \`/skill $name\` avant d'agir."
    fi
  else
    prefix="💡 Expertise recommandée"
    if [ "$type" = "agent" ]; then
      verb="Sous-agent \`$name\` disponible (Task tool) — recommandé pour cette tâche."
    else
      verb="Skill \`$name\` disponible — charge-le avec \`/skill $name\`."
    fi
  fi
  printf "%s : %s\n   Raison : %s" "$prefix" "$verb" "$reason"
}

# ── Path 1: rules-based routing ───────────────────────────────────────────────

if [ -f "$ROUTING" ] && command -v jq >/dev/null 2>&1; then
  # Iterate rules; on first match, emit and exit.
  count=$(jq '.rules | length' "$ROUTING" 2>/dev/null || printf "0")
  i=0
  while [ "$i" -lt "$count" ]; do
    rule=$(jq -c ".rules[$i]" "$ROUTING")
    regex=$(printf "%s" "$rule" | jq -r '.match.regex // empty')
    if [ -n "$regex" ] && printf "%s" "$lower" | grep -qE "$regex"; then
      type=$(printf "%s" "$rule" | jq -r '.target.type')
      name=$(printf "%s" "$rule" | jq -r '.target.name')
      force=$(printf "%s" "$rule" | jq -r '.force // false')
      reason=$(printf "%s" "$rule" | jq -r '.reason')
      msg=$(format_message "$type" "$name" "$force" "$reason")
      emit "$msg"
      exit 0
    fi
    i=$((i + 1))
  done
  exit 0
fi

# ── Path 2: legacy fallback (no jq, or routing file missing) ──────────────────

if printf "%s" "$lower" | grep -qE "review|qualit|lisibilit|solid|mainten|refactor|propre|clean code"; then
  skill="code-reviewer"
elif printf "%s" "$lower" | grep -qE "s[eé]curit|auth|secret|inject|owasp|vuln|token|jwt|permiss|xss|csrf"; then
  skill="security-reviewer"
elif printf "%s" "$lower" | grep -qE "architect|api|rest|graphql|microserv|monolith|backend|design pattern|ddd|cqrs|hexagonal"; then
  skill="backend-architect"
elif printf "%s" "$lower" | grep -qE "frontend|react|vue|angular|next|nuxt|ssr|csr|a11y|accessib|composant|component|web vital"; then
  skill="frontend-expert"
elif printf "%s" "$lower" | grep -qE "database|sql|nosql|schema|index|migration|query|postgres|mongo|redis|explain|lent|slow"; then
  skill="database-expert"
elif printf "%s" "$lower" | grep -qE "documente|javadoc|jsdoc|readme|openapi|swagger|commente|doc technique|mise.?à.?jour.*doc"; then
  skill="doc-writer"
else
  exit 0
fi

emit "💡 Skill disponible : \`$skill\` — charge-le avec \`/skill $skill\` pour une expertise spécialisée sur cette tâche."
