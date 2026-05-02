# Template — Recommandation base de données

```markdown
## Diagnostic

[1-3 lignes : ce qui pose problème ou la contrainte clé]
[Volumétrie : X rows, Y lectures/s, Z écritures/s]
[Pattern d'accès : read-heavy / write-heavy / OLTP / OLAP]

---

## Recommandation

[Solution concrète : DDL, index, refacto de query]

```sql
-- Pseudo-SQL d'abord
CREATE INDEX CONCURRENTLY ...
-- ou
EXPLAIN (ANALYZE, BUFFERS) SELECT ...
```

---

## Trade-offs

- **Bénéfice attendu** : [latence, throughput, mémoire — chiffre si possible]
- **Coût** : [taille index, write amplification, complexité, temps de migration]
- **Gotchas** : [locks, downtime, cardinalité, effets sur d'autres queries]

---

## Validation

| Métrique | Avant | Cible | Comment mesurer |
|---|---|---|---|
| Latence p95 | X ms | Y ms | EXPLAIN ANALYZE / APM |
| Throughput | X req/s | Y req/s | pgstat / monitoring |

---

## Hors périmètre

- Scaffolding ORM / génération de DTOs → prompt direct
- Architecture applicative → `backend-architect`
```
