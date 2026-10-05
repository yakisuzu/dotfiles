#!/bin/bash
# SessionEnd hook: session 終了時の追跡ファイル掃除 (active plan / session 依存)
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

PLANS_DIR="$HOME/.claude/plans"
ACTIVE_DIR="$PLANS_DIR/.active"
DEPS_DIR="$PLANS_DIR/.deps"

rm -f "$ACTIVE_DIR/$SESSION_ID"
rm -f "$DEPS_DIR/$SESSION_ID"
