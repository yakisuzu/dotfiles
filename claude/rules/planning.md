---
globs: ""
alwaysApply: true
---

# Planning Documentation

- 設計思想・変更時の背景は `dotfiles/claude/docs/plan-system-design.md` を参照
- Plan files are saved under `~/.claude/plans/`
- **Plan Group**: `CLAUDE.local.md` defines working directory pattern to group name mappings in the `Plan Group` section
  - If cwd matches a mapping, save plans to `~/.claude/plans/<group>/`
  - If no match, save plans to `~/.claude/plans/` directly (default behavior)
- Naming conventions (3 types):
  - `plan-<topic>.md`: Implementation plan (How) - technical steps, task breakdown, file changes
  - `feature-<topic>.md`: Product requirements (What & Why) - user stories, acceptance criteria
  - `research-<topic>.md`: Research & investigation (What happened / What is it) - bug investigation, technology comparison, troubleshooting. Record investigation steps and findings as a log
- **Same topic = same file**: If a plan for the same topic already exists, UPDATE it instead of creating a new file
- When entering Plan Mode, follow existing naming conventions in the target plan directory
- When you start working on a plan, register it: write the plan file path to `~/.claude/plans/.active/{session_id}`

## Frontmatter (required)

- Every plan/research file MUST start with YAML frontmatter:
  ```yaml
  ---
  topic: <kebab-case, ファイル名から prefix (plan-/feature-/research-) と .md を除いたもの>
  status: active | done | superseded
  updated: YYYY-MM-DD
  repos: [repo名, ...]   # 特定できる場合のみ。不明なら行ごと省略
  description: <日本語1行の内容サマリ>
  ---
  ```
- New file: `status: active`. Updating content: bump `updated` to today

## Status Lifecycle

- `active` (作業中) → `done` (完了) → `superseded` (別 plan に置き換え)
- plan の作業が完了したら status を `done` に更新する

## Search Instead of Resume

- 新規作成前・過去の調査/計画を参照したい場面では、まず該当グループの `INDEX.md` を Read して topic を検索する
- 同 topic があれば新規作成せずそのファイルを UPDATE。該当グループに無ければ他グループの `INDEX.md` も確認する
- `INDEX.md` は hook (`plan-index.sh`) が自動生成する。手動編集しない

## Native Plan Mode Plans

- Claude Code 本体が plan mode で自動保存する plan (codename 命名の `*.md`) は `~/.claude/plans/` 直下にそのまま保存される
  - `plansDirectory` 設定による物理的な分離 (`~/.claude/plans-native/` へのリダイレクト) は試みたが、検証の結果機能しないため撤回済み (詳細: `plan-system-design.md`)
- `plan-index.sh` は `plan-/feature-/research-<topic>.md` の命名規則に一致するファイルのみを INDEX に含めるため、native plan の codename ファイルは自動的に検索対象外になる
- 残す価値がある native plan は命名規則に沿って rename + frontmatter を付与し、該当グループへ移動して取り込む (移動後に INDEX に反映される)
