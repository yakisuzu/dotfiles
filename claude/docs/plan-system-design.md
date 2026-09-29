# Plan 運用システムの設計思想

> このドキュメントは plan 運用システムを変更する時に読む。通常セッションで読む必要はない。

対象コンポーネント: `claude/rules/planning.md` / `claude/hooks/plan-index.sh` / `claude/hooks/init-session.sh` / `claude/settings.base.json` の `plansDirectory`。

## 1. resume ではなく検索 (Search Instead of Resume)

- **決定**: plan/research ファイルを topic 単位で横断検索し、UPDATE して使い回す運用にする。セッション resume には依存しない。
- **理由**: Claude Code 公式の plan は「セッションに紐づく一時成果物」モデルで、後から戻る公式手段は `claude --resume` のみ (2026-09 時点、v2.1.228 で確認)。topic 単位で横断検索する公式機構は存在しない。過去の調査・計画を「あのセッションを覚えている」前提で扱うと、セッションを跨いだ瞬間に参照不能になる。
- **却下した代替案**: `claude --resume` の運用ルール化 (session_id を控えておいて resume する)。session_id の管理コストが高く、複数トピックが1セッションに混在すると絞り込めない。かつ resume は「同じ会話の続き」であって「topic を起点にした知識検索」には向かない。

## 2. CLAUDE.md / auto memory ではなく plan file + INDEX を選んだ理由

- **決定**: topic が明確な永続情報 (計画・調査ログ) は plan file + INDEX.md の層に置く。CLAUDE.md / rules や auto memory (MEMORY.md) には置かない。
- **理由**:
  - CLAUDE.md / rules は全文が毎セッション無条件注入される。蓄積するほど全セッションが固定費を払い、トピック関連性を判定する機構がない。
  - auto memory は「index 1行 + 本文遅延読み」の二段構造を持つが、retrieval 機構はなく index 自体の行数に比例して固定費と関連判断ノイズが増える。少数精鋭でしか維持できない。
  - plan file + INDEX.md は「初期ロードはポインタ数行のみ、必要になったら INDEX を Read して検索、ヒットした本文だけ読む」というオンデマンドロードが成立する。これが本システムの中核思想。
- **却下した代替案**: 全部 auto memory に寄せる。auto memory は個人の短い habit/preference には向くが、長い調査ログや技術的な計画の本文を持つには不向き (index が肥大化し全体の固定費が上がる)。

## 3. 3層設計

- **決定**: (a) 各 plan file の YAML frontmatter (topic/status/updated/repos/description) を検索メタデータとして持つ、(b) グループごとの INDEX.md は `plan-index.sh` による決定的な自動生成 (LLM 不要・冪等・手動編集禁止)、(c) SessionStart hook はポインタ (INDEX のパス・他セッションの active plan) のみ注入し、本文は注入しない。
- **理由**:
  - description 1行の品質が検索の実用性を決める。ヒット候補を開かずに絞り込めるかどうかは、この1行にかかっている。
  - status ライフサイクル (active → done → superseded) があることで、検索結果の鮮度 (まだ有効か、終わった話か、置き換えられたか) を本文を開かずに判別できる。
  - 生成を LLM ではなく shell script (`plan-index.sh`) に固定しているのは、索引の正しさをコード品質として保証するため。LLM 生成だと索引自体の信頼性が揺らぐ。
- **却下した代替案**: INDEX を Claude に都度生成させる (frontmatter を読んで要約させる)。生成コストと表記ゆれが発生し、索引という「常に正しくあるべきデータ構造」に不確実性を持ち込むため却下。

## 4. native plan の除外 (命名規則フィルタ)

- **決定**: Claude Code 本体が plan mode で自動保存する codename ファイル (例: `refactored-questing-sun.md`) は物理的に分離せず、`plan-index.sh` の対象ファイルを命名規則 (`plan-/feature-/research-<topic>.md`) に完全一致するものだけに絞るフィルタで検索対象から除外する。
- **理由**: native plan はファイル名がランダムな codename で topic を表さず、frontmatter も付与されない。検索 corpus に混在させると INDEX.md の信頼性が下がる。命名規則フィルタなら frontmatter の有無に関わらず確実に除外でき、物理的な分離機構の可用性に依存しない。
- **却下した代替案**: `plansDirectory` 設定で `~/.claude/plans-native/` に物理分離する案 (2026-09-29 撤回)。Claude Code 側の project root 制約により機能せず、native plan は corpus 直下に漏れ続けていた。加えて dotfiles 共有設定へのフルパス直書きで他マシン drift の問題もあった。検証の詳細は `plansdirectory-native-plan-isolation` (research file, INDEX から検索可) を参照。

## 5. `.active/{session_id}` の役割

- **決定**: 作業中の plan を `~/.claude/plans/.active/{session_id}` に宣言する。
- **理由**: 用途は3つ。
  1. compact 時に本文を再注入する (init-session.sh がこのファイルを読んで plan 本文を出力する)。
  2. 他セッションに「このファイルは使用中」と表示する (並行セッションが同じ plan を同時に編集する事故を防ぐ)。
  3. SessionEnd での掃除、および 7日超残骸の SessionStart 掃除 (`find "$ACTIVE_DIR" -type f -mtime +7 -delete`)。
- **却下した代替案**: active plan の管理をユーザーの記憶や会話履歴に任せる。並行セッションが増えると衝突検知ができず、事故の温床になるため機構化した。

## 6. 既知の運用上の注意

- 遡及的に frontmatter を付与した古い plan は、status が機械的に `done` になっているだけで本文の実態と乖離している可能性がある。status だけを鵜呑みにせず、疑わしい場合は本文を確認する。
- INDEX.md は生成物であり `~/.claude/plans/` 配下 (dotfiles の git 管理外) にあるため、git 管理していない。
- `claude/rules/` 配下には長文の設計思想を置かない。rules は毎セッション無条件注入されるため、設計思想のような読む頻度の低い内容を置くと固定費が積み上がる。設計思想はこのドキュメント (`claude/docs/`) に置き、rules からは1行のポインタで参照する。
