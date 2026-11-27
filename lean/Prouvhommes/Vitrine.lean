import Prouvhommes.Preavis
import Prouvhommes.Indemnite
import Prouvhommes.Rupture
import Prouvhommes.Hierarchie
import Prouvhommes.TempsDeTravail
import Prouvhommes.HeuresSup
import Prouvhommes.Conges
import Prouvhommes.Modele

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

/-! Pas d'effet de seuil : un mois d'ancienneté de plus augmente l'indemnité de moins de 3/80 du salaire de référence, plus un centime. -/

/-- info: 'Prouvhommes.indemnite_saut_mensuel' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms indemnite_saut_mensuel

/-! ## Rupture (P1, P3, P4, P8, P9, P9 bis) -/

/-! T-PREAVIS : toute fin est justifiée par un préavis couru, un juste motif, un accord écrit ou un décès. -/

/-- info: 'Prouvhommes.fin_justifiee' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms fin_justifiee

/-! Un licenciement après l'essai laisse au moins durée d'essai + 30 jours, quels que soient l'accord d'entreprise et le contrat. -/

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

/-! ## Modèle composé : conventions, rupture et indemnité ensemble -/

/-! Pour l'employeur, faire signer un accord écrit au lieu de licencier met fin au contrat au moins 30 jours plus tôt, et sans indemnité. -/

/-- info: 'Prouvhommes.accord_domine_licenciement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms accord_domine_licenciement

/-! Un licenciement reçu au jour 364 laisse 30 jours de préavis, reçu au jour 365 il en laisse 60 : un jour de retard allonge la relation de 31 jours. -/

/-- info: 'Prouvhommes.seuil_preavis' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms seuil_preavis

/-! La durée minimale ne vaut pas pour la démission : un contrat peut ramener le préavis du salarié à zéro. -/

/-- info: 'Prouvhommes.demission_sans_duree_minimale' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms demission_sans_duree_minimale

/-! ## Hiérarchie des normes (M4, P15) -/

/-! Absolue : aucune dérogation. -/

/-- info: 'Prouvhommes.applicable_absolue' depends on axioms: [propext] -/
#guard_msgs in #print axioms applicable_absolue

/-! Relative : jamais moins favorable que la loi. -/

/-- info: 'Prouvhommes.applicable_relative_plancher' depends on axioms: [propext] -/
#guard_msgs in #print axioms applicable_relative_plancher

/-! Relative : principe de faveur, au moins aussi favorable que chaque stipulation. -/

/-- info: 'Prouvhommes.applicable_relative_faveur' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms applicable_relative_faveur

/-! Relative : une clause moins favorable que la loi est sans effet. -/

/-- info: 'Prouvhommes.applicable_relative_clause_defavorable' depends on axioms: [propext] -/
#guard_msgs in #print axioms applicable_relative_clause_defavorable

/-! Dispositive : primauté de l'accord d'entreprise (P15). -/

/-- info: 'Prouvhommes.applicable_dispositive_accord' depends on axioms: [propext] -/
#guard_msgs in #print axioms applicable_dispositive_accord

/-! Dispositive : la limite absolue n'est jamais dépassée. -/

/-- info: 'Prouvhommes.applicable_dispositive_limite' depends on axioms: [propext] -/
#guard_msgs in #print axioms applicable_dispositive_limite

/-! Le préavis dû par l'employeur n'est jamais plus court que le préavis légal. -/

/-- info: 'Prouvhommes.preavisEmployeur_ge_legal' depends on axioms: [propext] -/
#guard_msgs in #print axioms preavisEmployeur_ge_legal

/-! Le préavis dû par le salarié n'est jamais plus long que le préavis légal. -/

/-- info: 'Prouvhommes.preavisSalarie_le_legal' depends on axioms: [propext] -/
#guard_msgs in #print axioms preavisSalarie_le_legal

/-! L'essai ne dépasse jamais 90 jours. -/

/-- info: 'Prouvhommes.dureeEssai_le_max' depends on axioms: [propext] -/
#guard_msgs in #print axioms dureeEssai_le_max

/-! ## Temps de travail et congés (P10 à P13) -/

/-! Les journées de travail partitionnent le planning. -/

/-- info: 'Prouvhommes.grouper_flatten' depends on axioms: [propext] -/
#guard_msgs in #print axioms grouper_flatten

/-! Avec le repos quotidien, aucune journée ne compte plus de 13 h de travail. -/

/-- info: 'Prouvhommes.travail_journee_le_13h' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms travail_journee_le_13h

/-! Avec les pauses, on ne travaille jamais 6 h d'affilée. -/

/-- info: 'Prouvhommes.travail_continu_lt_6h' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms travail_continu_lt_6h

/-! La période de référence ne dépasse jamais 26 semaines (6 mois). -/

/-- info: 'Prouvhommes.periodeReference_le_26' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms periodeReference_le_26

/-! Un travailleur de nuit ne travaille jamais plus de 8 h dans une journée. -/

/-- info: 'Prouvhommes.travail_nuit_journee_le_8h' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms travail_nuit_journee_le_8h

/-! Chaque règle de santé a un sens : repos quotidien. -/

/-- info: 'Prouvhommes.reposQuotidien_independant' depends on axioms: [propext] -/
#guard_msgs in #print axioms reposQuotidien_independant

/-! Chaque règle de santé a un sens : repos hebdomadaire. -/

/-- info: 'Prouvhommes.reposHebdomadaire_independant' depends on axioms: [propext] -/
#guard_msgs in #print axioms reposHebdomadaire_independant

/-! Chaque règle de santé a un sens : pauses. -/

/-- info: 'Prouvhommes.pauses_independantes' depends on axioms: [propext] -/
#guard_msgs in #print axioms pauses_independantes

/-! Chaque règle de santé a un sens : 48 h en moyenne. -/

/-- info: 'Prouvhommes.moyenne48h_independante' depends on axioms: [propext] -/
#guard_msgs in #print axioms moyenne48h_independante

/-! Chaque règle de santé a un sens : travail de nuit. -/

/-- info: 'Prouvhommes.nuit8h_independante' depends on axioms: [propext] -/
#guard_msgs in #print axioms nuit8h_independante


/-! Une heure supplémentaire est payée au moins au taux normal. -/

/-- info: 'Prouvhommes.paiementHS_ge_normal' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms paiementHS_ge_normal

/-! Le droit à congés n'est jamais inférieur à 20 jours. -/

/-- info: 'Prouvhommes.conges_ge_legal' depends on axioms: [propext] -/
#guard_msgs in #print axioms conges_ge_legal

/-! Pas de rachat des congés pendant le contrat. -/

/-- info: 'Prouvhommes.pas_de_rachat_conges' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms pas_de_rachat_conges

end Prouvhommes
