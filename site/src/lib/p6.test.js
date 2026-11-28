import { describe, expect, test } from "vitest";
import { q, eq, sub, add, mul, div, cmp, ZERO, toFixed, floor, natFloor } from "./rational.js";
import {
  LAW_PARAMS,
  coefficient,
  currentLawCoefficient,
  SUSPENDED,
  activityMass,
  referenceSalary,
  severancePay,
  smoothstep,
} from "./p6.js";

const fired = { kind: "ordinaryTermination", party: "employer" };
const repeat = (n, cents) => Array.from({ length: n }, () => BigInt(cents));

describe("rational", () => {
  test("normalises sign and gcd", () => {
    expect(q(6, -4)).toEqual({ n: -3n, d: 2n });
  });
  test("floor rounds towards −∞", () => {
    expect(floor(q(-7, 2))).toBe(-4n);
    expect(floor(q(7, 2))).toBe(3n);
    expect(natFloor(q(-1, 3))).toBe(0n);
  });
  test("toFixed", () => {
    expect(toFixed(q(87, 2000), 2)).toBe("0.04");
    expect(toFixed(q(81, 16), 2)).toBe("5.06");
    expect(toFixed(q(-1, 8), 2)).toBe("-0.13");
  });
});

// Same values as the `example`s at the end of lean/Prouvhommes/Indemnite.lean.
describe("P6 matches the Lean examples", () => {
  test.each([
    [12, q(87, 2000)],
    [60, q(15, 16)],
    [120, q(3)],
    [180, q(81, 16)],
    [300, q(6)],
  ])("coefficient %i", (m, expected) => {
    expect(eq(coefficient(m), expected)).toBe(true);
  });

  test("3,000 € for 10 years, dismissed: 9,000 €", () => {
    expect(severancePay(repeat(120, 300000), 120, fired)).toBe(900000n);
  });

  test("smoothstep(1/2) = 1/2", () => {
    expect(eq(smoothstep(q(1, 2)), q(1, 2))).toBe(true);
  });
});

describe("P6 properties", () => {
  // salaireReference_encadrement: constant full-time salary.
  test("a constant salary is its own reference salary", () => {
    expect(eq(referenceSalary(repeat(37, 250000)), q(250000))).toBe(true);
  });

  // salaireReference_suspendu: a suspended month changes nothing.
  test("a suspended month leaves SR unchanged", () => {
    const h = [...repeat(10, 100000), ...repeat(5, 200000)];
    expect(eq(referenceSalary([...h, SUSPENDED]), referenceSalary(h))).toBe(true);
  });

  // salaireReference_prorata: a partial month paid pro rata changes nothing.
  test("a partial month paid pro rata leaves SR unchanged", () => {
    const h = repeat(24, 300000);
    const activity = q(1, 3);
    const sr = referenceSalary([...h, SUSPENDED]);
    const partial = { salary: 100000n, activity };
    expect(eq(mul(activity, sr), q(100000))).toBe(true);
    expect(eq(referenceSalary([...h, partial]), sr)).toBe(true);
  });

  // salaireReference_mois_proche: no jump between 0 € and 1 cent.
  test("an almost suspended month almost does not count", () => {
    const h = repeat(120, 300000);
    // One cent for a thousandth of a month: SR moves by 13 cents, within the
    // proved bound α(s + τ·SR)/B (125 € with the former rule, which counted
    // the month in full).
    const before = [...h, SUSPENDED];
    const month = { salary: 1n, activity: q(1, 1000) };
    const sr = referenceSalary(before);
    const shift = sub(sr, referenceSalary([...h, month]));
    const bound = div(mul(LAW_PARAMS.alpha, add(q(month.salary), mul(month.activity, sr))), activityMass(before));
    expect(cmp(shift, ZERO) > 0 && cmp(shift, bound) <= 0).toBe(true);
    expect(cmp(shift, q(20)) < 0).toBe(true);
  });

  test("no severance unless the employer terminates ordinarily", () => {
    const h = repeat(120, 300000);
    for (const cause of [
      { kind: "ordinaryTermination", party: "employee" },
      { kind: "trialTermination", party: "employer" },
      { kind: "immediateTermination", party: "employer" },
    ]) {
      expect(severancePay(h, 120, cause)).toBe(0n);
    }
  });

  // salaireReference_sensibilite and indemniteRupture_manipulation, on samples.
  // Exact rationals over 60 to 160 months are slow (denominators grow like
  // 24^n): 50 samples, and a budget well above the default 5 s, so a slow CI
  // runner does not fail the test. Lean proves the property for all cases.
  test("last salary moves SR by exactly αΔ/B; after 5 years, severance by < 3Δ/11 + 1", { timeout: 20000 }, () => {
    let seed = 7;
    const rand = (n) => (seed = (seed * 48271) % 2147483647) % n;
    for (let i = 0; i < 50; i++) {
      const old = Array.from({ length: rand(60) }, () =>
        rand(4) ? BigInt(100000 + rand(900000)) : { salary: BigInt(rand(100000)), activity: q(rand(4), 3) },
      );
      const recent = repeat(59 + rand(40), 100000 + rand(900000));
      const x = BigInt(rand(800000));
      const delta = BigInt(rand(500000));
      const m = rand(400);
      const low = [...old, ...recent, x];
      const high = [...old, ...recent, x + delta];
      const shift = sub(referenceSalary(high), referenceSalary(low));
      expect(eq(shift, div(mul(LAW_PARAMS.alpha, q(delta)), activityMass(low)))).toBe(true);
      const pLow = severancePay(low, m, fired);
      const pHigh = severancePay(high, m, fired);
      expect(pLow <= pHigh).toBe(true);
      // pHigh < pLow + 3Δ/11 + 1  ⇔  11·pHigh < 11·pLow + 3Δ + 11
      expect(11n * pHigh < 11n * pLow + 3n * delta + 11n).toBe(true);
    }
  });

  test("current law, for comparison (charter §5)", () => {
    expect(toFixed(currentLawCoefficient(12), 2)).toBe("0.25");
    expect(toFixed(currentLawCoefficient(120), 2)).toBe("2.50");
    expect(toFixed(currentLawCoefficient(240), 2)).toBe("5.83");
  });

  test("law parameters are frozen", () => {
    expect(Object.isFrozen(LAW_PARAMS)).toBe(true);
    expect(eq(add(LAW_PARAMS.alpha, q(23, 24)), q(1))).toBe(true);
  });
});
