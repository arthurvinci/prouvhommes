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
 *   doc: string | null, source: string }} LeanDecl
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
        part = t[1].replace(/\s*---\s*/g, " — ");
        return;
      }
      const end = i + 1 < tokens.length ? tokens[i + 1].index : src.length;
      const body = src.slice(t.index + t[0].length, end);
      const label = t[4] ?? null;
      const number = articles.length + 1;
      articles.push({
        number,
        title: t[3],
        level: t[2] || null,
        label,
        id: label ? label.replace(/[^\w-]/g, "-") : `article-${number}`,
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

/** Indexes every top-level declaration of lean/Prouvhommes/*.lean by name. */
export function readLeanDecls(leanDir) {
  const dir = join(leanDir, "Prouvhommes");
  /** @type {Map<string, LeanDecl>} */
  const decls = new Map();
  for (const file of readdirSync(dir).filter((f) => f.endsWith(".lean"))) {
    const lines = readFileSync(join(dir, file), "utf8").split("\n");
    lines.forEach((line, i) => {
      const m = line.match(/^(?:@\[[^\]]*\]\s*)?(?:noncomputable\s+)?(theorem|lemma|def|abbrev|inductive|structure|opaque)\s+([^\s:({]+)/);
      if (!m) return;
      let end = i + 1;
      while (end < lines.length && !/^\S/.test(lines[end]) && !(lines[end] === "" && /^\S/.test(lines[end + 1] ?? "x"))) end++;
      decls.set(m[2], {
        name: m[2],
        kind: m[1],
        file: `lean/Prouvhommes/${file}`,
        line: i + 1,
        doc: docBefore(lines, i),
        source: lines.slice(i, end).join("\n").trimEnd(),
      });
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

/** "proved" (pinned in Vitrine), "stated" (exists in Lean) or "missing". */
export function proofStatus(name, decls, showcase) {
  if (showcase.some((e) => e.name === name)) return "proved";
  return decls.has(name) ? "stated" : "missing";
}

export function readLaw(repoRoot) {
  const articles = readArticles(join(repoRoot, "texte"));
  const decls = readLeanDecls(join(repoRoot, "lean"));
  const showcase = readShowcase(join(repoRoot, "lean"));
  return { articles, decls, showcase };
}

function stripComments(tex) {
  return tex.replace(/(^|[^\\])%.*$/gm, "$1");
}

function macroArgs(tex, name) {
  return [...tex.matchAll(new RegExp(`\\\\${name}\\{([^}]*)\\}`, "g"))].map((m) => m[1]);
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
