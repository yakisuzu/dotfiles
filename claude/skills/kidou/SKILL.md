---
name: kidou
description: TODO (タスク) を claude-task のキューに積む。「あとでやる」「TODO に積んで」「タスク追加」など、今の session では着手せず別 session で処理したい依頼を受けたときに使う。どの session からでも呼べる。振り分け・起動は /bankai が行う。
argument-hint: "[dir: <path>] [after: T-<n>,...] [p1|p2|p3] <依頼文>"
allowed-tools: Bash(claude-task *)
model: sonnet
---

# Kidou Skill

依頼を `claude-task` のタスクとして積むだけの軽い skill。**ここでは作業に着手しない・session も起動しない** (起動は `/bankai` または `/delegate task:`)。ユーザーへの確認も原則しない (積む動作を軽く保つ)。

## Arguments

- `dir: <path>` — 任意。作業ディレクトリ。直後の 1 トークン
- `after: T-1,T-2` — 任意。先に終わっている必要があるタスク (blocked_by)
- `p1` / `p2` / `p3` — 任意。優先度 (既定 p2)
- 残り全文 — 依頼文

依頼が複数の独立した作業を含む場合は、タスクを分けて積む (順序があれば後のものに `--blocked-by` を付ける)。

## Steps

1. **title を作る**: 依頼文を 1 行 (40 字程度) に要約。依頼文そのものは `--body` に全文渡す (起動された session への最初のプロンプトになる。後から読んでも分かるよう、会話中の文脈 — issue 番号、ファイル、決定事項 — を補って自己完結させる)
2. **dir を決める** (上から順に、一意に決まったら採用。決まらなければ空のまま = inbox):
   1. `dir:` の明示
   2. 依頼文に repo 名・issue URL・パスがある → `~/work/<org>/<repo>` 等の実在パスに解決 (`ls -d` で存在確認)
   3. 依頼が明らかに現在の repo に関するもの → 現在の repo のルート
   - 推測が 2 候補以上に割れる場合は **聞かずに空** にする (`/bankai` が判定する)
   - dir は `~` 始まりで渡す (ホームのフルパスをファイルに残さない)
3. **重複確認**: `claude-task ls --all --json | jq -r '.tasks[] | select(.status != "done" and .status != "dropped") | "\(.id)\t\(.title)"'` を見て、同じ内容の未完了タスクがあれば追加せず既存 ID を報告する (内容を足したいなら `claude-task log <id> <追記>`)
4. **追加**:
   ```bash
   claude-task add [--dir <dir>] [--priority N] [--blocked-by T-1,T-2] --body "<自己完結した依頼文>" -- "<title>"
   ```
   - 引数はシェルのクォートに注意 (依頼文に `"` や `$` が含まれる場合は heredoc で変数に入れてから渡す)
5. **報告**: 1 行で `T-<n> を積みました (<repo or inbox>)` と返す。起動したいなら `/bankai` か `/delegate task: T-<n>` と添える
6. **一覧表示**: 最後に `claude-task ls --table` の出力 (Markdown 表: タスク / session / 概要 / 状態) を **加工せずそのまま** 貼る。表は自分で組み立てない
