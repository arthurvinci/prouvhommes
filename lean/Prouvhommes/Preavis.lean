import Prouvhommes.Basic

/-!
# Préavis (P3, P4)

Préavis ordinaire selon l'ancienneté (P4). Le préavis de rupture d'essai (P3)
viendra en phase 3.
-/

namespace Prouvhommes

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
