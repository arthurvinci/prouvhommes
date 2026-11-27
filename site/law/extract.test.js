// Runs against the real texte/ and lean/ folders: if the law's structure
// changes in a way the site can't read, this fails before the build does.
import { describe, expect, test } from "vitest";
import { fileURLToPath } from "node:url";
import { proofStatus, readLaw } from "./extract.js";

const repoRoot = fileURLToPath(new URL("../..", import.meta.url));
const { articles, decls, showcase } = readLaw(repoRoot);

describe("law extraction", () => {
  test("articles are numbered in document order", () => {
    expect(articles.length).toBeGreaterThan(0);
    articles.forEach((a, i) => expect(a.number).toBe(i + 1));
  });

  test("the severance article is found with its references", () => {
    const art = articles.find((a) => a.label === "art:indemnite");
    expect(art).toBeDefined();
    expect(art.level).toBe("relative");
    expect(art.lean).toContain("indemniteRupture");
    expect(art.theorems).toContain("indemniteRupture_le_plafond");
  });

  test("every Lean name cited by the text exists in Lean", () => {
    const missing = articles
      .flatMap((a) => [...a.lean, ...a.theorems])
      .filter((name) => proofStatus(name, decls, showcase) === "missing");
    expect(missing).toEqual([]);
  });

  test("declarations keep their source and docstring", () => {
    const d = decls.get("coefficient");
    expect(d.kind).toBe("def");
    expect(d.source).toMatch(/^def coefficient .*plafondMois \* smoothstep/s);
    expect(d.doc).toMatch(/Coefficient/);
  });

  test("showcase theorems are proved and carry a summary", () => {
    const plafond = showcase.find((e) => e.name === "indemniteRupture_le_plafond");
    expect(plafond.summary).toMatch(/T-PLAFOND/);
    expect(proofStatus("indemniteRupture_le_plafond", decls, showcase)).toBe("proved");
  });
});
