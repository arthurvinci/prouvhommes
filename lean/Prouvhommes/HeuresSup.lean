import Prouvhommes.TempsDeTravail

/-!
# Heures supplémentaires (P12)

Il n'y a pas de durée légale (P10) : les heures supplémentaires sont les
minutes de travail effectif qui dépassent, dans une semaine civile, la durée
hebdomadaire convenue au contrat.

Elles sont payées au taux horaire du contrat, majoré de 10 % à défaut d'accord
ou de clause contraire (`dispositive`). La majoration ne peut pas être
négative : une heure supplémentaire est payée au moins au taux normal.
-/

namespace Prouvhommes

/-- Minutes de travail de la semaine `k` au-delà de la durée hebdomadaire
convenue `dureeHebdo` (en minutes). -/
def heuresSup (dureeHebdo : ℕ) (p : Planning) (k : ℕ) : ℕ :=
  travailDans p (k * minutesSemaine) ((k + 1) * minutesSemaine) - dureeHebdo

/-- Majoration des heures supplémentaires (P12) : dispositive, 10 % à défaut de
stipulation, limite absolue 0 % (pas de minoration). -/
def dispMajorationHS : Disposition ℚ :=
  { niveau := .dispositive, loi := 1 / 10, sens := .plusGrand, limite := some 0 }

/-- Taux horaire du contrat, en centimes par heure : salaire mensuel divisé par
la durée mensuelle convenue (`dureeHebdo × 52 / 12`). -/
def tauxHoraire (k : Contrat) : ℚ :=
  k.salaireMensuel * 12 * 60 / (52 * k.dureeHebdo)

/-- Paiement de `minutes` d'heures supplémentaires, en centimes (non arrondi). -/
def paiementHS (k : Contrat) (st : Stipulations ℚ) (minutes : ℕ) : ℚ :=
  (minutes / 60 : ℚ) * tauxHoraire k * (1 + applicable dispMajorationHS st)

theorem tauxHoraire_nonneg (k : Contrat) : 0 ≤ tauxHoraire k := by
  unfold tauxHoraire; positivity

/-- Pas d'heures supplémentaires sans dépassement de la durée convenue. -/
theorem heuresSup_eq_zero {dureeHebdo : ℕ} {p : Planning} {k : ℕ}
    (h : travailDans p (k * minutesSemaine) ((k + 1) * minutesSemaine) ≤ dureeHebdo) :
    heuresSup dureeHebdo p k = 0 := by
  unfold heuresSup; omega

/-- La majoration n'est jamais négative, quelles que soient les stipulations. -/
theorem majorationHS_nonneg (st : Stipulations ℚ) : 0 ≤ applicable dispMajorationHS st :=
  applicable_dispositive_limite (d := dispMajorationHS) rfl rfl st

/-- Une heure supplémentaire est payée au moins au taux normal. -/
theorem paiementHS_ge_normal (k : Contrat) (st : Stipulations ℚ) (minutes : ℕ) :
    (minutes / 60 : ℚ) * tauxHoraire k ≤ paiementHS k st minutes := by
  unfold paiementHS
  have h1 := majorationHS_nonneg st
  have h2 : 0 ≤ (minutes / 60 : ℚ) * tauxHoraire k :=
    mul_nonneg (by positivity) (tauxHoraire_nonneg k)
  nlinarith

/-- À défaut de stipulation, la majoration est de 10 %. -/
theorem majorationHS_defaut : applicable dispMajorationHS {} = 1 / 10 := by
  rw [applicable_dispositive_loi (d := dispMajorationHS) rfl]
  norm_num [meilleurOpt, dispMajorationHS, Sens.meilleur]

/-- Un accord d'entreprise peut supprimer la majoration (P15), le contrat dût-il
la prévoir. -/
theorem majorationHS_accord_zero (contrat : Option ℚ) :
    applicable dispMajorationHS { accord := some 0, contrat := contrat } = 0 := by
  rw [applicable_dispositive_accord (d := dispMajorationHS) rfl]
  simp [meilleurOpt, dispMajorationHS, Sens.meilleur]

/-- Un accord qui prévoirait une majoration négative est ramené à 0 %. -/
example : applicable dispMajorationHS { accord := some (-1 / 5) } = 0 := by
  rw [applicable_dispositive_accord (d := dispMajorationHS) rfl]
  norm_num [meilleurOpt, dispMajorationHS, Sens.meilleur]

end Prouvhommes
