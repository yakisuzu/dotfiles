---
name: delegate
description: 現在の tmux session 内に新しい window を開き、名前付きの Claude Code session を起動してプロンプトを渡す。別の作業を他 session に切り出したいとき、並行して進めたいサブタスクがあるときに使う。
argument-hint: "[task: T-<n>] [dir: <path>] <渡したい指示文>"
allowed-tools: Bash(tmux *), Bash(claude-task *)
---

# Delegate Skill

現在の tmux の中に新しい window を作り、そこで `claude --name <name> <prompt>` を起動する。新しい window は現在の session とは独立した Claude Code session になり、渡したプロンプトがその session の最初の発言として自動送信される。

このスキルが行うのは「別 window を起動してプロンプトを渡す」ことだけ。タスク管理 (`claude-task`) と紐付ける場合は `task:` を渡す。新 session には環境変数 `CLAUDE_TASK_ID` が渡り、SessionStart hook がタスクと session を自動で紐付ける (running 化)。自動起動の上限判定は呼び出し側 (`/bankai` の `claude-task next --auto`) の責務で、このスキルは上限を見ない (明示的な起動指示は上限を超えてよい)。

## Arguments

`$ARGUMENTS` から以下を読み取る。

- `task: T-<n>` — 任意。`claude-task` のタスク ID。直後の 1 トークンを値として消費する。指定時は起動 dir とプロンプトを `claude-task launch-spec <id>` の出力で決める (自分で組み立てない)。`dir:` との併用は不可 (起動 dir は常に本体 repo のルート)。
- `dir: <path>` — 任意。新 session の作業ディレクトリ。直後の 1 トークン (空白区切り) を値として消費する。省略時は現在の cwd。worktree を切ってから渡したい場合は、先に `/wt` で worktree を作成し、そのパスを `dir:` に指定する。
- プロンプト本体 — `task:` / `dir:` として認識した部分を除いた残り全文 (前後どちらにあってもよい) をそのままプロンプトとして扱う。`prompt:` のようなキーワードは不要。

name は受け付けない。window / session の名前は常に Steps 1 でプロンプトの内容から自動生成する。

プロンプトから委譲すべきタスクの内容が全く読み取れないとき (`task:` も無く、`$ARGUMENTS` が空、または意味を成さない文字列しかないとき) だけ、作業を進めず AskUserQuestion もしくは聞き返しで確認する。

## Steps

1. **プロンプトを確定し、name を生成する**
   - `task:` があれば `claude-task show <id>` で JSON を読む。status が `done` / `dropped` なら起動せず報告して止める。`running` で session が生きている (`claude-task ls` の返事待ち/実行中に出ている) なら二重起動になるため止めて報告する。
   - `task:` 指定時: `claude-task launch-spec <id>` の `prompt` をそのままプロンプトにする (先頭の `[T-<n>]` と、起動後に EnterWorktree で worktree を切る指示が埋め込み済み)。残り全文があれば `prompt` の末尾に改行 2 つを挟んで追記する。
   - `task:` 無し: `dir:` を取り除いた残り全文をプロンプトとする。
   - プロンプトの内容が全く特定できない場合のみ、ここで止めてユーザーに確認する。
   - プロンプトの内容を要約した 2〜4 単語程度の kebab-case 名を自分で生成する (英数字・ハイフンのみ、日本語の要旨はローマ字化や英訳で短く)。例: 「issue #123 の事前リファクタ (Foo を Bar に分離) をやって」→ `refactor-foo-bar` のような名前にする。

2. **tmux 内で実行されているか確認する**
   ```bash
   [ -n "$TMUX" ] || echo "NOT_IN_TMUX"
   ```
   `NOT_IN_TMUX` が出たら、tmux の外では新 window を作れない旨を伝えて中断する。

3. **名前の重複を確認する**
   ```bash
   tmux list-windows -a -F '#{window_name}' | grep -Fx "$NAME" && echo "WINDOW_NAME_EXISTS"
   ```
   自動生成した名前が既存 window と被っていても、確認せず `-2`/`-3` のように連番を付けて重複を避け、そのまま続行する (ユーザーが明示的に選んだ名前ではないため)。Claude Code 自体も同名 session が居れば起動時に別名へ自動リネームするため、**session としての衝突は起きない**。

4. **作業ディレクトリを決める**
   - `task:` 指定時は `launch-spec` の `dir` (本体 repo のルート) を使う。**worktree を先に切って dir に渡さない** (新しい dir ごとに信頼確認ダイアログが出て止まるため。worktree は子 session が起動後に自分で切る)。
   - それ以外は `dir:` が指定されていればそれを使う。存在確認する: `[ -d "$DIR" ]`。
   - 指定が無ければ `pwd` (現在の cwd) を使う。
   - 指定ディレクトリが Claude Code にとって未信頼のフォルダだと、新 session は起動直後に信頼確認ダイアログで止まる (自動では解除しない — ユーザーの明示的な信頼承認が必要なため)。この場合は「`<dir>` が未信頼のため起動直後に確認待ちで止まっている」と報告する。

5. **コマンドを安全に組み立てて window を起動する**

   name と prompt は `printf %q` で一度だけシェルエスケープする (二重エスケープしない。tmux は渡された文字列を 1 回だけ shell に渡すため)。

   ```bash
   NAME_Q=$(printf %q "$NAME")
   PROMPT_Q=$(printf %q "$PROMPT")
   CMD="claude --name $NAME_Q $PROMPT_Q"
   # task: 無し
   tmux new-window -d -n "$NAME" -c "$DIR" "$CMD"
   # task: 有り (どちらか一方だけ実行する)。-e で task ID を渡し、SessionStart hook が claude-task link する
   tmux new-window -d -n "$NAME" -c "$DIR" -e "CLAUDE_TASK_ID=$TASK_ID" "$CMD"
   ```

   - `-d`: window を作るが focus は移さない (今の作業を中断しない)。
   - プロンプトに `` $() `` や バッククォートや二重引用符を含んでいても、`printf %q` によってリテラル文字列として渡る (コマンドインジェクションしない)。これは実際に特殊文字を含むプロンプトで動作確認済み。

6. **起動確認**

   数秒待ってから session registry に登録されたか確認する。
   ```bash
   sleep 3
   for f in ~/.claude/sessions/*.json; do
     jq -r 'select(.name=="'"$NAME"'") | [.name,.sessionId,.pid,.status] | @tsv' "$f" 2>/dev/null
   done
   ```
   `task:` 指定時は `claude-task show <id> | jq '{status,session_name}'` が `running` になっていることも確認する。
   何も出ない場合は信頼確認ダイアログ等で止まっている可能性がある。`tmux capture-pane -t "$NAME" -p | tail -20` で画面を見て報告する。

7. **結果をユーザーに伝える**

   - 起動した window 名 (自動生成したこと)、作業ディレクトリ、渡したプロンプトの要旨を簡潔に報告する。
   - 他 window への切替は `tmux select-window -t <name>` (このスキルでは自動では切り替えない)。
   - 完了通知が欲しい場合は `SendMessage` の `notify_when_idle: true` を該当 session 宛てに張る (`/bankai` 経由の起動では bankai 側が張る)。

## Non-goals (現時点)

- 依存関係・残タスクの管理 — `claude-task` / `/bankai` に委ねる。このスキルは起動だけ。
- 自動起動の上限判定 — `/bankai` (`claude-task next --auto`) の責務。
- worktree の自動作成 — `/wt` skill に委ねる。このスキルは `dir:` を受け取るだけ。
- background session (`claude --bg`) への対応 — tmux window 方式のみ。agent view TUI には出ない点を把握しておくこと。

## Example

```
/delegate task: T-12
/delegate dir: ~/work/<org>/<repo> issue #123 の事前リファクタ (Foo を Bar に分離) をやってください。完了したら PR を作成してください。
```
