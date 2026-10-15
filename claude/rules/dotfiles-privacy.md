# Dotfiles Privacy

- dotfiles (このrepo配下で git 管理されるファイル: CLAUDE.md / rules / skills / hooks / scripts 等) には、所属組織名・プロジェクト名・リポジトリ名など PJ 固有情報を含めない
- 具体例や mapping で PJ 名が必要な場合は、一般化した名前 (例: `<org>/<repo>`, `project-a`) に置き換える
- マシンのフルパス (`/Users/<username>/...` 等、OS のユーザー名や個人のディレクトリ構成が特定できるパス) も含めない。具体例が要る場合は `~/work/<org>/<repo>` のようにホームディレクトリは `~` に、それ以外は汎用名に置き換える

**Why:** dotfiles は個人設定として共有・公開されうるため、組織名やプロジェクト名を含めると意図せず所属先や取引先情報が漏洩するリスクがある。マシンのフルパスも OS のユーザー名という個人情報を含み、同じ理由で避ける

**How to apply:**
- dotfiles 配下のファイルを編集・新規作成する際、コミット前に org 名・repo 名などの固有名詞が紛れていないか確認する
- `~/.claude/CLAUDE.local.md` など個人ローカル専用ファイル (gitignore 対象で dotfiles にコミットされない実データ) はこの規則の対象外。PJ 固有情報を記載してよい
- dotfiles 配下にテンプレートとして置く `claude/CLAUDE.local.md` は空のテンプレートのまま維持し、実データ (org 名・repo 名) を書き込まない
- 確認は「見た目で org 名っぽいか」の目視判断だけに頼らない。`~/.claude/CLAUDE.local.md` の `Privacy Terms` 節 (org 名・repo 名・製品名・顧客名。一般名詞に紛れる社内コードネームを含む) と Plan Group mapping を対象に、変更差分を grep して一致がないか機械的に確認する
  ```bash
  terms=$(sed -n '/^## Privacy Terms/,/^## /s/^- //p' ~/.claude/CLAUDE.local.md)
  git diff origin/main..HEAD | grep -a '^+' | grep -aniwF -f <(echo "$terms")   # 未 push の全コミット。コミット前は git diff / git diff --cached
  git log origin/main..HEAD --format=%B | grep -aniwF -f <(echo "$terms")       # コミットメッセージも対象
  ```
- grep には必ず `-a` を付ける。制御文字を含むファイル (JS の区切り文字など) はバイナリとみなされ、`-a` が無いと一致しても行が出ずに見落とす
- 作業中に Privacy Terms に無い repo 名・顧客名に気づいたら、`~/.claude/CLAUDE.local.md` の Privacy Terms に追記する (Plan Group mapping は plan の振り分け用で、全 repo を網羅しない)
- フルパスの確認も同様に機械的に行う。変更差分を `/Users/` および自分の OS ユーザー名 (`whoami` の結果) で grep し、一致が無いことを確認する。コマンド出力やログをそのままファイルに貼った際に紛れ込みやすい

