// Exact rational arithmetic on BigInt, mirroring Lean's ℚ (charter rule M5:
// no floating point anywhere in a displayed amount).
//
// A rational is an immutable { n, d } with d > 0 and gcd(|n|, d) = 1.

const abs = (x) => (x < 0n ? -x : x);

function gcd(a, b) {
  a = abs(a);
  b = abs(b);
  while (b) [a, b] = [b, a % b];
  return a;
}

export function q(n, d = 1n) {
  n = BigInt(n);
  d = BigInt(d);
  if (d === 0n) throw new RangeError("Zero denominator");
  if (d < 0n) [n, d] = [-n, -d];
  const g = gcd(n, d) || 1n;
  return Object.freeze({ n: n / g, d: d / g });
}

export const ZERO = q(0);
export const ONE = q(1);

export const add = (a, b) => q(a.n * b.d + b.n * a.d, a.d * b.d);
export const sub = (a, b) => q(a.n * b.d - b.n * a.d, a.d * b.d);
export const mul = (a, b) => q(a.n * b.n, a.d * b.d);
export const div = (a, b) => q(a.n * b.d, a.d * b.n);
export const pow = (a, k) => q(a.n ** BigInt(k), a.d ** BigInt(k));

export const cmp = (a, b) => {
  const x = a.n * b.d - b.n * a.d;
  return x < 0n ? -1 : x > 0n ? 1 : 0;
};
export const eq = (a, b) => a.n === b.n && a.d === b.d;
export const min = (a, b) => (cmp(a, b) <= 0 ? a : b);

/** Floor towards −∞, as a BigInt. */
export function floor(a) {
  const f = a.n / a.d; // truncates towards zero
  return a.n < 0n && f * a.d !== a.n ? f - 1n : f;
}

/** Lean's ⌊x⌋₊: floor, clamped at 0. */
export const natFloor = (a) => {
  const f = floor(a);
  return f < 0n ? 0n : f;
};

/** Approximate value for display only (charts, slider positions). */
export const toNumber = (a) => Number(a.n) / Number(a.d);

/** Decimal string with `digits` decimals, rounded half away from zero. */
export function toFixed(a, digits) {
  const scale = 10n ** BigInt(digits);
  const scaled = a.n * scale;
  let i = scaled / a.d;
  const r = abs(scaled % a.d) * 2n;
  if (r >= a.d) i += a.n < 0n ? -1n : 1n;
  const neg = i < 0n;
  const s = abs(i).toString().padStart(digits + 1, "0");
  const int = s.slice(0, s.length - digits) || "0";
  const frac = digits ? "." + s.slice(s.length - digits) : "";
  return (neg ? "-" : "") + int + frac;
}
