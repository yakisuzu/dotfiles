---
name: organize-config
description: Analyze current repo's CLAUDE.md, rules, skills, hooks, and scripts placement. Propose reorganization based on best practices.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[audit|migrate|init] [team|personal]"
---

# Organize Config Skill

Analyze Claude Code configuration (CLAUDE.md / rules / skills / hooks / scripts) and propose reorganization based on best practices.

## Usage

- `/organize-config audit [team|personal]` -- Analyze current configuration and output improvement proposals
- `/organize-config migrate [team|personal]` -- Execute file moves/splits based on analysis results
- `/organize-config init [team|personal]` -- Generate minimal configuration for a new repository

Default action (no argument) is `audit`. Default mode (no second argument) is detected via Step 0 below.

### Modes

Two distribution modes drive the proposal logic. They MUST be resolved before Step 2:

- **`team`** -- Company / team development. Multiple repos share the same skill set. Standalone `.claude/skills/` duplicated across repos is an anti-pattern.

  **Default distribution architecture (team mode):**
  - **One org, one marketplace repo** (e.g. `<org>/claude-plugins`). All team plugins live here so any team member can discover any team's skills via `/plugin` Discover tab
  - **Per-team plugin** inside that repo: `plugins/shared/`, `plugins/<team-name>/`, ... Each gets its own `plugin.json` (`name`, `version`) and `skills/`
  - **Per-repo `.claude/settings.json`** wires the marketplace and selectively enables plugins for that repo's team:
    ```json
    {
      "extraKnownMarketplaces": {
        "<marketplace-name>": { "source": { "source": "github", "repo": "<org>/claude-plugins" } }
      },
      "enabledPlugins": {
        "shared@<marketplace-name>": true,
        "<team-name>@<marketplace-name>": true
      }
    }
    ```

  **Three-layer model -- understand before proposing:**
  1. **Marketplace registered** (`extraKnownMarketplaces`) -> the catalog is visible in `/plugin` Discover tab. All listed plugins are discoverable, even other teams'
  2. **Plugin installed** (`/plugin install` or auto-prompted on repo trust when `enabledPlugins` lists it) -> downloaded to cache
  3. **Plugin enabled** (`enabledPlugins: true`) -> namespace `/<plugin>:<skill>` is invokable and shows in completion

  **Implications for proposals:**
  - Default-enabled per repo = `shared` + that team's plugin only. Other teams' skills do NOT pollute completion
  - Other teams' skills remain **discoverable** via `/plugin` and can be installed ad-hoc (`/plugin install <other-team>@<marketplace>`) or pinned at user scope (`~/.claude/settings.json`) for individuals who cross teams

- **`personal`** -- Solo work. Single user, may span multiple repos but no shared distribution required. Standalone `~/.claude/skills/` or per-repo `.claude/skills/` is acceptable. Plugin overhead is not required.

## Instructions

### Step 0: Resolve mode (team vs personal)

If the user passed `team` or `personal` as the second argument, use it directly.

Otherwise, detect from repo signals:
- Multiple distinct authors in `git log --format='%ae' | sort -u` (> 1 non-bot email) -> likely `team`
- Remote is under a personal GitHub account / no remote -> likely `personal`
- Repo has a parent CLAUDE.md indicating monorepo / company conventions -> likely `team`

If detection is ambiguous, ASK the user once: "Treat this repo as `team` (shared with others) or `personal`?" Then proceed.

Record the resolved mode and use it throughout subsequent steps.

### Step 1: Gather current state

Collect the following:

1. **CLAUDE.md** -- Read from project root and `.claude/CLAUDE.md`, count lines
2. **Rules** -- Read all files under `.claude/rules/`. Check `paths` / `alwaysApply` in frontmatter
3. **Skills** -- Read all files under `.claude/skills/` AND `~/.claude/skills/`. For each: parse YAML frontmatter (`name`, `description`, `allowed-tools`, etc.), count SKILL.md body lines, list supporting files (`scripts/`, `reference/`, templates). Note skills present in BOTH layers (potential collision)
4. **Plugin / marketplace registration** -- Read `.claude/settings.json` and `~/.claude/settings.json`. Inspect `extraKnownMarketplaces` and `enabledPlugins`. List which marketplaces / plugins are already wired up
5. **Cross-repo duplication (team mode only)** -- If the user can supply sibling repo paths or a list of project roots, scan each for `.claude/skills/<same-name>/SKILL.md`. Without that input, ASK: "List sibling repos to scan for duplicated skills, or skip." Skills with identical names across 2+ repos are duplication candidates
6. **Hooks** -- Read `hooks` section in settings.json (both `~/.claude/settings.json` and `.claude/settings.json`). List hook scripts referenced by `command` fields
7. **Hook scripts** -- Read all files under `.claude/hooks/` and `~/.claude/hooks/`. Check language, permissions, and placement
8. **Parent directory** -- If a parent CLAUDE.md exists, check its contents (monorepo support)

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

#### Skill quality criteria

Evaluate each `SKILL.md` against the official authoring rules:

**Frontmatter `name` field:**
- MUST match `^[a-z0-9-]+$` (lowercase, digits, hyphens only)
- MUST be 64 chars or fewer
- MUST NOT contain reserved words (`anthropic`, `claude`)
- SHOULD use gerund form (verb + -ing): `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`
  - Acceptable alternatives: noun phrase (`pdf-processing`), action-oriented (`process-pdfs`)
- MUST NOT be vague: `helper`, `utils`, `tools`, `docs`, `data`, `files`
- MUST match the containing directory name

**Frontmatter `description` field:**
- MUST be non-empty, 1024 chars or fewer
- MUST be written in third person ("Extracts ...", not "I can ..." / "You can ...")
- MUST include BOTH what the skill does AND when to use it
- First 250 chars are the primary discovery signal -- front-load triggers/keywords

**SKILL.md body:**
- SHOULD be under 500 lines. Over 500 -> propose splitting into reference files (`reference/*.md`)
- File references SHOULD be one level deep from SKILL.md (no nested `see A -> see B -> see C`)
- Reference files over 100 lines SHOULD include a table of contents at the top

**Cross-skill consistency within the repo:**
- Naming pattern SHOULD be uniform (don't mix `processing-pdfs` and `pdf-tool` and `do_excel`)
- Terminology SHOULD be consistent across skills (one term per concept)

#### Skill distribution criteria

Distribution rules differ by mode resolved in Step 0. Precedence at runtime is always **managed > personal > project**. Plugin skills live alongside whichever layer enables them (typically personal for `extraKnownMarketplaces` set at user scope, or project for repo-committed settings).

**Mode = `team` (default for company / multi-repo):**

Target architecture = **1 org / 1 marketplace repo containing per-team plugins (`shared` + `<team-name>`), wired via per-repo `.claude/settings.json` with `extraKnownMarketplaces` + `enabledPlugins` selecting that repo's team plugins**.

| Layer | Path | When to use in team mode |
|-------|------|--------------------------|
| Team marketplace plugin | `<org>/claude-plugins` repo, `plugins/<team-or-shared>/` | DEFAULT for any skill / hook / agent shared by 2+ team members |
| Project standalone | `<repo>/.claude/skills/` | Only for skills truly specific to ONE repo and unlikely to be reused |
| Personal | `~/.claude/skills/` | Individual cross-team augmentation (e.g. backend dev who often touches frontend, enabling `frontend@<marketplace>` at user scope) |
| Managed (org-wide) | admin console | Only when org-wide enforcement is required (compliance, security policies that must not be overridden) |

**Plugin grouping rule:**
- Skill used by 2+ teams -> `plugins/shared/`
- Skill used by exactly 1 team -> `plugins/<team-name>/`
- Skill used by only 1 repo within 1 team -> stays as project-standalone `<repo>/.claude/skills/`

Items to **flag** in `team` mode:
- Same skill name (or near-identical content) found in 2+ project `.claude/skills/` -> Propose extracting to a plugin in the org marketplace; choose `shared` vs `<team>` per grouping rule above
- Skill in `<repo>/.claude/skills/` that is generic (not repo-specific) and `git log` shows multiple team members touching it -> Propose promoting to the team's plugin
- Repo lacks `extraKnownMarketplaces` in `.claude/settings.json` but the org marketplace exists -> Propose committing the registration so cloners can discover all team plugins via `/plugin`
- `extraKnownMarketplaces` registered but `enabledPlugins` empty / missing this repo's team -> Warn: marketplace catalog is visible but no plugin is auto-enabled; nothing is invokable by default. Propose adding `shared@<marketplace>` + the relevant team plugin
- `enabledPlugins` lists plugins from teams unrelated to this repo -> Question whether they belong here, or should be moved to user scope (`~/.claude/settings.json`) so they don't pollute team mates' completion
- Personal skill (`~/.claude/skills/`) that other team members also need -> Propose promoting to the team plugin in the org marketplace
- Hook scripts duplicated across repos -> Move into the plugin's `hooks/hooks.json` (same schema as settings.json hooks)
- Name collision between personal and project skill with same `name:` -> Warn: precedence silently masks one
- Plugin skill name lacks plugin namespace awareness (will be invoked as `/<plugin-name>:<skill-name>`) -> Verify chosen names read naturally with the namespace prefix (e.g. `backend:deploy-check` not `backend:backend-deploy-check`)

**Mode = `personal` (default for solo work):**

Target distribution = **standalone `.claude/skills/` (project or personal scope)**. Plugin overhead is not required.

| Layer | Path | When to use in personal mode |
|-------|------|------------------------------|
| Project standalone | `<repo>/.claude/skills/` | Repo-specific skills |
| Personal | `~/.claude/skills/` | Skills used across own repos |
| Plugin | (optional) | Only if the user is also distributing the same skills publicly or to others |
| Managed | -- | N/A |

Items to **flag** in `personal` mode:
- Skill duplicated between `~/.claude/skills/` and `<repo>/.claude/skills/` with same `name:` -> Pick one layer; precedence masks the other
- Skill used in many of the user's own repos but living only in one project -> Propose promoting to `~/.claude/skills/`
- Do NOT propose plugin extraction unless the user explicitly says they want to distribute the skill

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

### Mode
- Resolved mode: {team|personal} ({detected|user-specified})

### Summary
- CLAUDE.md: {line_count} lines {WARNING if over 200 lines}
- Rules: {file_count} files (alwaysApply: {count}, path-scoped: {count})
- Skills: {file_count} files (project: {n}, personal: {n}, body over 500 lines: {n}, name violations: {n})
- Plugins/Marketplaces: {registered_marketplaces}, {enabled_plugins} (team mode only)
- Hooks: {hook_count} event types configured, {script_count} external scripts
- Scripts: {languages_used} (sh: {count}, js: {count}, py: {count})

### Improvement Proposals
1. [Move] CLAUDE.md L{start}-L{end} "{summary}" -> rules/{proposed-name}.md (Reason: only relevant to {paths})
2. [Split] rules/{name}.md template section -> skills/{proposed-name}/SKILL.md
3. [Merge] rules/{name}.md -> Merge into CLAUDE.md (short, always needed)
4. [Extract] hooks/{event} inline command -> .claude/hooks/{proposed-name}.sh (Reason: complex inline command)
5. [Move] {script_path} -> .claude/hooks/{name} (Reason: script outside recommended location)
6. [Rewrite] {script_path} from Python to sh/Node.js (Reason: prefer sh/js over Python)
7. [Rename] skills/{current-name} -> skills/{proposed-name} (Reason: not kebab-case / reserved word / vague / not gerund form)
8. [Rewrite description] skills/{name} -- current is first-person / lacks "when to use" / exceeds 1024 chars
9. [Split skill] skills/{name}/SKILL.md ({n} lines) -> split into SKILL.md + reference/*.md (Reason: over 500 lines)
10. [Resolve collision] skills/{name} exists in both `~/.claude/skills/` and `.claude/skills/` (Reason: precedence will mask one)

**Team mode proposals (skip in personal mode):**

11. [Promote to plugin] skills/{name} -> {org}/claude-plugins/plugins/{shared|team-name}/skills/{name} (Reason: duplicated across {repo-A, repo-B} / used by multiple team members. Grouping: {shared if 2+ teams use it, else team plugin})
12. [Wire marketplace] Add to `.claude/settings.json`:
    ```json
    {
      "extraKnownMarketplaces": {
        "{marketplace-name}": { "source": { "source": "github", "repo": "{org}/claude-plugins" } }
      },
      "enabledPlugins": {
        "shared@{marketplace-name}": true,
        "{team-name}@{marketplace-name}": true
      }
    }
    ```
    (Reason: catalog registration + selective enable for this repo's team)
13. [Move hooks to plugin] {repo}/hooks/{name} -> {plugin}/hooks/hooks.json (Reason: same hook duplicated across team repos)
14. [Complete enablement] `extraKnownMarketplaces` is set but `enabledPlugins` is empty/missing -> Add `shared@{marketplace}` + `{team}@{marketplace}` to `enabledPlugins` so plugins actually load (Reason: catalog visible but nothing invokable)
15. [Move cross-team to user scope] `enabledPlugins` lists `{other-team}@{marketplace}` in project `.claude/settings.json` -> Move to user scope `~/.claude/settings.json` (Reason: only one individual crosses teams; project scope forces it on every team mate)
...

### References
- Skills: https://code.claude.com/docs/en/skills.md
- Skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
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

In `team` mode, also:

5. ASK for the team's plugin marketplace repo (`org/repo` or full URL). If supplied, write `.claude/settings.json` with `extraKnownMarketplaces` and a placeholder `enabledPlugins` block so cloners get the marketplace registered automatically
6. Add `.claude/settings.local.json` to `.gitignore` if not already excluded (keep personal overrides out of the commit)

In `personal` mode, skip steps 5-6.

Template content is adjusted by auto-detecting the repository's language and framework.

## Writing Rules

- **Language**: English and Japanese have no meaningful difference in Claude's comprehension, skill matching accuracy, or token efficiency. Choose whichever language the team uses. Be consistent within a project
- Do NOT use emojis in any configuration files
- **How-to only**: Skills MUST contain only procedures and decision criteria. NEVER write investigation results, current state summaries, or repo-specific data that must stay in sync with code. Such data drifts from the source of truth and silently degrades skill quality. Always gather repo state dynamically at runtime. Universal guidelines and thresholds (e.g. official doc metrics) ARE permitted as decision criteria (how to judge).

## Best Practice Reference

When updating configuration, check the latest best practices in these official docs:

- Skills: https://code.claude.com/docs/en/skills.md
- Skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Plugins (create): https://code.claude.com/docs/en/plugins
- Plugin marketplaces (distribute): https://code.claude.com/docs/en/plugin-marketplaces
- Discover/install plugins (3-layer enablement model): https://code.claude.com/docs/en/discover-plugins
- Plugins reference (schemas, defaultEnabled, precedence): https://code.claude.com/docs/en/plugins-reference
- Best Practices: https://code.claude.com/docs/en/best-practices.md
- Memory & CLAUDE.md: https://code.claude.com/docs/en/memory.md
- Hooks: https://code.claude.com/docs/en/hooks-guide.md

**Key metrics (subject to change, verify at the URLs above):**
- CLAUDE.md: Under 200 lines recommended
- SKILL.md body: Under 500 lines recommended
- Skill `name`: lowercase + digits + hyphens, max 64 chars, no `anthropic`/`claude`
- Skill `description`: max 1024 chars, third-person, first 250 chars front-load triggers
- MEMORY.md: First 200 lines or 25KB loaded
