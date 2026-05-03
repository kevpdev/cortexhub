---
description: Initialize memory-bank in current project (agent-agnostic)
---

Wrapper for `~/.ai-core/scripts/memory-bank-init.sh`.

## Steps

1. Ask the user: "Solo or shared project? [1] solo  [2] shared"

2. Run in terminal with the chosen mode:

```bash
~/.ai-core/scripts/memory-bank-init.sh solo
# or
~/.ai-core/scripts/memory-bank-init.sh shared
```

3. Display the script output.
4. Suggest running `/memory-bank-setup` to wire Cursor to this memory-bank.
