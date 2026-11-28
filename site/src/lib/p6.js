// Severance pay (P6), mirroring lean/Prouvhommes/{Smoothstep,SalaireReference,
// Indemnite}.lean definition by definition. Lean names are given in comments.
// Amounts are BigInt cents; every intermediate value is an exact rational, with
// a single final floor (charter rule M5).
//
// The thresholds are parameters so the site can show "what if" variants. The
// Lean theorems are proved for LAW_PARAMS only.

import { q, ONE, ZERO, add, sub, mul, div, pow, min, natFloor } from "./rational.js";

export const LAW_PARAMS = Object.freeze({
  capMonths: q(6), // plafondMois
  saturationMonths: 240, // ancienneteSaturation
  alpha: q(1, 24), // alphaSR
});

/** smoothstep: S(t) = 3t² − 2t³ */
export const smoothstep = (t) => sub(mul(q(3), pow(t, 2)), mul(q(2), pow(t, 3)));

/** pasEMA: e ↦ α·x + (1 − α)·e */
const emaStep = (alpha, e, x) => add(mul(alpha, x), mul(sub(ONE, alpha), e));

/** sommeExp: exponential sum starting from 0. */
export const expSum = (alpha, values) => values.reduce((e, x) => emaStep(alpha, e, x), ZERO);

/**
 * MoisTravaille: a month of the history, { salary: BigInt cents, activity:
 * rational in [0, 1] }. A bare BigInt is a full month (activity 1) paid that
 * amount (MoisTravaille.plein).
 */
export const fullMonth = (salary) => ({ salary: BigInt(salary), activity: ONE });
/** MoisTravaille.suspendu: no activity, no salary. */
export const SUSPENDED = Object.freeze({ salary: 0n, activity: ZERO });
const asMonth = (m) => (typeof m === "bigint" ? fullMonth(m) : m);

/** masseSalaires */
export const salaryMass = (history, params = LAW_PARAMS) =>
  expSum(params.alpha, history.map((m) => q(asMonth(m).salary)));

/** masseActivite */
export const activityMass = (history, params = LAW_PARAMS) =>
  expSum(params.alpha, history.map((m) => asMonth(m).activity));

/** salaireReference: salary mass / activity mass (0 without any activity). */
export function referenceSalary(history, params = LAW_PARAMS) {
  const b = activityMass(history, params);
  return b.n === 0n ? ZERO : div(salaryMass(history, params), b);
}

/** fractionAnciennete: min(m, saturation) / saturation, in [0, 1]. */
export const seniorityFraction = (months, params = LAW_PARAMS) =>
  q(Math.min(months, params.saturationMonths), params.saturationMonths);

/** coefficient: cap × S(fraction), in months of reference salary. */
export const coefficient = (months, params = LAW_PARAMS) =>
  mul(params.capMonths, smoothstep(seniorityFraction(months, params)));

/** indemniteQ: exact amount before rounding, in cents. */
export const severanceExact = (sr, months, params = LAW_PARAMS) =>
  mul(sr, coefficient(months, params));

/** indemnite: rounded down to the cent. */
export const severance = (sr, months, params = LAW_PARAMS) =>
  natFloor(severanceExact(sr, months, params));

/**
 * CauseFin. `kind` is "trialTermination" (ruptureEssai), "ordinaryTermination"
 * (resiliationOrdinaire), "immediateTermination" (resiliationImmediate, for
 * just cause), "mutualAgreement" (accordCommun) or "death" (deces); `party`
 * is "employer" or "employee" for the first three.
 */
export const isSeveranceDue = (cause) =>
  cause.kind === "ordinaryTermination" && cause.party === "employer";

/** indemniteRupture: severance actually paid, in cents. */
export const severancePay = (history, months, cause, params = LAW_PARAMS) =>
  isSeveranceDue(cause) ? severance(referenceSalary(history, params), months, params) : 0n;

/** Current French law (art. L1234-9 and R1234-2 of the Code du travail), for
 * comparison: 1/4 month per year up to 10 years, 1/3 beyond, from 8 months of
 * service. In months of salary. */
export function currentLawCoefficient(months) {
  if (months < 8) return ZERO;
  const years = q(months, 12);
  const firstTen = min(years, q(10));
  const beyond = sub(years, firstTen);
  return add(div(firstTen, q(4)), div(beyond, q(3)));
}
