# CortexHub

Agent-agnostic AI config core. Skills, scripts, and templates live in `core/` — each AI agent connects via a thin wrapper.

## Architecture

```
core/                          ← source of truth, no vendor dependencies
  scripts/                     ← shell scripts (memory-bank, session, capture)
  skills/                      ← portable AI skills (code-reviewer, security-reviewer, …)
  templates/memory-bank/       ← projectbrief, techContext, activeContext
  docs/                        ← guides (MEMORY-BANK-GUIDE.md)

wrappers/
  claude/
    commands/                  ← Claude Code slash commands
    CLAUDE.md.snippet          ← snippet to inject into ~/.claude/CLAUDE.md

install.sh                     ← sets up symlinks on a new machine
```

**Principle:** `core/` runs without any AI agent. Wrappers only point to it — they never modify data.

## Install

```bash
git clone <repo> ~/path/to/cortexhub
cd ~/path/to/cortexhub
./install.sh --dry-run   # preview
./install.sh             # apply
```

### What install.sh does

| Action | Result |
|---|---|
| `~/.ai-core` → `core/` | Symlink — git pull auto-updates the core |
| `~/.claude/skills/<skill>` → `core/skills/<skill>` | 5 portable skills wired to Claude |
| `~/.claude/commands/<cmd>` → `wrappers/claude/commands/<cmd>` | Slash commands wired to Claude |
| `~/.claude/MEMORY-BANK-GUIDE.md` → `core/docs/` | Guide always up to date |
| `~/.claude/CLAUDE.md` | Session auto-load snippet injected (once) |

### Uninstall

```bash
./install.sh --uninstall
```

## Compatibility

| Platform | Status |
|---|---|
| Linux | Supported |
| macOS | Supported (requires Bash 4+ via Homebrew) |
| WSL2 | Supported |
| Windows native | Out of scope |

## Skills (core)

| Skill | Role |
|---|---|
| `code-reviewer` | Code quality, SOLID, naming, performance |
| `security-reviewer` | OWASP, auth, secrets, injections |
| `backend-architect` | API design, architecture patterns |
| `frontend-expert` | SSR/CSR, a11y, state management |
| `database-expert` | Schema, indexing, migrations |

## Wrappers

| Agent | Status |
|---|---|
| Claude Code | Implemented |
| Cursor | Planned (Phase 5) |
| Windsurf | Planned (Phase 5) |
| Ollama | Out of scope (Phase 6) |
