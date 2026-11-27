import { describe, expect, test } from "vitest";
import { q, eq, sub, add, toFixed, floor, natFloor } from "./rational.js";
import {
  LAW_PARAMS,
  coefficient,
  currentLawCoefficient,
  referenceSalary,
  salaryWindow,
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
  test("months without salary leave the window, which reaches back", () => {
    const h = [...repeat(10, 100), 0n, 0n, ...repeat(60, 200)];
    expect(salaryWindow(h)).toHaveLength(60);
    expect(eq(referenceSalary(h), q(200))).toBe(true);
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
  test("last salary moves SR by exactly Δ/24 and severance by < Δ/4 + 1", () => {
    let seed = 7;
    const rand = (n) => (seed = (seed * 48271) % 2147483647) % n;
    for (let i = 0; i < 200; i++) {
      const h = Array.from({ length: 1 + rand(90) }, () => BigInt(rand(3) ? 100000 + rand(900000) : 0));
      if (!h.some((s) => s !== 0n)) h.push(150000n);
      const x = BigInt(1 + rand(800000));
      const delta = BigInt(rand(500000));
      const m = rand(400);
      const low = [...h, x];
      const high = [...h, x + delta];
      expect(eq(sub(referenceSalary(high), referenceSalary(low)), q(delta, 24))).toBe(true);
      const pLow = severancePay(low, m, fired);
      const pHigh = severancePay(high, m, fired);
      expect(pLow <= pHigh).toBe(true);
      // pHigh < pLow + Δ/4 + 1  ⇔  4·pHigh < 4·pLow + Δ + 4
      expect(4n * pHigh < 4n * pLow + delta + 4n).toBe(true);
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
