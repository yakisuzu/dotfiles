# Task 管理 (claude-task)

- タスク状態は `claude-task` 経由でのみ読み書きする (`~/.claude/plans/.tasks/` を直接編集しない)
- 今の session で着手しない依頼は `/kidou` で積む。残タスク確認・振り分け・起動は `/bankai`
- SessionStart に `Task: この session は T-<n> を担当` と出たら、完了時に `claude-task done T-<n>`、PR 作成時に `claude-task set T-<n> prs=<owner/repo#N>`
- 設計思想は `dotfiles/claude/docs/task-system-design.md`
