#!/bin/bash
#
# SessionStart hook: セッションID記録 + active plan復元
#
# 1. PID→session_id マッピングを保存（tmux等の外部ツール参照用）
# 2. compact時にactive planの内容をコンテキストに注入
#
# 設計思想: dotfiles/claude/docs/plan-system-design.md を読んでから変更すること。
#
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "new"')

PLANS_DIR="$HOME/.claude/plans"
SESSION_DIR="$PLANS_DIR/.sessions"
ACTIVE_DIR="$PLANS_DIR/.active"
DEPS_DIR="$PLANS_DIR/.deps"
SESSIONS_REGISTRY_DIR="$HOME/.claude/sessions"
mkdir -p "$SESSION_DIR" "$ACTIVE_DIR" "$DEPS_DIR"

# --- session_id をPIDベースで記録（外部ツール参照用） ---
if [[ -n "$SESSION_ID" ]]; then
  echo "$SESSION_ID" > "$SESSION_DIR/$PPID"
fi
# 24h超の古いファイルをcleanup
find "$SESSION_DIR" -type f -mmin +1440 -delete 2>/dev/null || true
# 7日超のactive plan残骸をcleanup
find "$ACTIVE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
# 7日超のsession依存(.deps)残骸をcleanup (claude-session-deps が宣言するファイル)
find "$DEPS_DIR" -type f -mtime +7 -delete 2>/dev/null || true

# --- worktree cleanup (残骸検出・削除) ---
# compact: セッション継続中のため対象外 / fork: 並行セッションの worktree を消すリスクがあるため対象外
if [ "$TRIGGER" != "compact" ] && [ "$TRIGGER" != "fork" ]; then
  # 1. 参照切れ(ディレクトリ消失)の worktree エントリを掃除
  git worktree prune 2>/dev/null || true

  # 2. prune 後に残った worktree-* ブランチで、アクティブでないものを削除
  STALE_BRANCHES=()
  ACTIVE_WTS=$(git worktree list --porcelain 2>/dev/null | grep '^branch ' | sed 's|^branch refs/heads/||')
  for branch in $(git branch --list 'worktree-*' --format='%(refname:short)' 2>/dev/null); do
    if ! echo "$ACTIVE_WTS" | grep -qx "$branch"; then
      STALE_BRANCHES+=("$branch")
    fi
  done
  if [ ${#STALE_BRANCHES[@]} -gt 0 ]; then
    for b in "${STALE_BRANCHES[@]}"; do
      git branch -D "$b" 2>/dev/null || true
    done
    echo "Cleaned up stale worktree branches: ${STALE_BRANCHES[*]}"
  fi

  # 3. ディレクトリが残っている worktree-* を差分で判定
  CLEANED_WTS=()
  DIRTY_WTS=()
  while IFS= read -r line; do
    wt_path=$(echo "$line" | awk '{print $1}')
    wt_branch=$(echo "$line" | sed 's/.*\[//;s/\]//')
    [[ "$wt_branch" != worktree-* ]] && continue
    if [ -z "$(git -C "$wt_path" status --porcelain 2>/dev/null)" ]; then
      git worktree remove "$wt_path" 2>/dev/null || true
      git branch -D "$wt_branch" 2>/dev/null || true
      CLEANED_WTS+=("$wt_branch")
    else
      DIRTY_WTS+=("$wt_branch ($wt_path)")
    fi
  done < <(git worktree list 2>/dev/null | tail -n +2)
  if [ ${#CLEANED_WTS[@]} -gt 0 ]; then
    echo "Auto-removed clean worktrees: ${CLEANED_WTS[*]}"
  fi
  if [ ${#DIRTY_WTS[@]} -gt 0 ]; then
    echo "⚠ Worktrees with uncommitted changes (manual cleanup needed): ${DIRTY_WTS[*]}"
  fi
fi

# --- active plan tracking ---
if [ "$TRIGGER" = "compact" ]; then
  ACTIVE_FILE="$ACTIVE_DIR/${SESSION_ID}"
  if [ -f "$ACTIVE_FILE" ]; then
    PLAN_PATH=$(cat "$ACTIVE_FILE")
    if [ -f "$PLAN_PATH" ]; then
      echo "## Active Plan: ${PLAN_PATH}"
      echo "## Session ID: ${SESSION_ID}"
      echo ""
      cat "$PLAN_PATH"
    fi
  fi
else
  echo "Session ID: ${SESSION_ID}"
  echo "To track your active plan, write the plan path to: $ACTIVE_DIR/${SESSION_ID}"

  # --- plan INDEX 再生成 (検索型オンデマンド参照の索引) ---
  "$HOME/.claude/hooks/plan-index.sh" || true

  # --- 自分以外のセッションの active plan を表示 ---
  for f in "$ACTIVE_DIR"/*; do
    [ -f "$f" ] || continue
    other_session_id=$(basename "$f")
    [ "$other_session_id" = "$SESSION_ID" ] && continue
    other_plan_path=$(cat "$f" 2>/dev/null || true)
    [ -n "$other_plan_path" ] && echo "Other session active plan: ${other_plan_path}"
  done

  # --- plan INDEX への導線 ---
  for index_file in "$PLANS_DIR"/INDEX.md "$PLANS_DIR"/*/INDEX.md; do
    [ -f "$index_file" ] && echo "Plan index: ${index_file}"
  done

  # --- 自分を待っている session がいれば通知 (新規起動時のみ。resume/clear では毎回出さない) ---
  if [ "$TRIGGER" = "startup" ]; then
    MY_NAME=""
    if [ -f "$SESSIONS_REGISTRY_DIR/$PPID.json" ]; then
      MY_NAME=$(jq -r '.name // empty' "$SESSIONS_REGISTRY_DIR/$PPID.json" 2>/dev/null) || MY_NAME=""
    fi
    if [ -n "$MY_NAME" ]; then
      WAITERS=()
      for f in "$DEPS_DIR"/*; do
        if [ ! -f "$f" ]; then
          continue
        fi
        while IFS= read -r dep; do
          if [ -z "$dep" ]; then
            continue
          fi
          dep_type=$(jq -r '.type // empty' <<<"$dep" 2>/dev/null) || continue
          if [ "$dep_type" = "session" ]; then
            dep_name=$(jq -r '.name // empty' <<<"$dep" 2>/dev/null) || continue
            if [ "$dep_name" = "$MY_NAME" ]; then
              waiter_sid=$(basename "$f")
              WAITERS+=("${waiter_sid:0:8}")
            fi
          fi
        done <"$f"
      done
      if [ "${#WAITERS[@]}" -gt 0 ]; then
        echo "Waited by: $(IFS=,; echo "${WAITERS[*]}") が、この session (name: ${MY_NAME}) の完了を待っています。詳細は \`claude-session-deps\` を参照"
      fi
    fi
  fi
fi
