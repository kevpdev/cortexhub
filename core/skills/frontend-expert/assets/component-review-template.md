# Template — Review de composant frontend

```markdown
## Verdict

🔴 À RETRAVAILLER  /  🟡 SUGGESTIONS  /  🟢 LGTM

**Framework détecté :** [React / Vue / Angular / Svelte]
**Contexte :** [POC / prod / composant partagé / page publique SEO]

---

## 🔴 Bloquants

- 🔴 **`<fichier>:<ligne>`** — <issue>
  **Pourquoi** : <impact UX / perf / bug>
  **Fix** :
  ```diff
  - <code actuel>
  + <code corrigé>
  ```

---

## 🟡 Suggestions

- 🟡 **`<fichier>:<ligne>`** — <suggestion>
  **Fix** : <description ou diff>

---

## 🟢 Points positifs

- <Pattern bien appliqué>

---

## Hors périmètre

- 🔒 Sécurité (XSS, CORS, auth) → `security-reviewer`
- 🏛️ Architecture API backend → `backend-architect`
- ✨ Qualité code générale → `code-reviewer`
```

## Catégories de review

| Catégorie | Points clés |
|---|---|
| Structure | SRP, props drilling évité, composition |
| Performance | mémoïsation utile, lazy loading, bundle |
| Accessibilité | rôles ARIA, navigation clavier, contraste |
| State | minimal, server state séparé, pas de duplication |
| Typage | props typées, pas de `any`, events typés |
