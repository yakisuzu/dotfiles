---
globs: ""
alwaysApply: true
---

# Planning Documentation

- Plan files are saved under `~/.claude/plans/`
- **Plan Group**: `CLAUDE.local.md` defines working directory pattern to group name mappings in the `Plan Group` section
  - If cwd matches a mapping, save plans to `~/.claude/plans/<group>/`
  - If no match, save plans to `~/.claude/plans/` directly (default behavior)
- Naming conventions (3 types):
  - `plan-<topic>.md`: Implementation plan (How) - technical steps, task breakdown, file changes
  - `feature-<topic>.md`: Product requirements (What & Why) - user stories, acceptance criteria
  - `research-<topic>.md`: Research & investigation (What happened / What is it) - bug investigation, technology comparison, troubleshooting. Record investigation steps and findings as a log
- **Same topic = same file**: If a plan for the same topic already exists, UPDATE it instead of creating a new file
- When entering Plan Mode, follow existing naming conventions in the target plan directory
- When you start working on a plan, register it: write the plan file path to `~/.claude/plans/.active/{session_id}`
