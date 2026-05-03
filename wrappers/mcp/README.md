# CortexHub MCP Server

Expose le core CortexHub comme outils MCP — scripts de session, skills experts et router multi-modèles — utilisables par Claude Code, Cursor, Continue.dev, Open WebUI, ou tout client MCP.

## Prérequis

- Node.js 24+ (LTS)
- pnpm (`corepack enable` suffit — Node l'inclut nativement)
- CortexHub installé (`~/.ai-core/` doit exister)

## Installation

```bash
# Via install.sh (recommandé)
./install.sh --mcp

# Manuel
corepack enable        # une seule fois par machine
cd wrappers/mcp && pnpm install
```

## Connexion à Claude Code

```bash
claude mcp add cortexhub -- node ~/.ai-core/mcp/server.js
```

Ou dans `.mcp.json` du projet :

```json
{
  "mcpServers": {
    "cortexhub": {
      "command": "node",
      "args": ["~/.ai-core/mcp/server.js"]
    }
  }
}
```

## Connexion à Cursor

Dans `.cursor/mcp.json` (projet) ou `~/.cursor/mcp.json` (global) :

```json
{
  "mcpServers": {
    "cortexhub": {
      "command": "node",
      "args": ["/home/<user>/.ai-core/mcp/server.js"]
    }
  }
}
```

## Connexion à Continue.dev

Dans `~/.continue/config.json` :

```json
{
  "mcpServers": [
    {
      "name": "cortexhub",
      "command": "node",
      "args": ["/home/<user>/.ai-core/mcp/server.js"]
    }
  ]
}
```

## Connexion à Open WebUI

1. Settings → Tools → MCP Servers
2. Ajouter :
   ```
   Command : node
   Args    : /home/<user>/.ai-core/mcp/server.js
   ```
3. Activer les tools dans le chat

## Variable d'environnement

`CORTEXHUB_PROJECT` — chemin du projet par défaut si `project_path` n'est pas passé dans les args du tool.

```bash
export CORTEXHUB_PROJECT=/path/to/my-project
```

## Tools exposés

| Tool | Description | Params requis |
|---|---|---|
| `session_start` | Charge le contexte / fixe le focus | `goal?` |
| `session_end` | Sauvegarde la session | `accomplished`, `next` |
| `capture` | Note rapide dans le memory-bank | `note` |
| `memory_bank_init` | Initialise `.ai-local/memory-bank/` | `mode` (solo\|shared) |
| `memory_bank_setup` | Configure l'agent cible | `agent?` (claude\|cursor\|windsurf) |
| `list_skills` | Liste les skills disponibles | — |
| `get_skill` | Retourne les instructions d'un skill | `name` |
| `route_completion` | Délègue une completion au bon modèle | `task_type`, `messages` |

Tous acceptent `project_path` (optionnel) pour cibler un projet spécifique.
