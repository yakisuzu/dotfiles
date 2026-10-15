# Task 管理システムの設計思想

> このドキュメントは claude-task / `/hadou` / `/bankai` を変更する時に読む。通常セッションで読む必要はない。

対象コンポーネント: `bin/claude-task` / `claude/skills/hadou` / `claude/skills/bankai` / `claude/skills/delegate` (`task:` 引数) / `claude/hooks/init-session.sh` (タスク紐付け) / `claude/rules/task.md`。

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

- **保存**: 意図と関係 (依頼文、type、parent、dir、priority、blocked_by、担当 session、PR、result、waiting_on、status = inbox/queued/running/waiting/done/dropped)。
- **導出 (保存しない)**: epic の子一覧と進捗 (子の parent から)、running タスクの未完了の待ち先 (blocked_by。session が先に動いていても一覧の補足に出し、session が終了していれば「要確認」ではなく「ブロック中」に寄せる)、session 名 (registry の現在値を優先。SessionStart の link 時点では registry に name が未登録のことがあるため、保存値は fallback)、session の生死・busy/idle (`~/.claude/sessions/*.json`、非公式フォーマット)、ブロック中か (blocked_by の status)、repo 名 (dir の git-common-dir)、プロダクト group (`CLAUDE.local.md` の Plan Group mapping)。
- **理由**: 導出できる値を保存すると実態とずれる。session-deps v3 と同じ方針。idle をそのまま「ユーザーの番」と表示するのは近似 (単に作業が終わっただけの idle もある)。
- **title は人に伝える名前**: 日本語 10-30 字の短い名詞句で、issue 番号・repo 名は入れない (repo は表示時に導出、番号は body)。`/bankai` の報告文ではタスクを番号ではなく title で呼ぶ (番号だけではユーザーに伝わらない)。CLI は長さの目安外を警告のみ (adopt の仮 title が session 名になるため拒否しない)、title 変更は旧値を log に残す。
- **priority は作業の分類**: 1 復旧 (アラート・脆弱性・テスト復旧) / 2 優先 (問い合わせ・レビュー) / 3 目標 (月目標・顧客約束を含む戦略的作業。表示ラベルは「3 月」と読まれないよう「目標」) / 4 その他 (今ではない)。4 は `/bankai` が起動を提案しない (着手には目標への格上げ調整が要るため)。CLI の既定は 4 (未分類を急ぎ扱いしない)。優先度変更は旧値を log に残す。
- **customer / summary は報告用** (epic の子は epic の summary / customer で段落を作る。§9): Slack 報告の相手 (チーム) にとってタスク番号・session・作業状態や細かいタスク名は意味がなく、知りたいのは「どの優先度で、どのお客さんの、どの機能を進めているか」。そのため `ls --slack` は優先度で見出しを切り、summary (機能) ごとに「お客さん名: 概要」の段落を出す。段落内のタスクは依存 (blocked_by) が分かるように、待っているタスクを待ち先の下に字下げして並べる (段落外の待ち先は「(「…」の後)」)。タスクが 1 件だけで段落外の待ちも無い段落は見出し行だけにする。customer は特定顧客に紐づかない作業を「全体」、未確認を空 (表示「未確認」) として区別する。
- **ID に分類を入れない理由**: 追加時点では dir 未定のことがあり、複数 repo 跨ぎや途中移動もある。分類 (group / repo) は表示時に dir から導出し、一覧の各行に `[group/repo]` として出す。

## 4. 秘書は常駐しない

- **決定**: `/bankai` は呼ばれたときだけ秘書として振る舞う。常駐 session は置かない。
- **理由**: 常駐が必要に見える機能はすべて代替できる。dir 判定は `/hadou` を呼んだ session がその場で行い、次の起動候補は `claude-task done` が表示し、残タスク一覧は `ls` が毎回導出する。秘書の会話コンテキストに状態を持たせると compact / 終了で失われる。
- `notify_when_idle` は bankai session が生きている間だけのベストエフォート。正は常に claude-task。
- hook から session を自動起動することはしない (挙動が見えにくく、誤った振り分けの被害が大きい)。

## 5. 起動は番号指定だけ。小回りは hadou、全体は bankai

- **決定**: 起動は `/hadou <n> [<n> ...]` の番号指定 (と、`/hadou <依頼文> 起動まで` で積んだ直後) だけ。空き枠を数えて複数を自動起動する機能 (旧 `/bankai go` / `claude-task next --auto` / `CLAUDE_TASK_MAX_RUNNING`) は持たない。
- **命名**: BLEACH の破道 (鬼道のうち番号で唱える攻撃の小技) と卍解 (全力の大技) に倣う。積む・番号で起動するといった小回りの操作はすべて `/hadou`、全体の把握と振り分けは `/bankai`。tmux window の起動処理は裏方の `/delegate` に置き、ユーザーの入口には出さない。
- **理由**: 何件起動するかはユーザーが決めればよく、「n 件起動」は `hadou n1 n2 n3` の個別指定で足りる。自動起動の上限は件数の判断を LLM から外すために必要だったが、自動起動自体をやめれば上限も要らない。bankai から起動を外すことで、「状況を聞いたら session が立ち上がった」という予期しない副作用も無くなる。
- **入力の判定**: 全トークンが番号 (`20` / `T-20`) なら起動、それ以外は依頼文として積む。数字で始まる依頼文 (「3件のバグを直して」) を誤って起動しないよう、判定は「全トークンが番号か」で行う。

## 6. タスク外 session も追う

- ユーザーが手で立てた session は `ls` の「タスク外 session」に導出表示し、`claude-task adopt` で running タスクとして取り込める。
- remote (claude.ai/code) session は local registry に現れないため、claude-task では追わない (PR 経由で claude-session-deps が追う)。

## 7. session との紐付け

- `/hadou <n>` は内部で `/delegate task: T-n` を呼ぶ。delegate は `claude-task launch-spec` の dir / prompt で、`tmux new-window -e CLAUDE_TASK_ID=T-n` により環境変数を渡し、SessionStart hook (`init-session.sh`) が `claude-task link` する。プロンプト文の解析に依存しない決定的な紐付け。
- resume/compact 時は `claude-task id-of-session` で逆引きし、担当タスクを再注入する (adopt 済み session も対象)。
- SessionEnd では何もしない。session が消えた running タスクは `ls` の「要確認」に出し、done にするかは人が決める。

## 8. worktree ルール: ルートで起動し、子が自分で切る

- **決定**: タスク起動時の dir は常に本体 repo のルート (信頼済み dir)。worktree は子 session が起動直後に `EnterWorktree (name: task-<n>)` で自分で切る。この指示と起動 dir は `claude-task launch-spec` が決定的に生成し、hadou / delegate は組み立てない。
- **理由**: 先に worktree を切って新 dir で起動すると、dir ごとに信頼確認ダイアログが出て起動が止まる。また子 session が CLAUDE.md の Worktree Rule に従って `/wt` で確認を求めると止まるため、指示文で確認不要と明示する。
- **掃除処理との両立**: `init-session.sh` は未変更の `worktree-*` を自動削除するため、並列起動では「EnterWorktree した直後の、まだ未変更の worktree」を別 session の SessionStart が消しうる。生きている session (registry の pid が生存) の cwd が中にある worktree は削除対象から外す。registry の cwd は EnterWorktree 後の worktree パスに追従することを確認済み。
- **repo ルートの解決**: 通常 repo / worktree は git-common-dir (`<repo>/.git`) の親。submodule は common dir の `core.worktree` から本体側のチェックアウト位置を引く (toplevel を使うと submodule 内 worktree で worktree 自身を返す)。
- EnterWorktree は origin の default branch を基点にするため、local の未 push commit は worktree に含まれない (観測: dotfiles で main が origin より先行していたとき、worktree は origin 側の commit から作られた)。
- **完了時の片付け**: `claude-task done` / `drop` はタスクの repo ルートで `delete_git_merged_branch.sh` を実行し、merge 済み branch とその worktree を消す。片付けを session の記憶に頼らず done に結びつけることで、担当 session が done し忘れて閉じても、後で bankai やユーザーが done した時点で片付く。呼び出し元の cwd が worktree 内のときは自分の cwd を消さないよう実行せず、`ExitWorktree` (keep) で抜けてからの実行を案内する。merge 判定は `git branch --merged` のため、squash merge された branch は対象外 (残る)。

## 9. 種別 (type) と epic

- **決定**: タスクに type を持たせる。`analysis` 分析 / `work` 作業 (既定) / `request` 依頼 / `epic`。issue の Type と同じく一次分類とし、表示ラベルだけでなく起動と完了の挙動を CLI で変える。
  | | analysis | work | request | epic |
  |---|---|---|---|---|
  | 成果物 | 結論 (問題なし / issue / Slack) | PR / issue / Slack 報告 | 他者の返答 | 子の完了 |
  | 起動時 worktree | 切らない | 切る | 切らない | 切らない |
  | `done` | result 必須 | prs も result も無ければ警告 | 制約なし | 未完了の子があれば拒否 |
  | session の役割 | 調べて結論を出す | 実装して PR 等を出す | 依頼文の作成・催促 (任意) | 振り分けと進捗の親 (子を積み、起動を提案) |
- **理由**: 分析と作業は完了の定義が違う (分析は「問題ない」と分かれば PR 無しで閉じてよい)。種別が無いと、分析 session が PR を作ろうとしたり、結論を残さず done したりする。完了条件を script に置けば、LLM の判断に頼らず結論が result に残る。
- **完了手順の注入**: 担当 session への注入文は `claude-task brief` が種別ごとに決め、SessionStart hook はそれを出すだけ。種別の知識を hook と skill に分散させない。
- **自分がするレビューは作業**: 往復はあっても、自分が成果物 (レビュー) を出す点で作業と同じ。区分を増やすと分類で迷う。動作確認・検証は成果物が結論なので分析、環境への適用は Slack 報告で閉じるので作業。
- **依頼は status `waiting`**: 他者待ちは session が無くても続く状態のため、running とは別の status にする。`waiting_on` (相手・URL) を入れると waiting になる。他者待ちを依頼タスクにしておくと、それを blocked_by に持つタスクの「何待ちか」が一覧に出る (GitHub に書かれた待ちは引き続き claude-session-deps)。
- **epic の session は振り分けと進捗のルート**: epic は成果物を作る session ではなく、ユースケースごとに起動する親 session。`claude-task tree` で子と依存を把握し、子は epic の session から `/hadou parent: <epic> ...` で積み、着手できる子の起動 (`/hadou <n>`) をユーザーに提案する。自分では実装しない。そのため epic の queued は「着手可」ではなく「親 session が未起動」を意味し、一覧では通常タスクの「起動可能」と分けて「親 session 未起動」と出す (子が全部進行中でも epic の session は起動してよい)。done 後の「起動可能になったタスク」にも epic は出さない。
- **epic は 1 段、子が parent を持つ**: 子一覧を epic 側に保存すると parent と二重管理になるため、子の parent だけを保存し、子一覧・進捗は導出する。入れ子は持たない (tree と Slack 段落が 1 対 1 で単純)。epic 内の順序 (B の後に C) は既存の blocked_by で表し、`claude-task tree` が epic 内の最初の待ち先の下に字下げして見せる。
- **summary は epic に統合**: 機能ごとの段落 (summary) と epic は同じ「ユースケースのまとまり」を表すため、epic の子は epic 単位で Slack 段落を作る。summary は epic の見出しと、epic に属さないタスクの段落にだけ使う。既存の summary のまとまりは `/bankai` が epic 化を提案する (自動移行はしない)。
- **後方互換**: 種別追加前の JSON は書き換えず、読むときに `type: work` などの既定値で補う (`JQ_NORM`)。

## 10. 今後 (Phase 3)

- claude-session-deps の graph にタスク層を足す。PR が merge されたらタスクを done 候補として表示する。
- `.deps` の pr/remote 宣言をタスクの `blocked_by` に吸収する。
