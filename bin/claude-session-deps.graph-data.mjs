#!/usr/bin/env node
// claude-session-deps.graph-data.mjs - session / PR 依存グラフの組み立て (v2)
//
// bash 側 (claude-session-deps) から呼ばれる。役割:
//   1. live session 一覧は bash の `_sessions_json` (build_entries) を子プロセスで呼んで再利用する
//   2. 各 session の PR を seed に、GitHub GraphQL の cross-reference (incoming) と
//      PR 本文の正規表現走査 (outgoing) で 1 ホップ先の PR / issue を発見する
//   3. 言及箇所の前後の方向語から辺の種別 (pair / prerequisite / followup / related) を決める
//   4. `.deps` (手動宣言) を overlay し、`.deps-ignore` で誤検出を抑制する
//   5. 前回スナップショットとの差分を「変化ログ」として残す
//   6. data.js ({sessions, graph, changes}) を書き出す / JSON を stdout に出す / 静的シェルを配置する
//
// Node のみで完結させている理由: 使うのは `gh` 呼び出し・JSON・正規表現・ファイル I/O だけで
// サードパーティ依存が無く、ブラウザ側の描画 (vanilla JS) と言語を揃えるため。
// python3 ではなく Node を選んだ経緯は plan-claude-session-deps.md の「v2 実装の構成」参照。
//
// 設計の経緯は ~/.claude/plans/plan-claude-session-deps.md の「再分析と再設計 (v2)」を参照。

import { execFile as execFileCb } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const execFile = promisify(execFileCb);

// ---------------------------------------------------------------------------
// 定数
// ---------------------------------------------------------------------------
const CLAUDE_DIR = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), ".claude");
const PLANS_DIR = path.join(CLAUDE_DIR, "plans");
const IGNORE_FILE = path.join(PLANS_DIR, ".deps-ignore");
const CACHE_BASE = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"), "claude-session-deps");
const GQL_CACHE = path.join(CACHE_BASE, "gql");
const TYPE_CACHE = path.join(CACHE_BASE, "type");
const ISSUE_CACHE = path.join(CACHE_BASE, "issue");
const SEED_CACHE = path.join(CACHE_BASE, "seed.json");
const VIEWER_CACHE = path.join(CACHE_BASE, "viewer.json");
const GRAPH_DIR = path.join(CACHE_BASE, "graph");
const PREV_SNAPSHOT = path.join(GRAPH_DIR, "prev.json");
const CHANGES_LOG = path.join(GRAPH_DIR, "changes.jsonl");

const PR_TTL_MS = 60 * 1000;                 // PR の state / 本文 / cross-ref のキャッシュ
const MERGED_WINDOW_MS = 14 * 24 * 3600 * 1000; // merged / closed 済みでも表示する期間
const ISSUE_TTL_MS = 5 * 60 * 1000;          // 依存先 issue の state / assignee のキャッシュ
const VIEWER_TTL_MS = 24 * 3600 * 1000;       // gh の認証ユーザー名
const STALE_DAYS = 30;                        // 自分の PR がこの日数更新なしなら stale 表示
const CHANGES_KEEP = 50;
const CHANGES_SHOW = 20;
const CONTEXT_CHARS = 60;
// owner/repo の手掛かりが無い bare "#N" 参照 (地の文の単語 + #N を含む) の最小信頼番号。
// 本文内のローカルな番号付け ("DoD#1"〜"#4" 等) を実在の issue/PR 番号と誤認しないための閾値。
// このリポジトリ群で観測された実在番号は全て 24000 台以降なので、十分安全側に倒している
const MIN_BARE_NUMBER = 100;

const PAIR_WORDS = ["対になる", "セットで", "同時マージ", "同時デプロイ", "同時に出す", "同時リリース"];
const PREREQ_WORDS = ["前提PR", "前提 PR", "前提", "先行", "depends on", "Depends on", "based on",
  "で入った", "マージ済み", "マージ後", "取り込み済み", "取り込まれた", "rebase 済み", "rebase済み"];
const FOLLOWUP_WORDS = ["後に実装", "後続", "派生", "follow-up", "followup", "後で対応", "別PR で", "別 PR で"];
const GENERIC_TOKENS = new Set(["pr", "prs", "issue", "issues", "pull", "mr"]);
// kebab-case の repo slug ("my-repo" 等)。単語1つ+ハイフン1つ以上の形だけ受理し、
// 単独の "-" や通常の英単語 ("closes" 等) を誤って repo 名扱いしないようにする。
const REPO_SLUG_RE = /^[A-Za-z0-9]+(-[A-Za-z0-9]+)+$/;

const URL_RE = /github\.com\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)\/(pull|issues)\/(\d+)/g;
const MENTION_RE = /(?:(?<owner>[A-Za-z0-9_.-]+)\/)?(?<repo>[A-Za-z0-9_.-]+)\s?#(?<num>\d+)|(?<![\w/#])#(?<bare>\d+)/g;

const KIND_PRIORITY = { pair: 3, prerequisite: 2, followup: 2, related: 1 };
// GitHub 上の構造 (base branch / blocked-by) から確定した辺。本文の方向語より確度が高いので優先する
const STRUCTURAL_SOURCES = new Set(["stacked", "blockedBy"]);

const PEOPLE = "author{login} assignees(first:5){nodes{login}}";
const ISSUE_FIELDS = `number url state title updatedAt closedAt ${PEOPLE} repository{nameWithOwner}`;
const GQL_QUERY = `
query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      number url title body state isDraft mergedAt closedAt updatedAt baseRefName headRefName
      reviewDecision mergeable author{login}
      repository{ nameWithOwner owner{login} defaultBranchRef{name} }
      commits(last:1){ nodes{ commit{ statusCheckRollup{ state } } } }
      reviewRequests(first:10){ nodes{ requestedReviewer{ __typename ... on User{login} ... on Team{name} ... on Bot{login} } } }
      latestReviews(first:10){ nodes{ author{login} state } }
      closingIssuesReferences(first:20){ nodes{ ${ISSUE_FIELDS}
        blockedBy(first:10){ nodes{ ${ISSUE_FIELDS} } } } }
      timelineItems(first:100, itemTypes:[CROSS_REFERENCED_EVENT]){
        nodes{ ... on CrossReferencedEvent { isCrossRepository createdAt
          source{ __typename
            ... on PullRequest { number url state isDraft mergedAt closedAt title repository{nameWithOwner} }
            ... on Issue { number url state closedAt title repository{nameWithOwner} } } } } }
    }
  }
}
`;
// stacked PR の検出用: base branch を head に持つ open PR (= 自分の PR が乗っている土台の PR)
const STACK_QUERY = `
query($owner:String!,$repo:String!,$head:String!){
  repository(owner:$owner,name:$repo){
    pullRequests(headRefName:$head, states:OPEN, first:1){ nodes{ number } }
  }
}
`;

function log(msg) {
  process.stderr.write(`claude-session-deps.graph-data: ${msg}\n`);
}

function isoNow() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function parseIso(s) {
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

// ---------------------------------------------------------------------------
// 外部コマンド
//
// gh への問い合わせは全部独立した読み取りなので、Promise.all で並列発行する。
// 逐次 (spawnSync) だと `gh` のプロセス起動オーバーヘッドだけで 1 回 0.3〜0.5 秒かかり、
// live 7 PR の1ホップ展開で ~24 回呼ぶと 20 秒前後になって「数秒で refresh」という
// 要件に反することが実機計測 (v2 実装時) で判明したため、最初から非同期で組んでいる。
// ---------------------------------------------------------------------------
async function runJson(cmd) {
  let stdout;
  try {
    ({ stdout } = await execFile(cmd[0], cmd.slice(1), { encoding: "utf8", maxBuffer: 20 * 1024 * 1024 }));
  } catch (err) {
    if (err && err.code === "ENOENT") {
      log(`コマンドが見つかりません: ${cmd[0]}`);
    } else {
      const stderr = (err && err.stderr) ? String(err.stderr).trim().slice(0, 200) : String(err);
      log(`失敗: ${cmd.slice(0, 4).join(" ")}… ${stderr}`);
    }
    return null;
  }
  try {
    return JSON.parse(stdout);
  } catch {
    log(`JSON として読めません: ${cmd.slice(0, 4).join(" ")}…`);
    return null;
  }
}

async function loadSessions(scriptPath) {
  // claude-session-deps (bash) の既存 `json` サブコマンド (= build_entries) をそのまま再利用する。
  // v1 で検証済みのロジック (session一覧・PR紐付け・.deps解決) を二重実装しない。
  const data = await runJson([scriptPath, "json"]);
  return Array.isArray(data) ? data : [];
}

function cacheFresh(p, ttlMs) {
  try {
    return Date.now() - fs.statSync(p).mtimeMs < ttlMs;
  } catch {
    return false;
  }
}

function writeFileAtomic(p, text) {
  const tmp = `${p}.tmp.${process.pid}`;
  fs.writeFileSync(tmp, text, "utf8");
  fs.renameSync(tmp, p);
}

// TTL 付きで JSON をファイルキャッシュする共通処理。fetcher が null を返したらキャッシュしない
async function cachedJson(cachePath, ttlMs, fetcher) {
  fs.mkdirSync(path.dirname(cachePath), { recursive: true });
  if (cacheFresh(cachePath, ttlMs)) {
    try {
      return JSON.parse(fs.readFileSync(cachePath, "utf8"));
    } catch {
      // キャッシュ破損時はフォールスルーして取り直す
    }
  }
  const value = await fetcher();
  if (value === null || value === undefined) return null;
  writeFileAtomic(cachePath, JSON.stringify(value));
  return value;
}

async function fetchPr(owner, repo, number) {
  return cachedJson(path.join(GQL_CACHE, `${owner}_${repo}_${number}.json`), PR_TTL_MS, async () => {
    const data = await runJson([
      "gh", "api", "graphql", "-f", `query=${GQL_QUERY}`,
      "-F", `owner=${owner}`, "-F", `repo=${repo}`, "-F", `number=${number}`,
    ]);
    return (data && data.data && data.data.repository && data.data.repository.pullRequest) || null;
  });
}

// base branch を head に持つ open PR の番号 (無ければ 0)。0 もキャッシュして毎回問い合わせない
async function fetchStackBase(owner, repo, head) {
  const safe = head.replace(/[^A-Za-z0-9_.-]/g, "_");
  const r = await cachedJson(path.join(GQL_CACHE, `stack_${owner}_${repo}_${safe}.json`), PR_TTL_MS, async () => {
    const data = await runJson([
      "gh", "api", "graphql", "-f", `query=${STACK_QUERY}`,
      "-F", `owner=${owner}`, "-F", `repo=${repo}`, "-f", `head=${head}`,
    ]);
    if (!data || !data.data) return null;
    const n = ((((data.data.repository || {}).pullRequests || {}).nodes) || [])[0];
    return { number: n ? n.number : 0 };
  });
  return r ? r.number : 0;
}

// REST の issue 1 件 (state / title / author / assignees / updated_at)。本文言及で見つけた
// 事前・事後対応 issue のメタ情報に使う
async function fetchIssue(owner, repo, number) {
  return cachedJson(path.join(ISSUE_CACHE, `${owner}_${repo}_${number}.json`), ISSUE_TTL_MS, async () => {
    const d = await runJson(["gh", "api", `repos/${owner}/${repo}/issues/${number}`]);
    if (!d || !d.number) return null;
    return {
      title: d.title || "", state: String(d.state || "").toUpperCase(), url: d.html_url || "",
      updatedAt: d.updated_at || "", author: (d.user || {}).login || "",
      assignees: (d.assignees || []).map((a) => a.login),
    };
  });
}

async function fetchViewer() {
  const v = await cachedJson(VIEWER_CACHE, VIEWER_TTL_MS, async () => {
    const d = await runJson(["gh", "api", "user"]);
    return d && d.login ? { login: d.login } : null;
  });
  return v ? v.login : "";
}

// 自分が author の open PR (= board の主語)。remote session が作った PR もここで拾える
async function fetchSeeds() {
  const list = await cachedJson(SEED_CACHE, PR_TTL_MS, async () => {
    const d = await runJson([
      "gh", "search", "prs", "--author", "@me", "--state", "open",
      "--json", "repository,number", "--limit", "100",
    ]);
    return Array.isArray(d) ? d.map((p) => ({ repo: p.repository.nameWithOwner, number: p.number })) : null;
  });
  return list || [];
}

async function lookupType(owner, repo, number) {
  fs.mkdirSync(TYPE_CACHE, { recursive: true });
  const p = path.join(TYPE_CACHE, `${owner}_${repo}_${number}`);
  try {
    const cached = fs.readFileSync(p, "utf8").trim();
    if (cached === "pr" || cached === "issue" || cached === "none") return cached;
  } catch {
    // キャッシュなし。取得に進む
  }
  const data = await runJson(["gh", "api", `repos/${owner}/${repo}/issues/${number}`]);
  let kind = "none";
  if (data && typeof data === "object" && "number" in data) {
    kind = "pull_request" in data ? "pr" : "issue";
  }
  fs.writeFileSync(p, kind, "utf8");
  return kind;
}

// ---------------------------------------------------------------------------
// 本文の言及抽出と方向語判定
// ---------------------------------------------------------------------------
function classifyContext(before, after) {
  const ctx = `${before} ${after}`;
  if (PAIR_WORDS.some((w) => ctx.includes(w))) return "pair";
  if (PREREQ_WORDS.some((w) => ctx.includes(w))) return "prerequisite";
  if (FOLLOWUP_WORDS.some((w) => ctx.includes(w))) return "followup";
  return "related";
}

function extractMentions(body, selfOwner, selfRepo) {
  const mentions = [];
  if (!body) return mentions;
  // HTML コメント (PRテンプレートの "<!-- 例: closed #123, fixes #456 -->" 等の記入例・
  // 編集指示) は GitHub 上で人には見えない。実在しない番号を誤検出する主要因なので
  // スキャン対象から除く
  body = body.replace(/<!--[\s\S]*?-->/g, "");
  for (const line of body.split("\n")) {
    const found = []; // {start, end, owner, repo, number, hint}
    for (const m of line.matchAll(URL_RE)) {
      found.push({
        start: m.index, end: m.index + m[0].length,
        owner: m[1], repo: m[2], number: Number(m[4]),
        hint: m[3] === "pull" ? "pr" : "issue", certain: true,
      });
    }
    for (const m of line.matchAll(MENTION_RE)) {
      const start = m.index, end = m.index + m[0].length;
      if (found.some((f) => f.start <= start && start < f.end)) continue;
      if (m.groups.bare !== undefined) {
        const num = Number(m.groups.bare);
        found.push({ start, end, owner: selfOwner, repo: selfRepo, number: num, hint: "", certain: num >= MIN_BARE_NUMBER });
        continue;
      }
      const repo = m.groups.repo;
      const num = Number(m.groups.num);
      const hasExplicitOwner = m.groups.owner !== undefined;
      // owner/ プレフィックス無しで、かつ "my-repo" のような kebab-case repo slug にも
      // 見えない語 ("closes" / "Refs" / "Closes" / "DoD" / 単独の "-" 等、地の文の普通の単語) は
      // 誤検出の温床なので repo 名として採用しない。self-repo の bare #N 参照として扱う
      // (実例: 本文 "- closes #12345" を <org>/closes#12345 と誤解釈し 404 を連発していた)。
      // ただしこの経路は「DoD#1〜#4」のような本文内ローカルな番号付け (チェックリスト項目等) も
      // 拾ってしまうため、番号が小さい (MIN_BARE_NUMBER 未満) ものは信頼度を落とし certain:false にする
      const looksLikeRepoSlug = REPO_SLUG_RE.test(repo) || GENERIC_TOKENS.has(repo.toLowerCase());
      if (!hasExplicitOwner && !looksLikeRepoSlug) {
        found.push({ start, end, owner: selfOwner, repo: selfRepo, number: num, hint: "", certain: num >= MIN_BARE_NUMBER });
        continue;
      }
      if (GENERIC_TOKENS.has(repo.toLowerCase())) {
        // "PR #123" / "issue #123" は明示的な参照意図が強いので番号閾値は適用しない
        found.push({ start, end, owner: selfOwner, repo: selfRepo, number: num, hint: "", certain: true });
        continue;
      }
      // owner 省略時 ("my-repo #12345") は同じ owner (org) 配下とみなす。repo slug か
      // 明示 owner があるので番号閾値は適用しない
      const owner = m.groups.owner || selfOwner;
      found.push({ start, end, owner, repo, number: num, hint: "", certain: true });
    }
    found.sort((a, b) => a.start - b.start);
    for (let i = 0; i < found.length; i++) {
      const f = found[i];
      const prevEnd = i > 0 ? found[i - 1].end : 0;
      const nextStart = i + 1 < found.length ? found[i + 1].start : line.length;
      if (f.certain === false) continue; // 番号が小さすぎる bare 参照はローカルな番号付けの誤検出とみなし捨てる
      const before = line.slice(Math.max(prevEnd, f.start - CONTEXT_CHARS), f.start);
      const after = line.slice(f.end, Math.min(nextStart, f.end + CONTEXT_CHARS));
      mentions.push({ owner: f.owner, repo: f.repo, number: f.number, hint: f.hint, kind: classifyContext(before, after) });
    }
  }
  return mentions;
}

function prId(owner, repo, number) { return `pr:${owner}/${repo}#${number}`; }
function issueId(owner, repo, number) { return `issue:${owner}/${repo}#${number}`; }
function splitNameWithOwner(nwo) {
  const i = nwo.indexOf("/");
  return [nwo.slice(0, i), nwo.slice(i + 1)];
}
function parsePrUrl(url) {
  URL_RE.lastIndex = 0;
  const m = URL_RE.exec(url || "");
  if (!m || m[3] !== "pull") return null;
  return [m[1], m[2], Number(m[4])];
}

function withinWindow(pr) {
  if (pr.state === "OPEN") return true;
  const ts = parseIso(pr.mergedAt) || parseIso(pr.closedAt);
  if (!ts) return false;
  return Date.now() - ts.getTime() <= MERGED_WINDOW_MS;
}

function prNodeFromGql(owner, repo, number, pr) {
  const node = {
    id: prId(owner, repo, number), type: "pr", repo: `${owner}/${repo}`, number,
    url: `https://github.com/${owner}/${repo}/pull/${number}`,
    title: "", state: "UNKNOWN", draft: false, ci: "", review: "", merged_at: "", owners: [],
    author: "", base: "", head: "", default_branch: "", mergeable: "", updated_at: "",
    review_requests: [], remote_sessions: [],
  };
  if (pr) {
    const rollup = (((pr.commits || {}).nodes || [{}])[0].commit || {}).statusCheckRollup || {};
    Object.assign(node, {
      title: pr.title || "",
      state: pr.state || "UNKNOWN",
      draft: Boolean(pr.isDraft),
      ci: rollup.state || "",
      review: pr.reviewDecision || "",
      merged_at: pr.mergedAt || "",
      url: pr.url || node.url,
      author: (pr.author || {}).login || "",
      base: pr.baseRefName || "",
      head: pr.headRefName || "",
      default_branch: ((pr.repository || {}).defaultBranchRef || {}).name || "",
      mergeable: pr.mergeable || "",
      updated_at: pr.updatedAt || "",
      review_requests: (((pr.reviewRequests || {}).nodes) || [])
        .map((n) => (n.requestedReviewer || {}))
        .map((r) => r.login || (r.name ? `team:${r.name}` : ""))
        .filter(Boolean),
      // remote (claude.ai/code) session が作った PR は本文末尾に session URL を持つ。
      // local の transcript からは辿れないので、運転中 session の手掛かりはこれしかない
      remote_sessions: [...new Set(
        [...String(pr.body || "").matchAll(/https:\/\/claude\.ai\/code\/session_[A-Za-z0-9]+/g)].map((m) => m[0]),
      )],
    });
  }
  return node;
}

function issueNode(owner, repo, number, meta) {
  return {
    id: issueId(owner, repo, number), type: "issue", repo: `${owner}/${repo}`, number,
    url: meta.url || `https://github.com/${owner}/${repo}/issues/${number}`,
    title: meta.title || "", state: String(meta.state || "").toUpperCase(),
    author: meta.author || "", assignees: meta.assignees || [], updated_at: meta.updatedAt || "",
  };
}

// GraphQL の issue (ISSUE_FIELDS) を fetchIssue と同じ形に揃える
function issueMetaFromGql(n) {
  return {
    title: n.title, state: n.state, url: n.url, updatedAt: n.updatedAt,
    author: (n.author || {}).login || "",
    assignees: (((n.assignees || {}).nodes) || []).map((a) => a.login),
  };
}

// ---------------------------------------------------------------------------
// グラフ組み立て
// ---------------------------------------------------------------------------
const edgeKey = (a, b) => `${a} ${b}`;

class GraphBuilder {
  constructor(sessions, ignore, viewer, seeds) {
    this.sessions = sessions;
    this.ignore = ignore;
    this.viewer = viewer;
    this.seeds = seeds;          // [{repo:"owner/repo", number}] 自分が author の open PR
    this.nodes = new Map();      // id -> node
    this.prData = new Map();     // pr_id -> gql pr (raw)
    this.edges = new Map();      // edgeKey -> {from,to,kind,source,note}
    this.issueLinks = new Map(); // issue_id -> Set(pr_id)
    this.issueMeta = new Map();  // issue_id -> meta
    this.inflight = new Map();   // pr_id -> Promise<gql pr> (同一PRへの同時並行フェッチを1回に畳む)
  }

  fetchPrDeduped(owner, repo, number, nid) {
    if (!this.inflight.has(nid)) {
      this.inflight.set(nid, fetchPr(owner, repo, number));
    }
    return this.inflight.get(nid);
  }

  async ensurePr(owner, repo, number) {
    const nid = prId(owner, repo, number);
    if (this.ignore.has(`${owner}/${repo}#${number}`)) return null;
    if (this.nodes.has(nid)) return nid;
    const pr = await this.fetchPrDeduped(owner, repo, number, nid);
    if (!this.nodes.has(nid)) {
      this.prData.set(nid, pr);
      this.nodes.set(nid, prNodeFromGql(owner, repo, number, pr));
    }
    return nid;
  }

  async ensurePrIfInWindow(owner, repo, number) {
    const nid = prId(owner, repo, number);
    if (this.nodes.has(nid)) return nid;
    if (this.ignore.has(`${owner}/${repo}#${number}`)) return null;
    const pr = await this.fetchPrDeduped(owner, repo, number, nid);
    if (!pr || !withinWindow(pr)) return this.nodes.has(nid) ? nid : null;
    if (!this.nodes.has(nid)) {
      this.prData.set(nid, pr);
      this.nodes.set(nid, prNodeFromGql(owner, repo, number, pr));
    }
    return nid;
  }

  noteIssue(owner, repo, number, meta, linkedPr) {
    if (this.ignore.has(`${owner}/${repo}#${number}`)) return;
    const iid = issueId(owner, repo, number);
    if (!this.issueLinks.has(iid)) this.issueLinks.set(iid, new Set());
    this.issueLinks.get(iid).add(linkedPr);
    if (!this.issueMeta.has(iid)) {
      this.issueMeta.set(iid, {
        id: iid, type: "issue", repo: `${owner}/${repo}`, number,
        url: `https://github.com/${owner}/${repo}/issues/${number}`, title: "", state: "",
      });
    }
    const cur = this.issueMeta.get(iid);
    for (const k of ["title", "state", "url"]) {
      if (meta[k] && !cur[k]) cur[k] = meta[k];
    }
  }

  // 事前・事後対応や blockedBy の issue は橋渡しかどうかに関係なくノード化する
  async ensureIssue(owner, repo, number, meta = null) {
    if (this.ignore.has(`${owner}/${repo}#${number}`)) return null;
    const iid = issueId(owner, repo, number);
    if (this.nodes.has(iid)) return iid;
    const m = meta || await fetchIssue(owner, repo, number) || {};
    if (!this.nodes.has(iid)) this.nodes.set(iid, issueNode(owner, repo, number, m));
    return iid;
  }

  addEdge(src, dst, kind, source, note = "") {
    if (src === dst) return;
    const key = kind === "pair" || kind === "related"
      ? edgeKey(...[src, dst].sort())
      : edgeKey(src, dst);
    const [a, b] = key.split(" ");
    const cur = this.edges.get(key);
    if (cur && cur.source === "manual" && source !== "manual") return; // 手動宣言は自動検出で上書きしない
    if (!cur || (KIND_PRIORITY[kind] || 0) > (KIND_PRIORITY[cur.kind] || 0) || source === "manual") {
      this.edges.set(key, { from: a, to: b, kind, source, note });
    }
  }

  resolveMutualPairs() {
    for (const key of [...this.edges.keys()]) {
      if (!this.edges.has(key)) continue;
      const [a, b] = key.split(" ");
      const revKey = edgeKey(b, a);
      if (revKey === key) continue;
      if (this.edges.has(revKey)) {
        const e1 = this.edges.get(key), e2 = this.edges.get(revKey);
        if (e1.source === "manual" || e2.source === "manual") continue;
        if (STRUCTURAL_SOURCES.has(e1.source) || STRUCTURAL_SOURCES.has(e2.source)) continue;
        this.edges.delete(key);
        this.edges.delete(revKey);
        const nk = edgeKey(...[a, b].sort());
        const [na, nb] = nk.split(" ");
        this.edges.set(nk, { from: na, to: nb, kind: "pair", source: "mutual", note: "相互に言及" });
      }
    }
  }

  async expandFrom(seedId) {
    const pr = this.prData.get(seedId);
    if (!pr) return;
    const [owner, repo] = splitNameWithOwner(pr.repository.nameWithOwner);

    // outgoing: 本文の言及。言及は互いに独立な読み取りなので並列に解決する
    const mentions = extractMentions(pr.body || "", owner, repo).filter((m) => m.owner === owner);
    await Promise.all(mentions.map(async (m) => {
      const hint = m.hint || await lookupType(m.owner, m.repo, m.number);
      if (hint === "pr") {
        if (m.owner === owner && m.repo === repo && m.number === pr.number) return;
        const target = await this.ensurePrIfInWindow(m.owner, m.repo, m.number);
        if (target) this.addEdgeByKind(seedId, target, m.kind, "body");
      } else if (hint === "issue") {
        if (m.kind === "prerequisite" || m.kind === "followup") {
          // merge のための事前対応 / merge 後の事後対応 issue
          const target = await this.ensureIssue(m.owner, m.repo, m.number);
          if (target) this.addEdgeByKind(seedId, target, m.kind, "body");
        } else {
          this.noteIssue(m.owner, m.repo, m.number, {}, seedId);
        }
      }
    }));

    // closes: 構造化された issue リンク。その issue に GitHub ネイティブの blocked-by が
    // 付いていれば、それは PR の merge 前提でもあるので prerequisite 辺にする
    const blockedBy = [];
    for (const n of (pr.closingIssuesReferences || {}).nodes || []) {
      const [o, r] = splitNameWithOwner(n.repository.nameWithOwner);
      this.noteIssue(o, r, n.number, { title: n.title, state: n.state, url: n.url }, seedId);
      for (const b of ((n.blockedBy || {}).nodes) || []) blockedBy.push({ closing: n, b });
    }
    await Promise.all(blockedBy.map(async ({ closing, b }) => {
      const [o, r] = splitNameWithOwner(b.repository.nameWithOwner);
      const target = await this.ensureIssue(o, r, b.number, issueMetaFromGql(b));
      if (target) this.addEdge(seedId, target, "prerequisite", "blockedBy", `#${closing.number} が blocked by`);
    }));

    // stacked: base が default branch 以外なら、その branch を head に持つ open PR が土台
    const base = pr.baseRefName || "";
    const defaultBranch = ((pr.repository || {}).defaultBranchRef || {}).name || "";
    if (base && defaultBranch && base !== defaultBranch) {
      const n = await fetchStackBase(owner, repo, base);
      if (n && n !== pr.number) {
        const target = await this.ensurePr(owner, repo, n);
        if (target) this.addEdge(seedId, target, "prerequisite", "stacked", `base: ${base}`);
      }
    }

    // incoming: timeline の cross-reference。こちらも並列に解決する
    const timelineItems = (pr.timelineItems || {}).nodes || [];
    await Promise.all(timelineItems.map(async (item) => {
      const src = (item || {}).source || {};
      if (!src.repository) return;
      const [o, r] = splitNameWithOwner(src.repository.nameWithOwner);
      if (o !== owner) return;
      if (src.__typename === "PullRequest") {
        const target = await this.ensurePrIfInWindow(o, r, src.number);
        if (!target) return;
        const kind = this.kindFromOtherBody(target, owner, repo, pr.number);
        this.addEdgeByKind(target, seedId, kind, "timeline");
      } else if (src.__typename === "Issue") {
        this.noteIssue(o, r, src.number, { title: src.title, state: src.state, url: src.url }, seedId);
      }
    }));
  }

  // 構造的な辺がある 2 ノード間では、本文由来の推測辺 (pair / related 等) を落とす (手動宣言は残す)
  preferStructural() {
    const pairs = new Set();
    for (const e of this.edges.values()) {
      if (STRUCTURAL_SOURCES.has(e.source)) pairs.add(edgeKey(...[e.from, e.to].sort()));
    }
    for (const [k, e] of [...this.edges]) {
      if (STRUCTURAL_SOURCES.has(e.source) || e.source === "manual") continue;
      if (pairs.has(edgeKey(...[e.from, e.to].sort()))) this.edges.delete(k);
    }
  }

  kindFromOtherBody(otherId, owner, repo, number) {
    const other = this.prData.get(otherId);
    if (!other) return "related";
    const [oOwner, oRepo] = splitNameWithOwner(other.repository.nameWithOwner);
    let best = "related";
    for (const m of extractMentions(other.body || "", oOwner, oRepo)) {
      if (m.owner === owner && m.repo === repo && m.number === number) {
        if ((KIND_PRIORITY[m.kind] || 0) > (KIND_PRIORITY[best] || 0)) best = m.kind;
      }
    }
    return best;
  }

  addEdgeByKind(mentioner, mentioned, kind, source) {
    if (kind === "prerequisite") {
      this.addEdge(mentioner, mentioned, "prerequisite", source); // mentioner は mentioned の merge が前提
    } else if (kind === "followup") {
      this.addEdge(mentioned, mentioner, "followup", source);     // mentioned は mentioner の後
    } else if (kind === "pair") {
      this.addEdge(mentioner, mentioned, "pair", source);
    } else {
      this.addEdge(mentioner, mentioned, "related", source);
    }
  }

  attachBridgeIssues() {
    const connected = new Set();
    for (const e of this.edges.values()) {
      connected.add(edgeKey(...[e.from, e.to].sort()));
    }
    for (const [iid, prsSet] of this.issueLinks) {
      const prs = [...prsSet].filter((p) => this.nodes.has(p));
      if (prs.length < 2) continue;
      let allConnected = true;
      for (let i = 0; i < prs.length && allConnected; i++) {
        for (let j = i + 1; j < prs.length; j++) {
          if (!connected.has(edgeKey(...[prs[i], prs[j]].sort()))) { allConnected = false; break; }
        }
      }
      if (allConnected) continue;
      if (!this.nodes.has(iid)) this.nodes.set(iid, { ...this.issueMeta.get(iid) });
      for (const p of prs) {
        const key = edgeKey(...[p, iid].sort());
        if (!this.edges.has(key)) {
          const [a, b] = key.split(" ");
          this.edges.set(key, { from: a, to: b, kind: "related", source: "issue", note: "issue 経由" });
        }
      }
    }
  }

  async attachSessions() {
    // 各 session が所有する PR の解決は互いに独立なので並列に行う
    await Promise.all(this.sessions.map(async (s) => {
      let anchor = null;
      const parsed = parsePrUrl(s.pr_url || "");
      if (parsed) {
        anchor = await this.ensurePr(...parsed);
        if (anchor) {
          this.nodes.get(anchor).owners.push({
            name: s.name, status: s.status, tmux: s.tmux, plan: s.plan, sessionId: s.sessionId,
          });
        }
      }
      if (anchor === null) {
        const sid = `session:${s.name}`;
        this.nodes.set(sid, { id: sid, type: "session", name: s.name, status: s.status, tmux: s.tmux, plan: s.plan, sessionId: s.sessionId });
        anchor = sid;
      }
      s._anchor = anchor;
    }));
    const nameToAnchor = new Map(this.sessions.map((s) => [s.name, s._anchor]));
    // .deps overlay はセッション数・宣言数ともに小さい想定なので逐次処理で十分
    for (const s of this.sessions) {
      const src = s._anchor;
      for (const dep of s.deps_detail || []) {
        if (dep.type === "pr") {
          const parsed = parsePrUrl(dep.url || "");
          if (!parsed) continue;
          const dst = await this.ensurePr(...parsed);
          if (!dst) continue;
          // session が PR を「待つ」宣言は常に prerequisite 意味論 (pair/followup は PR 同士の
          // 自動検出が使う語彙で、session→PR の手動宣言には馴染まない)
          for (const k of [...this.edges.keys()]) {
            const [a, b] = k.split(" ");
            if ((a === src && b === dst) || (a === dst && b === src)) this.edges.delete(k);
          }
          this.addEdge(src, dst, "prerequisite", "manual", dep.label || "");
        } else if (dep.type === "session") {
          let dst = nameToAnchor.get(dep.target);
          if (dst === undefined) {
            dst = `session:${dep.target}`;
            if (!this.nodes.has(dst)) {
              this.nodes.set(dst, { id: dst, type: "session", name: dep.target, status: "exited?", tmux: "-", plan: "-" });
            }
          }
          this.addEdge(src, dst, "waits", "manual", dep.label || "");
        } else if (dep.type === "remote") {
          const dst = `remote:${dep.target}`;
          if (!this.nodes.has(dst)) {
            this.nodes.set(dst, { id: dst, type: "remote", name: dep.target, label: dep.label || "" });
          }
          this.addEdge(src, dst, "waits", "manual", dep.label || "");
        }
      }
    }
  }

  async build() {
    // 主語は自分が author の open PR。session (local) が握る PR はその注釈として後から紐づける
    await Promise.all(this.seeds.map((p) => this.ensurePr(...splitNameWithOwner(p.repo), p.number)));
    await this.attachSessions();
    // seed (自分の PR + session が所有する PR) の展開は互いに独立なので並列に行う
    const seedIds = [...this.nodes.keys()].filter((n) => n.startsWith("pr:"));
    await Promise.all(seedIds.map((nid) => this.expandFrom(nid)));
    this.resolveMutualPairs();
    this.preferStructural();
    this.attachBridgeIssues();
    for (const n of this.nodes.values()) {
      if (n.type === "pr") n.mine = Boolean(this.viewer) && n.author === this.viewer;
    }
    const graph = { nodes: [...this.nodes.values()], edges: [...this.edges.values()] };
    return { graph, board: buildBoard(graph, this.viewer) };
  }
}

// ---------------------------------------------------------------------------
// board: 自分の PR ごとに「merge まで何を待っているか」を、自分で解消できるもの (self) と
// 他人待ち (others) に分けてまとめ、base branch ごとのレーンに振り分ける
// ---------------------------------------------------------------------------
function daysSince(iso) {
  const d = parseIso(iso);
  return d ? Math.floor((Date.now() - d.getTime()) / (24 * 3600 * 1000)) : null;
}

function isResolved(n) {
  return n.state === "MERGED" || n.state === "CLOSED";
}

function refItem(n, e, extra = {}) {
  return {
    id: n.id, type: n.type, ref: `${n.repo}#${n.number}`, url: n.url, title: n.title || "",
    state: n.state || "", draft: Boolean(n.draft), author: n.author || "", assignees: n.assignees || [],
    base: n.base || "", updated_days: daysSince(n.updated_at), kind: e.kind, source: e.source, note: e.note || "",
    ...extra,
  };
}

// 依存先が「自分の手で進められるか」。PR は author、issue は assignee (未割当なら author) で判定
function isMineRef(n, viewer) {
  if (!viewer) return false;
  if (n.type === "pr") return n.author === viewer;
  if (n.type === "issue") return n.assignees && n.assignees.length ? n.assignees.includes(viewer) : n.author === viewer;
  return false;
}

function buildBoard(graph, viewer) {
  const byId = new Map(graph.nodes.map((n) => [n.id, n]));
  const lanes = new Map();
  for (const pr of graph.nodes) {
    if (pr.type !== "pr" || !pr.mine || pr.state !== "OPEN") continue;
    const self = [], others = [], followups = [];
    if (pr.draft) self.push({ label: "draft" });
    if (pr.ci === "FAILURE" || pr.ci === "ERROR") self.push({ label: "CI✗" });
    if (pr.mergeable === "CONFLICTING") self.push({ label: "conflict" });
    if (pr.review === "CHANGES_REQUESTED") self.push({ label: "changes requested" });
    if (pr.review_requests.length) others.push({ label: "review 待ち", who: pr.review_requests });
    else if (pr.review === "REVIEW_REQUIRED" && !pr.draft) self.push({ label: "reviewer 未指定" });

    for (const e of graph.edges) {
      const otherId = e.from === pr.id ? e.to : e.to === pr.id ? e.from : null;
      if (!otherId) continue;
      const t = byId.get(otherId);
      if (!t || (t.type !== "pr" && t.type !== "issue")) continue;
      if (e.kind === "followup" && e.to === pr.id) {
        // 事後対応 (この PR の後にやるもの)。merge の blocker ではないので別枠
        if (!isResolved(t)) followups.push(refItem(t, e));
        continue;
      }
      const isPrereq = e.kind === "prerequisite" && e.from === pr.id;
      if (!isPrereq && e.kind !== "pair") continue;
      if (e.kind === "pair" && t.state === "MERGED") {
        self.push({ label: "ペアが先に merged", ref: `${t.repo}#${t.number}`, url: t.url });
        continue;
      }
      if (isResolved(t)) continue;
      const item = refItem(t, e, { kind: e.source === "stacked" ? "stacked" : e.kind });
      (isMineRef(t, viewer) ? self : others).push(item);
    }

    const isDefault = !pr.base || pr.base === pr.default_branch;
    const key = `${pr.repo}:${pr.base}`;
    if (!lanes.has(key)) {
      const stackEdge = graph.edges.find((e) => e.from === pr.id && e.source === "stacked");
      lanes.set(key, {
        key, repo: pr.repo, base: pr.base, is_default: isDefault,
        base_pr: stackEdge ? refItem(byId.get(stackEdge.to), stackEdge) : null, prs: [],
      });
    }
    const updatedDays = daysSince(pr.updated_at);
    lanes.get(key).prs.push({
      id: pr.id, updated_days: updatedDays, stale: updatedDays !== null && updatedDays > STALE_DAYS,
      blockers: { self, others }, followups,
    });
  }
  const laneList = [...lanes.values()];
  for (const l of laneList) {
    l.prs.sort((a, b) => (a.stale - b.stale) || ((a.updated_days ?? 1e9) - (b.updated_days ?? 1e9)));
  }
  // default branch 向けを先頭に、stacked / release branch 向けを後ろに並べる
  laneList.sort((a, b) => (b.is_default - a.is_default) || a.repo.localeCompare(b.repo) || a.base.localeCompare(b.base));
  return { viewer, stale_days: STALE_DAYS, lanes: laneList };
}

// ---------------------------------------------------------------------------
// 変化ログ
// ---------------------------------------------------------------------------
function snapshotOf(graph) {
  const snap = {};
  for (const n of graph.nodes) {
    if (n.type === "pr") snap[n.id] = { state: n.state, ci: n.ci, draft: n.draft, review: n.review };
    else if (n.type === "issue" && n.state) snap[n.id] = { state: n.state };
  }
  return snap;
}

function updateChanges(graph) {
  fs.mkdirSync(GRAPH_DIR, { recursive: true });
  let prev = {};
  try {
    prev = JSON.parse(fs.readFileSync(PREV_SNAPSHOT, "utf8"));
  } catch {
    prev = {};
  }
  const cur = snapshotOf(graph);
  const ts = isoNow();
  const hadPrev = Object.keys(prev).length > 0;
  const newEntries = [];
  for (const [nid, c] of Object.entries(cur)) {
    const p = prev[nid];
    const label = nid.replace(/^(pr|issue):/, "");
    if (p === undefined) {
      if (hadPrev) newEntries.push({ ts, node: label, msg: "グラフに現れた" }); // 初回は新規を大量に出さない
      continue;
    }
    if (p.state !== c.state) newEntries.push({ ts, node: label, msg: `state ${p.state} → ${c.state}` });
    if (p.ci !== c.ci && c.ci) newEntries.push({ ts, node: label, msg: `CI ${p.ci || "-"} → ${c.ci}` });
    if (p.review !== c.review && c.review) newEntries.push({ ts, node: label, msg: `review ${p.review || "-"} → ${c.review}` });
    if (p.draft !== undefined && p.draft !== c.draft) newEntries.push({ ts, node: label, msg: c.draft ? "draft に戻った" : "draft 解除" });
  }
  for (const nid of Object.keys(prev)) {
    if (!(nid in cur)) newEntries.push({ ts, node: nid.replace(/^(pr|issue):/, ""), msg: "グラフから消えた" });
  }
  let existing = [];
  try {
    existing = fs.readFileSync(CHANGES_LOG, "utf8").split("\n").filter(Boolean).map((l) => JSON.parse(l));
  } catch {
    existing = [];
  }
  const merged = [...existing, ...newEntries].slice(-CHANGES_KEEP);
  writeFileAtomic(CHANGES_LOG, merged.map((e) => JSON.stringify(e)).join("\n") + (merged.length ? "\n" : ""));
  writeFileAtomic(PREV_SNAPSHOT, JSON.stringify(cur));
  return merged.slice(-CHANGES_SHOW);
}

// ---------------------------------------------------------------------------
// 出力
// ---------------------------------------------------------------------------
function loadIgnore() {
  try {
    return new Set(
      fs.readFileSync(IGNORE_FILE, "utf8").split("\n")
        .map((l) => l.trim())
        .filter((l) => l && !l.startsWith("#")),
    );
  } catch {
    return new Set();
  }
}

async function buildPayload(scriptPath, interval, withChanges) {
  const [sessions, viewer, seeds] = await Promise.all([loadSessions(scriptPath), fetchViewer(), fetchSeeds()]);
  const { graph, board } = await new GraphBuilder(sessions, loadIgnore(), viewer, seeds).build();
  for (const s of sessions) delete s._anchor;
  return {
    generated_at: isoNow(),
    interval,
    sessions,
    graph,
    board,
    changes: withChanges ? updateChanges(graph) : [],
  };
}

function writeDataJs(payload) {
  fs.mkdirSync(GRAPH_DIR, { recursive: true });
  const p = path.join(GRAPH_DIR, "data.js");
  const text = JSON.stringify(payload).replace(/<\/script/g, "<\\/script");
  writeFileAtomic(p, `window.CSD_DATA = ${text};\n`);
  return p;
}

function installShell(templateDir) {
  fs.mkdirSync(GRAPH_DIR, { recursive: true });
  for (const name of ["claude-session-deps.graph.html", "claude-session-deps.graph.js"]) {
    const src = path.join(templateDir, name);
    if (!fs.existsSync(src)) throw new Error(`テンプレートが見つかりません: ${src}`);
  }
  fs.copyFileSync(path.join(templateDir, "claude-session-deps.graph.html"), path.join(GRAPH_DIR, "index.html"));
  fs.copyFileSync(path.join(templateDir, "claude-session-deps.graph.js"), path.join(GRAPH_DIR, "graph.js"));
  return path.join(GRAPH_DIR, "index.html");
}

function parseArgs(argv) {
  const args = { mode: "json", interval: 5, script: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--script") args.script = argv[++i];
    else if (a === "--mode") args.mode = argv[++i];
    else if (a === "--interval") args.interval = Number(argv[++i]);
    else throw new Error(`不明な引数: ${a}`);
  }
  if (!args.script) throw new Error("--script <claude-session-deps のパス> が必要です");
  if (!["json", "data", "shell"].includes(args.mode)) throw new Error(`--mode は json|data|shell のいずれか (指定値: ${args.mode})`);
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.mode === "shell") {
    const templateDir = path.dirname(path.resolve(args.script));
    const html = installShell(templateDir);
    const payload = await buildPayload(args.script, args.interval, true);
    writeDataJs(payload);
    process.stdout.write(html + "\n");
    return 0;
  }
  if (args.mode === "data") {
    const payload = await buildPayload(args.script, args.interval, true);
    writeDataJs(payload);
    return 0;
  }
  const payload = await buildPayload(args.script, args.interval, false);
  process.stdout.write(JSON.stringify(payload, null, 2) + "\n");
  return 0;
}

main().then(
  (code) => process.exit(code),
  (err) => {
    log(String((err && err.stack) || err));
    process.exit(1);
  },
);
