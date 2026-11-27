// The site must say what the text and the formalisation say. These tests
// read the real texte/ and lean/ folders and fail when a change on either
// side leaves the site behind.
import { describe, expect, test } from "vitest";
import { fileURLToPath } from "node:url";
import { readLaw } from "./extract.js";
import { ENRICHED, OPEN_NOTIONS } from "./enriched.js";
import { buildPages } from "./pages.js";
import { SIMULATORS } from "./simulators.js";
import { LAW_PARAMS } from "../src/lib/p6.js";
import { checkedTheorems } from "../src/lib/promises.js";
import { eq, q } from "../src/lib/rational.js";

const repoRoot = fileURLToPath(new URL("../..", import.meta.url));
const law = readLaw(repoRoot);

/** Right-hand side of a Lean `def name : T := value`, as a rational. */
function leanValue(name) {
  const source = law.decls.get(name)?.source;
  const m = source?.match(/:=\s*(\d+)(?:\s*\/\s*(\d+))?\s*$/);
  if (!m) throw new Error(`No numeric value for ${name}: ${source}`);
  return q(m[1], m[2] ?? 1);
}

describe("site ↔ Lean", () => {
  // The live thresholds start from these values; the Lean theorems are
  // proved for the Lean ones.
  test("the law's thresholds equal the Lean constants", () => {
    expect(eq(LAW_PARAMS.capMonths, leanValue("plafondMois"))).toBe(true);
    expect(eq(q(LAW_PARAMS.saturationMonths), leanValue("ancienneteSaturation"))).toBe(true);
    expect(eq(LAW_PARAMS.alpha, leanValue("alphaSR"))).toBe(true);
  });

  test("every theorem with a live check exists in Lean", () => {
    expect(checkedTheorems().filter((n) => !law.decls.has(n))).toEqual([]);
  });

  test("every open notion is a Lean predicate", () => {
    for (const lean of Object.values(OPEN_NOTIONS)) expect(law.decls.has(lean), lean).toBe(true);
  });

  for (const [label, entry] of Object.entries(ENRICHED)) {
    describe(`annotated ${label}`, () => {
      const sources = entry.leanDecls.map((n) => law.decls.get(n)?.source ?? "");

      test("shows Lean declarations that exist", () => {
        expect(entry.leanDecls.filter((n) => !law.decls.has(n))).toEqual([]);
      });

      // A link with no match on the Lean side would light up only one face.
      test("each link finds its Lean counterpart", () => {
        for (const [key, pattern] of Object.entries(entry.links)) {
          const re = new RegExp(pattern, "u");
          expect(sources.some((s) => re.test(s)), `${key}: /${pattern}/`).toBe(true);
        }
      });

      test("each link is used in the text, and only declared links are", () => {
        const used = new Set([...entry.body.matchAll(/data-link="([^"]+)"/g)].map((m) => m[1]));
        expect([...used].sort()).toEqual(Object.keys(entry.links).sort());
      });
    });
  }
});

describe("site ↔ text", () => {
  const pages = buildPages(law, () => {});

  test("every article has its page, in the text's order and numbering", () => {
    for (const a of law.articles) {
      const html = pages.get(`/code/${a.slug}/`);
      expect(html, a.slug).toBeDefined();
      expect(html).toContain(`<span class="article-number" aria-hidden="true">${a.number}</span>`);
    }
  });

  test("tables of the text are rendered, not dropped", () => {
    for (const a of law.articles.filter((x) => x.body.includes("\\begin{tabular}"))) {
      expect(pages.get(`/code/${a.slug}/`), a.slug).toContain('class="values law-table"');
    }
  });

  test("no raw LaTeX reaches a page", () => {
    for (const [route, html] of pages) {
      const visible = html.replace(/<script[\s\S]*?<\/script>|data-links="[^"]*"/g, "");
      expect(visible.match(/\\[a-zA-Z]{2,}/g), route).toBeNull();
    }
  });

  test("every simulator belongs to an article of the text", () => {
    for (const s of SIMULATORS) expect(law.articles.some((a) => a.label === s.article), s.slug).toBe(true);
  });
});
