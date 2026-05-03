# CortexHub — Cursor Wrapper

Expose the 8 CortexHub V1 workflows as Cursor slash commands.

## Install

```bash
bash ~/path/to/cortexhub/install.sh --cursor
```

Or manually:

```bash
mkdir -p .cursor/commands
cp ~/path/to/cortexhub/wrappers/cursor/commands/*.md .cursor/commands/
```

## Usage

Type `/` in Cursor chat to see available commands:

| Command | Description |
|---|---|
| `/session-start [goal]` | Load context, set session goal |
| `/session-end` | Save progress for next session |
| `/capture <note>` | Quick note capture |
| `/memory-bank-init` | Bootstrap project memory-bank |
| `/memory-bank-setup [agent]` | Wire agent to memory-bank |
| `/plan <description>` | Explore + plan, no code |
| `/epct <description>` | Implement validated plan |
| `/create-pull-request` | Create PR with auto description |

## Requirements

- `~/.ai-core/scripts/` installed (run `cortexhub/install.sh` first)
- `git` and `gh` CLI for `/create-pull-request`
