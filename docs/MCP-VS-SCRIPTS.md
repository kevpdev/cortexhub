# CortexHub — MCP vs Scripts directs

## Règle générale

> Les scripts `~/.ai-core/scripts/` sont l'API publique. Les wrappers les appellent **directement**. Le MCP est un consommateur spécialisé, pas la couche obligatoire.

## Quand appeler les scripts directement

C'est le cas par défaut pour tous les wrappers Tier 1 :

- Claude Code (`wrappers/claude/commands/*.md`)
- Cursor (`wrappers/cursor/commands/*.md`)
- Continue.dev (`wrappers/continue/config.ts`)

L'agent lit la commande/règle → exécute le script via le terminal → affiche le résultat.

**Avantages**
- Aucune dépendance serveur — fonctionne offline, sans processus en arrière-plan
- Debugging direct : `bash ~/.ai-core/scripts/session-start.sh --read`
- Ajouter un agent = écrire un wrapper, zéro impact sur les autres
- Conforme à la vision antifragile du projet

## Quand utiliser le MCP

Réservé aux cas où le shell n'est pas accessible ou où le MCP apporte une valeur unique :

| Cas d'usage | Pourquoi MCP |
|---|---|
| `route_completion` (routing tier1→2→3 + fallback) | Nécessite un process long-running pour gérer les connexions providers et les retries |
| Agents browser-based (Open WebUI) | Pas d'accès shell depuis un navigateur — MCP est le seul pont possible |
| Tool discovery automatique | L'agent voit les tools disponibles sans lire de fichiers de config |

## Ce que le MCP n'est PAS

- Une couche d'abstraction obligatoire entre les wrappers et les scripts
- Un SPOF qu'on force pour "avoir une architecture uniforme"
- Un remplacement des wrappers natifs par agent

## Diagramme

```
~/.ai-core/scripts/         ← API publique stable
        ↑           ↑           ↑
   wrappers/    wrappers/   wrappers/      ← consommateurs directs
    claude/      cursor/    continue/
                                    ↑
                               wrappers/mcp/  ← consommateur spécialisé
                                              (route_completion, Open WebUI)
```

## Règle de décision

```
L'agent peut-il exécuter du shell ?
  OUI → appelle le script directement
  NON → utilise le MCP
```
