import Prouvhommes.Preavis

/-!
# Vitrine

Les théorèmes phares du code. Pour chacun, `#guard_msgs` fige la sortie de
`#print axioms` : la compilation échoue si une preuve dépend de `sorryAx`
ou d'un axiome autre que les trois axiomes standard de Lean
(`propext`, `Classical.choice`, `Quot.sound`).
-/

namespace Prouvhommes

/-! ## Préavis (P4) -/

/-- info: 'Prouvhommes.preavisLegal_ge_30' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms preavisLegal_ge_30

/-- info: 'Prouvhommes.preavisLegal_monotone' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms preavisLegal_monotone

end Prouvhommes
