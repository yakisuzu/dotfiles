# Local Settings (personal, not committed)

## Plan Group

Map working directory patterns to plan group names.
Plans are saved to `~/.claude/plans/<group>/`.
Pattern は cwd のパスに前方一致 (部分一致) で照合する。subdir は親 repo の 1 行で拾えるので subdir ごとの行は書かない。最初に一致した行を採用するので、具体的な行を先に、fallback (`<org>/` 等) を最後に書く。
root 直下 (`~/.claude/plans/*.md`) は未整理の置き場。mapping に無い repo の plan が落ちたら、mapping を足して group に移す。

Format: `- <dir_pattern>: <group>`

Mappings (例):
- dotfiles: dotfiles
- <org>/<product-a-repo>: product-a
- <org>/: org

## Privacy Terms

dotfiles に含めてはいけない固有名詞 (org・repo・製品・顧客名)。dotfiles-privacy rule の機械的な確認で grep 対象にする。
1 行 1 語、`- ` の後ろを単語単位 (grep -w) で照合する。

