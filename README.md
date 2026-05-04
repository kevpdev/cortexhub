# CortexHub

Agent-agnostic AI config core. Skills, scripts, and workflows live in `core/` — each AI tool connects via a thin wrapper that calls the same scripts.

## Architecture

```
core/                          ← source of truth, zero vendor dependencies
  scripts/                     ← shell scripts (the public API)
  skills/                      ← portable AI skills (code-reviewer, …)
  templates/memory-bank/       ← projectbrief, techContext, activeContext
  docs/                        ← MEMORY-BANK-GUIDE.md, SCRIPTS-CONTRACT.md

wrappers/
  claude/    commands/*.md     ← Claude Code slash commands → call scripts
             agents/*.md       ← Claude sub-agents (doc-writer, websearch, …)
  cursor/    commands/*.md     ← Cursor slash commands     → call scripts
  opencode/  gateway.js        ← Ollama model router
  mcp/       server.js         ← MCP server for shell-less environments

WORKFLOWS.md                   ← universal workflow contract
install.sh                     ← sets up symlinks on a new machine
```

**Core principle:** Scripts are the public API. Wrappers translate tool-native UX into script calls.

---

## Quick Setup

### Prerequisites

| Tool | Check | Install (Linux) |
|---|---|---|
| `git` | `git --version` | `sudo apt install git` |
| `jq` | `jq --version` | `sudo apt install jq` |
| Claude Code | `claude --version` | [claude.ai/download](https://claude.ai/download) |

### Install

```bash
git clone git@github.com:kevpdev/cortexhub.git ~/path/to/cortexhub
cd ~/path/to/cortexhub

./install.sh --dry-run   # preview what will be done
./install.sh             # core + Claude Code (default)
```

### What the default install sets up

- `~/.ai-core/` → symlink to `core/` (scripts, skills, templates)
- `~/.claude/skills/` → 5 core skills (code-reviewer, security-reviewer, …)
- `~/.claude/commands/` → 14 slash commands (/session-start, /plan, /epct, …)
- `~/.claude/agents/` → 4 sub-agents (doc-writer, explore-codebase, …)
- `~/.claude/CLAUDE.md` → Memory-Bank snippet injected
- `~/.claude/settings.json` → 3 hooks (SessionStart, UserPromptSubmit, PreToolUse)

### Verify

```bash
/doctor   # inside Claude Code — validates all 33 checks
```

### install.sh flags

| Command | Result |
|---|---|
| `./install.sh` | core + Claude Code |
| `./install.sh --cursor` | core + Cursor |
| `./install.sh --cursor --claude` | core + Cursor + Claude Code |
| `./install.sh --opencode` | core + OpenCode/Ollama |
| `./install.sh --opencode --claude` | core + OpenCode + Claude Code |
| `./install.sh --mcp` | adds MCP server (any combination) |
| `./install.sh --dry-run` | preview without changes |
| `./install.sh --uninstall [flags]` | remove installed symlinks |

> `--mcp` requires Node 24+ and pnpm (`corepack enable`).

---

## Workflows (V1)

| Workflow | Claude Code | Cursor | OpenCode |
|---|---|---|---|
| `/session-start [goal]` | ✅ | ✅ | ✅ |
| `/session-end` | ✅ | ✅ | ✅ |
| `/capture <note>` | ✅ | ✅ | ✅ |
| `/memory-bank-init` | ✅ | ✅ | ✅ |
| `/memory-bank-setup` | ✅ | ✅ | ✅ |
| `/plan <description>` | ✅ | ✅ | ✅ |
| `/epct` | ✅ | ✅ | ✅ |
| `/create-pull-request` | ✅ | ✅ | ✅ |

See [`WORKFLOWS.md`](WORKFLOWS.md) for the full contract.

---

## Skills (core)

| Skill | Role |
|---|---|
| `code-reviewer` | Code quality, SOLID, naming, performance |
| `security-reviewer` | OWASP, auth, secrets, injections |
| `backend-architect` | API design, architecture patterns |
| `frontend-expert` | SSR/CSR, a11y, state management |
| `database-expert` | Schema, indexing, migrations |

Skills are auto-suggested via the `UserPromptSubmit` hook — see [Agent routing](#agent-routing) for the deterministic rule engine.

---

## Agent routing

CortexHub ships with a deterministic routing engine that triggers agents/skills based on user prompts, replacing Claude's probabilistic delegation choice.

- Rules live in `~/.ai-core/config/agent-routing.json` (created from `.example` at install)
- Hook `UserPromptSubmit` evaluates rules in order; first match wins
- `force: true` → impératif message; `force: false` → suggestion
- Multi-provider: runs **before** Claude, works with Claude CLI + Ollama, Cursor, OpenCode

Full doc: [`core/docs/AGENT-ROUTING.md`](core/docs/AGENT-ROUTING.md).

---

## Compatibility

| Platform | Status |
|---|---|
| Linux | ✅ |
| macOS | ✅ (Bash 4+ via Homebrew) |
| WSL2 | ✅ |
| Windows native | Out of scope |

---

## References

- [`WORKFLOWS.md`](WORKFLOWS.md) — workflow contract, agent × workflow matrix
- [`core/docs/SCRIPTS-CONTRACT.md`](core/docs/SCRIPTS-CONTRACT.md) — scripts args, exit codes, output format
- [`docs/MCP-VS-SCRIPTS.md`](docs/MCP-VS-SCRIPTS.md) — when to use MCP vs direct scripts
- [`wrappers/mcp/capabilities.md`](wrappers/mcp/capabilities.md) — MCP server capabilities
