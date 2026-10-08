# Task 管理システムの設計思想

> このドキュメントは claude-task / `/kidou` / `/bankai` を変更する時に読む。通常セッションで読む必要はない。

対象コンポーネント: `bin/claude-task` / `claude/skills/kidou` / `claude/skills/bankai` / `claude/skills/delegate` (`task:` 引数) / `claude/hooks/init-session.sh` (タスク紐付け) / `claude/rules/task.md`。

## 1. 位置づけ

- session を repo ごとに手動で立てる運用だと、入口が分散し、残タスク・依存・待ちを横断で見る場所がない。
- claude-session-deps が「自分の PR」起点で merge blocker を見るのに対し、こちらは「依頼 (タスク)」起点。依頼 → 振り分け → session → PR を追う上位層。
- 依存は一方向: claude-task は claude-session-deps を知らない。逆方向の連携 (graph へのタスク層追加) は deps 側の任意機能。

## 2. 状態の正はファイル、書き込みは CLI のみ

- **決定**: `~/.claude/plans/.tasks/T-<n>.json` を正とし、書き込みは `claude-task` 経由に限定する。
- **理由**: skill ごとに LLM が直接ファイルを書くと、表記ゆれ (status の値など) と同時書き込みによる破損が起きる。スキーマ・状態遷移・採番を script に固定すれば、その上の skill は自由に足せる (plan INDEX を shell で決定的に生成するのと同じ思想)。
- **JSON を選んだ理由**: 当初は plan file に揃えて md + frontmatter を検討したが、bash/awk の frontmatter パースは壊れやすい。jq で読み書きできる JSON にし、人間は `claude-task show` / `ls` で読む。
- **保存場所**: `~/.claude/tasks/` は Claude Code 本体が使用中のため避け、`.active` / `.deps` と並ぶ `~/.claude/plans/.tasks/` に置く。dotfiles の git 管理外。
- **排他**: 全書き込みを単一の mkdir ロック下で実行し、tmp + mv で置き換える。60 秒超のロックは残骸とみなして奪う。

## 3. 保存する状態と導出する状態

- **保存**: 意図と関係 (依頼文、dir、priority、blocked_by、担当 session、PR、status = inbox/queued/running/done/dropped)。
- **導出 (保存しない)**: session の生死・busy/idle (`~/.claude/sessions/*.json`、非公式フォーマット)、ブロック中か (blocked_by の status)、repo 名 (dir の git-common-dir)、プロダクト group (`CLAUDE.local.md` の Plan Group mapping)。
- **理由**: 導出できる値を保存すると実態とずれる。session-deps v3 と同じ方針。idle をそのまま「ユーザーの番」と表示するのは近似 (単に作業が終わっただけの idle もある)。
- **ID に分類を入れない理由**: 追加時点では dir 未定のことがあり、複数 repo 跨ぎや途中移動もある。分類は `ls --group/--repo` で表示時に行う。

## 4. 秘書は常駐しない

- **決定**: `/bankai` は呼ばれたときだけ秘書として振る舞う。常駐 session は置かない。
- **理由**: 常駐が必要に見える機能はすべて代替できる。dir 判定は `/kidou` を呼んだ session がその場で行い、次の起動は `claude-task done` が候補を表示し、残タスク一覧は `ls` が毎回導出する。秘書の会話コンテキストに状態を持たせると compact / 終了で失われる。
- `notify_when_idle` は bankai session が生きている間だけのベストエフォート。正は常に claude-task。
- hook から session を自動起動することはしない (挙動が見えにくく、誤った振り分けの被害が大きい)。

## 5. 自動起動の上限は「自動」だけのゲート

- **決定**: `claude-task next --auto` が空き枠 (`CLAUDE_TASK_MAX_RUNNING`、既定 6 から生存中の running タスク数を引いた数) の分だけ返す。`/bankai go` はこれが返したものだけを起動し、件数を LLM が判断しない。ユーザーが ID を指定した明示的な起動は上限を無視する。
- **理由**: bankai を呼ぶと積んだタスクがすべて立ち上がるのは困る。一方で、remote の issue-to-pr のように意図して 5 並列などで起動することもあるため、完全なゲートにはしない。判定を script に置いて LLM の判断ぶれを排除する。

## 6. タスク外 session も追う

- ユーザーが手で立てた session は `ls` の「タスク外 session」に導出表示し、`claude-task adopt` で running タスクとして取り込める。
- remote (claude.ai/code) session は local registry に現れないため、claude-task では追わない (PR 経由で claude-session-deps が追う)。

## 7. session との紐付け

- `/delegate task: T-n` は `claude-task launch-spec` の dir / prompt で、`tmux new-window -e CLAUDE_TASK_ID=T-n` により環境変数を渡し、SessionStart hook (`init-session.sh`) が `claude-task link` する。プロンプト文の解析に依存しない決定的な紐付け。
- resume/compact 時は `claude-task id-of-session` で逆引きし、担当タスクを再注入する (adopt 済み session も対象)。
- SessionEnd では何もしない。session が消えた running タスクは `ls` の「要確認」に出し、done にするかは人が決める。

## 8. worktree ルール: ルートで起動し、子が自分で切る

- **決定**: タスク起動時の dir は常に本体 repo のルート (信頼済み dir)。worktree は子 session が起動直後に `EnterWorktree (name: task-<n>)` で自分で切る。この指示と起動 dir は `claude-task launch-spec` が決定的に生成し、bankai / delegate は組み立てない。
- **理由**: 先に worktree を切って新 dir で起動すると、dir ごとに信頼確認ダイアログが出て起動が止まる。また子 session が CLAUDE.md の Worktree Rule に従って `/wt` で確認を求めると止まるため、指示文で確認不要と明示する。
- **掃除処理との両立**: `init-session.sh` は未変更の `worktree-*` を自動削除するため、並列起動では「EnterWorktree した直後の、まだ未変更の worktree」を別 session の SessionStart が消しうる。生きている session (registry の pid が生存) の cwd が中にある worktree は削除対象から外す。registry の cwd は EnterWorktree 後の worktree パスに追従することを確認済み。
- **repo ルートの解決**: 通常 repo / worktree は git-common-dir (`<repo>/.git`) の親。submodule は common dir の `core.worktree` から本体側のチェックアウト位置を引く (toplevel を使うと submodule 内 worktree で worktree 自身を返す)。
- EnterWorktree は origin の default branch を基点にするため、local の未 push commit は worktree に含まれない (観測: dotfiles で main が origin より先行していたとき、worktree は origin 側の commit から作られた)。

## 9. 今後 (Phase 3)

- claude-session-deps の graph にタスク層を足す。PR が merge されたらタスクを done 候補として表示する。
- `.deps` の pr/remote 宣言をタスクの `blocked_by` に吸収する。
