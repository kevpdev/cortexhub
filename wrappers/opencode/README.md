# CortexHub — OpenCode Wrapper

Expose les workflows CortexHub dans OpenCode avec routing automatique vers le bon modèle Ollama selon le type de tâche.

**Cas d'usage principal :** fallback CLI quand le quota Claude Code est épuisé — même workflow, modèle local, zéro reconfiguration.

## Prérequis

- [Ollama](https://ollama.com) installé et démarré
- [OpenCode](https://opencode.ai) installé (`npm install -g opencode-ai`)
- Node.js 18+
- CortexHub core installé (`./install.sh`)

## Install

```bash
./install.sh --opencode
```

Ce que ça fait :
- Copie `opencode.json` → `~/.config/opencode/opencode.json` (si inexistant)
- Symlink `~/.local/bin/oc` → `opencode-start.sh`

## Usage

```bash
# Avec routing automatique
oc "review my authentication PR"     # → code profile (qwen2.5-coder)
oc "triage my obsidian inbox"        # → vault profile (llama3.2)
oc "configure a systemd service"     # → daily profile (gemma3)
oc "extract text from this image"    # → ocr profile (minicpm-v)

# Sans argument — profil par défaut (code)
oc
```

## Routing

```
oc "task description"
      ↓
gateway.js — keywords (0 token, déterministe)
      ↓ pas de match
gateway.js — LLM tier1 (classifieur léger)
      ↓ fallback
profil par défaut : code
      ↓
opencode lancé avec ollama/<model>
```

## Modèles à installer

```bash
ollama pull qwen2.5-coder:7b-instruct-q4_K_M   # code (défaut)
ollama pull llama3.2:3b                          # vault / notes
ollama pull gemma3:4b                            # daily / shell
ollama pull minicpm-v:8b                         # ocr / vision
```

Voir `MODELS.md` pour la matrice complète et les commandes `num_ctx`.

## Étendre les profils

Ajouter un profil dans `~/.ai-core/config/providers.json` — le gateway le prend en compte sans redémarrage :

```json
"profiles": {
  "monprofil": {
    "description": "Ce que ce profil gère",
    "model": "mon-modele:tag",
    "base_url": "http://localhost:11434/v1",
    "skill": null,
    "triggers": ["mot-clé1", "mot-clé2"]
  }
}
```

## MCP

`opencode.json` connecte automatiquement le serveur MCP CortexHub si `--mcp` a été installé. Les tools `session_start`, `session_end`, `capture` et `route_completion` sont disponibles dans le chat OpenCode.

> ⚠️ **V1 — workflows probabilistes** : OpenCode n'a pas de système de hooks ni de slash commands natifs. Les workflows session/capture sont déclenchés par le modèle selon le contexte — fiables sur 14B+ (recommandé), dégradés sur 7/8B (machine limitée). Pour des workflows déterministes, utilise Claude Code ou Cursor.
>
> **Amélioration future** : hooks natifs OpenCode ou wrapper shell custom (`oc-session`, `oc-capture`) à ajouter en V1.1.

## Fichiers

| Fichier | Rôle |
|---|---|
| `gateway.js` | Classification tâche → profil Ollama |
| `opencode-start.sh` | Launcher avec routing (alias `oc`) |
| `opencode.json` | Config OpenCode : providers + MCP |
| `MODELS.md` | Matrice modèles × domaines + commandes pull |
