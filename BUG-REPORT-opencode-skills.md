# Bug Report: Project-level skills not loaded from .opencode/skill/

## Summary

OpenCode does not load skills from project-level `.opencode/skill/` or `.claude/skills/` directories, only from `~/.claude/skills/` (global).

## Environment

- **OpenCode version**: Latest (as of Jan 2026)
- **OS**: macOS (darwin 25.2.0)
- **Installation**: `~/.opencode/bin/opencode`

## Steps to Reproduce

1. Create a new project directory:
   ```bash
   mkdir test-project && cd test-project
   git init
   ```

2. Create a skill in the project:
   ```bash
   mkdir -p .opencode/skill/my-skill
   cat > .opencode/skill/my-skill/SKILL.md << 'EOF'
   ---
   name: my-skill
   description: "Test skill for reproduction"
   ---
   
   # My Skill
   
   This is a test skill.
   EOF
   ```

3. Start OpenCode in the project directory

4. Check if the skill is loaded (it won't be)

5. Now move the skill to `~/.claude/skills/`:
   ```bash
   mkdir -p ~/.claude/skills
   mv .opencode/skill/my-skill ~/.claude/skills/
   ```

6. Restart OpenCode — the skill now loads

## Expected Behavior

Skills should be loaded from:
- `~/.claude/skills/` (global) ✅ Works
- `~/.opencode/skill/` (global) — Should work
- `<project>/.opencode/skill/` (project-level) — Should work
- `<project>/.claude/skills/` (project-level) — Should work

## Actual Behavior

Only skills in `~/.claude/skills/` are loaded. Project-level skills are ignored.

## Analysis

I traced through the OpenCode binary using `strings ~/.opencode/bin/opencode` and found the skill loading logic:

### OPENCODE_SKILL_GLOB (`{skill,skills}/**/SKILL.md`)

Scans directories from `Config.directories()`:
```javascript
const directories = [
  Global.Path.config,
  ...Filesystem.up({
    targets: [".opencode"],
    start: Instance.directory,  // ← Should be project root
    stop: Instance.worktree     // ← Should be git root
  }),
  ...Filesystem.up({
    targets: [".opencode"],
    start: Global.Path.home,
    stop: Global.Path.home
  })
];
```

### CLAUDE_SKILL_GLOB (`skills/**/SKILL.md`)

```javascript
claudeDirs = Filesystem.up({
  targets: [".claude"],
  start: Instance.directory,
  stop: Instance.worktree
});
claudeDirs.push(`${Global.Path.home}/.claude`);  // This works
```

### Suspected Issue

Either:
1. `Instance.directory` is not set to the project root when skills are scanned
2. `Instance.worktree` is not being detected correctly (defaults to `/`)
3. `Filesystem.up()` is not yielding project-level directories

## Workaround

Symlink project skills to `~/.claude/skills/`:
```bash
ln -s /path/to/project/.opencode/skill/my-skill ~/.claude/skills/my-skill
```

## Requested Fix

Please ensure that:
1. Skills in `<project>/.opencode/{skill,skills}/` are discovered
2. Skills in `<project>/.claude/skills/` are discovered (Claude Code compatibility)
3. `Instance.directory` correctly reflects the project root at skill scan time

## Diagnostic Request

Could you add debug logging that shows:
- What `Instance.directory` and `Instance.worktree` resolve to
- What directories `Config.directories()` returns
- What paths `Filesystem.up()` yields for `.opencode` and `.claude` targets

This would help users diagnose why their skills aren't loading.

---

**Labels**: `bug`, `skills`
