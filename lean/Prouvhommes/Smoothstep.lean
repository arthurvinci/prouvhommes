import Prouvhommes.Basic

/-!
# Smoothstep (P6)

La courbe de l'indemnité de rupture : `S(t) = 3t² − 2t³`, sur `ℚ`.
Sur `[0, 1]`, elle part de 0, arrive à 1, est croissante et reste dans `[0, 1]`.
Sa pente est nulle aux deux bouts : l'indemnité démarre lentement et sature
en douceur.
-/

namespace Prouvhommes

/-- La fonction smoothstep `S(t) = 3t² − 2t³` (P6). -/
def smoothstep (t : ℚ) : ℚ := 3 * t ^ 2 - 2 * t ^ 3

@[simp] theorem smoothstep_zero : smoothstep 0 = 0 := by norm_num [smoothstep]

@[simp] theorem smoothstep_one : smoothstep 1 = 1 := by norm_num [smoothstep]

/-- Symétrie : à mi-parcours, la moitié du plafond. -/
theorem smoothstep_demi : smoothstep (1 / 2) = 1 / 2 := by norm_num [smoothstep]

/-- `S(t) = t²(3 − 2t)`. -/
theorem smoothstep_eq_mul (t : ℚ) : smoothstep t = t ^ 2 * (3 - 2 * t) := by
  unfold smoothstep; ring

/-- `1 − S(t) = (1 − t)²(1 + 2t)`. -/
theorem one_sub_smoothstep (t : ℚ) : 1 - smoothstep t = (1 - t) ^ 2 * (1 + 2 * t) := by
  unfold smoothstep; ring

theorem smoothstep_nonneg {t : ℚ} (h1 : t ≤ 1) : 0 ≤ smoothstep t := by
  rw [smoothstep_eq_mul]
  exact mul_nonneg (sq_nonneg t) (by linarith)

theorem smoothstep_le_one {t : ℚ} (h0 : 0 ≤ t) : smoothstep t ≤ 1 := by
  have := one_sub_smoothstep t
  have : 0 ≤ (1 - t) ^ 2 * (1 + 2 * t) := mul_nonneg (sq_nonneg _) (by linarith)
  linarith

/-- Croissance sur `[0, 1]`, sans analyse : on factorise
`S(b) − S(a) = (b − a)(3(a + b) − 2(a² + ab + b²))`. -/
theorem smoothstep_mono {a b : ℚ} (ha : 0 ≤ a) (hab : a ≤ b) (hb : b ≤ 1) :
    smoothstep a ≤ smoothstep b := by
  have hfact : smoothstep b - smoothstep a
      = (b - a) * (3 * (a + b) - 2 * (a ^ 2 + a * b + b ^ 2)) := by
    unfold smoothstep; ring
  have h2 : 0 ≤ 3 * (a + b) - 2 * (a ^ 2 + a * b + b ^ 2) := by
    nlinarith [mul_le_mul_of_nonneg_left (show a ≤ 1 by linarith) ha,
      mul_le_mul_of_nonneg_left hb (show 0 ≤ b by linarith),
      mul_le_mul_of_nonneg_left (show b ≤ 1 from hb) ha]
  have : 0 ≤ smoothstep b - smoothstep a := by
    rw [hfact]; exact mul_nonneg (by linarith) h2
  linarith

theorem smoothstep_monotoneOn : MonotoneOn smoothstep (Set.Icc 0 1) :=
  fun _ ha _ hb hab => smoothstep_mono ha.1 hab hb.2

end Prouvhommes
