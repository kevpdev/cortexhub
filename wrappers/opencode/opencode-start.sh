#!/usr/bin/env bash
# opencode-start.sh — launch OpenCode with the right Ollama model for the task.
#
# Usage:
#   opencode-start.sh                          # default profile (code)
#   opencode-start.sh "review my auth PR"      # gateway classifies → routes to right model
#
# The gateway writes a temporary project-level opencode.json override for the
# session, then cleans it up on exit. It will NOT overwrite an existing
# opencode.json that you manage yourself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK="${1:-}"
OVERRIDE_CONFIG="$(pwd)/opencode.json"
GATEWAY_CREATED_CONFIG=false

if ! command -v opencode &>/dev/null; then
  printf "[cortexhub] opencode not found — install it first:\n"
  printf "  npm install -g opencode-ai\n"
  exit 1
fi

if ! command -v node &>/dev/null; then
  printf "[cortexhub] node not found — install Node.js 24+\n"
  exit 1
fi

# Ensure MCP server is ready — OpenCode spawns it on demand via opencode.json.
MCP_SERVER="$HOME/.ai-core/mcp/server.js"
MCP_DIR="$HOME/.ai-core/mcp"

if [ ! -f "$MCP_SERVER" ]; then
  printf "[cortexhub] Warning: MCP server not found — session_start, capture and skills won't work\n" >&2
  printf "  Fix: cd <cortexhub-repo> && ./install.sh --mcp\n" >&2
elif [ ! -d "$MCP_DIR/node_modules" ]; then
  if command -v pnpm &>/dev/null; then
    printf "[cortexhub] MCP dependencies missing — installing...\n" >&2
    (cd "$MCP_DIR" && pnpm install --silent) \
      && printf "[cortexhub] MCP ready\n" >&2 \
      || printf "[cortexhub] pnpm install failed — MCP tools may not work\n" >&2
  else
    printf "[cortexhub] MCP dependencies missing and pnpm not found\n" >&2
    printf "  Fix: corepack enable && cd <cortexhub-repo> && ./install.sh --mcp\n" >&2
  fi
fi

cleanup() {
  if $GATEWAY_CREATED_CONFIG && [ -f "$OVERRIDE_CONFIG" ]; then
    rm -f "$OVERRIDE_CONFIG"
  fi
}
trap cleanup EXIT

if [ -n "$TASK" ]; then
  RESULT=$(node "$SCRIPT_DIR/gateway.js" "$TASK" 2>/dev/null) || RESULT=""

  if [ -n "$RESULT" ]; then
    OPENCODE_MODEL=$(node -e "
      try {
        const r = JSON.parse(process.argv[1]);
        process.stdout.write(r.opencode_model || '');
      } catch(e) {}
    " "$RESULT")

    if [ -n "$OPENCODE_MODEL" ] && [ ! -f "$OVERRIDE_CONFIG" ]; then
      printf '{ "model": "%s" }\n' "$OPENCODE_MODEL" > "$OVERRIDE_CONFIG"
      GATEWAY_CREATED_CONFIG=true
      printf "[cortexhub] routing to %s\n" "$OPENCODE_MODEL" >&2
    fi
  fi
fi

exec opencode
