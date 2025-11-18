# Release Skills

Execute a manual release of all plugins with pending changesets.

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

4. **Check for pending changesets:**
   ```bash
   ls .changeset/*.md 2>/dev/null | grep -v README || echo "NO_CHANGESETS"
   ```
   If no changesets found (only README.md), report "No pending changesets to release" and stop.

## Release Process

5. **Run changeset version to bump versions:**
   ```bash
   pnpm changeset version
   ```
   This will:
   - Bump package.json versions based on changesets
   - Generate/update CHANGELOG.md files
   - Delete consumed changeset files

6. **Sync marketplace.json with new versions:**
   ```bash
   pnpm sync-marketplace
   ```

7. **Install to update lockfile:**
   ```bash
   pnpm install
   ```

8. **Validate all skills pass quality checks:**
   ```bash
   pnpm -r validate
   ```
   If validation fails, stop and report issues.

9. **Create version commit:**
   ```bash
   git add -A
   git commit -m "chore: release skills"
   ```

10. **Create git tags for each released package:**
    Read each plugin's package.json to get the version, then create tags:
    ```bash
    # For each plugin directory with a CHANGELOG.md that was modified
    git tag "plugin-name@version"
    ```

    Use this pattern to find released packages and create tags:
    ```bash
    # Get list of plugins with version changes
    for pkg in */package.json; do
      dir=$(dirname "$pkg")
      name=$(jq -r '.name' "$pkg")
      version=$(jq -r '.version' "$pkg")
      if [ -f "$dir/CHANGELOG.md" ]; then
        tag="${name}@${version}"
        if ! git tag -l "$tag" | grep -q .; then
          git tag "$tag"
          echo "Created tag: $tag"
        fi
      fi
    done
    ```

11. **Push commits and tags:**
    ```bash
    git push origin main --follow-tags
    ```

12. **Create GitHub releases for each new tag:**
    For each tag created, extract the changelog entry and create a release:
    ```bash
    # For each new tag
    gh release create "tag-name" \
      --title "tag-name" \
      --notes "Changelog content for this version"
    ```

    Extract changelog content by reading from the ## version header to the next ## header.

## Post-Release

13. **Report summary:**
    List all released packages with their versions and links to GitHub releases.

## Error Handling

- If any step fails, stop immediately and report the error
- Do NOT force push or skip any checks
- If changeset version fails, the changesets may be malformed - check their syntax
- If validation fails, fix the issues before releasing

## Important Notes

- This is a MANUAL release process - no automation
- Always review the generated CHANGELOGs before pushing
- Tags follow the pattern: `package-name@version` (e.g., `solana@0.1.0`)
- GitHub releases are created from the CHANGELOG content
