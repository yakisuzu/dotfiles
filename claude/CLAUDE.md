@~/.claude/CLAUDE.local.md

# Global Settings

## Environment

- This machine runs GNU sed (installed via `brew install gnu-sed`) as the default `sed` in PATH, replacing macOS BSD sed.
- When using `sed` in Bash commands, always use GNU sed syntax (e.g. `-i` without backup extension argument).

## Worktree Rule

- **Before editing or creating any files**, check the current branch and uncommitted changes by running `git branch --show-current`, `git diff --stat`, and `git diff --cached --stat`.
- **If the current branch is NOT main/master**: The branch may have in-progress work. Invoke the `/wt` skill to propose a worktree switch (regardless of whether diffs exist) and wait for the user's decision. Do NOT begin file modifications without the user's response.
- **If the current branch IS main/master**:
  - If uncommitted changes exist, judge whether they are **the same topic/purpose** as the task you are about to perform.
    - **Same topic**: Proceed without proposing a worktree switch.
    - **Different topic**: Invoke the `/wt` skill to propose a worktree switch and wait for the user's decision. Do NOT begin file modifications without the user's response.
  - If no changes exist, proceed with work normally.
- **Basic workflow**: Start work from main/master — `git checkout main && git pull` (or `master`) before beginning a new task.

## CLI Tools

- When using `gh` CLI (GitHub CLI), backticks in `--title` or `--body` arguments cause shell interpolation failures. Always pass the body via HEREDOC with a quoted delimiter to prevent interpolation:
  ```bash
  gh issue create --title "Title here" --body "$(cat <<'EOF'
  Body with `backticks` and ```code blocks``` is safe here.
  EOF
  )"
  ```
  **Why this matters:** With unquoted `<<EOF`, backticks are treated as command substitution — e.g. `` `echo foo` `` becomes `foo`, and `` `nonexistent` `` produces an error and becomes empty string. The key is `<<'EOF'` (quoted), which disables all shell expansion inside the heredoc.
