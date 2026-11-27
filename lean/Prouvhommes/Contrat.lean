import Prouvhommes.Basic

/-!
# Contrat de travail (P1, P2, P3)

* **P1** : le contrat n'a qu'une forme et ne comporte aucun terme. La structure
  `Contrat` n'a donc aucun champ pour une date de fin : un terme convenu n'est
  même pas exprimable.
* **P2** : écrit minimal (parties, date de début, fonction, salaire, durée de
  travail convenue).
* **P3** : période d'essai de 30 jours par défaut, 90 jours au plus.

Les dates de la relation sont comptées en jours depuis le début du contrat
(jour 0) ; la date de début absolue n'est qu'une information.
-/

namespace Prouvhommes

/-- Durée de l'essai à défaut de stipulation, en jours (P3). -/
def dureeEssaiParDefaut : ℕ := 30

/-- Durée maximale de l'essai, en jours (P3). -/
def dureeEssaiMax : ℕ := 90

/-- Un contrat de travail : les mentions de l'écrit minimal (P2) et la durée
de l'essai (P3). Aucun champ ne permet de fixer un terme (P1). -/
structure Contrat where
  employeur : String
  salarie : String
  /-- Date de début (information ; les calculs partent du jour 0). -/
  dateDebut : String
  fonction : String
  /-- Salaire mensuel brut convenu, en centimes. -/
  salaireMensuel : Centimes
  /-- Durée de travail hebdomadaire convenue, en minutes. -/
  dureeHebdo : ℕ
  /-- Durée de la période d'essai, en jours. -/
  dureeEssai : ℕ := dureeEssaiParDefaut
  essai_le_max : dureeEssai ≤ dureeEssaiMax := by decide

end Prouvhommes
