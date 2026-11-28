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
* `indemniteRupture_le_plafond` (**T-PLAFOND**) : l'indemnité légale ne dépasse
  jamais 6 mois de `SR` (une convention peut prévoir plus :
  `indemnite_applicable_le_plafond`, dans `Hierarchie.lean`) ;
* `indemniteRupture_manipulation` (**T-MANIP**) : après 5 ans à temps plein,
  baisser le dernier salaire de `Δ` baisse l'indemnité de moins de
  `3Δ/11 + 1` centime ;
* `indemnite_saut_mensuel` : un mois d'ancienneté de plus augmente l'indemnité
  de moins de `3/80` du salaire de référence, plus un centime.
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

/-- Un mois d'ancienneté de plus fait avancer la fraction d'au plus `1/240`. -/
theorem fractionAnciennete_succ_le (m : Mois) :
    fractionAnciennete (m + 1) ≤ fractionAnciennete m + 1 / 240 := by
  unfold fractionAnciennete ancienneteSaturation
  have : ((min (m + 1) 240 : ℕ) : ℚ) ≤ (min m 240 : ℕ) + 1 := by
    exact_mod_cast (by omega : min (m + 1) 240 ≤ min m 240 + 1)
  rw [div_add' _ _ _ (by norm_num), div_le_div_iff_of_pos_right (by norm_num)]
  linarith

/-- Un mois d'ancienneté de plus augmente le coefficient d'au plus
`6 × 3/2 × 1/240 = 3/80` mois de salaire de référence. -/
theorem coefficient_succ_le (m : Mois) : coefficient (m + 1) ≤ coefficient m + 3 / 80 := by
  unfold coefficient plafondMois
  have h1 := smoothstep_sub_le (fractionAnciennete_mono (Nat.le_succ m))
  have h2 := fractionAnciennete_succ_le m
  linarith

/-- **Pas d'effet de seuil.** Un mois d'ancienneté de plus augmente l'indemnité
de moins de `3/80` du salaire de référence (moins de 4 %), plus un centime
d'arrondi. Il n'y a donc aucun mois où retarder ou avancer un licenciement
change beaucoup l'indemnité. Le préavis obéit à la même règle
(`preavis_succ_le`). -/
theorem indemnite_saut_mensuel {sr : ℚ} (hsr : 0 ≤ sr) (m : Mois) :
    (indemnite sr (m + 1) : ℚ) < indemnite sr m + 3 / 80 * sr + 1 := by
  have h := floor_lt_floor_add (indemniteQ_nonneg hsr (m + 1)) (indemniteQ sr m)
  have hc : indemniteQ sr (m + 1) - indemniteQ sr m ≤ 3 / 80 * sr := by
    unfold indemniteQ
    have := mul_le_mul_of_nonneg_left (coefficient_succ_le m) hsr
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
l'historique des mois (salaire et activité), de l'ancienneté en mois et de la
cause de la fin du contrat. -/
def indemniteRupture (h : List MoisTravaille) (m : Mois) (c : CauseFin) : Centimes :=
  if indemniteDue c then indemnite (salaireReference h) m else 0

/-- Pas d'indemnité en cas de démission, de rupture d'essai, de résiliation
immédiate pour juste motif, d'accord écrit ou de décès. -/
theorem indemniteRupture_eq_zero {c : CauseFin} (hc : c ≠ .resiliationOrdinaire .employeur)
    (h : List MoisTravaille) (m : Mois) : indemniteRupture h m c = 0 := by
  have : indemniteDue c = false := by
    cases hd : indemniteDue c
    · rfl
    · exact absurd ((indemniteDue_iff c).1 hd) hc
  simp [indemniteRupture, this]

/-- **T-PLAFOND.** L'indemnité légale de rupture ne dépasse jamais 6 mois de
salaire de référence, quelle que soit la cause de la fin. Un accord ou le
contrat peut prévoir plus (disposition `relative`), jamais au-delà de ce qu'il
stipule : `indemnite_applicable_le_plafond`. -/
theorem indemniteRupture_le_plafond (h : List MoisTravaille) (m : Mois) (c : CauseFin) :
    (indemniteRupture h m c : ℚ) ≤ 6 * salaireReference h := by
  unfold indemniteRupture
  split
  · exact indemnite_le_plafond (salaireReference_nonneg h) m
  · simpa using salaireReference_nonneg h

/-- **T-MANIP.** Pour un salarié à temps plein depuis au moins 5 ans, si
l'employeur abaisse le dernier salaire de `x + Δ` à `x`, l'indemnité baisse
(au sens large), mais de moins de `3Δ/11 + 1` centime. Exemple : une baisse
de 1 000 € du dernier salaire coûte moins de 272,73 € d'indemnité. -/
theorem indemniteRupture_manipulation (p r : List MoisTravaille)
    (hr : ∀ y ∈ r, y.activite = 1) (hlen : 59 ≤ r.length)
    (x Δ : ℕ) (m : Mois) (c : CauseFin) :
    indemniteRupture (p ++ r ++ [.plein x]) m c ≤ indemniteRupture (p ++ r ++ [.plein (x + Δ)]) m c ∧
      (indemniteRupture (p ++ r ++ [.plein (x + Δ)]) m c : ℚ)
        < indemniteRupture (p ++ r ++ [.plein x]) m c + 3 * Δ / 11 + 1 := by
  have hB : 11 / 12 ≤ masseActivite (p ++ r ++ [.plein x]) := by
    rw [List.append_assoc]
    refine masseActivite_ge_onze_douziemes p _ (fun y hy => ?_) (by simp; omega)
    rcases List.mem_append.1 hy with hy | hy
    · exact hr y hy
    · simp at hy; subst hy; rfl
  have hs := salaireReference_sensibilite (p ++ r) (.plein x) Δ
  have heq : ({ MoisTravaille.plein x with salaire := (MoisTravaille.plein x).salaire + Δ }
      : MoisTravaille) = .plein (x + Δ) := rfl
  rw [heq] at hs
  set d := alphaSR * Δ / masseActivite (p ++ r ++ [.plein x]) with hd
  have hd0 : 0 ≤ d := by
    rw [hd]; have := alphaSR_pos; positivity
  have hdle : d ≤ Δ / 22 := by
    rw [hd, div_le_iff₀ (by linarith)]
    have hΔ : (0 : ℚ) ≤ Δ := by positivity
    have := mul_le_mul_of_nonneg_left hB hΔ
    simp only [alphaSR]
    linarith
  have hsr : salaireReference (p ++ r ++ [.plein (x + Δ)])
      = salaireReference (p ++ r ++ [.plein x]) + d := by linarith
  unfold indemniteRupture
  split
  · rw [hsr]
    refine ⟨indemnite_mono_sr m (by linarith), ?_⟩
    have := indemnite_lipschitz (salaireReference_nonneg (p ++ r ++ [.plein x])) hd0 m
    unfold plafondMois at this
    linarith
  · simp only [Nat.cast_zero, le_refl, true_and]
    positivity

end Prouvhommes
