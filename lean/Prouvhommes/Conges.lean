import Prouvhommes.Hierarchie

/-!
# Congés payés (P13)

* Le salarié acquiert 20 jours ouvrés de congés payés par année de travail,
  à raison de 5/3 de jour par mois (`relative` : plus = plus favorable).
* Les congés ne peuvent pas être remplacés par une indemnité, sauf à la fin du
  contrat, pour les jours acquis et non pris (`absolue`, directive 2003/88,
  art. 7).
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

/-- Indemnité compensatrice des congés acquis et non pris, en centimes : due
seulement à la fin du contrat. -/
def indemniteCompensatrice (finDeContrat : Bool) (joursNonPris salaireJournalier : ℚ) : ℚ :=
  if finDeContrat then joursNonPris * salaireJournalier else 0

/-- **Pas de rachat des congés** pendant le contrat. -/
theorem pas_de_rachat_conges (joursNonPris salaireJournalier : ℚ) :
    indemniteCompensatrice false joursNonPris salaireJournalier = 0 := rfl

/-- À la fin du contrat, les jours non pris sont indemnisés. -/
theorem indemniteCompensatrice_fin (joursNonPris salaireJournalier : ℚ) :
    indemniteCompensatrice true joursNonPris salaireJournalier
      = joursNonPris * salaireJournalier := rfl

end Prouvhommes
