---
name: organize-config
description: Analyze current repo's CLAUDE.md, rules, skills, hooks, and scripts placement. Propose reorganization based on best practices.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[audit|migrate|init]"
---

# Organize Config Skill

Analyze Claude Code configuration (CLAUDE.md / rules / skills / hooks / scripts) and propose reorganization based on best practices.

## Usage

- `/organize-config audit` -- Analyze current configuration and output improvement proposals
- `/organize-config migrate` -- Execute file moves/splits based on analysis results
- `/organize-config init` -- Generate minimal configuration for a new repository

Default (no argument) is `audit`.

## Instructions

### Step 1: Gather current state

Collect the following:

1. **CLAUDE.md** -- Read from project root and `.claude/CLAUDE.md`, count lines
2. **Rules** -- Read all files under `.claude/rules/`. Check `paths` / `alwaysApply` in frontmatter
3. **Skills** -- Read all files under `.claude/skills/`. Check frontmatter and supporting files (scripts/, templates, etc.)
4. **Hooks** -- Read `hooks` section in settings.json (both `~/.claude/settings.json` and `.claude/settings.json`). List hook scripts referenced by `command` fields
5. **Hook scripts** -- Read all files under `.claude/hooks/` and `~/.claude/hooks/`. Check language, permissions, and placement
6. **Parent directory** -- If a parent CLAUDE.md exists, check its contents (monorepo support)

### Step 2: Analyze based on placement rules

Evaluate each entry against these placement principles:

| Location | Suitable content | Context cost |
|----------|-----------------|--------------|
| **CLAUDE.md** | Build commands, code conventions, environment quirks, shared team knowledge. **Under 200 lines** | High (full text loaded every time) |
| **rules/** | Conditional reminders, path-specific rules. Lazy-loaded via `paths` | Medium (conditional) |
| **skills/** | Domain expertise, reusable workflows, on-demand references | Low (loaded only on invocation. Only 250-char description loaded always) |
| **hooks (settings.json)** | Hook definitions: event, matcher, command reference. Inline commands for simple one-liners | N/A (not loaded into context) |
| **hooks/** | Hook scripts referenced from settings.json. Standalone executables (.sh, .js) | N/A (executed on events) |
| **skills/\*/scripts/** | Supporting scripts for a specific skill. Referenced from SKILL.md | N/A (executed on demand) |

#### Specific criteria

Items to **move out of** CLAUDE.md:
- Instructions relevant only to specific file patterns -> Move to `rules/` (with `paths`)
- Procedures, workflows, templates -> Move to `skills/`
- When exceeding 200 lines, move lower-priority items first

Items to **move out of** Rules:
- `alwaysApply: true` with no `paths`, and short -> Consider merging into CLAUDE.md
- Contains complex procedures or templates -> Split to `skills/`, keep only a reference in the rule

Items to **create as** Skills:
- Repeatedly used workflows (PR creation, deploy procedures, etc.)
- Deep domain knowledge (API specs, DB design, etc.)

#### Hooks and scripts criteria

Placement rules for hook scripts:
- Project-level hook scripts -> `.claude/hooks/`
- Personal (cross-project) hook scripts -> `~/.claude/hooks/`
- Skill-specific scripts -> `<skill>/scripts/`
- Simple one-liner hooks can stay inline in settings.json `command` field
- Multi-line or complex logic MUST be extracted to a script file

Script language preference (in order):
1. **Shell (sh/bash)** -- Preferred for simple file checks, git operations, text processing
2. **Node.js (js)** -- Preferred for JSON parsing, complex logic, cross-platform needs
3. **Python** -- Avoid unless the project already depends on Python

Items to **flag** in hooks:
- Scripts placed outside `.claude/hooks/` or `<skill>/scripts/` -> Propose moving to recommended location
- Python scripts when sh/js would suffice -> Propose rewriting in sh or Node.js
- Inline commands in settings.json that are complex (pipes, conditionals) -> Propose extracting to a script file
- Missing executable permission on script files
- Hardcoded absolute paths instead of `$CLAUDE_PROJECT_DIR` or `${CLAUDE_SKILL_DIR}`

### Step 3: Output

#### `audit` mode

Output a report in the following format:

```
## Config Analysis Report

### Summary
- CLAUDE.md: {line_count} lines {WARNING if over 200 lines}
- Rules: {file_count} files (alwaysApply: {count}, path-scoped: {count})
- Skills: {file_count} files
- Hooks: {hook_count} event types configured, {script_count} external scripts
- Scripts: {languages_used} (sh: {count}, js: {count}, py: {count})

### Improvement Proposals
1. [Move] CLAUDE.md L{start}-L{end} "{summary}" -> rules/{proposed-name}.md (Reason: only relevant to {paths})
2. [Split] rules/{name}.md template section -> skills/{proposed-name}/SKILL.md
3. [Merge] rules/{name}.md -> Merge into CLAUDE.md (short, always needed)
4. [Extract] hooks/{event} inline command -> .claude/hooks/{proposed-name}.sh (Reason: complex inline command)
5. [Move] {script_path} -> .claude/hooks/{name} (Reason: script outside recommended location)
6. [Rewrite] {script_path} from Python to sh/Node.js (Reason: prefer sh/js over Python)
...

### References
- Skills: https://code.claude.com/docs/en/skills.md
- Best Practices: https://code.claude.com/docs/en/best-practices.md
- Memory & CLAUDE.md: https://code.claude.com/docs/en/memory.md
```

#### `migrate` mode

Based on `audit` results, execute file moves/splits with user confirmation.
Explain each change before executing and wait for approval.

#### `init` mode

Generate minimal configuration for the current repository:

1. Create `CLAUDE.md` template if it does not exist
2. Create `.claude/rules/` directory
3. Create `.claude/skills/` directory
4. Create `.claude/hooks/` directory

Template content is adjusted by auto-detecting the repository's language and framework.

## Writing Rules

- All configuration files (CLAUDE.md, rules, skills) MUST be written in English
- Do NOT use emojis in any configuration files
- **How-to only**: Skills MUST contain only procedures and decision criteria. NEVER write investigation results, current state summaries, or repo-specific data that must stay in sync with code. Such data drifts from the source of truth and silently degrades skill quality. Always gather repo state dynamically at runtime. Universal guidelines and thresholds (e.g. official doc metrics) ARE permitted as decision criteria (how to judge).

## Best Practice Reference

When updating configuration, check the latest best practices in these official docs:

- Skills: https://code.claude.com/docs/en/skills.md
- Best Practices: https://code.claude.com/docs/en/best-practices.md
- Memory & CLAUDE.md: https://code.claude.com/docs/en/memory.md
- Hooks: https://code.claude.com/docs/en/hooks-guide.md

**Key metrics (subject to change, verify at the URLs above):**
- CLAUDE.md: Under 200 lines recommended
- Skill description: Truncated at 250 characters
- MEMORY.md: First 200 lines or 25KB loaded
