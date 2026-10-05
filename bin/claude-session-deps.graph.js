// claude-session-deps.graph.js - 依存グラフの描画 (vanilla JS, 外部ライブラリ無し)
//
// データは window.CSD_DATA ({generated_at, interval, sessions, graph:{nodes,edges}, changes})。
// 初回は index.html が <script src="data.js"> で同期的に読み込む。以後は本ファイルが
// data.js を動的に <script> 再注入して定期的に読み直す (file:// では fetch() が CORS で
// 弾かれるため、script タグ経由での読み込みに統一している)。
//
// レイアウト: longest-path layering (依存先ほど左) + 1回だけの barycenter 整列。
// dagre 等は使わず、10〜20 ノード規模を想定した vanilla 実装 (設計の経緯は
// ~/.claude/plans/plan-claude-session-deps.md の「再分析と再設計 (v2)」参照)。

(function () {
  "use strict";

  const COLUMN_WIDTH = 260;
  const ROW_HEIGHT = 92;
  const MARGIN_X = 40;
  const MARGIN_Y = 40;
  const DEFAULT_INTERVAL_MS = 5000;

  const DIRECTED_KINDS = new Set(["prerequisite", "followup", "waits"]);

  function esc(s) {
    const d = document.createElement("div");
    d.textContent = s === null || s === undefined ? "" : String(s);
    return d.innerHTML;
  }

  function cssSafeId(s) {
    return "n-" + String(s).replace(/[^a-zA-Z0-9_-]/g, "_");
  }

  // ---------------------------------------------------------------------
  // データ読み込み (初回は静的 <script>、以後はポーリングで再注入)
  // ---------------------------------------------------------------------
  function pollData(onData) {
    const old = document.getElementById("csd-data-script");
    if (old) old.remove();
    const s = document.createElement("script");
    s.id = "csd-data-script";
    s.src = "data.js?t=" + Date.now();
    s.onload = () => onData(window.CSD_DATA);
    s.onerror = () => {
      // file:// 環境によっては動的な script 再読み込みがブロックされることがある。
      // その場合は初回表示のまま固定され、ページの再読み込み (手動 F5) が代替手段になる。
      console.warn("claude-session-deps: data.js の再読み込みに失敗しました");
    };
    document.body.appendChild(s);
  }

  // ---------------------------------------------------------------------
  // レイアウト: longest-path layering + barycenter
  // ---------------------------------------------------------------------
  function computeLayout(nodes, edges) {
    const byId = new Map(nodes.map((n) => [n.id, n]));
    const dependsOn = new Map(); // src -> [dst,...] (DIRECTED_KINDS のみ)
    for (const n of nodes) dependsOn.set(n.id, []);
    for (const e of edges) {
      if (!DIRECTED_KINDS.has(e.kind)) continue;
      if (!byId.has(e.from) || !byId.has(e.to)) continue;
      dependsOn.get(e.from).push(e.to);
    }

    const layerCache = new Map();
    function layerOf(id, visiting) {
      if (layerCache.has(id)) return layerCache.get(id);
      if (visiting.has(id)) return 0; // 循環は深追いしない (保険)
      visiting.add(id);
      let maxChild = -1;
      for (const dst of dependsOn.get(id) || []) {
        maxChild = Math.max(maxChild, layerOf(dst, visiting));
      }
      visiting.delete(id);
      const layer = maxChild + 1;
      layerCache.set(id, layer);
      return layer;
    }
    for (const n of nodes) layerOf(n.id, new Set());

    const layers = new Map(); // layerIndex -> [nodeId,...]
    for (const n of nodes) {
      const l = layerCache.get(n.id) || 0;
      if (!layers.has(l)) layers.set(l, []);
      layers.get(l).push(n.id);
    }
    const layerIndices = [...layers.keys()].sort((a, b) => a - b);

    // barycenter: 1回だけ、左の層の確定済み y 順をもとに右の層を並べ替える
    const yIndex = new Map(); // nodeId -> このレイヤー内の表示順
    for (const li of layerIndices) {
      const ids = layers.get(li);
      if (li === layerIndices[0]) {
        ids.forEach((id, i) => yIndex.set(id, i));
        continue;
      }
      const incoming = new Map(); // nodeId -> [隣接ノードのyIndex,...]
      for (const e of edges) {
        if (!DIRECTED_KINDS.has(e.kind)) continue;
        if (ids.includes(e.from) && yIndex.has(e.to)) {
          if (!incoming.has(e.from)) incoming.set(e.from, []);
          incoming.get(e.from).push(yIndex.get(e.to));
        }
      }
      const withScore = ids.map((id, i) => {
        const nbrs = incoming.get(id);
        const score = nbrs && nbrs.length ? nbrs.reduce((a, b) => a + b, 0) / nbrs.length : i + 1000;
        return { id, score };
      });
      withScore.sort((a, b) => a.score - b.score);
      withScore.forEach((item, i) => yIndex.set(item.id, i));
    }

    const positions = new Map(); // nodeId -> {x,y,layer}
    for (const li of layerIndices) {
      for (const id of layers.get(li)) {
        positions.set(id, {
          x: MARGIN_X + li * COLUMN_WIDTH,
          y: MARGIN_Y + (yIndex.get(id) || 0) * ROW_HEIGHT,
          layer: li,
        });
      }
    }
    return positions;
  }

  // ---------------------------------------------------------------------
  // 描画
  // ---------------------------------------------------------------------
  function statusDotClass(status) {
    if (status === "busy" || status === "working") return "dot-ok";
    if (status === "idle" || status === "done") return "dot-idle";
    if (status === "blocked" || status === "failed" || status === "stopped") return "dot-bad";
    return "dot-unknown";
  }

  function edgeClass(edge) {
    if (edge.kind === "pair") return "bad"; // pair は「片側だけ進んでいたら危険」を強調する色
    return "unknown";
  }

  // 左端の帯色は PR の状態 (merged/closed/draft/open) 専用に固定する。
  // CI の pass/fail はここに混ぜず、行内の小さいアイコンとして別表現にする。
  function prStatusClass(node) {
    if (node.state === "MERGED") return "merged";
    if (node.state === "CLOSED") return "bad";
    if (node.draft) return "warn";
    return "ok";
  }

  function ciIconHtml(ci) {
    if (!ci) return "";
    if (ci === "SUCCESS") return '<span class="ci ci-ok" title="CI: SUCCESS">&#10003;</span>';
    if (ci === "FAILURE" || ci === "ERROR") return `<span class="ci ci-bad" title="CI: ${esc(ci)}">&#10007;</span>`;
    if (ci === "PENDING" || ci === "EXPECTED") return `<span class="ci ci-warn" title="CI: ${esc(ci)}">&#8226;</span>`;
    return `<span class="ci ci-unknown" title="CI: ${esc(ci)}">?</span>`;
  }

  function nodeBoxHtml(node) {
    if (node.type === "pr") {
      const cls = prStatusClass(node);
      const owners = (node.owners || [])
        .map((o) => `<span class="owner">@${esc(o.name)} (${esc(o.status)})</span>`)
        .join(" ");
      return `
        <div class="box pr ${cls}">
          <div class="row">
            <a class="title" href="${esc(node.url)}" target="_blank" rel="noopener">${esc(node.repo)}#${esc(node.number)}</a>
            ${ciIconHtml(node.ci)}
          </div>
          <div class="muted">${esc(node.state)}${node.draft ? " (draft)" : ""}</div>
          <div class="muted ellipsis" title="${esc(node.title)}">${esc(node.title)}</div>
          ${owners ? `<div class="owners">${owners}</div>` : ""}
        </div>`;
    }
    if (node.type === "issue") {
      return `
        <div class="box issue">
          <a class="title" href="${esc(node.url)}" target="_blank" rel="noopener">issue ${esc(node.repo)}#${esc(node.number)}</a>
          <div class="muted ellipsis" title="${esc(node.title)}">${esc(node.title)}</div>
        </div>`;
    }
    if (node.type === "remote") {
      return `
        <div class="box remote">
          <div class="title">remote: ${esc(node.name)}</div>
          <div class="muted ellipsis">${esc(node.label)}</div>
        </div>`;
    }
    // session
    return `
      <div class="box session">
        <div class="row"><span class="dot ${statusDotClass(node.status)}"></span><strong>${esc(node.name)}</strong></div>
        <div class="muted">${esc(node.status)}${node.plan && node.plan !== "-" ? " · " + esc(node.plan) : ""}</div>
      </div>`;
  }

  function render(data) {
    const board = document.getElementById("board");
    const svg = document.getElementById("edges");
    const emptyEl = document.getElementById("empty");
    const changesEl = document.getElementById("changes");
    board.innerHTML = "";
    const nodes = (data.graph && data.graph.nodes) || [];
    const edges = (data.graph && data.graph.edges) || [];

    const meta = document.getElementById("meta");
    if (meta) {
      meta.textContent = `generated ${data.generated_at || "-"} (UTC) · ${data.interval || "?"} 秒ごとに自動更新`;
    }

    if (nodes.length === 0) {
      emptyEl.hidden = false;
      renderChanges(changesEl, data.changes);
      return;
    }
    emptyEl.hidden = true;

    const positions = computeLayout(nodes, edges);
    const elById = new Map();
    for (const n of nodes) {
      const pos = positions.get(n.id) || { x: MARGIN_X, y: MARGIN_Y };
      const el = document.createElement("div");
      el.className = "node-wrap";
      el.id = cssSafeId(n.id);
      el.style.left = pos.x + "px";
      el.style.top = pos.y + "px";
      el.innerHTML = nodeBoxHtml(n);
      board.appendChild(el);
      elById.set(n.id, el);
    }

    const maxLayer = Math.max(0, ...[...positions.values()].map((p) => p.layer));
    const maxRows = Math.max(1, ...Object.values(
      [...positions.values()].reduce((acc, p) => {
        acc[p.layer] = (acc[p.layer] || 0) + 1;
        return acc;
      }, {}),
    ));
    board.style.width = MARGIN_X * 2 + (maxLayer + 1) * COLUMN_WIDTH + "px";
    board.style.height = MARGIN_Y * 2 + maxRows * ROW_HEIGHT + "px";

    drawEdges(svg, board, edges, elById);
    renderChanges(changesEl, data.changes);
  }

  function ensureMarker(defs, cls) {
    if (defs.querySelector("#arrow-" + cls)) return;
    const m = document.createElementNS("http://www.w3.org/2000/svg", "marker");
    m.setAttribute("id", "arrow-" + cls);
    m.setAttribute("viewBox", "0 0 10 10");
    m.setAttribute("refX", "9");
    m.setAttribute("refY", "5");
    m.setAttribute("markerWidth", "6");
    m.setAttribute("markerHeight", "6");
    m.setAttribute("orient", "auto-start-reverse");
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("d", "M 0 0 L 10 5 L 0 10 z");
    path.setAttribute("class", "arrowhead-" + cls);
    m.appendChild(path);
    defs.appendChild(m);
  }

  function drawEdges(svg, board, edges, elById) {
    while (svg.firstChild) svg.removeChild(svg.firstChild);
    svg.setAttribute("width", board.scrollWidth || board.style.width);
    svg.setAttribute("height", board.scrollHeight || board.style.height);
    const defs = document.createElementNS("http://www.w3.org/2000/svg", "defs");
    svg.appendChild(defs);
    for (const e of edges) {
      const fromEl = elById.get(e.from);
      const toEl = elById.get(e.to);
      if (!fromEl || !toEl) continue;
      const directed = DIRECTED_KINDS.has(e.kind);
      // depends_on は「依存元(from) -> 依存先(to)」だが、依存先を左に置くレイアウトなので
      // 矢印は to -> from (左から右) ではなく from -> to (右から左) に見える向きで描く
      const r1 = fromEl.getBoundingClientRect();
      const r2 = toEl.getBoundingClientRect();
      const boardRect = board.getBoundingClientRect();
      const fromRight = r1.left > r2.left;
      const x1 = (fromRight ? r1.left : r1.right) - boardRect.left;
      const y1 = r1.top + r1.height / 2 - boardRect.top;
      const x2 = (fromRight ? r2.right : r2.left) - boardRect.left;
      const y2 = r2.top + r2.height / 2 - boardRect.top;
      const midX = (x1 + x2) / 2;
      const cls = edgeClass(e);
      ensureMarker(defs, cls);
      const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
      path.setAttribute("d", `M ${x1} ${y1} C ${midX} ${y1}, ${midX} ${y2}, ${x2} ${y2}`);
      path.setAttribute("class", "edge edge-" + cls + (e.kind === "pair" ? " edge-pair" : "") + (!directed ? " edge-undirected" : ""));
      if (directed) path.setAttribute("marker-end", "url(#arrow-" + cls + ")");
      const title = document.createElementNS("http://www.w3.org/2000/svg", "title");
      title.textContent = `${e.kind}${e.note ? ": " + e.note : ""}`;
      path.appendChild(title);
      svg.appendChild(path);
    }
  }

  function renderChanges(el, changes) {
    if (!el) return;
    if (!changes || changes.length === 0) {
      el.innerHTML = '<span class="muted">変化なし</span>';
      return;
    }
    el.innerHTML = changes
      .slice()
      .reverse()
      .map((c) => `<div class="change-line"><span class="muted">${esc(c.ts)}</span> ${esc(c.node)}: ${esc(c.msg)}</div>`)
      .join("");
  }

  // ---------------------------------------------------------------------
  // 起動
  // ---------------------------------------------------------------------
  function start() {
    if (window.CSD_DATA) render(window.CSD_DATA);
    const intervalMs = (window.CSD_DATA && window.CSD_DATA.interval ? window.CSD_DATA.interval * 1000 : DEFAULT_INTERVAL_MS);
    setInterval(() => pollData(render), intervalMs);
    window.addEventListener("resize", () => {
      if (window.CSD_DATA) render(window.CSD_DATA);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
