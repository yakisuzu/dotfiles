# Session 依存の宣言

- 自分の PR の merge blocker (前提/ペア/stacked PR、blocked-by issue、review 待ち) は `claude-session-deps` が GitHub から自動検出する。宣言は不要
- GitHub に書かれていない待ちに入ったときだけ `claude-session-deps add <pr|session|remote> <target> [note]` で宣言する (本文に書いていない前提 PR、PR 未作成の他 session、remote 依頼の応答)
- PR の前提・事後対応は本文に方向語 (`前提` / `depends on` / `後続` 等) 付きで書くと自動検出に乗る
- 待ち先が解消したら `claude-session-deps rm <type> <target>` で消す
- 同一マシンの session の完了を待つときは SendMessage の `notify_when_idle` を使う (ポーリング禁止)
- 作業を別 session に切り出すときは `/delegate` を使う
