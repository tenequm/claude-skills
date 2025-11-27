# Release Skills

Execute a release using Nx Release for independent plugin versioning.

## Pre-flight Checks

1. **Check working tree is clean:**
   ```bash
   git status --porcelain
   ```
   If not clean, stop and report dirty files.

2. **Check we're on main branch:**
   ```bash
   git branch --show-current
   ```
   Must be `main`.

3. **Ensure local is up to date with remote:**
   ```bash
   git fetch origin
   git status -sb
   ```
   If behind, run `git pull --rebase`.

4. **Check for unreleased changes:**
   ```bash
   pnpm nx release --dry-run
   ```
   This will show which plugins have unreleased commits.

## Release Process

### Option 1: Release All Changed Plugins (Recommended)

```bash
# Interactive release - prompts for version bump per plugin
pnpm nx release
```

This will:
1. Run validation (cached, fast)
2. Prompt for version bump for each changed plugin (major/minor/patch)
3. Update package.json files
4. Generate project-level CHANGELOG.md files
5. Sync marketplace.json (via postChangelogCommand hook)
6. Create commit: `chore(release): plugin-name@version`
7. Create git tags: `plugin-name@version`
8. Push to GitHub
9. Create GitHub releases with changelog content
10. Prompt to publish (if needed)

### Option 2: Release Specific Version

```bash
# Automatically bump to specific version for all changed plugins
pnpm nx release patch   # or minor, major
```

### Option 3: Release Specific Plugins

```bash
# Release only specific plugins
pnpm nx release --projects=solana,gh-cli
```

### Option 4: Preview First (Dry Run)

```bash
# See what would happen without making changes
pnpm nx release --dry-run
```

## Post-Release

After the release completes, Nx will:
- ✅ Create version commits
- ✅ Create git tags (pattern: `plugin-name@version`)
- ✅ Push commits and tags to GitHub
- ✅ Create GitHub releases with changelog content (as drafts initially)

**Publish GitHub Releases:**

If releases are created as drafts, publish them:
```bash
# List draft releases
gh release list --limit 10

# Publish a draft release
gh release edit plugin-name@version --draft=false
```

**Report summary:**
List all released packages with their versions and links to GitHub releases.

## Release Configuration

All release configuration is in `nx.json`:
- **Independent versioning**: Each plugin has its own version
- **Git tags**: `{projectName}@{version}` pattern
- **Changelogs**: Generated in each plugin's CHANGELOG.md
- **GitHub releases**: Automatic with changelog content
- **Validation**: Runs before versioning (cached)
- **Marketplace sync**: Automatic via `postChangelogCommand`

## Error Handling

- If any step fails, Nx will stop immediately and report the error
- Do NOT force push or skip any checks
- If validation fails, fix the issues before releasing
- Nx creates one commit per release, with all version changes

## Important Notes

- Nx Release uses conventional commits to generate changelogs
- Tags follow the pattern: `plugin-name@version` (e.g., `solana@0.3.0`)
- GitHub releases are created automatically from CHANGELOG content
- Local caching makes repeated validation instant
- Affected detection only releases plugins with changes since last tag

## Common Commands

```bash
# Release workflow (full)
pnpm nx release

# Just version (no publish)
pnpm nx release version

# Just changelog (after versioning)
pnpm nx release changelog

# Just publish (after versioning)
pnpm nx release publish

# Target specific plugins
pnpm nx release --projects=solana

# Preview without changes
pnpm nx release --dry-run
```
