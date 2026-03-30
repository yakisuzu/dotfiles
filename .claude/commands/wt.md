# Worktree Proposal Skill

Check the working directory for uncommitted git changes (unstaged and staged) and propose switching to a worktree to protect existing work.

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

4. If the user chooses **wt**:
   - Use the `EnterWorktree` tool to switch to a worktree
   - Report the transition and resume the original task

5. If the user chooses **continue**:
   - Proceed with work on the current branch without switching
