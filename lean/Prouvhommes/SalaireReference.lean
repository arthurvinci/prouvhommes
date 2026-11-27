import Prouvhommes.Basic

/-!
# Salaire de référence (P6)

Le salaire de référence `SR` est une moyenne mobile exponentielle (EMA) des
salaires mensuels, de coefficient `α = 1/24`, calculée sur les 60 derniers mois
payés.

* L'historique est la liste des salaires mensuels bruts, en centimes, du plus
  ancien au plus récent.
* Un mois sans salaire (valeur `0`) est exclu de la fenêtre, qui remonte d'autant.
* Récurrence : `e₁ = s₁`, puis `eₖ = α·sₖ + (1 − α)·eₖ₋₁`.

Résultats principaux :
* `ema_encadrement` : l'EMA reste entre le plus petit et le plus grand salaire ;
* `ema_sensibilite_position` : modifier un mois de `Δ` déplace l'EMA de
  `α(1 − α)^k · Δ`, où `k` est le nombre de mois postérieurs ;
* `salaireReference_sensibilite` : modifier le dernier salaire de `Δ` déplace
  `SR` d'exactement `Δ / 24`, dès qu'il existe au moins un autre mois payé.
-/

namespace Prouvhommes

/-! ## Moyenne mobile exponentielle -/

/-- Un pas de la récurrence : `e ↦ α·x + (1 − α)·e`. -/
def pasEMA (α e x : ℚ) : ℚ := α * x + (1 - α) * e

/-- Moyenne mobile exponentielle d'une liste (du plus ancien au plus récent),
initialisée sur le premier élément. Vaut `0` sur la liste vide. -/
def ema (α : ℚ) : List ℚ → ℚ
  | [] => 0
  | s :: reste => reste.foldl (pasEMA α) s

/-- La récurrence est affine en sa valeur initiale. -/
theorem foldl_pasEMA_affine (α : ℚ) (r : List ℚ) (e : ℚ) :
    r.foldl (pasEMA α) e = r.foldl (pasEMA α) 0 + (1 - α) ^ r.length * e := by
  induction r generalizing e with
  | nil => simp
  | cons y r ih =>
    simp only [List.foldl_cons, List.length_cons]
    rw [ih (pasEMA α e y), ih (pasEMA α 0 y)]
    unfold pasEMA; ring

/-- Ajouter un mois à la fin : `ema (l ++ [x]) = α·x + (1 − α)·ema l`. -/
theorem ema_snoc (α : ℚ) {l : List ℚ} (hl : l ≠ []) (x : ℚ) :
    ema α (l ++ [x]) = pasEMA α (ema α l) x := by
  obtain ⟨s, r, rfl⟩ := List.exists_cons_of_ne_nil hl
  simp [ema, List.foldl_append]

/-- Découpage autour d'un mois `z` : l'EMA de `l ++ z :: r` reprend la
récurrence à partir de `pasEMA (ema l) z`. -/
theorem ema_append_cons (α : ℚ) {l : List ℚ} (hl : l ≠ []) (z : ℚ) (r : List ℚ) :
    ema α (l ++ z :: r) = r.foldl (pasEMA α) (pasEMA α (ema α l) z) := by
  obtain ⟨s, l', rfl⟩ := List.exists_cons_of_ne_nil hl
  simp [ema, List.foldl_append]

/-- **Sensibilité à un mois quelconque (sauf le premier).** Ajouter `Δ` au mois
suivi de `r.length` mois déplace l'EMA de `α (1 − α)^(r.length) Δ`. -/
theorem ema_sensibilite_position (α : ℚ) {l : List ℚ} (hl : l ≠ []) (x Δ : ℚ)
    (r : List ℚ) :
    ema α (l ++ (x + Δ) :: r) - ema α (l ++ x :: r) = α * (1 - α) ^ r.length * Δ := by
  rw [ema_append_cons α hl, ema_append_cons α hl, foldl_pasEMA_affine α r,
    foldl_pasEMA_affine α r (pasEMA α (ema α l) x)]
  unfold pasEMA; ring

/-- Corollaire : pour `α ∈ [0, 1]` et `Δ ≥ 0`, le déplacement est compris entre
`0` et `α Δ`. -/
theorem ema_sensibilite_le {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) {l : List ℚ}
    (hl : l ≠ []) (x : ℚ) {Δ : ℚ} (hΔ : 0 ≤ Δ) (r : List ℚ) :
    0 ≤ ema α (l ++ (x + Δ) :: r) - ema α (l ++ x :: r) ∧
      ema α (l ++ (x + Δ) :: r) - ema α (l ++ x :: r) ≤ α * Δ := by
  rw [ema_sensibilite_position α hl]
  have hp0 : 0 ≤ (1 - α) ^ r.length := pow_nonneg (by linarith) _
  have hp1 : (1 - α) ^ r.length ≤ 1 := pow_le_one₀ (by linarith) (by linarith)
  refine ⟨by positivity, ?_⟩
  have : α * (1 - α) ^ r.length * Δ = α * Δ * (1 - α) ^ r.length := by ring
  rw [this]
  exact mul_le_of_le_one_right (mul_nonneg hα0 hΔ) hp1

/-- Le dernier mois : déplacement d'exactement `α Δ`. -/
theorem ema_sensibilite_dernier (α : ℚ) {l : List ℚ} (hl : l ≠ []) (x Δ : ℚ) :
    ema α (l ++ [x + Δ]) - ema α (l ++ [x]) = α * Δ := by
  have := ema_sensibilite_position α hl x Δ []
  simpa using this

/-- La récurrence reste dans tout intervalle `[m, M]` qui contient la valeur
initiale et tous les termes. -/
theorem foldl_pasEMA_mem_Icc {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) {m M : ℚ}
    (r : List ℚ) (hr : ∀ x ∈ r, m ≤ x ∧ x ≤ M) {e : ℚ} (he : m ≤ e ∧ e ≤ M) :
    m ≤ r.foldl (pasEMA α) e ∧ r.foldl (pasEMA α) e ≤ M := by
  induction r generalizing e with
  | nil => simpa using he
  | cons y r ih =>
    simp only [List.foldl_cons]
    apply ih (fun x hx => hr x (List.mem_cons_of_mem _ hx))
    obtain ⟨hy1, hy2⟩ := hr y List.mem_cons_self
    unfold pasEMA
    constructor <;> nlinarith [mul_le_mul_of_nonneg_left hy1 hα0,
      mul_le_mul_of_nonneg_left hy2 hα0,
      mul_le_mul_of_nonneg_left he.1 (show 0 ≤ 1 - α by linarith),
      mul_le_mul_of_nonneg_left he.2 (show 0 ≤ 1 - α by linarith)]

/-- **Encadrement.** L'EMA d'une liste non vide est comprise entre tout minorant
et tout majorant de ses termes : c'est une moyenne pondérée. -/
theorem ema_encadrement {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) {l : List ℚ}
    (hl : l ≠ []) {m M : ℚ} (h : ∀ x ∈ l, m ≤ x ∧ x ≤ M) :
    m ≤ ema α l ∧ ema α l ≤ M := by
  obtain ⟨s, r, rfl⟩ := List.exists_cons_of_ne_nil hl
  exact foldl_pasEMA_mem_Icc hα0 hα1 r (fun x hx => h x (List.mem_cons_of_mem _ hx))
    (h s List.mem_cons_self)

/-- L'EMA d'une liste de termes positifs ou nuls est positive ou nulle. -/
theorem ema_nonneg {α : ℚ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) {l : List ℚ}
    (h : ∀ x ∈ l, 0 ≤ x) : 0 ≤ ema α l := by
  cases l with
  | nil => simp [ema]
  | cons s r =>
    simp only [ema]
    have key : ∀ (r : List ℚ), (∀ x ∈ r, 0 ≤ x) → ∀ e, 0 ≤ e → 0 ≤ r.foldl (pasEMA α) e := by
      intro r
      induction r with
      | nil => intro _ e he; simpa using he
      | cons y r ih =>
        intro hr e he
        simp only [List.foldl_cons]
        apply ih (fun x hx => hr x (List.mem_cons_of_mem _ hx))
        have hy := hr y List.mem_cons_self
        unfold pasEMA
        have : 0 ≤ 1 - α := by linarith
        positivity
    exact key r (fun x hx => h x (List.mem_cons_of_mem _ hx)) s (h s List.mem_cons_self)

/-! ## Fenêtre et salaire de référence -/

/-- Coefficient de l'EMA (P6). -/
def alphaSR : ℚ := 1 / 24

/-- Taille maximale de la fenêtre, en mois payés (P6). -/
def tailleFenetre : ℕ := 60

/-- Les mois payés de l'historique (les mois à salaire nul sont exclus). -/
def moisPayes (h : List Centimes) : List Centimes := h.filter (· ≠ 0)

/-- Conversion d'une liste de montants en rationnels. -/
def versQ (l : List Centimes) : List ℚ := List.map (fun s : ℕ => (s : ℚ)) l

/-- La fenêtre : les 60 derniers mois payés au plus, convertis en rationnels. -/
def fenetre (h : List Centimes) : List ℚ :=
  versQ ((moisPayes h).drop ((moisPayes h).length - tailleFenetre))

/-- **Salaire de référence** (P6), en centimes, non arrondi. -/
def salaireReference (h : List Centimes) : ℚ := ema alphaSR (fenetre h)

theorem fenetre_length_le (h : List Centimes) : (fenetre h).length ≤ tailleFenetre := by
  simp only [fenetre, versQ, List.length_map, List.length_drop]
  omega

/-- Un mois payé ajouté à la fin entre dans la fenêtre, à la dernière place ;
le reste de la fenêtre ne dépend pas de son montant. -/
theorem fenetre_snoc (h : List Centimes) {x : Centimes} (hx : x ≠ 0) :
    fenetre (h ++ [x]) =
      versQ ((moisPayes h).drop ((moisPayes h).length + 1 - tailleFenetre)) ++ [(x : ℚ)] := by
  have hp : moisPayes (h ++ [x]) = moisPayes h ++ [x] := by
    simp [moisPayes, List.filter_append, hx]
  simp only [fenetre, hp, List.length_append, List.length_singleton]
  rw [List.drop_append_of_le_length (by unfold tailleFenetre; omega)]
  simp [versQ]

theorem salaireReference_nonneg (h : List Centimes) : 0 ≤ salaireReference h := by
  refine ema_nonneg (by norm_num [alphaSR]) (by norm_num [alphaSR]) (fun x hx => ?_)
  simp only [fenetre, versQ, List.mem_map] at hx
  obtain ⟨s, -, rfl⟩ := hx
  positivity

/-- `SR` ne dépasse jamais un majorant de tous les salaires de l'historique. -/
theorem salaireReference_le {h : List Centimes} {M : ℚ} (hM0 : 0 ≤ M)
    (hM : ∀ s ∈ h, (s : ℚ) ≤ M) : salaireReference h ≤ M := by
  unfold salaireReference
  by_cases hw : fenetre h = []
  · simp [hw, ema, hM0]
  · refine (ema_encadrement (by norm_num [alphaSR]) (by norm_num [alphaSR]) hw
      (m := 0) (M := M) (fun x hx => ?_)).2
    simp only [fenetre, versQ, List.mem_map] at hx
    obtain ⟨s, hs, rfl⟩ := hx
    exact ⟨by positivity, hM s (List.mem_of_mem_filter (List.mem_of_mem_drop hs))⟩

/-- **Anti-manipulation** (P6). S'il existe au moins un mois payé avant le
dernier, augmenter (ou baisser) le dernier salaire de `Δ` déplace `SR`
d'exactement `Δ / 24`. -/
theorem salaireReference_sensibilite (h : List Centimes) (hh : ∃ s ∈ h, s ≠ 0)
    {x : Centimes} (hx : x ≠ 0) (Δ : ℕ) :
    salaireReference (h ++ [x + Δ]) - salaireReference (h ++ [x]) = Δ / 24 := by
  have hpos : 0 < (moisPayes h).length := by
    obtain ⟨s, hs, hs0⟩ := hh
    exact List.length_pos_of_mem (List.mem_filter.2 ⟨hs, by simpa using hs0⟩)
  have hw : versQ ((moisPayes h).drop ((moisPayes h).length + 1 - tailleFenetre)) ≠ [] := by
    simp only [versQ, ne_eq, List.map_eq_nil_iff, List.drop_eq_nil_iff]
    simp only [tailleFenetre]; omega
  unfold salaireReference
  rw [fenetre_snoc h hx, fenetre_snoc h (x := x + Δ) (by simp [hx])]
  have := ema_sensibilite_dernier alphaSR hw (x : ℚ) (Δ : ℚ)
  push_cast
  rw [this]
  norm_num [alphaSR]
  ring

end Prouvhommes
