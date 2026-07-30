#!/bin/bash
# SessionEnd hook: active plan の追跡ファイルを削除する
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

ACTIVE_DIR="$HOME/.claude/plans/.active"
rm -f "$ACTIVE_DIR/$SESSION_ID"
