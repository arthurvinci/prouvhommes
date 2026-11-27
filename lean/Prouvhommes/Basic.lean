import Mathlib

/-!
# Prouv'hommes — définitions de base

Premières briques de la formalisation : niveaux d'impérativité (méta-principe M4)
et préavis légal (principe P4).
-/

namespace Prouvhommes

/-- Niveau d'impérativité d'une disposition (M4).
* `absolue` : non dérogeable ;
* `relative` : dérogeable seulement en faveur du salarié ;
* `dispositive` : librement dérogeable. -/
inductive Imperativite
  | absolue
  | relative
  | dispositive
  deriving DecidableEq, Repr

/-- Préavis légal en jours, selon l'ancienneté en années révolues (P4) :
30 jours la première année, 60 jours de la 2ᵉ à la 9ᵉ, 90 jours ensuite. -/
def preavisLegal (annees : ℕ) : ℕ :=
  if annees = 0 then 30 else if annees ≤ 8 then 60 else 90

/-- Le préavis légal n'est jamais inférieur à 30 jours. -/
theorem preavisLegal_ge_30 (n : ℕ) : 30 ≤ preavisLegal n := by
  unfold preavisLegal
  split_ifs <;> omega

/-- Le préavis légal croît avec l'ancienneté. -/
theorem preavisLegal_monotone : Monotone preavisLegal := by
  intro a b hab
  unfold preavisLegal
  split_ifs <;> omega

end Prouvhommes
