# CortexHub — Scripts Core Contract

This document is the authoritative reference for `~/.ai-core/scripts/`. Every wrapper (Claude, Cursor, Continue.dev, future agents) calls these scripts directly. Arguments, exit codes, and output formats are stable.

## Conventions

- **Exit 0** = success. Stdout contains result.
- **Exit 1** = error. Stderr contains reason.
- **Interactive mode** = no args, prompts the user (for direct terminal use).
- **Non-interactive mode** = explicit args, for use by agent wrappers.
- Paths use `$HOME` — never hardcoded absolutes.

---

## capture.sh

Append a timestamped note to today's capture file in the project memory-bank.

**Args**
| Arg | Type | Required | Description |
|---|---|---|---|
| `$1` | string | yes | Note text |

**Exit codes**
| Code | Meaning |
|---|---|
| 0 | Note captured |
| 1 | Missing arg OR no memory-bank found |

**stdout (success)**
```
Captured to <path/to/captures/YYYY-MM-DD.md>
[HH:MM] <note text>
```

**stderr (error)**
```
Usage: capture.sh "your note"
No memory-bank found. Run: memory-bank-init.sh
```

---

## memory-bank-init.sh

Create `.ai-local/memory-bank/` in the current directory with template files. Agent-agnostic — produces no agent-specific config.

**Args**
| Arg | Type | Required | Description |
|---|---|---|---|
| `$1` | `solo`\|`shared` | no | Mode. Interactive prompt if omitted. |

**Exit codes**
| Code | Meaning |
|---|---|
| 0 | Initialized (or graceful cancel on overwrite prompt) |
| 1 | Invalid mode arg or invalid interactive choice |

**stdout (success)**
```
Memory-bank initialized in .ai-local/memory-bank/ (mode: <mode>)
  projectbrief.md
  techContext.md
  activeContext.md

Next: configure your AI agent to read this memory-bank.
```

**stderr (error)**
```
Invalid choice. Aborting.
Usage: memory-bank-init.sh [solo|shared]
```

---

## memory-bank-setup.sh

Patch the target agent's config file to wire it to `.ai-local/memory-bank/`. Mode (solo/shared) is auto-detected from `.gitignore`.

**Args**
| Arg | Type | Required | Description |
|---|---|---|---|
| `$1` | `claude`\|`cursor`\|`windsurf` | no | Target agent. Defaults to `claude`. |

**Exit codes**
| Code | Meaning |
|---|---|
| 0 | Agent configured or already configured |
| 1 | No memory-bank found OR unknown agent |

**stdout (success)**
```
CLAUDE.md patched: <path>          # claude
.cursor/rules/memory-bank.mdc created   # cursor
.windsurfrules patched: <path>     # windsurf

Agent '<agent>' configured for .ai-local/memory-bank/ (mode: <mode>)
```

**stderr (error)**
```
No .ai-local/memory-bank/ found. Run memory-bank-init.sh first.
Unknown agent: <agent>
Usage: memory-bank-setup.sh [claude|cursor|windsurf]
```

---

## session-start.sh

Display current project context from `activeContext.md`, optionally set the session focus goal.

**Args**
| Arg | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | Interactive mode — displays context and prompts for goal |
| `--read` | flag | — | Print context and exit (non-interactive, for wrappers) |
| `--set-focus "<goal>"` | flag + string | — | Update Current Focus without prompting |
| `"<goal>"` | string | — | Shorthand for `--set-focus` |

**Exit codes**
| Code | Meaning |
|---|---|
| 0 | Context loaded and/or focus set |
| 1 | No memory-bank found, `activeContext.md` missing, or `--set-focus` with no value |

**stdout — context display**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Focus:  <current focus>

Next Steps:
<up to 5 lines>

Challenges:
<up to 3 lines>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**stdout — focus set**
```
Focus set: <goal>
Updated: <path/to/activeContext.md>
```

**stderr (error)**
```
No memory-bank found. Run: memory-bank-init.sh
activeContext.md not found in <dir>
Usage: session-start.sh --set-focus "your goal"
```

---

## session-end.sh

Write session summary (accomplished, next, challenges) to `activeContext.md`.

**Args**
| Arg | Type | Required | Description |
|---|---|---|---|
| *(none)* | — | — | Interactive mode — prompts for all fields |
| `--accomplished "<text>"` | flag + string | yes (non-interactive) | What was done this session |
| `--next "<text>"` | flag + string | yes (non-interactive) | Next step for next session |
| `--challenges "<text>"` | flag + string | no | Blockers or open questions |

**Exit codes**
| Code | Meaning |
|---|---|
| 0 | Session saved |
| 1 | No memory-bank found OR missing required flags |

**stdout (success)**
```
Session saved to <path/to/activeContext.md>
  Accomplished: <text>
  Next:         <text>
  Challenges:   <text>   # only if provided
```

**stderr (error)**
```
No memory-bank found. Run: memory-bank-init.sh
Error: --accomplished and --next are required.
```
