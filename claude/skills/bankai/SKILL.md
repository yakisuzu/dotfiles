---
name: bankai
description: 秘書としてタスク全体を把握し振り分ける。claude-task の残タスク・返事待ち session・依頼中・epic の進み具合・ブロック状況を報告し、inbox の振り分けや優先度・メタ情報の整理を行う。「残タスクは？」「今どうなってる？」「タスクを整理して」などで使う。session の起動はしない (起動は /hadou <n>)。常駐はせず、呼ばれたときだけ動く。
argument-hint: ""
allowed-tools: Bash(claude-task *)
---

# Bankai Skill

状態の正は `claude-task` (ファイル)。この skill は把握・報告・整理だけを行い、**状態を自分の記憶や会話に持たない**。毎回 `claude-task ls --json` を読み直す。

**session は起動しない**。起動は番号指定の `/hadou <n> [<n> ...]` だけ (一括起動の機能は持たない)。起動を勧めるときは、ユーザーがそのまま打てる `/hadou 6 21` の形で示す。

## Steps

1. **把握**: `claude-task ls` (人間向け) と必要に応じ `claude-task ls --json` を読む
2. **報告と整理** (短く、優先度順。個々のタスクの列挙は Step 4 の表に任せ、ここでは判断が要るものだけ書く):
   - **優先度 1 (復旧) が未着手・ブロック中なら最初に書く**。未着手なら `/hadou <n>` での起動を提案する
   - 優先度 2 (優先) の返事待ち session は、待っている人がいるので返事待ちの中でも先に挙げる
   - **返事待ち (idle)**: ユーザーの番の session。最優先で示す (`tmux select-window -t <session_name>` で移動できる)
   - **依頼中 (waiting)**: 他の人の返答待ち。`claude-task show` の log で依頼してからの日数を見て、数日動きが無いものは催促 (`/hadou <n>` で催促文作成) を提案する。返答済みと分かれば done を提案
   - **要確認**: running なのに session が終了済み。`claude-task show` の log と prs (`gh pr view` で merge 済みか) を見て、完了していそうなら `done` を、途中なら `/hadou <n>` での再起動を提案する (勝手に done にしない)。PR merge 後に done せず session を閉じたケースが多く、`done` すると worktree / branch の片付けも走る
   - **inbox**: dir 未定のタスク。body から dir を推定し、一意なら `claude-task set <id> dir=<dir>` を実行してよい。曖昧なものはまとめて AskUserQuestion で確認
   - **タスク外 session**: ユーザーが手動で立てた session。追跡したそうなら `claude-task adopt <name> [title]` を提案
   - **ブロック中 / 起動可能**: 件数と先頭数件。起動可能なものは `/hadou <n> ...` の形で提案する (自分では起動しない)
   - **epic**: epic はユースケースごとの振り分け・進捗の親 session として起動するもの (成果物は作らない)。一覧の「親 session 未起動」は表示の誤りではない (通常タスクの「起動可能」= 着手可 とは別の意味)
     - `claude-task tree` で各 epic の子の進み具合と依存を見て、「epic『…』は分析が終わり、次は『…』が起動可能」の粒度で 1 行ずつ報告する
     - 親 session が未起動で、未完了の子がある epic は `/hadou <epic の番号>` での起動を提案する (子が全部進行中でも、振り分けと進捗の窓口として起動してよい)
     - 起動済みの epic の session が返事待ちなら、その epic の子の相談先としてそれを示す (`tmux select-window -t <session_name>`)
     - 子がすべて終わった epic は done を提案する
   - remote (claude.ai/code) session は local の registry に出ないため、PR 経由で追う (`claude-session-deps` が起動中ならそちら)。ListAgents で cloud session が見えれば補足として触れてよい
3. **一覧表示**: 最後に `claude-task ls --table` の出力 (Markdown 表: タスク / 優先度 / 種別 / session / 概要 / 状態) を **加工せずそのまま** 貼る。dir 設定などの操作をした後に取り直す。表は自分で組み立てない (並び順・状態ラベルは script が決める)
   - **Slack 共有を求められたら**: `claude-task ls --slack` の出力 (mrkdwn。優先度ごとの見出し + 概要ごとの段落「お客さん名: 概要」+ 依存順のタスク名。番号・session・状態は出さない) を加工せずコードブロックで示し、`claude-task ls --slack | pbcopy` でコピーできると添える。Slack 用の文面も自分で組み立てない
4. **idle 通知を受けたとき** (bankai session が生きていれば): `claude-task ls` を読み直し、そのタスクの状況 (返事待ちか、完了か) を 1 行で報告。完了で起動可能になったタスクがあれば `/hadou <n>` を提案する

## 守ること

- **報告文ではタスクを title (日本語の短いタイトル) で呼ぶ**。`T-<n>` だけで言及しない (ユーザーには番号では伝わらない)。`T-<n>` を使うのは一覧表と、ユーザーが打つ操作例 (`/hadou 6` など) のときだけ。例: 「『税額配賦ロジック実装』は『請求明細の税額カラム追加』の完了待ち」
- **優先度 4 (その他) は起動を提案しない・格上げしない**。着手するには目標への格上げ調整 (ユーザーの判断) が必要。格上げはユーザーの指示で `claude-task set <id> priority=3`
- 優先度の分類 (1 復旧 / 2 優先 / 3 目標 / 4 その他) が明らかに body と食い違うタスク (例: 脆弱性対応が 3) は、1 〜 3 の範囲の付け直しは `claude-task set <id> priority=<n>` で行ってよい (旧値は log に残る)。4 との出し入れはユーザーに確認する
- customer / summary が空のタスクは、body から分かる範囲で `claude-task set <id> customer=<名前|全体> summary=<概要>` で埋めてよい。お客さん名が body から分からないものは空のまま報告し (Slack では「未確認」)、ユーザーに聞く。推測で埋めない
- title が 30 字を超える・issue 番号始まりなど分かりにくいタスクを見つけたら、`claude-task set <id> title=<日本語10-30字>` で付け直してよい (旧 title は log に残る)

- **種別 (type) の整理**: 種別追加前のタスクは作業 (work) 扱い。body・title から明らかに分析 (調査・検証・動作確認で PR を作らない) や依頼 (他者待ち) なものは `claude-task set <id> type=<analysis|request>` で付け直してよい (旧値は log に残る)。迷うものは触らない
- **epic 化の提案**: epic に属さない未完了タスクのうち、同じ summary を持つものが 2 件以上ある、または blocked_by でつながっているものは、epic にまとめるとよい。勝手に作らず、「『<summary>』を epic にまとめますか」と提案し、合意したら `claude-task add --type epic --summary <summary> --customer <..> --dir <..> --priority <子の最小値> -- <title>` → 子に `claude-task set <id> parent=<epic>`
- epic の順序 (子 B の後に子 C) は `blocked_by` で表す。順序が body から明らかで blocked_by が欠けていれば `claude-task set <C> blocked_by=<B>` を提案する

- タスクファイルを直接編集しない。必ず `claude-task` のサブコマンドを使う
- `done` / `drop` はユーザーの確認か、担当 session 自身の判断でのみ行う
- 報告は「ユーザーが次に何をすべきか」が先頭に来るようにする
