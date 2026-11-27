// Build-time extraction of the law (texte/) and its formalisation (lean/).
// The site never copies article metadata by hand: numbers, titles,
// imperativeness levels, Lean references and proof status all come from here.

import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

/**
 * @typedef {{ number: number, title: string, level: string | null,
 *   label: string | null, id: string, part: string, body: string,
 *   lean: string[], theorems: string[], outsideFormalisation: string[] }} Article
 * @typedef {{ name: string, kind: string, file: string, line: number,
 *   doc: string | null, source: string,
 *   parent: { name: string, kind: string, header: string } | null }} LeanDecl
 * @typedef {{ name: string, summary: string | null }} ShowcaseEntry
 */

/** Reads the articles of texte/main.tex, in document order. */
export function readArticles(textDir) {
  const main = readFileSync(join(textDir, "main.tex"), "utf8");
  const inputs = [...stripComments(main).matchAll(/\\input\{([^}]+)\}/g)].map((m) => m[1]);
  const articles = [];
  for (const input of inputs) {
    const src = stripComments(readFileSync(join(textDir, `${input}.tex`), "utf8"));
    const tokens = [...src.matchAll(/\\section\{([^}]*)\}|\\article(?:\[(\w*)\])?\{([^}]*)\}(?:\s*\\label\{([^}]*)\})?/g)];
    let part = "";
    tokens.forEach((t, i) => {
      if (t[1] !== undefined) {
        part = t[1].replace(/\s*---\s*/g, " — ").replace(/'/g, "’");
        return;
      }
      const end = i + 1 < tokens.length ? tokens[i + 1].index : src.length;
      const body = src.slice(t.index + t[0].length, end);
      const label = t[4] ?? null;
      const number = articles.length + 1;
      articles.push({
        number,
        // Typographic apostrophe, as in the PDF.
        title: t[3].replace(/'/g, "’"),
        level: t[2] || null,
        label,
        id: label ? label.replace(/[^\w-]/g, "-") : `article-${number}`,
        // Page address: from the label, so it survives renumbering.
        slug: label ? label.replace(/^art:/, "") : slugify(t[3]),
        part,
        body: body.trim(),
        lean: macroArgs(body, "lean"),
        theorems: macroArgs(body, "theoreme"),
        outsideFormalisation: macroArgs(body, "horsformalisation"),
      });
    });
  }
  return articles;
}

/**
 * Indexes every top-level declaration of lean/Prouvhommes/*.lean by name,
 * plus structure fields and inductive constructors under their dotted name
 * (`Contrat.dureeEssai`, `CauseFin.deces`).
 */
export function readLeanDecls(leanDir) {
  const dir = join(leanDir, "Prouvhommes");
  /** @type {Map<string, LeanDecl>} */
  const decls = new Map();
  for (const file of readdirSync(dir).filter((f) => f.endsWith(".lean"))) {
    const lines = readFileSync(join(dir, file), "utf8").split("\n");
    const path = `lean/Prouvhommes/${file}`;
    // Names are given without the root `Prouvhommes.` namespace, as in the text.
    const namespaces = [];
    lines.forEach((line, i) => {
      const ns = line.match(/^namespace\s+(\S+)/);
      if (ns) return void namespaces.push(ns[1]);
      const end = line.match(/^end\s+(\S+)/);
      if (end && namespaces.at(-1) === end[1]) return void namespaces.pop();

      const m = line.match(/^(?:@\[[^\]]*\]\s*)?(?:noncomputable\s+)?(theorem|lemma|def|abbrev|inductive|structure|class|opaque)\s+([^\s:({]+)/);
      if (!m) return;
      let stop = i + 1;
      while (stop < lines.length && !/^\S/.test(lines[stop]) && !(lines[stop] === "" && /^\S/.test(lines[stop + 1] ?? "x"))) stop++;
      const prefix = namespaces.filter((n) => n !== "Prouvhommes").join(".");
      const decl = {
        name: prefix ? `${prefix}.${m[2]}` : m[2],
        kind: m[1],
        file: path,
        line: i + 1,
        doc: docBefore(lines, i),
        source: lines.slice(i, stop).join("\n").trimEnd(),
        parent: null,
      };
      decls.set(decl.name, decl);
      if (decl.kind === "structure" || decl.kind === "class" || decl.kind === "inductive") {
        for (const member of readMembers(lines, i, stop, decl)) decls.set(member.name, member);
      }
    });
  }
  return decls;
}

/**
 * Theorems pinned in Vitrine.lean. `#print axioms` is frozen by `#guard_msgs`
 * there, so CI fails if any of them depends on `sorry`.
 * @returns {ShowcaseEntry[]}
 */
export function readShowcase(leanDir) {
  const src = readFileSync(join(leanDir, "Prouvhommes", "Vitrine.lean"), "utf8");
  const entries = [];
  let summary = null;
  for (const m of src.matchAll(/\/-!\s*([\s\S]*?)-\/|#print axioms\s+(\S+)/g)) {
    if (m[1] !== undefined) {
      const text = m[1].trim();
      // Section headings ("## …") reset the summary; plain notes become it.
      summary = text.startsWith("#") ? null : text;
    } else {
      entries.push({ name: m[2], summary });
      summary = null;
    }
  }
  return entries;
}

/**
 * "proved" or "missing". CI rejects any `sorry` or `admit` in lean/
 * (scripts/check-sorry.sh), so a theorem present in Lean is proved; the
 * showcase (Vitrine.lean) additionally pins its axioms.
 */
export const proofStatus = (name, decls) => (decls.has(name) ? "proved" : "missing");

/**
 * The introduction of texte/main.tex (no normative value), as sections:
 * [{ title, body }], the first one untitled.
 */
export function readIntroduction(textDir) {
  const main = stripComments(readFileSync(join(textDir, "main.tex"), "utf8"));
  const start = main.indexOf("\\section*{Introduction}");
  if (start < 0) return [];
  const end = main.indexOf("\\input{", start);
  const body = main
    .slice(start + "\\section*{Introduction}".length, end < 0 ? undefined : end)
    .replace(/\\addcontentsline\{[^}]*\}\{[^}]*\}\{[^}]*\}/g, "");
  return body.split(/\\subsection\*\{([^}]*)\}/).reduce((sections, chunk, i) => {
    if (i === 0) sections.push({ title: null, body: chunk.trim() });
    else if (i % 2 === 1) sections.push({ title: chunk, body: "" });
    else sections.at(-1).body = chunk.trim();
    return sections;
  }, []);
}

export function readLaw(repoRoot) {
  const articles = readArticles(join(repoRoot, "texte"));
  const decls = readLeanDecls(join(repoRoot, "lean"));
  const showcase = readShowcase(join(repoRoot, "lean"));
  const introduction = readIntroduction(join(repoRoot, "texte"));
  return { articles, decls, showcase, introduction };
}

export const slugify = (s) =>
  s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

function stripComments(tex) {
  return tex.replace(/(^|[^\\])%.*$/gm, "$1");
}

function macroArgs(tex, name) {
  return [...tex.matchAll(new RegExp(`\\\\${name}\\{([^}]*)\\}`, "g"))].map((m) => m[1]);
}

/**
 * Fields of a structure and constructors of an inductive: the lines indented
 * one level inside the declaration (lines i..end). A member's source is its
 * own line plus any more deeply indented continuation lines.
 */
function readMembers(lines, i, end, parent) {
  const pattern =
    parent.kind === "inductive" ? /^ {2}\|\s*([A-Za-z_][\w']*)/ : /^ {2}([A-Za-z_][\w']*)\s*:(?!=)/;
  const members = [];
  for (let j = i + 1; j < end; j++) {
    const m = lines[j].match(pattern);
    if (!m) continue;
    let stop = j + 1;
    while (stop < end && /^ {3,}\S/.test(lines[stop])) stop++;
    members.push({
      name: `${parent.name}.${m[1]}`,
      kind: parent.kind === "inductive" ? "constructor" : "field",
      file: parent.file,
      line: j + 1,
      doc: docBefore(lines, j),
      source: lines.slice(j, stop).join("\n").trimEnd(),
      parent: { name: parent.name, kind: parent.kind, header: lines[i].trimEnd() },
    });
  }
  return members;
}

function docBefore(lines, i) {
  let j = i - 1;
  while (j >= 0 && /^@\[/.test(lines[j])) j--;
  if (j < 0 || !lines[j].trimEnd().endsWith("-/")) return null;
  let k = j;
  while (k >= 0 && !lines[k].includes("/--")) k--;
  if (k < 0) return null;
  return lines
    .slice(k, j + 1)
    .join("\n")
    .replace(/^\s*\/--\s?/, "")
    .replace(/\s*-\/\s*$/, "")
    .trim();
}
