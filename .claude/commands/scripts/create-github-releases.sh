#!/bin/bash
# Create GitHub releases for all new tags

set -e

echo "Finding new tags to release..."

# Get all tags for packages with CHANGELOG.md files
packages=$(find . -maxdepth 2 -name "CHANGELOG.md" -not -path "./.claude/*" | sed 's|/CHANGELOG.md||' | sed 's|^\./||')

if [ -z "$packages" ]; then
  echo "No packages found with CHANGELOG.md files"
  exit 0
fi

# Track releases created
releases_created=0

for pkg_dir in $packages; do
  if [ ! -f "$pkg_dir/package.json" ]; then
    echo "Warning: No package.json found in $pkg_dir, skipping"
    continue
  fi

  name=$(jq -r '.name' "$pkg_dir/package.json")
  version=$(jq -r '.version' "$pkg_dir/package.json")
  tag="${name}@${version}"

  # Check if release already exists
  if gh release view "$tag" &>/dev/null; then
    echo "✓ Release already exists: $tag"
    continue
  fi

  echo ""
  echo "Creating release for $tag..."

  # Extract changelog content for this version
  changelog_file="$pkg_dir/CHANGELOG.md"

  if [ ! -f "$changelog_file" ]; then
    echo "Warning: CHANGELOG.md not found for $pkg_dir, skipping"
    continue
  fi

  # Extract content between ## version and next ## or end of file
  # Using awk to extract the section
  changelog_content=$(awk "/^## $version\$/,/^## [0-9]/" "$changelog_file" | sed '$d')

  # If no content found, try alternative format (just the version number without ##)
  if [ -z "$changelog_content" ]; then
    changelog_content=$(awk "/^## $version\$/,/^##/" "$changelog_file" | head -n -1)
  fi

  if [ -z "$changelog_content" ]; then
    echo "Warning: Could not extract changelog content for version $version, using full CHANGELOG"
    changelog_content=$(head -50 "$changelog_file")
  fi

  # Create the GitHub release
  gh release create "$tag" \
    --title "$tag" \
    --notes "$changelog_content"

  echo "✓ Created release: $tag"
  releases_created=$((releases_created + 1))
done

echo ""
if [ $releases_created -eq 0 ]; then
  echo "No new releases created (all releases already exist)"
else
  echo "Release creation complete! Created $releases_created release(s)"
fi
