import Prouvhommes.Basic

/-!
# Préavis (P3, P4)

* Préavis de rupture d'essai : 7 jours (P3).
* Préavis ordinaire : 30, 60 ou 90 jours selon l'ancienneté (P4).

Tous les préavis sont comptés en jours (M1) et courent à partir du lendemain
de la réception de la notification.

L'ancienneté est comptée en jours depuis le début du contrat ; une année
révolue vaut 365 jours.
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

/-- Préavis de rupture pendant la période d'essai, en jours (P3). -/
def preavisEssai : ℕ := 7

/-- Années révolues d'ancienneté au jour `j` (jour 0 = début du contrat). -/
def anneesRevolues (j : Jour) : ℕ := j / 365

/-- Mois révolus d'ancienneté au jour `j`, cohérents avec les années :
`moisRevolus j / 12 = anneesRevolues j`. -/
def moisRevolus (j : Jour) : Mois := 12 * j / 365

theorem moisRevolus_div_douze (j : Jour) : moisRevolus j / 12 = anneesRevolues j := by
  unfold moisRevolus anneesRevolues
  omega

/-- Préavis ordinaire, en jours, pour une notification reçue au jour `j` (P4). -/
def preavisOrdinaire (j : Jour) : ℕ := preavisLegal (anneesRevolues j)

theorem preavisOrdinaire_ge_30 (j : Jour) : 30 ≤ preavisOrdinaire j :=
  preavisLegal_ge_30 _

end Prouvhommes
