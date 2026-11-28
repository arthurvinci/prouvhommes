import Prouvhommes.Hierarchie
import Prouvhommes.Rupture

/-!
# Congés payés (P13)

* Le salarié acquiert 20 jours ouvrés de congés payés par année de travail,
  à raison de 5/3 de jour par mois (`relative` : plus = plus favorable).
* Les congés ne peuvent pas être remplacés par une indemnité, sauf à la fin du
  contrat, pour les jours acquis et non pris (`absolue`, directive 2003/88,
  art. 7).

Le rachat est une disposition `absolue` de valeur nulle : un accord
d'entreprise ou un contrat peut bien stipuler un rachat, la stipulation est
sans effet. L'indemnité se lit sur l'état de la relation (`Rupture.lean`) :
`pas_de_rachat_conges` vaut pour toutes les stipulations et dans tout état
atteint avant la fin, `indemniteCompensatrice_fin` à la fin, quelle qu'en soit
la cause.
-/

namespace Prouvhommes

/-- Congés annuels, en jours ouvrés (P13) : relative, 20 jours. -/
def dispCongesAnnuels : Disposition ℕ :=
  { niveau := .relative, loi := 20, sens := .plusGrand }

/-- Jours de congés acquis après `mois` mois de travail dans l'année, pour un
droit annuel de `droitAnnuel` jours. -/
def congesAcquis (droitAnnuel : ℕ) (mois : Mois) : ℚ :=
  (droitAnnuel : ℚ) * (min mois 12 : ℕ) / 12

/-- Avec le droit légal, 5/3 de jour par mois. -/
theorem congesAcquis_legal {mois : Mois} (h : mois ≤ 12) :
    congesAcquis dispCongesAnnuels.loi mois = 5 / 3 * mois := by
  simp only [congesAcquis, dispCongesAnnuels, min_eq_left h]
  push_cast; ring

/-- Une année complète donne 20 jours ouvrés, soit 4 semaines. -/
theorem congesAcquis_annee : congesAcquis dispCongesAnnuels.loi 12 = 20 := by
  norm_num [congesAcquis, dispCongesAnnuels]

/-- Le droit annuel n'est jamais inférieur à 20 jours. -/
theorem conges_ge_legal (st : Stipulations ℕ) : 20 ≤ applicable dispCongesAnnuels st :=
  applicable_relative_plancher (d := dispCongesAnnuels) rfl st

/-- Rachat des congés pendant le contrat (P13), en fraction du salaire
journalier par jour racheté : absolue, nul. -/
def dispRachatConges : Disposition ℚ :=
  { niveau := .absolue, loi := 0, sens := .plusGrand }

/-- Indemnité versée pour `joursNonPris` jours de congés acquis et non pris,
dans l'état `s` de la relation, compte tenu des stipulations `st` sur le
rachat. À la fin du contrat, les jours sont indemnisés au salaire journalier ;
avant, ils ne peuvent l'être qu'au taux de rachat applicable. -/
def indemniteCompensatrice (st : Stipulations ℚ) (s : Etat)
    (joursNonPris salaireJournalier : ℚ) : ℚ :=
  match s.phase with
  | .termine .. => joursNonPris * salaireJournalier
  | _ => applicable dispRachatConges st * joursNonPris * salaireJournalier

/-- **Pas de rachat des congés.** Quels que soient l'accord d'entreprise et le
contrat, les délais de préavis et la suite d'événements, tant que la relation
n'est pas terminée, aucun jour de congé n'est remplacé par une indemnité. -/
theorem pas_de_rachat_conges {I : Interpretation} (st : Stipulations ℚ) (k : Contrat)
    (D : Delais) (evs : List (Evenement I)) (h : EnCours (execute k D evs))
    (joursNonPris salaireJournalier : ℚ) :
    indemniteCompensatrice st (execute k D evs) joursNonPris salaireJournalier = 0 := by
  unfold indemniteCompensatrice
  split
  · rename_i c j hc; exact absurd hc (h c j)
  · rw [applicable_absolue (d := dispRachatConges) rfl]
    simp [dispRachatConges]

/-- À la fin du contrat, quelle qu'en soit la cause et quelles que soient les
stipulations, les jours acquis et non pris sont indemnisés en entier. -/
theorem indemniteCompensatrice_fin (st : Stipulations ℚ) {s : Etat} {c : CauseFin} {j : Jour}
    (hs : s.phase = .termine c j) (joursNonPris salaireJournalier : ℚ) :
    indemniteCompensatrice st s joursNonPris salaireJournalier
      = joursNonPris * salaireJournalier := by
  simp [indemniteCompensatrice, hs]

end Prouvhommes
