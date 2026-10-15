# Task 管理 (claude-task)

- タスク状態は `claude-task` 経由でのみ読み書きする (`~/.claude/plans/.tasks/` を直接編集しない)
- 小回りの操作は `/kidou`: 依頼文で積む、番号 (`/kidou 20 23`) で起動する。残タスク確認・振り分けは `/bankai` (起動はしない)
- SessionStart に `Task: この session は T-<n> を担当` と出たら、PR 作成時に `claude-task set T-<n> prs=<owner/repo#N>`
- 完了 (PR が merge 済み、または PR の無い作業が終わった) したら、次の順で片付けて終える
  1. worktree 内にいれば `ExitWorktree` (action: keep) で本体に戻る (cwd が worktree 内のままだと片付けが走らない)
  2. `claude-task done T-<n>` (merge 済みの branch と worktree はここで `delete_git_merged_branch.sh` が消す)
  3. 出力で worktree が残っていないか確認し、「完了・片付け済み」と報告して終える
- 設計思想は `dotfiles/claude/docs/task-system-design.md`
