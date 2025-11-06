# Contributing to Claude Plugins

Thank you for your interest in contributing! This guide will help you get started.

## Requirements

- Node.js 24+ LTS
- pnpm 10+
- Python 3.12+ (for validation scripts)
- [uv](https://docs.astral.sh/uv/) (for pre-commit hooks)

## Setup

```bash
# Clone the repository
git clone https://github.com/tenequm/claude-plugins.git
cd claude-plugins

# Install dependencies
pnpm install

# Install pre-commit hooks
uvx pre-commit install
```

## Making Changes to Skills

When you modify a skill, create a changeset to document the change:

```bash
# 1. Make your changes to a skill
vim gh-cli/skill/SKILL.md

# 2. Validate your changes
cd gh-cli
pnpm validate

# 3. Create a changeset
cd ..
pnpm changeset
# Follow prompts:
#   - Select which skill(s) changed
#   - Choose bump type (patch/minor/major)
#   - Write a summary of changes

# 4. Commit everything including the changeset file
git add .
git commit -m "feat(gh-cli): add trending repos section"

# 5. Push
git push
```

**What happens next:**
1. GitHub Actions detects your changeset
2. A "Version Packages" PR is created/updated automatically
3. When merged: versions bump, marketplace.json updates, git tags created
4. Users can install: `/plugin marketplace update tenequm-plugins`

## Versioning Guidelines

- **Patch** (1.0.x): Bug fixes, typos, link corrections, small improvements
- **Minor** (1.x.0): New features, sections, examples, significant additions
- **Major** (x.0.0): Breaking changes (skill structure changes, removed features)

## Validation

```bash
# Validate specific skill
cd gh-cli
pnpm validate

# Validate all skills in workspace
cd ..
pnpm validate
```

## Creating New Skills

Each skill should follow Anthropic's best practices:

1. Main file: `SKILL.md` (frontmatter + concise overview)
2. References: `references/*.md` (detailed documentation)
3. Optional: `scripts/`, `assets/` directories

See the [official skill-creator](https://github.com/anthropics/skills) for guidelines.

## Development

### Pre-commit Hooks

This repository uses pre-commit to validate skills before committing.

**Setup:**

```bash
# Install pre-commit hooks
uvx pre-commit install

# Run manually on all files
uvx pre-commit run --all-files
```

**What gets validated:**
- Skill structure (SKILL.md format, frontmatter)
- No secrets or API keys
- YAML syntax
- No trailing whitespace

### Continuous Integration

GitHub Actions automatically runs these checks on every push and pull request:

- Skill validation
- Pre-commit checks
- Automated releases via Changesets

### Repository Structure

```
claude-plugins/
├── .changeset/              # Changesets for version management
├── .claude-plugin/          # Plugin marketplace configuration
│   └── marketplace.json     # Plugin registry (auto-synced)
├── .github/workflows/       # CI/CD workflows
├── chrome-extension-wxt/    # Chrome extension plugin
│   ├── package.json        # Plugin metadata with version
│   └── skill/              # Skill content
│       ├── SKILL.md
│       └── references/
├── gh-cli/                  # GitHub CLI plugin
│   ├── package.json
│   └── skill/
└── scripts/                 # Build and release scripts
    └── sync-marketplace.sh  # Syncs versions to marketplace.json
```

## Code of Conduct

Please be respectful and constructive in all interactions. We're here to build useful tools together!

## Questions?

Feel free to open an issue or discussion on GitHub.
