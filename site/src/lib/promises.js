// Re-checks a theorem's promise under variant thresholds.
//
// Honesty rule (docs/frontend.md): Lean proves these theorems for the law's
// values only. Under a variant we either find a concrete counterexample
// ("broken"), or check the property by computation on a range of cases
// ("checked"), which is not a proof. Never a green tick for a variant.

import { q, cmp, mul, sub, eq } from "./rational.js";
import { referenceSalary, severancePay } from "./p6.js";
import { euros, eurosOfRational, seniority } from "./format.js";

const FIRED = { kind: "ordinaryTermination", party: "employer" };
const SALARY = 300000n; // 3 000 €
const repeat = (n, cents) => Array.from({ length: n }, () => cents);

/**
 * @returns {{ state: "unaffected" | "checked" | "broken", text: string } | null}
 *   null when the theorem has no live check.
 */
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
        text: `Rompue. Contre-exemple : après ${seniority(m)} à 3 000 € par mois, l'indemnité est de ${euros(pay)}, au-delà de 6 mois de salaire (${euros(bound)}).`,
      };
    }
    const cap = p.capMonths.n;
    return {
      state: "checked",
      text:
        cap === 6n
          ? "Tenue : le plafond reste de 6 mois, seul le rythme pour l'atteindre change."
          : `Tenue : avec un plafond de ${cap} mois, l'indemnité ne dépasse jamais ${cap} mois de salaire, donc pas 6.`,
    };
  },

  // T-MANIP: lowering the last salary by Δ costs less than Δ/4 + 1 cent.
  indemniteRupture_manipulation(p) {
    // The severance moves by cap × α × Δ (up to rounding); the bound is Δ/4.
    const slope = mul(p.capMonths, p.alpha);
    if (cmp(slope, q(1, 4)) <= 0) {
      return {
        state: "checked",
        text: `Tenue : une baisse de Δ du dernier salaire coûte au plus ${p.capMonths.n} × 1/${p.alpha.d} = ${slope.n}/${slope.d} de Δ, sous la borne de Δ/4.`,
      };
    }
    const m = p.saturationMonths;
    // Large enough for the excess (slope − 1/4)·Δ to beat the 1-cent slack.
    let delta = SALARY;
    for (;;) {
      const low = severancePay([SALARY, SALARY], m, FIRED, p);
      const high = severancePay([SALARY, SALARY + delta], m, FIRED, p);
      const loss = high - low;
      if (4n * loss >= delta + 4n) {
        return {
          state: "broken",
          text: `Rompue. Contre-exemple : à ${seniority(m)}, baisser le dernier salaire de ${euros(delta)} fait perdre ${euros(loss)} d'indemnité, plus que la borne Δ/4 + 0,01 € (${euros(delta / 4n + 1n)}).`,
        };
      }
      delta *= 10n;
    }
  },

  // The last salary moves SR by exactly Δ/24.
  salaireReference_sensibilite(p) {
    const delta = 240000n;
    const h = repeat(Math.max(2, p.windowSize), SALARY);
    const shift = sub(referenceSalary([...h, SALARY + delta], p), referenceSalary([...h, SALARY], p));
    if (eq(shift, q(delta, 24))) {
      return { state: "checked", text: "Tenue : le poids du dernier mois reste 1/24." };
    }
    return {
      state: "broken",
      text: `Rompue. Le dernier mois pèse désormais 1/${p.alpha.d} : une hausse de ${euros(delta)} déplace le salaire de référence de ${eurosOfRational(shift)}, pas de ${euros(delta / 24n)}.`,
    };
  },

  // Agreements and contracts can only raise the severance (P15).
  indemnite_ge_legal: () => ({
    state: "unaffected",
    text: "Ne dépend d'aucun seuil : un accord ou le contrat ne peut que relever l'indemnité.",
  }),

  indemniteRupture_eq_zero: () => ({
    state: "unaffected",
    text: "Ne dépend d'aucun seuil : elle reste prouvée.",
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
    return { state: "checked", text: "Vérifiée par le calcul, mois par mois, de 0 à 50 ans d'ancienneté." };
  },
};
