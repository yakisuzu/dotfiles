#!/bin/bash
# 指定期間の自分の GitHub 実績 (PR 中心) を JSON で取得する。
#
# Usage:
#   fetch_activity.sh START END [gh search 追加引数...]
#
#   START / END: YYYY-MM-DD
#   追加引数の例: --owner my-org / --repo my-org/my-repo
#
# 出力 (stdout): {merged_prs: [...], open_prs: [...]}
#   merged_prs: 期間内にマージされた自分の PR
#   open_prs:   期間内に作成され、まだ open な自分の PR (進行中の把握用)
#
# Requires: gh (認証済み), jq

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 START END [gh search args...]" >&2
  exit 1
fi

start="$1"
end="$2"
shift 2

for d in "$start" "$end"; do
  if ! [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "Error: date must be YYYY-MM-DD (got: $d)" >&2
    exit 1
  fi
done

pr_fields="number,title,repository,url,createdAt,closedAt,labels"

merged=$(gh search prs --author=@me --merged --merged-at "${start}..${end}" \
  --limit 300 --json "$pr_fields" "$@")

open_prs=$(gh search prs --author=@me --state open --created "${start}..${end}" \
  --limit 100 --json "$pr_fields" "$@")

jq -n \
  --argjson merged "$merged" \
  --argjson open "$open_prs" \
  '{merged_prs: $merged, open_prs: $open}'
