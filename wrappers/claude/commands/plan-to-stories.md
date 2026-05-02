---
description: Split plan/brief into focused stories
argument-hint: <plan-file-or-text>
---

Split a plan, brief, or specification into focused, implementable stories.

## What this does

Analyzes a plan and creates multiple story files in `.claude/memory-bank/stories/`, each representing a focused feature or task. Follows BMAD document sharding: each story is self-contained with complete context.

## Steps

1. Read input:
   - If file path provided: Read file
   - If text provided: Use directly
   - If no argument: Ask user to paste content or provide file path

2. Analyze plan structure:
   - Identify distinct features/capabilities
   - Group related functionality
   - Determine dependencies between stories
   - Suggest story breakdown to user for approval

2.5. Check Project Initialization (Smart Detection):
   - Check current working directory for BOTH `package.json` AND `tsconfig.json`
   - If BOTH exist (project initialized):
     - Set internal flag: `skipSetupStories = true`
     - Do NOT create any SETUP-### stories
     - Proceed directly to feature story generation
   - If EITHER is missing (project NOT initialized):
     - Use AskUserQuestion to prompt user:
       Question: "Ce projet n'est pas initialisé (package.json et/ou tsconfig.json manquants). Comment souhaitez-vous procéder ?"
       Options:
         1. "Lancer /init-node-ts maintenant (Recommandé)" → Execute /init-node-ts via SlashCommand tool, then set skipSetupStories = true
         2. "Créer SETUP-001 story" → Set skipSetupStories = false (current behavior)
         3. "Ignorer (déjà fait manuellement)" → Set skipSetupStories = true
     - Wait for user response before proceeding
   - Continue to next step with `skipSetupStories` flag set

3. For each story:
   - **Important**: If `skipSetupStories = true`, do NOT create stories with SETUP-### prefix. Only create feature stories (AUTH-###, USER-###, API-###, etc.)
   - Generate unique ID (e.g., AUTH-001, USER-002, or SETUP-001 if applicable)
   - Extract relevant context from plan
   - Identify user need/business value
   - Define implementation scope
   - List acceptance criteria
   - Suggest test scenarios
   - Note dependencies on other stories

4. Create `.claude/memory-bank/stories/` directory if not exists

5. Write story files:
   - One file per story: `<STORY-ID>-<slug>.md`
   - Use story.md template
   - Include cross-references to related stories
   - Link back to parent plan

6. Generate index file:
   - Create `.claude/memory-bank/stories/INDEX.md`
   - List all stories with status
   - Show dependencies graph
   - Provide implementation order suggestion

## Usage

```bash
# From file
/plan-to-stories .claude/memory-bank/plan.md
/plan-to-stories docs/feature-spec.md

# Interactive (will prompt for content)
/plan-to-stories

# With text directly
/plan-to-stories "Feature: User authentication
- Login with email/password
- JWT tokens
- Password reset flow"
```

## Example Output

```
📋 Analyzing plan...

Found 5 distinct features:
1. User authentication (login, JWT, password reset)
2. User profile management
3. Admin dashboard
4. Notification system
5. Data export

Suggested breakdown into 8 stories:
- AUTH-001: Login flow (email/password)
- AUTH-002: JWT token management
- AUTH-003: Password reset flow
- USER-001: Profile CRUD operations
- USER-002: Avatar upload
- ADMIN-001: Dashboard overview
- NOTIF-001: Email notifications
- EXPORT-001: CSV data export

Proceed with this breakdown? (y/n/edit)
> y

✅ Created 8 story files in .claude/memory-bank/stories/
✅ Created INDEX.md with dependency graph

Stories ready for implementation!

Suggested order (based on dependencies):
1. AUTH-001 (no dependencies)
2. AUTH-002 (depends on AUTH-001)
3. USER-001 (depends on AUTH-002)
4. AUTH-003, USER-002, ADMIN-001 (parallel)
5. NOTIF-001, EXPORT-001 (parallel)
```

## Story Breakdown Principles

**Size:** Each story should be implementable in 1-4 hours
**Focus:** One clear user need or business capability
**Self-contained:** Complete context, no external references needed
**Testable:** Clear acceptance criteria
**Ordered:** Dependencies explicit, implementation sequence clear

## Story Format (IMPORTANT)

**Stories must be succinct - NO code examples:**
- **Header**: Title, Status, Priority, Effort (3-4 lines)
- **Context**: Parent + Why (2-3 lines)
- **Scope**: Files + Key Functions list (NO code, just names and brief descriptions)
- **Acceptance Criteria**: Checklist (5-10 items)
- **Dependencies**: Blocks/Blocked by (2-3 lines)
- **Notes**: Technical notes if needed (1-2 lines max)

**Total: ~30-50 lines max per story**

**Do NOT include:**
- Code examples or snippets
- Detailed algorithms with pseudo-code
- Security/Performance sections with code
- Setup instructions with code
- Test scenarios with code

**Rationale:** Token optimization. Stories are reference frames, not full specs.

## SETUP Story Pattern

**When to create**: Only if project not initialized AND user chose "Créer SETUP-001 story" option

**Prefix**: `SETUP-###` (e.g., SETUP-001, SETUP-002)

**Purpose**: Initialize project foundation (package.json, tsconfig.json, dependencies, scripts)

**Template Example**:
```markdown
# SETUP-001: Initialize Node.js TypeScript Project

**Status**: pending
**Priority**: critical
**Effort**: 1h

## Context
**Parent**: [plan name]
**Why**: Foundation for entire project with strict TypeScript, package management, and test infrastructure.

## Scope
**Files to create**:
- package.json - Project manifest with scripts
- tsconfig.json - TypeScript strict mode configuration
- .gitignore - Exclude node_modules, dist/, .env

**Key packages**: typescript, @types/node, [others from plan]

## Acceptance Criteria
- [ ] Package manager initialized (pnpm/npm/yarn)
- [ ] TypeScript strict mode enabled (strict: true)
- [ ] All dependencies installed
- [ ] Scripts functional (build, start, test)
- [ ] .gitignore configured

## Dependencies
**Blocks**: ALL other stories
**Blocked by**: None

## Notes
Use package manager specified in plan. Target ES2022, module: NodeNext.
```

**Key characteristics**:
- **Blocks all feature stories**: Project must be initialized first
- **Critical priority**: Cannot proceed without it
- **Short effort**: ~1 hour for basic setup
- **No code examples**: Just list required files and packages (token efficient)

**Why SETUP stories block all others**: Project must be initialized before any feature work can begin.

## Output Structure

```
.claude/memory-bank/stories/
├── INDEX.md                           # Overview + dependency graph
├── AUTH-001-login-flow.md            # Login implementation
├── AUTH-002-jwt-tokens.md            # Token management
├── AUTH-003-password-reset.md        # Reset flow
├── USER-001-profile-crud.md          # Profile operations
└── USER-002-avatar-upload.md         # Avatar handling
```

## Integration with Workflow

**After generating stories:**
1. Review INDEX.md for implementation order
2. Start with first story: `/session-start "Implement AUTH-001"`
3. During work: Use story file as reference
4. Mark acceptance criteria as complete
5. Move to next story

**Updating stories:**
- Stories are living documents
- Update as implementation reveals details
- Add technical notes, decisions made
- Check off acceptance criteria when done

## Tips

1. **Start broad, refine later** - Initial breakdown approximate, iterate
2. **Dependencies matter** - Stories with no deps = start here
3. **Review before generating** - Validate breakdown makes sense
4. **One story at a time** - Don't parallelize unless truly independent
5. **Update parent plan** - Link stories back to original plan/epic

## Notes

- Story IDs use prefix convention: AUTH, USER, ADMIN, API, UI, DATA, etc.
- Customize prefixes based on your domain
- Stories are stack-agnostic (generic Component/Service/Logic)
- Each story has complete context (BMAD principle: no external deps)
