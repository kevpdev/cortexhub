# Contributing to CortexHub

CortexHub is built on a core principle: **scripts are the API**. Changes must maintain backwards compatibility, versionning discipline, and transparent upgrade paths.

## Before You Code

- Read [`WORKFLOWS.md`](WORKFLOWS.md) — defines the contract every tool must honor
- Read [`core/docs/SCRIPTS-CONTRACT.md`](core/docs/SCRIPTS-CONTRACT.md) — args, exit codes, output format
- Understand the architecture: `core/` = source of truth, `wrappers/` = tool-specific wrappers

## Types of Changes

### 1. Adding a new script

**Where**: `core/scripts/<workflow-name>.sh`

**Checklist**:
- [ ] Script follows the **Workflow Contract** (args, exit codes, stdout/stderr, idempotent)
- [ ] Bash shebang: `#!/usr/bin/env bash`
- [ ] Error handling: `set -euo pipefail`
- [ ] No external deps beyond `bash`, `jq`, `git` (or document clearly)
- [ ] Documented at top: usage, args, exit codes, examples
- [ ] Tested: `bash core/scripts/<name>.sh --help` works
- [ ] Add to [`WORKFLOWS.md`](WORKFLOWS.md) if it's a user-facing workflow

**Example header**:
```bash
#!/usr/bin/env bash
# <workflow-name>.sh — one-line purpose
# Usage: <workflow-name>.sh [args]
#   --help    show this help
#   <arg1>    description (required|optional)
# Exit codes:
#   0 — success
#   1 — user error (bad input)
#   2 — system error (file not found, etc.)
set -euo pipefail
```

---

### 2. Adding a new skill

**Where**: `core/skills/<skill-name>/` (directory with at least `README.md` and skill content)

**Checklist**:
- [ ] Skill is **agent-agnostic** — no Claude-specific features, no tool calls
- [ ] Documented: `README.md` with purpose, when to use, examples
- [ ] Self-contained: all files needed are inside the skill directory
- [ ] Added to agent routing example: `core/config/agent-routing.json.example`
- [ ] Updated root `README.md` skills table

---

### 3. Modifying a config file (`*.json`, `*.example`)

**When to version** (`_schema_version`):

- ✅ Change field structure, nesting, or type
- ✅ Add/remove required fields
- ✅ Change field semantics significantly
- ❌ Add optional fields (additive = no bump)
- ❌ Fix typos or cosmetic changes

**Checklist** (if version bump needed):
- [ ] Increment `_schema_version` in `.example` file
- [ ] Create migration in `MIGRATIONS.md` → `## v<N+0.1>`
- [ ] Create migration script in `migrations/v<N>-*.sh` if complex (>3 manual steps)
- [ ] Update `/doctor` validation if needed (in `core/scripts/doctor.sh`)
- [ ] Test: `./install.sh --dry-run` on both fresh and upgraded installs

**Example schema version bump**:
```json
{
  "_schema_version": 2,
  "_migration_guide": "See ../../MIGRATIONS.md#v20-date",
  "field": "value"
}
```

---

### 4. Injecting code into user files (CLAUDE.md, settings.json)

**Philosophy**: Never overwrite user config. Inject **once**, then user owns updates.

**For CLAUDE.md snippet** (`wrappers/claude/CLAUDE.md.snippet`):
- [ ] Wrap new content in a versioned marker:
  ```markdown
  ## Session Auto-Load (Memory-Bank) — v1.1
  
  [content here]
  ```
- [ ] Update the marker comparison logic in `install.sh` if marker changes
- [ ] Inject is skipped if marker found (idempotent)

**For settings.json hooks** (`wrappers/claude/settings.hook.json`):
- [ ] Use a unique hook name: `"suggest-skill"`, `"guard-no-claude"`, etc.
- [ ] Installer checks for hook name presence (grep) before merging
- [ ] If hook definition changes, **user must manually merge** (documented in `TROUBLESHOOTING`)
- [ ] Never auto-overwrite hooks in `settings.json`

**Checklist**:
- [ ] Marker or hook name is **versionned and unique**
- [ ] `install.sh` detects presence (grep, jq check)
- [ ] User is guided to manual merge if breaking change (in `TROUBLESHOOTING`)
- [ ] Tested: fresh install + re-run install (should be idempotent)

---

### 5. Adding a new wrapper (Cursor, Windsurf, etc.)

**Where**: `wrappers/<tool-name>/`

**Structure**:
```
wrappers/<tool>
  ├─ commands/              (slash commands)
  ├─ rules/                 (if tool supports rules/context)
  ├─ settings.hook.json     (if tool supports hooks)
  ├─ README.md              (tool-specific setup instructions)
  └─ [tool-specific files]
```

**Checklist**:
- [ ] Wrapper translates all V1 workflows to tool's native UX
- [ ] Commands call scripts in `core/scripts/` (not reimplemented)
- [ ] Documented: `wrappers/<tool>/README.md` with setup steps
- [ ] `install.sh` updated with `--<tool>` flag
- [ ] Tested on fresh + upgraded installs
- [ ] Added to `WORKFLOWS.md` × `Compatibility` matrix

---

## Common Tasks

### Update agent-routing rules

File: `core/config/agent-routing.json.example`

**Checklist**:
- [ ] Rule `id` is unique and kebab-case
- [ ] Regex pattern tested: `echo '{"prompt":"your test"}' | bash core/scripts/suggest-skill.sh`
- [ ] New skill exists in `core/skills/<name>/`
- [ ] Reason is clear (helps users understand why rule triggered)
- [ ] Order = priority (most critical `force: true` rules at top)

---

### Fix a broken symlink

After an upgrade, a symlink may point to a deleted file.

**Fix**:
```bash
rm ~/.claude/commands/old-name.md
# Re-run install to add new version if it exists
./install.sh
```

**Prevent** in PR:
- When renaming a command, delete the old file **last**, after PR is merged and users upgrade

---

### Test the installer

```bash
# On a clean machine or in Docker:
mkdir -p ~/.ai-core ~/.claude ~/.cursor ~/.config/opencode
./install.sh --dry-run                  # preview
./install.sh                            # install (default Claude)
./install.sh --dry-run --uninstall      # preview uninstall
./install.sh --uninstall                # uninstall

# Re-install to test idempotency
./install.sh
```

---

## PR Checklist

Before submitting a PR, verify:

- [ ] **Code quality**: Bash linting (`shellcheck`), no hardcoded paths (use `~` and env vars)
- [ ] **Backwards compatible** or includes `MIGRATIONS.md` entry
- [ ] **Scripts documented** (usage, args, exit codes at top)
- [ ] **Configs versioned** if structure changed (`_schema_version` bumped)
- [ ] **`install.sh` still idempotent**: running it twice = same result
- [ ] **No files deleted** from `core/` or `wrappers/` without migration guide
- [ ] **Tested**: `./install.sh --dry-run` + `./install.sh` both work
- [ ] **README or WORKFLOWS.md updated** if user-facing change
- [ ] **CONTRIBUTING.md updated** if contributor workflow changed

---

## Version Numbering

CortexHub follows semantic versioning for **installer and configs**, not code:

- **Patch** (v1.0.1): Non-breaking script improvements, cosmetic changes
- **Minor** (v1.1): New workflows, new skills, new wrappers (additive)
- **Major** (v2.0): Breaking changes to contract or config schema

**When to bump**:
- New script or workflow → Minor
- Schema breaking change → Patch (if migration is trivial) or Minor
- Contract change (args, output format) → Major

---

## Questions?

- Read the [Architecture](#architecture) section in `README.md`
- Check existing PRs for patterns
- Open an issue to discuss before large changes
