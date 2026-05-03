# CortexHub — Workflow Contract (V1)

This document defines the universal workflow contract that every Tier 1 wrapper (Claude Code, Cursor, OpenCode) must implement.

## Principles

- **Agent-agnostic** — the contract describes WHAT the workflow does and its expected behavior, not HOW a specific agent implements it.
- **Scripts are the API** — every workflow ultimately calls a script in `~/.ai-core/scripts/`. Wrappers translate the agent's native UX into a script invocation.
- **MCP is optional** — wrappers MAY call MCP tools instead of scripts directly when running in environments without shell access (e.g. Open WebUI). Scripts remain the canonical path.
- **Stable args, stable output** — scripts honor a fixed CLI contract. Wrappers parse stdout, propagate exit codes, never reach into script internals.

## Conventions

- **Workflow name** — kebab-case, identical across agents (e.g. `session-start`).
- **Underlying script** — `~/.ai-core/scripts/<workflow>.sh`.
- **User input** — wrappers MAY ask interactively if args are missing. Wrappers MUST accept args directly when provided (no forced interactivity).
- **Output** — wrappers display the script's stdout verbatim. No reformatting that loses information.
- **Exit codes** — non-zero = display stderr to user, do not silently swallow.

---

## V1 Workflows (8)

### 1. session-start

**Purpose** — Load project context from `activeContext.md`, optionally set the session goal.

**Args** — `goal` (optional, free text).

**Script** — `session-start.sh --read` then `session-start.sh --set-focus "<goal>"` if goal provided.

**Expected behavior**
1. Run `--read`, display the loaded context.
2. If no goal arg provided, ask the user: "What's your goal for this session?"
3. Run `--set-focus` with the goal.
4. Confirm: "Session started. Context loaded."

---

### 2. session-end

**Purpose** — Save session progress to `activeContext.md` for the next session to load.

**Args** — None at invocation; collected interactively or from context.

**Script** — `session-end.sh --accomplished "<x>" --next "<y>" [--challenges "<z>"]`.

**Expected behavior**
1. Ask the user three questions (or extract from session context if obvious):
   - What did you accomplish this session?
   - What's the next step for the next session?
   - Any challenges or blockers? (optional)
2. Run the script with the answers.
3. Display script output.
4. Suggest committing the changes.

---

### 3. capture

**Purpose** — Append a timestamped note to today's capture file without breaking flow.

**Args** — `note` (required, free text).

**Script** — `capture.sh "<note>"`.

**Expected behavior**
1. If no arg provided, ask: "What do you want to capture?"
2. Run the script with the note.
3. Display the one-line confirmation.

---

### 4. memory-bank-init

**Purpose** — Bootstrap `.ai-local/memory-bank/` in the current project. Agent-agnostic — produces no agent-specific config.

**Args** — `mode` ∈ {`solo`, `shared`} (required).

**Script** — `memory-bank-init.sh <mode>`.

**Expected behavior**
1. If no mode provided, ask: "Solo or shared project? [1] solo [2] shared".
2. Run the script with the chosen mode.
3. Display script output.
4. Suggest running `memory-bank-setup` next to wire the current agent.

---

### 5. memory-bank-setup

**Purpose** — Patch the current agent's config file so it reads the project memory-bank.

**Args** — `agent` ∈ {`claude`, `cursor`, `windsurf`} (optional, defaults to the wrapper's own agent).

**Script** — `memory-bank-setup.sh <agent>`.

**Expected behavior**
1. Determine the target agent — use arg if provided, otherwise default to the wrapper's own agent.
2. Run the script.
3. Display script output.

---

### 6. plan

**Purpose** — Explore the codebase and produce an implementation plan. Stops before writing code.

**Args** — `description` (required, free text describing the feature or task).

**Script** — None (pure agent methodology workflow).

**Expected behavior**
1. **Explore** — gather context via the agent's native exploration capabilities (subagents in Claude, @-mentions in Cursor, context tools in OpenCode, etc.).
2. **Plan** — produce a structured plan with:
   - Objective (one sentence)
   - Files to change (with reason)
   - Files to create (with purpose)
   - Numbered implementation steps
   - Risks and open questions
3. **Stop** — do not write code. Hand the plan back to the user.

**Implementation note for wrappers** — translate "subagents / parallel exploration" into the agent's native equivalent. The deliverable (a structured plan) is the contract; the exploration mechanism is not.

---

### 7. epct

**Purpose** — Implement a validated plan (Code + Test phases). Assumes `plan` was already run.

**Args** — `plan-or-feature-description` (required).

**Script** — None (pure agent methodology workflow).

**Expected behavior**
1. **Load plan** — use the plan from prior context if available, otherwise do minimal exploration on the feature description (max 1-2 lookups).
2. **Code** — implement strictly in scope, follow existing patterns, no comments unless necessary, run autoformatters.
3. **Test** — run available scripts (`lint`, `typecheck`, `test`, `build`) and tests related to the feature only — never the full suite.
4. If major ambiguities surface, stop and ask before continuing.

---

### 8. create-pull-request

**Purpose** — Create and push a PR with auto-generated title and description.

**Args** — None (extracts from git state).

**Script** — None (uses `git` and `gh` directly).

**Expected behavior**
1. Verify state: `git status`, `git branch --show-current`.
2. **Safety** — if on `main`/`master`, create a descriptive branch first. Never commit to protected branches.
3. Push current branch with upstream tracking: `git push -u origin HEAD`.
4. Analyze diff: `git diff origin/<base>...HEAD --stat`.
5. Generate:
   - Title: one-line summary, ≤ 72 chars.
   - Body: bullet points of key changes, type tag (`feat`/`fix`/`refactor`/`docs`/`chore`).
6. Submit: `gh pr create --title "..." --body "..."` (HEREDOC for body).
7. Return the PR URL.

**Rules** — no verbose descriptions, no "Generated with" signatures, auto-detect base branch (main/master/develop).

---

---

### 9. skill

**Purpose** — Load a CortexHub skill into the agent's context for the rest of the conversation.

**Args** — `name` ∈ {`code-reviewer`, `security-reviewer`, `backend-architect`, `frontend-expert`, `database-expert`} (optional — lists available skills if omitted).

**Script** — None. Reads `~/.ai-core/skills/<name>/SKILL.md` directly.

**Expected behavior**
1. If no name provided: list available skills and prompt for one.
2. Validate name against the known list.
3. Read `~/.ai-core/skills/<name>/SKILL.md` and load content into context.
4. Confirm: "Skill `<name>` loaded." Apply instructions for the rest of the conversation.

**Note for Claude Code** — skills are loaded via the native skill mechanism (`~/.claude/skills/`). No explicit command needed; mention the skill in your request to activate it.

---

## Implementation matrix

| Workflow | Claude Code | Cursor | OpenCode |
|---|---|---|---|
| session-start | ✅ slash command `.md` | ✅ `.cursor/commands/` | ✅ `opencode.json` |
| session-end | ✅ | ✅ | ✅ |
| capture | ✅ | ✅ | ✅ |
| memory-bank-init | ✅ | ✅ | ✅ |
| memory-bank-setup | ✅ | ✅ | ✅ |
| plan | ✅ | ✅ | ✅ |
| epct | ✅ | ✅ | ✅ |
| create-pull-request | ✅ | ✅ | ✅ |
| skill | ✅ natif | ✅ `.cursor/commands/` | ✅ |

---

## Claude Code Agents

Claude Code offers four specialized sub-agents (isolated context, targeted model) for domain-specific tasks. **These are Claude Code-only** — not available in Cursor or OpenCode. Activate by mentioning the agent name in your request or using `/agent:<name>`.

| Agent | Purpose | Activation |
|---|---|---|
| **doc-writer** | Generate or update technical documentation: Javadoc, JSDoc/TypeDoc, README, OpenAPI, inline comments. Precise, developer-oriented, respects project conventions. | "Document this function", "Generate JSDoc", "Write the README", "Document this endpoint" |
| **explore-codebase** | Comprehensive codebase exploration to find all relevant code for a feature. Discovers patterns, dependencies, tests, and existing implementations via parallel grep + read strategy. | "Explore the codebase for X", "Find where Y is implemented", "Show me related code" |
| **explore-docs** | Retrieve precise library documentation with code examples. Uses Context7 for library docs + WebFetch fallback. Filters for essentials: code examples, API specs, configuration, common pitfalls. | "How do I use X with Y library?", "Show me X library examples", "Document search for Y" |
| **websearch** | Fast web search for accurate information. Fetches authoritative sources and summarizes concisely with sources. | "Search for X", "Find information about Y" |

Each agent is Haiku-optimized for speed and focused on a single responsibility. Load them automatically when their domain is mentioned in your request.

---

## Out of V1

- `fix-pr-comments`, `watch-ci`, `run-tasks` — require GitHub API integration. Deferred to V1.1.
- `plan-to-stories`, `story-create` — BMAD methodology, niche audience. Deferred to V1.1.
- `init-node-ts` — narrow tech-specific bootstrap. Out of scope.

## Known limitations

**OpenCode — probabilistic workflows** : OpenCode has no native hooks or slash command system. Session/capture workflows are triggered by the model based on context — reliable on 14B+ (recommended default), degraded on 7/8B (constrained machines). Claude Code and Cursor remain the primary agents for deterministic workflows.

Planned for V1.1 : native OpenCode hooks support or shell wrapper commands (`oc-session`, `oc-capture`) as a deterministic fallback.
