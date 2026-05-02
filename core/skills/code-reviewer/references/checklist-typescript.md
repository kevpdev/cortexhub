# Checklist review — TypeScript / Node.js

Chargée à la demande quand le code reviewé est en TypeScript ou Node.js.

## Typage

- 🔴 `any` non justifié → typer précisément ou utiliser `unknown` + narrowing
- 🔴 `as` cast sans garde → préférer un type guard (`if (typeof x === 'string')`)
- 🟡 Types inline répétés → extraire un `type` ou `interface`
- 🟡 `Function` au lieu de signature précise → `(x: T) => U`
- ✅ `readonly` sur les propriétés immuables, `as const` sur les littéraux
- ✅ Discriminated unions pour les états (`{ status: 'loading' } | { status: 'ready', data: T }`)

## Naming

- ❌ Variables en 1-2 lettres hors itérateurs (`d`, `r`, `tmp`)
- ❌ Booléens sans préfixe (`active` au lieu de `isActive` / `hasActive`)
- ✅ `camelCase` variables/fonctions, `PascalCase` types/classes/composants
- ✅ Préfixe `_` pour params volontairement inutilisés (`_event`)

## SOLID & structure

### SRP
- ❌ Fonction > 50 lignes ou > 3 niveaux d'indentation → extraire des helpers
- ❌ Handler / contrôleur qui contient de la logique métier → déplacer dans un service
- ❌ Composant React qui fait fetch + transformation + UI → split en hook + presentational

### Couplage
- ❌ Imports circulaires → restructurer ou injection
- ❌ Singletons mutables exportés → préférer factory + DI explicite
- ❌ `import * as X` → imports nommés explicites

## Async / await

- 🔴 `await` dans une boucle quand les appels sont indépendants → `Promise.all([...].map(...))`
- 🔴 Promise non awaitée et non `.catch()` → unhandled rejection (configurer ESLint `no-floating-promises`)
- 🟡 `async` sans `await` → enlever le `async`
- 🟡 `try/catch` autour d'un seul `await` qui re-throw tel quel → inutile

## Performance & mémoire

- 🟡 `.map().filter().reduce()` sur > 10k items → un seul `for` loop plus performant
- 🟡 Re-création d'un objet/regex dans une fonction chaude → sortir au scope module
- 🟡 `JSON.parse(JSON.stringify(...))` pour cloner → `structuredClone()` (Node 17+)
- 🔴 Stream non fermé (`fs.createReadStream` sans `.close()`) → fuite de file descriptors

## Express / Fastify / NestJS

| Anti-pattern | Fix |
|---|---|
| Validation manuelle dans le handler | Schéma Zod / class-validator / Fastify schema |
| `req.body` typé `any` | Type explicite via inférence du schéma |
| `try/catch` partout dans les routes | Async error handler global ou wrapper |
| Middleware ordonnés par hasard | Ordre explicite et commenté (auth → validation → handler) |
| Réponse sans status code explicite | `res.status(201).json(...)` |

## React / Vue (si front)

- ❌ `useEffect` pour du data fetching simple → React Query / SWR / TanStack Query
- ❌ `useEffect` qui dépend d'un objet/array recréé → mémoïser ou déplacer
- ❌ State dérivable du props stocké dans `useState` → calcul inline ou `useMemo`
- ❌ Mutation directe d'un state (`array.push()`) → spread / immutable update
- ✅ Clés stables sur les listes, jamais l'index si l'ordre change

## Tests

- ❌ Test qui assert l'implémentation au lieu du comportement (`expect(spy).toHaveBeenCalledWith(...internal)`)
- ❌ `expect(...).toBeTruthy()` quand on peut être plus précis
- ✅ Pattern AAA avec lignes vides séparatrices
- ✅ Nom de test descriptif : `it('returns 404 when user does not exist')`
