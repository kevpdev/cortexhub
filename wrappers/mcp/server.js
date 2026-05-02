#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { resolve as resolvePath, join } from "node:path";

const SCRIPTS_DIR = join(homedir(), ".ai-core", "scripts");

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
function resolveProject(projectPath) {
  if (projectPath) return resolvePath(projectPath);
  if (process.env.CORTEXHUB_PROJECT) return resolvePath(process.env.CORTEXHUB_PROJECT);
  return process.cwd();
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
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args = {} } = req.params;
  const cwd = resolveProject(args.project_path);

  switch (name) {
    case "session_start": {
      const scriptArgs = args.goal ? [args.goal] : ["--read"];
      return toContent(await runScript("session-start.sh", scriptArgs, cwd));
    }
    case "session_end": {
      const scriptArgs = ["--accomplished", args.accomplished, "--next", args.next];
      if (args.challenges) scriptArgs.push("--challenges", args.challenges);
      return toContent(await runScript("session-end.sh", scriptArgs, cwd));
    }
    case "capture": {
      return toContent(await runScript("capture.sh", [args.note], cwd));
    }
    case "memory_bank_init": {
      return toContent(await runScript("memory-bank-init.sh", [args.mode], cwd));
    }
    case "memory_bank_setup": {
      const agent = args.agent ?? "claude";
      return toContent(await runScript("memory-bank-setup.sh", [agent], cwd));
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
