---
name: bankai
description: 秘書としてタスク全体を把握し振り分ける。claude-task の残タスク・返事待ち session・ブロック状況を報告し、inbox の振り分けと起動可能タスクの session 起動を行う。「残タスクは？」「今どうなってる？」「タスクを回して」「次を起動して」などで使う。常駐はせず、呼ばれたときだけ動く。
argument-hint: "[status | go | T-<n> ...]"
allowed-tools: Bash(claude-task *), Bash(tmux *)
---

# Bankai Skill

状態の正は `claude-task` (ファイル)。この skill は判断と起動指示だけを行い、**状態を自分の記憶や会話に持たない**。毎回 `claude-task ls --json` を読み直す。

## モード (`$ARGUMENTS`)

| 引数 | 動作 |
|---|---|
| なし / `status` | Step 1-2 (報告 + inbox 振り分け提案) と Step 4 (一覧表示)。起動はしない |
| `go` | Step 1-4。自動起動の枠内で起動可能タスクを起動 |
| `T-<n> ...` | 指定タスクを **上限を無視して** 起動 (明示指示)。Step 3 の「明示」の後に Step 4 |

## Steps

1. **把握**: `claude-task ls` (人間向け) と必要に応じ `claude-task ls --json` を読む
2. **報告と整理** (短く、優先度順。個々のタスクの列挙は Step 4 の表に任せ、ここでは判断が要るものだけ書く):
   - **返事待ち (idle)**: ユーザーの番の session。最優先で示す (`tmux select-window -t <session_name>` で移動できる)
   - **要確認**: running なのに session が終了済み。`claude-task show` の log を見て、完了していそうなら `done` を、途中なら再起動を提案する (勝手に done にしない)
   - **inbox**: dir 未定のタスク。body から dir を推定し、一意なら `claude-task set <id> dir=<dir>` を実行してよい。曖昧なものはまとめて AskUserQuestion で確認
   - **タスク外 session**: ユーザーが手動で立てた session。追跡したそうなら `claude-task adopt <name> [title]` を提案
   - **ブロック中 / 起動可能**: 件数と先頭数件
   - remote (claude.ai/code) session は local の registry に出ないため、PR 経由で追う (`claude-session-deps` が起動中ならそちら)。ListAgents で cloud session が見えれば補足として触れてよい
3. **起動**:
   - **自動 (`go`)**: `claude-task next --auto --json` が返したものだけを起動する。**件数の判断を自分でしない** (上限は script 側: `CLAUDE_TASK_MAX_RUNNING`, 既定 6)。0 件なら「枠が埋まっている」と報告して終わる
   - **明示 (`T-<n>` 指定 / ユーザーが「これ起動して」と言った)**: 上限を無視して起動してよい。上限超えになる場合は 1 行その旨を添える
   - 起動は `/delegate task: T-<n>` (Skill tool) で 1 件ずつ。モデルは delegate の既定 (sonnet)。ユーザーがモデルを明示したときだけ `model: <alias>` を足す
   - **worktree ルール**: 起動 dir は常に本体 repo のルート (信頼済み dir) にし、worktree は子 session が起動直後に `EnterWorktree (name: task-<n>)` で自分で切る。この指示は `claude-task launch-spec` がプロンプトに埋め込むので、bankai は worktree を事前に作らず、`/wt` の確認もしない (先に worktree を作って dir に渡すと、新しい dir ごとに信頼確認ダイアログで止まる)。git 管理外の dir は worktree 指示なしで起動される
   - 起動後、その session に `SendMessage` の `notify_when_idle: true` を張る (この bankai session が生きている間だけ有効なベストエフォート。正は claude-task)
4. **一覧表示**: どのモードでも、最後に `claude-task ls --table` の出力 (Markdown 表: タスク / session / 概要 / 状態) を **加工せずそのまま** 貼る。起動・dir 設定などの操作をした後に取り直す。表は自分で組み立てない (並び順・状態ラベルは script が決める)
5. **idle 通知を受けたとき** (bankai session が生きていれば): `claude-task ls` を読み直し、そのタスクの状況 (返事待ちか、完了か) を 1 行で報告。完了なら Step 3 の自動起動を提案する (勝手に `go` しない)

## 守ること

- タスクファイルを直接編集しない。必ず `claude-task` のサブコマンドを使う
- `done` / `drop` はユーザーの確認か、担当 session 自身の判断でのみ行う
- 報告は「ユーザーが次に何をすべきか」が先頭に来るようにする
