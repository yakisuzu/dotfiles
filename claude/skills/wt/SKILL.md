---
name: wt
description: Check for uncommitted git changes and propose switching to a worktree. Use when starting new work on a branch with existing changes, or when the Worktree Rule in CLAUDE.md triggers.
argument-hint: "[base branch: <branch>] [name: <worktree-name>]"
allowed-tools: Bash EnterWorktree
---

# Worktree Proposal Skill

Check the working directory for uncommitted git changes (unstaged and staged) and propose switching to a worktree to protect existing work.

## Arguments

- `base branch: <branch>` — (optional) Base branch for the worktree (e.g. `qa`, `master`). If specified, the worktree will be reset to `origin/<branch>` after creation.
- `name: <worktree-name>` — (optional) Name for the worktree. Passed to EnterWorktree.

## Steps

1. Run the following commands to detect changes:
   ```
   git diff --stat
   git diff --cached --stat
   ```

2. **If no changes are found**: Report "No uncommitted changes detected. Proceeding with work." and exit.

3. **If changes are found**: Display a summary of the changes and present the user with the following options:
   - **wt**: Switch to a worktree to isolate new work (protects existing uncommitted changes)
   - **continue**: Proceed on the current branch as-is (risk of overwriting uncommitted changes)

4. If the user chooses **wt** (or was explicitly asked to create a worktree):
   - Use the `EnterWorktree` tool to switch to a worktree (pass `name` if provided)
   - **If `base branch` was specified**, run the following to rebase onto the target branch:
     ```bash
     git fetch origin <branch> && git reset --hard origin/<branch> && git branch -u origin/<branch>
     ```
   - Verify the result with `git log origin/<branch>..HEAD --oneline` (should be empty)
   - Report the transition and resume the original task

5. If the user chooses **continue**:
   - Proceed with work on the current branch without switching
