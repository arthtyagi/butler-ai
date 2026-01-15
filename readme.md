# Butler Skills

Minimal, installable skillset for Butler AI browser automation.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/arthtyagi/butler-ai/main/scripts/install.sh | sh
```

Installs skills + MCP dependencies. Requires `jq` and `npx`.

## Manual Install

### Skills Only

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

### Stable Releases

```bash
npx add-skill arthtyagi/butler-ai@v0.1.0
```

## Directory Structure

```text
skills/
└── zepto-automation/   # Zepto search/cart/address automation
scripts/
├── sync-skills         # Sync source → distribution
└── install.sh          # Unified installer (skills + MCP)
```

## Requirements

- Active Zepto login in a browser tab

## Usage

```
"Get me a White Monster and some protein bars. pay-on-delivery."
"What's in my Zepto cart?"
```

## Development

- `.claude/skills/zepto-automation` is the source of truth
- `skills/` and `.opencode/skill/` are distribution targets
- Sync: `./scripts/sync-skills`
- Check parity: `./scripts/sync-skills --check`

CI runs parity check on every PR.

## More Skills

Full skillset + dogfood setup: https://github.com/fluid-tools/claude-skills

## License

MIT
