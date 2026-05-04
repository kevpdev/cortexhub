# Agent Routing — déclenchement déterministe des agents/skills

## Pourquoi

Sans routage explicite, Claude rate régulièrement le déclenchement de sous-agents évidents (génère la doc inline au lieu d'appeler `doc-writer`, ignore `security-reviewer` sur un audit, etc.). Causes typiques :

- Biais "je peux le faire moi-même"
- Phrasing utilisateur ambigu
- Descriptions d'agents trop génériques
- Suggestions trop polies → ignorées

**Solution** : un classifier déterministe qui s'exécute dans le hook `UserPromptSubmit`, lit `core/config/agent-routing.json`, et injecte un message — impératif (`force: true`) ou suggestif (`force: false`) — avant que Claude ne traite le prompt.

## Fonctionnement

```
prompt utilisateur
       ↓
hook UserPromptSubmit (suggest-skill.sh)
   ├─ lit core/config/agent-routing.json
   ├─ matche regex sur le prompt (lowercase)
   └─ injecte additionalContext si match (première règle gagne)
       ↓
Claude reçoit prompt + injection
   └─ délègue à l'agent/skill ciblé
```

Multi-provider gratuit : le hook tourne **avant** Claude. Compatible Claude CLI seul, Claude CLI + Ollama (Phase 10), Cursor (via wrapper équivalent à venir), OpenCode.

## Format des règles

Fichier : `core/config/agent-routing.json` (créé depuis `.example` à l'install).

```json
{
  "rules": [
    {
      "id": "doc-generation",
      "match": { "regex": "documente|javadoc|jsdoc|readme" },
      "target": { "type": "agent", "name": "doc-writer" },
      "force": true,
      "reason": "Génération de doc — déléguer systématiquement."
    }
  ]
}
```

### Champs

| Champ | Type | Description |
|---|---|---|
| `id` | string | Identifiant unique (kebab-case). |
| `match.regex` | string | Pattern POSIX étendu, matché contre le prompt en lowercase. **Obligatoire en V1.** |
| `match.files_changed` | array | *Réservé V2 — non évalué.* Globs sur fichiers modifiés. |
| `match.tools` | array | *Réservé V2 — non évalué.* Outils utilisés (Edit, Write…). |
| `target.type` | enum | `agent` (déléguer via Task tool) ou `skill` (charger via `/skill <name>`). |
| `target.name` | string | Nom de l'agent ou du skill. |
| `force` | bool | `true` → message impératif. `false` → suggestion. Défaut `false`. |
| `reason` | string | Affichée à Claude **et** à l'utilisateur (transparence). |

### Évaluation

- Les règles sont évaluées dans l'ordre du fichier
- **Première règle qui matche gagne**, les suivantes sont ignorées
- L'ordre = la priorité → mettre les règles `force: true` les plus critiques en haut

## Ajouter une règle

1. Éditer `~/.ai-core/config/agent-routing.json`
2. Ajouter une entrée dans le tableau `rules`
3. Valider : `bash ~/.ai-core/scripts/doctor.sh`
4. Tester : `echo '{"prompt":"<exemple>"}' | bash ~/.ai-core/scripts/suggest-skill.sh`

## Règles par défaut

Voir `core/config/agent-routing.json.example` :

| id | force | target | trigger résumé |
|---|---|---|---|
| `doc-generation` | ✅ | agent `doc-writer` | javadoc, jsdoc, README, documente |
| `security-audit` | ✅ | skill `security-reviewer` | sécurité, OWASP, vulnérabilité, injection |
| `code-review` | ❌ | skill `code-reviewer` | review, qualité, SOLID, refactor |
| `frontend-expertise` | ❌ | skill `frontend-expert` | React, Vue, SSR, a11y, web vitals |
| `database-expertise` | ✅ | skill `database-expert` | SQL, index, migration, EXPLAIN |
| `backend-architecture` | ❌ | skill `backend-architect` | REST, GraphQL, DDD, hexagonal |

## Quand utiliser `force: true` vs `false`

- **`true`** → règle évidente, expertise systématiquement requise (doc, sécurité, migrations DB). Claude doit déléguer.
- **`false`** → expertise utile mais pas impérative (review qualité, choix d'archi). Claude reste libre selon le contexte.

Trop de `force: true` → friction excessive. Réserver aux cas où une non-délégation est un vrai bug.

## Fallback

Si `agent-routing.json` est absent ou si `jq` n'est pas installé, le script bascule sur les regex hardcodées historiques (mode legacy `💡 Skill disponible`). Aucune régression.

## Limites V1

- `files_changed` et `tools` sont schématisés mais **non évalués** (le payload `UserPromptSubmit` ne les fournit pas). V2 prévu pour exploiter le hook `Stop` ou `PreToolUse`.
- Pas de classifier LLM en fallback pour les requêtes vagues. Ajout possible en V2 si les regex se révèlent insuffisantes (cf. `wrappers/opencode/gateway.js` pour le pattern).

## Liens

- ADR : `1 PROJECTS/CORTEXHUB/decisions/agent-routing-deterministe.md` (vault)
- Schema : `core/config/agent-routing.schema.json`
- Hook : `core/scripts/suggest-skill.sh`
- Référence pattern : `wrappers/opencode/gateway.js`
