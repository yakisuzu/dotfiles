# Task 管理 (claude-task)

- タスク状態は `claude-task` 経由でのみ読み書きする (`~/.claude/plans/.tasks/` を直接編集しない)
- 小回りの操作は `/kidou`: 依頼文で積む、番号 (`/kidou 20 23`) で起動する。残タスク確認・振り分けは `/bankai` (起動はしない)
- タスクには種別がある: 分析 (結論で閉じる) / 作業 (PR 等で閉じる) / 依頼 (他者の返答待ち) / epic (ユースケースの親。子の順序は blocked_by)
- epic を担当する session は振り分けと進捗の親: `claude-task tree <epic>` で子と依存を把握し、子は `/kidou parent: <epic> ...` で積み、着手できる子の `/kidou <n>` をユーザーに提案する。自分では実装しない
- SessionStart に `Task: この session は T-<n> (<種別>) を担当` と出たら、その行の完了手順に従う (作業なら PR 作成時に `claude-task set T-<n> prs=<owner/repo#N>`、分析なら `claude-task done T-<n> <結論>`)。子 session (親 epic がある) は、派生したタスクを `/kidou parent: <epic> ...` で同じ epic に積む
- 完了 (PR が merge 済み、または PR の無い作業が終わった) したら、次の順で片付けて終える
  1. worktree 内にいれば `ExitWorktree` (action: keep) で本体に戻る (cwd が worktree 内のままだと片付けが走らない)
  2. `claude-task done T-<n> [結論や成果物の URL]` (merge 済みの branch と worktree はここで `delete_git_merged_branch.sh` が消す)
  3. 出力で worktree が残っていないか確認し、「完了・片付け済み」と報告して終える
- 設計思想は `dotfiles/claude/docs/task-system-design.md`
