---
name: wt
description: 未コミットの git 変更を確認し、worktree への切り替えを提案する。既存の変更があるブランチで新しい作業を始めるとき、または CLAUDE.md の Worktree Rule が発動したときに使用する。
argument-hint: "[base branch: <branch>] [name: <worktree-name>]"
allowed-tools: Bash(git *) EnterWorktree
---

# Worktree Proposal Skill

現在のブランチと未コミット変更を確認し、状況に応じた適切なアクションを提案する。

## Arguments

- `base branch: <branch>` — (任意) worktree のベースブランチ (例: `qa`, `master`)。指定された場合、worktree 作成後に `origin/<branch>` へ reset する。
- `name: <worktree-name>` — (任意) worktree の名前。EnterWorktree に渡す。

## Steps

1. 以下のコマンドでブランチと変更を検出する:
   ```
   git branch --show-current
   git diff --stat
   git diff --cached --stat
   ```

2. 状況を判定し、それに応じて行動する:

### Case A: main/master + 変更なし
「main に未コミット変更はありません。このまま作業を進めます」と報告して終了する。

### Case B: main/master + 変更あり
変更のサマリを表示し、ユーザーに選択肢を提示する:
- **wt**: worktree に切り替えて新しい作業を隔離する (既存の未コミット変更を保護)
- **continue**: 現在のブランチのまま進める

### Case C: feature ブランチ + 変更あり
変更のサマリを表示し、ユーザーに選択肢を提示する:
- **wt**: worktree に切り替えて新しい作業を隔離する (feature ブランチ上の既存の未コミット変更を保護)
- **continue**: 現在の feature ブランチのまま進める

### Case D: feature ブランチ + 変更なし
現在のブランチ名を報告し、このブランチでの前の作業が完了しているかユーザーに確認する:
- **done**: 前の作業は完了 → main/master に戻って pull する
- **wt**: 前の作業は未完了 → 新しいタスク用に worktree (main/master ベース) へ切り替える

3. 選択されたアクションを実行する:

**wt の場合 (Case B または C):**
   - `EnterWorktree` ツールで worktree に切り替える (`name` があれば渡す)
   - **`base branch` が指定されていた場合**、以下を実行して対象ブランチに載せ替える:
     ```bash
     git fetch origin <branch> && git reset --hard origin/<branch> && git branch -u origin/<branch>
     ```
   - `git log origin/<branch>..HEAD --oneline` で結果を確認する (空であるべき)
   - 切り替えを報告し、元のタスクを再開する

**done の場合 (Case D):**
   - デフォルトブランチ名 (`main` か `master`) を検出する
   - `git checkout <default-branch> && git pull` を実行する
   - 切り替えを報告し、元のタスクを再開する

**wt の場合 (Case D):**
   - `EnterWorktree` ツールで worktree に切り替える (`name` があれば渡す)
   - main/master へ reset する:
     ```bash
     git fetch origin <default-branch> && git reset --hard origin/<default-branch> && git branch -u origin/<default-branch>
     ```
   - `git log origin/<default-branch>..HEAD --oneline` で結果を確認する (空であるべき)
   - 切り替えを報告し、元のタスクを再開する

**continue の場合:**
   - 切り替えずに現在のブランチで作業を進める
