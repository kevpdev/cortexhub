# Template de rapport — Code Review

À utiliser comme structure de sortie systématique.

```markdown
## Verdict

🔴 À RETRAVAILLER  /  🟡 SUGGESTIONS  /  🟢 LGTM

**Contexte assumé :** [POC / prod / legacy / feature flag] — adapte le niveau d'exigence.

---

## 🔴 Bloquants (à fixer avant merge)

- 🔴 **`<fichier>:<ligne>`** — <issue concise>
  **Pourquoi** : <raison technique>
  **Fix** :
  ```diff
  - <code actuel>
  + <code corrigé>
  ```

---

## 🟡 Suggestions (nice-to-have)

- 🟡 **`<fichier>:<ligne>`** — <suggestion>
  **Fix** : <description courte ou diff>

---

## 🟢 Points positifs

- <Pattern bien appliqué>
- <Décision pertinente>

---

## Hors périmètre

- 🔒 Sécurité : utiliser `security-reviewer` si auth, injection ou secrets touchés.
- 🏛️ Architecture : utiliser `backend-architect` / `frontend-expert` si refonte structurelle envisagée.
```

## Rappels

- **Toujours** un fix concret pour chaque 🔴
- **Jamais** dépasser ~300 mots de prose ; le détail va dans les issues localisées
- **Distinguer** bloquant 🔴 de suggestion 🟡 — un dev doit savoir quoi merger
- **Adapter** au contexte : un POC ne mérite pas le même verdict qu'une feature en prod critique
