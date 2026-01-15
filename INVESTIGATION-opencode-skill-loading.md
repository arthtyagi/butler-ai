# OpenCode Skill Loading Investigation

## Summary

**Root Cause Identified**: OpenCode's skill discovery DOES support project-level skills, but there appears to be an issue with how `Instance.directory` (the working directory context) is determined at runtime.

---

## How OpenCode Discovers Skills

### Two Glob Patterns

| Pattern | Location Type | Scanned Directories |
|---------|---------------|---------------------|
| `{skill,skills}/**/SKILL.md` | OpenCode native | `Config.directories()` |
| `skills/**/SKILL.md` | Claude Code compat | `.claude` directories |

### Config.directories() Returns:

```javascript
const directories = [
  Global.Path.config,                    // ~/.config/opencode (or similar)
  ...Filesystem.up({
    targets: [".opencode"],
    start: Instance.directory,           // Current working dir
    stop: Instance.worktree              // Git root
  }),
  ...Filesystem.up({
    targets: [".opencode"],
    start: Global.Path.home,             // ~/
    stop: Global.Path.home
  })
];
```

### Claude-style Skills (.claude/skills/):

```javascript
claudeDirs = Filesystem.up({
  targets: [".claude"],
  start: Instance.directory,
  stop: Instance.worktree
});
const globalClaude = `${Global.Path.home}/.claude`;
if (await Filesystem.isDir(globalClaude)) {
  claudeDirs.push(globalClaude);
}
```

---

## Project Skills ARE in Correct Locations

```
/Users/arthtyagi/stash/test-zepto/
├── .opencode/
│   └── skill/
│       └── zepto-automation/
│           └── SKILL.md              ✅ Matches {skill,skills}/**/SKILL.md
├── .claude/
│   └── skills/
│       └── zepto-automation/
│           └── SKILL.md              ✅ Matches skills/**/SKILL.md
└── .git/                             ✅ Git worktree exists
```

---

## Why Skills Aren't Loading

The most likely cause is that **`Instance.directory` is not set to the project root** when OpenCode scans for skills. This can happen if:

1. **OpenCode was started from a different directory** - The `Instance.directory` is set from `process.cwd()` at startup
2. **Git worktree detection failed** - `Instance.worktree` defaults to "/" if no git repo found
3. **Skill scan happens before directory context is established**

### Evidence from Binary Analysis

```javascript
// Instance.directory is set from input.directory during instance creation
Log.Default.info("creating instance", { directory: input.directory });
```

---

## Relevant Flags

| Flag | Purpose |
|------|---------|
| `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` | Disables loading `.claude/skills/**` |
| `OPENCODE_DISABLE_CLAUDE_CODE` | Parent flag that also disables skills |
| `OPENCODE_CONFIG_DIR` | Additional directory to scan for config/skills |

---

## Workarounds

### Option 1: Symlink (Recommended)

```bash
ln -s "/Users/arthtyagi/stash/test-zepto/.opencode/skill/zepto-automation" \
      "$HOME/.claude/skills/zepto-automation"
```

### Option 2: Use OPENCODE_CONFIG_DIR

```bash
export OPENCODE_CONFIG_DIR="/Users/arthtyagi/stash/test-zepto/.opencode"
```

### Option 3: Global Installation

Copy skills to `~/.opencode/skill/` or `~/.claude/skills/`:

```bash
cp -r /Users/arthtyagi/stash/test-zepto/.opencode/skill/zepto-automation \
      ~/.opencode/skill/
```

---

## Recommendation for Bug Report

If reporting to OpenCode team, include:

1. **Repro steps**:
   - Create a project with `.opencode/skill/my-skill/SKILL.md`
   - Run OpenCode from that project directory
   - Skill is not loaded despite correct format

2. **Expected behavior**: 
   - Skills in `.opencode/{skill,skills}/**` should be discovered when working in that project

3. **Actual behavior**:
   - Only skills in `~/.claude/skills/` are loaded

4. **Diagnostic request**:
   - Log what `Instance.directory` and `Instance.worktree` resolve to
   - Log what directories `Config.directories()` returns
   - Log what `Filesystem.up()` finds for `.opencode` and `.claude` targets

---

## Technical Details

### Filesystem.up() Implementation

```javascript
async function* up({ targets, start, stop }) {
  let current = start;
  while (true) {
    for (const target of targets) {
      const search = join(current, target);
      if (await Filesystem.exists(search))
        yield search;   // Returns full path like "/path/to/.opencode"
    }
    if (stop === current) break;
    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }
}
```

### SKILL.md Format Requirements

```yaml
---
name: skill-name           # Required
description: "..."         # Required  
allowed-tools:             # Optional
  - tool_name
---

# Content...
```

The test-zepto skill has correct YAML frontmatter with `name` and `description` fields.

---

## Files Analyzed

- `~/.opencode/bin/opencode` (binary, via `strings` extraction)
- `/Users/arthtyagi/stash/test-zepto/.opencode/skill/zepto-automation/SKILL.md`
- `/Users/arthtyagi/stash/test-zepto/.claude/skills/zepto-automation/SKILL.md`
- `/Users/arthtyagi/stash/test-zepto/opencode.jsonc`

---

*Investigation completed: 2026-01-15*
