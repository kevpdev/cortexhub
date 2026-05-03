import { ContinueConfig, SlashCommand } from "@continuedev/config-types";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import * as os from "node:os";
import * as path from "node:path";

const execAsync = promisify(exec);

const SCRIPTS = path.join(os.homedir(), ".ai-core", "scripts");
const SKILLS  = path.join(os.homedir(), ".ai-core", "skills");

function script(name: string): string {
  return path.join(SCRIPTS, name);
}

// Sanitize user input — no shell metacharacters allowed.
function sanitize(input: string): string {
  return input.replace(/[`$\\"|;&<>]/g, "").trim();
}

async function run(cmd: string): Promise<string> {
  try {
    const { stdout, stderr } = await execAsync(cmd);
    return (stdout || stderr).trim();
  } catch (err: unknown) {
    const e = err as { stderr?: string; message?: string };
    return `Error: ${e.stderr ?? e.message ?? "unknown"}`;
  }
}

// ─── session-start ──────────────────────────────────────────────────────────

const sessionStart: SlashCommand = {
  name: "session-start",
  description: "Load project context, optionally set session goal",
  run: async function* ({ input }) {
    const context = await run(`${script("session-start.sh")} --read`);
    yield context + "\n";

    const goal = sanitize(input);
    if (goal) {
      const result = await run(`${script("session-start.sh")} --set-focus "${goal}"`);
      yield result + "\n";
      yield "Session started. Context loaded.";
    } else {
      yield "What's your goal for this session? Re-run `/session-start <goal>` with your goal.";
    }
  },
};

// ─── session-end ────────────────────────────────────────────────────────────

const sessionEnd: SlashCommand = {
  name: "session-end",
  description: "Save session progress — usage: /session-end <accomplished> | <next> [| <challenges>]",
  run: async function* ({ input }) {
    // Expected input format: "accomplished | next | challenges (optional)"
    const parts = input.split("|").map((s) => sanitize(s));
    const [accomplished, next, challenges] = parts;

    if (!accomplished || !next) {
      yield "Usage: `/session-end <accomplished> | <next> [| <challenges>]`\n";
      yield "Example: `/session-end Fixed auth bug | Add rate limiting | None`";
      return;
    }

    let cmd = `${script("session-end.sh")} --accomplished "${accomplished}" --next "${next}"`;
    if (challenges) cmd += ` --challenges "${challenges}"`;

    const result = await run(cmd);
    yield result;
  },
};

// ─── capture ────────────────────────────────────────────────────────────────

const capture: SlashCommand = {
  name: "capture",
  description: "Quick note capture — usage: /capture <note>",
  run: async function* ({ input }) {
    const note = sanitize(input);
    if (!note) {
      yield "Usage: `/capture <note>`";
      return;
    }
    const result = await run(`${script("capture.sh")} "${note}"`);
    yield result;
  },
};

// ─── memory-bank-init ───────────────────────────────────────────────────────

const memoryBankInit: SlashCommand = {
  name: "memory-bank-init",
  description: "Init project memory-bank — usage: /memory-bank-init solo|shared",
  run: async function* ({ input }) {
    const mode = sanitize(input).toLowerCase();
    if (mode !== "solo" && mode !== "shared") {
      yield "Usage: `/memory-bank-init solo` or `/memory-bank-init shared`\n";
      yield "• solo  — personal project, .ai-local/ committable\n";
      yield "• shared — team project, .ai-local/ git-ignored";
      return;
    }
    const result = await run(`${script("memory-bank-init.sh")} ${mode}`);
    yield result + "\n";
    yield "Tip: run `/memory-bank-setup` to wire Continue.dev to this memory-bank.";
  },
};

// ─── memory-bank-setup ──────────────────────────────────────────────────────

const memoryBankSetup: SlashCommand = {
  name: "memory-bank-setup",
  description: "Wire an agent to the project memory-bank — usage: /memory-bank-setup [claude|cursor|windsurf]",
  run: async function* ({ input }) {
    const agent = sanitize(input).toLowerCase() || "claude";
    const valid = ["claude", "cursor", "windsurf"];
    if (!valid.includes(agent)) {
      yield `Unknown agent "${agent}". Valid: ${valid.join(", ")}`;
      return;
    }
    const result = await run(`${script("memory-bank-setup.sh")} ${agent}`);
    yield result;
  },
};

// ─── plan (prompt-based) ────────────────────────────────────────────────────

const plan: SlashCommand = {
  name: "plan",
  description: "Explore codebase and produce an implementation plan — stops before writing code",
  prompt: `You are an implementation planner. Your job is to explore, think, and produce a plan. You do not write any code.

## 1. EXPLORE

- Use @Codebase to search for existing patterns, related files, conventions.
- Use @Docs for library/framework specifics when needed.
- Think deeply about what to search before searching — avoid redundant lookups.

## 2. PLAN

Produce a structured plan:

\`\`\`
## Objective
[One sentence: what this achieves and why]

## Files to change
- path/to/file.ext — what and why

## Files to create
- path/to/new.ext — purpose

## Implementation steps
1. Step one
2. Step two
...

## Risks / open questions
- ...
\`\`\`

## Rules
- No code during this phase.
- Stop after the plan — wait for user validation.
- If major ambiguities exist, ask before planning.

Feature/task to plan: {{{ input }}}`,
};

// ─── epct (prompt-based) ────────────────────────────────────────────────────

const epct: SlashCommand = {
  name: "epct",
  description: "Implement a validated plan — Code + Test phases only (run /plan first)",
  prompt: `You are a systematic implementation specialist. You implement plans — you do not re-plan.

## 1. LOAD PLAN

- If a /plan result is in context: use it directly.
- If only a description is provided: use @Codebase for minimal orientation (1-2 lookups max), then proceed.
- If major ambiguities exist, stop and ask.

## 2. CODE

- Follow existing codebase style — match conventions, naming, structure.
- Stay strictly in scope — change only what's needed.
- No comments unless the WHY is non-obvious.
- Run autoformatting when done.

## 3. TEST

- Check available scripts (package.json or equivalent): lint, typecheck, test, build.
- Run only tests related to the feature — not the full suite.
- Report what was tested and the result.

Plan or feature to implement: {{{ input }}}`,
};

// ─── skill ──────────────────────────────────────────────────────────────────

const VALID_SKILLS = ["code-reviewer", "security-reviewer", "backend-architect", "frontend-expert", "database-expert"];

const skill: SlashCommand = {
  name: "skill",
  description: "Load a CortexHub skill — usage: /skill <name>",
  run: async function* ({ input }) {
    const name = sanitize(input).toLowerCase();

    if (!name) {
      yield "Available skills:\n";
      yield VALID_SKILLS.map((s) => `  • ${s}`).join("\n");
      yield "\n\nUsage: `/skill <name>`";
      return;
    }

    if (!VALID_SKILLS.includes(name)) {
      yield `Unknown skill: "${name}"\nAvailable: ${VALID_SKILLS.join(", ")}`;
      return;
    }

    try {
      const { readFile } = await import("node:fs/promises");
      const content = await readFile(path.join(SKILLS, name, "SKILL.md"), "utf-8");
      yield content;
      yield `\n\n---\nSkill \`${name}\` loaded. Apply these instructions for the rest of this conversation.`;
    } catch {
      yield `Could not read skill "${name}". Check that ~/.ai-core/skills/${name}/SKILL.md exists.`;
    }
  },
};

// ─── create-pull-request ────────────────────────────────────────────────────

const createPullRequest: SlashCommand = {
  name: "create-pull-request",
  description: "Create and push a PR with auto-generated title and description",
  prompt: `You are a PR automation tool. Create a pull request for the current branch.

## Steps

1. Run \`git status\` and \`git branch --show-current\` in terminal.
2. If on main/master: create a descriptive branch first. Never commit to protected branches.
3. Run \`git push -u origin HEAD\`.
4. Run \`git diff origin/<base>...HEAD --stat\` to analyze changes.
5. Generate:
   - Title: one-line summary ≤ 72 chars.
   - Body: bullet points of key changes + type tag (feat/fix/refactor/docs/chore).
6. Run \`gh pr create --title "..." --body "..."\` (HEREDOC for body).
7. Return the PR URL.

## Rules
- No verbose descriptions, no signatures.
- Auto-detect base branch (main/master/develop).
- If PR already exists, return the existing URL.`,
};

// ─── Config export ───────────────────────────────────────────────────────────

const config: ContinueConfig = {
  slashCommands: [
    sessionStart,
    sessionEnd,
    capture,
    memoryBankInit,
    memoryBankSetup,
    plan,
    epct,
    createPullRequest,
    skill,
  ],
};

export default config;
