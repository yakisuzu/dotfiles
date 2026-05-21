---
name: wt
description: Check for uncommitted git changes and propose switching to a worktree. Use when starting new work on a branch with existing changes, or when the Worktree Rule in CLAUDE.md triggers.
argument-hint: "[base branch: <branch>] [name: <worktree-name>]"
allowed-tools: Bash EnterWorktree
---

# Worktree Proposal Skill

Check the current branch and uncommitted changes, then propose the appropriate action based on the situation.

## Arguments

- `base branch: <branch>` — (optional) Base branch for the worktree (e.g. `qa`, `master`). If specified, the worktree will be reset to `origin/<branch>` after creation.
- `name: <worktree-name>` — (optional) Name for the worktree. Passed to EnterWorktree.

## Steps

1. Run the following commands to detect branch and changes:
   ```
   git branch --show-current
   git diff --stat
   git diff --cached --stat
   ```

2. Determine the situation and act accordingly:

### Case A: main/master + no changes
Report "No uncommitted changes on main. Proceeding with work." and exit.

### Case B: main/master + changes exist
Display a summary of the changes and present the user with options:
- **wt**: Switch to a worktree to isolate new work (protects existing uncommitted changes)
- **continue**: Proceed on the current branch as-is

### Case C: Feature branch + changes exist
Display a summary of the changes and present the user with options:
- **wt**: Switch to a worktree to isolate new work (protects existing uncommitted changes on the feature branch)
- **continue**: Proceed on the current feature branch as-is

### Case D: Feature branch + no changes
Report the current branch name and ask the user whether the previous work on this branch is finished:
- **done**: The previous work is finished → return to main/master and pull
- **wt**: The previous work is NOT finished → switch to a worktree (based on main/master) to start the new task

3. Execute the chosen action:

**If wt** (Case B or C):
   - Use the `EnterWorktree` tool to switch to a worktree (pass `name` if provided)
   - **If `base branch` was specified**, run the following to rebase onto the target branch:
     ```bash
     git fetch origin <branch> && git reset --hard origin/<branch> && git branch -u origin/<branch>
     ```
   - Verify the result with `git log origin/<branch>..HEAD --oneline` (should be empty)
   - Report the transition and resume the original task

**If done** (Case D):
   - Detect the default branch name (`main` or `master`)
   - Run `git checkout <default-branch> && git pull`
   - Report the transition and resume the original task

**If wt** (Case D):
   - Use the `EnterWorktree` tool to switch to a worktree (pass `name` if provided)
   - Reset to main/master:
     ```bash
     git fetch origin <default-branch> && git reset --hard origin/<default-branch> && git branch -u origin/<default-branch>
     ```
   - Verify the result with `git log origin/<default-branch>..HEAD --oneline` (should be empty)
   - Report the transition and resume the original task

**If continue**:
   - Proceed with work on the current branch without switching
