# Claude Skills Collection

Personal collection of Claude Code skills for various development tasks.

## Skills

| Name | Description | Last Updated |
|------|-------------|--------------|
| [chrome-extension-wxt](./chrome-extension-wxt) | Build modern Chrome extensions using WXT framework | 05 Nov 2025 |

## Installation

### Using with Claude Code

```bash
# Clone this repo to your preferred location
git clone https://github.com/tenequm/claude-skills.git

# Symlink skills to Claude's skills directory
ln -s /path/to/claude-skills/chrome-extension-wxt ~/.claude/skills/chrome-extension-wxt
```

### Manual Installation

Copy any skill directory to `~/.claude/skills/`:

```bash
cp -r /path/to/claude-skills/chrome-extension-wxt ~/.claude/skills/
```

## Creating Your Own Skills

Each skill should follow Anthropic's best practices:

1. Main file: `SKILL.md` (frontmatter + concise overview)
2. References: `references/*.md` (detailed documentation)
3. Optional: `scripts/`, `assets/` directories

See the [official skill-creator](https://github.com/anthropics/skills) for guidelines.

## License

MIT License - see [LICENSE](./LICENSE) file for details.
