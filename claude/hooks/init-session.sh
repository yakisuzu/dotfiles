#!/bin/bash
#
# SessionStart hook: セッションID記録 + active plan復元
#
# 1. PID→session_id マッピングを保存（tmux等の外部ツール参照用）
# 2. compact時にactive planの内容をコンテキストに注入
#
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "new"')

PLANS_DIR="$HOME/.claude/plans"
SESSION_DIR="$PLANS_DIR/.sessions"
ACTIVE_DIR="$PLANS_DIR/.active"
mkdir -p "$SESSION_DIR" "$ACTIVE_DIR"

# --- session_id をPIDベースで記録（外部ツール参照用） ---
if [[ -n "$SESSION_ID" ]]; then
  echo "$SESSION_ID" > "$SESSION_DIR/$PPID"
fi
# 24h超の古いファイルをcleanup
find "$SESSION_DIR" -type f -mmin +1440 -delete 2>/dev/null || true

# --- worktree cleanup (残骸検出・削除) ---
if [ "$TRIGGER" != "compact" ]; then
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
fi
