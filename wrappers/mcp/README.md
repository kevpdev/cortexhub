# CortexHub MCP Server

Expose les scripts core CortexHub (`session-start`, `session-end`, `capture`, `memory-bank-init`, `memory-bank-setup`) comme outils MCP — utilisables par Claude Code, Open WebUI, Cursor, Windsurf, ou tout client MCP.

## Prérequis

- Node.js 18+
- CortexHub installé (`~/.ai-core/` doit exister)

## Installation

```bash
# Via install.sh (recommandé)
./install.sh --mcp

# Manuel
cd wrappers/mcp && npm install
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
| `route_completion` | Délègue une completion au bon modèle | `task_type`, `messages` |

Tous acceptent `project_path` (optionnel) pour cibler un projet spécifique.
