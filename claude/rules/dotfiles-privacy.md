# Dotfiles Privacy

- dotfiles (このrepo配下で git 管理されるファイル: CLAUDE.md / rules / skills / hooks / scripts 等) には、所属組織名・プロジェクト名・リポジトリ名など PJ 固有情報を含めない
- 具体例や mapping で PJ 名が必要な場合は、一般化した名前 (例: `<org>/<repo>`, `project-a`) に置き換える

**Why:** dotfiles は個人設定として共有・公開されうるため、組織名やプロジェクト名を含めると意図せず所属先や取引先情報が漏洩するリスクがある

**How to apply:**
- dotfiles 配下のファイルを編集・新規作成する際、コミット前に org 名・repo 名などの固有名詞が紛れていないか確認する
- `~/.claude/CLAUDE.local.md` など個人ローカル専用ファイル (gitignore 対象で dotfiles にコミットされない実データ) はこの規則の対象外。PJ 固有情報を記載してよい
- dotfiles 配下にテンプレートとして置く `claude/CLAUDE.local.md` は空のテンプレートのまま維持し、実データ (org 名・repo 名) を書き込まない
- 確認は「見た目で org 名っぽいか」の目視判断だけに頼らない。`~/.claude/CLAUDE.local.md` の Plan Group mapping に登場する org 名・repo 名・グループ略称 (例のような一般名詞に紛れる社内コードネームを含む) を対象に、変更差分を grep して一致がないか機械的に確認する

