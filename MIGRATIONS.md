# CortexHub — Migration Guide

This document tracks breaking changes and migration paths for upgrades.

## Format

Each migration entry follows this structure:

```markdown
## v<VERSION> — YYYY-MM-DD

### Breaking
- Describe what changed and why it breaks existing configs.
- List all affected files/configs.

### Migration
Step-by-step instructions to update your setup. Include:
1. Exact commands to run
2. Files to edit and what to change
3. Verification step (how to confirm it worked)

### Optional: Migration Script
If complex, provide a bash script in `migrations/v<VERSION>-*.sh` that users can review and run.
```

## Entries

### v1.1 — 2026-05-05

**Status**: Non-breaking, additive.

**Changes**:
- `./install.sh --check` is now fully operational: read-only pre-flight report with exit code 1 on conflicts or drifts.
- `jq` is now a hard requirement for `--check` and Claude installs (was silently skipped before).
- `--check` no longer creates directories (was creating `~/.claude` and subdirs even in read-only mode).

**Migration**: No action required. Existing installs are unaffected.

---

### v1.0 — 2026-01-15

**Status**: Initial release. No breaking changes from prior versions.

---

### Example: v1.1 — YYYY-MM-DD (when applicable)

This is a **commented example** showing the format. Remove after first real migration.

```markdown
## v1.1 — YYYY-MM-DD

### Breaking
- `core/config/providers.json._schema_version` changed from `1` to `2`.
  - Old: `tier1`, `tier2`, `tier3` at top level.
  - New: Nested under `tiers: { tier1: {...}, tier2: {...}, ... }`.
- Affects: `~/.ai-core/config/providers.json`.
- Impact: OpenCode routing will fail until you migrate.

### Migration

**1. Backup your current config**
```bash
cp ~/.ai-core/config/providers.json ~/.ai-core/config/providers.json.v1.backup
```

**2. Run the migration script**
```bash
bash ~/path/to/cortexhub/migrations/providers-v1-to-v2.sh
```

This script:
- Reads your `providers.json.v1.backup`
- Converts old format to new format
- Writes to `~/.ai-core/config/providers.json`
- Validates the output

**3. Verify**
```bash
/doctor
```

Should report no schema mismatches.

**4. Test a workflow**
```bash
/plan "List all files in src/"
```

Should complete without provider errors.

### Alternative: Manual migration

If the script fails, edit manually:

```bash
# Old format (v1)
{
  "tier1": { "model": "qwen2.5-coder:7b", ... },
  "tier2": { "model": "qwen2.5-coder:14b", ... },
  ...
}

# New format (v2)
{
  "tiers": {
    "tier1": { "model": "qwen2.5-coder:7b", ... },
    "tier2": { "model": "qwen2.5-coder:14b", ... },
    ...
  },
  ...
}
```

Wrap the old tier objects inside `"tiers": { ... }`.
```

---

## For Contributors

When adding a breaking change:

1. **Bump the version** in the filename: `v1.1 → v1.2`.
2. **Add a section above** with `## v<N> — YYYY-MM-DD`.
3. **Include both Breaking + Migration** — migration scripts are optional.
4. **Test the migration** on a fresh install and an upgraded install.
5. **Update `/doctor`** if new validation checks are needed.
6. **Reference in CONTRIBUTING.md** if the change affects development workflow.

See `CONTRIBUTING.md` for the full contributor checklist.
