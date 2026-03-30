---
globs: ""
alwaysApply: true
---

# Planning Documentation

- Plan files are saved to `~/.claude/plans/` (Claude Code default location)
- Naming conventions (3 types):
  - `plan-<topic>.md`: Implementation plan (How) - technical steps, task breakdown, file changes
  - `feature-<topic>.md`: Product requirements (What & Why) - user stories, acceptance criteria
  - `research-<topic>.md`: Research & investigation (What happened / What is it) - bug investigation, technology comparison, troubleshooting. Record investigation steps and findings as a log
- **Same topic = same file**: If a plan for the same topic already exists, UPDATE it instead of creating a new file
- When entering Plan Mode, follow existing naming conventions in `~/.claude/plans/`
- When you start working on a plan, register it: write the plan file path to `~/.claude/plans/.active/{session_id}`
