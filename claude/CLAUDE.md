# Global Settings

## Environment

- This machine runs GNU sed (installed via `brew install gnu-sed`) as the default `sed` in PATH, replacing macOS BSD sed.
- When using `sed` in Bash commands, always use GNU sed syntax (e.g. `-i` without backup extension argument).

## Worktree Rule

- **Before editing or creating any files**, always check for uncommitted changes by running `git diff --stat` and `git diff --cached --stat`.
- If changes exist, invoke the `/wt` skill to propose a worktree switch and wait for the user's decision. Do NOT begin file modifications without the user's response.
- If no changes exist, proceed with work normally.

## CLI Tools

- When using `gh` CLI (GitHub CLI), backticks in `--title` or `--body` arguments cause shell interpolation failures. Always pass the body via HEREDOC with a quoted delimiter to prevent interpolation:
  ```bash
  gh issue create --title "Title here" --body "$(cat <<'EOF'
  Body with `backticks` and ```code blocks``` is safe here.
  EOF
  )"
  ```
  **Why this matters:** With unquoted `<<EOF`, backticks are treated as command substitution — e.g. `` `echo foo` `` becomes `foo`, and `` `nonexistent` `` produces an error and becomes empty string. The key is `<<'EOF'` (quoted), which disables all shell expansion inside the heredoc.
