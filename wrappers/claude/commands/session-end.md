---
description: End session and update context
---

Claude wrapper for `~/.ai-core/scripts/session-end.sh`.

## Steps

1. Ask the user:
   - "What did you accomplish this session?"
   - "What's the next step for your next session?"
   - "Any new challenges or blockers? (Enter to skip)"

2. Run the script with the answers:

```bash
~/.ai-core/scripts/session-end.sh \
  --accomplished "user's answer" \
  --next "user's answer" \
  --challenges "user's answer"  # omit if empty
```

3. Display the script output.
4. If `.claude/vault-sync.json` exists in the current project:
   - Mettre à jour `docs/tech-state.md` en lisant l'état actuel du projet (structure, stack, statut des features) si des changements notables ont eu lieu cette session
   - Lancer `/vault-sync-from-dev` pour pousser vers le vault
5. Ask if the user wants to commit the changes.
