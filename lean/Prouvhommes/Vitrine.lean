import Prouvhommes.Preavis
import Prouvhommes.Indemnite
import Prouvhommes.Rupture

/-!
# Vitrine

Les théorèmes phares du code. Pour chacun, `#guard_msgs` fige la sortie de
`#print axioms` : la compilation échoue si une preuve dépend de `sorryAx`
ou d'un axiome autre que les trois axiomes standard de Lean
(`propext`, `Classical.choice`, `Quot.sound`). Certaines preuves n'en utilisent
qu'une partie.
-/

namespace Prouvhommes

/-! ## Préavis (P4) -/

/-- info: 'Prouvhommes.preavisLegal_ge_30' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms preavisLegal_ge_30

/-- info: 'Prouvhommes.preavisLegal_monotone' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms preavisLegal_monotone

/-! ## Indemnité de rupture (P6) -/

/-! T-PLAFOND : l'indemnité ne dépasse jamais 6 mois de salaire de référence. -/

/-- info: 'Prouvhommes.indemniteRupture_le_plafond' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms indemniteRupture_le_plafond

/-! T-MANIP : baisser le dernier salaire de Δ baisse l'indemnité de moins de Δ/4 + 1 centime. -/

/-- info: 'Prouvhommes.indemniteRupture_manipulation' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms indemniteRupture_manipulation

/-! Le dernier salaire ne pèse que 1/24 dans le salaire de référence. -/

/-- info: 'Prouvhommes.salaireReference_sensibilite' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms salaireReference_sensibilite

/-! Pas d'indemnité hors licenciement ordinaire. -/

/-- info: 'Prouvhommes.indemniteRupture_eq_zero' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms indemniteRupture_eq_zero

/-! L'indemnité croît avec l'ancienneté. -/

/-- info: 'Prouvhommes.indemnite_mono_anciennete' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms indemnite_mono_anciennete

/-! ## Rupture (P1, P3, P4, P8, P9, P9 bis) -/

/-! T-PREAVIS : toute fin est justifiée par un préavis couru, un juste motif, un accord écrit ou un décès. -/

/-- info: 'Prouvhommes.fin_justifiee' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms fin_justifiee

/-! Une relation résiliée après l'essai dure au moins durée d'essai + 30 jours. -/

/-- info: 'Prouvhommes.duree_minimale' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms duree_minimale

/-! Pas de préavis ordinaire avant la fin de l'essai. -/

/-- info: 'Prouvhommes.preavis_ordinaire_apres_essai' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms preavis_ordinaire_apres_essai

/-! Pas de résiliation immédiate sans juste motif, pour toute interprétation. -/

/-- info: 'Prouvhommes.fin_resiliationImmediate' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms fin_resiliationImmediate

/-! Le temps seul ne met jamais fin à la relation. -/

/-- info: 'Prouvhommes.pas_de_terme' depends on axioms: [propext, Classical.choice] -/
#guard_msgs in #print axioms pas_de_terme

/-! Protection : congé de l'employeur nul. -/

/-- info: 'Prouvhommes.protection_nullite' depends on axioms: [propext, Classical.choice] -/
#guard_msgs in #print axioms protection_nullite

/-! Protection : préavis de l'employeur suspendu. -/

/-- info: 'Prouvhommes.protection_suspend' depends on axioms: [propext, Classical.choice] -/
#guard_msgs in #print axioms protection_suspend

end Prouvhommes
