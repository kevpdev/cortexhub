#!/usr/bin/env node
// gateway.js — classify a task description → Ollama profile for OpenCode
//
// Usage:
//   node gateway.js "review my authentication PR"
//   node gateway.js ""          # → default profile (code)
//
// Output: JSON { profile, model, base_url, opencode_model, skill }
//   opencode_model is ready to pass as: opencode --model <value>

import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const CONFIG_PATH = join(homedir(), ".ai-core", "config", "providers.json");
const DEFAULT_PROFILE = "code";

async function loadConfig() {
  let raw;
  try {
    raw = await readFile(CONFIG_PATH, "utf-8");
  } catch {
    throw new Error(
      `providers.json not found at ${CONFIG_PATH}\nRun: cp ~/.ai-core/config/providers.json.example ~/.ai-core/config/providers.json`
    );
  }
  let config;
  try { config = JSON.parse(raw); }
  catch { throw new Error(`providers.json is not valid JSON — check ${CONFIG_PATH}`); }
  if (!config.profiles) {
    throw new Error(
      `No 'profiles' section in providers.json — add one before using the OpenCode gateway.\nSee providers.json.example for the expected format.`
    );
  }
  return config;
}

// Score each profile by number of trigger keywords found in the task.
function classifyByKeywords(task, profiles) {
  const taskLower = task.toLowerCase();
  let bestName = null;
  let bestScore = 0;

  for (const [name, profile] of Object.entries(profiles)) {
    const score = (profile.triggers ?? []).filter(t =>
      taskLower.includes(t.toLowerCase())
    ).length;
    if (score > bestScore) {
      bestScore = score;
      bestName = name;
    }
  }

  return bestScore > 0 ? bestName : null;
}

// LLM fallback for ambiguous tasks — calls tier1 Ollama model directly.
// Uses fetch (Node 22+), no npm dependencies.
async function classifyByLLM(task, profiles, tier1) {
  const profileNames = Object.keys(profiles).join(", ");
  const descriptions = Object.entries(profiles)
    .map(([name, p]) => `- ${name}: ${p.description}`)
    .join("\n");

  const body = JSON.stringify({
    model: tier1.model,
    messages: [
      {
        role: "user",
        content:
          `Classify the following task into exactly one of these profiles: ${profileNames}\n\n` +
          `Profiles:\n${descriptions}\n\n` +
          `Task: "${task}"\n\n` +
          `Respond with only the profile name, nothing else.`,
      },
    ],
    max_tokens: 10,
    stream: false,
  });

  const SAFE_BASE_URL = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/;
  if (!SAFE_BASE_URL.test(tier1.base_url)) {
    throw new Error(`Untrusted base_url for LLM classify: ${tier1.base_url}`);
  }

  const res = await fetch(`${tier1.base_url}/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
    signal: AbortSignal.timeout(8000),
  });

  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  const answer = data.choices?.[0]?.message?.content?.trim().toLowerCase();
  return profiles[answer] ? answer : null;
}

async function classify(task) {
  const config = await loadConfig();
  const { profiles, tier1 } = config;

  if (!task || task.trim() === "") {
    const name = DEFAULT_PROFILE in profiles ? DEFAULT_PROFILE : Object.keys(profiles)[0];
    return { name, profile: profiles[name] };
  }

  // 1. Keyword matching — deterministic, 0 tokens
  const byKeyword = classifyByKeywords(task, profiles);
  if (byKeyword) return { name: byKeyword, profile: profiles[byKeyword] };

  // 2. LLM fallback — for vague or composite requests
  if (tier1) {
    try {
      const byLLM = await classifyByLLM(task, profiles, tier1);
      if (byLLM) return { name: byLLM, profile: profiles[byLLM] };
    } catch (err) {
      process.stderr.write(`[gateway] LLM classify failed (${err.message}) — using default\n`);
    }
  }

  // 3. Default
  const name = DEFAULT_PROFILE in profiles ? DEFAULT_PROFILE : Object.keys(profiles)[0];
  return { name, profile: profiles[name] };
}

// ── CLI ───────────────────────────────────────────────────────────────────────

const task = process.argv[2] ?? "";
const { name, profile } = await classify(task);

process.stdout.write(
  JSON.stringify(
    {
      profile: name,
      model: profile.model,
      base_url: profile.base_url,
      opencode_model: `ollama/${profile.model}`,
      skill: profile.skill ?? null,
    },
    null,
    2
  ) + "\n"
);
