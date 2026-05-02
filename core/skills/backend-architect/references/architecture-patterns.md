# Patterns d'architecture backend

## Hexagonal (Ports & Adapters)

**Principe :** le domaine métier au centre, les I/O (DB, HTTP, messaging) en périphérie via des interfaces.

```
[ HTTP Controller ] ---→ [ Port d'entrée (interface) ] ---→ [ Use Case / Service ]
                                                                      ↓
[ Repository Interface ] ←--- [ Port de sortie ] ←--- [ Adapter JPA / Mongo ]
```

**Quand :** domaine métier complexe, tests d'isolation nécessaires, changements d'infra fréquents.
**Signal de prématurité :** < 3 entités métier, pas de règles métier complexes → CRUD classique suffit.

## DDD (Domain-Driven Design)

**Vocabulaire essentiel :**
- **Aggregate** : grappe d'entités avec racine cohérente (ex: `Order` + `OrderLine`)
- **Value Object** : immuable, identifié par valeur (ex: `Money`, `Email`)
- **Repository** : abstraction de persistance par aggregate
- **Domain Event** : fait métier passé (ex: `OrderPlaced`, `PaymentFailed`)
- **Bounded Context** : périmètre métier avec son propre langage ubiquitaire

**Quand :** domaine complexe, équipes multiples, logique métier dense.
**Signal de prématurité :** CRUD sans règles métier → active record pattern suffit.

## CQRS (Command Query Responsibility Segregation)

**Principe :** séparer les chemins de lecture (Query) et d'écriture (Command).

```
Client → Command → CommandHandler → Write Model → Event Store / DB
Client ← Query  ← QueryHandler  ← Read Model (view optimisée)
```

**Quand :** lectures et écritures avec des besoins très différents, event sourcing, scalabilité asymétrique.
**Signal de prématurité :** même schéma pour lire et écrire sans problème de perf → inutile.

## Monolithe modulaire vs Microservices

| Critère | Monolithe modulaire | Microservices |
|---|---|---|
| Equipe | < 5-8 devs | > 8 devs, plusieurs équipes |
| Domaines | 1-3 bounded contexts | Plusieurs BC indépendants |
| Déploiement | Simple, une unité | CI/CD par service, infra complexe |
| Latence inter-composants | In-process (µs) | Network (ms) |
| Overhead ops | Faible | Fort (service mesh, observabilité) |
| Recommandé pour commencer | ✅ Oui | ❌ Non sauf contrainte forte |

**Règle :** commence monolithe modulaire, découpe en services quand une équipe autonome en possède un.

## Event-driven (Kafka / RabbitMQ)

**Kafka :** replay d'events, event sourcing, haute throughput, rétention longue.
**RabbitMQ :** task queues, routing complexe, acknowledgement fin, faible latence.
**Sync REST/gRPC :** si réponse immédiate nécessaire (SLA < 100ms, lecture-confirm).

**Règle de choix :**
- Besoin de rejouer des events → Kafka
- Décorrélation de charge (worker pool) → RabbitMQ ou Kafka
- Réponse synchrone critique → REST/gRPC + retry
