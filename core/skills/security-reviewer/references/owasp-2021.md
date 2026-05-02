# OWASP Top 10 — 2021

Référence chargée à la demande pour citer la catégorie applicable et orienter le fix.

## A01:2021 — Broken Access Control

**Symptômes :**
- IDOR : `/api/users/123/orders` → un user peut lire `/api/users/124/orders`
- `@PreAuthorize` manquant sur méthodes sensibles
- Middleware d'authz omis sur certaines routes
- Élévation horizontale (user A → user B) ou verticale (user → admin)

**Détection :** chercher routes sans guard, comparer ID dans URL vs ID de session.

## A02:2021 — Cryptographic Failures

**Symptômes :**
- MD5, SHA1, DES, RC4, ECB mode
- `Math.random()` ou `Random` pour tokens/secrets
- IV réutilisé entre messages
- Pas de TLS sur transport sensible
- Stockage de mots de passe en clair ou en hash simple

**Algos recommandés (2026) :**
- Hash mot de passe : bcrypt (cost ≥ 12), argon2id (preferred)
- Hash général : SHA-256, SHA-3
- Symétrique : AES-256-GCM
- Asymétrique : RSA-2048+ ou Ed25519
- RNG : `crypto.randomBytes` (Node), `SecureRandom` (Java), `crypto.getRandomValues` (Web)

## A03:2021 — Injection

**Sous-catégories :**
- SQL injection (raw query, string concatenation)
- NoSQL injection (Mongo `$where`, `$ne`)
- Command injection (`exec`, `shell_exec`, `Runtime.exec`)
- LDAP, XPath, template injection (Thymeleaf, Handlebars)
- XSS (reflected, stored, DOM-based)

**Fix universel :** prepared statements / parameterized queries / output encoding contextuel.

## A04:2021 — Insecure Design

**Symptômes :**
- Pas de rate limiting sur login/reset password → brute force
- Pas de lockout après N échecs
- Token de reset prévisible / longue durée
- Workflow business sans contrôle (transferer 0€, prix négatif)

## A05:2021 — Security Misconfiguration

**Checklist :**
- Headers : `Content-Security-Policy`, `Strict-Transport-Security`, `X-Frame-Options`, `X-Content-Type-Options`
- CORS : pas de `Access-Control-Allow-Origin: *` sur endpoints authentifiés
- Debug désactivé en prod (`spring.h2.console.enabled=false`, `DEBUG=false`)
- Default credentials changés (admin/admin)
- Erreurs sans stack trace côté client

## A06:2021 — Vulnerable and Outdated Components

**Outils dédiés :** `npm audit`, `mvn dependency-check`, Snyk, Dependabot.
Hors périmètre du skill — flag uniquement les versions visiblement obsolètes (Log4j 2.14, Spring Boot < 2.6).

## A07:2021 — Identification and Authentication Failures

**Symptômes :**
- JWT sans `algorithms` whitelist (`alg: none` accepté)
- Session ID dans URL
- Cookie sans `HttpOnly`, `Secure`, `SameSite`
- Pas de rotation de token après login
- 2FA bypassable (token réutilisable, pas de rate limit)

## A08:2021 — Software and Data Integrity Failures

**Symptômes :**
- Désérialisation non sûre (`ObjectInputStream`, `pickle`, `yaml.load`)
- Update auto sans vérification de signature
- Dépendances tirées de sources non vérifiées (typosquatting)

## A09:2021 — Security Logging and Monitoring Failures

**Symptômes :**
- Tokens / mots de passe loggés
- Pas de log sur les events sensibles (login échoué, accès admin, modification de rôle)
- Logs non centralisés / non monitorés

## A10:2021 — Server-Side Request Forgery (SSRF)

**Symptômes :**
- Endpoint qui fetch une URL fournie par l'utilisateur sans whitelist
- Métadonnées cloud accessibles (`http://169.254.169.254/`)
- Reverse proxy mal configuré

**Fix :** whitelist d'hôtes/protocoles, résolution DNS contrôlée, isolation réseau.
