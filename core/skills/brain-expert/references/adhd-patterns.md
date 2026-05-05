# Référence — Patterns TDAH

Chargé à la demande quand le contexte implique un profil TDAH ou forte sensibilité aux interruptions.

## Profil cognitif TDAH

Le TDAH n'est pas un déficit d'attention — c'est une **dysrégulation de l'attention** : difficulté à diriger l'attention volontairement, mais capacité d'hyperfocus intense sur ce qui stimule.

Mécanismes clés :
- **Mémoire de travail réduite** : 20-30% moins de capacité que la moyenne
- **Time blindness** : le temps futur n'est pas "ressenti", seulement le présent immédiat
- **Déficit de la fonction exécutive** : initiation, planification, transition entre tâches
- **Régulation dopaminergique atypique** : besoin de stimulation plus forte pour déclencher l'action
- **Hyperfocus** : engagement total possible quand l'intérêt est élevé

## Patterns à appliquer

### Externalisation systématique
Le cerveau TDAH ne peut pas se fier à sa mémoire interne.
- Tout dans le système (pas dans la tête) : notes, contexte, next steps
- Visible = existant : ce qui n'est pas à l'écran n'existe pas
- → CortexHub : `/session-start` charge le contexte, `/capture` externalise immédiatement

### Réduction des frictions d'initiation
L'initiation est le moment le plus coûteux cognitivement.
- First step ultra-concret : "ouvre le fichier X" pas "travaille sur le projet Y"
- Pas de choix à l'ouverture : l'outil doit dire quoi faire
- → CortexHub : afficher "Current Focus" dès le démarrage, pas de menu

### Feedback immédiat et fréquent
La boucle dopaminergique a besoin de signal rapide.
- Confirmation visible de chaque action (même micro)
- Progression visible en permanence
- Célébration des petites victoires (pas seulement les grandes)

### Protection contre les interruptions
Reprendre après interruption est disproportionnellement coûteux.
- Sauvegarde de contexte avant interruption (→ `/capture`)
- Rechargement de contexte à la reprise (→ `/session-start`)
- Signaux d'alerte avant de quitter un état de flow

### Time boxing explicite
Le temps ne s'écoule pas naturellement dans la perception TDAH.
- Durées courtes et fixes : 25 min (Pomodoro) ou moins
- Timer visible, pas mental
- Checkpoints fréquents plutôt qu'un seul deadline

### Structure paradoxale
Le TDAH résiste aux systèmes rigides mais s'effondre sans structure.
- Structure légère : quelques règles simples, pas un système complexe
- Flexibilité dans le comment, fermeté dans le quoi
- → CortexHub : workflows simples (3 commandes : start/capture/end), pas de process lourd

## Anti-patterns à éviter

| Anti-pattern | Pourquoi ça échoue |
|---|---|
| "Tu n'as qu'à te souvenir" | Mémoire de travail insuffisante — pas une question de volonté |
| Long onboarding avant la première valeur | L'attention se perd avant d'atteindre la valeur |
| Notifications fréquentes non urgentes | Interrompent le flow sans valeur ajoutée |
| Tâches sans deadline claire | Time blindness = tâche sans deadline = tâche jamais faite |
| Choix entre 10 options | Paralysie de décision amplifiée |
| Feedback différé ("tu verras le résultat demain") | Boucle dopaminergique trop longue |

## Application à CortexHub

CortexHub est pensé TDAH-first par design :
- **Externalisation** : memory-bank = cerveau externe
- **Friction minimale** : 3 commandes core (`/session-start`, `/capture`, `/session-end`)
- **Contexte auto-chargé** : hook SessionStart = zéro effort de reprise
- **Capture immédiate** : `/capture "note"` sans interrompre le flow
- **Routage déterministe** : pas de décision à prendre sur quel skill charger
