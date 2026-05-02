---
description: Create a new story interactively
argument-hint: <optional-story-id>
---

Create a new story file interactively with guided prompts.

## What this does

Walks you through creating a well-structured story file using the story template. Asks targeted questions to fill each section properly.

## Steps

1. Check for `memory-bank/stories/` directory
   - Create if doesn't exist
   - Read existing INDEX.md if present (to suggest next ID)

2. Gather story information through prompts:
   - Story ID (suggest next available, e.g., FEAT-003)
   - Story title (brief, action-oriented)
   - User need / business value (the "why")
   - Feature description (2-3 sentences)
   - Parent plan/epic (optional)
   - Related stories (optional)

3. Help define implementation:
   - Files to create/modify (list only)
   - Key functions (name + brief description, NO code)
   - Dependencies (story IDs)

4. Define acceptance criteria:
   - Prompt for 3-5 testable items (checklist only)

5. Optional notes:
   - Ask if technical notes needed (1-2 lines max)

6. Create story file:
   - Generate filename: `<STORY-ID>-<slug>.md`
   - Fill succinct template (NO code examples)
   - Save to `.claude/memory-bank/stories/`

7. Update INDEX.md:
   - Add new story to list
   - Mark as "Not started"
   - Note any dependencies

## Usage

```bash
# Interactive - will ask all questions
/story-create

# With story ID pre-filled
/story-create AUTH-004

# Quick mode (minimal prompts, fill template manually after)
/story-create --quick
```

## Example Interaction

```
📝 Creating new story...

Story ID? (e.g., AUTH-001, USER-003, API-005)
Suggested next: FEAT-004
> AUTH-004

Story title? (brief, action-oriented)
> Two-factor authentication

Why is this needed? (user need or business value)
> Users need additional security for sensitive accounts

Brief description (2-3 sentences):
> Implement TOTP-based 2FA. Users can enable 2FA in settings,
  scan QR code with authenticator app, and enter code on login.

Parent plan/epic? (press Enter to skip)
> .claude/memory-bank/plan-authentication.md

Related stories? (comma-separated IDs, or press Enter to skip)
> AUTH-001, AUTH-002

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files to create/modify? (one per line, empty line when done)
> components/Settings2FA.tsx
> lib/2fa.ts
> api/auth/2fa/setup.ts
>

Key functions? (name - brief description, one per line, empty when done)
> generate2FASecret() - Create TOTP secret for user
> verifyTOTPCode() - Validate TOTP code
>

Dependencies (story IDs this depends on, comma-separated or Enter to skip)?
> AUTH-001

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Acceptance criteria (what must be true when done):

1. > User can enable 2FA from settings page
2. > QR code displays correctly for authenticator apps
3. > Login requires TOTP code when 2FA enabled
4. > User can disable 2FA with verification
5. (press Enter if done) >

Technical notes? (1-2 lines max, or press Enter to skip)
> Uses speakeasy library. Store secret encrypted in DB.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Created .claude/memory-bank/stories/AUTH-004-two-factor-authentication.md
✅ Updated .claude/memory-bank/stories/INDEX.md

Story ready! Start implementation with:
/session-start "Implement AUTH-004"
```

## Quick Mode

With `--quick` flag, only asks essentials:
- Story ID
- Title
- Description

Creates template with placeholders for rest. Fill manually after.

```bash
/story-create --quick
> ID: AUTH-004
> Title: Two-factor authentication
> Description: Add TOTP-based 2FA to user accounts

✅ Created AUTH-004-two-factor-authentication.md
Open file to complete implementation details.
```

## Output File Example

**File:** `.claude/memory-bank/stories/AUTH-004-two-factor-authentication.md`

```markdown
# AUTH-004 Two-factor authentication

**Status**: Not Started
**Priority**: High
**Effort**: 2 hours

## Context

**Parent:** .claude/memory-bank/plan-authentication.md
**Why:** Users need additional security for sensitive accounts

## Scope

**Files:**
- components/Settings2FA.tsx
- lib/2fa.ts
- api/auth/2fa/setup.ts

**Key Functions:**
- generate2FASecret() - Create TOTP secret for user
- verifyTOTPCode() - Validate TOTP code

## Acceptance Criteria

- [ ] User can enable 2FA from settings page
- [ ] QR code displays correctly for authenticator apps
- [ ] Login requires TOTP code when 2FA enabled
- [ ] User can disable 2FA with verification
- [ ] TypeScript compiles without errors

## Dependencies

**Blocks**: AUTH-005
**Blocked by**: AUTH-001

## Notes

Uses speakeasy library. Store secret encrypted in DB.
```

## Tips

1. **Be specific in acceptance criteria** - "User can login" vs "User can login with valid credentials in < 2s"
2. **Think flows, not features** - Describe the path through the system
3. **Note all file changes** - Helps estimate scope, avoid surprises
4. **Write tests first mentally** - If you can't write tests, story unclear
5. **Link related stories** - Context for dependencies, avoid duplication

## Notes

- Stories are living docs - update during implementation
- Acceptance criteria = done definition
- Use story as reference during `/session-start`
- Check off criteria as you complete them
