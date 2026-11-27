// Renders the law into static HTML at build time, so the reader works
// without JavaScript; src/ only adds interactivity on top.

import { createHash } from "node:crypto";
import { ENRICHED, OPEN_NOTIONS } from "./enriched.js";
import { proofStatus } from "./extract.js";

const REPO = "https://github.com/arthurvinci/prouvhommes/blob/main";

const LEVELS = {
  absolue: ["absolue", "non dérogeable"],
  relative: ["relative", "dérogeable seulement en faveur du salarié"],
  dispositive: ["dispositive", "librement dérogeable"],
};

const STATUS = {
  proved: "Prouvé en Lean",
  stated: "Énoncé en Lean, preuve non épinglée",
  missing: "Absent de la formalisation",
};

export const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

/** Page sections: one per part ("Titre I — …"), each with its articles. */
export function renderArticles(law, warn = console.warn) {
  const parts = [];
  for (const a of law.articles) {
    if (parts.at(-1)?.title !== a.part) parts.push({ title: a.part, articles: [] });
    parts.at(-1).articles.push(a);
  }
  return parts
    .map(
      (p) => `<section class="law-part" aria-labelledby="${slug(p.title)}">
<h2 class="part-title" id="${slug(p.title)}">${escapeHtml(p.title)}</h2>
${p.articles.map((a) => renderArticle(a, law, warn)).join("\n")}
</section>`,
    )
    .join("\n");
}

/** Table of contents for the reader. */
export function renderToc(law) {
  return `<ol class="toc">${law.articles
    .map((a) => `<li><a href="#${a.id}"><span class="toc-number">${a.number}</span> ${escapeHtml(a.title)}</a></li>`)
    .join("")}</ol>`;
}

/** Home page: every pinned theorem, as a plain-language promise. */
export function renderPromises(law) {
  const items = law.showcase.map((entry) => {
    const article = law.articles.find((a) => a.theorems.includes(entry.name));
    const { tag, text } = splitSummary(promiseText(entry.name, law));
    const where = article
      ? `<a class="promise-article" href="/code/#${article.id}">Article ${article.number} · ${escapeHtml(article.title)}</a>`
      : "";
    return `<li class="promise-item">
  <p class="promise-text">${text}</p>
  <p class="promise-meta">${statusBadge("proved")}${tag ? `<span class="promise-tag">${tag}</span>` : ""}${where}</p>
</li>`;
  });
  return `<ul class="promise-list">${items.join("\n")}</ul>`;
}

function renderArticle(a, law, warn) {
  const enriched = a.label ? ENRICHED[a.label] : undefined;
  if (enriched && enriched.sourceHash !== sourceHash(a.body)) {
    warn(
      `[law] ${a.label}: the LaTeX changed since site/law/enriched.js was annotated. ` +
        `Update the annotated copy, then set sourceHash to "${sourceHash(a.body)}".`,
    );
  }
  const body = enriched ? resolveRefs(enriched.body, law) : latexToHtml(a.body, law);
  const declNames = enriched?.leanDecls ?? a.lean;
  const decls = declNames.map((n) => law.decls.get(n)).filter(Boolean);
  const level = LEVELS[a.level];

  return `<article class="law-article" id="${a.id}"${a.label ? ` data-label="${a.label}"` : ""}${
    enriched ? ` data-links="${escapeHtml(JSON.stringify(enriched.links))}"` : ""
  }>
<header class="article-head">
  <span class="article-number" aria-hidden="true">${a.number}</span>
  <div>
    <h3 class="article-title"><span class="visually-hidden">Article ${a.number} : </span>${escapeHtml(a.title)}</h3>
    ${level ? `<p class="level" data-level="${a.level}"><span class="level-mark" aria-hidden="true"></span>Impérativité ${level[0]} : ${level[1]}</p>` : ""}
  </div>
</header>
<div class="faces">
  <div class="face-switch" role="group" aria-label="Face affichée">
    <button type="button" data-face="law" aria-pressed="true">Droit</button>
    <button type="button" data-face="lean" aria-pressed="false">Lean</button>
  </div>
  <section class="face face-law" data-face="law" aria-label="Texte de l'article">
    ${body}
  </section>
  <section class="face face-lean" data-face="lean" aria-label="Formalisation en Lean">
    ${decls.length ? groupMembers(decls).map(renderDecl).join("\n") : `<p class="empty">${a.outsideFormalisation.length ? "Hors formalisation." : "Pas encore formalisé."}</p>`}
  </section>
</div>
${a.theorems.length ? renderGuarantees(a, law) : ""}
${enriched?.extra ? `<div class="article-extra" data-extra="${enriched.extra}"></div>` : ""}
</article>`;
}

function renderGuarantees(a, law) {
  const items = a.theorems.map((name) => {
    const status = proofStatus(name, law.decls, law.showcase);
    const decl = law.decls.get(name);
    const { tag, text } = splitSummary(promiseText(name, law));
    return `<li class="guarantee" data-theorem="${name}">
  <p class="guarantee-text">${text}</p>
  <p class="guarantee-meta">${statusBadge(status)}${tag ? `<span class="promise-tag">${tag}</span>` : ""}${
      decl ? `<a href="${REPO}/${decl.file}#L${decl.line}"><code>${name}</code></a>` : `<code>${name}</code>`
    }</p>
  <p class="guarantee-check" data-check="${name}" aria-live="polite"></p>
</li>`;
  });
  return `<section class="guarantees" aria-label="Ce que l'article garantit">
<h4>Ce que l'article garantit</h4>
<ul>${items.join("\n")}</ul>
</section>`;
}

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
<figcaption><a href="${REPO}/${first.file}#L${first.line}">${first.file.replace("lean/", "")}:${first.line}</a></figcaption>
<pre><code>${highlightLean(src)}</code></pre>
</figure>`;
}

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

/** Converts the plain LaTeX of an article (no enriched copy) to HTML. */
export function latexToHtml(tex, law) {
  const cleaned = tex
    .replace(/\\(lean|theoreme|horsformalisation)\{[^}]*\}/g, "")
    .replace(/\\begin\{center\}[\s\S]*?\\end\{center\}/g, "")
    .trim();
  const paragraphs = cleaned
    .split(/\n\s*\n|(?=(?:^|\n)\s*[IVX]+\. ---)/)
    .map((p) => p.trim())
    .filter(Boolean);
  return paragraphs
    .map((p) => {
      let html = escapeHtml(p.replace(/\s+/g, " "));
      html = html
        .replace(/^([IVX]+)\. ---\s*/, '<span class="para">$1. —</span> ')
        .replace(/\\\[([\s\S]*?)\\\]/g, (_, m) => `<code class="math-tex">${m.trim()}</code>`)
        .replace(/\$([^$]+)\$/g, (_, m) => `<var>${m.replace(/\\/g, "")}</var>`)
        .replace(/---/g, "—")
        .replace(/--/g, "–")
        .replace(/~/g, "&nbsp;")
        .replace(/\\ref\{([^}]+)\}/g, (_, label) => refLink(label, law))
        .replace(/\\(?:emph|textit)\{([^}]*)\}/g, "<em>$1</em>")
        .replace(/\\textbf\{([^}]*)\}/g, "<strong>$1</strong>")
        .replace(/\s*\\begin\{(itemize|enumerate)\}\s*/g, (_, k) => `</p><${k === "itemize" ? "ul" : "ol"}>`)
        .replace(/\s*\\end\{(itemize|enumerate)\}\s*/g, (_, k) => `</${k === "itemize" ? "ul" : "ol"}><p>`)
        .replace(/\s*\\item\s+/g, "<li>");
      html = markOpenNotions(html);
      const block = html.startsWith("<code") ? `<p class="math-block">${html}</p>` : `<p>${html}</p>`;
      return block.replace(/<p>\s*<\/p>/g, "");
    })
    .join("\n");
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
  return target ? `<a href="#${target.id}">${target.number}</a>` : "?";
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
  const raw = (m ? m[2] : summary).replace(/\*\*/g, "").trim();
  const text = escapeHtml(raw.charAt(0).toUpperCase() + raw.slice(1)).replace(/`([^`]+)`/g, "<code>$1</code>");
  return { tag: m ? m[1] : null, text };
}

const statusBadge = (status) => `<span class="status" data-status="${status}">${STATUS[status]}</span>`;

const slug = (s) =>
  s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
