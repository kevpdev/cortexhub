---
description: Start coding session with context
argument-hint: <optional-goal>
---

Claude wrapper for `~/.ai-core/scripts/session-start.sh`.

## Steps

1. Run to read current context:

```bash
~/.ai-core/scripts/session-start.sh --read
```

2. Display the output to the user.

3. Ask: "What's your goal for this session?"
   - If an argument was passed to `/session-start "goal"`: use it directly, skip the question.

4. Update the focus:

```bash
~/.ai-core/scripts/session-start.sh --set-focus "user's goal"
```

5. Confirm: "Session started. Context loaded."
