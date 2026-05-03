---
description: Synchronise le projet courant vers sa documentation dans le vault Obsidian
argument-hint: [--dry-run]
---

Synchronise le projet dev courant vers le vault Obsidian. Gère la configuration automatiquement si absente.

## Étape 1 — Vérifier la variable d'environnement

Exécute `echo $OBSIDIAN_VAULT_PRO` pour lire la variable d'environnement.

Si vide ou non définie, afficher :

```
❌ Variable $OBSIDIAN_VAULT_PRO non définie.

Ajoute cette ligne à ton ~/.zshrc :
  export OBSIDIAN_VAULT_PRO="/chemin/absolu/vers/MyObsidianProVault"

  # Vault perso (optionnel) :
  export OBSIDIAN_VAULT_PERSO="/chemin/absolu/vers/MyObsidianVault"

Puis recharge le shell :
  source ~/.zshrc   # ou : zs

Relance ensuite /vault-sync-from-dev.
```

S'arrêter ici.

## Étape 2 — Vérifier si .claude/vault-sync.json existe

Chercher `.claude/vault-sync.json` dans le répertoire courant.

Si le fichier existe :
- Le lire et extraire `project`
- Vérifier que `$OBSIDIAN_VAULT_PRO/3 PROJECTS/{project}/` existe encore
- Si le dossier vault n'existe plus → traiter comme absent (refaire la sélection)
- Sinon → sauter l'étape 3, aller directement à l'étape 4

## Étape 3 — Sélection interactive du projet vault

Lister les dossiers dans `$OBSIDIAN_VAULT_PRO/3 PROJECTS/` avec :

```bash
ls -1 "$OBSIDIAN_VAULT_PRO/3 PROJECTS/"
```

Afficher le menu :

```
📁 Projets vault disponibles à lier :

  1. NOM-PROJET-A
  2. NOM-PROJET-B
  ...
  0. Aucun — annuler

À quel projet vault ce projet dev correspond-il ?
```

**Si l'utilisateur répond un numéro valide :**
- Retenir le projet sélectionné
- Inspecter le répertoire courant pour proposer des mappings par défaut :
  - Chercher `README.md` → mapper vers `project-note.md#Vue d'ensemble`
  - Chercher `docs/architecture.md` → mapper vers `project-note.md#Contexte technique`
  - Chercher `CHANGELOG.md` → mapper vers `project-note.md#Historique`
- Si `.claude/` n'existe pas dans le répertoire courant → le créer avec `mkdir -p .claude`
- Créer `.claude/vault-sync.json` avec ces mappings (uniquement les sources qui existent)
- Afficher le fichier créé et demander confirmation avant de poursuivre :

```
✅ .claude/vault-sync.json créé :

{contenu du fichier}

Continuer la synchronisation ? (oui / modifier d'abord)
```

**Si l'utilisateur répond `0` ou "aucun" :**

```
⏸️  Synchronisation annulée.

Pour créer le projet dans le vault :
  /vault:new-project NOM-PROJET                   # projet seul
  /vault:new-project NOM-PROJET 3                 # projet + lien sprint

Puis relance /vault-sync-from-dev pour lier ce projet dev.
```

S'arrêter ici.

## Étape 4 — Détecter le mode

Inspecter `$ARGUMENTS` :
- Si `--dry-run` présent → mode DRY-RUN
- Si `dry_run_by_default: true` dans `.claude/vault-sync.json` → mode DRY-RUN
- Sinon → mode LIVE

## Étape 5 — Déléguer à l'agent vault-sync

Lancer l'agent `vault-sync` en lui fournissant :
- Le contenu complet de `.claude/vault-sync.json`
- La valeur de `$OBSIDIAN_VAULT_PRO`
- Le mode (LIVE ou DRY-RUN)
- Le répertoire courant absolu (pour résoudre les chemins `source`)
