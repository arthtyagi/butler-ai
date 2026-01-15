# Butler AI

![Butler AI Banner](https://bfq19ar33r7ynbpv.public.blob.vercel-storage.com/butler-ai%20Large.jpeg)

AI-powered personal assistant with browser automation capabilities for everyday tasks.

## Overview

Butler AI automates routine tasks through browser automation, starting with grocery ordering. The project uses Claude's Agent Skills to provide specialized automation knowledge.

## Prerequisites

- **Node.js 18+**
- **Playwright or [Playwriter MCP](https://github.com/remorses/playwriter)** - Browser automation runtime
- **Active browser session** - Logged into services you want to automate (e.g., Zepto for grocery)

### Browser Setup

Butler AI works through Playwright browser automation. You'll need:

1. A browser with an active session (cookies/login state)
2. Playwriter MCP extension installed and running
3. The browser tab you want to control must be active

## Features

### Zepto Grocery Automation

Automate your grocery shopping on Zepto:

- Search for products
- Add items to cart
- Manage cart contents
- Select delivery address
- View order totals and savings

**Example usage:**
```
"Add monster energy and greek yogurt to my Zepto cart"
"What's in my Zepto cart?"
"Search for protein bars on Zepto"
```

## Project Structure

```
butler-ai/
├── .claude/
│   └── skills/
│       └── zepto-automation/    # Core Butler AI skill
│           ├── SKILL.md         # Main skill entry
│           ├── selectors.md     # DOM selector reference
│           ├── operations.md    # Automation functions
│           ├── debugging.md     # Troubleshooting guide
│           └── fallbacks.md     # Recovery strategies
├── zepto-ai.md                  # Full reference documentation
└── readme.md
```

## Claude Skills

This project includes Claude Agent Skills in `.claude/skills/`:

### Butler AI Skills

These are the core skills that power Butler AI's automation capabilities:

| Skill | Purpose |
|-------|---------|
| **zepto-automation** | Browser automation for Zepto grocery delivery - search, cart, checkout |

### Helper Skills

These skills assist in building and maintaining Butler AI but aren't part of the core automation:

| Skill | Purpose |
|-------|---------|
| vercel-ai-sdk | AI SDK v6 patterns for building AI features |
| vercel-react-best-practices | React/Next.js performance optimization |
| react-useeffect | React hooks best practices |
| planning-with-files | Structured task planning workflow |
| convex-* | Convex backend patterns (various skills) |
| typescript-strict-mode | TypeScript best practices |
| web-design-guidelines | UI/UX design patterns |

## Usage

### With Claude

Butler AI skills are automatically available to Claude when working in this project. Simply ask Claude to perform grocery-related tasks:

```
"Order my usual groceries from Zepto"
"Add 2 cans of Monster Energy to cart"
"Check my Zepto cart total"
```

### With Playwriter MCP

The automation requires an active Playwriter session:

1. Open Chrome with Playwriter extension
2. Navigate to zepto.com and log in
3. Click the Playwriter extension icon on the tab
4. Claude can now control the browser

## Development

### Adding New Automation Skills

1. Create a new directory in `.claude/skills/`
2. Add `SKILL.md` with YAML frontmatter
3. Include `allowed-tools` for required capabilities
4. Add sub-files for detailed reference

### Skill Structure

```yaml
---
name: skill-name
description: "When to use this skill..."
allowed-tools:
  - playwriter_execute
  - playwriter_reset
---

# Skill Title

Quick start and overview...
```

## Roadmap

- [ ] Checkout flow automation
- [ ] Payment method selection
- [ ] Order tracking
- [ ] Multi-platform support (Blinkit, Swiggy Instamart)
- [ ] Recipe-based shopping lists

## Contributing

When updating automation skills:

1. Test all selectors on the live site
2. Update version in documentation
3. Document any breaking changes
4. Test fallback strategies

## License

MIT
