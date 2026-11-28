import Prouvhommes.Basic

/-!
# Salaire de référence (P6)

Le salaire de référence `SR` est une **moyenne pondérée des salaires ramenés à
temps plein**, sur tout le contrat. Le poids d'un mois est son taux d'activité
(la fraction du mois travaillée ou rémunérée, entre 0 et 1), multiplié par
`α (1 − α)^k`, où `k` est le nombre de mois écoulés depuis et `α = 1/24`.

Concrètement, on tient deux moyennes exponentielles parties de 0, l'une des
salaires versés, l'autre des taux d'activité, et on fait le quotient :

* `Aₖ = α·sₖ + (1 − α)·Aₖ₋₁` (masse des salaires) ;
* `Bₖ = α·τₖ + (1 − α)·Bₖ₋₁` (masse d'activité) ;
* `SR = A / B` (et `0` si le contrat n'a jamais connu d'activité).

Il n'y a ni fenêtre ni mois exclu, donc aucun effet de seuil :

* un mois suspendu (`τ = 0`, salaire nul) ne compte pas ; un mois presque
  suspendu compte presque pas (`salaireReference_mois_proche`) ;
* un mois partiel payé au prorata ne change rien (`salaireReference_prorata`) ;
* les mois anciens s'effacent progressivement, sans jamais sortir d'un coup.

Résultats principaux :
* `salaireReference_encadrement` : `SR` est compris entre le plus petit et le
  plus grand salaire ramené à temps plein ;
* `salaireReference_sensibilite` : modifier le dernier salaire de `Δ` déplace
  `SR` d'exactement `α Δ / B` ;
* `masseActivite_ge` : après 60 mois à temps plein, `B ≥ 1 − (23/24)^60 > 11/12`,
  donc le dernier salaire pèse moins de 1/22.
-/

namespace Prouvhommes

/-! ## Mois de l'historique -/

/-- Un mois de l'historique : salaire brut versé, en centimes, et taux
d'activité (fraction du mois travaillée ou rémunérée, congés payés compris). -/
structure MoisTravaille where
  salaire : Centimes
  activite : ℚ := 1
  activite_nonneg : 0 ≤ activite := by norm_num
  activite_le_one : activite ≤ 1 := by norm_num

namespace MoisTravaille

/-- Un mois entier travaillé, payé `s`. -/
def plein (s : Centimes) : MoisTravaille := { salaire := s }

/-- Un mois suspendu : ni activité, ni salaire. -/
def suspendu : MoisTravaille := { salaire := 0, activite := 0 }

end MoisTravaille

/-! ## Sommes exponentielles -/

/-- Un pas de la récurrence : `e ↦ α·x + (1 − α)·e`. -/
def pasEMA (α e x : ℚ) : ℚ := α * x + (1 - α) * e

/-- Somme exponentielle d'une liste (du plus ancien au plus récent), partie de 0 :
`Σ α (1 − α)^k xₖ`, où `k` compte les termes postérieurs. -/
def sommeExp (α : ℚ) (l : List ℚ) : ℚ := l.foldl (pasEMA α) 0

/-- La récurrence est affine en sa valeur initiale. -/
theorem foldl_pasEMA_affine (α : ℚ) (r : List ℚ) (e : ℚ) :
    r.foldl (pasEMA α) e = r.foldl (pasEMA α) 0 + (1 - α) ^ r.length * e := by
  induction r generalizing e with
  | nil => simp
  | cons y r ih =>
    simp only [List.foldl_cons, List.length_cons]
    rw [ih (pasEMA α e y), ih (pasEMA α 0 y)]
    unfold pasEMA; ring

theorem sommeExp_snoc (α : ℚ) (l : List ℚ) (x : ℚ) :
    sommeExp α (l ++ [x]) = pasEMA α (sommeExp α l) x := by
  simp [sommeExp, List.foldl_append]

/-- Positivité : partie d'une valeur positive ou nulle, sur des termes positifs
ou nuls, la récurrence reste positive ou nulle. -/
theorem foldl_pasEMA_nonneg {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) (l : List ℚ)
    (hl : ∀ x ∈ l, 0 ≤ x) {e : ℚ} (he : 0 ≤ e) : 0 ≤ l.foldl (pasEMA α) e := by
  induction l generalizing e with
  | nil => simpa using he
  | cons y l ih =>
    simp only [List.foldl_cons]
    apply ih (fun x hx => hl x (List.mem_cons_of_mem _ hx))
    have hy := hl y List.mem_cons_self
    unfold pasEMA
    have : 0 ≤ 1 - α := by linarith
    positivity

/-- Comparaison terme à terme : si `f ≤ g` sur chaque mois et au départ, la
récurrence sur `f` reste sous la récurrence sur `g`. -/
theorem foldl_pasEMA_le {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) {β : Type*} (l : List β)
    (f g : β → ℚ) (hfg : ∀ x ∈ l, f x ≤ g x) {a b : ℚ} (hab : a ≤ b) :
    (l.map f).foldl (pasEMA α) a ≤ (l.map g).foldl (pasEMA α) b := by
  induction l generalizing a b with
  | nil => simpa using hab
  | cons y l ih =>
    simp only [List.map_cons, List.foldl_cons]
    apply ih (fun x hx => hfg x (List.mem_cons_of_mem _ hx))
    have hy := hfg y List.mem_cons_self
    unfold pasEMA
    have h1 : 0 ≤ 1 - α := by linarith
    nlinarith [mul_le_mul_of_nonneg_left hy hα0, mul_le_mul_of_nonneg_left hab h1]

/-- Linéarité : multiplier tous les termes et la valeur initiale par `c`
multiplie le résultat par `c`. -/
theorem foldl_pasEMA_mul (α c : ℚ) {β : Type*} (l : List β) (g : β → ℚ) (b : ℚ) :
    (l.map fun x => c * g x).foldl (pasEMA α) (c * b) = c * (l.map g).foldl (pasEMA α) b := by
  induction l generalizing b with
  | nil => simp
  | cons y l ih =>
    simp only [List.map_cons, List.foldl_cons]
    rw [show pasEMA α (c * b) (c * g y) = c * pasEMA α b (g y) by unfold pasEMA; ring, ih]

/-- Sur des termes tous égaux à 1 : `1 − (1 − α)^n (1 − e)`. -/
theorem foldl_pasEMA_replicate_one (α : ℚ) (n : ℕ) (e : ℚ) :
    (List.replicate n (1 : ℚ)).foldl (pasEMA α) e = 1 - (1 - α) ^ n * (1 - e) := by
  induction n generalizing e with
  | zero => simp
  | succ n ih =>
    rw [List.replicate_succ, List.foldl_cons, ih]
    unfold pasEMA; ring

/-! ## Salaire de référence -/

/-- Coefficient des moyennes exponentielles (P6). -/
def alphaSR : ℚ := 1 / 24

theorem alphaSR_pos : 0 < alphaSR := by norm_num [alphaSR]
theorem alphaSR_le_one : alphaSR ≤ 1 := by norm_num [alphaSR]

/-- Masse des salaires : somme exponentielle des salaires versés. -/
def masseSalaires (h : List MoisTravaille) : ℚ :=
  sommeExp alphaSR (h.map fun x => (x.salaire : ℚ))

/-- Masse d'activité : somme exponentielle des taux d'activité. -/
def masseActivite (h : List MoisTravaille) : ℚ :=
  sommeExp alphaSR (h.map (·.activite))

/-- **Salaire de référence** (P6), en centimes, non arrondi. Vaut `0` si le
contrat n'a connu aucune activité (division par 0 dans `ℚ`). -/
def salaireReference (h : List MoisTravaille) : ℚ := masseSalaires h / masseActivite h

theorem masseSalaires_snoc (h : List MoisTravaille) (x : MoisTravaille) :
    masseSalaires (h ++ [x]) = alphaSR * x.salaire + (1 - alphaSR) * masseSalaires h := by
  simp [masseSalaires, sommeExp_snoc, pasEMA]

theorem masseActivite_snoc (h : List MoisTravaille) (x : MoisTravaille) :
    masseActivite (h ++ [x]) = alphaSR * x.activite + (1 - alphaSR) * masseActivite h := by
  simp [masseActivite, sommeExp_snoc, pasEMA]

theorem masseSalaires_nonneg (h : List MoisTravaille) : 0 ≤ masseSalaires h :=
  foldl_pasEMA_nonneg alphaSR_pos.le alphaSR_le_one _
    (fun x hx => by obtain ⟨m, -, rfl⟩ := List.mem_map.1 hx; positivity) le_rfl

theorem masseActivite_nonneg (h : List MoisTravaille) : 0 ≤ masseActivite h :=
  foldl_pasEMA_nonneg alphaSR_pos.le alphaSR_le_one _
    (fun x hx => by obtain ⟨m, -, rfl⟩ := List.mem_map.1 hx; exact m.activite_nonneg) le_rfl

theorem salaireReference_nonneg (h : List MoisTravaille) : 0 ≤ salaireReference h :=
  div_nonneg (masseSalaires_nonneg h) (masseActivite_nonneg h)

/-- **Encadrement.** Si chaque salaire, ramené à temps plein, est compris entre
`m` et `M`, alors `SR` aussi : c'est une moyenne. -/
theorem salaireReference_encadrement {h : List MoisTravaille} {m M : ℚ}
    (hB : 0 < masseActivite h)
    (hm : ∀ x ∈ h, m * x.activite ≤ x.salaire) (hM : ∀ x ∈ h, (x.salaire : ℚ) ≤ M * x.activite) :
    m ≤ salaireReference h ∧ salaireReference h ≤ M := by
  have hα0 := alphaSR_pos.le
  have hα1 := alphaSR_le_one
  have up : masseSalaires h ≤ M * masseActivite h := by
    unfold masseSalaires masseActivite sommeExp
    rw [← foldl_pasEMA_mul, mul_zero]
    exact foldl_pasEMA_le hα0 hα1 h _ _ hM le_rfl
  have lo : m * masseActivite h ≤ masseSalaires h := by
    unfold masseSalaires masseActivite sommeExp
    rw [← foldl_pasEMA_mul, mul_zero]
    exact foldl_pasEMA_le hα0 hα1 h _ _ hm le_rfl
  unfold salaireReference
  exact ⟨(le_div_iff₀ hB).2 lo, (div_le_iff₀ hB).2 up⟩

/-- **Sensibilité au dernier salaire.** Modifier le dernier salaire de `Δ`
déplace `SR` d'exactement `α Δ / B`, où `B` est la masse d'activité. -/
theorem salaireReference_sensibilite (h : List MoisTravaille) (x : MoisTravaille) (Δ : ℕ) :
    salaireReference (h ++ [{ x with salaire := x.salaire + Δ }]) - salaireReference (h ++ [x])
      = alphaSR * Δ / masseActivite (h ++ [x]) := by
  have hB : masseActivite (h ++ [{ x with salaire := x.salaire + Δ }]) = masseActivite (h ++ [x]) := by
    simp only [masseActivite_snoc]
  unfold salaireReference
  rw [hB, div_sub_div_same, masseSalaires_snoc, masseSalaires_snoc]
  congr 1
  push_cast; ring

/-- Après au moins 60 mois à temps plein, la masse d'activité dépasse
`1 − (23/24)^60`, soit plus de 11/12. -/
theorem masseActivite_ge (p r : List MoisTravaille) (hr : ∀ x ∈ r, x.activite = 1) :
    1 - (1 - alphaSR) ^ r.length ≤ masseActivite (p ++ r) := by
  have hmap : r.map (·.activite) = List.replicate r.length 1 := by
    rw [List.eq_replicate_iff]
    simp only [List.length_map, List.mem_map, true_and]
    rintro _ ⟨x, hx, rfl⟩
    exact hr x hx
  unfold masseActivite sommeExp
  rw [List.map_append, List.foldl_append, hmap, foldl_pasEMA_replicate_one]
  have h0 : 0 ≤ (p.map (·.activite)).foldl (pasEMA alphaSR) 0 := masseActivite_nonneg p
  have h1 : 0 ≤ (1 - alphaSR) ^ r.length := pow_nonneg (by norm_num [alphaSR]) _
  nlinarith

theorem masseActivite_ge_onze_douziemes (p r : List MoisTravaille)
    (hr : ∀ x ∈ r, x.activite = 1) (hlen : 60 ≤ r.length) :
    11 / 12 ≤ masseActivite (p ++ r) := by
  have := masseActivite_ge p r hr
  have hp : (1 - alphaSR) ^ r.length ≤ (1 - alphaSR) ^ 60 :=
    pow_le_pow_of_le_one (by norm_num [alphaSR]) (by norm_num [alphaSR]) hlen
  have h60 : (1 - alphaSR) ^ 60 ≤ 1 / 12 := by norm_num [alphaSR]
  linarith

/-! ## Pas d'effet de seuil sur l'activité -/

/-- Un mois suspendu ne change pas le salaire de référence. -/
theorem salaireReference_suspendu (h : List MoisTravaille) :
    salaireReference (h ++ [.suspendu]) = salaireReference h := by
  simp only [salaireReference, masseSalaires_snoc, masseActivite_snoc, MoisTravaille.suspendu,
    Nat.cast_zero, mul_zero, zero_add]
  exact mul_div_mul_left _ _ (by norm_num [alphaSR])


/-- **Un mois quelconque, comparé à un mois suspendu.** Formule exacte de
l'écart entre `SR` après un mois `x` et `SR` après un mois suspendu, lorsque
le contrat a déjà connu une activité. -/
theorem salaireReference_mois (h : List MoisTravaille) (x : MoisTravaille)
    (h0 : masseActivite (h ++ [.suspendu]) ≠ 0) :
    salaireReference (h ++ [x]) - salaireReference (h ++ [.suspendu])
      = alphaSR * (x.salaire - x.activite * salaireReference (h ++ [.suspendu]))
          / masseActivite (h ++ [x]) := by
  have hB := masseActivite_nonneg h
  have hτ := x.activite_nonneg
  simp only [salaireReference, masseSalaires_snoc, masseActivite_snoc,
    MoisTravaille.suspendu] at h0 ⊢
  simp only [Nat.cast_zero, mul_zero, zero_add] at h0 ⊢
  have hBpos : 0 < masseActivite h := by
    rcases hB.lt_or_eq with hB' | hB'
    · exact hB'
    · exfalso; apply h0; rw [← hB']; ring
  have hα : 0 < 1 - alphaSR := by norm_num [alphaSR]
  have h1 : alphaSR * x.activite + (1 - alphaSR) * masseActivite h ≠ 0 := by
    have := alphaSR_pos; positivity
  field_simp
  ring

/-- **Continuité en l'activité.** L'écart avec un mois suspendu est au plus
`α (s + τ·SR) / B` : il tend vers 0 quand le salaire `s` et l'activité `τ`
du mois tendent vers 0. Un mois presque suspendu compte presque pas. -/
theorem salaireReference_mois_proche (h : List MoisTravaille) (x : MoisTravaille)
    (h0 : masseActivite (h ++ [.suspendu]) ≠ 0) :
    |salaireReference (h ++ [x]) - salaireReference (h ++ [.suspendu])|
      ≤ alphaSR * (x.salaire + x.activite * salaireReference (h ++ [.suspendu]))
          / masseActivite (h ++ [.suspendu]) := by
  rw [salaireReference_mois h x h0]
  set sr := salaireReference (h ++ [.suspendu])
  have hsr := salaireReference_nonneg (h ++ [.suspendu])
  have hτ := x.activite_nonneg
  have hs : (0 : ℚ) ≤ x.salaire := by positivity
  have hB0 : 0 < masseActivite (h ++ [.suspendu]) :=
    (masseActivite_nonneg _).lt_of_ne (Ne.symm h0)
  have hB1 : masseActivite (h ++ [.suspendu]) ≤ masseActivite (h ++ [x]) := by
    simp only [masseActivite_snoc, MoisTravaille.suspendu]
    have := alphaSR_pos
    nlinarith
  have hα := alphaSR_pos
  rw [abs_div, abs_of_pos (hB0.trans_le hB1)]
  have hnum : |alphaSR * (x.salaire - x.activite * sr)| ≤ alphaSR * (x.salaire + x.activite * sr) := by
    rw [abs_mul, abs_of_pos hα]
    apply mul_le_mul_of_nonneg_left _ hα.le
    rw [abs_le]
    constructor <;> nlinarith
  have hpos : 0 ≤ alphaSR * (x.salaire + x.activite * sr) :=
    mul_nonneg hα.le (add_nonneg hs (mul_nonneg hτ hsr))
  calc |alphaSR * (x.salaire - x.activite * sr)| / masseActivite (h ++ [x])
      ≤ alphaSR * (x.salaire + x.activite * sr) / masseActivite (h ++ [x]) := by
        have := masseActivite_nonneg (h ++ [x])
        gcongr
    _ ≤ alphaSR * (x.salaire + x.activite * sr) / masseActivite (h ++ [.suspendu]) := by
        gcongr

/-- **Mois partiel au prorata.** Un mois partiel payé au prorata du salaire de
référence (`s = τ·SR`) laisse `SR` exactement inchangé par rapport à un mois
suspendu : travailler quelques jours ne fait ni gagner ni perdre. -/
theorem salaireReference_prorata (h : List MoisTravaille) (x : MoisTravaille)
    (h0 : masseActivite (h ++ [.suspendu]) ≠ 0)
    (hx : (x.salaire : ℚ) = x.activite * salaireReference (h ++ [.suspendu])) :
    salaireReference (h ++ [x]) = salaireReference (h ++ [.suspendu]) := by
  have := salaireReference_mois h x h0
  rw [hx, sub_self, mul_zero, zero_div] at this
  linarith

end Prouvhommes
