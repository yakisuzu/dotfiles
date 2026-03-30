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
