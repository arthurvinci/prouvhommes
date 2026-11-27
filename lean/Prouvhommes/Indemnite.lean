import Prouvhommes.Smoothstep
import Prouvhommes.SalaireReference

/-!
# Indemnité de rupture (P6)

`indemnité = ⌊ SR × 6 × S(min(m, 240) / 240) ⌋`

* `SR` : salaire de référence (`SalaireReference.lean`), en centimes ;
* `m` : ancienneté en mois révolus ; saturation à 240 mois (20 ans) ;
* `S` : smoothstep (`Smoothstep.lean`) ;
* arrondi unique au centime inférieur (M5).

L'indemnité n'est due qu'en cas de résiliation ordinaire par l'employeur.

Résultats principaux :
* `indemniteRupture_le_plafond` (**T-PLAFOND**) : jamais plus de 6 mois de `SR` ;
* `indemniteRupture_manipulation` (**T-MANIP**) : baisser le dernier salaire de
  `Δ` baisse l'indemnité de moins de `Δ/4 + 1` centime.
-/

namespace Prouvhommes

/-- Plafond, en mois de salaire de référence (P6). -/
def plafondMois : ℚ := 6

/-- Ancienneté de saturation, en mois (P6). -/
def ancienneteSaturation : ℕ := 240

/-- Fraction de l'ancienneté de saturation atteinte, dans `[0, 1]`. -/
def fractionAnciennete (m : Mois) : ℚ :=
  (min m ancienneteSaturation : ℕ) / ancienneteSaturation

theorem fractionAnciennete_nonneg (m : Mois) : 0 ≤ fractionAnciennete m := by
  unfold fractionAnciennete; positivity

theorem fractionAnciennete_le_one (m : Mois) : fractionAnciennete m ≤ 1 := by
  unfold fractionAnciennete ancienneteSaturation
  rw [div_le_one (by norm_num)]
  exact_mod_cast min_le_right m 240

theorem fractionAnciennete_mono {a b : Mois} (h : a ≤ b) :
    fractionAnciennete a ≤ fractionAnciennete b := by
  unfold fractionAnciennete
  gcongr

/-- Coefficient de l'indemnité, en mois de `SR` : `6 × S(min(m, 240) / 240)`. -/
def coefficient (m : Mois) : ℚ := plafondMois * smoothstep (fractionAnciennete m)

theorem coefficient_nonneg (m : Mois) : 0 ≤ coefficient m := by
  unfold coefficient plafondMois
  have := smoothstep_nonneg (fractionAnciennete_le_one m)
  positivity

theorem coefficient_le_plafond (m : Mois) : coefficient m ≤ plafondMois := by
  unfold coefficient plafondMois
  have := smoothstep_le_one (fractionAnciennete_nonneg m)
  linarith

theorem coefficient_mono : Monotone coefficient := by
  intro a b h
  unfold coefficient plafondMois
  have := smoothstep_mono (fractionAnciennete_nonneg a) (fractionAnciennete_mono h)
    (fractionAnciennete_le_one b)
  linarith

@[simp] theorem coefficient_zero : coefficient 0 = 0 := by
  simp [coefficient, fractionAnciennete]

theorem coefficient_sature {m : Mois} (h : ancienneteSaturation ≤ m) :
    coefficient m = plafondMois := by
  unfold coefficient fractionAnciennete
  rw [min_eq_right h, div_self (by norm_num [ancienneteSaturation])]
  simp [plafondMois]

/-! ## Montant -/

/-- Montant exact, avant arrondi, en centimes. -/
def indemniteQ (sr : ℚ) (m : Mois) : ℚ := sr * coefficient m

/-- **Indemnité de rupture** (P6), en centimes, arrondie au centime inférieur. -/
def indemnite (sr : ℚ) (m : Mois) : Centimes := ⌊indemniteQ sr m⌋₊

theorem indemniteQ_nonneg {sr : ℚ} (hsr : 0 ≤ sr) (m : Mois) : 0 ≤ indemniteQ sr m :=
  mul_nonneg hsr (coefficient_nonneg m)

theorem indemniteQ_le_plafond {sr : ℚ} (hsr : 0 ≤ sr) (m : Mois) :
    indemniteQ sr m ≤ plafondMois * sr := by
  unfold indemniteQ
  rw [mul_comm plafondMois]
  exact mul_le_mul_of_nonneg_left (coefficient_le_plafond m) hsr

/-- Plafond, avant le filtre sur la cause de rupture. -/
theorem indemnite_le_plafond {sr : ℚ} (hsr : 0 ≤ sr) (m : Mois) :
    (indemnite sr m : ℚ) ≤ plafondMois * sr :=
  (Nat.floor_le (indemniteQ_nonneg hsr m)).trans (indemniteQ_le_plafond hsr m)

/-- L'indemnité croît avec l'ancienneté. -/
theorem indemnite_mono_anciennete {sr : ℚ} (hsr : 0 ≤ sr) : Monotone (indemnite sr) := by
  intro a b h
  exact Nat.floor_mono (mul_le_mul_of_nonneg_left (coefficient_mono h) hsr)

/-- L'indemnité croît avec le salaire de référence. -/
theorem indemnite_mono_sr (m : Mois) : Monotone (fun sr => indemnite sr m) := by
  intro a b h
  exact Nat.floor_mono (mul_le_mul_of_nonneg_right h (coefficient_nonneg m))

@[simp] theorem indemnite_zero (sr : ℚ) : indemnite sr 0 = 0 := by
  simp [indemnite, indemniteQ]

theorem indemnite_sature (sr : ℚ) {m : Mois} (h : ancienneteSaturation ≤ m) :
    indemnite sr m = ⌊plafondMois * sr⌋₊ := by
  rw [indemnite, indemniteQ, coefficient_sature h, mul_comm]

/-- L'arrondi ne coûte jamais plus d'un centime d'écart :
`⌊a⌋ < ⌊b⌋ + (a − b) + 1` dès que `0 ≤ a`. -/
theorem floor_lt_floor_add {a : ℚ} (ha : 0 ≤ a) (b : ℚ) :
    (⌊a⌋₊ : ℚ) < ⌊b⌋₊ + (a - b) + 1 := by
  have h1 := Nat.floor_le ha
  have h2 := Nat.lt_floor_add_one b
  have : b < (⌊b⌋₊ : ℚ) + 1 := by exact_mod_cast h2
  linarith

/-- Une hausse de `d ≥ 0` du salaire de référence augmente l'indemnité de moins
de `6 d + 1` centime. -/
theorem indemnite_lipschitz {sr d : ℚ} (hsr : 0 ≤ sr) (hd : 0 ≤ d) (m : Mois) :
    (indemnite (sr + d) m : ℚ) < indemnite sr m + plafondMois * d + 1 := by
  have h := floor_lt_floor_add (indemniteQ_nonneg (by linarith : 0 ≤ sr + d) m)
    (indemniteQ sr m)
  have hc : indemniteQ (sr + d) m - indemniteQ sr m ≤ plafondMois * d := by
    unfold indemniteQ
    have := mul_le_mul_of_nonneg_left (coefficient_le_plafond m) hd
    nlinarith
  unfold indemnite
  linarith

/-! ## Cas où l'indemnité est due -/

/-- L'indemnité n'est due qu'en cas de résiliation ordinaire par l'employeur (P6). -/
def indemniteDue : CauseFin → Bool
  | .resiliationOrdinaire .employeur => true
  | _ => false

theorem indemniteDue_iff (c : CauseFin) :
    indemniteDue c = true ↔ c = .resiliationOrdinaire .employeur := by
  cases c with
  | ruptureEssai p => simp [indemniteDue]
  | resiliationOrdinaire p => cases p <;> simp [indemniteDue]
  | resiliationImmediate p => simp [indemniteDue]
  | accordCommun => simp [indemniteDue]
  | deces => simp [indemniteDue]

/-- **Indemnité de rupture effectivement versée**, en centimes, à partir de
l'historique des salaires mensuels, de l'ancienneté en mois et de la cause de
la fin du contrat. -/
def indemniteRupture (h : List Centimes) (m : Mois) (c : CauseFin) : Centimes :=
  if indemniteDue c then indemnite (salaireReference h) m else 0

/-- Pas d'indemnité en cas de démission, de rupture d'essai, de résiliation
immédiate pour juste motif, d'accord écrit ou de décès. -/
theorem indemniteRupture_eq_zero {c : CauseFin} (hc : c ≠ .resiliationOrdinaire .employeur)
    (h : List Centimes) (m : Mois) : indemniteRupture h m c = 0 := by
  have : indemniteDue c = false := by
    cases hd : indemniteDue c
    · rfl
    · exact absurd ((indemniteDue_iff c).1 hd) hc
  simp [indemniteRupture, this]

/-- **T-PLAFOND.** L'indemnité de rupture ne dépasse jamais 6 mois de salaire
de référence. -/
theorem indemniteRupture_le_plafond (h : List Centimes) (m : Mois) (c : CauseFin) :
    (indemniteRupture h m c : ℚ) ≤ 6 * salaireReference h := by
  unfold indemniteRupture
  split
  · exact indemnite_le_plafond (salaireReference_nonneg h) m
  · simpa using salaireReference_nonneg h

/-- **T-MANIP.** Soit un historique contenant au moins un mois payé, suivi
d'un dernier mois payé `x + Δ`. Si l'employeur abaisse ce dernier salaire à
`x`, l'indemnité baisse (au sens large), mais de moins de `Δ/4 + 1` centime.
Exemple : une baisse de 1 000 € du dernier salaire coûte moins de 250,01 €
d'indemnité. -/
theorem indemniteRupture_manipulation (h : List Centimes) (hh : ∃ s ∈ h, s ≠ 0)
    {x : Centimes} (hx : x ≠ 0) (Δ : ℕ) (m : Mois) (c : CauseFin) :
    indemniteRupture (h ++ [x]) m c ≤ indemniteRupture (h ++ [x + Δ]) m c ∧
      (indemniteRupture (h ++ [x + Δ]) m c : ℚ)
        < indemniteRupture (h ++ [x]) m c + Δ / 4 + 1 := by
  have hs := salaireReference_sensibilite h hh hx Δ
  have hsr : salaireReference (h ++ [x + Δ]) = salaireReference (h ++ [x]) + Δ / 24 := by
    linarith
  unfold indemniteRupture
  split
  · rw [hsr]
    refine ⟨indemnite_mono_sr m (by simp; positivity), ?_⟩
    have := indemnite_lipschitz (salaireReference_nonneg (h ++ [x]))
      (show (0 : ℚ) ≤ Δ / 24 by positivity) m
    have e : plafondMois * ((Δ : ℚ) / 24) = Δ / 4 := by norm_num [plafondMois]; ring
    linarith
  · exact ⟨le_rfl, by simp only [Nat.cast_zero, zero_add]; positivity⟩

/-! ## Exemples (charte, §5)

Coefficients, en mois de salaire de référence. -/

example : coefficient 12 = 87 / 2000 := by
  norm_num [coefficient, fractionAnciennete, ancienneteSaturation, plafondMois, smoothstep]
example : coefficient 60 = 15 / 16 := by
  norm_num [coefficient, fractionAnciennete, ancienneteSaturation, plafondMois, smoothstep]
example : coefficient 120 = 3 := by
  norm_num [coefficient, fractionAnciennete, ancienneteSaturation, plafondMois, smoothstep]
example : coefficient 180 = 81 / 16 := by
  norm_num [coefficient, fractionAnciennete, ancienneteSaturation, plafondMois, smoothstep]
example : coefficient 300 = 6 := coefficient_sature (by norm_num [ancienneteSaturation])

/-- Salaire constant de 3 000 € pendant 10 ans, licenciement : 9 000 €. -/
example :
    indemniteRupture (List.replicate 120 300000) 120 (.resiliationOrdinaire .employeur)
      = 900000 := by
  decide +kernel

end Prouvhommes
