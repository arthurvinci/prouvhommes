// Renders the law into static HTML at build time, so every page works
// without JavaScript; src/ only adds interactivity on top. Pages are
// assembled in pages.js.

import { createHash } from "node:crypto";
import { ENRICHED, OPEN_NOTIONS } from "./enriched.js";
import { proofStatus } from "./extract.js";
import { SIMULATORS } from "./simulators.js";

export const REPO = "https://github.com/arthurvinci/prouvhommes";
const BLOB = `${REPO}/blob/main`;

const LEVELS = {
  absolue: ["absolue", "non dérogeable"],
  relative: ["relative", "dérogeable seulement en faveur du salarié"],
  dispositive: ["dispositive", "librement dérogeable"],
};

const STATUS = {
  proved: "Prouvé en Lean",
  missing: "Absent de la formalisation",
};

export const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

export const articleUrl = (a) => `/code/${a.slug}/`;

/** Articles grouped by part ("Titre I — …"), in document order. */
export function parts(law) {
  const list = [];
  for (const a of law.articles) {
    if (list.at(-1)?.title !== a.part) list.push({ title: a.part, articles: [] });
    list.at(-1).articles.push(a);
  }
  return list;
}

/* Le code ------------------------------------------------------------------- */

/** Side navigation of the reader: every article, the current one marked. */
export function renderToc(law, current) {
  return parts(law)
    .map(
      (p) => `<p class="toc-part">${escapeHtml(p.title)}</p>
<ol class="toc">${p.articles
        .map(
          (a) =>
            `<li><a href="${articleUrl(a)}"${a === current ? ' aria-current="page"' : ""}><span class="toc-number">${a.number}</span> ${escapeHtml(a.title)}</a></li>`,
        )
        .join("")}</ol>`,
    )
    .join("\n");
}

/** /code/: the contents, with each article's level and formal status. */
export function renderContents(law) {
  return parts(law)
    .map(
      (p) => `<section class="contents-part" aria-labelledby="${slug(p.title)}">
<h2 class="part-title" id="${slug(p.title)}">${escapeHtml(p.title)}</h2>
<ol class="contents">${p.articles
        .map((a) => {
          const level = LEVELS[a.level];
          return `<li><a class="contents-row" href="${articleUrl(a)}">
  <span class="contents-number">${a.number}</span>
  <span class="contents-title">${escapeHtml(a.title)}</span>
  ${level ? `<span class="level" data-level="${a.level}"><span class="level-mark" aria-hidden="true"></span>${level[0]}</span>` : `<span class="level"></span>`}
  <span class="contents-status">${formalStatus(a, law)}</span>
</a></li>`;
        })
        .join("\n")}</ol>
</section>`,
    )
    .join("\n");
}

function formalStatus(a, law) {
  if (a.outsideFormalisation.length) return "Hors formalisation";
  if (!a.lean.length && !a.theorems.length) return "Pas encore formalisé";
  const proved = a.theorems.filter((t) => proofStatus(t, law.decls) === "proved").length;
  if (!a.theorems.length) return "Formalisé";
  return `${proved} garantie${proved > 1 ? "s" : ""} prouvée${proved > 1 ? "s" : ""}`;
}

/** /code/texte-integral/: every article, for continuous reading. */
export function renderFullText(law, warn) {
  return parts(law)
    .map(
      (p) => `<section class="law-part" aria-labelledby="${slug(p.title)}">
<h2 class="part-title" id="${slug(p.title)}">${escapeHtml(p.title)}</h2>
${p.articles.map((a) => renderArticle(a, law, warn)).join("\n")}
</section>`,
    )
    .join("\n");
}

/** Previous and next article, at the bottom of an article page. */
export function renderArticleNav(a, law) {
  const i = law.articles.indexOf(a);
  const link = (b, rel, label) =>
    b
      ? `<a class="article-nav-${rel}" href="${articleUrl(b)}" rel="${rel}"><span>${label}</span>Article ${b.number} · ${escapeHtml(b.title)}</a>`
      : "<span></span>";
  return `<nav class="article-nav" aria-label="Articles voisins">${link(law.articles[i - 1], "prev", "Précédent")}${link(law.articles[i + 1], "next", "Suivant")}</nav>`;
}

/**
 * One article: header, the two faces, its guarantees and, for an annotated
 * article, a compact simulator linking to its full page.
 * `standalone`: the article is the page (h1), rather than a section (h3).
 */
export function renderArticle(a, law, warn, { standalone = false } = {}) {
  const enriched = a.label ? ENRICHED[a.label] : undefined;
  if (enriched && enriched.sourceHash !== sourceHash(a.body)) {
    warn(
      `[law] ${a.label}: the LaTeX changed since site/law/enriched.js was annotated. ` +
        `Update the annotated copy, then set sourceHash to "${sourceHash(a.body)}".`,
    );
  }
  const body = enriched
    ? resolveRefs(enriched.body, law) + latexTables(a.body, law)
    : latexToHtml(a.body, law);
  const declNames = enriched?.leanDecls ?? a.lean;
  const decls = declNames.map((n) => law.decls.get(n)).filter(Boolean);
  const level = LEVELS[a.level];
  const h = standalone ? "h1" : "h3";
  const simulator = enriched?.extra && SIMULATORS.find((s) => s.extra === enriched.extra);

  return `<article class="law-article" id="${a.id}"${a.label ? ` data-label="${a.label}"` : ""}${
    enriched ? ` data-links="${escapeHtml(JSON.stringify(enriched.links))}"` : ""
  }>
<header class="article-head">
  <span class="article-number" aria-hidden="true">${a.number}</span>
  <div>
    <${h} class="article-title"><span class="visually-hidden">Article ${a.number} : </span>${escapeHtml(a.title)}</${h}>
    ${level ? `<p class="level" data-level="${a.level}"><span class="level-mark" aria-hidden="true"></span>Impérativité ${level[0]} : ${level[1]}</p>` : ""}
  </div>
</header>
<section class="face-law" aria-label="Texte de l’article">
  ${body}
</section>
${renderFormalisation(a, decls)}
${a.theorems.length ? renderGuarantees(a, law, standalone) : ""}
${
  simulator
    ? `<div class="article-extra" data-extra="${simulator.extra}" data-compact data-full-url="/simulateurs/${simulator.slug}/"></div>`
    : ""
}
</article>`;
}

/**
 * The Lean side of an article: always a dropdown right under its text,
 * closed by default. Opening it shows the declarations; linked phrases of
 * the text then light up their counterpart in it.
 */
function renderFormalisation(a, decls) {
  if (!decls.length) {
    const why = a.outsideFormalisation.length
      ? `Hors formalisation : ${escapeHtml(a.outsideFormalisation.join(" ; "))}.`
      : "Pas encore formalisé en Lean.";
    return `<p class="lean-none">${why}</p>`;
  }
  const groups = groupMembers(decls);
  const files = [...new Set(decls.map((d) => d.file.replace("lean/Prouvhommes/", "")))];
  const count = `${groups.length} ${groups.length > 1 ? "déclarations" : "déclaration"}`;
  return `<details class="lean-dropdown face-lean">
  <summary><span class="lean-dropdown-label">Formalisation Lean</span><span class="lean-dropdown-meta">${count} · ${files.map(escapeHtml).join(", ")}</span></summary>
  <div class="lean-dropdown-body">
    ${groups.map(renderDecl).join("\n")}
  </div>
</details>`;
}

/** A theorem's statement: its source up to the `:=` that opens the proof. */
function theoremStatement(decl) {
  const src = decl.source;
  const m = src.match(/\s:=(?=\s*(?:by\b|$))/m) ?? src.match(/\s:=/);
  return m ? `${src.slice(0, m.index).trimEnd()} := …` : src;
}

function renderGuarantees(a, law, standalone) {
  const h = standalone ? "h2" : "h4";
  const items = a.theorems.map((name) => {
    const decl = law.decls.get(name);
    const { tag, text } = splitSummary(promiseText(name, law));
    return `<li class="guarantee" data-theorem="${name}">
  <p class="guarantee-text">${text}</p>
  <p class="guarantee-meta">${statusBadge(proofStatus(name, law.decls))}${tag ? `<span class="promise-tag">${tag}</span>` : ""}${leanLink(name, decl)}</p>
  <p class="guarantee-check" data-check="${name}" aria-live="polite"></p>
  ${
    decl
      ? `<details class="lean-dropdown lean-statement">
    <summary><span class="lean-dropdown-label">Énoncé Lean</span></summary>
    <div class="lean-dropdown-body">
      <pre><code>${highlightLean(theoremStatement(decl))}</code></pre>
      <p class="lean-proof-link"><a href="${BLOB}/${decl.file}#L${decl.line}">Voir la démonstration dans ${escapeHtml(decl.file.replace("lean/", ""))}</a></p>
    </div>
  </details>`
      : ""
  }
</li>`;
  });
  return `<section class="guarantees" aria-label="Ce que l’article garantit">
<${h} class="guarantees-title">Ce que l’article garantit</${h}>
<ul>${items.join("\n")}</ul>
</section>`;
}

const leanLink = (name, decl) =>
  decl ? `<a href="${BLOB}/${decl.file}#L${decl.line}"><code>${name}</code></a>` : `<code>${name}</code>`;

/**
 * Consecutive fields or constructors of the same parent share one figure,
 * so `CauseFin.accordCommun` and `CauseFin.deces` read as one excerpt.
 */
function groupMembers(decls) {
  const groups = [];
  for (const d of decls) {
    const last = groups.at(-1);
    if (d.parent && last?.[0].parent?.name === d.parent.name) last.push(d);
    else groups.push([d]);
  }
  return groups;
}

/** One figure: a declaration, or members shown under their parent's header. */
function renderDecl(group) {
  const [first] = group;
  const withDoc = (d, indent) => (d.doc ? `${indent}/-- ${d.doc} -/\n` : "") + d.source;
  const src = first.parent
    ? `${first.parent.header}\n  -- …\n${group.map((d) => withDoc(d, "  ")).join("\n")}`
    : withDoc(first, "");
  return `<figure class="lean-decl">
<figcaption><a href="${BLOB}/${first.file}#L${first.line}">${first.file.replace("lean/", "")}:${first.line}</a></figcaption>
<pre><code>${highlightLean(src)}</code></pre>
</figure>`;
}

/* Promesses ----------------------------------------------------------------- */

/**
 * Every theorem cited by the text, once, in document order, with the
 * articles that cite it (a theorem can back several articles).
 */
export function allPromises(law) {
  const byName = new Map();
  for (const a of law.articles) {
    for (const name of a.theorems) {
      if (!byName.has(name)) byName.set(name, { name, articles: [], status: proofStatus(name, law.decls) });
      byName.get(name).articles.push(a);
    }
  }
  return [...byName.values()];
}

/** A list of promises as cards (home page, dashboard). */
export function renderPromiseCards(promises, law) {
  return `<ul class="promise-list">${promises
    .map(({ name, articles, status }) => {
      const { tag, text } = splitSummary(promiseText(name, law));
      const links = articles
        .map((a) => `<a class="promise-article" href="${articleUrl(a)}">Article ${a.number} · ${escapeHtml(a.title)}</a>`)
        .join("");
      return `<li class="promise-item">
  <p class="promise-text">${text}</p>
  <p class="promise-meta">${statusBadge(status)}${tag ? `<span class="promise-tag">${tag}</span>` : ""}${links}</p>
</li>`;
    })
    .join("\n")}</ul>`;
}

/** /promesses/: counters, then the promises of each part. */
export function renderDashboard(law) {
  const all = allPromises(law);
  const proved = all.filter((p) => p.status === "proved").length;
  const formalised = law.articles.filter((a) => a.lean.length || a.theorems.length).length;
  const outside = law.articles.filter((a) => a.outsideFormalisation.length).length;
  const pending = law.articles.length - formalised - outside;
  const stat = (value, label) => `<div class="stat"><dt>${label}</dt><dd>${value}</dd></div>`;
  return `<dl class="stats">
${stat(`${proved}<span class="stat-of"> / ${all.length}</span>`, "Promesses prouvées")}
${stat(`${formalised}<span class="stat-of"> / ${law.articles.length}</span>`, "Articles formalisés")}
${stat(outside, "Hors formalisation")}
${stat(pending, "Pas encore formalisés")}
</dl>
${parts(law)
  .map((p) => {
    // Listed under the first article that cites it.
    const promises = all.filter((x) => p.articles.includes(x.articles[0]));
    if (!promises.length) return "";
    return `<section class="dashboard-part" aria-labelledby="d-${slug(p.title)}">
<h2 class="part-title" id="d-${slug(p.title)}">${escapeHtml(p.title)}</h2>
${renderPromiseCards(promises, law)}
</section>`;
  })
  .join("\n")}`;
}

/* Méthode ------------------------------------------------------------------- */

/** The introduction of the text, as rendered sections. */
export function renderIntroduction(law) {
  return law.introduction
    .map(
      (s) => `<section class="method-section">
${s.title ? `<h2>${escapeHtml(s.title)}</h2>` : ""}
${latexToHtml(s.body, law)}
</section>`,
    )
    .join("\n");
}

/* LaTeX and Lean ---------------------------------------------------------- */

const LEAN_KEYWORDS = new Set(["def", "theorem", "lemma", "abbrev", "inductive", "structure", "opaque",
  "if", "then", "else", "fun", "match", "with", "by", "let", "have", "show", "where", "deriving"]);

const OPEN_NOTION_FIELDS = new Set(Object.values(OPEN_NOTIONS).map((n) => n.split(".").at(-1)));

/** Minimal Lean highlighting: comments, docstrings, keywords, open notions. */
export function highlightLean(src) {
  return src.replace(/(\/-[\s\S]*?-\/|--[^\n]*)|([A-Za-z_][\w']*)|([\s\S])/g, (m, comment, word) => {
    if (comment) return `<span class="lean-comment">${escapeHtml(comment)}</span>`;
    if (word && LEAN_KEYWORDS.has(word)) return `<span class="lean-kw">${word}</span>`;
    if (word && OPEN_NOTION_FIELDS.has(word)) return `<span class="open-notion">${word}</span>`;
    return escapeHtml(m);
  });
}

/** Converts plain LaTeX (an article without annotated copy, the introduction). */
export function latexToHtml(tex, law) {
  const tables = [];
  const cleaned = tex
    .replace(/\\(lean|theoreme|horsformalisation)\{[^}]*\}/g, "")
    .replace(/\\begin\{center\}[\s\S]*?\\end\{center\}/g, (block) => {
      tables.push(renderTable(block, law));
      return `\n\n@@table${tables.length - 1}@@\n\n`;
    })
    .trim();
  const paragraphs = cleaned
    .split(/\n\s*\n|(?=(?:^|\n)\s*[IVX]+\. ---)/)
    .map((p) => p.trim())
    .filter(Boolean);
  const LIST = { itemize: "ul", enumerate: "ol", description: "dl" };
  return paragraphs
    .map((p) => {
      const table = p.match(/^@@table(\d+)@@$/);
      if (table) return tables[Number(table[1])];
      let html = inlineLatex(p.replace(/\s+/g, " "), law);
      html = html
        .replace(/\s*\\begin\{(itemize|enumerate|description)\}\s*/g, (_, k) => `</p><${LIST[k]}>`)
        .replace(/\s*\\end\{(itemize|enumerate|description)\}\s*/g, (_, k) => `</${LIST[k]}><p>`)
        .replace(/\s*\\item\[([^\]]*)\]\s*/g, "<dt>$1</dt><dd>")
        .replace(/\s*\\item\s+/g, "<li>");
      html = markOpenNotions(html);
      const block = html.startsWith("<code") ? `<p class="math-block">${html}</p>` : `<p>${html}</p>`;
      return block.replace(/<p>\s*<\/p>/g, "");
    })
    .join("\n");
}

/**
 * Inline LaTeX of a paragraph or a table cell: escaping, typographic
 * apostrophes and dashes (as in the PDF), math, references, emphasis.
 */
function inlineLatex(tex, law) {
  return escapeHtml(tex)
    .replace(/^([IVX]+)\. ---\s*/, '<span class="para">$1. —</span> ')
    .replace(/\\\[([\s\S]*?)\\\]/g, (_, m) => `<code class="math-tex">${m.trim()}</code>`)
    .replace(/\$([^$]+)\$/g, (_, m) => `<var>${m.replace(/\\/g, "")}</var>`)
    .replace(/'/g, "’")
    .replace(/---/g, "—")
    .replace(/--/g, "–")
    .replace(/~/g, "&nbsp;")
    .replace(/\\%/g, "%")
    .replace(/\\ref\{([^}]+)\}/g, (_, label) => refLink(label, law))
    .replace(/\\textsc\{([^}]*)\}/g, '<span class="smallcaps">$1</span>')
    .replace(/\\(?:textmd|textsf)\{([^}]*)\}/g, "$1")
    .replace(/\\texttt\{([^}]*)\}/g, "<code>$1</code>")
    .replace(/\\(?:emph|textit)\{([^}]*)\}/g, "<em>$1</em>")
    .replace(/\\textbf\{([^}]*)\}/g, "<strong>$1</strong>");
}

/**
 * A `center` + `tabular` block of the text (indicative values, the table of
 * numeric provisions). A leading `\multicolumn` row is the caption; the
 * first row after it is the header; the first column labels each row.
 */
function renderTable(block, law) {
  const body = block.match(/\\begin\{tabular\}\{[^}]*\}([\s\S]*?)\\end\{tabular\}/)?.[1];
  if (!body) return "";
  const rows = body
    .replace(/\\hline/g, "")
    .split(/\\\\(?:\[[^\]]*\])?/)
    .map((r) => r.trim())
    .filter(Boolean)
    .map((r) => r.split(/(?<!\\)&/).map((c) => c.trim()));
  let caption = "";
  const first = rows[0]?.[0].match(/^\\multicolumn\{\d+\}\{\w+\}\{([\s\S]*)\}$/);
  if (first && rows[0].length === 1) {
    caption = inlineLatex(first[1], law);
    rows.shift();
  }
  const [head, ...rest] = rows;
  const cell = (c) => (c === "---" ? "—" : inlineLatex(c, law));
  return `<div class="table-wrap law-table-wrap"><table class="values law-table">
${caption ? `<caption>${caption}</caption>` : ""}
<thead><tr>${head.map((c) => `<th scope="col">${cell(c)}</th>`).join("")}</tr></thead>
<tbody>${rest
    .map((r) => `<tr>${r.map((c, i) => (i === 0 ? `<th scope="row">${cell(c)}</th>` : `<td>${cell(c)}</td>`)).join("")}</tr>`)
    .join("\n")}</tbody>
</table></div>`;
}

/** The tables of an article's LaTeX, for an annotated copy (which has none). */
export function latexTables(tex, law) {
  return [...tex.matchAll(/\\begin\{center\}[\s\S]*?\\end\{center\}/g)].map((m) => renderTable(m[0], law)).join("\n");
}

/** Fingerprint of an article's LaTeX, whitespace-insensitive. */
export const sourceHash = (tex) =>
  createHash("sha256").update(tex.replace(/\s+/g, " ").trim()).digest("hex").slice(0, 12);

/** Draws each open notion (M2) as a hole, linked to its Lean predicate. */
function markOpenNotions(html) {
  for (const [phrase, lean] of Object.entries(OPEN_NOTIONS)) {
    html = html.replace(
      new RegExp(`(?<![\\p{L}])${phrase}(?![\\p{L}])`, "gu"),
      `<span class="open-notion" title="Notion ouverte, appréciée par le juge (${lean})">${phrase}</span>`,
    );
  }
  return html;
}

function resolveRefs(html, law) {
  return html.replace(/\{\{ref:([^}]+)\}\}/g, (_, label) => refLink(label, law));
}

function refLink(label, law) {
  const target = law.articles.find((a) => a.label === label);
  return target ? `<a href="${articleUrl(target)}">${target.number}</a>` : "?";
}

function promiseText(name, law) {
  const pinned = law.showcase.find((e) => e.name === name)?.summary;
  if (pinned) return pinned;
  const doc = law.decls.get(name)?.doc;
  return doc ? doc.split(/(?<=\.)\s/)[0] : name;
}

/** "T-PLAFOND : l'indemnité…" → tag + capitalised sentence, `code` kept. */
function splitSummary(summary) {
  const m = summary.match(/^\**(T-[A-Z]+)\**\s*[.:]\s*([\s\S]*)$/);
  const raw = (m ? m[2] : summary).replace(/\*\*/g, "").replace(/'/g, "’").trim();
  const text = escapeHtml(raw.charAt(0).toUpperCase() + raw.slice(1)).replace(/`([^`]+)`/g, "<code>$1</code>");
  return { tag: m ? m[1] : null, text };
}

const statusBadge = (status) => `<span class="status" data-status="${status}">${STATUS[status]}</span>`;

export const slug = (s) =>
  s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
