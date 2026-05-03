# CortexHub

Agent-agnostic AI config core. Skills, scripts, and workflows live in `core/` — each AI agent connects via a thin wrapper that calls the same scripts.

## Architecture

```
core/                          ← source of truth, zero vendor dependencies
  scripts/                     ← shell scripts (the public API)
  skills/                      ← portable AI skills (code-reviewer, …)
  templates/memory-bank/       ← projectbrief, techContext, activeContext
  docs/                        ← MEMORY-BANK-GUIDE.md, SCRIPTS-CONTRACT.md

wrappers/
  claude/    commands/*.md     ← Claude Code slash commands → call scripts
  cursor/    commands/*.md     ← Cursor slash commands     → call scripts
  continue/  config.ts         ← Continue.dev slash cmds   → call scripts
  mcp/       server.js         ← MCP server (route_completion + browser agents)

WORKFLOWS.md                   ← universal workflow contract (V1, 8 workflows)
install.sh                     ← sets up symlinks on a new machine
```

**Core principle:** Scripts are the public API. Wrappers translate agent-native UX into script calls. MCP is a specialized consumer for cases where shell is unavailable.

## Install

```bash
git clone git@github.com:kevpdev/cortexhub.git ~/path/to/cortexhub
cd ~/path/to/cortexhub
./install.sh --dry-run    # preview
./install.sh              # core + Claude Code
./install.sh --cursor     # + Cursor commands
./install.sh --continue   # + Continue.dev config
./install.sh --mcp        # + MCP server
```

### What install.sh does

| Flag | Action |
|---|---|
| *(none)* | Core + Claude Code (symlinks + CLAUDE.md snippet) |
| `--cursor` | Symlinks 8 commands to `~/.cursor/commands/` |
| `--continue` | Copies `config.ts` to `~/.continue/config.ts` |
| `--mcp` | npm install + symlink `~/.ai-core/mcp` + setup instructions |
| `--dry-run` | Preview without changes |
| `--uninstall` | Remove everything installed |

## Workflows (V1 — 8 universal)

All Tier 1 agents expose the same workflows. See [`WORKFLOWS.md`](WORKFLOWS.md) for the full contract.

| Workflow | Claude Code | Cursor | Continue.dev |
|---|---|---|---|
| `/session-start [goal]` | ✅ | ✅ | ✅ |
| `/session-end` | ✅ | ✅ | ✅ |
| `/capture <note>` | ✅ | ✅ | ✅ |
| `/memory-bank-init` | ✅ | ✅ | ✅ |
| `/memory-bank-setup [agent]` | ✅ | ✅ | ✅ |
| `/plan <description>` | ✅ | ✅ | ✅ |
| `/epct <description>` | ✅ | ✅ | ✅ |
| `/create-pull-request` | ✅ | ✅ | ✅ |

## Skills (core)

Portable across all agents via `get_skill` MCP tool or direct file load.

| Skill | Role |
|---|---|
| `code-reviewer` | Code quality, SOLID, naming, performance |
| `security-reviewer` | OWASP, auth, secrets, injections |
| `backend-architect` | API design, architecture patterns |
| `frontend-expert` | SSR/CSR, a11y, state management |
| `database-expert` | Schema, indexing, migrations |

## Compatibility

| Platform | Status |
|---|---|
| Linux | ✅ |
| macOS | ✅ (Bash 4+ via Homebrew) |
| WSL2 | ✅ |
| Windows native | Out of scope |

## References

- [`WORKFLOWS.md`](WORKFLOWS.md) — workflow contract, agent × workflow matrix
- [`core/docs/SCRIPTS-CONTRACT.md`](core/docs/SCRIPTS-CONTRACT.md) — scripts args, exit codes, output format
- [`docs/MCP-VS-SCRIPTS.md`](docs/MCP-VS-SCRIPTS.md) — when to use MCP vs direct scripts
- [`wrappers/mcp/capabilities.md`](wrappers/mcp/capabilities.md) — MCP server capabilities by agent
