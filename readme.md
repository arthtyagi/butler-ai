# Butler Skills

Minimal, installable skillset for Butler AI. Ships only Zepto grocery automation.

## Installation

> **npm**
> ```bash
> npx add-skill arthtyagi/butler-ai
> ```

> **bun**
> ```bash
> bunx add-skill arthtyagi/butler-ai
> ```

> **pnpm**
> ```bash
> pnpm dlx add-skill arthtyagi/butler-ai
> ```

Interactive installer supports Cursor, VS Code, Claude Code.

## Directory Structure

```text
skills/
└── zepto-automation/   # Zepto search/cart/address automation
```

## Requirements

- Playwriter MCP (or compatible Playwright MCP)
- Active Zepto login in a browser tab

## Usage

```
"Add hokkaido mango mix and 2 pepsi black to my Zepto cart"
"What's in my Zepto cart?"
```

## Development

- `.claude/skills/` is the source of truth
- `skills/` is the distribution surface for `add-skill`
- Sync: `cp -R .claude/skills/zepto-automation skills/`

## More Skills

Install the full skillset + dogfood setup: https://github.com/fluid-tools/claude-skills
