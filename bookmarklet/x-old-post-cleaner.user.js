// ==UserScript==
// @name         x-old-post-cleaner
// @namespace    https://github.com/yakisuzu/dotfiles
// @version      0.3.0
// @description  x.com で UI が受信した GraphQL レスポンスを横取りし、自分の古い投稿/リポストをキューに積んで一定間隔で削除する
// @match        https://x.com/*
// @match        https://twitter.com/*
// @run-at       document-start
// @grant        none
// @updateURL    https://raw.githack.com/yakisuzu/dotfiles/main/bookmarklet/x-old-post-cleaner.user.js
// @downloadURL  https://raw.githack.com/yakisuzu/dotfiles/main/bookmarklet/x-old-post-cleaner.user.js
// ==/UserScript==

// 使い方
//   userscript: Tampermonkey で上の downloadURL を開いてインストール。x.com を開くと右下にパネルが出る
//   bookmarklet: ../bookmarklet/build.sh でこのファイルから javascript: URL を生成してブックマークに登録
//   console:     x.com 上で DevTools console にこのファイル全体を貼る
// 動き
//   1. window.fetch / XMLHttpRequest をラップし /i/api/graphql/ のレスポンス JSON から Tweet を拾う
//   2. 自分の投稿でパネルの days (初期値 MIN_AGE_DAYS) 日より古いものをメモリ上のキューに積む (永続化なし)
//   3. auto を押すと 削除ループ (DELETE_INTERVAL_MS ごとに 1 件) と自動収集が同時に始まる。stop で両方止まる
//      収集元は radio で選ぶプロフィールタブ: posts (/handle) | with_replies | reposts
//      フェーズ 1: 選んだタブを底まで舐めてキューを消し切り、また先頭から、を新規 0 件になるまで繰り返す
//        (タイムラインは新しい順に一定数しか返さないが、消すと窓が古い方へずれる)
//      フェーズ 2 (reposts 以外): 検索 from:自分 since/until をフェーズ 1 で届いた最古日から WINDOW_DAYS ずつ遡る。
//        タイムラインで届かなかった分の保険 (検索はリポストを返さない)
//      拾ったノードが通常の投稿なら DeleteTweet、リポストなら DeleteRetweet (元ポスト ID) で消す。種別はノードから自動判定
//   4. x-rate-limit-remaining が 0 か 429 なら x-rate-limit-reset まで待つ
//   skip: 「bookmarkした」(legacy.bookmarked) / 「bookmarkされた」(legacy.bookmark_count から自分の分を除いて 1 以上) /
//         「いいね N 以上」(legacy.favorite_count から自分の分を除いて N 以上、初期値 1) はデフォルトで除外
//   自動収集が終わっても削除ループは動き続けるので、プロフィールの各タブを手でスクロールすれば拾って消す

(() => {
  if (window.__xcleaner) { console.log('[xcleaner] already running'); return; }

  // ===== settings =====
  const MIN_AGE_DAYS = 30;         // パネルの days 入力の初期値
  const DELETE_INTERVAL_MS = 5000;
  const DELETE_QID = 'VaenaVgh5q5ih7kvyVjgtg';   // DeleteTweet
  const UNRT_QID = 'iQtK4dl5hBmXewYZuEOKVw';     // DeleteRetweet
  const BEARER = 'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA';
  // auto モード
  const WINDOW_DAYS = 90;          // 検索の since/until 幅。1 窓に数百件以上あって検索が底まで返さないなら狭める
  const SCROLL_MS = 1500;          // スクロール間隔
  const IDLE_TICKS = 8;            // 高さも取得件数も増えない tick がこの回数続いたら窓終了
  const EMPTY_WINDOWS_TO_STOP = 6; // 0 件の窓がこの回数続いたら終了
  const FLOOR_DATE = '2006-03-21'; // アカウント作成日が取れなかったときの床。通常はプロフィール表示時に取得した created_at を使う
  // =====================

  const cookie = (n) => document.cookie.match(new RegExp('(^| )' + n + '=([^;]+)'))?.[2];
  const myId = () => decodeURIComponent(cookie('twid') || '').replace(/^u=/, '');
  const cutoffMs = () => Date.now() - state.days * 86400e3;   // これより古い投稿が対象
  const snowflakeMs = (id) => Number((BigInt(id) >> 22n) + 1288834974657n);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const state = {
    running: false,
    driving: false,
    dryRun: true,
    tab: 'posts',       // 収集元のプロフィールタブ: 'posts' | 'with_replies' | 'reposts'。post / repost の別はノードから自動判定
    days: MIN_AGE_DAYS, // この日数より古い投稿を対象にする
    skipBookmarked: true,     // 自分がブックマークした投稿は消さない
    skipBookmarkedBy: true,   // 他人にブックマークされた投稿は消さない
    skipLiked: true,          // 他人に likeMin 件以上いいねされた投稿は消さない
    likeMin: 1,
    queue: new Map(),   // id -> { kind: 'tweet' | 'rt', sourceId }
    dryDone: new Map(), // dry run で処理した分。dry を外したら queue に戻す
    seen: new Set(),
    skippedIds: new Set(),
    stats: { queued: 0, deleted: 0, gone: 0, failed: 0, skipped: 0 },
    harvested: 0,       // 受信した Tweet ノード総数 (スクロール停止判定用)
    oldestMs: null,     // 受信した自分の投稿の最古時刻 (検索フェーズの開始位置)
    createdMs: null,    // アカウント作成時刻 (検索フェーズの床)。プロフィール表示時の User ノードから取得
    mineSeen: 0,        // 受信した自分の投稿数 (検索の空窓判定用)
    gqlResponses: 0,    // GraphQL レスポンス数 (遷移完了判定用)
    status: 'harvesting (press auto to search & delete)',
    pageHeaders: {},    // ページ自身の GraphQL リクエストヘッダを流用
  };

  // ---------- harvest ----------
  function walk(node) {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node)) { node.forEach(walk); return; }
    if (node.__typename === 'Tweet' && node.rest_id && node.legacy) { state.harvested++; consider(node); }
    if (node.__typename === 'User' && node.rest_id === myId() && state.createdMs === null) {
      const ms = Date.parse(node.legacy?.created_at ?? node.core?.created_at ?? '');
      if (ms) { state.createdMs = ms; console.log(`[xcleaner] account created ${new Date(ms).toISOString().slice(0, 10)}`); }
    }
    for (const k in node) walk(node[k]);
  }
  function consider(t) {
    const id = t.rest_id;
    if (state.seen.has(id)) return;
    if (t.legacy.user_id_str !== myId()) return;
    state.mineSeen++;
    const ms = snowflakeMs(id);
    if (state.oldestMs === null || ms < state.oldestMs) state.oldestMs = ms;
    if (ms > cutoffMs()) return;
    const rtSrc = t.legacy.retweeted_status_result?.result;
    const src = rtSrc?.tweet ?? rtSrc;   // TweetWithVisibilityResults 対応
    // skip 条件は seen に入れない (チェックを外せば後で拾える)。skipped は同じ投稿を何度も数えないよう別 Set
    const mine = !!t.legacy.bookmarked;
    const byOthers = (t.legacy.bookmark_count || 0) - (mine ? 1 : 0) > 0;
    const likedByOthers = (t.legacy.favorite_count || 0) - (t.legacy.favorited ? 1 : 0);   // 自分のいいねは除く
    if ((state.skipBookmarked && mine) || (state.skipBookmarkedBy && byOthers) || (state.skipLiked && likedByOthers >= state.likeMin)) {
      if (!state.skippedIds.has(id)) { state.skippedIds.add(id); state.stats.skipped++; render(); }
      return;
    }
    state.seen.add(id);
    state.queue.set(id, src ? { kind: 'rt', sourceId: src.rest_id } : { kind: 'tweet' });
    state.stats.queued++;
    render();
  }
  function harvest(text) {
    state.gqlResponses++;
    try { walk(JSON.parse(text)); } catch { /* not json */ }
  }
  function captureHeaders(h) {
    if (!h) return;
    const out = {};
    new Headers(h).forEach((v, k) => { out[k] = v; });
    if (out['x-csrf-token']) state.pageHeaders = out;
  }
  const isGql = (url) => /\/i\/api\/graphql\//.test(String(url));

  const origFetch = window.fetch;
  window.fetch = async function (input, init) {
    const url = typeof input === 'string' ? input : input?.url;
    const res = await origFetch.apply(this, arguments);
    if (isGql(url)) {
      captureHeaders(input instanceof Request ? input.headers : init?.headers);
      res.clone().text().then(harvest).catch(() => {});
    }
    return res;
  };
  const XP = XMLHttpRequest.prototype;
  const [xOpen, xSetHdr, xSend] = [XP.open, XP.setRequestHeader, XP.send];
  XP.open = function (m, url) { this.__xcUrl = url; this.__xcHdr = {}; return xOpen.apply(this, arguments); };
  XP.setRequestHeader = function (k, v) { if (this.__xcHdr) this.__xcHdr[k.toLowerCase()] = v; return xSetHdr.apply(this, arguments); };
  XP.send = function () {
    if (isGql(this.__xcUrl)) {
      this.addEventListener('load', () => { captureHeaders(this.__xcHdr); harvest(this.responseText); });
    }
    return xSend.apply(this, arguments);
  };

  // ---------- delete ----------
  async function gql(qid, op, variables) {
    const headers = {
      authorization: BEARER,
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-active-user': 'yes',
      ...state.pageHeaders,
      'x-csrf-token': cookie('ct0'),
      'content-type': 'application/json',
    };
    const res = await origFetch(`https://x.com/i/api/graphql/${qid}/${op}`, {
      method: 'POST', headers, credentials: 'include',
      body: JSON.stringify({ variables, queryId: qid }),
    });
    const body = await res.json().catch(() => ({}));
    return { res, body };
  }
  async function deleteOne(id, item) {
    if (state.dryRun) {
      console.log('[xcleaner][dry] would delete', item.kind, id);
      state.dryDone.set(id, item);
      state.stats.deleted++;
      return;
    }
    const { res, body } = item.kind === 'rt'
      ? await gql(UNRT_QID, 'DeleteRetweet', { source_tweet_id: item.sourceId, dark_request: false })
      : await gql(DELETE_QID, 'DeleteTweet', { tweet_id: id, dark_request: false });

    if (res.status === 429 || res.headers.get('x-rate-limit-remaining') === '0') {
      const reset = Number(res.headers.get('x-rate-limit-reset')) * 1000;
      const wait = Math.min(Math.max(reset - Date.now() + 5000, 5000), 16 * 60e3);
      if (res.status === 429) state.queue.set(id, item);   // 失敗分は積み直し
      state.status = `rate limited, resume ${new Date(Date.now() + wait).toLocaleTimeString()}`;
      render();
      await sleep(wait);
      return;
    }
    const msg = JSON.stringify(body.errors ?? '');
    if (res.ok && !body.errors) state.stats.deleted++;
    else if (/not found|no status|already|deleted/i.test(msg)) state.stats.gone++;
    else if (res.status === 403 || res.status === 404) {
      state.stats.failed++;
      state.running = false;
      state.status = `fatal ${res.status}: ${msg}`;
      console.error('[xcleaner] fatal', res.status, msg, '(x-client-transaction-id が必要な可能性)');
    } else {
      state.stats.failed++;
      console.warn('[xcleaner] failed', res.status, msg);
    }
  }
  async function loop() {
    while (state.running) {
      const next = state.queue.entries().next();
      if (next.done) { state.status = 'waiting for queue'; render(); await sleep(1000); continue; }
      const [id, item] = next.value;
      state.queue.delete(id);
      state.status = `deleting ${id}`;
      render();
      await deleteOne(id, item);
      render();
      await sleep(DELETE_INTERVAL_MS);
    }
    state.status = 'stopped (harvesting continues)';
    render();
  }
  function start() { if (state.running) return; state.running = true; loop(); }
  function stop() { state.running = false; state.driving = false; }

  // ---------- auto: 検索 + スクロール ----------
  const fmt = (d) => d.toISOString().slice(0, 10);
  const myHandle = () =>
    document.querySelector('[data-testid="AppTabBar_Profile_Link"]')?.getAttribute('href')?.replace(/^\//, '');
  function navigate(path) {
    history.pushState({}, '', path);
    dispatchEvent(new PopStateEvent('popstate', { state: {} }));
  }
  async function waitFor(cond, ms) {
    const t0 = Date.now();
    while (!cond() && Date.now() - t0 < ms) await sleep(250);
    return cond();
  }
  async function scrollUntilIdle() {
    let idle = 0, lastH = 0, lastSeen = state.harvested;
    while (state.driving && idle < IDLE_TICKS) {
      scrollTo(0, document.documentElement.scrollHeight);
      await sleep(SCROLL_MS);
      const h = document.documentElement.scrollHeight;
      idle = (h === lastH && state.harvested === lastSeen) ? idle + 1 : 0;
      lastH = h; lastSeen = state.harvested;
    }
  }
  async function goto(path) {
    const n0 = state.gqlResponses;
    navigate(path);
    const loaded = await waitFor(() => state.gqlResponses > n0, 15000);
    if (!loaded) console.warn('[xcleaner] no GraphQL response after navigate; scrolling anyway');
  }
  async function waitQueueDrained() {
    while (state.driving && state.queue.size > 0) await sleep(2000);
  }
  // フェーズ 1: 選んだプロフィールタブを底まで舐めて消し切る、を新規 0 件になるまで繰り返す
  // タイムラインは新しい順に一定数しか返さないが、古い分を消すと次に古いものが見えるようになる
  async function driveTimeline(handle) {
    for (let pass = 1; state.driving; pass++) {
      const before = state.stats.queued;
      state.status = `timeline pass ${pass}`; render();
      const target = `/${handle}${state.tab === 'posts' ? '' : '/' + state.tab}`;
      await goto(state.tab === 'posts' ? `/${handle}/with_replies` : `/${handle}`);   // 同じ URL では再取得されないので別タブを経由
      await goto(target);
      await scrollUntilIdle();
      if (state.stats.queued === before) return `timeline: no new items after ${pass} pass(es)`;
      state.status = `timeline pass ${pass}: draining ${state.queue.size}`; render();
      await waitQueueDrained();
    }
    return 'stopped';
  }
  // フェーズ 2 (post のみ): 検索を since/until の窓で遡る。タイムラインで届かなかった分の保険
  async function driveSearch(handle) {
    // 床はアカウント作成日 (前日)。取れていなければ FLOOR_DATE
    const floor = state.createdMs ? fmt(new Date(state.createdMs - 86400e3)) : FLOOR_DATE;
    let until = new Date(Math.min(cutoffMs(), state.oldestMs ?? Infinity)), empty = 0;
    while (state.driving && fmt(until) > floor) {
      const since = new Date(Math.max(until.getTime() - WINDOW_DAYS * 86400e3, Date.parse(floor)));
      const q = `from:${handle} since:${fmt(since)} until:${fmt(until)}`;
      const before = state.mineSeen;
      state.status = `search ${q}`; render();
      await goto(`/search?q=${encodeURIComponent(q)}&src=typed_query&f=live`);
      await scrollUntilIdle();
      empty = state.mineSeen === before ? empty + 1 : 0;   // 自分の投稿が 1 件も来なかった窓
      if (empty >= EMPTY_WINDOWS_TO_STOP) return `search: ${EMPTY_WINDOWS_TO_STOP} empty windows`;
      until = since;
    }
    return `search: reached ${floor}`;
  }
  async function drive() {
    const handle = myHandle();
    if (!handle) { state.status = 'profile link not found (open any x.com page first)'; render(); return; }
    state.driving = true;
    let done = await driveTimeline(handle);
    if (state.driving && state.tab !== 'reposts') done += ' / ' + await driveSearch(handle);   // 検索はリポストを返さない
    if (state.driving) state.status = `auto finished (${done})`;
    state.driving = false;
    render();
  }
  function auto() { if (state.driving) return; start(); drive(); }

  // ---------- ui ----------
  let box, text, btn, daysInput, radios = [];
  function mountUi() {
    if (box || !document.body) return;
    box = document.createElement('div');
    Object.assign(box.style, {
      position: 'fixed', right: '12px', bottom: '12px', zIndex: 99999, padding: '8px 12px',
      background: 'rgba(0,0,0,.85)', color: '#fff', font: '12px/1.5 monospace', borderRadius: '8px',
      width: 'max-content', maxWidth: 'calc(100vw - 24px)', whiteSpace: 'pre',
    });
    text = document.createElement('div');
    text.style.whiteSpace = 'pre-wrap';
    const newRow = () => { const d = document.createElement('div'); d.style.marginTop = '4px'; return d; };
    const styleBtn = (b) => Object.assign(b.style, {
      background: '#fff', color: '#000', border: '1px solid #888', borderRadius: '4px',
      padding: '2px 10px', font: 'inherit', cursor: 'pointer',
    });
    btn = document.createElement('button');   // auto <-> stop のトグル
    styleBtn(btn);
    btn.onclick = () => (state.running ? stop() : auto());
    const dry = document.createElement('label');
    dry.style.marginLeft = '8px';
    const cb = document.createElement('input');
    cb.type = 'checkbox'; cb.checked = state.dryRun;
    cb.onchange = () => {
      state.dryRun = cb.checked;
      if (!state.dryRun && state.dryDone.size) {   // dry で流した分を実削除キューに戻す
        state.dryDone.forEach((item, id) => state.queue.set(id, item));
        state.stats.deleted -= state.dryDone.size;
        state.dryDone.clear();
      }
      render();
    };
    dry.append(cb, ' dry run');
    radios = ['posts', 'with_replies', 'reposts'].map((m, i) => {
      const l = document.createElement('label');
      if (i) l.style.marginLeft = '8px';
      const r = document.createElement('input');
      r.type = 'radio'; r.name = 'xcleaner-tab'; r.value = m; r.checked = state.tab === m;
      r.style.accentColor = '#1d9bf0';   // 暗い背景でも選択状態が見えるように
      r.onchange = () => { if (r.checked) { state.tab = m; render(); } };
      l.append(r, ' ' + m);
      return r;
    });
    const daysLabel = document.createElement('label');
    daysInput = document.createElement('input');
    daysInput.type = 'number'; daysInput.min = '0'; daysInput.value = state.days;
    Object.assign(daysInput.style, { width: '3.5em', font: 'inherit', textAlign: 'right' });
    daysInput.onchange = () => { state.days = Math.max(0, Number(daysInput.value) || 0); daysInput.value = state.days; render(); };
    daysLabel.append('older than ', daysInput, ' days');
    const row1 = newRow(); row1.append(btn, dry);
    const row2 = newRow(); row2.append(...radios.map((r) => r.parentElement));
    const row3 = newRow(); row3.append(daysLabel);
    const skipBox = (key, ...labelParts) => {
      const l = document.createElement('label');
      l.style.marginLeft = '8px';
      const c = document.createElement('input');
      c.type = 'checkbox'; c.checked = state[key];
      c.style.accentColor = '#1d9bf0';
      c.onchange = () => { state[key] = c.checked; render(); };
      l.append(c, ' ', ...labelParts);
      return l;
    };
    const likeInput = document.createElement('input');
    likeInput.type = 'number'; likeInput.min = '0'; likeInput.value = state.likeMin;
    Object.assign(likeInput.style, { width: '3.5em', font: 'inherit', textAlign: 'right' });
    likeInput.onchange = () => { state.likeMin = Math.max(0, Number(likeInput.value) || 0); likeInput.value = state.likeMin; render(); };
    const skipRow1 = newRow();
    skipRow1.append('skip:', skipBox('skipBookmarked', 'bookmarkした'), skipBox('skipBookmarkedBy', 'bookmarkされた'));
    const skipRow2 = newRow();
    skipRow2.append('     ', skipBox('skipLiked', 'いいね ', likeInput, ' 以上'));
    box.append(text, row1, row2, row3, skipRow1, skipRow2);
    document.body.appendChild(box);
    render();
  }
  function render() {
    if (!text) return;
    const s = state.stats;
    text.textContent =
      `xcleaner v0.3.0 [${state.tab} >${state.days}d] ${state.dryRun ? '[DRY RUN]' : '[LIVE]'}${state.driving ? ' [AUTO]' : ''}\n` +
      `queue ${state.queue.size} | queued ${s.queued} | deleted ${s.deleted} | gone ${s.gone} | failed ${s.failed} | skipped ${s.skipped}\n` +
      state.status;
    btn.textContent = state.running ? 'stop' : 'auto';
    radios.forEach((r) => { r.disabled = state.running; });   // 実行中はモード・日数変更不可
    if (daysInput) daysInput.disabled = state.running;
  }
  if (document.body) mountUi();
  else document.addEventListener('DOMContentLoaded', mountUi, { once: true });

  window.__xcleaner = { start, stop, auto, state };
  console.log(`[xcleaner] loaded. cutoff=${new Date(cutoffMs()).toISOString()}`);
})();
