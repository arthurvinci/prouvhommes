import { describe, expect, test } from "vitest";
import { NOTICE_POINTS, currentLawNotice, lastDay, notice } from "./notice.js";

const DAYS = Array.from({ length: 4000 }, (_, j) => j);

describe("notice (P3, P4)", () => {
  test("goes through 7, 30, 60 and 90 days", () => {
    for (const [j, n] of NOTICE_POINTS) expect(notice(j), `day ${j}`).toBe(n);
  });

  // Values checked with #eval in the Lean PR (fonctions-continues).
  test("matches the Lean evaluations", () => {
    expect(notice(10)).toBe(14);
    expect(lastDay(400)).toBe(460);
    expect(lastDay(364)).toBe(423);
    expect(lastDay(365)).toBe(425);
  });

  test("stays between 7 and 90 days, and is 90 from 9 years on (preavis_ge_7, preavis_le_90, preavis_sature)", () => {
    for (const j of DAYS) {
      expect(notice(j)).toBeGreaterThanOrEqual(7);
      expect(notice(j)).toBeLessThanOrEqual(90);
      if (j >= 3285) expect(notice(j)).toBe(90);
    }
  });

  test("no threshold effect: one more day adds at most one day (preavis_monotone, preavis_succ_le)", () => {
    for (const j of DAYS) {
      const step = notice(j + 1) - notice(j);
      expect(step).toBeGreaterThanOrEqual(0);
      expect(step).toBeLessThanOrEqual(1);
    }
  });

  test("notifying a day later ends the contract 1 or 2 days later (fin_preavis_succ)", () => {
    for (const j of DAYS) expect([1, 2]).toContain(lastDay(j + 1) - lastDay(j));
  });
});

describe("current law (L1234-1)", () => {
  test("nothing before 6 months, one month up to 2 years, two months after", () => {
    expect(currentLawNotice(182)).toBe(0);
    expect(currentLawNotice(183)).toBe(30);
    expect(currentLawNotice(729)).toBe(30);
    expect(currentLawNotice(730)).toBe(60);
  });
});
