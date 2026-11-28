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
* Pendant l'essai, une notification ouvre une rupture d'essai (P3) ; après
  l'essai, une résiliation ordinaire (P4). Il n'y a pas de préavis ordinaire
  avant la fin de l'essai (P1). Dans les deux cas, la durée du préavis suit la
  même courbe continue de l'ancienneté (`preavis`) : la fin de l'essai ne crée
  pas de saut. Le préavis d'une rupture d'essai peut se terminer après la fin
  de l'essai.
* Les durées de préavis ne sont pas lues dans la loi : elles sont un paramètre
  `D : Delais` de la machine. `Delais.legal` donne les durées légales ; le
  modèle composé (`Modele.lean`) les obtient par la hiérarchie des normes, à
  partir de l'accord d'entreprise et du contrat. Les théorèmes valent pour
  **tous** les délais, ou pour tous les délais admissibles
  (`Delais.Admissible`) : jamais seulement pour les valeurs légales.
* Pendant une période de protection (P8), une notification de l'employeur est
  nulle et le décompte d'un préavis ordinaire de l'employeur est suspendu.
  La protection ne joue ni pendant l'essai, ni contre le salarié.
* La résiliation immédiate (P9) exige une preuve de juste motif, notion ouverte
  donnée par l'interprétation `I` (M2).
* L'accord écrit des parties et le décès du salarié mettent fin à la relation
  le jour même (P9 bis).

Résultats principaux :
* `fin_justifiee` (**T-PREAVIS**) : toute fin de relation est justifiée par un
  préavis effectivement couru, ou par l'événement qui l'a déclenchée le jour
  même : un juste motif invoqué par la partie qui résilie, un accord écrit ou
  un décès ;
* `pas_de_terme` : sans notification, juste motif, accord ou décès, aucune
  suite d'événements ne met fin à la relation ;
* `duree_minimale` : un licenciement ordinaire n'intervient jamais avant
  « durée d'essai + préavis à la fin de l'essai » (60 jours pour l'essai de
  30 jours par défaut), quelles que soient les stipulations ; ce n'est
  pas vrai d'une démission, dont le préavis peut être raccourci
  (`demission_sans_duree_minimale`, dans `Modele.lean`) ;
* `protection_nullite`, `protection_suspend` : effets de la protection (P8),
  sur toute la vie de la relation : un licenciement repose sur une
  notification reçue hors protection, et son préavis court autant de journées
  hors protection que sa durée.
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

/-- Durée légale du préavis, en jours, pour une notification reçue au jour `j` :
la même courbe dans les deux cadres. -/
def duree : Cadre → Jour → ℕ
  | _, j => preavis j

/-- La phase dans laquelle une notification ouvre ce cadre de préavis. -/
def phaseNotification : Cadre → Phase
  | essai => .essai
  | ordinaire => .actif

/-- La cause de fin à laquelle aboutit le préavis. -/
def cause : Cadre → Partie → CauseFin
  | essai, p => .ruptureEssai p
  | ordinaire, p => .resiliationOrdinaire p

end Cadre

/-! ## Délais de préavis -/

/-- Les durées de préavis applicables : `D.duree p c j` est la durée, en jours,
du préavis notifié par `p` dans le cadre `c` et reçu au jour `j`. -/
structure Delais where
  duree : Partie → Cadre → Jour → ℕ

namespace Delais

/-- Les délais légaux : la courbe `preavis`, pour les deux parties et dans les
deux cadres. -/
def legal : Delais := ⟨fun _ c j => c.duree j⟩

/-- Des délais sont **admissibles** si le préavis dû par l'employeur n'est
jamais plus court que le préavis légal. C'est tout ce que garantit la
hiérarchie des normes : le préavis dû par le salarié, lui, peut être raccourci
(P4 II). -/
def Admissible (D : Delais) : Prop := ∀ c j, c.duree j ≤ D.duree .employeur c j

theorem legal_admissible : legal.Admissible := fun _ _ => le_rfl

end Delais

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
def pasNotification (D : Delais) (s : Etat) (p : Partie) : Etat :=
  match s.phase with
  | .essai => { s with phase := .preavis p .essai (D.duree p .essai s.jour) }
  | .actif =>
    if s.protection = true ∧ p = .employeur then s  -- congé nul (P8)
    else { s with phase := .preavis p .ordinaire (D.duree p .ordinaire s.jour) }
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
def pas {I : Interpretation} (k : Contrat) (D : Delais) (s : Etat) : Evenement I → Etat
  | .jourPasse => pasJour k s
  | .notification p => pasNotification D s p
  | .resiliationImmediate p _ _ => terminer s (.resiliationImmediate p)
  | .accordCommun => terminer s .accordCommun
  | .deces => terminer s .deces
  | .debutProtection => proteger s true
  | .finProtection => proteger s false

/-- L'état atteint après une suite d'événements, avec les délais `D`. -/
def execute {I : Interpretation} (k : Contrat) (D : Delais) (evs : List (Evenement I)) : Etat :=
  evs.foldl (pas k D) (initial k)

variable {I : Interpretation}

variable (D : Delais)

@[simp] theorem execute_nil (k : Contrat) : execute k D ([] : List (Evenement I)) = initial k := rfl

theorem execute_snoc (k : Contrat) (evs : List (Evenement I)) (e : Evenement I) :
    execute k D (evs ++ [e]) = pas k D (execute k D evs) e := by
  simp [execute, List.foldl_append]

theorem execute_append_cons (k : Contrat) (pre post : List (Evenement I)) (e : Evenement I) :
    execute k D (pre ++ e :: post) = post.foldl (pas k D) (pas k D (execute k D pre) e) := by
  simp [execute, List.foldl_append]

/-- La relation n'est pas terminée. -/
def EnCours (s : Etat) : Prop := ∀ c j, s.phase ≠ .termine c j

/-- `1` si l'événement `e`, reçu dans l'état `s`, fait passer une journée hors
période de protection, `0` sinon. -/
def compteJour (k : Contrat) (s : Etat) (e : Evenement I) : ℕ :=
  if (pas k D s e).jour = s.jour + 1 ∧ s.protection = false then 1 else 0

/-- Journées écoulées hors période de protection le long de la suite `evs`, à
partir de l'état `s`. -/
def joursLibres (k : Contrat) : Etat → List (Evenement I) → ℕ
  | _, [] => 0
  | s, e :: es => compteJour D k s e + joursLibres k (pas k D s e) es

theorem joursLibres_snoc (k : Contrat) (s : Etat) (es : List (Evenement I)) (e : Evenement I) :
    joursLibres D k s (es ++ [e]) = joursLibres D k s es + compteJour D k (es.foldl (pas k D) s) e := by
  induction es generalizing s with
  | nil => simp [joursLibres]
  | cons x es ih => simp only [List.cons_append, joursLibres, List.foldl_cons, ih]; omega

/-! ## Propriétés locales -/

/-- Une relation terminée le reste. -/
theorem termine_stable (k : Contrat) {s : Etat} {c : CauseFin} {j : Jour}
    (hs : s.phase = .termine c j) (e : Evenement I) : pas k D s e = s := by
  cases e <;> simp [pas, pasJour, pasNotification, terminer, proteger, hs]

/-- Aucune suite d'événements ne fait sortir d'une relation terminée. -/
theorem foldl_termine (k : Contrat) {s : Etat} {c : CauseFin} {j : Jour}
    (hs : s.phase = .termine c j) (evs : List (Evenement I)) : evs.foldl (pas k D) s = s := by
  induction evs with
  | nil => rfl
  | cons e evs ih => rw [List.foldl_cons, termine_stable D k hs e, ih]

/-- Le passage d'une journée ne met jamais fin à une relation en essai ou en
cours. Le cas général, sur toute une suite d'événements, est `pas_de_terme`. -/
theorem pas_de_terme_jour (k : Contrat) {s : Etat} (hs : s.phase = .essai ∨ s.phase = .actif) :
    ∀ c j, (pas (I := I) k D s .jourPasse).phase ≠ .termine c j := by
  intro c j
  rcases hs with hs | hs
  · simp only [pas, pasJour, hs]; split_ifs <;> simp
  · simp [pas, pasJour, hs]

/-- Pendant une protection, la notification de l'employeur est sans effet. Le
cas général est `protection_nullite`. -/
theorem protection_nullite_pas (k : Contrat) {s : Etat} (hs : s.phase = .actif)
    (hp : s.protection = true) : pas (I := I) k D s (.notification .employeur) = s := by
  simp [pas, pasNotification, hs, hp]

/-- Pendant une protection, le décompte d'un préavis ordinaire de l'employeur
ne progresse pas. Le cas général est `protection_suspend`. -/
theorem protection_suspend_pas (k : Contrat) {s : Etat} {r : ℕ}
    (hs : s.phase = .preavis .employeur .ordinaire r) (hp : s.protection = true) :
    (pas (I := I) k D s .jourPasse).phase = s.phase := by
  simp [pas, pasJour, hs, suspendu, hp]

/-- La protection ne bride pas le salarié : il peut toujours démissionner. -/
theorem protection_salarie_libre (k : Contrat) {s : Etat} (hs : s.phase = .actif) :
    (pas (I := I) k D s (.notification .salarie)).phase
      = .preavis .salarie .ordinaire (D.duree .salarie .ordinaire s.jour) := by
  simp [pas, pasNotification, hs]

/-! ## Invariants -/

/-- Le préavis de `p`, dans le cadre `c`, a été notifié dans la phase prévue,
et à la date `fin` il en reste au plus `r` jours à courir : `fin` est au moins
la date de réception plus les jours déjà courus. Pour un préavis ordinaire de
l'employeur, la notification a été reçue hors protection, et les jours déjà
courus sont des journées hors protection (P8). -/
def PreavisServi (k : Contrat) (evs : List (Evenement I)) (p : Partie) (c : Cadre)
    (fin r : ℕ) : Prop :=
  ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
    (execute k D pre).phase = c.phaseNotification ∧
    r ≤ D.duree p c (execute k D pre).jour ∧
    (execute k D pre).jour + (D.duree p c (execute k D pre).jour - r) ≤ fin ∧
    (p = .employeur → c = .ordinaire →
      (execute k D pre).protection = false ∧
      D.duree p c (execute k D pre).jour - r ≤
        joursLibres D k (pas k D (execute k D pre) (Evenement.notification (I := I) p)) post)

/-- L'événement `e` a mis fin à la relation au jour `j` : il a été reçu ce
jour-là, alors que la relation n'était pas terminée. -/
def Declenche (k : Contrat) (evs : List (Evenement I)) (e : Evenement I) (j : Jour) : Prop :=
  ∃ pre post, evs = pre ++ e :: post ∧ EnCours (execute k D pre) ∧ (execute k D pre).jour = j

/-- Ce qui justifie qu'une relation ait pris fin pour la cause `c` au jour `j`. -/
def FinJustifiee (k : Contrat) (evs : List (Evenement I)) : CauseFin → Jour → Prop
  | .ruptureEssai p, j => PreavisServi D k evs p .essai j 0
  | .resiliationOrdinaire p, j => PreavisServi D k evs p .ordinaire j 0
  | .resiliationImmediate p, j =>
    ∃ f, ∃ h : I.justeMotif f, Declenche D k evs (.resiliationImmediate p f h) j
  | .accordCommun, j => Declenche D k evs .accordCommun j
  | .deces, j => Declenche D k evs .deces j

/-- L'invariant de la machine : tout préavis en cours et toute fin sont justifiés. -/
def Justifie (k : Contrat) (evs : List (Evenement I)) (s : Etat) : Prop :=
  match s.phase with
  | .essai | .actif => True
  | .preavis p c r => PreavisServi D k evs p c s.jour r
  | .termine c j => FinJustifiee D k evs c j

theorem PreavisServi.snoc {k : Contrat} {evs : List (Evenement I)} {p : Partie} {c : Cadre}
    {fin r : ℕ} (h : PreavisServi D k evs p c fin r) (e : Evenement I) {fin' : ℕ}
    (hfin : fin ≤ fin') : PreavisServi D k (evs ++ [e]) p c fin' r := by
  obtain ⟨pre, post, rfl, h1, h2, h3, h4⟩ := h
  refine ⟨pre, post ++ [e], by simp, h1, h2, by omega, fun hp hc => ?_⟩
  obtain ⟨h5, h6⟩ := h4 hp hc
  exact ⟨h5, by rw [joursLibres_snoc]; omega⟩

theorem Declenche.snoc {k : Contrat} {evs : List (Evenement I)} {e : Evenement I} {j : Jour}
    (h : Declenche D k evs e j) (e' : Evenement I) : Declenche D k (evs ++ [e']) e j := by
  obtain ⟨pre, post, rfl, h1, h2⟩ := h
  exact ⟨pre, post ++ [e'], by simp, h1, h2⟩

theorem FinJustifiee.snoc {k : Contrat} {evs : List (Evenement I)} {c : CauseFin} {j : Jour}
    (h : FinJustifiee D k evs c j) (e : Evenement I) : FinJustifiee D k (evs ++ [e]) c j := by
  cases c with
  | ruptureEssai p => exact PreavisServi.snoc D h e le_rfl
  | resiliationOrdinaire p => exact PreavisServi.snoc D h e le_rfl
  | resiliationImmediate p =>
    obtain ⟨f, hf, hd⟩ := h
    exact ⟨f, hf, hd.snoc D e⟩
  | accordCommun => exact Declenche.snoc D h e
  | deces => exact Declenche.snoc D h e

/-- Un événement qui ne change pas la phase et ne fait pas reculer le jour
préserve l'invariant. -/
theorem Justifie.snoc {k : Contrat} {evs : List (Evenement I)} {s s' : Etat}
    (h : Justifie D k evs s) (e : Evenement I) (hp : s'.phase = s.phase)
    (hj : s.jour ≤ s'.jour) : Justifie D k (evs ++ [e]) s' := by
  unfold Justifie at h ⊢
  rw [hp]
  rcases hph : s.phase with _ | _ | ⟨p, c, r⟩ | ⟨c, j⟩ <;> rw [hph] at h
  · trivial
  · trivial
  · exact PreavisServi.snoc D h e hj
  · exact FinJustifiee.snoc D h e

/-- Une relation n'est en cours (après l'essai) qu'une fois l'essai écoulé. -/
theorem actif_apres_essai (k : Contrat) (evs : List (Evenement I)) :
    (execute k D evs).phase = .actif → k.dureeEssai ≤ (execute k D evs).jour := by
  induction evs using List.reverseRecOn with
  | nil =>
    intro h
    simp only [execute_nil, initial] at h ⊢
    split_ifs at h with h0
    omega
  | append_singleton evs e ih =>
    rw [execute_snoc]
    generalize execute k D evs = s at ih
    intro h
    obtain ⟨j, ph, pr⟩ := s
    cases e <;> rcases ph with _ | _ | ⟨p, c, _ | r⟩ | ⟨c, j'⟩ <;>
      simp only [pas, pasJour, pasNotification, terminer, proteger] at h ⊢ <;>
      (try split_ifs at h ⊢) <;> simp_all
    omega

/-- **L'invariant est vrai après toute suite d'événements.** -/
theorem justifie_execute (k : Contrat) (evs : List (Evenement I)) :
    Justifie D k evs (execute k D evs) := by
  induction evs using List.reverseRecOn with
  | nil =>
    simp only [execute_nil, initial]
    split_ifs <;> simp [Justifie]
  | append_singleton evs e ih =>
    rw [execute_snoc]
    generalize hs : execute k D evs = s at ih
    cases e with
    | jourPasse =>
      rcases hph : s.phase with _ | _ | ⟨p, c, r⟩ | ⟨c, j⟩
      · simp only [pas, pasJour, hph]; split_ifs <;> simp [Justifie]
      · simp only [Justifie, pas, pasJour, hph]
      · simp only [Justifie, hph] at ih
        simp only [pas, pasJour, hph]
        split
        · exact Justifie.snoc D (s := s) (by simp only [Justifie, hph]; exact ih) _
            (by simp [hph]) (by simp)
        · rename_i hsus
          split
          · simp only [Justifie]
            cases c
            · exact ih.snoc D _ le_rfl
            · exact ih.snoc D _ le_rfl
          · rename_i r
            simp only [Justifie]
            obtain ⟨pre, post, he, h1, h2, h3, h4⟩ := ih
            have hf : post.foldl (pas k D) (pas k D (execute k D pre) (Evenement.notification (I := I) p)) = s := by
              rw [← execute_append_cons, ← he, hs]
            refine ⟨pre, post ++ [.jourPasse], by simp [he], h1, by omega, by omega,
              fun hp hc => ?_⟩
            obtain ⟨h5, h6⟩ := h4 hp hc
            subst hp hc
            have hprot : s.protection = false := by simpa [suspendu] using hsus
            have hc1 : compteJour D k s (.jourPasse : Evenement I) = 1 := by
              simp [compteJour, pas, pasJour, hph, suspendu, hprot]
            refine ⟨h5, ?_⟩
            rw [joursLibres_snoc, hf, hc1]
            omega
      · simp only [pas, pasJour, hph]
        exact Justifie.snoc D (s := s) ih _ rfl le_rfl
    | notification p =>
      rcases hph : s.phase with _ | _ | ⟨q, c, r⟩ | ⟨c, j⟩
      · simp only [Justifie, pas, pasNotification, hph]
        exact ⟨evs, [], by simp, by simp [hs, hph, Cadre.phaseNotification],
          by simp [hs], by simp [hs], fun _ hc => absurd hc (by decide)⟩
      · simp only [pas, pasNotification, hph]
        split
        · simp only [Justifie, hph]
        · rename_i hnp
          simp only [Justifie]
          exact ⟨evs, [], by simp, by simp [hs, hph, Cadre.phaseNotification],
            by simp [hs], by simp [hs],
            fun hp _ => ⟨by rw [hs]; subst hp; simpa using hnp, by simp [joursLibres, hs]⟩⟩
      · simp only [pas, pasNotification, hph]
        exact Justifie.snoc D ih _ rfl le_rfl
      · simp only [pas, pasNotification, hph]
        exact Justifie.snoc D ih _ rfl le_rfl
    | resiliationImmediate p f hf =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc D ih _ rfl le_rfl
      · rename_i hne
        simp only [Justifie, FinJustifiee]
        exact ⟨f, hf, evs, [], by simp, by rw [hs]; intro c j h; exact hne c j h, by rw [hs]⟩
    | accordCommun =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc D ih _ rfl le_rfl
      · rename_i hne
        simp only [Justifie, FinJustifiee]
        exact ⟨evs, [], by simp, by rw [hs]; intro c j h; exact hne c j h, by rw [hs]⟩
    | deces =>
      simp only [pas, terminer]
      split
      · exact Justifie.snoc D ih _ rfl le_rfl
      · rename_i hne
        simp only [Justifie, FinJustifiee]
        exact ⟨evs, [], by simp, by rw [hs]; intro c j h; exact hne c j h, by rw [hs]⟩
    | debutProtection =>
      simp only [pas, proteger]
      split
      · exact Justifie.snoc D ih _ rfl le_rfl
      · exact Justifie.snoc D ih _ rfl le_rfl
    | finProtection =>
      simp only [pas, proteger]
      split
      · exact Justifie.snoc D ih _ rfl le_rfl
      · exact Justifie.snoc D ih _ rfl le_rfl

/-! ## Théorèmes -/

/-- **T-PREAVIS.** Pour toute interprétation des notions ouvertes, tous délais
et toute suite d'événements, une relation terminée l'a été pour une cause
justifiée : un préavis effectivement couru, ou l'événement qui a mis fin à la
relation le jour même (un juste motif invoqué par la partie qui résilie, un
accord écrit ou un décès). -/
theorem fin_justifiee (k : Contrat) (evs : List (Evenement I)) {c : CauseFin} {j : Jour}
    (h : (execute k D evs).phase = .termine c j) : FinJustifiee D k evs c j := by
  have := justifie_execute D k evs
  unfold Justifie at this
  rw [h] at this
  exact this

/-- Une résiliation ordinaire suppose une notification reçue après l'essai, et
le dernier jour de la relation tombe au plus tôt à la date de réception plus
le préavis applicable. -/
theorem fin_resiliationOrdinaire (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k D evs).phase = .termine (.resiliationOrdinaire p) j) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      (execute k D pre).phase = .actif ∧
      (execute k D pre).jour + D.duree p .ordinaire (execute k D pre).jour ≤ j := by
  obtain ⟨pre, post, he, h1, -, h3, -⟩ := fin_justifiee D k evs h
  exact ⟨pre, post, he, h1, by simpa using h3⟩

/-- Une rupture d'essai suppose une notification reçue pendant l'essai, suivie
du préavis d'essai applicable. -/
theorem fin_ruptureEssai (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k D evs).phase = .termine (.ruptureEssai p) j) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      (execute k D pre).phase = .essai ∧
      (execute k D pre).jour + D.duree p .essai (execute k D pre).jour ≤ j := by
  obtain ⟨pre, post, he, h1, -, h3, -⟩ := fin_justifiee D k evs h
  exact ⟨pre, post, he, h1, by simpa using h3⟩

/-- **Juste motif (P9).** Pour toute interprétation des notions ouvertes et
tous délais, une résiliation immédiate par `p` au jour `j` a été déclenchée,
ce jour-là et alors que la relation était en cours, par `p` lui-même, sur des
faits qui constituent un juste motif. -/
theorem fin_resiliationImmediate (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {j : Jour} (h : (execute k D evs).phase = .termine (.resiliationImmediate p) j) :
    ∃ pre post f, ∃ hf : I.justeMotif f,
      evs = pre ++ Evenement.resiliationImmediate p f hf :: post ∧
      EnCours (execute k D pre) ∧ (execute k D pre).jour = j := by
  obtain ⟨f, hf, pre, post, he, h1, h2⟩ := fin_justifiee D k evs h
  exact ⟨pre, post, f, hf, he, h1, h2⟩

/-- Les événements qui peuvent mettre fin à la relation : une notification,
une résiliation immédiate, un accord écrit ou un décès. -/
def Evenement.rompt : Evenement I → Prop
  | .notification _ => True
  | .resiliationImmediate .. => True
  | .accordCommun => True
  | .deces => True
  | _ => False

/-- **Pas de terme (P1).** Pour tous délais, une suite d'événements sans
notification, juste motif, accord écrit ni décès ne met jamais fin à la
relation, quelle que soit sa longueur et quelles que soient les périodes de
protection. -/
theorem pas_de_terme (k : Contrat) (evs : List (Evenement I)) (h : ∀ e ∈ evs, ¬ e.rompt) :
    EnCours (execute k D evs) := by
  intro c j hc
  have hj := fin_justifiee D k evs hc
  cases c with
  | ruptureEssai p =>
    obtain ⟨pre, post, he, -⟩ := hj
    exact h (.notification p) (by simp [he]) trivial
  | resiliationOrdinaire p =>
    obtain ⟨pre, post, he, -⟩ := hj
    exact h (.notification p) (by simp [he]) trivial
  | resiliationImmediate p =>
    obtain ⟨f, hf, pre, post, he, -⟩ := hj
    exact h (.resiliationImmediate p f hf) (by simp [he]) trivial
  | accordCommun =>
    obtain ⟨pre, post, he, -⟩ := hj
    exact h .accordCommun (by simp [he]) trivial
  | deces =>
    obtain ⟨pre, post, he, -⟩ := hj
    exact h .deces (by simp [he]) trivial

/-- **Nullité du congé (P8).** Pour tous délais et toute suite d'événements,
un licenciement ordinaire repose sur une notification reçue hors période de
protection : une notification reçue pendant une protection ne fonde jamais un
licenciement. -/
theorem protection_nullite (k : Contrat) (evs : List (Evenement I)) {j : Jour}
    (h : (execute k D evs).phase = .termine (.resiliationOrdinaire .employeur) j) :
    ∃ pre post, evs = pre ++ Evenement.notification .employeur :: post ∧
      (execute k D pre).phase = .actif ∧ (execute k D pre).protection = false := by
  obtain ⟨pre, post, he, h1, -, -, h4⟩ := fin_justifiee D k evs h
  exact ⟨pre, post, he, h1, (h4 rfl rfl).1⟩

/-- **Suspension du préavis (P8).** Pour tous délais et toute suite
d'événements, un licenciement ordinaire n'intervient qu'après que le préavis
a couru autant de journées hors protection que sa durée : les journées de
protection ne comptent pas. -/
theorem protection_suspend (k : Contrat) (evs : List (Evenement I)) {j : Jour}
    (h : (execute k D evs).phase = .termine (.resiliationOrdinaire .employeur) j) :
    ∃ pre post, evs = pre ++ Evenement.notification .employeur :: post ∧
      (execute k D pre).protection = false ∧
      D.duree .employeur .ordinaire (execute k D pre).jour ≤
        joursLibres D k (pas k D (execute k D pre) (Evenement.notification (I := I) .employeur)) post := by
  obtain ⟨pre, post, he, -, -, -, h4⟩ := fin_justifiee D k evs h
  obtain ⟨h5, h6⟩ := h4 rfl rfl
  exact ⟨pre, post, he, h5, by simpa using h6⟩

/-- Durée minimale, sous une hypothèse explicite : si le préavis ordinaire de
`p` n'est jamais plus court que le préavis légal, une résiliation ordinaire
par `p` intervient au plus tôt à « durée d'essai + préavis légal à la fin de
l'essai ». -/
theorem duree_minimale_of (k : Contrat) (evs : List (Evenement I)) {p : Partie} {j : Jour}
    (hD : ∀ j, preavis j ≤ D.duree p .ordinaire j)
    (h : (execute k D evs).phase = .termine (.resiliationOrdinaire p) j) :
    k.dureeEssai + preavis k.dureeEssai ≤ j := by
  obtain ⟨pre, -, -, h1, h3⟩ := fin_resiliationOrdinaire D k evs h
  have he := actif_apres_essai D k pre h1
  have := preavis_monotone he
  have := hD (execute k D pre).jour
  omega

/-- **Durée minimale (P1).** Pour tous délais admissibles, donc quels que
soient l'accord d'entreprise et le contrat, un licenciement ordinaire
intervient au plus tôt à « durée d'essai + préavis légal à la fin de
l'essai » : 60 jours avec l'essai de 30 jours par défaut. -/
theorem duree_minimale (k : Contrat) (evs : List (Evenement I)) {D : Delais}
    (hD : D.Admissible) {j : Jour}
    (h : (execute k D evs).phase = .termine (.resiliationOrdinaire .employeur) j) :
    k.dureeEssai + preavis k.dureeEssai ≤ j :=
  duree_minimale_of D k evs (fun j => hD .ordinaire j) h

/-- Avec les délais légaux, la durée minimale vaut aussi pour la démission. -/
theorem duree_minimale_legal (k : Contrat) (evs : List (Evenement I)) {p : Partie} {j : Jour}
    (h : (execute k Delais.legal evs).phase = .termine (.resiliationOrdinaire p) j) :
    k.dureeEssai + preavis k.dureeEssai ≤ j :=
  duree_minimale_of Delais.legal k evs (fun _ => le_rfl) h

/-- **Pas de préavis anticipé (P1).** Un préavis ordinaire en cours a été
notifié après la fin de l'essai. -/
theorem preavis_ordinaire_apres_essai (k : Contrat) (evs : List (Evenement I)) {p : Partie}
    {r : ℕ} (h : (execute k D evs).phase = .preavis p .ordinaire r) :
    ∃ pre post, evs = pre ++ Evenement.notification p :: post ∧
      k.dureeEssai ≤ (execute k D pre).jour := by
  have := justifie_execute D k evs
  unfold Justifie at this
  rw [h] at this
  obtain ⟨pre, post, he, h1, -⟩ := this
  exact ⟨pre, post, he, actif_apres_essai D k pre h1⟩

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

/-- Licenciement reçu au jour 400 (1 an et 35 jours) : 60 jours de préavis,
dernier jour 460. -/
example : (execute contratType Delais.legal (jours 400 ++ [.notification .employeur] ++ jours 61)).phase
    = .termine (.resiliationOrdinaire .employeur) 460 := by
  decide +kernel

/-- Même licenciement, avec 10 jours d'incapacité pendant le préavis :
le préavis est prolongé d'autant, dernier jour 470. -/
example : (execute contratType Delais.legal (jours 400 ++ [.notification .employeur] ++ jours 10 ++
    [.debutProtection] ++ jours 10 ++ [.finProtection] ++ jours 51)).phase
    = .termine (.resiliationOrdinaire .employeur) 470 := by
  decide +kernel

/-- Rupture d'essai reçue au jour 28 : le préavis de 28 jours déborde après la
fin de l'essai (jour 30), dernier jour 56. -/
example : (execute contratType Delais.legal (jours 28 ++ [.notification .salarie] ++ jours 29)).phase
    = .termine (.ruptureEssai .salarie) 56 := by
  decide +kernel

end Prouvhommes
