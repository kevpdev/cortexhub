# Migrations safe en production

## Principes fondamentaux

1. **Rendre les migrations réversibles** — toujours prévoir un rollback.
2. **Séparer la migration schema de la migration data** — deux déploiements distincts.
3. **Éviter les locks table** — utiliser `CONCURRENTLY`, `NOT VALID`, batches.
4. **Tester le temps d'exécution** sur un dump de prod avant le déploiement.

## Patterns safe

### Ajouter une colonne NOT NULL avec valeur par défaut

```sql
-- ❌ DANGEREUX en prod (lock + backfill synchrone)
ALTER TABLE users ADD COLUMN score INT NOT NULL DEFAULT 0;

-- ✅ En 3 étapes :

-- Étape 1 : nullable (instantané, 0 lock)
ALTER TABLE users ADD COLUMN score INT;

-- Étape 2 : backfill par batch (hors migration, sans lock)
UPDATE users SET score = 0 WHERE score IS NULL AND id BETWEEN $start AND $end;

-- Étape 3 : contrainte NOT NULL après backfill complet
ALTER TABLE users ALTER COLUMN score SET NOT NULL;
ALTER TABLE users ALTER COLUMN score SET DEFAULT 0;
```

### Renommer une colonne

```sql
-- ❌ DANGEREUX : rompt immédiatement l'app qui lit l'ancien nom
ALTER TABLE users RENAME COLUMN old_name TO new_name;

-- ✅ Expand/Contract en 3 déploiements :
-- Deploy 1 : ajouter new_name, écrire dans les deux
ALTER TABLE users ADD COLUMN new_name VARCHAR;
-- Deploy 2 : migrer les données + app lit new_name
UPDATE users SET new_name = old_name WHERE new_name IS NULL;
-- Deploy 3 : supprimer old_name (après validation)
ALTER TABLE users DROP COLUMN old_name;
```

### Ajouter un index

```sql
-- ❌ Lock TABLE en écriture pendant la création
CREATE INDEX idx_users_email ON users(email);

-- ✅ Non-bloquant
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
-- Note : CONCURRENTLY ne peut pas être dans une transaction
```

### Ajouter une contrainte FK

```sql
-- ❌ Valide toutes les rows existantes + lock
ALTER TABLE orders ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id);

-- ✅ NOT VALID + validate séparé (lock plus court)
ALTER TABLE orders ADD CONSTRAINT fk_user
    FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;
-- Plus tard (maintenance window) :
ALTER TABLE orders VALIDATE CONSTRAINT fk_user;
```

### Supprimer une colonne

```sql
-- ❌ Supprimer directement si l'app lit encore cette colonne
ALTER TABLE users DROP COLUMN old_email;

-- ✅ Expand/Contract :
-- Deploy 1 : retirer toute lecture de la colonne dans l'app
-- Deploy 2 : DROP (maintenant safe)
ALTER TABLE users DROP COLUMN old_email;
```

## Flyway / Liquibase — bonnes pratiques

- **Toujours** inclure un script de rollback (`undo` Flyway Pro, `rollback` Liquibase)
- **Nommer** : `V<version>__<description_underscored>.sql`
- **Ne jamais** modifier une migration déjà appliquée en prod — créer une nouvelle
- **Tester** sur un snapshot de prod avant le déploiement
- **Séparer** les grandes migrations data (> 1M rows) du déploiement app → job batch indépendant

## Checklist avant migration prod

- [ ] Migration testée sur dump récent de prod
- [ ] Temps d'exécution estimé (< 30s sans fenêtre, sinon planifier)
- [ ] Aucun `ALTER TABLE` sans `CONCURRENTLY` ni `NOT VALID`
- [ ] Rollback script disponible et testé
- [ ] Monitoring activé (Datadog, PG logs, slow query log)
- [ ] Application en backward-compat (tolère ancien ET nouveau schéma pendant le déploiement)
