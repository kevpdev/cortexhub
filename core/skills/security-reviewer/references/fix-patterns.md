# Patterns de fix sécurité — par catégorie

Référence chargée à la demande quand un fix concret est nécessaire.

## SQL Injection

### Java / Spring (JPA + JdbcTemplate)
```java
// ❌ VULNÉRABLE
@Query(value = "SELECT * FROM users WHERE email = '" + email + "'", nativeQuery = true)

// ✅ SÛR — paramètre nommé
@Query(value = "SELECT * FROM users WHERE email = :email", nativeQuery = true)
User findByEmail(@Param("email") String email);

// ❌ VULNÉRABLE — JdbcTemplate concat
jdbcTemplate.queryForObject("SELECT * FROM users WHERE id = " + id, ...);

// ✅ SÛR — placeholders
jdbcTemplate.queryForObject("SELECT * FROM users WHERE id = ?", User.class, id);
```

### Node (Prisma / pg / Drizzle)
```typescript
// ❌ VULNÉRABLE — template literal
const result = await db.$queryRawUnsafe(`SELECT * FROM users WHERE id = ${id}`);

// ✅ SÛR — Prisma typed
const user = await prisma.user.findUnique({ where: { id } });

// ✅ SÛR — pg avec placeholders
await pgClient.query('SELECT * FROM users WHERE id = $1', [id]);
```

## XSS

### React (sortie auto-échappée par défaut)
```tsx
// ❌ VULNÉRABLE
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ SÛR — sortie texte échappée
<div>{userContent}</div>

// ✅ SI HTML NÉCESSAIRE — sanitize d'abord
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### Thymeleaf (Spring)
```html
<!-- ❌ VULNÉRABLE — utext = unescaped -->
<div th:utext="${comment}"></div>

<!-- ✅ SÛR — text = escaped par défaut -->
<div th:text="${comment}"></div>
```

## Validation d'input

### Spring (Bean Validation)
```java
// ✅ Avec @Valid + contraintes
public record CreateUserRequest(
    @Email @NotBlank String email,
    @Size(min = 8, max = 128) String password,
    @Pattern(regexp = "^[A-Za-z\\s]+$") String name
) {}

@PostMapping
public User create(@Valid @RequestBody CreateUserRequest req) { ... }
```

### Node (Zod)
```typescript
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
  // role NE FAIT PAS PARTIE → ignoré
}).strict();  // strict() = rejette les clés inconnues

const data = schema.parse(req.body);
```

## JWT

### Node (jsonwebtoken)
```typescript
// ❌ VULNÉRABLE — accepte alg:none
jwt.verify(token, secret);

// ✅ SÛR — algos whitelistés + claims vérifiés
jwt.verify(token, publicKey, {
  algorithms: ['RS256'],
  issuer: 'https://auth.example.com',
  audience: 'api.example.com',
  clockTolerance: 5,
});
```

### Java (jjwt)
```java
// ✅ SÛR — clé asymétrique + validation explicite
Jws<Claims> jws = Jwts.parserBuilder()
    .setSigningKey(publicKey)
    .requireIssuer("https://auth.example.com")
    .requireAudience("api.example.com")
    .build()
    .parseClaimsJws(token);
```

## Password storage

### Spring Security
```java
// ✅ BCrypt avec cost 12
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12);
}

// Usage
String hash = passwordEncoder.encode(rawPassword);
boolean matches = passwordEncoder.matches(rawPassword, hash);
```

### Node (argon2)
```typescript
import argon2 from 'argon2';

// ✅ Argon2id par défaut
const hash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 19456,  // 19 MiB
  timeCost: 2,
  parallelism: 1,
});

const valid = await argon2.verify(hash, password);
```

## CORS

### Spring
```java
// ❌ VULNÉRABLE — wildcard avec credentials
config.addAllowedOriginPattern("*");
config.setAllowCredentials(true);

// ✅ SÛR — origins explicites
config.setAllowedOrigins(List.of("https://app.example.com"));
config.setAllowCredentials(true);
config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
config.setMaxAge(3600L);
```

### Express
```typescript
import cors from 'cors';

app.use(cors({
  origin: ['https://app.example.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));
```

## Headers de sécurité

### Express (helmet)
```typescript
import helmet from 'helmet';
app.use(helmet());  // applique CSP, HSTS, X-Frame-Options, etc.
```

### Spring Security
```java
http.headers(headers -> headers
    .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
    .httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31536000).includeSubDomains(true))
    .frameOptions(frame -> frame.deny())
);
```

## Secrets management

```bash
# ❌ NE JAMAIS COMMIT
echo "DB_PASSWORD=hunter2" >> .env  # puis git add .env

# ✅ FAIRE
echo ".env" >> .gitignore
# Stockage runtime : Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault
```

```java
// ❌ Hardcoded
private static final String API_KEY = "sk_live_abc123";

// ✅ Injection via env / secret manager
@Value("${api.key}")
private String apiKey;
```
