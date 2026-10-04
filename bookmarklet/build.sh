#!/bin/bash -e
# .user.js から bookmarklet (javascript: URL) を生成する
#   usage: bookmarklet/build.sh bookmarklet/x-old-post-cleaner.user.js
#   出力: stdout に URL。macOS なら pbcopy にも入れる
# コメント行 (userscript metadata 含む) を落としてから URL エンコードする

SRC="$1"
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "usage: $0 <file.user.js>" >&2
  exit 1
fi

URL=$(node -e '
const fs = require("fs");
// 行頭コメント・空行・行頭インデントを落とす (複数行テンプレートリテラルは使わない前提)
const src = fs.readFileSync(process.argv[1], "utf8")
  .split("\n")
  .map((l) => l.trimStart())
  .filter((l) => l && !l.startsWith("//"))
  .join("\n");
process.stdout.write("javascript:" + encodeURIComponent(src));
' "$SRC")

echo "$URL"
if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$URL" | pbcopy
  echo "copied to clipboard (${#URL} bytes)" >&2
fi
