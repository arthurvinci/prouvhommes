// Display helpers. Amounts are formatted from BigInt cents and exact
// rationals directly, so no float ever reaches a displayed amount.

import { toFixed } from "./rational.js";

const NNBSP = " "; // French thousands separator

function groupThousands(digits) {
  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, NNBSP);
}

/** 900000n → "9 000,00 €" */
export function euros(cents) {
  const neg = cents < 0n;
  const abs = neg ? -cents : cents;
  const units = groupThousands((abs / 100n).toString());
  const rest = (abs % 100n).toString().padStart(2, "0");
  return `${neg ? "−" : ""}${units},${rest}${NNBSP}€`;
}

/** Rational cents → euros string with cents, rounded half-up (display only). */
export function eurosOfRational(r) {
  const s = toFixed(r, 0);
  return euros(BigInt(s));
}

/** Rational → "3" or "5,06" (French decimal comma). */
export function decimal(r, digits = 2) {
  const s = toFixed(r, digits).replace(/\.?0+$/, "") || "0";
  const [int, frac] = s.split(".");
  return groupThousands(int) + (frac ? `,${frac}` : "");
}

/** Exact rational as a fraction: "81/16" or "3". */
export const fraction = (r) => (r.d === 1n ? r.n.toString() : `${r.n}/${r.d}`);

/** 123 → "10 ans et 3 mois" */
export function seniority(months) {
  const y = Math.floor(months / 12);
  const m = months % 12;
  const years = y === 0 ? "" : `${y} an${y > 1 ? "s" : ""}`;
  const rest = m === 0 ? "" : `${m} mois`;
  return [years, rest].filter(Boolean).join(" et ") || "0 mois";
}

/** "3000" or "3 000,50" typed by a user → cents, or null. */
export function parseEuros(text) {
  const clean = String(text).replace(/[\s  €]/g, "").replace(",", ".");
  const m = clean.match(/^(\d+)(?:\.(\d{1,2}))?$/);
  if (!m) return null;
  return BigInt(m[1]) * 100n + BigInt((m[2] ?? "").padEnd(2, "0"));
}
