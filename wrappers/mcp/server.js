#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "node:child_process";
import { readdir, readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { resolve as resolvePath, join } from "node:path";
import { routeCompletion, TASK_TYPES } from "./router.js";

const SCRIPTS_DIR = join(homedir(), ".ai-core", "scripts");
const SKILLS_DIR  = join(homedir(), ".ai-core", "skills");

// Spawn a core script with args array — no shell interpolation, no injection risk.
function runScript(scriptName, args, cwd) {
  return new Promise((res) => {
    const scriptPath = join(SCRIPTS_DIR, scriptName);
    const proc = spawn(scriptPath, args, {
      cwd,
      env: { ...process.env },
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    proc.stdout.on("data", (d) => { stdout += d; });
    proc.stderr.on("data", (d) => { stderr += d; });
    proc.on("close", (code) => res({ stdout: stdout.trim(), stderr: stderr.trim(), code }));
    proc.on("error", (err) => res({ stdout: "", stderr: err.message, code: 1 }));
  });
}

// Project path resolution order: explicit arg → env var → server cwd.
// Restricts resolved path to the user's home directory to prevent scripts
// from running in sensitive system directories (/etc, /sys, etc.).
function resolveProject(projectPath) {
  const resolved = projectPath
    ? resolvePath(projectPath)
    : process.env.CORTEXHUB_PROJECT
      ? resolvePath(process.env.CORTEXHUB_PROJECT)
      : process.cwd();

  const home = homedir();
  if (!resolved.startsWith(home) && !resolved.startsWith("/tmp")) {
    throw new Error(`project_path must be under home directory (got: ${resolved})`);
  }
  return resolved;
}

function toContent(result) {
  const isError = result.code !== 0;
  const text = result.stdout || result.stderr || `Exit code: ${result.code}`;
  return { content: [{ type: "text", text }], isError };
}

const server = new Server(
  { name: "cortexhub", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "session_start",
      description:
        "Load project context from activeContext.md. Pass `goal` to set the session focus, omit it to read context only.",
      inputSchema: {
        type: "object",
        properties: {
          goal: {
            type: "string",
            description: "Session focus goal. Omit to read context only.",
          },
          project_path: {
            type: "string",
            description:
              "Absolute path to the project root (defaults to CORTEXHUB_PROJECT env var or server cwd).",
          },
        },
      },
    },
    {
      name: "session_end",
      description: "Save session progress to activeContext.md.",
      inputSchema: {
        type: "object",
        required: ["accomplished", "next"],
        properties: {
          accomplished: { type: "string", description: "What was completed this session." },
          next: { type: "string", description: "Next step for the following session." },
          challenges: { type: "string", description: "Blockers or open questions (optional)." },
          project_path: { type: "string" },
        },
      },
    },
    {
      name: "capture",
      description: "Append a timestamped note to today's capture file in the project memory-bank.",
      inputSchema: {
        type: "object",
        required: ["note"],
        properties: {
          note: { type: "string", description: "Text to capture." },
          project_path: { type: "string" },
        },
      },
    },
    {
      name: "memory_bank_init",
      description: "Initialize .ai-local/memory-bank/ in a project directory.",
      inputSchema: {
        type: "object",
        required: ["mode"],
        properties: {
          mode: {
            type: "string",
            enum: ["solo", "shared"],
            description: "solo = personal project. shared = team project (.ai-local/ added to .gitignore).",
          },
          project_path: { type: "string" },
        },
      },
    },
    {
      name: "memory_bank_setup",
      description: "Patch an AI agent's config file to wire it to the project memory-bank.",
      inputSchema: {
        type: "object",
        properties: {
          agent: {
            type: "string",
            enum: ["claude", "cursor", "windsurf"],
            description: "Target agent (default: claude).",
          },
          project_path: { type: "string" },
        },
      },
    },
    {
      name: "list_skills",
      description: "List all available CortexHub skills (code-reviewer, security-reviewer, etc.).",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "get_skill",
      description: "Return the full instructions of a CortexHub skill. Use this to load expert behavior into your context before a task.",
      inputSchema: {
        type: "object",
        required: ["name"],
        properties: {
          name: {
            type: "string",
            description: "Skill name (e.g. code-reviewer, security-reviewer, backend-architect).",
          },
          section: {
            type: "string",
            description: "Optional reference file inside the skill's references/ folder (e.g. 'checklist-typescript.md').",
          },
        },
      },
    },
    {
      name: "route_completion",
      description:
        "Send a prompt to the appropriate local or cloud model based on task type. Reads ~/.ai-core/config/providers.json for provider config.",
      inputSchema: {
        type: "object",
        required: ["task_type", "messages"],
        properties: {
          task_type: {
            type: "string",
            enum: TASK_TYPES,
            description: "Type of task — determines the model tier (tier1=fast/local, tier2=standard, tier3=complex).",
          },
          messages: {
            type: "array",
            description: "Messages in OpenAI format.",
            items: {
              type: "object",
              required: ["role", "content"],
              properties: {
                role: { type: "string", enum: ["system", "user", "assistant"] },
                content: { type: "string" },
              },
            },
          },
          max_tokens: {
            type: "number",
            description: "Max tokens in response (default: 2048).",
          },
          tier: {
            type: "string",
            enum: ["tier1", "tier2", "tier3"],
            description: "Force a specific tier, ignoring task_type routing.",
          },
        },
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args = {} } = req.params;

  switch (name) {
    case "session_start": {
      const cwd = resolveProject(args.project_path);
      const scriptArgs = args.goal ? [args.goal] : ["--read"];
      return toContent(await runScript("session-start.sh", scriptArgs, cwd));
    }
    case "session_end": {
      const cwd = resolveProject(args.project_path);
      const scriptArgs = ["--accomplished", args.accomplished, "--next", args.next];
      if (args.challenges) scriptArgs.push("--challenges", args.challenges);
      return toContent(await runScript("session-end.sh", scriptArgs, cwd));
    }
    case "capture": {
      const cwd = resolveProject(args.project_path);
      return toContent(await runScript("capture.sh", [args.note], cwd));
    }
    case "memory_bank_init": {
      const cwd = resolveProject(args.project_path);
      return toContent(await runScript("memory-bank-init.sh", [args.mode], cwd));
    }
    case "memory_bank_setup": {
      const cwd = resolveProject(args.project_path);
      const agent = args.agent ?? "claude";
      return toContent(await runScript("memory-bank-setup.sh", [agent], cwd));
    }
    case "list_skills": {
      try {
        const entries = await readdir(SKILLS_DIR, { withFileTypes: true });
        const skills = entries.filter((e) => e.isDirectory()).map((e) => e.name);
        return { content: [{ type: "text", text: skills.join("\n") }] };
      } catch (err) {
        return { content: [{ type: "text", text: err.message }], isError: true };
      }
    }
    case "get_skill": {
      try {
        const entries = await readdir(SKILLS_DIR, { withFileTypes: true });
        const valid = new Set(entries.filter((e) => e.isDirectory()).map((e) => e.name));

        // Validate name against known skills — prevents path traversal.
        if (!valid.has(args.name)) {
          return { content: [{ type: "text", text: `Unknown skill: ${args.name}. Available: ${[...valid].join(", ")}` }], isError: true };
        }

        const SAFE_SECTION = /^[a-zA-Z0-9_-]+\.md$/;
        if (args.section && !SAFE_SECTION.test(args.section)) {
          return { content: [{ type: "text", text: `Invalid section name: ${args.section}` }], isError: true };
        }

        const filePath = args.section
          ? join(SKILLS_DIR, args.name, "references", args.section)
          : join(SKILLS_DIR, args.name, "SKILL.md");

        const content = await readFile(filePath, "utf-8");
        return { content: [{ type: "text", text: content }] };
      } catch (err) {
        return { content: [{ type: "text", text: err.message }], isError: true };
      }
    }
    case "route_completion": {
      try {
        const result = await routeCompletion({
          task_type: args.task_type,
          messages: args.messages,
          max_tokens: args.max_tokens,
          tier: args.tier,
        });
        const fallbackNote = result.fallback_from ? ` ⚡ fallback from ${result.fallback_from}` : "";
        const meta = `[${result.tier} · ${result.model}${fallbackNote}]${result.usage ? ` · ${result.usage.total_tokens} tokens` : ""}`;
        return { content: [{ type: "text", text: `${meta}\n\n${result.content}` }] };
      } catch (err) {
        return { content: [{ type: "text", text: err.message }], isError: true };
      }
    }
    default:
      return { content: [{ type: "text", text: `Unknown tool: ${name}` }], isError: true };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  process.stderr.write(`Fatal: ${err.message}\n`);
  process.exit(1);
});
