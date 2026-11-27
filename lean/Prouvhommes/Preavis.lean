import Prouvhommes.Basic

/-!
# Préavis (P3, P4)

Un seul préavis, pendant l'essai comme après, fonction **continue** de
l'ancienneté au jour de la réception de la notification. La courbe est affine
par morceaux et passe par :

| ancienneté | 0 | 30 jours | 1 an (365 j) | 9 ans (3 285 j) et plus |
|---|---|---|---|---|
| préavis | 7 j | 30 j | 60 j | 90 j |

Elle est **concave** (ses pentes décroissent : 23/30, 6/67, 3/292, puis 0) :
c'est donc le minimum de ses quatre morceaux, ce qui rend les preuves
élémentaires. Le résultat est arrondi au jour inférieur. En `ℕ`, la
soustraction tronquée ne change rien : avant son point de départ, un morceau
vaut sa valeur en ce point, qui dépasse déjà la courbe.

Il n'y a aucun effet de seuil : un jour d'ancienneté de plus allonge le préavis
d'au plus un jour (`preavis_succ_le`). Notifier un jour plus tard fait donc
finir le contrat 1 ou 2 jours plus tard, jamais plus, jamais plus tôt
(`fin_preavis_succ`).

Tous les préavis sont comptés en jours (M1) et courent à partir du lendemain
de la réception de la notification. L'ancienneté est comptée en jours depuis
le début du contrat ; une année révolue vaut 365 jours.
-/

namespace Prouvhommes

/-- **Préavis** en jours, pour une notification reçue au jour `j` d'ancienneté
(P3, P4) : `⌊min(7 + 23j/30, 30 + 6(j − 30)/67, 60 + 3(j − 365)/292, 90)⌋`. -/
def preavis (j : Jour) : ℕ :=
  min (min (7 + 23 * j / 30) (30 + 6 * (j - 30) / 67)) (min (60 + 3 * (j - 365) / 292) 90)

/-! ## Points de passage -/

theorem preavis_zero : preavis 0 = 7 := by decide
theorem preavis_un_mois : preavis 30 = 30 := by decide
theorem preavis_un_an : preavis 365 = 60 := by decide
theorem preavis_neuf_ans : preavis 3285 = 90 := by decide

/-- Au-delà de 9 ans, le préavis est constant : 90 jours. -/
theorem preavis_sature {j : Jour} (h : 3285 ≤ j) : preavis j = 90 := by
  unfold preavis; omega

/-! ## Bornes et monotonie -/

/-- Le préavis n'est jamais inférieur à 7 jours. -/
theorem preavis_ge_7 (j : Jour) : 7 ≤ preavis j := by
  unfold preavis; omega

/-- Le préavis ne dépasse jamais 90 jours. -/
theorem preavis_le_90 (j : Jour) : preavis j ≤ 90 := by
  unfold preavis; omega

/-- Le préavis croît avec l'ancienneté. -/
theorem preavis_monotone : Monotone preavis := by
  intro a b h
  unfold preavis
  omega

/-- **Pas d'effet de seuil.** Un jour d'ancienneté de plus allonge le préavis
d'au plus un jour. -/
theorem preavis_succ_le (j : Jour) : preavis (j + 1) ≤ preavis j + 1 := by
  unfold preavis
  omega

/-- **Notifier un jour plus tard** fait finir le contrat 1 ou 2 jours plus tard :
jamais plus tôt, jamais plus de 2 jours plus tard. -/
theorem fin_preavis_succ (j : Jour) :
    j + preavis j + 1 ≤ (j + 1) + preavis (j + 1) ∧
      (j + 1) + preavis (j + 1) ≤ j + preavis j + 2 := by
  have h1 := preavis_monotone (by omega : j ≤ j + 1)
  have h2 := preavis_succ_le j
  omega

/-- À partir de la fin d'un essai de 30 jours, le préavis n'est jamais plus
court que dans la version à paliers de la charte v0.5 (30 jours la première
année, 60 jours de la 2ᵉ à la 9ᵉ, 90 jours ensuite). -/
theorem preavis_ge_paliers {j : Jour} (h : 30 ≤ j) :
    (if j < 365 then 30 else if j < 3285 then 60 else 90) ≤ preavis j := by
  unfold preavis
  split_ifs <;> omega

/-! ## Ancienneté -/

/-- Années révolues d'ancienneté au jour `j` (jour 0 = début du contrat). -/
def anneesRevolues (j : Jour) : ℕ := j / 365

/-- Mois révolus d'ancienneté au jour `j`, cohérents avec les années :
`moisRevolus j / 12 = anneesRevolues j`. -/
def moisRevolus (j : Jour) : Mois := 12 * j / 365

theorem moisRevolus_div_douze (j : Jour) : moisRevolus j / 12 = anneesRevolues j := by
  unfold moisRevolus anneesRevolues
  omega

end Prouvhommes
