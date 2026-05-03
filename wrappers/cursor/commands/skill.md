---
description: Load a CortexHub skill into context — usage: /skill <name>
---

Load the skill instructions from `~/.ai-core/skills/<name>/SKILL.md` and apply them.

## Available skills

| Name | When to use |
|---|---|
| `code-reviewer` | Code quality, readability, SOLID, performance |
| `security-reviewer` | OWASP, auth, secrets, injections |
| `backend-architect` | API design, architecture trade-offs |
| `frontend-expert` | SSR/CSR, a11y, state management |
| `database-expert` | Schema, indexing, migrations, query optimization |

## Steps

1. Determine the skill name from the argument provided.
   - If no argument: list the available skills above and ask which one to load.

2. Read the skill file:

```bash
cat ~/.ai-core/skills/<name>/SKILL.md
```

3. Apply the skill instructions to your behavior for the rest of this conversation.
4. Confirm: "Skill `<name>` loaded."
