# OpenCode — Model Matrix

Models configured in CortexHub for OpenCode + Ollama.

## Profiles (automatic routing via gateway)

| Profile | Model | Use case | Triggers (examples) |
|---|---|---|---|
| `code` | `qwen2.5-coder:7b-instruct-q4_K_M` | Code gen, review, debug | code, review, PR, bug, test, refactor |
| `vault` | `llama3.2:3b` | Notes, triage, writing | note, vault, triage, inbox, summary |
| `daily` | `gemma3:4b` | Shell, config, system | install, script, shell, config, setup |
| `ocr` | `minicpm-v:8b` | Vision, OCR, images | image, scan, ocr, screenshot, extract |

## Tiers (MCP router — capacity-based)

| Tier | Model | Use case |
|---|---|---|
| tier1 (fast) | `qwen2.5-coder:7b-instruct-q4_K_M` | Simple tasks, vault, notes |
| tier2 (standard) | `qwen2.5-coder:14b-instruct-q8_0` | Code, analysis, review |
| tier3 (complex) | `qwen2.5-coder:32b-instruct-q3_K_M` | Architecture, reasoning |

## Routing logic

```
opencode-start.sh "task description"
        ↓
gateway.js — keyword match (0 tokens)
        ↓ no match
gateway.js — LLM classify via tier1 (lightweight call)
        ↓ fallback
default profile: code
        ↓
opencode launched with ollama/<model>
```

## Required Ollama models

Pull before first use:

```bash
# Profiles
ollama pull qwen2.5-coder:7b-instruct-q4_K_M
ollama pull llama3.2:3b
ollama pull gemma3:4b
ollama pull minicpm-v:8b

# Tier 2 and 3 (optional, heavier)
ollama pull qwen2.5-coder:14b-instruct-q8_0
ollama pull qwen2.5-coder:32b-instruct-q3_K_M
```

## Context window

Ollama defaults to 4K context — increase for tool use:

```bash
ollama run qwen2.5-coder:7b-instruct-q4_K_M
/set parameter num_ctx 16384
/save qwen2.5-coder:7b-instruct-q4_K_M
```

## Extending profiles

Add a new profile in `~/.ai-core/config/providers.json`:

```json
"profiles": {
  "myprofile": {
    "description": "What this profile handles",
    "model": "my-model:tag",
    "base_url": "http://localhost:11434/v1",
    "skill": "my-skill-name-or-null",
    "triggers": ["keyword1", "keyword2"]
  }
}
```

No code changes needed — gateway reads profiles dynamically.
