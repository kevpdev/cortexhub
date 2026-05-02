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
4. Ask if the user wants to commit the changes.
