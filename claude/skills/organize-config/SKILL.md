---
name: organize-config
description: Analyze current repo's CLAUDE.md, rules, and skills placement. Propose reorganization based on best practices.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[audit|migrate|init]"
---

# Organize Config Skill

Analyze Claude Code configuration (CLAUDE.md / rules / skills) and propose reorganization based on best practices.

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
3. **Skills** -- Read all files under `.claude/skills/`. Check frontmatter
4. **Parent directory** -- If a parent CLAUDE.md exists, check its contents (monorepo support)

### Step 2: Analyze based on placement rules

Evaluate each entry against these placement principles:

| Location | Suitable content | Context cost |
|----------|-----------------|--------------|
| **CLAUDE.md** | Build commands, code conventions, environment quirks, shared team knowledge. **Under 200 lines** | High (full text loaded every time) |
| **rules/** | Conditional reminders, path-specific rules. Lazy-loaded via `paths` | Medium (conditional) |
| **skills/** | Domain expertise, reusable workflows, on-demand references | Low (loaded only on invocation. Only 250-char description loaded always) |

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

### Step 3: Output

#### `audit` mode

Output a report in the following format:

```
## Config Analysis Report

### Summary
- CLAUDE.md: {line_count} lines {WARNING if over 200 lines}
- Rules: {file_count} files (alwaysApply: {count}, path-scoped: {count})
- Skills: {file_count} files

### Improvement Proposals
1. [Move] CLAUDE.md L{start}-L{end} "{summary}" -> rules/{proposed-name}.md (Reason: only relevant to {paths})
2. [Split] rules/{name}.md template section -> skills/{proposed-name}/SKILL.md
3. [Merge] rules/{name}.md -> Merge into CLAUDE.md (short, always needed)
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

Template content is adjusted by auto-detecting the repository's language and framework.

## Writing Rules

- All configuration files (CLAUDE.md, rules, skills) MUST be written in English
- Do NOT use emojis in any configuration files

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
