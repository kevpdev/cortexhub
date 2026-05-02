# Memory-Bank Guide

## Philosophy

**Global-First, Project-Minimal:** 80% rules universal (CLAUDE.md) → all projects. Projects specify: stack, current state, overrides (rare).

**Result:** 20min setup vs 2-3h, zero context loss between sessions.

---

## Quick Start

```bash
cd ~/projects/my-app
/memory-bank-init                    # Creates 3 files
edit memory-bank/projectbrief.md     # What/who/why (2 min)
edit memory-bank/techContext.md      # Stack (1 min)
/session-start "Initial setup"       # Start coding
```

**Done.** Context preservation active.

---

## Daily Workflow

**Morning:** `/session-start` → See where you left off, set goal
**During:** `/capture "Quick note"` → Capture without breaking flow
**Evening:** `/session-end` → Save progress, set next steps

**Example:**
```bash
/session-start
# Shows: last session focus, recent changes, next steps, challenges
> What's your goal? "Implement auth"

# ... code ...
/capture "Bug: JWT validation slow on edge"
# ... code ...

/session-end
# Updates activeContext with: what you did, files changed, next steps
```

---

## Structure

### Per Project
```
my-app/
├── memory-bank/
│   ├── projectbrief.md      # What/who/why (rarely changes)
│   ├── techContext.md       # Stack + arch (rarely changes)
│   ├── activeContext.md     # Current work (daily updates)
│   ├── captures/            # Daily notes (YYYY-MM-DD.md)
│   └── stories/             # Feature breakdown (optional, when needed)
│       ├── INDEX.md         # Stories overview + dependency graph
│       └── *.md             # Individual story files
└── src/
```

### Global
```
~/.claude/
├── CLAUDE.md                # Universal rules
├── MEMORY-BANK-GUIDE.md     # This file
├── commands/                # /memory-bank-init, /session-*, /capture
└── templates/memory-bank/   # Templates for new projects
```

---

## The 3 Essential Files

### projectbrief.md (The "Why")
**Purpose:** Project overview
**Updates:** Rarely (only on pivot)
**Contains:** What, for whom, key features, constraints

### techContext.md (The "How")
**Purpose:** Tech stack + architecture
**Updates:** Rarely (major deps only)
**Contains:** Framework/DB/libs, architecture type, why these choices
**Note:** "Follows global CLAUDE.md rules" + deviations (if any)

### activeContext.md (The "Now")
**Purpose:** Current work state
**Updates:** Daily (via /session-start, /session-end)
**Contains:** Current focus, recent changes (timestamped), next steps (checkboxes), challenges, decisions

---

## Optional Files (Add When Needed)

**productContext.md:** Complex vision/roadmap beyond brief (multi-phase, OKRs)
**systemPatterns.md:** Project-specific patterns overriding global rules
**progress.md:** Detailed milestone tracking, stakeholder reporting

**Default:** Start with 3 essential. Add only when friction appears.

---

## Working with Stories

**Purpose:** Break large features into focused, implementable pieces (BMAD document sharding)

### When to Use Stories

**Use stories when:**
- Feature > 4h implementation
- Multiple components/files involved
- Team collaboration needed (clear handoff points)
- Complex planning required (dependencies, sequence)

**Skip stories when:**
- Quick fixes (< 1h)
- Single file changes
- Exploratory work (use /capture instead)

### Story Workflow

**From plan to implementation:**
```bash
# 1. Create/have a plan
edit memory-bank/plan-auth-system.md

# 2. Split into stories
/plan-to-stories memory-bank/plan-auth-system.md
# Creates: stories/AUTH-001.md, AUTH-002.md, etc.
# Creates: stories/INDEX.md (dependency graph)

# 3. Review breakdown
cat memory-bank/stories/INDEX.md
# Check: sizes reasonable? Dependencies clear? Order logical?

# 4. Implement story by story
/session-start "Implement AUTH-001"
# Work on story, check off acceptance criteria
/session-end

# 5. Move to next story
/session-start "Implement AUTH-002"
```

**Create single story manually:**
```bash
# Interactive creation
/story-create
# Walks through: ID, title, description, scope, acceptance criteria

# Quick creation (fill details later)
/story-create --quick
```

### Story Structure

```
memory-bank/stories/
├── INDEX.md                      # Overview + dependency graph + status
├── AUTH-001-login-flow.md       # Story 1
├── AUTH-002-jwt-tokens.md       # Story 2 (depends on AUTH-001)
└── AUTH-003-password-reset.md   # Story 3 (depends on AUTH-002)
```

**Each story contains (succinct format):**
- Header (Status, Priority, Effort)
- Context (why, parent)
- Scope (files, key functions - NO code)
- Acceptance criteria (checklist)
- Dependencies (blocks/blocked by)
- Notes (1-2 lines if needed)

**Stories are ~30-50 lines max (NO code examples)**

### Story Principles

**Size:** 1-4h implementation (if bigger, split)
**Focus:** One clear capability/user need
**Succinct:** 30-50 lines max, NO code examples (token optimization)
**Self-contained:** Complete context, no external refs (BMAD principle)
**Testable:** Clear acceptance criteria = done definition
**Ordered:** Dependencies explicit, implementation sequence clear
**Stack-agnostic:** Generic Component/Service/Logic (not Redux/React specific)

### Integration with Daily Workflow

**Stories + sessions:**
```bash
# Morning
/session-start "Implement AUTH-001"
# Loads: project context + story file
# Clear goal: acceptance criteria from story

# During work
/capture "Decision: Using bcrypt for password hashing"
/capture "Bug: Token expiry not validated"

# Evening
/session-end
# Update: activeContext + check off story acceptance criteria
```

**When story is done:**
- All acceptance criteria checked ✅
- Tests written and passing
- Update story status in INDEX.md
- Move to next story (check dependencies)

### Tips

1. **Review INDEX.md first:** Understand full scope, dependencies, order
2. **One story at a time:** Don't parallelize unless truly independent
3. **Update stories during work:** Add decisions, technical notes discovered
4. **Link commits to stories:** `git commit -m "AUTH-001: Implement login validation"`
5. **Stories are living docs:** Not set in stone, update as you learn

### Example: Auth System

**Plan:** `memory-bank/plan-auth-system.md` (high-level feature)

**Split into stories:**
- AUTH-001: Login flow (no deps) → Start here
- AUTH-002: JWT tokens (depends AUTH-001) → Then this
- AUTH-003: Password reset (depends AUTH-002) → Finally this
- AUTH-004: 2FA (depends AUTH-002) → Parallel with AUTH-003

**Implementation order:**
```bash
Day 1: /session-start "Implement AUTH-001"  # Login flow
Day 2: /session-start "Implement AUTH-002"  # JWT tokens
Day 3: /session-start "Implement AUTH-003"  # Password reset
Day 4: /session-start "Implement AUTH-004"  # 2FA
```

**Benefits:**
- Clear progress (4 stories = 4 checkpoints)
- Focused work (one capability at a time)
- Easy review (check acceptance criteria)
- Team visibility (INDEX.md shows status)
- Context preserved (each story self-contained)

---

## Global vs Project

**Global (CLAUDE.md):** Universal standards - architecture, security, a11y, performance, TypeScript, testing, communication
**Project (memory-bank/):** This project specifics - stack choice, current state, overrides

**Why split:** Global never changes across projects. Project = unique context.

---

## Benefits

**Context Preservation:**
- Without: "Where was I?" = 15min lost
- With: `/session-start` = instant recall, 0min lost

**Setup Time:**
- Without: 2-3h documenting all standards
- With: 20min (3 files + global reuse)

**AI Quality:**
- Without: 10 clarifying questions
- With: Reads context → immediate action

---

## Tips

1. **Capture everything:** `/capture "Idea: X"`, `/capture "Bug: Y"` → Review end of day
2. **Daily updates:** Even partial progress → Run `/session-end` with what you did
3. **Keep minimal:** 3 files sufficient. No docs, no copy global rules, add optional only when needed
4. **Review weekly:** `cat captures/2025-12-*.md` → Extract patterns (recurring bugs, ideas)
5. **Commit memory-bank:** Context history, team visibility, restore after branch switches

---

## Troubleshooting

**Forgot /session-end:** Run now, approximate is fine, better than nothing
**Cluttered captures:** Archive old `mv captures/2025-11-*.md captures/archive/`
**Cluttered activeContext:** Remove old changes (keep last 10), completed next steps
**Doesn't fit structure:** Add custom files or modify templates. Goal = context preservation, not rigid structure.

---

## Example Session

```bash
# Day 1
/memory-bank-init
# Fill projectbrief.md: "SaaS starter - auth + billing"
# Fill techContext.md: "Next.js 15, Stripe, Supabase"
/session-start "Setup structure"
# ... code ...
/session-end

# Day 5
/session-start
# See: "Last: Stripe integration, Next: Test webhooks, Challenge: Signatures failing"
/capture "Bug: Webhook signature fails with ngrok"
/session-end

# Day 10 (after 3-day break)
/session-start
# Instant recall: "Project: SaaS starter, Last: Webhooks, Next: Subscription UI"
# No "where was I?" → straight to coding
```

---

## Summary

**Memory-Bank = External brain**

**Components:**
- Global rules (CLAUDE.md) → universal standards
- Project context (memory-bank/) → specific details
- Session commands (/session-start|end) → workflow
- Quick capture (/capture) → flow preservation
- Stories (optional) → feature breakdown, BMAD document sharding

**Results:** Zero context loss, 20min setup, better AI, visible progress, ADHD-friendly

**Philosophy:** Start minimal. Add when needed. Iterate.
