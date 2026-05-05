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

## Installation

### Prerequisites

| Tool | Check | Install (Linux) |
|---|---|---|
| `git` | `git --version` | `sudo apt install git` |
| `jq` | `jq --version` | `sudo apt install jq` |
| `bash` 4+ | `bash --version` | (pre-installed on most systems) |
| Claude Code | `claude --version` | [claude.ai/download](https://claude.ai/download) |

### Install on a fresh machine

**Philosophy**: The installer follows **"add only, never modify, never delete"**. It never overwrites your existing configs, never deletes anything, and never merges conflicting files. You stay in control.

**1. Clone the repo**

```bash
git clone git@github.com:kevpdev/cortexhub.git ~/path/to/cortexhub
cd ~/path/to/cortexhub
```

**2. Check for conflicts (optional but recommended)**

```bash
./install.sh --dry-run
```

This shows what will be installed without making any changes.

**3. Address conflicts if any**

The installer will refuse to create symlinks if files already exist at the target location. Common conflicts:

| File | What | Fix |
|---|---|---|
| `~/.claude/CLAUDE.md` | Your global Claude instructions | Back it up, review for CortexHub sections, then move it temporarily: `mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak` |
| `~/.claude/settings.json` | Your Claude hook config | Merge manually after install (see Troubleshooting) |
| `~/.claude/commands/*.md` | Your custom commands | Move them to a backup folder: `mkdir -p ~/claude-backup && mv ~/.claude/commands/* ~/claude-backup/` |
| `~/.claude/agents/*.md` | Your custom agents | Same as above |

Once conflicts are resolved, proceed to step 4.

**4. Run the installer**

```bash
./install.sh             # core + Claude Code (default)
```

Or with specific tools:

```bash
./install.sh --cursor                   # core + Cursor
./install.sh --cursor --claude          # core + Cursor + Claude Code
./install.sh --opencode                 # core + OpenCode/Ollama
./install.sh --opencode --claude        # core + OpenCode + Claude Code
./install.sh --mcp                      # add MCP server (any combination)
```

> `--mcp` requires Node 24+ and pnpm (run `corepack enable` first).

**5. Verify**

```bash
# Inside Claude Code:
/doctor
```

This validates all symlinks, configs, and hooks are in place.

### What the installer creates

**Core (all installs)**:
- `~/.ai-core/` → symlink to `core/` (scripts, skills, templates)

**Claude Code (default or with `--claude`)**:
- `~/.claude/skills/` → 5 core skills (code-reviewer, security-reviewer, …)
- `~/.claude/commands/` → 14 slash commands (/session-start, /plan, /epct, …)
- `~/.claude/agents/` → 4 sub-agents (doc-writer, explore-codebase, …)
- `~/.claude/CLAUDE.md` → Memory-Bank snippet (injected; existing file preserved)
- `~/.claude/settings.json` → 3 hooks (SessionStart, UserPromptSubmit, PreToolUse)

**Cursor (with `--cursor`)**:
- `~/.cursor/commands/` → slash commands
- `~/.cursor/rules/` → context rules (if present)

**OpenCode (with `--opencode`)**:
- `~/.config/opencode/opencode.json` → model config (if not exists)
- `~/.local/bin/oc` → symlink to launcher script

**MCP (with `--mcp`)**:
- `~/.ai-core/mcp/` → symlink to MCP server
- Connects to Claude Code via `/mcp add cortexhub`

### Install flags

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

---

## Upgrading

**90% of an upgrade happens automatically via symlinks** — when you run `git pull`, all symlinked scripts, skills, and commands in `core/` and `wrappers/` are instantly live. No extra steps needed.

The remaining 10% are config file changes that **you control** (never auto-merged).

### Workflow

**1. Pull the latest**

```bash
cd ~/path/to/cortexhub
git pull
```

All symlinked content is now up-to-date.

**2. Check for config updates [planned]**

```bash
./install.sh --check
```

This reports (but does NOT apply):

| Case | Example | Action |
|---|---|---|
| New wrappers to install | `/session-end` command added | Safe — run `./install.sh` to add |
| Symlinks pointing to deleted files | `agent-routing-old.md` was renamed | Manually remove orphan: `rm ~/.claude/agents/agent-routing-old.md` |
| CLAUDE.md snippet out of sync | Marker version mismatch | Review `~/.claude/CLAUDE.md` manually (see Troubleshooting) |
| settings.json hooks out of sync | Hook `SessionStart` definition changed | Merge manually via `jq` (see Troubleshooting) |
| Config schema version mismatch | `providers.json._schema_version` differs | Migrate using script in `migrations/` if provided |
| Breaking changes | See migration guide | Read `MIGRATIONS.md` for exact steps |

> `--check` feature is [planned] for V1.1. For now, review changes manually: `git log --oneline origin/main..main` or `git diff` before pulling.

**3. Add new safe wrappers (optional)**

If new commands or agents were added:

```bash
./install.sh
```

This is idempotent — only adds what's missing, skips what's already linked.

**4. Migrate configs if breaking changes**

If `MIGRATIONS.md` lists breaking changes, follow the migration script:

```bash
bash migrations/v1.1-provider-config.sh
```

Migration scripts are **proposed but never auto-run** — you review and approve each step.

### What autosyncs via git pull

✅ Scripts in `core/scripts/`  
✅ Skills in `core/skills/`  
✅ Commands in `wrappers/claude/commands/`  
✅ Agents in `wrappers/claude/agents/`  
✅ Agent routing rules in `core/config/agent-routing.json.example`  
✅ Templates in `core/templates/`

### What requires manual action

❌ `~/.claude/CLAUDE.md` (user-editable; snippet versionned)  
❌ `~/.claude/settings.json` (user hooks; new hooks must be merged)  
❌ `~/.ai-core/config/providers.json` (user credentials, no git tracking)  
❌ `~/.ai-core/config/agent-routing.json` (user customizations)  
❌ Breaking changes in schema format (use migration scripts)

---

## Troubleshooting

### Symlinks are orphaned after upgrade

**Symptom**: `ls -l ~/.claude/commands/` shows broken links (red/dark colored).

**Cause**: A command file was renamed or deleted in the repo.

**Fix**:
```bash
# Find orphans
find ~/.claude/commands -type l ! -exec test -e {} \; -print

# Remove one
rm ~/.claude/commands/old-command.md

# Or batch-remove all orphans
find ~/.claude/commands -type l ! -exec test -e {} \; -exec rm {} \;
```

### CLAUDE.md snippet is out of sync

**Symptom**: New Memory-Bank section in repo, but your `~/.claude/CLAUDE.md` still has old version.

**How to detect**:
1. Check the version marker: search for `## Session Auto-Load (Memory-Bank)` in `~/.claude/CLAUDE.md`
2. Compare with snippet: `cat wrappers/claude/CLAUDE.md.snippet`
3. If sections differ, the snippet was updated

**Fix** (manual merge):
```bash
# Backup your current file
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup

# View what's in the new snippet
cat ~/path/to/cortexhub/wrappers/claude/CLAUDE.md.snippet

# Manually review and merge into your ~/.claude/CLAUDE.md
# Keep your personal notes, add the new CortexHub section, remove the old one
```

### settings.json hooks are out of sync

**Symptom**: New hook in `settings.hook.json` (e.g., `PreToolUse`), but your `~/.claude/settings.json` doesn't have it.

**How to detect**:
```bash
# Check if suggest-skill hook is present
grep -c "suggest-skill" ~/.claude/settings.json  # should print 1

# Check if PreToolUse hook is present
grep -c "PreToolUse" ~/.claude/settings.json     # should print 1
```

**Fix** (merge with jq):
```bash
# Backup first
cp ~/.claude/settings.json ~/.claude/settings.json.backup

# Merge the new hooks
jq -s '.[0] * .[1]' ~/.claude/settings.json ~/path/to/cortexhub/wrappers/claude/settings.hook.json > /tmp/merged.json && mv /tmp/merged.json ~/.claude/settings.json
```

### Config schema is out of sync

**Symptom**: `doctor` warns about schema mismatch, e.g., `providers.json._schema_version: got 1, expected 2`.

**Fix**:
```bash
# Check current version
jq '._schema_version' ~/.ai-core/config/providers.json

# If migration script exists, run it
bash ~/path/to/cortexhub/migrations/providers-v1-to-v2.sh

# Or manually copy the new template and re-configure
cp ~/.ai-core/config/providers.json.example ~/.ai-core/config/providers.json
# Edit to fill in your API keys
```

### Uninstall

To remove all CortexHub installations:

```bash
./install.sh --uninstall           # core + Claude Code
./install.sh --uninstall --cursor  # + Cursor
./install.sh --uninstall --mcp     # + MCP
```

This removes only CortexHub symlinks, never touches your user configs or dotfiles.

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

| Platform | Status | Notes |
|---|---|---|
| Linux | ✅ | Tested on Ubuntu 20.04+ |
| macOS | ✅ | Requires Bash 4+ via Homebrew (`brew install bash`) |
| WSL2 | ✅ | Same as Linux |
| Windows native | ❌ | Out of scope (use WSL2) |

## Contributing

Want to add a skill, fix a bug, or propose a workflow? Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first — it documents versioning discipline, backwards compatibility rules, and the PR checklist.

TL;DR:
- Scripts are the API — never break the contract without a migration guide
- Configs are versioned (`_schema_version`) — bump when structure changes
- Changes are additive — never delete files without a migration path
- Migrations go in [`MIGRATIONS.md`](MIGRATIONS.md) + optional scripts in `migrations/`

---

## References

- [`WORKFLOWS.md`](WORKFLOWS.md) — workflow contract, agent × workflow matrix
- [`MIGRATIONS.md`](MIGRATIONS.md) — breaking changes and upgrade paths
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contributor guide, versioning discipline
- [`core/docs/SCRIPTS-CONTRACT.md`](core/docs/SCRIPTS-CONTRACT.md) — scripts args, exit codes, output format
- [`core/docs/AGENT-ROUTING.md`](core/docs/AGENT-ROUTING.md) — deterministic agent routing rules
- [`docs/MCP-VS-SCRIPTS.md`](docs/MCP-VS-SCRIPTS.md) — when to use MCP vs direct scripts
- [`wrappers/mcp/capabilities.md`](wrappers/mcp/capabilities.md) — MCP server capabilities
