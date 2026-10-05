# Session 依存の宣言

- 他 session の修正・PR・remote 依頼の結果を待つ状態に入ったら `claude-session-deps add <pr|session|remote> <target> [note]` で宣言する
- 待ち先が解消したら `claude-session-deps rm <type> <target>` で消す
- 同一マシンの session の完了を待つときは SendMessage の `notify_when_idle` を使う (ポーリング禁止)
- 作業を別 session に切り出すときは `/delegate` を使う
