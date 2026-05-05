# Installation Documentation — Known Gaps

This file documents discrepancies between the **intended install/upgrade behavior** described in README.md and MIGRATIONS.md, versus what the **current `install.sh` actually implements**.

These gaps are **not bugs** — they are **planned features** that the documentation reserves for future implementation, marked with `[planned]`.

## Current Status (v1.0)

### `--check` mode [planned for v1.1]

**What was documented**:
- `./install.sh --check` produces a detailed diff report of what changed in the repo
- Reports: new wrappers, orphaned symlinks, schema version mismatches, breaking changes

**What actually exists**:
- `./install.sh --dry-run` exists and previews symlinks to be created
- No systematic analysis of config schema versions, hook definitions, or breaking changes
- Users must manually compare repo versions with their local configs

**Impact on users**:
- Users must run `git diff` themselves to detect breaking changes
- Troubleshooting section in README.md still provides manual checks (grep, jq, diff)
- This is acceptable for v1.0; v1.1 should automate these checks

**Action items for v1.1**:
1. Implement `install.sh --check` as a new mode
2. Add logic to detect:
   - New files that would be symlinked (safe)
   - Orphaned symlinks (deleted files in repo)
   - `_schema_version` mismatches in config files
   - Marker version mismatches in CLAUDE.md snippet
   - Hook definition changes in settings.json
3. Output a human-readable diff report
4. Exit with status 1 if breaking changes detected (prevent silent failures)

---

### Config version checking in `/doctor`

**What was implied**:
- `/doctor` validates schema versions automatically
- Warns if `_schema_version` field doesn't match `.example`

**What actually exists**:
- `/doctor` is referenced as the verification step, but the README.md doesn't know its exact checks
- Implementation details depend on `core/scripts/doctor.sh` (not read for this doc)

**Impact on users**:
- `doctor` may not validate schema versions yet — users should manually check via `jq`
- This is noted in the Troubleshooting section

---

### Migration scripts in `migrations/`

**What was documented**:
- Migration scripts live in `migrations/v<VERSION>-*.sh`
- Always proposed, never auto-run
- Example: `migrations/providers-v1-to-v2.sh`

**What actually exists**:
- No `migrations/` directory is present in the current repo
- This is correct — only add when a breaking change occurs (v1.1 or later)

**Action items**:
- Create `migrations/` directory on first breaking change
- Add first migration script with the breaking change PR

---

## Documented Behavior That Works

✅ `./install.sh` idempotent — safe to re-run  
✅ `./install.sh --dry-run` previews changes  
✅ Symlinks auto-update via `git pull`  
✅ `~/.claude/CLAUDE.md` snippet injected once (idempotent check via grep)  
✅ `~/.claude/settings.json` hooks merged once (idempotent check via grep)  
✅ `providers.json.example` → `providers.json` copy (skipped if exists)  
✅ `agent-routing.json.example` → `agent-routing.json` copy (skipped if exists)  
✅ Conflict detection: refuses to overwrite non-symlinks  
✅ `./install.sh --uninstall` removes symlinks cleanly

---

## Next Steps (v1.1+)

1. **Implement `--check` mode** — priority high (helps users catch issues before upgrade)
2. **Add schema version validation to `/doctor`** — if not already present
3. **Create `migrations/` directory** — on first breaking change
4. **Test upgrade workflow** — use a Docker container with v1.0, pull v1.1, verify `--check` output

---

## For Documentation Reviewers

If you're reading README.md or MIGRATIONS.md and notice a feature marked `[planned]`, this file is the source of truth for what's actually implemented. The documentation is **aspirational** (describes the ideal state) rather than **descriptive** (what exists now), to guide development.

This is intentional — it avoids writing "unsupported" every paragraph while still setting clear expectations.
