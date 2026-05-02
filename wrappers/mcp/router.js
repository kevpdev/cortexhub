import OpenAI from "openai";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const CONFIG_PATH = join(homedir(), ".ai-core", "config", "providers.json");

// task_type → tier mapping.
// 80% vault/notes → tier1, 15% code/analysis → tier2, 5% reasoning → tier3.
const ROUTING = {
  vault:        "tier1",
  capture:      "tier1",
  notes:        "tier1",
  summary:      "tier1",
  code:         "tier2",
  review:       "tier2",
  analysis:     "tier2",
  debug:        "tier2",
  architecture: "tier3",
  reasoning:    "tier3",
  planning:     "tier3",
};

export const TASK_TYPES = Object.keys(ROUTING);

let _configCache = null;

async function loadConfig() {
  if (_configCache) return _configCache;
  let raw;
  try {
    raw = await readFile(CONFIG_PATH, "utf-8");
  } catch {
    throw new Error(
      `providers.json not found at ${CONFIG_PATH}. Run: cp ~/.ai-core/config/providers.json.example ~/.ai-core/config/providers.json`
    );
  }

  let config;
  try { config = JSON.parse(raw); }
  catch { throw new Error(`providers.json is not valid JSON — check ${CONFIG_PATH}`); }

  // Resolve $ENV_VAR references in api_key at runtime — keys never in source.
  for (const tier of Object.values(config)) {
    if (typeof tier.api_key === "string" && tier.api_key.startsWith("$")) {
      tier.api_key = process.env[tier.api_key.slice(1)] ?? "";
    }
  }

  _configCache = config;
  return config;
}

export function resolveTier(task_type) {
  return ROUTING[task_type] ?? "tier2";
}

/**
 * Route a completion request to the appropriate provider tier.
 *
 * @param {object} opts
 * @param {string} opts.task_type  - Determines the tier (see ROUTING map)
 * @param {Array}  opts.messages   - OpenAI-format messages [{role, content}]
 * @param {number} [opts.max_tokens=2048]
 * @param {string} [opts.tier]     - Force a specific tier (overrides task_type)
 * @returns {{ tier, model, base_url, content, usage }}
 */
export async function routeCompletion({ task_type, messages, max_tokens = 2048, tier: forcedTier }) {
  if (max_tokens > 8192) throw new Error(`max_tokens ${max_tokens} exceeds limit of 8192`);
  const config = await loadConfig();
  const tier = forcedTier ?? resolveTier(task_type);
  const provider = config[tier];

  if (!provider) {
    throw new Error(`No provider configured for tier "${tier}". Check ${CONFIG_PATH}`);
  }

  const client = new OpenAI({
    baseURL: provider.base_url,
    // Ollama requires a non-empty string even without auth.
    apiKey: provider.api_key || "no-key",
  });

  const response = await client.chat.completions.create({
    model: provider.model,
    messages,
    max_tokens,
  });

  const choice = response.choices?.[0];
  if (!choice) throw new Error(`Provider returned no choices (model: ${provider.model})`);

  return {
    tier,
    model: provider.model,
    base_url: provider.base_url,
    content: choice.message.content,
    usage: response.usage ?? null,
  };
}
