import Prouvhommes.Rupture
import Prouvhommes.Hierarchie

/-!
# Modèle composé

Les autres fichiers vérifient chaque règle isolément, souvent avec les seules
valeurs légales. Ici, on assemble tout en **une seule exécution** :

* l'accord d'entreprise et le contrat fixent, par la hiérarchie des normes
  (`Hierarchie.lean`), la durée de l'essai et les préavis ;
* la machine à états (`Rupture.lean`) déroule les événements avec ces délais ;
* l'ancienneté au dernier jour et l'historique des salaires donnent
  l'indemnité de rupture (`Indemnite.lean`).

Un `Scenario` décrit une relation de travail complète ; `Scenario.issue` en
donne l'issue : cause, dernier jour, ancienneté, indemnité.

Seuls des théorèmes qui traversent les modules ont leur place ici. Ce sont
eux qui révèlent les effets que personne n'a écrits :

* `duree_minimale_scenario` : un licenciement laisse au moins « essai +
  30 jours », quels que soient l'accord et le contrat ;
* `demission_sans_duree_minimale` : ce n'est pas vrai d'une démission, dont le
  préavis peut être raccourci jusqu'à zéro ;
* `accord_domine_licenciement` : pour l'employeur, faire signer un accord
  écrit au lieu de licencier met fin au contrat au moins 30 jours plus tôt,
  et sans indemnité ;
* `seuil_preavis` : un jour de retard dans la notification d'un licenciement,
  au premier anniversaire du contrat, allonge la relation de 31 jours.
  L'indemnité, elle, n'a pas d'effet de seuil (`indemnite_saut_mensuel`).
-/

namespace Prouvhommes

/-! ## Conventions -/

/-- Les stipulations de l'accord d'entreprise et du contrat individuel sur la
rupture. Chaque champ est vide par défaut : la loi s'applique. -/
structure Conventions where
  /-- Durée de l'essai (P3, dispositive). -/
  essai : Stipulations ℕ := {}
  /-- Préavis de rupture d'essai dû par l'employeur (P3, relative). -/
  preavisEssaiEmployeur : Stipulations ℕ := {}
  /-- Préavis de rupture d'essai dû par le salarié (P3, relative). -/
  preavisEssaiSalarie : Stipulations ℕ := {}
  /-- Préavis ordinaire dû par l'employeur (P4, relative). -/
  preavisEmployeur : Stipulations ℕ := {}
  /-- Préavis ordinaire dû par le salarié (P4, relative). -/
  preavisSalarie : Stipulations ℕ := {}

namespace Conventions

/-- Les délais de préavis applicables, résolus par la hiérarchie des normes. -/
def delais (cv : Conventions) : Delais where
  duree
    | .employeur, .essai, _ => applicable dispPreavisEssaiEmployeur cv.preavisEssaiEmployeur
    | .salarie, .essai, _ => applicable dispPreavisEssaiSalarie cv.preavisEssaiSalarie
    | .employeur, .ordinaire, j => applicable (dispPreavisEmployeur j) cv.preavisEmployeur
    | .salarie, .ordinaire, j => applicable (dispPreavisSalarie j) cv.preavisSalarie

/-- Quelles que soient les conventions, les délais obtenus sont admissibles :
l'employeur ne doit jamais moins que le préavis légal. -/
theorem delais_admissible (cv : Conventions) : cv.delais.Admissible := by
  intro c j
  cases c
  · exact applicable_relative_plancher (d := dispPreavisEssaiEmployeur) rfl _
  · exact preavisEmployeur_ge_legal j _

/-- Sans stipulation, les délais sont les délais légaux. -/
theorem delais_vide : ({} : Conventions).delais = Delais.legal := by
  unfold delais Delais.legal
  congr 1
  funext p c j
  cases p <;> cases c <;> rfl

end Conventions

/-! ## Scénarios -/

/-- Une relation de travail complète. -/
structure Scenario (I : Interpretation) where
  /-- Le contrat écrit (P2). Sa durée d'essai est ignorée : elle est fixée par
  `conventions.essai`. -/
  contrat : Contrat
  /-- L'accord d'entreprise et les clauses du contrat sur la rupture. -/
  conventions : Conventions := {}
  /-- Ce qui se passe, dans l'ordre. -/
  evenements : List (Evenement I)
  /-- Salaire brut payé au titre du mois `m` du contrat (mois 0 = premier
  mois), en centimes ; `0` pour un mois non payé. -/
  salaire : Mois → Centimes := fun _ => contrat.salaireMensuel

/-- L'issue d'une relation de travail terminée. -/
structure Issue where
  cause : CauseFin
  dernierJour : Jour
  /-- Ancienneté au dernier jour, en mois révolus. -/
  anciennete : Mois
  /-- Indemnité de rupture versée, en centimes. -/
  indemnite : Centimes
  deriving DecidableEq, Repr

namespace Scenario

variable {I : Interpretation} (s : Scenario I)

/-- Le contrat, avec la durée d'essai que fixent les conventions. -/
def contratApplicable : Contrat := s.contrat.avecEssai s.conventions.essai

/-- L'état de la relation après tous les événements. -/
def etat : Etat := execute s.contratApplicable s.conventions.delais s.evenements

/-- Les salaires des `m` premiers mois, du plus ancien au plus récent. -/
def historique (m : Mois) : List Centimes := (List.range m).map s.salaire

/-- L'issue d'une relation terminée à la date `j` pour la cause `c`. -/
def issueDe (c : CauseFin) (j : Jour) : Issue :=
  { cause := c, dernierJour := j, anciennete := moisRevolus j,
    indemnite := indemniteRupture (s.historique (moisRevolus j)) (moisRevolus j) c }

/-- L'issue de la relation, si elle est terminée. -/
def issue : Option Issue :=
  match s.etat.phase with
  | .termine c j => some (s.issueDe c j)
  | _ => none

theorem issue_eq_some {i : Issue} (h : s.issue = some i) :
    s.etat.phase = .termine i.cause i.dernierJour ∧ i = s.issueDe i.cause i.dernierJour := by
  unfold issue at h
  split at h
  · rename_i c j hp
    cases h
    exact ⟨hp, rfl⟩
  · cases h

end Scenario

variable {I : Interpretation}

/-! ## Théorèmes transverses -/

/-- **Durée minimale, toutes conventions confondues.** Quels que soient
l'accord d'entreprise et le contrat, un licenciement ordinaire intervient au
plus tôt « durée d'essai + 30 jours » après le début du contrat. -/
theorem duree_minimale_scenario (s : Scenario I) {i : Issue} (h : s.issue = some i)
    (hc : i.cause = .resiliationOrdinaire .employeur) :
    s.contratApplicable.dureeEssai + 30 ≤ i.dernierJour := by
  obtain ⟨hp, -⟩ := s.issue_eq_some h
  rw [hc] at hp
  exact duree_minimale _ _ (Conventions.delais_admissible _) hp

/-- Contrat d'exemple : comptable à 3 000 € par mois, 35 h par semaine. -/
def contratExemple : Contrat :=
  { employeur := "Employeur", salarie := "Salarié", dateDebut := "2027-01-01",
    fonction := "Comptable", salaireMensuel := 300000, dureeHebdo := 35 * 60 }

/-- `n` jours qui passent. -/
def joursQuiPassent (n : ℕ) : List (Evenement I) := List.replicate n .jourPasse

/-- Un contrat stipule un préavis de démission de 0 jour ; le salarié démissionne
le jour où l'essai de 30 jours se termine. -/
def scenarioDemissionImmediate : Scenario interpretationVide :=
  { contrat := contratExemple,
    conventions := { preavisSalarie := { contrat := some 0 } },
    evenements := joursQuiPassent 30 ++ [.notification .salarie] ++ joursQuiPassent 1 }

/-- **La durée minimale ne vaut pas pour la démission.** Le texte permet de
raccourcir le préavis du salarié (P4 II), jusqu'à zéro : une démission peut
alors mettre fin au contrat dès la fin de l'essai. `duree_minimale` ne vaut
donc que pour le licenciement, et `duree_minimale_legal` que pour les délais
légaux. -/
theorem demission_sans_duree_minimale :
    ∃ s : Scenario interpretationVide, ∃ i, s.issue = some i ∧
      i.cause = .resiliationOrdinaire .salarie ∧
      i.dernierJour < s.contratApplicable.dureeEssai + 30 :=
  ⟨scenarioDemissionImmediate,
    ⟨.resiliationOrdinaire .salarie, 30, 0, 0⟩, by decide +kernel, rfl, by decide⟩

/-- **L'accord écrit domine le licenciement, pour l'employeur.** Dans toute
relation qui se termine par un licenciement ordinaire, remplacer la
notification du licenciement par un accord écrit, signé le même jour, met fin
au contrat au moins 30 jours plus tôt (pas de préavis à payer), et sans
indemnité. Le code donne ainsi à l'employeur une raison forte d'obtenir la
signature du salarié. -/
theorem accord_domine_licenciement (s : Scenario I) {i : Issue} (h : s.issue = some i)
    (hc : i.cause = .resiliationOrdinaire .employeur) :
    ∃ pre post, s.evenements = pre ++ .notification .employeur :: post ∧
      ∃ i', ({ s with evenements := pre ++ .accordCommun :: post } : Scenario I).issue = some i' ∧
        i'.cause = .accordCommun ∧ i'.dernierJour + 30 ≤ i.dernierJour ∧ i'.indemnite = 0 := by
  obtain ⟨hp, -⟩ := s.issue_eq_some h
  rw [hc] at hp
  have hp' : (execute s.contratApplicable s.conventions.delais s.evenements).phase
      = .termine (.resiliationOrdinaire .employeur) i.dernierJour := hp
  obtain ⟨pre, post, he, h1, h3⟩ := fin_resiliationOrdinaire _ _ _ hp'
  have h30 := (preavisOrdinaire_ge_30
    (execute s.contratApplicable s.conventions.delais pre).jour).trans
    (Conventions.delais_admissible s.conventions .ordinaire _)
  refine ⟨pre, post, he,
    s.issueDe .accordCommun (execute s.contratApplicable s.conventions.delais pre).jour,
    ?_, rfl, ?_, ?_⟩
  · have hpas : pas s.contratApplicable s.conventions.delais
        (execute s.contratApplicable s.conventions.delais pre) (Evenement.accordCommun (I := I))
        = { execute s.contratApplicable s.conventions.delais pre with
            phase := .termine .accordCommun
              (execute s.contratApplicable s.conventions.delais pre).jour } := by
      simp [pas, terminer, h1]
    have hetat : ({ s with evenements := pre ++ .accordCommun :: post } : Scenario I).etat
        = { execute s.contratApplicable s.conventions.delais pre with
            phase := .termine .accordCommun
              (execute s.contratApplicable s.conventions.delais pre).jour } := by
      show execute s.contratApplicable s.conventions.delais (pre ++ .accordCommun :: post) = _
      rw [execute_append_cons, hpas]
      exact foldl_termine _ _ rfl _
    simp only [Scenario.issue, hetat]
    rfl
  · simp only [Scenario.issueDe]
    omega
  · simp [Scenario.issueDe, indemniteRupture, indemniteDue]

/-- Licenciement notifié au jour `j` : `j` jours, la notification, puis
assez de jours pour que le préavis s'écoule. -/
def scenarioLicenciement (j : ℕ) : Scenario interpretationVide :=
  { contrat := contratExemple,
    evenements := joursQuiPassent j ++ [.notification .employeur] ++ joursQuiPassent 100 }

/-- **Effet de seuil du préavis.** Un licenciement reçu au jour 364 laisse
30 jours de préavis : dernier jour 394. Reçu un jour plus tard, au premier
anniversaire, il en laisse 60 : dernier jour 425. Un jour de retard coûte 31
jours de relation. -/
theorem seuil_preavis :
    ((scenarioLicenciement 364).issue.map Issue.dernierJour) = some 394 ∧
      ((scenarioLicenciement 365).issue.map Issue.dernierJour) = some 425 := by
  constructor <;> decide +kernel

end Prouvhommes
