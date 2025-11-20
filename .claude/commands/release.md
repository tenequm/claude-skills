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

    **Option A: Use the helper script (recommended):**
    ```bash
    bash .claude/commands/scripts/create-release-tags.sh
    ```

    **Option B: Manual tag creation:**
    First, identify which packages were released by checking for CHANGELOG.md files:
    ```bash
    find . -maxdepth 2 -name "CHANGELOG.md" -not -path "./.claude/*" | sed 's|/CHANGELOG.md||' | sed 's|^\./||'
    ```

    Then, for each package directory found, create a tag:
    ```bash
    # Example for a single package (repeat for each found):
    pkg_dir="skill-factory"
    name=$(jq -r '.name' "$pkg_dir/package.json")
    version=$(jq -r '.version' "$pkg_dir/package.json")
    tag="${name}@${version}"

    # Check if tag already exists
    if git tag -l "$tag" | grep -q .; then
      echo "Tag already exists: $tag"
    else
      git tag "$tag"
      echo "Created tag: $tag"
    fi
    ```

    **Note:** The helper script automates tag creation for all packages with CHANGELOG.md files. Use manual creation if you need more control over which tags to create.

11. **Push commits and tags:**
    ```bash
    git push origin main --follow-tags
    ```

    If any tags weren't pushed with --follow-tags, push them individually:
    ```bash
    # Example: Push specific tag if needed
    git push origin skill-factory-skill@0.2.0
    ```

12. **Create GitHub releases for each new tag:**

    **Option A: Use the helper script (recommended):**
    ```bash
    bash .claude/commands/scripts/create-github-releases.sh
    ```

    **Option B: Manual release creation:**
    For each tag created, extract the changelog entry and create a release.

    First, read the CHANGELOG.md to extract the content for the new version:
    ```bash
    # Read the CHANGELOG.md file to get the release notes
    # For example, for skill-factory v0.2.0:
    cat skill-factory/CHANGELOG.md
    ```

    Then create the GitHub release with the extracted notes:
    ```bash
    # Example for skill-factory-skill@0.2.0
    gh release create "skill-factory-skill@0.2.0" \
      --title "skill-factory-skill@0.2.0" \
      --notes "## 0.2.0

### Minor Changes

- Add comprehensive Anthropic best practices documentation
  - [Detailed changelog content from CHANGELOG.md]"
    ```

    **Note:** The helper script automates release creation by extracting changelog content and creating releases for all new tags. Extract the content between the version header (e.g., `## 0.2.0`) and the next version header (or end of file) from the CHANGELOG.md file if creating releases manually.

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
