# Checklist accessibilité (a11y) — WCAG 2.2

## Rôles ARIA

```html
<!-- ❌ div cliquable sans rôle -->
<div onClick={handleClick}>Valider</div>

<!-- ✅ élément sémantique ou rôle explicite -->
<button onClick={handleClick}>Valider</button>
<!-- ou si besoin d'un div -->
<div role="button" tabIndex={0} onClick={handleClick} onKeyDown={handleKeyDown}>Valider</div>
```

## Navigation clavier

- Tous les éléments interactifs atteignables à la `Tab`
- Ordre de focus logique (pas de `tabIndex > 0` sauf exception)
- `Escape` ferme les modales, menus, drawers
- Flèches naviguent dans les listes, tabs, menus (`role="menu"`)
- Pas de piège clavier (focus bloqué dans un composant sans sortie)

## Contraste

| Niveau | Texte normal | Texte large (18px+) |
|---|---|---|
| AA (minimum) | 4.5:1 | 3:1 |
| AAA (optimum) | 7:1 | 4.5:1 |

Outils : Chrome DevTools > Accessibility, axe, Lighthouse.

## Images et médias

```html
<!-- Image informative -->
<img src="chart.png" alt="Évolution des ventes Q1 2026 : +23%" />

<!-- Image décorative — alt vide obligatoire (pas absent) -->
<img src="decoration.svg" alt="" />

<!-- Icône avec texte adjacent — alt vide -->
<img src="icon-warning.svg" alt="" />
<span>Attention : formulaire invalide</span>
```

## Formulaires

```html
<!-- ✅ label associé explicitement -->
<label htmlFor="email">Adresse email</label>
<input id="email" type="email" aria-describedby="email-hint" />
<span id="email-hint">Format : nom@exemple.com</span>

<!-- ✅ erreur accessible -->
<input aria-invalid="true" aria-describedby="email-error" />
<span id="email-error" role="alert">Email invalide</span>
```

## Composants dynamiques

```jsx
// Modal — focus trap + aria-modal
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Confirmer la suppression</h2>
  ...
</div>

// Live region pour les notifications
<div aria-live="polite" aria-atomic="true">{statusMessage}</div>
// aria-live="assertive" pour les erreurs critiques uniquement
```

## React — pièges courants

- `onClick` sur `<div>` → utiliser `<button>` ou ajouter `role` + `tabIndex` + `onKeyDown`
- `autoFocus` inconsidéré → gère le focus manuellement à l'ouverture de modale
- Animations → respecter `prefers-reduced-motion`

```css
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```
