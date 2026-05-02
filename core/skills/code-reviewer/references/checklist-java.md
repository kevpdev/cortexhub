# Checklist review — Java / Spring Boot

Chargée à la demande quand le code reviewé est en Java/Spring.

## Naming

- ❌ Classes en `Manager`, `Helper`, `Utils` génériques → préférer le rôle métier (`OrderProcessor`, `InvoiceFormatter`)
- ❌ Méthodes booléennes sans préfixe (`active()` au lieu de `isActive()`)
- ❌ Abréviations obscures (`usr`, `prc`, `cfg`) → noms complets
- ✅ Constantes en `SCREAMING_SNAKE_CASE`, classes en `PascalCase`, méthodes/variables en `camelCase`

## SOLID

### SRP (Single Responsibility)
- ❌ Service > 300 lignes ou > 10 méthodes publiques → split par cas d'usage
- ❌ Méthode > 30 lignes → extraire des méthodes privées au nom expressif
- ❌ Contrôleur qui contient de la logique métier → déplacer dans le service

### OCP / LSP / ISP / DIP
- ❌ `if (type == "X") ... else if (type == "Y")` → polymorphisme ou strategy pattern
- ❌ Sous-classe qui jette `UnsupportedOperationException` → violation de Liskov, revoir la hiérarchie
- ❌ Interface fourre-tout (10+ méthodes) → splitter par rôle
- ❌ `new ServiceImpl()` dans un autre service → injection via `@Autowired` constructeur

## Spring spécifique

| Anti-pattern | Fix |
|---|---|
| `@Autowired` sur champ | Injection par constructeur (`final` + `@RequiredArgsConstructor`) |
| `@Transactional` sur méthode privée | Spring proxy ne fonctionne que sur public — déplacer ou auto-injecter |
| Logique dans `@RestController` | Déplacer dans `@Service` |
| `Optional.get()` sans `isPresent()` | `.orElseThrow()` ou `.orElse(default)` |
| `findAll()` sans pagination | `Pageable` paramètre |
| `@Entity` sans `equals/hashCode` basé sur ID | Ajouter, sinon bugs avec collections JPA |
| Exception générique `catch (Exception e)` | Catch spécifique + log structuré |

## Performance JPA

- 🔴 **N+1** : `findAll()` + accès lazy dans une boucle → `@EntityGraph` ou `JOIN FETCH`
- 🔴 `@OneToMany(fetch = EAGER)` par défaut → préférer LAZY + chargement explicite
- 🟡 `findById().orElseGet(() -> save(...))` → race condition possible, préférer `merge`
- 🟡 Streams Java sur grosses collections JPA → matérialiser en `List` d'abord

## Tests

- ❌ Test sans assertion → vide ou supprimer
- ❌ `@MockBean` partout au lieu de slice tests (`@WebMvcTest`, `@DataJpaTest`)
- ❌ Logique de production dans le test (calculs, formatage)
- ✅ Pattern AAA : Arrange / Act / Assert avec lignes vides séparatrices
- ✅ Nom de test descriptif : `should_return404_whenUserNotFound`

## Lombok / Records

- ✅ Préférer `record` (Java 17+) pour les DTO immuables
- ❌ `@Data` sur entité JPA → casse `equals/hashCode` à cause des collections lazy
- ✅ `@Builder` utile pour > 4 paramètres ; au-dessous, constructeur classique
