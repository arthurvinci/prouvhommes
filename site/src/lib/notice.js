// The notice period (P3, P4), as in lean/Prouvhommes/Preavis.lean. Days are
// small natural numbers, so plain integer arithmetic is exact here; `sub`
// mirrors Lean's truncated subtraction on ℕ and `div` its floor division.

const sub = (a, b) => Math.max(0, a - b);
const div = (a, b) => Math.floor(a / b);

/**
 * Notice in days for a notification received at seniority `j` (days):
 * ⌊min(7 + 23j/30, 30 + 6(j − 30)/67, 60 + 3(j − 365)/292, 90)⌋.
 */
export function notice(j) {
  return Math.min(
    Math.min(7 + div(23 * j, 30), 30 + div(6 * sub(j, 30), 67)),
    Math.min(60 + div(3 * sub(j, 365), 292), 90),
  );
}

/** Last day of the contract when the notification is received on day `j`. */
export const lastDay = (j) => j + notice(j);

/** The points the curve goes through: [seniority, notice] in days. */
export const NOTICE_POINTS = [
  [0, 7],
  [30, 30],
  [365, 60],
  [3285, 90],
];

/** Completed months at day `j`, as in Lean's `moisRevolus`. */
export const completedMonths = (j) => div(12 * j, 365);

/**
 * Current French law, dismissal by the employer (article L1234-1): no legal
 * notice before 6 months of seniority, one month up to 2 years, two months
 * after. A month is counted here as 30 days.
 */
export function currentLawNotice(j) {
  const m = completedMonths(j);
  if (m < 6) return 0;
  return m < 24 ? 30 : 60;
}
