# CortexHub — Continue.dev Wrapper

Expose the 8 CortexHub V1 workflows as Continue.dev slash commands.

## Install

```bash
bash ~/path/to/cortexhub/install.sh --continue
```

Or manually — merge the slash commands into your `.continue/config.ts`:

```bash
cp ~/path/to/cortexhub/wrappers/continue/config.ts .continue/config.ts
```

> If you already have a `config.ts`, manually add the `slashCommands` array entries from the CortexHub config.

## Usage

Type `/` in Continue chat to see available commands:

| Command | Description |
|---|---|
| `/session-start [goal]` | Load context, set session goal |
| `/session-end <done> \| <next> [\| <challenges>]` | Save progress |
| `/capture <note>` | Quick note capture |
| `/memory-bank-init solo\|shared` | Bootstrap project memory-bank |
| `/memory-bank-setup [agent]` | Wire agent to memory-bank |
| `/plan <description>` | Explore + plan, no code |
| `/epct <description>` | Implement validated plan |
| `/create-pull-request` | Create PR with auto description |

## Requirements

- `~/.ai-core/scripts/` installed (run `cortexhub/install.sh` first)
- `@continuedev/config-types` package for TypeScript types
- `git` and `gh` CLI for `/create-pull-request`
