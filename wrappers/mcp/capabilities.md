# CortexHub MCP — Capabilities audit

Matrice des tools core vs support natif par agent cible.
Mise à jour avant chaque implémentation de wrapper.

## Règle

Ne jamais wrapper ce qui existe déjà nativement — friction inutile.
Le MCP complète ; il ne duplique pas.

---

## Matrice

| Tool core | Claude Code | Open WebUI / Ollama | Cursor | Windsurf |
|---|---|---|---|---|
| `session_start` | `/session-start` (skill natif) | ✗ absent | ✗ absent | ✗ absent |
| `session_end` | `/session-end` (skill natif) | ✗ absent | ✗ absent | ✗ absent |
| `capture` | `/capture` (skill natif) | ✗ absent | ✗ absent | ✗ absent |
| `memory_bank_init` | `/memory-bank-init` (skill natif) | ✗ absent | ✗ absent | ✗ absent |
| `memory_bank_setup` | `/memory-bank-setup` (skill natif) | ✗ absent | ✗ absent | ✗ absent |

**Légende :** ✓ natif (skip wrapper) — ✗ absent (wrapper MCP utile)

---

## Décision par agent

### Claude Code
Les 5 tools ont un skill natif. Le wrapper MCP reste utile pour :
- Les appeler **programmatiquement** depuis un autre agent dans un pipeline multi-modèles
- Exposer les tools à un orchestrateur externe

→ MCP installé en option, pas par défaut pour Claude Code pur.

### Open WebUI / Ollama
Aucun équivalent natif. MCP = seul vecteur pour ces tools.
→ Cible principale du wrapper MCP.

### Cursor / Windsurf
Pas de skills system. MCP supporté via `.cursor/mcp.json` / `.windsurfrules`.
→ MCP pertinent pour ces agents.

---

## Client MCP — support confirmé

| Client | Support MCP | Notes |
|---|---|---|
| Claude Code | ✓ natif | `claude mcp add` ou `.mcp.json` |
| Open WebUI | ✓ (≥ 0.4) | Config Tools → MCP Servers |
| Cursor | ✓ (`.cursor/mcp.json`) | Projet ou global |
| Windsurf | ✓ (`.windsurfrules` + MCP) | En cours de déploiement |
| LM Studio | Partiel | API OpenAI-compat uniquement pour l'instant |
| Jan | ✗ | Pas encore supporté |

---

_Mis à jour : 2026-05-02_
