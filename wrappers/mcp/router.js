/**
 * Routes LLM completions to the appropriate provider tier (1/2/3) based on task type, with fallback chain.
 */

import OpenAI from "openai";
import { readFile, appendFile, mkdir } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const CONFIG_PATH = join(homedir(), ".ai-core", "config", "providers.json");
const LOGS_DIR    = join(homedir(), ".ai-core", "logs");
const LOG_FILE    = join(LOGS_DIR, "router.log");

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

/**
 * Loads and caches providers.json. Resolves `$ENV_VAR` references in api_key at runtime.
 * @returns {Promise<object>} Config indexed by tier (tier1/tier2/tier3).
 * @throws {Error} If file is missing or invalid JSON.
 */
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

// Logging is best-effort — a write failure must never block a completion.
async function logUsage({ tier, model, base_url, usage, fallback_from }) {
  try {
    await mkdir(LOGS_DIR, { recursive: true });
    const entry = JSON.stringify({
      ts: new Date().toISOString(),
      tier,
      model,
      base_url,
      tokens: usage?.total_tokens ?? null,
      fallback_from: fallback_from ?? null,
    });
    await appendFile(LOG_FILE, entry + "\n");
  } catch { /* silent */ }
}

/**
 * Maps task_type to the target tier. Defaults to tier2 if unmapped.
 * @param {string} task_type - Task category (vault, code, reasoning, etc.).
 * @returns {string} Tier name (tier1, tier2, or tier3).
 */
export function resolveTier(task_type) {
  return ROUTING[task_type] ?? "tier2";
}

/**
 * Route a completion request to the appropriate provider tier.
 * On failure, follows the `fallback` chain defined in providers.json.
 *
 * @param {object} opts
 * @param {string} opts.task_type  - Determines the tier (see ROUTING map)
 * @param {Array}  opts.messages   - OpenAI-format messages [{role, content}]
 * @param {number} [opts.max_tokens=2048]
 * @param {string} [opts.tier]     - Force a specific tier (overrides task_type)
 * @returns {{ tier, model, base_url, content, usage, fallback_from }}
 */
export async function routeCompletion({ task_type, messages, max_tokens = 2048, tier: forcedTier }) {
  if (max_tokens > 8192) throw new Error(`max_tokens ${max_tokens} exceeds limit of 8192`);

  const config    = await loadConfig();
  const startTier = forcedTier ?? resolveTier(task_type);

  let currentTier = startTier;
  let lastError;

  while (currentTier) {
    const provider = config[currentTier];
    if (!provider) throw new Error(`No provider configured for tier "${currentTier}". Check ${CONFIG_PATH}`);

    try {
      const client = new OpenAI({
        baseURL: provider.base_url,
        apiKey:  provider.api_key || "no-key",
      });

      const response = await client.chat.completions.create({
        model: provider.model,
        messages,
        max_tokens,
      });

      const choice = response.choices?.[0];
      if (!choice) throw new Error(`Provider returned no choices (model: ${provider.model})`);

      const fallback_from = currentTier !== startTier ? startTier : null;
      await logUsage({ tier: currentTier, model: provider.model, base_url: provider.base_url, usage: response.usage, fallback_from });

      return {
        tier: currentTier,
        model: provider.model,
        base_url: provider.base_url,
        content: choice.message.content,
        usage: response.usage ?? null,
        fallback_from,
      };
    } catch (err) {
      lastError = err;
      const nextTier = provider.fallback;
      if (nextTier) {
        process.stderr.write(`[cortexhub] ${currentTier} failed (${err.message}) → trying ${nextTier}\n`);
        currentTier = nextTier;
      } else {
        break;
      }
    }
  }

  throw new Error(`All providers failed. Last error: ${lastError?.message}`);
}
