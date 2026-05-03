# CortexHub — Claude Code Wrapper

Expose les workflows CortexHub comme slash commands natives dans Claude Code, avec auto-load du memory-bank et hook de suggestion de skills.

## Install

```bash
./install.sh
```

Ce que ça fait :
- Symlinks `~/.claude/commands/` → `wrappers/claude/commands/`
- Symlinks `~/.claude/skills/` → `core/skills/` (via wrapper stubs)
- Injecte le snippet memory-bank dans `~/.claude/CLAUDE.md`
- Ajoute le hook `suggest-skill` dans `~/.claude/settings.json`

## Slash commands disponibles

| Commande | Description |
|---|---|
| `/session-start [goal]` | Charge le contexte, fixe l'objectif de session |
| `/session-end` | Sauvegarde progress et next steps |
| `/capture <note>` | Note rapide sans casser le flow |
| `/memory-bank-init` | Initialise `.ai-local/memory-bank/` — neutre, zéro mention agent |
| `/memory-bank-setup [agent]` | Configure l'agent courant pour lire le memory-bank |
| `/plan <description>` | Explore + plan détaillé, s'arrête avant le code |
| `/epct <description>` | Implémente un plan validé — Code + Test uniquement |
| `/create-pull-request` | Crée une PR avec titre/description auto |
| `/fix-pr-comments` | Implémente tous les review comments d'une PR |
| `/watch-ci` | Monitore la CI et auto-fix jusqu'au vert |
| `/run-tasks` | Exécute des issues GitHub avec EPCT + PR auto |
| `/plan-to-stories` | Découpe un plan en stories |
| `/story-create` | Crée une story interactivement |
| `/init-node-ts` | Initialise un projet Node.js TypeScript |

## Hook suggest-skill

À chaque réponse, Claude vérifie si un skill core est pertinent pour la tâche en cours et le suggère automatiquement. Les skills disponibles : `code-reviewer`, `security-reviewer`, `backend-architect`, `frontend-expert`, `database-expert`.

## Prérequis

- Claude Code CLI installé
- `~/.ai-core/` installé (étape 1 de `install.sh`)
- `git` et `gh` CLI pour les commandes PR/CI
