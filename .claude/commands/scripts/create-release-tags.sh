#!/bin/bash
# Create git tags for all packages with CHANGELOG.md files

set -e

echo "Finding packages with CHANGELOG.md files..."

# Find all package directories with CHANGELOG.md (excluding .claude directory)
packages=$(find . -maxdepth 2 -name "CHANGELOG.md" -not -path "./.claude/*" | sed 's|/CHANGELOG.md||' | sed 's|^\./||')

if [ -z "$packages" ]; then
  echo "No packages found with CHANGELOG.md files"
  exit 0
fi

echo "Found packages:"
echo "$packages"
echo ""

# Create tags for each package
for pkg_dir in $packages; do
  if [ ! -f "$pkg_dir/package.json" ]; then
    echo "Warning: No package.json found in $pkg_dir, skipping"
    continue
  fi

  name=$(jq -r '.name' "$pkg_dir/package.json")
  version=$(jq -r '.version' "$pkg_dir/package.json")
  tag="${name}@${version}"

  # Check if tag already exists
  if git tag -l "$tag" | grep -q .; then
    echo "✓ Tag already exists: $tag"
  else
    git tag "$tag"
    echo "✓ Created tag: $tag"
  fi
done

echo ""
echo "Tag creation complete!"
