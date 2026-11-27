import Prouvhommes.Hierarchie

/-!
# Temps de travail (P10, P11)

Un **planning** est la liste des plages de travail effectif d'un salarié, en
minutes depuis le lundi 0 h de la première semaine, triées et disjointes.
Il n'y a pas de durée légale (P10) : seuls comptent la durée convenue au
contrat et les plafonds de santé de la directive 2003/88 (P11, `absolue`).

Les règles sont des fonctions booléennes : on peut les **calculer** sur un
planning concret (`decide`).

* `reposQuotidien` : les journées de travail sont séparées par au moins 11 h
  de repos consécutives, et une journée s'étend sur 13 h au plus ;
* `reposHebdomadaire` : chaque semaine civile contient 35 h de repos
  consécutives (24 h + 11 h) ;
* `pauses` : on ne travaille jamais 6 h sans une pause d'au moins 20 minutes ;
* `moyenne48h` : 48 h en moyenne par semaine sur chaque période de référence
  (17 semaines, jusqu'à 52 par accord d'entreprise) ;
* `nuit8h` : une journée d'un travailleur de nuit compte 8 h de travail au plus.

Résultats principaux :
* `grouper_flatten` : les journées (et les blocs de travail continu)
  partitionnent le planning ;
* `travail_journee_le_13h` : avec le repos quotidien, aucune journée ne compte
  plus de 13 h de travail effectif ;
* `travail_continu_lt_6h` : avec les pauses, aucun bloc de travail continu
  n'atteint 6 h ;
* `travail_nuit_journee_le_8h` : un travailleur de nuit ne travaille jamais
  plus de 8 h dans une journée ;
* `reposQuotidien_independant`, `reposHebdomadaire_independant`,
  `pauses_independantes`, `moyenne48h_independante`, `nuit8h_independante` :
  **chaque règle a un sens**. Pour chacune, un planning respecte toutes les
  autres mais pas celle-là : aucune n'est impliquée par les autres.
-/

namespace Prouvhommes

/-! ## Plannings -/

/-- `instant j h m` : le jour `j` (jour 0 = premier lundi), à `h` h `m`. -/
def instant (j h m : ℕ) : Minute := j * 1440 + h * 60 + m

/-- Une plage de travail effectif `[debut, fin)`. -/
structure Plage where
  debut : Minute
  fin : Minute
  deriving DecidableEq, Repr

/-- Durée d'une plage, en minutes. -/
def Plage.duree (x : Plage) : ℕ := x.fin - x.debut

/-- Un planning : plages triées et disjointes (cf. `bienForme`). -/
abbrev Planning := List Plage

/-- Chaque plage est non vide et finit avant le début de la suivante. -/
def bienForme : Planning → Bool
  | [] => true
  | [x] => decide (x.debut < x.fin)
  | x :: y :: r => decide (x.debut < x.fin) && decide (x.fin ≤ y.debut) && bienForme (y :: r)

/-- Durée totale de travail d'un planning, en minutes. -/
def duree (p : Planning) : ℕ := (p.map Plage.duree).sum

/-- Travail effectif compris dans la fenêtre `[a, b)`, en minutes. -/
def travailDans (p : Planning) (a b : Minute) : ℕ :=
  (p.map fun x => min x.fin b - max x.debut a).sum

/-- Début de la première plage. -/
def debutPlanning (p : Planning) : Minute := (p.head?.map Plage.debut).getD 0

/-- Fin de la dernière plage. -/
def finPlanning (p : Planning) : Minute := (p.getLast?.map Plage.fin).getD 0

/-- Amplitude : du début de la première plage à la fin de la dernière. -/
def amplitude (p : Planning) : ℕ := finPlanning p - debutPlanning p

/-- Regroupe les plages séparées par moins de `seuil` minutes. -/
def grouper (seuil : ℕ) : Planning → List Planning
  | [] => []
  | x :: r =>
    match grouper seuil r with
    | [] => [[x]]
    | [] :: gs => [x] :: gs
    | (y :: g) :: gs =>
      if y.debut - x.fin < seuil then (x :: y :: g) :: gs else [x] :: (y :: g) :: gs

/-! ### Propriétés des groupes -/

theorem bienForme_tail {x : Plage} {r : Planning} (h : bienForme (x :: r) = true) :
    bienForme r = true := by
  cases r with
  | nil => rfl
  | cons y r => simp only [bienForme, Bool.and_eq_true] at h; exact h.2

/-- Le premier groupe commence par la première plage. -/
theorem grouper_head (seuil : ℕ) (x : Plage) (r : Planning) :
    ∃ g gs, grouper seuil (x :: r) = (x :: g) :: gs := by
  simp only [grouper]
  split
  · exact ⟨[], [], rfl⟩
  · exact ⟨[], _, rfl⟩
  · split
    · exact ⟨_, _, rfl⟩
    · exact ⟨[], _, rfl⟩

/-- **Les groupes partitionnent le planning** : mis bout à bout, ils redonnent
le planning, dans l'ordre. -/
theorem grouper_flatten (seuil : ℕ) (p : Planning) : (grouper seuil p).flatten = p := by
  induction p with
  | nil => rfl
  | cons x r ih =>
    simp only [grouper]
    split
    · rename_i h; rw [h] at ih; simp at ih; simp [ih]
    · rename_i gs h; rw [h] at ih; simp at ih ⊢; exact ih
    · rename_i y g gs h
      rw [h] at ih
      split <;> simp at ih ⊢ <;> exact ih

/-- Chaque groupe est non vide et bien formé. -/
theorem grouper_bienForme (seuil : ℕ) {p : Planning} (hp : bienForme p = true) :
    ∀ g ∈ grouper seuil p, g ≠ [] ∧ bienForme g = true := by
  induction p with
  | nil => simp [grouper]
  | cons x r ih =>
    have hr := ih (bienForme_tail hp)
    have hx : x.debut < x.fin := by
      cases r with
      | nil => simpa [bienForme] using hp
      | cons y r => simp only [bienForme, Bool.and_eq_true, decide_eq_true_eq] at hp; exact hp.1.1
    simp only [grouper]
    split
    · simp [bienForme, hx]
    · rename_i gs h
      intro g hg
      simp only [List.mem_cons] at hg
      rcases hg with rfl | hg
      · simp [bienForme, hx]
      · exact hr g (by rw [h]; simp [hg])
    · rename_i y g gs h
      have hyg := hr (y :: g) (by rw [h]; simp)
      cases r with
      | nil => simp [grouper] at h
      | cons z r' =>
        obtain ⟨g', gs', h'⟩ := grouper_head seuil z r'
        rw [h'] at h
        simp only [List.cons.injEq] at h
        obtain ⟨⟨h1, h2⟩, h3⟩ := h
        subst h1 h2 h3
        have hxy : x.fin ≤ z.debut := by
          simp only [bienForme, Bool.and_eq_true, decide_eq_true_eq] at hp; exact hp.1.2
        split
        · intro g₀ hg₀
          simp only [List.mem_cons] at hg₀
          rcases hg₀ with rfl | hg₀
          · refine ⟨by simp, ?_⟩
            simp only [bienForme, Bool.and_eq_true, decide_eq_true_eq]
            exact ⟨⟨hx, hxy⟩, hyg.2⟩
          · exact hr g₀ (by rw [h']; simp [hg₀])
        · intro g₀ hg₀
          simp only [List.mem_cons] at hg₀
          rcases hg₀ with rfl | rfl | hg₀
          · simp [bienForme, hx]
          · exact hyg
          · exact hr g₀ (by rw [h']; simp [hg₀])

/-- Dans un planning bien formé et non vide, la durée de travail ne dépasse
pas l'amplitude. -/
theorem duree_add_debut_le_fin {x : Plage} {r : Planning} (h : bienForme (x :: r) = true) :
    duree (x :: r) + x.debut ≤ finPlanning (x :: r) := by
  induction r generalizing x with
  | nil =>
    simp only [bienForme, decide_eq_true_eq] at h
    simp [duree, finPlanning, Plage.duree]; omega
  | cons y r ih =>
    simp only [bienForme, Bool.and_eq_true, decide_eq_true_eq] at h
    have := ih h.2
    simp only [duree, List.map_cons, List.sum_cons, finPlanning, List.getLast?_cons_cons,
      Plage.duree] at this ⊢
    omega

theorem duree_le_amplitude {g : Planning} (hg : g ≠ []) (h : bienForme g = true) :
    duree g ≤ amplitude g := by
  obtain ⟨x, r, rfl⟩ := List.exists_cons_of_ne_nil hg
  have := duree_add_debut_le_fin h
  simp only [amplitude, debutPlanning, List.head?_cons, Option.map_some, Option.getD_some]
  omega

/-! ## Repos quotidien -/

/-- Repos quotidien minimal, en minutes : 11 h consécutives. -/
def reposQuotidienMin : ℕ := 11 * 60

/-- Amplitude maximale d'une journée de travail : 24 h − 11 h = 13 h. -/
def amplitudeJourneeMax : ℕ := 13 * 60

/-- Les journées de travail : plages séparées par moins de 11 h de repos. -/
def journees (p : Planning) : List Planning := grouper reposQuotidienMin p

/-- **Repos quotidien** (P11) : 11 h consécutives entre deux journées, et donc
13 h d'amplitude au plus pour une journée. -/
def reposQuotidien (p : Planning) : Bool :=
  (journees p).all fun g => decide (amplitude g ≤ amplitudeJourneeMax)

/-- Avec le repos quotidien, aucune journée ne compte plus de 13 h de travail. -/
theorem travail_journee_le_13h {p : Planning} (hp : bienForme p = true)
    (hr : reposQuotidien p = true) : ∀ g ∈ journees p, duree g ≤ amplitudeJourneeMax := by
  intro g hg
  have h1 := grouper_bienForme reposQuotidienMin hp g hg
  have h2 := List.all_eq_true.1 hr g hg
  simp only [decide_eq_true_eq] at h2
  exact (duree_le_amplitude h1.1 h1.2).trans h2

/-! ## Pauses -/

/-- Pause minimale, en minutes (relative : plus longue = plus favorable). -/
def dispPause : Disposition ℕ := { niveau := .relative, loi := 20, sens := .plusGrand }

/-- Durée à partir de laquelle une pause est due : 6 h. -/
def travailContinuMax : ℕ := 6 * 60

/-- Les blocs de travail continu, pour une pause minimale `pause`. -/
def blocs (pause : ℕ) (p : Planning) : List Planning := grouper pause p

/-- **Pauses** (P11) : aucun bloc de travail continu n'atteint 6 h. -/
def pauses (pause : ℕ) (p : Planning) : Bool :=
  (blocs pause p).all fun g => decide (amplitude g < travailContinuMax)

/-- Avec les pauses, on ne travaille jamais 6 h d'affilée. -/
theorem travail_continu_lt_6h {pause : ℕ} {p : Planning} (hp : bienForme p = true)
    (hpa : pauses pause p = true) : ∀ g ∈ blocs pause p, duree g < travailContinuMax := by
  intro g hg
  have h1 := grouper_bienForme pause hp g hg
  have h2 := List.all_eq_true.1 hpa g hg
  simp only [decide_eq_true_eq] at h2
  exact lt_of_le_of_lt (duree_le_amplitude h1.1 h1.2) h2

/-! ## Repos hebdomadaire -/

/-- Minutes par semaine. -/
def minutesSemaine : ℕ := 7 * 1440

/-- Repos hebdomadaire minimal : 24 h + 11 h = 35 h consécutives. -/
def reposHebdoMin : ℕ := 35 * 60

/-- Plus longue période sans travail dans la fenêtre `[a, b)`. -/
def libreMax (p : Planning) (a b : Minute) : ℕ :=
  let r := p.foldl (fun (acc : ℕ × ℕ) x =>
    let s := max x.debut a
    let e := min x.fin b
    if s < e then (max acc.1 e, max acc.2 (s - acc.1)) else acc) (a, 0)
  max r.2 (b - r.1)

/-- Nombre de semaines couvertes par le planning. -/
def nbSemaines (p : Planning) : ℕ := finPlanning p / minutesSemaine + 1

/-- **Repos hebdomadaire** (P11) : chaque semaine civile, du lundi 0 h au
dimanche 24 h, contient 35 h de repos consécutives. -/
def reposHebdomadaire (p : Planning) : Bool :=
  (List.range (nbSemaines p)).all fun k =>
    decide (reposHebdoMin ≤ libreMax p (k * minutesSemaine) ((k + 1) * minutesSemaine))

/-! ## Durée maximale : 48 h en moyenne -/

/-- Plafond hebdomadaire moyen, en minutes : 48 h (absolu, sans opt-out). -/
def plafondHebdo : ℕ := 48 * 60

/-- Période de référence, en semaines : dispositive, 17 semaines (4 mois) à
défaut d'accord, 52 semaines au plus. Seul un accord d'entreprise peut
l'allonger (le contrat n'est pas pris en compte). -/
def dispPeriodeReference : Disposition ℕ :=
  { niveau := .dispositive, loi := 17, sens := .plusPetit, limite := some 52 }

/-- Période de référence applicable, en semaines (au moins 1). -/
def periodeReference (accord : Option ℕ) : ℕ :=
  max 1 (applicable dispPeriodeReference { accord := accord })

/-- Nombre de périodes de référence de `n` semaines couvertes par le planning. -/
def nbPeriodes (n : ℕ) (p : Planning) : ℕ := nbSemaines p / n + 1

/-- Travail effectif pendant la `k`-ième période de référence de `n` semaines. -/
def travailPeriode (n : ℕ) (p : Planning) (k : ℕ) : ℕ :=
  travailDans p (k * n * minutesSemaine) ((k + 1) * n * minutesSemaine)

/-- **48 h en moyenne** (P11) sur chaque période de référence de `n` semaines. -/
def moyenne48h (n : ℕ) (p : Planning) : Bool :=
  (List.range (nbPeriodes n p)).all fun k => decide (travailPeriode n p k ≤ plafondHebdo * n)

theorem periodeReference_le_52 (accord : Option ℕ) : periodeReference accord ≤ 52 := by
  have h : applicable dispPeriodeReference { accord := accord } ≤ 52 :=
    applicable_dispositive_limite (d := dispPeriodeReference) rfl rfl { accord := accord }
  unfold periodeReference
  omega

theorem periodeReference_defaut : periodeReference none = 17 := by decide

/-! ## Travail de nuit -/

/-- Travail effectif pendant la nuit du jour `d` (de 21 h à 6 h le lendemain). -/
def travailNuit (p : Planning) (d : ℕ) : ℕ :=
  travailDans p (instant d 21 0) (instant (d + 1) 6 0)

/-- Nombre de nuits de la semaine `k` comptant au moins 3 h de travail. -/
def nuitsTravaillees (p : Planning) (k : ℕ) : ℕ :=
  ((List.range 7).filter fun i => decide (3 * 60 ≤ travailNuit p (7 * k + i))).length

/-- Travailleur de nuit : au moins 3 h de nuit, au moins deux nuits dans une
même semaine. -/
def travailleurDeNuit (p : Planning) : Bool :=
  (List.range (nbSemaines p)).any fun k => decide (2 ≤ nuitsTravaillees p k)

/-- Plafond quotidien du travailleur de nuit, en minutes : 8 h de travail
effectif par journée. -/
def plafondNuitJournee : ℕ := 8 * 60

/-- **Travail de nuit** (P11) : une journée de travail d'un travailleur de nuit
compte 8 h de travail effectif au plus.

Une première version (« 8 h en moyenne par 24 h ») était impliquée par la règle
des 48 h : 48 h par semaine, c'est moins de 8 h par 24 h. Elle ne protégeait
donc rien. Le plafond quotidien, lui, n'est impliqué par aucune autre règle
(`nuit8h_independante`). -/
def nuit8h (p : Planning) : Bool :=
  !travailleurDeNuit p || (journees p).all fun g => decide (duree g ≤ plafondNuitJournee)

/-- Un travailleur de nuit ne travaille jamais plus de 8 h dans une journée. -/
theorem travail_nuit_journee_le_8h {p : Planning} (hn : travailleurDeNuit p = true)
    (h : nuit8h p = true) : ∀ g ∈ journees p, duree g ≤ plafondNuitJournee := by
  simp only [nuit8h, hn, Bool.not_true, Bool.false_or] at h
  intro g hg
  exact of_decide_eq_true (List.all_eq_true.1 h g hg)

/-! ## Conformité -/

/-- Toutes les règles de santé, pour un accord d'entreprise donné sur la
période de référence et une pause minimale donnée. -/
def conforme (accordPeriode : Option ℕ) (pause : ℕ) (p : Planning) : Bool :=
  bienForme p && reposQuotidien p && reposHebdomadaire p && pauses pause p &&
    moyenne48h (periodeReference accordPeriode) p && nuit8h p

/-- Conformité avec les valeurs légales. -/
def conformeLegal (p : Planning) : Bool := conforme none dispPause.loi p

/-! ## Exemples -/

/-- Une journée de 7 h : 9 h – 12 h 30 et 13 h 30 – 17 h. -/
def journee7h (j : ℕ) : Planning := [⟨instant j 9 0, instant j 12 30⟩, ⟨instant j 13 30, instant j 17 0⟩]

/-- Une journée de 10 h : 8 h – 13 h et 14 h – 19 h. -/
def journee10h (j : ℕ) : Planning := [⟨instant j 8 0, instant j 13 0⟩, ⟨instant j 14 0, instant j 19 0⟩]

/-- `n` semaines de 5 journées, du lundi au vendredi. -/
def semaines (journee : ℕ → Planning) (n : ℕ) : Planning :=
  (List.range n).flatMap fun s => (List.range 5).flatMap fun i => journee (7 * s + i)

/-- 35 h par semaine pendant 17 semaines : conforme. -/
example : conformeLegal (semaines journee7h 17) = true := by decide +kernel

/-- 50 h par semaine pendant 17 semaines : la moyenne de 48 h est dépassée. -/
example : moyenne48h 17 (semaines journee10h 17) = false := by decide +kernel

/-- Une semaine de 50 h isolée passe : c'est une moyenne. -/
example : moyenne48h 17 (semaines journee10h 1) = true := by decide +kernel

/-- Fin à 23 h, reprise à 7 h : 8 h de repos seulement, le repos quotidien
n'est pas respecté. -/
example : reposQuotidien [⟨instant 0 15 0, instant 0 23 0⟩, ⟨instant 1 7 0, instant 1 12 0⟩]
    = false := by decide

/-- 6 h de travail d'affilée : la pause manque. -/
example : pauses 20 [⟨instant 0 8 0, instant 0 14 0⟩] = false := by decide

/-! ## Chaque règle a un sens

Pour chaque règle de santé, on exhibe un planning qui respecte toutes les
autres règles, mais pas celle-là. Aucune règle n'est donc impliquée par les
autres : chacune protège contre une situation que les autres laissent passer. -/

/-- Toutes les règles de santé, avec les valeurs légales, sous forme de liste
de booléens : bonne forme, repos quotidien, repos hebdomadaire, pauses,
48 h en moyenne, travail de nuit. -/
def regles (p : Planning) : List Bool :=
  [bienForme p, reposQuotidien p, reposHebdomadaire p, pauses dispPause.loi p,
    moyenne48h (periodeReference none) p, nuit8h p]

/-- Fin à 23 h, reprise à 7 h le lendemain : seul le repos quotidien manque. -/
def exempleReposQuotidien : Planning :=
  [⟨instant 0 15 0, instant 0 20 0⟩, ⟨instant 0 20 20, instant 0 23 0⟩,
    ⟨instant 1 7 0, instant 1 12 0⟩]

theorem reposQuotidien_independant :
    regles exempleReposQuotidien = [true, false, true, true, true, true] := by decide +kernel

/-- Six journées de 7 h, du lundi au samedi (42 h) : du samedi 17 h au lundi
0 h, il n'y a que 31 h de repos. Seul le repos hebdomadaire manque. -/
def exempleReposHebdomadaire : Planning := (List.range 6).flatMap journee7h

theorem reposHebdomadaire_independant :
    regles exempleReposHebdomadaire = [true, true, false, true, true, true] := by decide +kernel

/-- 8 h – 14 h d'affilée : seule la pause manque. -/
def exemplePauses : Planning := [⟨instant 0 8 0, instant 0 14 0⟩]

theorem pauses_independantes :
    regles exemplePauses = [true, true, true, false, true, true] := by decide +kernel

/-- 50 h par semaine pendant 17 semaines, repos et pauses respectés : seule la
moyenne de 48 h est dépassée. -/
def exempleMoyenne48h : Planning := semaines journee10h 17

theorem moyenne48h_independante :
    regles exempleMoyenne48h = [true, true, true, true, false, true] := by decide +kernel

/-- Une nuit de 10 h : 21 h – 2 h, pause de 20 minutes, 2 h 20 – 7 h 20. -/
def nuit10h (j : ℕ) : Planning :=
  [⟨instant j 21 0, instant (j + 1) 2 0⟩, ⟨instant (j + 1) 2 20, instant (j + 1) 7 20⟩]

/-- Quatre nuits de 10 h, du lundi soir au vendredi matin (40 h) : repos,
pauses et 48 h respectés, mais un travailleur de nuit fait 10 h par journée. -/
def exempleNuit : Planning := (List.range 4).flatMap nuit10h

theorem nuit8h_independante :
    regles exempleNuit = [true, true, true, true, true, false] := by decide +kernel

end Prouvhommes
