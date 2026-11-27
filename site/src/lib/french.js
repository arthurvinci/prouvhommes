// French number words, so a live threshold reads like the law's own text
// ("les soixante derniers mois", "un vingt-quatrième").

const UNITS = ["zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
  "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize"];
const TENS = { 2: "vingt", 3: "trente", 4: "quarante", 5: "cinquante", 6: "soixante" };

/** Cardinal, 0 to 99 (1990 spelling: hyphens everywhere). */
export function cardinal(n) {
  if (!Number.isInteger(n) || n < 0 || n > 99) return String(n);
  if (n <= 16) return UNITS[n];
  if (n < 20) return `dix-${UNITS[n - 10]}`;
  const t = Math.floor(n / 10);
  const u = n % 10;
  if (t === 7 || t === 9) {
    const base = t === 7 ? "soixante" : "quatre-vingt";
    return `${base}-${u === 1 && t === 7 ? "et-onze" : cardinal(10 + u)}`;
  }
  if (t === 8) return u === 0 ? "quatre-vingts" : `quatre-vingt-${cardinal(u)}`;
  if (u === 0) return TENS[t];
  return `${TENS[t]}-${u === 1 ? "et-un" : UNITS[u]}`;
}

/** Ordinal used for fractions: 24 → "vingt-quatrième". */
export function ordinal(n) {
  if (n === 2) return "demi";
  if (n === 3) return "tiers";
  if (n === 4) return "quart";
  let w = cardinal(n);
  if (w.endsWith("cinq")) return `${w}uième`;
  if (w.endsWith("neuf")) return `${w.slice(0, -1)}vième`;
  if (w.endsWith("quatre-vingts")) w = w.slice(0, -1);
  return `${w.replace(/e$/, "")}ième`;
}

/** Plural of a fraction word: "vingt-quatrièmes", "tiers", "quarts". */
export const ordinalPlural = (n) => (n === 3 ? "tiers" : `${ordinal(n)}s`);
