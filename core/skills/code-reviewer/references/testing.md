# Testing Rules

**APPLIQUE STRICTEMENT (80% qualité = 20% effort)**

## 1. Diamant Ratios Fixes (TOUS PROJETS)
- 60% Modulaires/Acceptance : Flux use case (controller-first) + stubs I/O `any()`
- 25% Unitaires pures : Algo isolé (NO mocks)
- 10% Intégration : Wiring HTTP/DB réel (Testcontainers)
- 5% E2E : Parcours critiques (Playwright)

**Métriques** : Coverage métier/SRS >80-100%, CI <10min

## 2. Outside-In TDD Cycle (5min)
1. Test acceptance modulaire (controller/use case + stubs I/O)
2. ROUGE → Code minimal VERT
3. Refactor interne → VERT stable
4. RARE : TU fines pour algo complexe

## 3. Règles Antifragiles (PIERRAIN)
- **NO stubs service** : Service réel, stub REPO/API/DB/queues (`@MockBean Repo`)
- **Matchers flex** : `when(any()).thenReturn()`, `argThat(metier)`, fuzzer(seed)
- **NO verify() sauf flux** : Assert ÉTAT (DB, events) > interactions
- **Auto-suffisant** : Inline Given (NO globals/fixtures lourds), classes <15 tests
- **HTTP minimal** : status 2xx + path métier (intégration pour contrats)

## 4. Par Type App
| App | SUT Principal | Stubs I/O | Extras |
|----|---------------|-----------|--------|
| **API** | Controller slice `@WebMvcTest` | `@MockBean Repo` | Testcontainers light |
| **Frontend** | Composant RTL + MSW | MSW handlers `rest.get(any())` | Vitest fuzzer |
| **Batch** | Job complet | Embed DB, queue mocks | Fixtures YAML |

## 5. Réglementaire (MDR/ISO 13485, Finance, etc.)
- **SRS Trace** : `@Tag("SRS-REQ-XXX")` → matrice Allure/Jira
- **100% REQ couverts** : URS/PRS → tests modulaires
- **Risques** : Fuzzer edges, chaos inputs
- **Preuves** : CI reports → DHF/GRC (coverage SRS)
- **V&V** : Tests = specs exécutables (pas manuel)

## 6. Outils Universels
| Lang | Test | Stubs | Fuzzer | Trace |
|------|------|-------|--------|-------|
| Java | JUnit5 Vitest | Mockito `@MockBean` | Jazzer/fast-random | `@Tag` Allure |
| JS/TS | Vitest RTL | MSW | fast-check | `test.describe.meta` |
| Python | pytest | unittest.mock | Hypothesis | pytest.mark |

## 7. Template Test (GWT Inline)
```java
@Test @Tag("SRS-XXX")
void [useCase]_[scenario]() {
  // Given INLINE complet
  final Req input = fuzzer.generateValidReq(seed);
  when(repoStub.save(argThat(metierValid()))).thenReturn(expected);

  // When
  Result res = controller.action(input);

  // Then ÉTAT
  assertEquals(expected.state(), res.state());
}
```

## 8. Red Flags BLOCK
- ❌ Champs data globals, verify() systématique, HTTP full modulaires
- ❌ Classes >15 tests, stubs service, hardcode valeurs
- ❌ Coverage code only (métier/SRS first)
