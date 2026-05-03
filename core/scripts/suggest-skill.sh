#!/usr/bin/env bash
# suggest-skill.sh — UserPromptSubmit hook for Claude Code
# Reads the user prompt from stdin (JSON payload), detects skill-relevant keywords,
# and injects a one-line suggestion. Silent when no keyword matches (no output, exit 0).
set -euo pipefail

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

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"💡 Skill disponible : `%s` — charge-le avec `/skill %s` pour une expertise spécialisée sur cette tâche."}}\n' \
  "$skill" "$skill"
