#!/bin/bash
#
# claude_session_register.sh - SessionStart hookでセッションIDを記録
#
# claudeプロセスのPIDをキーにしたファイルにsession_idを保存する。
# hookはclaudeの子プロセスとして実行されるため、$PPIDでclaude PIDを取得。
#

set -euo pipefail

SESSION_DIR="/tmp/claude-sessions"
mkdir -p "$SESSION_DIR"

# stdinからJSON読み取り → session_id抽出
SESSION_ID=$(node -e "
  const chunks = [];
  process.stdin.on('data', c => chunks.push(c));
  process.stdin.on('end', () => {
    const data = JSON.parse(chunks.join(''));
    console.log(data.session_id || '');
  });
")

if [[ -n "$SESSION_ID" ]]; then
  echo "$SESSION_ID" > "$SESSION_DIR/$PPID"
fi

# 24h超の古いファイルをcleanup
find "$SESSION_DIR" -type f -mmin +1440 -delete 2>/dev/null || true
