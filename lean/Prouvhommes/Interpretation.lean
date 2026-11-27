import Prouvhommes.Basic

/-!
# Notions ouvertes (M2)

Certaines notions demandent un jugement : on ne les définit pas. On les regroupe
dans une structure `Interpretation`, passée en paramètre. Tous les théorèmes de
fond sont énoncés pour **toute** interprétation : ils restent vrais quelle que
soit la façon dont un juge appréciera ces notions.

Liste fermée des notions ouvertes (annexe du texte) :
* `justeMotif` : juste motif de résiliation immédiate (P9).
-/

namespace Prouvhommes

/-- Une interprétation des notions ouvertes du code (M2). -/
structure Interpretation where
  /-- Les faits invoqués à l'appui d'une décision. -/
  Faits : Type
  /-- Ces faits constituent-ils un juste motif de résiliation immédiate (P9) ? -/
  justeMotif : Faits → Prop

end Prouvhommes
