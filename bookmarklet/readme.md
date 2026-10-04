# bookmarklet

ブラウザ上で動かす小物スクリプト置き場。1 本の `.user.js` を source にして、userscript と bookmarklet の 2 形態で使う。

## 配布形態

| 形態 | 更新方法 | 向き |
|---|---|---|
| userscript (Tampermonkey) | `@updateURL` が raw.githack の `main` を指すので push すれば自動更新 | 常用 |
| bookmarklet | `build.sh` で `javascript:` URL を生成してブックマークに貼り直す | 拡張を入れたくない環境 |
| console | x.com 上で DevTools console にファイル全体を貼る | 動作確認 |

### なぜ CDN 参照の bookmarklet にしないか

x.com の CSP は `script-src` / `connect-src` が許可ドメイン固定で、raw.githack や jsDelivr を含まない。
bookmarklet 自体のインライン実行は CSP の対象外なので動くが、そこから外部スクリプトを `<script src>` でも `fetch()` でも読めない。
拡張 (Tampermonkey) は CSP を迂回して注入できるので、自動更新したい場合はそちらを使う。

## 使い方

```bash
# bookmarklet 生成 (macOS なら clipboard にも入る)
bookmarklet/build.sh bookmarklet/x-old-post-cleaner.user.js
```

userscript は Tampermonkey を入れた状態で以下を開くとインストール画面になる。

```
https://raw.githack.com/yakisuzu/dotfiles/main/bookmarklet/x-old-post-cleaner.user.js
```

## ver 管理

- `@version` を上げて commit する。Tampermonkey はこの値を見て更新を判断する
- `raw.githack.com/.../main/...` はキャッシュ無しの dev URL。固定したい場合は `rawcdn.githack.com/<owner>/<repo>/<commit>/...` を使う

## scripts

### x-old-post-cleaner

x.com で UI が受信した GraphQL レスポンスを横取りし、自分の N 日 (パネルの `older than` 入力、初期値 30) より古い投稿 / リポストをメモリ上のキューに積んで 5 秒間隔で削除する。

- 右下パネルの `auto` で削除ループ + 自動収集が始まり、`stop` で両方止まる。radio で収集元のプロフィールタブを選ぶ (`posts` / `with_replies` / `reposts`)。拾ったノードが通常の投稿なら `DeleteTweet`、リポストなら `DeleteRetweet` で消す (種別は自動判定)
- 自動収集は 2 フェーズ
  1. 選んだタブを底まで舐めてキューを消し切り、また先頭から、を新規 0 件になるまで繰り返す。タイムラインは新しい順に一定数しか返さないが、古い分を消すと窓が古い方へずれるので、これだけで大半は遡れる。1 パスで数百件拾えるので検索より圧倒的に効率が良い
  2. `reposts` 以外: `from:自分 since:A until:B` を Latest で開き、フェーズ 1 で届いた最古日から 90 日ずつ遡る、を、アカウント作成日に達するか自分の投稿が 0 件の窓が 6 回続くまで繰り返す (投稿が集中した時期で検索が底まで返さないなら `WINDOW_DAYS` を下げる)。作成日はプロフィール表示時に受信する User ノードから取る。探索が終わっても削除ループは残るので、キューの残りは消し切る。ブックマーク除外などで窓が詰まった分や、大量削除後にタイムラインの追加読み込みが途中で止まる分の保険。検索はリポストを返さない
- 自動収集が終わっても削除ループは動き続けるので、プロフィールの各タブを手でスクロールすれば拾って消す
- `dry run` チェックを外すまで実際には消さない
- skip 行の `bookmarkした` (自分がブックマーク済み) / `bookmarkされた` (他人のブックマークが 1 件以上) / `いいね N 以上` (他人のいいねが N 件以上、初期値 1) はデフォルト ON で除外。除外した投稿は処理済み扱いにしないので、チェックを外してもう一度流せば拾う
- 検索遷移は SPA 内の `pushState` + `popstate` で行う。X 側がこれに反応しなくなったら `location.assign` に切り替えるが、その場合はメモリ上の状態が消えるので窓の位置を sessionStorage に逃がす必要が出る
- rate limit (実測 約 200 件 / 15 分) に当たったら `x-rate-limit-reset` まで自動で待つ
- 完全リロードで状態は消える (永続化なし)。userscript なら再注入される
- 403 / 404 で止まる場合は `x-client-transaction-id` を要求されている可能性がある。ページ自身のリクエストヘッダを流用しているが、それでも通らなければ要調査
