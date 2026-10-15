---
name: bankai
description: 秘書としてタスク全体を把握し振り分ける。claude-task の残タスク・返事待ち session・ブロック状況を報告し、inbox の振り分けや優先度・メタ情報の整理を行う。「残タスクは？」「今どうなってる？」「タスクを整理して」などで使う。session の起動はしない (起動は /kidou <n>)。常駐はせず、呼ばれたときだけ動く。
argument-hint: ""
allowed-tools: Bash(claude-task *)
---

# Bankai Skill

状態の正は `claude-task` (ファイル)。この skill は把握・報告・整理だけを行い、**状態を自分の記憶や会話に持たない**。毎回 `claude-task ls --json` を読み直す。

**session は起動しない**。起動は番号指定の `/kidou <n> [<n> ...]` だけ (一括起動の機能は持たない)。起動を勧めるときは、ユーザーがそのまま打てる `/kidou 6 21` の形で示す。

## Steps

1. **把握**: `claude-task ls` (人間向け) と必要に応じ `claude-task ls --json` を読む
2. **報告と整理** (短く、優先度順。個々のタスクの列挙は Step 4 の表に任せ、ここでは判断が要るものだけ書く):
   - **優先度 1 (復旧) が未着手・ブロック中なら最初に書く**。未着手なら `/kidou <n>` での起動を提案する
   - 優先度 2 (優先) の返事待ち session は、待っている人がいるので返事待ちの中でも先に挙げる
   - **返事待ち (idle)**: ユーザーの番の session。最優先で示す (`tmux select-window -t <session_name>` で移動できる)
   - **要確認**: running なのに session が終了済み。`claude-task show` の log と prs (`gh pr view` で merge 済みか) を見て、完了していそうなら `done` を、途中なら `/kidou <n>` での再起動を提案する (勝手に done にしない)。PR merge 後に done せず session を閉じたケースが多く、`done` すると worktree / branch の片付けも走る
   - **inbox**: dir 未定のタスク。body から dir を推定し、一意なら `claude-task set <id> dir=<dir>` を実行してよい。曖昧なものはまとめて AskUserQuestion で確認
   - **タスク外 session**: ユーザーが手動で立てた session。追跡したそうなら `claude-task adopt <name> [title]` を提案
   - **ブロック中 / 起動可能**: 件数と先頭数件。起動可能なものは `/kidou <n> ...` の形で提案する (自分では起動しない)
   - remote (claude.ai/code) session は local の registry に出ないため、PR 経由で追う (`claude-session-deps` が起動中ならそちら)。ListAgents で cloud session が見えれば補足として触れてよい
3. **一覧表示**: 最後に `claude-task ls --table` の出力 (Markdown 表: タスク / session / 概要 / 状態) を **加工せずそのまま** 貼る。dir 設定などの操作をした後に取り直す。表は自分で組み立てない (並び順・状態ラベルは script が決める)
   - **Slack 共有を求められたら**: `claude-task ls --slack` の出力 (mrkdwn。優先度ごとの見出し + 概要ごとの段落「お客さん名: 概要」+ 依存順のタスク名。番号・session・状態は出さない) を加工せずコードブロックで示し、`claude-task ls --slack | pbcopy` でコピーできると添える。Slack 用の文面も自分で組み立てない
4. **idle 通知を受けたとき** (bankai session が生きていれば): `claude-task ls` を読み直し、そのタスクの状況 (返事待ちか、完了か) を 1 行で報告。完了で起動可能になったタスクがあれば `/kidou <n>` を提案する

## 守ること

- **報告文ではタスクを title (日本語の短いタイトル) で呼ぶ**。`T-<n>` だけで言及しない (ユーザーには番号では伝わらない)。`T-<n>` を使うのは一覧表と、ユーザーが打つ操作例 (`/kidou 6` など) のときだけ。例: 「『税額配賦ロジック実装』は『請求明細の税額カラム追加』の完了待ち」
- **優先度 4 (その他) は起動を提案しない・格上げしない**。着手するには目標への格上げ調整 (ユーザーの判断) が必要。格上げはユーザーの指示で `claude-task set <id> priority=3`
- 優先度の分類 (1 復旧 / 2 優先 / 3 目標 / 4 その他) が明らかに body と食い違うタスク (例: 脆弱性対応が 3) は、1 〜 3 の範囲の付け直しは `claude-task set <id> priority=<n>` で行ってよい (旧値は log に残る)。4 との出し入れはユーザーに確認する
- customer / summary が空のタスクは、body から分かる範囲で `claude-task set <id> customer=<名前|全体> summary=<概要>` で埋めてよい。お客さん名が body から分からないものは空のまま報告し (Slack では「未確認」)、ユーザーに聞く。推測で埋めない
- title が 30 字を超える・issue 番号始まりなど分かりにくいタスクを見つけたら、`claude-task set <id> title=<日本語10-30字>` で付け直してよい (旧 title は log に残る)

- タスクファイルを直接編集しない。必ず `claude-task` のサブコマンドを使う
- `done` / `drop` はユーザーの確認か、担当 session 自身の判断でのみ行う
- 報告は「ユーザーが次に何をすべきか」が先頭に来るようにする
