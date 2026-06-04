@~/.claude/CLAUDE.local.md

# Global Settings

## Environment

- This machine runs GNU sed (installed via `brew install gnu-sed`) as the default `sed` in PATH, replacing macOS BSD sed.
- When using `sed` in Bash commands, always use GNU sed syntax (e.g. `-i` without backup extension argument).

## Behavior

- **Improvements**: 運用や設計の改善は skills / CLAUDE.md / rules に反映する。memory には個人/一時情報のみ残す
- **Survey scope**: 「全体調査」と銘打って実施する場合、発見した対象をすべて一次レポートに出す。除外判断はユーザーに委ねる
- **Counter-proposals**: ユーザー提案でも技術的に弱ければ yes-man にならず理由付きで代替案を提示する。選択肢化して trade-off を示し、最終判断はユーザーに委ねる

## Worktree Rule

- **Before editing or creating any files**, check the current branch and uncommitted changes by running `git branch --show-current`, `git diff --stat`, and `git diff --cached --stat`.
- **If the current branch is NOT main/master**:
  - **Uncommitted changes exist**: Invoke `/wt` to propose a worktree switch and wait for the user's decision. Do NOT begin file modifications without the user's response.
  - **No uncommitted changes**: Invoke `/wt` to confirm whether the previous work is done (→ return to main/master) or still in progress (→ worktree for the new task). Do NOT begin file modifications without the user's response.
- **If the current branch IS main/master**:
  - **Uncommitted changes exist**: Invoke `/wt` to propose a worktree switch and wait for the user's decision. Do NOT begin file modifications without the user's response.
  - **No uncommitted changes**: Proceed with work normally.
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
