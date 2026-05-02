# Patterns d'indexing — PostgreSQL

## Règles de base

1. **Index sur les colonnes WHERE fréquentes** — commence par là.
2. **Index composite** : ordre des colonnes = ordre d'utilisation dans WHERE (colonne la plus sélective en premier).
3. **Index partiel** : si la query filtre toujours sur une condition fixe (`WHERE deleted_at IS NULL`).
4. **Index covering** : inclure les colonnes SELECT pour éviter le heap lookup.
5. **Surveiller la cardinalité** : index sur une colonne booléenne = inutile (2 valeurs possibles).

## Patterns courants

### Recherche par foreign key (le plus fréquent)
```sql
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
-- Couvre : WHERE user_id = $1, JOIN orders ON orders.user_id = users.id
```

### Index composite (multi-colonnes)
```sql
-- Query : WHERE status = 'pending' AND created_at > $1 ORDER BY created_at
CREATE INDEX CONCURRENTLY idx_orders_status_created
    ON orders(status, created_at DESC);
-- Règle : colonne d'égalité (=) avant colonne de range (>, <, BETWEEN)
```

### Index partiel (filtre permanent)
```sql
-- Query : WHERE user_id = $1 AND deleted_at IS NULL
CREATE INDEX CONCURRENTLY idx_orders_active_user
    ON orders(user_id)
    WHERE deleted_at IS NULL;
-- Plus petit, plus rapide que l'index full
```

### Index covering (INCLUDE)
```sql
-- Query : SELECT status, total FROM orders WHERE user_id = $1
CREATE INDEX CONCURRENTLY idx_orders_user_covering
    ON orders(user_id)
    INCLUDE (status, total);
-- Évite le heap lookup — tout est dans l'index
```

### Full-text search
```sql
-- Ajouter colonne tsvector ou utiliser gin/gist
CREATE INDEX CONCURRENTLY idx_products_search
    ON products USING gin(to_tsvector('french', name || ' ' || description));
-- Query : WHERE to_tsvector('french', name) @@ plainto_tsquery('french', $1)
```

## Diagnostics

```sql
-- Indexes inutilisés (à supprimer)
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexname NOT LIKE '%pkey%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Tables sans index sur FK (N+1 potentiel)
SELECT conrelid::regclass AS table, a.attname AS column
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );
```

## Coûts et trade-offs

| Type | Gain | Coût |
|---|---|---|
| B-tree standard | Équilibré | Taille ≈ 10-20% table |
| Index partiel | Très rapide sur sous-ensemble | Inutile si filtre rare |
| GIN (full-text, jsonb) | Puissant sur données complexes | Write amplification élevée |
| Index composite | Élimine plusieurs scans | Lourd si colonnes peu sélectives |
| Index covering | 0 heap lookup | Espace disque augmenté |
