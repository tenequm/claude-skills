# Claude Skills Collection

Personal collection of Claude Code skills for various development tasks.

## Skills

| Name | Description |
|------|-------------|
| [chrome-extension-wxt](./chrome-extension-wxt) | Skill: Build Chrome extensions with WXT framework |
| [gh-cli](./gh-cli) | Skill: Full GitHub CLI capabilities for repos & code |

## Installation

### Quick Install (Recommended)

Install skills as plugins using Claude Code's marketplace system:

```bash
# 1. Add this marketplace
/plugin marketplace add tenequm/claude-plugins

# 2. Install specific skills
/plugin install gh-cli@tenequm-plugins
/plugin install chrome-extension-wxt@tenequm-plugins

# Or browse and install interactively
/plugin
```

### Alternative: Manual Installation

If you prefer to manage skills manually:

```bash
# Clone this repo to your preferred location
git clone https://github.com/tenequm/claude-plugins.git

# Symlink skills to Claude's skills directory
ln -s /path/to/claude-plugins/chrome-extension-wxt/skill ~/.claude/skills/chrome-extension-wxt
ln -s /path/to/claude-plugins/gh-cli/skill ~/.claude/skills/gh-cli
```

## Contributing

Interested in contributing? See [CONTRIBUTING.md](./CONTRIBUTING.md) for development setup, guidelines, and workflow.

## License

MIT License - see [LICENSE](./LICENSE) file for details.
