---
description: Start coding session with context
---

Wrapper for `~/.ai-core/scripts/session-start.sh`.

## Steps

1. Run in terminal to read current context:

```bash
~/.ai-core/scripts/session-start.sh --read
```

2. Display the output to the user.

3. Ask: "What's your goal for this session?"
   - If the user provided a goal with the command: use it directly, skip the question.

4. Set the focus:

```bash
~/.ai-core/scripts/session-start.sh --set-focus "user's goal"
```

5. Confirm: "Session started. Context loaded."
