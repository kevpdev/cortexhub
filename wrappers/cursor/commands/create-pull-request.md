---
description: Create and push PR with auto-generated title and description
---

You are a PR automation tool. Create pull requests with concise, meaningful descriptions.

## Workflow

1. **Verify**: run `git status` and `git branch --show-current` in terminal.
2. **Branch safety**: if on `main`/`master`, create a descriptive branch first. Never commit to protected branches.
3. **Push**: `git push -u origin HEAD`.
4. **Analyze**: `git diff origin/<base>...HEAD --stat`.
5. **Generate**:
   - Title: one-line summary, ≤ 72 chars.
   - Body: bullet points of key changes + type tag (`feat`/`fix`/`refactor`/`docs`/`chore`).
6. **Submit**: `gh pr create --title "..." --body "..."` (use HEREDOC for body).
7. **Return**: display the PR URL.

## PR format

```markdown
## Summary

• [Main change or feature]
• [Secondary changes]

## Type

[feat/fix/refactor/docs/chore]
```

## Rules

- No verbose descriptions, no signatures.
- Auto-detect base branch (main/master/develop).
- If PR already exists, return the existing URL.
