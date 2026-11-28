// Re-checks a theorem's promise under variant thresholds.
//
// Honesty rule (docs/frontend.md): Lean proves these theorems for the law's
// values only. Under a variant we either find a concrete counterexample
// ("broken"), or check the property by computation on a range of cases
// ("checked"), which is not a proof. Never a green tick for a variant.

import { q, cmp, mul, sub, div, pow, eq, ONE, toNumber } from "./rational.js";
import { activityMass, referenceSalary, severancePay } from "./p6.js";
import { euros, eurosOfRational, seniority } from "./format.js";

const FIRED = { kind: "ordinaryTermination", party: "employer" };
const SALARY = 300000n; // 3 000 €
const repeat = (n, cents) => Array.from({ length: n }, () => cents);

/**
 * @returns {{ state: "unaffected" | "checked" | "broken", text: string } | null}
 *   null when the theorem has no live check.
 */
/** Theorems that have a live check (tested against the Lean sources). */
export const checkedTheorems = () => Object.keys(CHECKS);

export function checkPromise(name, p) {
  const check = CHECKS[name];
  return check ? check(p) : null;
}

const CHECKS = {
  // T-PLAFOND: never more than 6 months of reference salary.
  indemniteRupture_le_plafond(p) {
    const m = p.saturationMonths;
    const pay = severancePay(repeat(m, SALARY), m, FIRED, p);
    const bound = 6n * SALARY;
    if (pay > bound) {
      return {
        state: "broken",
        text: `Rompue. Contre-exemple : après ${seniority(m)} à 3 000 € par mois, l’indemnité est de ${euros(pay)}, au-delà de 6 mois de salaire (${euros(bound)}).`,
      };
    }
    const cap = p.capMonths.n;
    return {
      state: "checked",
      text:
        cap === 6n
          ? "Tenue : le plafond reste de 6 mois, seul le rythme pour l’atteindre change."
          : `Tenue : avec un plafond de ${cap} mois, l’indemnité ne dépasse jamais ${cap} mois de salaire, donc pas 6.`,
    };
  },

  // T-MANIP: after 5 years full time, lowering the last salary by Δ costs
  // less than 3Δ/11 + 1 cent.
  indemniteRupture_manipulation(p) {
    // Worst case: exactly 60 full months. The last one weighs α/B in the
    // reference salary, with B = 1 − (1 − α)^60; the severance moves by
    // cap × α/B × Δ (up to rounding).
    const slope = div(mul(p.capMonths, p.alpha), sub(ONE, pow(sub(ONE, p.alpha), 60)));
    if (cmp(slope, q(3, 11)) <= 0) {
      return {
        state: "checked",
        text: `Tenue : après 5 ans à temps plein, une baisse de Δ du dernier salaire coûte au plus ${pct(slope)} de Δ, sous la borne de 3Δ/11 (${pct(q(3, 11))}).`,
      };
    }
    const m = p.saturationMonths;
    const base = repeat(59, SALARY);
    // Large enough for the excess (slope − 3/11)·Δ to beat the 1-cent slack.
    let delta = SALARY;
    for (;;) {
      const low = severancePay([...base, SALARY], m, FIRED, p);
      const high = severancePay([...base, SALARY + delta], m, FIRED, p);
      const loss = high - low;
      if (11n * loss >= 3n * delta + 11n) {
        return {
          state: "broken",
          text: `Rompue. Contre-exemple : après 5 ans à temps plein et ${seniority(m)} d’ancienneté, baisser le dernier salaire de ${euros(delta)} fait perdre ${euros(loss)} d’indemnité, plus que la borne 3Δ/11 + 0,01 € (${euros((3n * delta) / 11n + 1n)}).`,
        };
      }
      delta *= 10n;
    }
  },

  // The last salary moves SR by exactly αΔ/B, B being the activity mass.
  salaireReference_sensibilite(p) {
    const delta = 240000n;
    const h = repeat(60, SALARY);
    const shift = sub(referenceSalary([...h, SALARY + delta], p), referenceSalary([...h, SALARY], p));
    const weight = div(p.alpha, activityMass([...h, SALARY], p));
    if (eq(shift, mul(weight, q(delta)))) {
      return {
        state: "checked",
        text: `Tenue : après 5 ans à temps plein, le dernier mois pèse α/B = ${pct(weight)} du salaire de référence.`,
      };
    }
    return { state: "broken", text: `Rompue : le dernier mois ne pèse pas α/B.` };
  },

  // Agreements and contracts can only raise the severance (P15).
  indemnite_ge_legal: () => ({
    state: "unaffected",
    text: "Ne dépend d’aucun seuil : un accord ou le contrat ne peut que relever l’indemnité.",
  }),

  indemniteRupture_eq_zero: () => ({
    state: "unaffected",
    text: "Ne dépend d’aucun seuil : elle reste prouvée.",
  }),

  // Monotone in seniority: checked month by month over 50 years.
  indemnite_mono_anciennete(p) {
    let prev = 0n;
    for (let m = 0; m <= 600; m++) {
      const pay = severancePay([SALARY], m, FIRED, p);
      if (pay < prev) {
        return { state: "broken", text: `Rompue entre ${seniority(m - 1)} et ${seniority(m)}.` };
      }
      prev = pay;
    }
    return { state: "checked", text: "Vérifiée par le calcul, mois par mois, de 0 à 50 ans d’ancienneté." };
  },
};

const pct = (r) => `${(toNumber(r) * 100).toFixed(1).replace(".", ",")} %`;
