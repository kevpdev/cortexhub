# Template — Rapport de review sécurité

```markdown
## Verdict

🔴 BLOQUE  /  🟡 NEEDS FIX  /  🟢 LGTM avec suggestions

**Contexte assumé :** [POC interne / staging / prod publique / données régulées PII-PCI-HIPAA]
**Stack identifiée :** [Java/Spring | Node/Express | autre]

---

## 🔴 Critical (à fixer avant merge / déploiement)

- 🔴 **`<fichier>:<ligne>`** — <issue concise>
  **Risk** : <exploit concret possible — comment un attaquant l'utilise>
  **Ref** : OWASP A0X:2021 — <Catégorie>
  **Fix** :
  ```diff
  - <code vulnérable>
  + <code sécurisé>
  ```

---

## 🟡 Risk (defense-in-depth, à fixer rapidement)

- 🟡 **`<fichier>:<ligne>`** — <issue>
  **Risk** : <impact si combiné à autre faille>
  **Fix** : <description courte ou diff>

---

## 🟢 Notes (bonnes pratiques, optionnel)

- <pattern à appliquer pour renforcement>

---

## Hors périmètre

- 🔍 Scan de dépendances : utiliser `npm audit` / `mvn dependency-check` / Snyk.
- 🌐 Pentest dynamique : utiliser ZAP / Burp / nuclei.
- 📐 Décisions d'architecture (auth flow, design d'API) : utiliser `backend-architect`.
- ✨ Qualité du code (SOLID, naming, perf) : utiliser `code-reviewer`.

---

## Validation

Le fix est correct si :
- [ ] Plus de concaténation user → SQL/HTML/shell
- [ ] Tous les endpoints sensibles ont un guard d'authz testé
- [ ] Aucun secret en dur ni dans les logs
- [ ] Headers CSP / HSTS / SameSite vérifiés en runtime
```

## Rappels

- **Toujours** un fix concret pour chaque 🔴
- **Toujours** citer la ref OWASP quand applicable
- **Toujours** décrire l'**exploit concret**, pas juste "c'est mauvais"
- **Adapter** la sévérité au contexte (POC ≠ prod)
- **Ne pas** dupliquer les checks de `code-reviewer`
