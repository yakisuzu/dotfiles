# Local Settings (personal, not committed)

## Plan Group

Map working directory patterns to plan group names.
Plans are saved to `~/.claude/plans/<group>/`.

Format: `- <dir_pattern>: <group>`

Mappings:

## Privacy Terms

dotfiles に含めてはいけない固有名詞 (org・repo・製品・顧客名)。dotfiles-privacy rule の機械的な確認で grep 対象にする。
1 行 1 語、`- ` の後ろを単語単位 (grep -w) で照合する。

