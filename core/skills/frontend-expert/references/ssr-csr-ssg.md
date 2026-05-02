# SSR / CSR / SSG / ISR — Guide de décision

## Tableau de décision

| Critère | CSR (SPA) | SSR | SSG | ISR |
|---|---|---|---|---|
| SEO critique | ❌ | ✅ | ✅ | ✅ |
| Auth requise | ✅ | ✅ | ❌ | ❌ |
| Données temps-réel | ✅ | ✅ | ❌ | ⚠️ |
| TTFB optimisé | ❌ | ⚠️ | ✅ | ✅ |
| Interactivité forte | ✅ | ✅ | ❌ | ❌ |
| Coût d'hébergement | Faible | Élevé | Très faible | Faible |
| Complexité | Faible | Élevée | Faible | Moyenne |

## CSR (Client-Side Rendering)

**Stack :** React (Vite), Vue (Vite), Angular.
**Quand :** app authentifiée (dashboard, SaaS), pas de SEO public, données ultra-personnalisées, interactivité forte.
**Attention :** bundle initial visible → code splitting impératif (`React.lazy`, `defineAsyncComponent`).

## SSR (Server-Side Rendering)

**Stack :** Next.js (App Router), Nuxt 3, Angular Universal.
**Quand :** SEO critique + contenu fréquemment mis à jour, TTFB visible pour l'utilisateur non authentifié.
**Attention :** coût serveur, hydration mismatch, "use client" boundary à gérer (Next.js App Router).

### Next.js App Router — règles de base
```
Server Component (défaut) : data fetching, pas d'interactivité, pas de hooks.
Client Component ('use client') : state, effects, event handlers.
→ Règle : pousser 'use client' le plus bas possible dans l'arbre.
```

## SSG (Static Site Generation)

**Stack :** Next.js (`generateStaticParams`), Nuxt (`nitro prerender`), Astro.
**Quand :** contenu rarement mis à jour (landing page, blog, docs), CDN-first, performance max.
**Attention :** rebuild complet à chaque mise à jour de contenu.

## ISR (Incremental Static Regeneration)

**Stack :** Next.js (`revalidate`), Nuxt (routeRules).
**Quand :** contenu semi-statique (catalogue produit, articles de blog avec mise à jour régulière).
**Configuration Next.js :**
```typescript
export const revalidate = 3600; // revalide toutes les heures
// ou par fetch
fetch(url, { next: { revalidate: 3600 } });
```

## State management — règles de sélection

| Scope | Solution recommandée |
|---|---|
| State local (composant) | `useState` / `ref` |
| Server state (async data) | React Query / SWR / TanStack Query |
| State global UI simple | Zustand / Pinia |
| State global complexe | Redux Toolkit (React) / NgRx (Angular) |
| URL state | searchParams (Next.js) / useSearchParams |

**Règle :** ne pas stocker dans un state global ce qui peut vivre dans l'URL ou dans React Query.
