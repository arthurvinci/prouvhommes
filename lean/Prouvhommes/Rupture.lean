import Prouvhommes.Contrat
import Prouvhommes.Preavis
import Prouvhommes.Interpretation

/-!
# Rupture : machine à états (M6 ; P1, P3, P4, P8, P9, P9 bis)

La relation de travail est une machine à états finie, qui avance au fil
d'une liste d'événements.

* Le temps est discret : l'événement `jourPasse` fait passer au jour suivant.
  Les autres événements arrivent « dans la journée ».
* Une notification est datée du jour de sa **réception**. Le préavis court
  à partir du lendemain : notifié au jour `d`, un préavis de `n` jours couvre
  les jours `d + 1, …, d + n`, et le dernier jour de la relation est `d + n`.
* Pendant l'essai, une notification ouvre un préavis d'essai de 7 jours, qui
  peut se terminer après la fin de l'essai (P3).
* Après l'essai, une notification ouvre un préavis ordinaire de 30, 60 ou
  90 jours selon l'ancienneté (P4). Il n'y a pas de préavis ordinaire avant la
  fin de l'essai (P1).
* Pendant une période de protection (P8), une notification de l'employeur est
  nulle et le décompte d'un préavis ordinaire de l'employeur est suspendu.
  La protection ne joue ni pendant l'essai, ni contre le salarié.
* La résiliation immédiate (P9) exige une preuve de juste motif, notion ouverte
  donnée par l'interprétation `I` (M2).
* L'accord écrit des parties et le décès du salarié mettent fin à la relation
  le jour même (P9 bis).

Résultats principaux :
* `fin_justifiee` (**T-PREAVIS**) : toute fin de relation est justifiée par un
  préavis effectivement couru, un juste motif, un accord écrit ou un décès ;
* `duree_minimale` : une résiliation ordinaire n'intervient jamais avant
  « durée d'essai + 30 jours » ;
* `protection_nullite`, `protection_suspend` : effets de la protection (P8).
-/

namespace Prouvhommes

/-! ## États et événements -/

/-- Le cadre d'un préavis : rupture d'essai (P3) ou résiliation ordinaire (P4). -/
inductive Cadre
  | essai
  | ordinaire
  deriving DecidableEq, Repr

/-- La phase de la relation de travail. -/
inductive Phase
  /-- Période d'essai en cours. -/
  | essai
  /-- Relation en cours, après l'essai. -/
  | actif
  /-- Préavis en cours, notifié par `auteur`, avec `restant` jours à courir. -/
  | preavis (auteur : Partie) (cadre : Cadre) (restant : ℕ)
  /-- Relation terminée ; `dernierJour` est le dernier jour de la relation. -/
  | termine (cause : CauseFin) (dernierJour : Jour)
  deriving DecidableEq, Repr

/-- L'état de la relation : jour courant (jour 0 = début du contrat), phase,
et période de protection en cours ou non (P8). -/
structure Etat where
  jour : Jour
  phase : Phase
  protection : Bool
  deriving DecidableEq, Repr

/-- Les événements qui font avancer la relation. -/
inductive Evenement (I : Interpretation)
  /-- Fin de la journée : on passe au jour suivant. -/
  | jourPasse
  /-- Réception d'une notification de résiliation émise par `p`. -/
  | notification (p : Partie)
  /-- Résiliation immédiate par `p`, sur des faits `f` qui constituent un juste
  motif (P9). La preuve `h` est exigée : sans juste motif, l'événement
  n'existe pas. -/
  | resiliationImmediate (p : Partie) (f : I.Faits) (h : I.justeMotif f)
  /-- Accord écrit des parties pour mettre fin au contrat (P9 bis). -/
  | accordCommun
  /-- Décès du salarié (P9 bis). -/
  | deces
  /-- Début d'une incapacité de travail ou d'un congé de maternité (P8). -/
  | debutProtection
  /-- Fin de la période de protection (P8). -/
  | finProtection

namespace Cadre

/-- Durée du préavis, en jours, pour une notification reçue au jour `j`. -/
def duree : Cadre → Jour → ℕ
  | essai, _ => preavisEssai
  | ordinaire, j => preavisOrdinaire j

/-- La phase dans laquelle une notification ouvre ce cadre de préavis. -/
def phaseNotification : Cadre → Phase
  | essai => .essai
  | ordinaire => .actif

/-- La cause de fin à laquelle aboutit le préavis. -/
def cause : Cadre → Partie → CauseFin
  | essai, p => .ruptureEssai p
  | ordinaire, p => .resiliationOrdinaire p

end Cadre

/-! ## Transitions -/

/-- Le décompte d'un préavis est suspendu : préavis ordinaire de l'employeur
pendant une période de protection (P8). -/
def suspendu (s : Etat) (p : Partie) (c : Cadre) : Prop :=
  s.protection = true ∧ p = .employeur ∧ c = .ordinaire

instance (s : Etat) (p : Partie) (c : Cadre) : Decidable (suspendu s p c) := by
  unfold suspendu; infer_instance

/-- État initial : jour 0, en essai (ou directement en cours si l'essai est nul). -/
def initial (k : Contrat) : Etat :=
  { jour := 0, phase := if k.dureeEssai = 0 then .actif else .essai, protection := false }

/-- Passage au jour suivant. -/
def pasJour (k : Contrat) (s : Etat) : Etat :=
  match s.phase with
  | .essai =>
    { s with jour := s.jour + 1,
             phase := if k.dureeEssai ≤ s.jour + 1 then .actif else .essai }
  | .actif => { s with jour := s.jour + 1 }
  | .preavis p c r =>
    if suspendu s p c then { s with jour := s.jour + 1 }
    else
      match r with
      | 0 => { s with phase := .termine (c.cause p) s.jour }
      | r + 1 => { s with jour := s.jour + 1, phase := .preavis p c r }
  | .termine .. => s

/-- Réception d'une notification émise par `p`. -/
def pasNotification (s : Etat) (p : Partie) : Etat :=
  match s.phase with
  | .essai => { s with phase := .preavis p .essai preavisEssai }
  | .actif =>
    if s.protection = true ∧ p = .employeur then s  -- congé nul (P8)
    else { s with phase := .preavis p .ordinaire (preavisOrdinaire s.jour) }
  | _ => s

/-- Fin immédiate de la relation, le jour même. -/
def terminer (s : Etat) (c : CauseFin) : Etat :=
  match s.phase with
  | .termine .. => s
  | _ => { s with phase := .termine c s.jour }

/-- Début ou fin d'une période de protection. -/
def proteger (s : Etat) (b : Bool) : Etat :=
  match s.phase with
  | .termine .. => s
  | _ => { s with protection := b }

/-- Une transition de la machine à états. -/
def pas {I : Interpretation} (k : Contrat) (s : Etat) : Evenement I → Etat
  | .jourPasse => pasJour k s
  | .notification p => pasNotification s p
  | .resiliationImmediate p _ _ => terminer s (.resiliationImmediate p)
  | .accordCommun => terminer s .accordCommun
  | .deces => terminer s .deces
  | .debutProtection => proteger s true
  | .finProtection => proteger s false

/-- L'état atteint après une suite d'événements. -/
def execute {I : Interpretation} (k : Contrat) (evs : List (Evenement I)) : Etat :=
  evs.foldl (pas k) (initial k)

variable {I : Interpretation}

@[simp] theorem execute_nil (k : Contrat) : execute k ([] : List (Evenement I)) = initial k := rfl

theorem execute_snoc (k : Contrat) (evs : List (Evenement I)) (e : Evenement I) :
    execute k (evs ++ [e]) = pas k (execute k evs) e := by
  simp [execute, List.foldl_append]

/-! ## Propriétés locales -/

/-- Une relation terminée le reste. -/
theorem termine_stable (k : Contrat) {s : Etat} {c : CauseFin} {j : Jour}
    (hs : s.phase = .termine c j) (e : Evenement I) : pas k s e = s := by
  cases e <;> simp [pas, pasJour, pasNotification, terminer, proteger, hs]

/-- **Pas de terme (P1).** Le seul écoulement du temps ne met jamais fin à une
relation en essai ou en cours : il faut un préavis, un juste motif, un accord
ou un décès. -/
theorem pas_de_terme (k : Contrat) {s : Etat} (hs : s.phase = .essai ∨ s.phase = .actif) :
    ∀ c j, (pas (I := I) k s .jourPasse).phase ≠ .termine c j := by
  intro c j
  rcases hs with hs | hs
  · simp only [pas, pasJour, hs]; split_ifs <;> simp
  · simp [pas, pasJour, hs]

/-- **Nullité du congé (P8).** Pendant une protection, la notification de
l'employeur est sans effet. -/
theorem protection_nullite (k : Contrat) {s : Etat} (hs : s.phase = .actif)
    (hp : s.protection = true) : pas (I := I) k s (.notification .employeur) = s := by
  simp [pas, pasNotification, hs, hp]

/-- **Suspension du préavis (P8).** Pendant une protection, le décompte d'un
préavis ordinaire de l'employeur ne progresse pas. -/
theorem protection_suspend (k : Contrat) {s : Etat} {r : ℕ}
    (hs : s.phase = .preavis .employeur .ordinaire r) (hp : s.protection = true) :
    (pas (I := I) k s .jourPasse).phase = s.phase := by
  simp [pas, pasJour, hs, suspendu, hp]

/-- La protection ne bride pas le salarié : il peut toujours démissionner. -/
theorem protection_salarie_libre (k : Contrat) {s : Etat} (hs : s.phase = .actif) :
    (pas (I := I) k s (.notification .salarie)).phase
      = .preavis .salarie .ordinaire (preavisOrdinaire s.jour) := by
  simp [pas, pasNotification, hs]

/-! ## Invariants -/

/-- Le préavis de `p`, dans le cadre `c`, a été notifié dans la phase prévue,
et à la date `fin` il en reste au plus `r` jours à courir : `fin` est au moins
la date de réception plus les jours déjà courus. -/
def PreavisServi (k : Contrat) (evs : List (Evenement I)) (p : Partie) (c : Cadre)
    (fin r : ℕ) : Prop :=
  ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
    (execute k pre).phase = c.phaseNotification ∧
    r ≤ c.duree (execute k pre).jour ∧
    (execute k pre).jour + (c.duree (execute k pre).jour - r) ≤ fin

/-- Ce qui justifie qu'une relation ait pris fin pour la cause `c`. -/
def FinJustifiee (k : Contrat) (evs : List (Evenement I)) : CauseFin → Jour → Prop
  | .ruptureEssai p, j => PreavisServi k evs p .essai j 0
  | .resiliationOrdinaire p, j => PreavisServi k evs p .ordinaire j 0
  | .resiliationImmediate p, _ => ∃ f h, Evenement.resiliationImmediate (I := I) p f h ∈ evs
  | .accordCommun, _ => Evenement.accordCommun (I := I) ∈ evs
  | .deces, _ => Evenement.deces (I := I) ∈ evs

/-- L'invariant de la machine : tout préavis en cours et toute fin sont justifiés. -/
def Justifie (k : Contrat) (evs : List (Evenement I)) (s : Etat) : Prop :=
  match s.phase with
  | .essai | .actif => True
  | .preavis p c r => PreavisServi k evs p c s.jour r
  | .termine c j => FinJustifiee k evs c j

theorem PreavisServi.snoc {k : Contrat} {evs : List (Evenement I)} {p : Partie} {c : Cadre}
    {fin r : ℕ} (h : PreavisServi k evs p c fin r) (e : Evenement I) {fin' : ℕ}
    (hfin : fin ≤ fin') : PreavisServi k (evs ++ [e]) p c fin' r := by
  obtain ⟨pre, post, rfl, h1, h2, h3⟩ := h
  exact ⟨pre, post ++ [e], by simp, h1, h2, by omega⟩

theorem FinJustifiee.snoc {k : Contrat} {evs : List (Evenement I)} {c : CauseFin} {j : Jour}
    (h : FinJustifiee k evs c j) (e : Evenement I) : FinJustifiee k (evs ++ [e]) c j := by
  cases c with
  | ruptureEssai p => exact PreavisServi.snoc h e le_rfl
  | resiliationOrdinaire p => exact PreavisServi.snoc h e le_rfl
  | resiliationImmediate p =>
    obtain ⟨f, hf, hm⟩ := h
    exact ⟨f, hf, List.mem_append_left _ hm⟩
  | accordCommun => exact List.mem_append_left _ h
  | deces => exact List.mem_append_left _ h

/-- Un événement qui ne change pas la phase et ne fait pas reculer le jour
préserve l'invariant. -/
theorem Justifie.snoc {k : Contrat} {evs : List (Evenement I)} {s s' : Etat}
    (h : Justifie k evs s) (e : Evenement I) (hp : s'.phase = s.phase)
    (hj : s.jour ≤ s'.jour) : Justifie k (evs ++ [e]) s' := by
  unfold Justifie at h ⊢
  rw [hp]
  rcases hph : s.phase with _ | _ | ⟨p, c, r⟩ | ⟨c, j⟩ <;> rw [hph] at h
  · trivial
  · trivial
  · exact PreavisServi.snoc h e hj
  · exact FinJustifiee.snoc h e

/-- Une relation n'est en cours (après l'essai) qu'une fois l'essai écoulé. -/
theorem actif_apres_essai (k : Contrat) (evs : List (Evenement I)) :
    (execute k evs).phase = .actif → k.dureeEssai ≤ (execute k evs).jour := by
  induction evs using List.reverseRecOn with
  | nil =>
    intro h
    simp only [execute_nil, initial] at h ⊢
    split_ifs at h with h0
    omega
  | append_singleton evs e ih =>
    rw [execute_snoc]
    generalize execute k evs = s at ih
    intro h
    obtain ⟨j, ph, pr⟩ := s
    cases e <;> rcases ph with _ | _ | ⟨p, c, _ | r⟩ | ⟨c, j'⟩ <;>
      simp only [pas, pasJour, pasNotification, terminer, proteger] at h ⊢ <;>
      (try split_ifs at h ⊢) <;> simp_all
    omega

/-- **L'invariant est vrai après toute suite d'événements.** -/
theorem justifie_execute (k : Contrat) (evs : List (Evenement I)) :
    Justifie k evs (execute k evs) := by
  induction evs using List.reverseRecOn with
  | nil =>
    simp only [execute_nil, initial]
    split_ifs <;> simp [Justifie]
  | append_singleton evs e ih =>
    rw [execute_snoc]
    generalize hs : execute k evs = s at ih
    cases e with
    | jourPasse =>
      rcases hph : s.phase with _ | _ | ⟨p, c, r⟩ | ⟨c, j⟩
      · simp only [pas, pasJour, hph]; split_ifs <;> simp [Justifie]
      · simp only [Justifie, pas, pasJour, hph]
      · simp only [Justifie, hph] at ih
        simp only [pas, pasJour, hph]
        split
        · exact Justifie.snoc (s := s) (by simp only [Justifie, hph]; exact ih) _
            (by simp [hph]) (by simp)
        · split
          · simp only [Justifie]
            cases c
            · exact ih.snoc _ le_rfl
            · exact ih.snoc _ le_rfl
          · rename_i r
            simp only [Justifie]
            obtain ⟨pre, post, he, h1, h2, h3⟩ := ih
            exact ⟨pre, post ++ [.jourPasse], by simp [he], h1, by omega, by omega⟩
      · simp only [pas, pasJour, hph]
        exact Justifie.snoc (s := s) ih _ rfl le_rfl
    | notification p =>
      rcases hph : s.phase with _ | _ | ⟨q, c, r⟩ | ⟨c, j⟩
      · simp only [Justifie, pas, pasNotification, hph]
        exact ⟨evs, [], by simp, by simp [hs, hph, Cadre.phaseNotification],
          by simp [Cadre.duree], by simp [hs, Cadre.duree]⟩
      · simp only [pas, pasNotification, hph]
        split
        · simp only [Justifie, hph]
        · simp only [Justifie]
          exact ⟨evs, [], by simp, by simp [hs, hph, Cadre.phaseNotification],
            by simp [hs, Cadre.duree], by simp [hs, Cadre.duree]⟩
      · simp only [pas, pasNotification, hph]
        exact Justifie.snoc ih _ rfl le_rfl
      · simp only [pas, pasNotification, hph]
        exact Justifie.snoc ih _ rfl le_rfl
    | resiliationImmediate p f hf =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc ih _ rfl le_rfl
      · simp only [Justifie, FinJustifiee]; exact ⟨f, hf, by simp⟩
    | accordCommun =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc ih _ rfl le_rfl
      · simp [Justifie, FinJustifiee]
    | deces =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc ih _ rfl le_rfl
      · simp [Justifie, FinJustifiee]
    | debutProtection =>
      simp only [pas, proteger]
      split
      · exact Justifie.snoc ih _ rfl le_rfl
      · exact Justifie.snoc ih _ rfl le_rfl
    | finProtection =>
      simp only [pas, proteger]
      split
      · exact Justifie.snoc ih _ rfl le_rfl
      · exact Justifie.snoc ih _ rfl le_rfl

/-! ## Théorèmes -/

/-- **T-PREAVIS.** Pour toute interprétation des notions ouvertes et toute suite
d'événements, une relation terminée l'a été pour une cause justifiée : un
préavis effectivement couru, un juste motif, un accord écrit ou un décès. -/
theorem fin_justifiee (k : Contrat) (evs : List (Evenement I)) {c : CauseFin} {j : Jour}
    (h : (execute k evs).phase = .termine c j) : FinJustifiee k evs c j := by
  have := justifie_execute k evs
  unfold Justifie at this
  rw [h] at this
  exact this

/-- Une résiliation ordinaire suppose une notification reçue après l'essai, et
le dernier jour de la relation tombe au plus tôt à la date de réception plus
le préavis légal. -/
theorem fin_resiliationOrdinaire (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k evs).phase = .termine (.resiliationOrdinaire p) j) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      (execute k pre).phase = .actif ∧
      (execute k pre).jour + preavisOrdinaire (execute k pre).jour ≤ j := by
  obtain ⟨pre, post, he, h1, -, h3⟩ := fin_justifiee k evs h
  exact ⟨pre, post, he, h1, by simpa [Cadre.duree] using h3⟩

/-- Une rupture d'essai suppose une notification reçue pendant l'essai, suivie
de 7 jours de préavis. -/
theorem fin_ruptureEssai (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k evs).phase = .termine (.ruptureEssai p) j) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      (execute k pre).phase = .essai ∧ (execute k pre).jour + preavisEssai ≤ j := by
  obtain ⟨pre, post, he, h1, -, h3⟩ := fin_justifiee k evs h
  exact ⟨pre, post, he, h1, by simpa [Cadre.duree] using h3⟩

/-- Une résiliation immédiate suppose un juste motif (P9), quelle que soit la
façon dont le juge l'apprécie. -/
theorem fin_resiliationImmediate (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k evs).phase = .termine (.resiliationImmediate p) j) :
    ∃ f, I.justeMotif f := by
  obtain ⟨f, hf, -⟩ := fin_justifiee k evs h
  exact ⟨f, hf⟩

/-- **Durée minimale (P1).** Une relation qui prend fin par résiliation
ordinaire dure au moins « durée d'essai + 30 jours ». -/
theorem duree_minimale (k : Contrat) (evs : List (Evenement I)) {p : Partie} {j : Jour}
    (h : (execute k evs).phase = .termine (.resiliationOrdinaire p) j) :
    k.dureeEssai + 30 ≤ j := by
  obtain ⟨pre, -, -, h1, h3⟩ := fin_resiliationOrdinaire k evs h
  have := actif_apres_essai k pre h1
  have := preavisOrdinaire_ge_30 (execute k pre).jour
  omega

/-- **Pas de préavis anticipé (P1).** Un préavis ordinaire en cours a été
notifié après la fin de l'essai. -/
theorem preavis_ordinaire_apres_essai (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {r : ℕ} (h : (execute k evs).phase = .preavis p .ordinaire r) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      k.dureeEssai ≤ (execute k pre).jour := by
  have := justifie_execute k evs
  unfold Justifie at this
  rw [h] at this
  obtain ⟨pre, post, he, h1, -⟩ := this
  exact ⟨pre, post, he, actif_apres_essai k pre h1⟩

/-! ## Exemples -/

/-- Une interprétation triviale, pour les exemples : aucun fait n'est un
juste motif. -/
def interpretationVide : Interpretation := ⟨Empty, fun _ => False⟩

/-- Un contrat type, avec l'essai par défaut (30 jours). -/
def contratType : Contrat :=
  { employeur := "Employeur", salarie := "Salarié", dateDebut := "2027-01-01",
    fonction := "Comptable", salaireMensuel := 300000, dureeHebdo := 35 * 60 }

/-- `n` jours qui passent. -/
def jours (n : ℕ) : List (Evenement interpretationVide) := List.replicate n .jourPasse

/-- Licenciement reçu au jour 400 (1 an révolu) : 60 jours de préavis,
dernier jour 460. -/
example : (execute contratType (jours 400 ++ [.notification .employeur] ++ jours 61)).phase
    = .termine (.resiliationOrdinaire .employeur) 460 := by
  decide +kernel

/-- Même licenciement, avec 10 jours d'incapacité pendant le préavis :
le préavis est prolongé d'autant, dernier jour 470. -/
example : (execute contratType (jours 400 ++ [.notification .employeur] ++ jours 10 ++
    [.debutProtection] ++ jours 10 ++ [.finProtection] ++ jours 51)).phase
    = .termine (.resiliationOrdinaire .employeur) 470 := by
  decide +kernel

/-- Rupture d'essai reçue au jour 28 : le préavis de 7 jours déborde après la
fin de l'essai (jour 30), dernier jour 35. -/
example : (execute contratType (jours 28 ++ [.notification .salarie] ++ jours 8)).phase
    = .termine (.ruptureEssai .salarie) 35 := by
  decide +kernel

end Prouvhommes
