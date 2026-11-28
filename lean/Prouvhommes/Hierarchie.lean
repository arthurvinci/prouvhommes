import Prouvhommes.Contrat
import Prouvhommes.Preavis
import Prouvhommes.Indemnite

/-!
# Hiérarchie des normes (M4, P15)

Une disposition chiffrée du code a une valeur légale, un niveau d'impérativité
et un **sens favorable** au salarié (plus grand ou plus petit). Un accord
d'entreprise et le contrat individuel peuvent chacun stipuler une autre valeur.
La valeur applicable se résout ainsi :

* `absolue` : la loi, toujours ;
* `relative` : la valeur la plus favorable au salarié parmi la loi, l'accord et
  le contrat (principe de faveur) ;
* `dispositive` : l'accord s'il existe, sinon le contrat, sinon la loi (P15).
  Une limite absolue éventuelle borne le résultat du côté défavorable : une
  stipulation qui la dépasse est réduite à cette limite.

Résultats généraux : `applicable_absolue`, `applicable_relative_plancher`,
`applicable_relative_faveur`, `applicable_relative_sans_effet`,
`applicable_relative_source`, `applicable_dispositive_accord`,
`applicable_dispositive_limite`. On les instancie ensuite sur les dispositions
du code (préavis, essai, indemnité).
-/

namespace Prouvhommes

/-! ## Sens favorable -/

/-- Le sens dans lequel une valeur est plus favorable au salarié. -/
inductive Sens
  /-- Plus la valeur est grande, mieux c'est (préavis dû par l'employeur, indemnité…). -/
  | plusGrand
  /-- Plus la valeur est petite, mieux c'est (préavis dû par le salarié, essai…). -/
  | plusPetit
  deriving DecidableEq, Repr

namespace Sens

variable {α : Type*} [LinearOrder α]

/-- `s.auMoins a b` : `b` est au moins aussi favorable au salarié que `a`. -/
def auMoins : Sens → α → α → Prop
  | plusGrand, a, b => a ≤ b
  | plusPetit, a, b => b ≤ a

/-- La plus favorable des deux valeurs. -/
def meilleur : Sens → α → α → α
  | plusGrand, a, b => max a b
  | plusPetit, a, b => min a b

theorem auMoins_refl (s : Sens) (a : α) : s.auMoins a a := by
  cases s <;> simp [auMoins]

theorem auMoins_trans {s : Sens} {a b c : α} (h1 : s.auMoins a b) (h2 : s.auMoins b c) :
    s.auMoins a c := by
  cases s <;> simp only [auMoins] at * <;> exact le_trans (by assumption) (by assumption)

theorem auMoins_meilleur_left (s : Sens) (a b : α) : s.auMoins a (s.meilleur a b) := by
  cases s <;> simp [auMoins, meilleur]

theorem auMoins_meilleur_right (s : Sens) (a b : α) : s.auMoins b (s.meilleur a b) := by
  cases s <;> simp [auMoins, meilleur]

theorem meilleur_eq_or (s : Sens) (a b : α) : s.meilleur a b = a ∨ s.meilleur a b = b := by
  cases s
  · exact max_choice a b
  · exact min_choice a b

/-- Si `b` n'est pas plus favorable que `a`, la meilleure des deux est `a`. -/
theorem meilleur_of_auMoins {s : Sens} {a b : α} (h : s.auMoins b a) : s.meilleur a b = a := by
  cases s <;> simp only [auMoins, meilleur] at * <;> simp [h]

theorem meilleur_auMoins {s : Sens} {a b c : α} (ha : s.auMoins a c) (hb : s.auMoins b c) :
    s.auMoins (s.meilleur a b) c := by
  cases s <;> simp only [auMoins, meilleur] at * <;> simp [ha, hb]

end Sens

/-! ## Dispositions et stipulations -/

/-- Les stipulations conventionnelles sur une disposition : accord d'entreprise
et contrat individuel, chacun facultatif. -/
structure Stipulations (α : Type*) where
  accord : Option α := none
  contrat : Option α := none

/-- Une disposition chiffrée du code. -/
structure Disposition (α : Type*) where
  niveau : Imperativite
  /-- Valeur fixée par le code. -/
  loi : α
  /-- Sens favorable au salarié. -/
  sens : Sens
  /-- Limite absolue d'une disposition dispositive, du côté défavorable. -/
  limite : Option α := none

variable {α : Type*} [LinearOrder α]

/-- `v` amélioré, le cas échéant, par une stipulation `o`. -/
def meilleurOpt (s : Sens) (v : α) : Option α → α
  | none => v
  | some x => s.meilleur v x

theorem auMoins_meilleurOpt (s : Sens) (v : α) (o : Option α) : s.auMoins v (meilleurOpt s v o) := by
  cases o
  · exact Sens.auMoins_refl s v
  · exact Sens.auMoins_meilleur_left s v _

/-- **Valeur applicable** d'une disposition, compte tenu des stipulations (M4, P15). -/
def applicable (d : Disposition α) (st : Stipulations α) : α :=
  match d.niveau with
  | .absolue => d.loi
  | .relative => meilleurOpt d.sens (meilleurOpt d.sens d.loi st.accord) st.contrat
  | .dispositive => meilleurOpt d.sens (st.accord.getD (st.contrat.getD d.loi)) d.limite

/-! ## Disposition absolue -/

/-- Une disposition absolue ne souffre aucune dérogation. -/
theorem applicable_absolue {d : Disposition α} (h : d.niveau = .absolue) (st : Stipulations α) :
    applicable d st = d.loi := by
  simp [applicable, h]

/-! ## Disposition relative -/

/-- Une disposition relative est un plancher : la valeur applicable est toujours
au moins aussi favorable au salarié que la loi. -/
theorem applicable_relative_plancher {d : Disposition α} (h : d.niveau = .relative)
    (st : Stipulations α) : d.sens.auMoins d.loi (applicable d st) := by
  simp only [applicable, h]
  exact Sens.auMoins_trans (auMoins_meilleurOpt _ _ _) (auMoins_meilleurOpt _ _ _)

/-- **Principe de faveur.** La valeur applicable est au moins aussi favorable
que chacune des stipulations. -/
theorem applicable_relative_faveur {d : Disposition α} (h : d.niveau = .relative)
    (st : Stipulations α) :
    (∀ a, st.accord = some a → d.sens.auMoins a (applicable d st)) ∧
      (∀ c, st.contrat = some c → d.sens.auMoins c (applicable d st)) := by
  simp only [applicable, h]
  constructor
  · intro a ha
    rw [ha]
    exact Sens.auMoins_trans (Sens.auMoins_meilleur_right _ _ _) (auMoins_meilleurOpt _ _ _)
  · intro c hc
    rw [hc]
    exact Sens.auMoins_meilleur_right _ _ _

/-- La valeur applicable est toujours l'une des valeurs en présence : le code
n'en invente pas. -/
theorem applicable_relative_source {d : Disposition α} (h : d.niveau = .relative)
    (st : Stipulations α) :
    applicable d st = d.loi ∨ st.accord = some (applicable d st) ∨
      st.contrat = some (applicable d st) := by
  simp only [applicable, h]
  rcases hc : st.contrat with _ | c <;> rcases ha : st.accord with _ | a <;>
    simp only [meilleurOpt]
  · exact Or.inl trivial
  · rcases Sens.meilleur_eq_or d.sens d.loi a with e | e <;> rw [e] <;> simp
  · rcases Sens.meilleur_eq_or d.sens d.loi c with e | e <;> rw [e] <;> simp
  · rcases Sens.meilleur_eq_or d.sens (d.sens.meilleur d.loi a) c with e | e
    · rw [e]
      rcases Sens.meilleur_eq_or d.sens d.loi a with e' | e' <;> rw [e'] <;> simp
    · rw [e]; simp

/-- Une clause du contrat qui n'améliore pas ce que prévoient déjà la loi et
l'accord est sans effet. -/
theorem applicable_relative_sans_effet {d : Disposition α} (h : d.niveau = .relative)
    (accord : Option α) {c : α}
    (hc : d.sens.auMoins c (applicable d { accord := accord })) :
    applicable d { accord := accord, contrat := some c } = applicable d { accord := accord } := by
  simp only [applicable, h] at hc ⊢
  exact Sens.meilleur_of_auMoins hc

/-- En particulier, une clause moins favorable que la loi est sans effet. -/
theorem applicable_relative_clause_defavorable {d : Disposition α} (h : d.niveau = .relative)
    (accord : Option α) {c : α} (hc : d.sens.auMoins c d.loi) :
    applicable d { accord := accord, contrat := some c } = applicable d { accord := accord } :=
  applicable_relative_sans_effet h accord
    (Sens.auMoins_trans hc (applicable_relative_plancher h _))

/-! ## Disposition dispositive -/

/-- **Primauté de l'accord d'entreprise (P15).** S'il existe, l'accord s'applique,
quel que soit le contrat, dans la limite absolue éventuelle. -/
theorem applicable_dispositive_accord {d : Disposition α} (h : d.niveau = .dispositive)
    {a : α} (contrat : Option α) :
    applicable d { accord := some a, contrat := contrat } = meilleurOpt d.sens a d.limite := by
  simp [applicable, h]

/-- À défaut d'accord, le contrat s'applique. -/
theorem applicable_dispositive_contrat {d : Disposition α} (h : d.niveau = .dispositive)
    {c : α} : applicable d { contrat := some c } = meilleurOpt d.sens c d.limite := by
  simp [applicable, h]

/-- À défaut de toute stipulation, la loi s'applique. -/
theorem applicable_dispositive_loi {d : Disposition α} (h : d.niveau = .dispositive) :
    applicable d ({} : Stipulations α) = meilleurOpt d.sens d.loi d.limite := by
  simp [applicable, h]

/-- La limite absolue d'une disposition dispositive n'est jamais dépassée au
détriment du salarié. -/
theorem applicable_dispositive_limite {d : Disposition α} (h : d.niveau = .dispositive)
    {l : α} (hl : d.limite = some l) (st : Stipulations α) :
    d.sens.auMoins l (applicable d st) := by
  simp only [applicable, h, hl, meilleurOpt]
  exact Sens.auMoins_meilleur_right _ _ _

/-! ## Les dispositions du code -/

/-- Préavis dû par l'employeur, pour une notification reçue au jour `j`
(P3, P4) : relative, plus long = plus favorable. Le même pendant l'essai et
après. -/
def dispPreavisEmployeur (j : Jour) : Disposition ℕ :=
  { niveau := .relative, loi := preavis j, sens := .plusGrand }

/-- Préavis dû par le salarié (P3, P4) : relative, plus court = plus favorable. -/
def dispPreavisSalarie (j : Jour) : Disposition ℕ :=
  { niveau := .relative, loi := preavis j, sens := .plusPetit }

/-- Durée de l'essai (P3) : dispositive, 30 jours à défaut de stipulation,
limite absolue de 90 jours. -/
def dispDureeEssai : Disposition ℕ :=
  { niveau := .dispositive, loi := dureeEssaiParDefaut, sens := .plusPetit,
    limite := some dureeEssaiMax }

/-- Indemnité de rupture (P6) : relative, plus grande = plus favorable. -/
def dispIndemnite (sr : ℚ) (m : Mois) : Disposition ℕ :=
  { niveau := .relative, loi := indemnite sr m, sens := .plusGrand }

/-- Le préavis dû par l'employeur n'est jamais plus court que le préavis légal. -/
theorem preavisEmployeur_ge_legal (j : Jour) (st : Stipulations ℕ) :
    preavis j ≤ applicable (dispPreavisEmployeur j) st :=
  applicable_relative_plancher (d := dispPreavisEmployeur j) rfl st

/-- Le préavis dû par le salarié n'est jamais plus long que le préavis légal. -/
theorem preavisSalarie_le_legal (j : Jour) (st : Stipulations ℕ) :
    applicable (dispPreavisSalarie j) st ≤ preavis j :=
  applicable_relative_plancher (d := dispPreavisSalarie j) rfl st

/-- Une clause qui allongerait le préavis du salarié démissionnaire est sans effet. -/
theorem preavisSalarie_clause_allongee (j : Jour) (accord : Option ℕ) {c : ℕ}
    (hc : preavis j ≤ c) :
    applicable (dispPreavisSalarie j) { accord := accord, contrat := some c }
      = applicable (dispPreavisSalarie j) { accord := accord } :=
  applicable_relative_clause_defavorable (d := dispPreavisSalarie j) rfl accord hc

/-- L'essai ne dépasse jamais 90 jours, quelles que soient les stipulations. -/
theorem dureeEssai_le_max (st : Stipulations ℕ) :
    applicable dispDureeEssai st ≤ dureeEssaiMax :=
  applicable_dispositive_limite (d := dispDureeEssai) rfl rfl st

/-- L'accord d'entreprise fixe l'essai, même si le contrat dit autre chose (P15). -/
theorem dureeEssai_accord {a : ℕ} (ha : a ≤ dureeEssaiMax) (contrat : Option ℕ) :
    applicable dispDureeEssai { accord := some a, contrat := contrat } = a := by
  rw [applicable_dispositive_accord (d := dispDureeEssai) rfl]
  simp [meilleurOpt, dispDureeEssai, Sens.meilleur, ha]

/-- L'indemnité de rupture n'est jamais inférieure à l'indemnité légale. -/
theorem indemnite_ge_legal (sr : ℚ) (m : Mois) (st : Stipulations ℕ) :
    indemnite sr m ≤ applicable (dispIndemnite sr m) st :=
  applicable_relative_plancher (d := dispIndemnite sr m) rfl st

/-- Contrat dont l'essai est fixé par les stipulations, dans la limite légale. -/
def Contrat.avecEssai (k : Contrat) (st : Stipulations ℕ) : Contrat :=
  { k with dureeEssai := applicable dispDureeEssai st, essai_le_max := dureeEssai_le_max st }

/-! ## Exemples -/

/-- Accord à 60 jours, contrat à 15 : l'accord s'impose (P15). -/
example : applicable dispDureeEssai { accord := some 60, contrat := some 15 } = 60 := by
  decide

/-- Contrat à 120 jours : réduit à 90. -/
example : applicable dispDureeEssai { contrat := some 120 } = 90 := by decide

/-- Préavis de l'employeur au jour 800 : 64 jours légaux, accord à 75, contrat
à 45 : le plus favorable, 75. -/
example : applicable (dispPreavisEmployeur 800) { accord := some 75, contrat := some 45 } = 75 := by
  decide

/-- Préavis du salarié au jour 800 : 64 jours légaux, contrat à 90 (sans
effet), accord à 30 : 30. -/
example : applicable (dispPreavisSalarie 800) { accord := some 30, contrat := some 90 } = 30 := by
  decide

end Prouvhommes
