import Mathlib

/-!
# Prouv'hommes — définitions de base

Unités (M1, M5), parties au contrat et niveaux d'impérativité (M4).
-/

namespace Prouvhommes

/-- Une date, en jours depuis une origine fixée (en général le début du contrat). M1. -/
abbrev Jour := ℕ

/-- Une durée en mois révolus (ancienneté). M1. -/
abbrev Mois := ℕ

/-- Un montant en centimes d'euro. Les calculs intermédiaires se font dans `ℚ`,
avec un seul arrondi final au centime inférieur. M5. -/
abbrev Centimes := ℕ

/-- Les deux parties au contrat de travail. -/
inductive Partie
  | employeur
  | salarie
  deriving DecidableEq, Repr

/-- Les manières dont la relation de travail prend fin (P1, P3, P4, P9).
L'argument désigne la partie qui prend l'initiative. -/
inductive CauseFin
  /-- Rupture pendant la période d'essai (P3). -/
  | ruptureEssai (auteur : Partie)
  /-- Résiliation ordinaire, avec préavis (P4). -/
  | resiliationOrdinaire (auteur : Partie)
  /-- Résiliation immédiate pour juste motif (P9). -/
  | resiliationImmediate (auteur : Partie)
  deriving DecidableEq, Repr

/-- Niveau d'impérativité d'une disposition (M4).
* `absolue` : non dérogeable ;
* `relative` : dérogeable seulement en faveur du salarié ;
* `dispositive` : librement dérogeable. -/
inductive Imperativite
  | absolue
  | relative
  | dispositive
  deriving DecidableEq, Repr

end Prouvhommes
