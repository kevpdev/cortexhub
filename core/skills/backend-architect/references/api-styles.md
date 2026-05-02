# Comparatif styles d'API

## REST

**Quand choisir :**
- Clients connus et stables (web + mobile avec les mêmes besoins)
- Cache HTTP critique (CDN, reverse proxy)
- Équipe familière avec HTTP semantics
- API publique exposée à des tiers

**Points forts :** universel, tooling mature, cache natif, stateless par design.
**Points faibles :** over-fetching/under-fetching, versioning complexe, N+1 requests sur ressources liées.

## GraphQL

**Quand choisir :**
- Clients multiples avec besoins hétérogènes (web léger vs mobile data-constrained)
- Évolution rapide du schéma produit
- Agrégation de données multi-sources
- Dashboard / back-office avec queries complexes

**Points forts :** typage fort, un seul endpoint, client-driven queries, introspection.
**Points faibles :** complexité resolver, N+1 côté serveur (DataLoader obligatoire), pas de cache HTTP natif, over-engineering pour CRUD simple.

## gRPC

**Quand choisir :**
- Communication inter-services interne (microservices)
- Performance réseau critique (binaire Protobuf vs JSON)
- Streaming bidirectionnel nécessaire
- Contrat fort entre équipes

**Points forts :** performance, typage fort avec Protobuf, streaming natif, code generation.
**Points faibles :** pas navigateur-natif (grpc-web requis), tooling moins mature, debugging plus complexe.

## Tableau de décision rapide

| Critère | REST | GraphQL | gRPC |
|---|---|---|---|
| Clients publics | ✅ | ✅ | ❌ |
| Communication interne | ✅ | ⚠️ | ✅ |
| Cache HTTP | ✅ | ❌ | ❌ |
| Clients hétérogènes | ⚠️ | ✅ | ❌ |
| Performance binaire | ❌ | ❌ | ✅ |
| Streaming | ❌ | ⚠️ | ✅ |
| Simplicité | ✅ | ⚠️ | ❌ |
