---
name: organize-config
description: 現在の repo の CLAUDE.md / rules / skills / hooks / scripts の配置を分析し、ベストプラクティスに基づく再編成を提案する。
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[audit|migrate|init] [team|personal]"
---

# Organize Config Skill

Claude Code の設定 (CLAUDE.md / rules / skills / hooks / scripts) を分析し、ベストプラクティスに基づく再編成を提案する。

## Usage

- `/organize-config audit [team|personal]` -- 現在の設定を分析し、改善提案を出力する
- `/organize-config migrate [team|personal]` -- 分析結果に基づきファイルの移動・分割を実行する
- `/organize-config init [team|personal]` -- 新規リポジトリ向けの最小構成を生成する

引数なしのデフォルトアクションは `audit`。第2引数なしの場合のモードは下記 Step 0 で判定する。

### Modes

提案ロジックは 2 つの配布モードで分岐する。Step 2 より前に必ず確定させること:

- **`team`** -- 会社・チーム開発。複数 repo が同じ skill セットを共有する。repo 間で複製された standalone `.claude/skills/` はアンチパターン。

  **デフォルトの配布アーキテクチャ (team モード):**
  - **1 org に 1 marketplace repo** (例: `<org>/claude-plugins`)。全チームの plugin をここに集約し、どのメンバーも `/plugin` の Discover タブからどのチームの skill でも発見できるようにする
  - その repo 内に **チームごとの plugin**: `plugins/shared/`, `plugins/<team-name>/`, ... それぞれに `plugin.json` (`name`, `version`) と `skills/` を持たせる
  - **repo ごとの `.claude/settings.json`** で marketplace を登録し、その repo のチームの plugin だけを選択的に有効化する:
    ```json
    {
      "extraKnownMarketplaces": {
        "<marketplace-name>": { "source": { "source": "github", "repo": "<org>/claude-plugins" } }
      },
      "enabledPlugins": {
        "shared@<marketplace-name>": true,
        "<team-name>@<marketplace-name>": true
      }
    }
    ```

  **3 層モデル -- 提案の前に理解しておくこと:**
  1. **Marketplace 登録済み** (`extraKnownMarketplaces`) -> カタログが `/plugin` の Discover タブに見える。他チームの plugin も含め、一覧の全 plugin が発見可能
  2. **Plugin インストール済み** (`/plugin install`、または `enabledPlugins` に記載があり repo を trust した際の自動プロンプト) -> キャッシュにダウンロードされる
  3. **Plugin 有効化済み** (`enabledPlugins: true`) -> namespace `/<plugin>:<skill>` が起動可能になり、補完に表示される

  **提案への含意:**
  - repo ごとのデフォルト有効化 = `shared` + そのチームの plugin のみ。他チームの skill が補完を汚染しない
  - 他チームの skill は `/plugin` から**発見可能**なままで、アドホックにインストールしたり (`/plugin install <other-team>@<marketplace>`)、チームを跨ぐ個人が user スコープ (`~/.claude/settings.json`) で固定したりできる

- **`personal`** -- 個人作業。ユーザーは 1 人で、複数 repo に跨ってもよいが共有配布は不要。standalone の `~/.claude/skills/` や repo ごとの `.claude/skills/` で問題ない。plugin のオーバーヘッドは不要。

## Instructions

### Step 0: モードを確定する (team vs personal)

ユーザーが第2引数に `team` / `personal` を渡していればそれをそのまま使う。

なければ repo のシグナルから判定する:
- `git log --format='%ae' | sort -u` に複数の作者 (bot 以外のメールが 2 つ以上) -> `team` の可能性が高い
- remote が個人の GitHub アカウント配下 / remote なし -> `personal` の可能性が高い
- 親ディレクトリに monorepo / 会社の規約を示す CLAUDE.md がある -> `team` の可能性が高い

判定が曖昧な場合は 1 回だけユーザーに確認する:「この repo は `team` (他者と共有) と `personal` のどちらとして扱いますか?」その後続行する。

確定したモードを記録し、以降のステップ全体で使用する。

### Step 1: 現状を収集する

以下を収集する:

1. **CLAUDE.md** -- プロジェクトルートと `.claude/CLAUDE.md` を読み、行数を数える
2. **Rules** -- `.claude/rules/` 配下の全ファイルを読む。frontmatter の `paths` / `alwaysApply` を確認する
3. **Skills** -- `.claude/skills/` と `~/.claude/skills/` の両方の配下の全ファイルを読む。各 skill について: YAML frontmatter (`name`, `description`, `when_to_use`, `allowed-tools`, `disable-model-invocation`, `context` 等) をパースし、SKILL.md 本文の行数を数え、補助ファイル (`scripts/`, `reference/`, テンプレート) を列挙する。両レイヤーに存在する skill (衝突候補) を記録する。SKILL.md のない skill ディレクトリ (死んだ placeholder) をフラグする
4. **Legacy commands** -- `.claude/commands/*.md` と `~/.claude/commands/*.md` を列挙する。custom command は skill に統合済み。これらのファイルはまだ動作するが移行候補
5. **Plugin / marketplace 登録** -- `.claude/settings.json` と `~/.claude/settings.json` を読む。`extraKnownMarketplaces` と `enabledPlugins` を調べ、どの marketplace / plugin が既に接続されているか列挙する
6. **repo 間の重複 (team モードのみ)** -- ユーザーが兄弟 repo のパスやプロジェクトルート一覧を提供できる場合、各 repo の `.claude/skills/<same-name>/SKILL.md` をスキャンする。入力がなければ確認する:「重複 skill をスキャンする兄弟 repo を列挙してください。不要ならスキップします」。2 つ以上の repo に同名の skill があれば重複候補
7. **Hooks** -- settings.json (`~/.claude/settings.json` と `.claude/settings.json` の両方) の `hooks` セクション、および skill / agent の frontmatter 内の `hooks` を読む。`command` フィールドが参照する hook スクリプトを列挙し、hook の `type` (`command` / `http` / `mcp_tool` / `prompt` / `agent`) を記録する
8. **Hook スクリプト** -- `.claude/hooks/` と `~/.claude/hooks/` 配下の全ファイルを読む。言語・実行権限・配置を確認する
9. **親ディレクトリ** -- 親に CLAUDE.md があればその内容を確認する (monorepo 対応)

### Step 2: 配置ルールに基づき分析する

各エントリを以下の配置原則に照らして評価する:

| 配置場所 | 適した内容 | コンテキストコスト |
|----------|-----------|-------------------|
| **CLAUDE.md** | ビルドコマンド、コード規約、環境の癖、チーム共有の知識。**200 行未満** | 高 (毎回全文ロード) |
| **rules/** | 条件付きリマインダー、パス限定ルール。`paths` で遅延ロード | 中 (条件付き) |
| **skills/** | ドメイン知識、再利用可能なワークフロー、オンデマンド参照 | 低 (起動時のみロード。常時ロードは `name` + `description`/`when_to_use` のみで 1,536 文字で切り詰め) |
| **hooks (settings.json)** | hook 定義: event, matcher, command 参照。単純なワンライナーはインラインで可 | なし (コンテキストにロードされない) |
| **hooks/** | settings.json から参照される hook スクリプト。単体で実行可能なファイル (.sh, .js) | なし (イベント時に実行) |
| **skills/\*/scripts/** | 特定 skill の補助スクリプト。SKILL.md から参照 | なし (オンデマンドで実行) |

#### 個別基準

CLAUDE.md から**外に出す**もの:
- 特定のファイルパターンにのみ関係する指示 -> `rules/` へ (`paths` 付き)
- 手順、ワークフロー、テンプレート -> `skills/` へ
- 200 行を超えた場合、優先度の低いものから移す

Rules から**外に出す**もの:
- `paths` なしの `alwaysApply: true` で短いもの -> CLAUDE.md への統合を検討
- 複雑な手順やテンプレートを含む -> `skills/` へ分割し、rule には参照だけ残す

Skills として**作る**もの:
- 繰り返し使うワークフロー (PR 作成、デプロイ手順等)
- 深いドメイン知識 (API 仕様、DB 設計等)

#### Skill 品質基準

仕様への準拠チェックは公式ドキュメント (ライブ) に**委譲**する -- このファイルには転記しない。audit 時に最新のルールを取得し、各 SKILL.md をそれに照らして評価する:

- Frontmatter リファレンス (全フィールド、上限値、起動制御、変数展開): https://code.claude.com/docs/en/skills.md
- Authoring ベストプラクティス (命名、description の書き方、本文の長さ、progressive disclosure): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

最低限、そこで得た**現行仕様**に基づいて確認すること: ディレクトリ名 / `name` の妥当性、`description` / `when_to_use` の書き方と切り詰め上限、本文の長さと参照ファイル構造、起動制御フィールド (`disable-model-invocation`, `user-invocable`, `context: fork`, `allowed-tools`, `model` / `effort`, `paths`) がドキュメントの推奨どおりに使われているか。

**追加観点 (公式ドキュメントがカバーしないもの):**
- bundled skill との重複: Claude Code の bundled skill を列挙する (commands リファレンス、または `/help`)。bundled skill (例: `/run`, `/verify`, `/code-review`, `/update-config`, `/run-skill-generator`) と重複する custom skill は薄い wrapper に縮小すべき: bundled skill に委譲し、repo / チーム固有の追加分 (追加チェック、デフォルト値、ポリシー) だけを残す
- repo 内の skill 間一貫性: 命名パターンの統一 (`processing-pdfs` と `pdf-tool` と `do_excel` を混在させない)、skill を跨いで 1 概念 1 用語
- ハードコードされたパス: skill 本文は `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` を使うこと。`~/.claude/skills/<name>/...` は禁止 -- ハードコードされたパスは plugin 配布時や他ユーザー環境で壊れる
- `allowed-tools` のスコープ: スコープ付きルール (`Bash(git *)`, `Bash(${CLAUDE_SKILL_DIR}/scripts/run.sh *)`) を使う。`Bash` のような裸のツール名は不可
- `model` / `effort` の値: alias (`sonnet`, `opus`, `haiku`, `fable`) か `inherit` を使う。日付付き model ID の固定は禁止 -- 陳腐化する

#### Skill 配布基準

配布ルールは Step 0 で確定したモードにより異なる。実行時の優先順位は常に **managed > personal > project**。plugin の skill は、それを有効化したレイヤー側に属する (user スコープの `extraKnownMarketplaces` なら personal、repo にコミットされた settings なら project が典型)。

**Mode = `team` (会社 / 複数 repo のデフォルト):**

目標アーキテクチャ = **1 org / 1 marketplace repo にチームごとの plugin (`shared` + `<team-name>`) を置き、repo ごとの `.claude/settings.json` の `extraKnownMarketplaces` + `enabledPlugins` でその repo のチームの plugin を選択する**。

| レイヤー | パス | team モードで使う場面 |
|---------|------|----------------------|
| Team marketplace plugin | `<org>/claude-plugins` repo, `plugins/<team-or-shared>/` | 2 人以上のメンバーが共有する skill / hook / agent のデフォルト |
| Project standalone | `<repo>/.claude/skills/` | 本当にその repo 固有で再利用の見込みがない skill のみ |
| Personal | `~/.claude/skills/` | 個人のチーム横断的な補強 (例: frontend をよく触る backend 開発者が `frontend@<marketplace>` を user スコープで有効化) |
| Managed (org 全体) | 管理コンソール | org 全体での強制が必要な場合のみ (コンプライアンス、上書きさせないセキュリティポリシー) |

**Plugin グルーピングルール:**
- 2 チーム以上が使う skill -> `plugins/shared/`
- ちょうど 1 チームが使う skill -> `plugins/<team-name>/`
- 1 チーム内の 1 repo だけが使う skill -> project standalone `<repo>/.claude/skills/` のまま

`team` モードで**フラグする**もの:
- 2 つ以上のプロジェクトの `.claude/skills/` に同名 (またはほぼ同内容) の skill -> org marketplace の plugin への抽出を提案。`shared` か `<team>` かは上記グルーピングルールで選ぶ
- `<repo>/.claude/skills/` にある汎用的 (repo 固有でない) な skill で、`git log` 上複数メンバーが触っている -> チームの plugin への昇格を提案
- org marketplace が存在するのに repo の `.claude/settings.json` に `extraKnownMarketplaces` がない -> 登録のコミットを提案し、clone した人が `/plugin` で全チームの plugin を発見できるようにする
- `extraKnownMarketplaces` は登録済みだが `enabledPlugins` が空 / この repo のチーム分がない -> 警告: カタログは見えるが plugin は自動有効化されず、デフォルトでは何も起動できない。`shared@<marketplace>` + 該当チームの plugin の追加を提案
- `enabledPlugins` にこの repo と無関係なチームの plugin がある -> ここにあるべきか、user スコープ (`~/.claude/settings.json`) に移してチームメイトの補完を汚染しないようにすべきかを問う
- 他のメンバーも必要とする personal skill (`~/.claude/skills/`) -> org marketplace のチーム plugin への昇格を提案
- repo 間で重複した hook スクリプト -> plugin の `hooks/hooks.json` へ移す (settings.json の hooks と同じスキーマ)
- personal と project で同じ `name:` の skill が衝突 -> 警告: 優先順位により片方が黙ってマスクされる
- plugin の skill 名が namespace を考慮していない (`/<plugin-name>:<skill-name>` として起動される) -> namespace プレフィックス付きで自然に読める名前か確認する (例: `backend:deploy-check`。`backend:backend-deploy-check` は不可)

**Mode = `personal` (個人作業のデフォルト):**

目標配布 = **standalone `.claude/skills/` (project または personal スコープ)**。plugin のオーバーヘッドは不要。

| レイヤー | パス | personal モードで使う場面 |
|---------|------|--------------------------|
| Project standalone | `<repo>/.claude/skills/` | repo 固有の skill |
| Personal | `~/.claude/skills/` | 自分の複数 repo を跨いで使う skill |
| Plugin | (任意) | 同じ skill を公開配布・他者配布もする場合のみ |
| Managed | -- | 対象外 |

`personal` モードで**フラグする**もの:
- `~/.claude/skills/` と `<repo>/.claude/skills/` に同じ `name:` の skill が重複 -> どちらか一方のレイヤーに寄せる。優先順位が他方をマスクする
- 自分の多くの repo で使っているのに 1 プロジェクトにしかない skill -> `~/.claude/skills/` への昇格を提案
- ユーザーが明示的に配布したいと言わない限り、plugin への抽出は提案しない

#### Hooks / スクリプト基準

hook スクリプトの配置ルール:
- プロジェクトレベルの hook スクリプト -> `.claude/hooks/`
- 個人用 (プロジェクト横断) の hook スクリプト -> `~/.claude/hooks/`
- skill 固有のスクリプト -> `<skill>/scripts/`
- 特定の skill / agent がアクティブな間だけ意味を持つ hook -> その skill / agent の frontmatter の `hooks` (ライフサイクル限定)。グローバルの settings.json には置かない
- 単純なワンライナー hook は settings.json の `command` フィールドにインラインで可
- 複数行または複雑なロジックは必ずスクリプトファイルに抽出する

hook 定義の品質 (settings.json / frontmatter):
- hook の `type` は `command` に限らない: `prompt` / `agent` (LLM による判定)、`http` (エンドポイント)、`mcp_tool` が使える。曖昧な判定ロジックを再実装している `command` スクリプトは `type: prompt` への置き換え候補
- ツールイベントの hook は、スクリプト内で tool input を grep するのではなく `if` フィールド (permission ルール構文、例: `"if": "Bash(git push *)"`) でゲートする
- `Stop` / `PostToolUse` 上の遅い副作用 hook (TTS、通知、ネットワーク呼び出し) はセッションをブロックしないよう `async: true` を設定すべき
- 長時間実行される hook は明示的な `timeout` を設定すべき。ユーザーに見えるものは `statusMessage` があるとよい

スクリプト言語の優先順 (上から順に):
1. **Shell (sh/bash)** -- 単純なファイルチェック、git 操作、テキスト処理に推奨
2. **Node.js (js)** -- JSON パース、複雑なロジック、クロスプラットフォーム要件に推奨
3. **Python** -- プロジェクトが既に Python に依存している場合以外は避ける

hooks で**フラグする**もの:
- `.claude/hooks/` / `<skill>/scripts/` 以外に置かれたスクリプト -> 推奨位置への移動を提案
- sh/js で足りるのに Python のスクリプト -> sh または Node.js での書き直しを提案
- settings.json 内の複雑なインラインコマンド (パイプ、条件分岐) -> スクリプトファイルへの抽出を提案
- スクリプトファイルの実行権限漏れ
- `$CLAUDE_PROJECT_DIR` / `${CLAUDE_SKILL_DIR}` を使わないハードコードされた絶対パス
- 遅い副作用を持つブロッキングな `Stop`/`PostToolUse` hook -> `async: true` を提案
- hook スクリプトが際限なく追記する debug ログファイル -> ローテーション / 切り詰め、または安定後の削除を提案

### Step 3: 出力

#### `audit` mode

以下のフォーマットでレポートを出力する:

```
## Config Analysis Report

### Mode
- Resolved mode: {team|personal} ({detected|user-specified})

### Summary
- CLAUDE.md: {line_count} 行 {200 行超なら WARNING}
- Rules: {file_count} ファイル (alwaysApply: {count}, path-scoped: {count})
- Skills: {file_count} ファイル (project: {n}, personal: {n}, 本文 500 行超: {n}, name 違反: {n})
- Plugins/Marketplaces: {registered_marketplaces}, {enabled_plugins} (team モードのみ)
- Hooks: {hook_count} イベント種別を設定済み, 外部スクリプト {script_count} 本
- Scripts: {languages_used} (sh: {count}, js: {count}, py: {count})

### Improvement Proposals
1. [Move] CLAUDE.md L{start}-L{end} "{summary}" -> rules/{proposed-name}.md (理由: {paths} にのみ関係)
2. [Split] rules/{name}.md のテンプレート節 -> skills/{proposed-name}/SKILL.md
3. [Merge] rules/{name}.md -> CLAUDE.md へ統合 (短く、常に必要)
4. [Extract] hooks/{event} のインラインコマンド -> .claude/hooks/{proposed-name}.sh (理由: 複雑なインラインコマンド)
5. [Move] {script_path} -> .claude/hooks/{name} (理由: 推奨位置の外にあるスクリプト)
6. [Rewrite] {script_path} を Python から sh/Node.js へ (理由: Python より sh/js を優先)
7. [Rename] skills/{current-name} -> skills/{proposed-name} (理由: kebab-case でない / 予約語 / 曖昧 / 動名詞形でない)
8. [Rewrite description] skills/{name} -- 一人称になっている / 「いつ使うか」がない / 1024 文字超
9. [Split skill] skills/{name}/SKILL.md ({n} 行) -> SKILL.md + reference/*.md に分割 (理由: 500 行超)
10. [Resolve collision] skills/{name} が `~/.claude/skills/` と `.claude/skills/` の両方に存在 (理由: 優先順位が片方をマスクする)
11. [Migrate command] .claude/commands/{name}.md -> skills/{name}/SKILL.md (理由: custom command は skill に統合済み。補助ファイルと起動制御が使えるようになる)
12. [Scope tools] skills/{name} の `allowed-tools: Bash` -> `Bash(git *)` 等 (理由: 裸のツール名はそのターンの全操作を許可してしまう)
13. [Fix path] skills/{name} 本文が `~/.claude/skills/{name}/...` を参照 -> `${CLAUDE_SKILL_DIR}/...` (理由: インストールパスのハードコード)
14. [Invocation control] skills/{name} -> `disable-model-invocation: true` / `user-invocable: false` を追加 (理由: 副作用のあるワークフロー / 背景知識)
15. [Async hook] hooks/{event} {script} -> `async: true` を追加 (理由: 遅い副作用がセッションをブロックする)
16. [Remove or complete] skills/{name}/ に SKILL.md がない (理由: 死んだ placeholder ディレクトリ)
17. [Thin-wrap] skills/{name} が bundled の /{bundled-skill} と重複 -> bundled skill に委譲し、{repo/チーム固有の追加分} だけ残す (理由: ベースのワークフローは bundled skill がカバーしており、ローカルコピーは陳腐化する)

**Team モードの提案 (personal モードではスキップ):**

18. [Promote to plugin] skills/{name} -> {org}/claude-plugins/plugins/{shared|team-name}/skills/{name} (理由: {repo-A, repo-B} で重複 / 複数メンバーが使用。グルーピング: {2 チーム以上なら shared、それ以外はチーム plugin})
19. [Wire marketplace] `.claude/settings.json` に追加:
    ```json
    {
      "extraKnownMarketplaces": {
        "{marketplace-name}": { "source": { "source": "github", "repo": "{org}/claude-plugins" } }
      },
      "enabledPlugins": {
        "shared@{marketplace-name}": true,
        "{team-name}@{marketplace-name}": true
      }
    }
    ```
    (理由: カタログ登録 + この repo のチーム分の選択的有効化)
20. [Move hooks to plugin] {repo}/hooks/{name} -> {plugin}/hooks/hooks.json (理由: 同じ hook がチームの repo 間で重複)
21. [Complete enablement] `extraKnownMarketplaces` はあるが `enabledPlugins` が空 / 欠落 -> `shared@{marketplace}` + `{team}@{marketplace}` を `enabledPlugins` に追加して plugin が実際にロードされるようにする (理由: カタログは見えるが何も起動できない)
22. [Move cross-team to user scope] project の `.claude/settings.json` の `enabledPlugins` に `{other-team}@{marketplace}` がある -> user スコープ `~/.claude/settings.json` へ移動 (理由: チームを跨ぐのは一個人だけ。project スコープは全チームメイトに強制してしまう)
...

### References
- Skills: https://code.claude.com/docs/en/skills.md
- Skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Best Practices: https://code.claude.com/docs/en/best-practices.md
- Memory & CLAUDE.md: https://code.claude.com/docs/en/memory.md
```

#### `migrate` mode

`audit` の結果に基づき、ユーザー確認を取りながらファイルの移動・分割を実行する。
各変更は実行前に説明し、承認を待つ。
settings.json の編集 (permissions, hooks の接続, env) は手編集ではなく bundled の `/update-config` skill への委譲を優先する。

#### `init` mode

現在のリポジトリ向けに最小構成を生成する:

1. `CLAUDE.md` テンプレートを作成 (存在しない場合)
2. `.claude/rules/` ディレクトリを作成
3. `.claude/skills/` ディレクトリを作成
4. `.claude/hooks/` ディレクトリを作成

`team` モードではさらに:

5. チームの plugin marketplace repo (`org/repo` または完全 URL) を確認する。提供されたら、clone した人に marketplace が自動登録されるよう `extraKnownMarketplaces` と placeholder の `enabledPlugins` ブロックを含む `.claude/settings.json` を書く
6. `.claude/settings.local.json` が除外されていなければ `.gitignore` に追加する (個人の上書き設定をコミットに含めない)

`personal` モードではステップ 5-6 をスキップする。

テンプレートの内容はリポジトリの言語・フレームワークを自動検出して調整する。

## Writing Rules

- **言語**: 英語と日本語で Claude の理解度・skill マッチング精度・token 効率に意味のある差はない。チームが使う言語を選ぶこと。プロジェクト内では一貫させる
- いかなる設定ファイルでも絵文字を使わない
- **How-to のみ**: skill には手順と判断基準だけを書くこと。調査結果、現状のまとめ、コードと同期し続ける必要がある repo 固有データは絶対に書かない。そうしたデータは source of truth から乖離し、skill の品質を静かに劣化させる。repo の状態は常に実行時に動的に収集する。普遍的なガイドラインや閾値 (公式ドキュメントの数値等) は判断基準 (どう判定するか) として書いてよい。

## Best Practice Reference

設定を更新する際は、以下の公式ドキュメントで最新のベストプラクティスを確認すること:

- Skills: https://code.claude.com/docs/en/skills.md
- Skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Bundled skills / commands リファレンス (thin-wrapper 判断用): https://code.claude.com/docs/en/commands.md
- Plugins (作成): https://code.claude.com/docs/en/plugins
- Plugin marketplaces (配布): https://code.claude.com/docs/en/plugin-marketplaces
- Plugin の発見/インストール (3 層有効化モデル): https://code.claude.com/docs/en/discover-plugins
- Plugins リファレンス (スキーマ, defaultEnabled, 優先順位): https://code.claude.com/docs/en/plugins-reference
- Best Practices: https://code.claude.com/docs/en/best-practices.md
- Memory & CLAUDE.md: https://code.claude.com/docs/en/memory.md
- Hooks ガイド: https://code.claude.com/docs/en/hooks-guide.md
- Hooks リファレンス (イベント, type, JSON 契約): https://code.claude.com/docs/en/hooks.md

**主要な数値 (変更されうるため上記 URL で要確認):**
- CLAUDE.md: 200 行未満推奨
- SKILL.md 本文: 500 行未満推奨
- Skill `name`: 小文字 + 数字 + ハイフン、最大 64 文字、`anthropic`/`claude` 禁止
- Skill `description`: 最大 1024 文字、三人称。skill 一覧では `description` + `when_to_use` の合計が 1,536 文字で切り詰められる -- トリガーを先頭に置く
- Skill `model`: alias (`sonnet` / `opus` / `haiku` / `fable`) か `inherit`。日付付き model ID は固定しない
- MEMORY.md: 先頭 200 行または 25KB がロードされる
