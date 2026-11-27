# Charte des principes — Prouv'hommes (v0.9, brouillon)

> Objectif : un code du travail d'environ 50 pages, d'inspiration libérale, écrit dès le départ pour être formalisable en Lean 4.
> Statut : document de travail. Les points marqués [À TRANCHER] restent à décider.

## Journal des décisions
- **27/11/2026**
  - P1 : aucun terme convenu, la relation ne prend fin que par un préavis.
  - P1 : aucun préavis ordinaire avant la fin de la période d'essai.
  - P4 : licenciement libre, sans motif, à la suisse.
  - §4 : retrait de la France de l'OIT, et dénonciation de la convention 158.
  - P6 : indemnité de rupture en sigmoïde (smoothstep) de l'ancienneté, avec A = 20 ans et IMAX = 6 mois de salaire de référence.
  - P6 : le salaire de référence est une EMA des salaires mensuels sur 60 mois au plus, avec α = 1/24.
  - P6 : les mois sans salaire sont exclus de la fenêtre.
  - P6 : pas d'indemnité en cas de démission ni de résiliation immédiate pour juste motif.
  - P11 : temps de travail aligné sur la directive UE 2003/88.
  - P14 : suppression du salaire minimum.
  - P4 : préavis comptés en jours : 30, 60 ou 90 jours (M1).
  - P4 : le préavis court à partir du lendemain de la réception de la notification.
  - P3 : une rupture notifiée pendant l'essai reste une rupture d'essai, même si ses 7 jours de préavis se terminent après la fin de l'essai.
  - P1 : deux autres fins de la relation sont admises : l'accord écrit des parties et le décès du salarié.
  - M4 : pour une disposition `relative`, on applique la valeur la plus favorable au salarié parmi la loi, l'accord d'entreprise et le contrat.
  - P15 : pour une disposition `dispositive`, l'accord d'entreprise l'emporte sur le contrat, qui l'emporte sur la loi.
  - P4 : « en faveur du salarié » s'apprécie dans chaque sens : le préavis dû par l'employeur ne peut qu'être allongé, celui dû par le salarié qu'être raccourci.
  - P11 : pas d'opt-out individuel (art. 22 de la directive) : le plafond de 48 h est absolu.
  - P11 : pause de 20 minutes ; la nuit s'entend de 21 h à 6 h.
  - P11 : le travailleur de nuit est limité à 8 h de travail effectif par journée. La règle « 8 h en moyenne par 24 h » était impliquée par le plafond de 48 h, donc sans effet (prouvé en Lean).
  - P13 : congés comptés en jours ouvrés : 20 jours par an, acquis à raison de 5/3 de jour par mois.
  - P11 : la période de référence ne dépasse pas 26 semaines (6 mois), ce que la directive 2003/88 (art. 19) permet à un accord collectif sans autre condition.
  - P9 bis : l'accord écrit et le décès sont des fins `absolue` ; un article sans niveau ne fait que définir une notion.
  - M8 : pas d'effet de seuil. Toute durée ou tout montant varie de façon continue (en temps discret : par incréments bornés, prouvés en Lean).
  - P3/P4 : un seul préavis, pendant l'essai comme après, fonction continue de l'ancienneté : 7 j au jour 0, 30 j à 30 jours, 60 j à 1 an, 90 j à 9 ans, affine entre ces points. Remplace les paliers 7 / 30 / 60 / 90 jours.
  - P6 : le salaire de référence est une moyenne pondérée des salaires ramenés à temps plein, pondérée par le taux d'activité de chaque mois, sur tout le contrat. Plus de fenêtre de 60 mois, plus de mois exclus.

---

## 0. Inspirations retenues

| Source | Ce qu'on garde |
|---|---|
| **Suisse, CO art. 319-362** | Le contrat de travail tient dans environ 45 articles ; la rupture est libre avec un préavis progressif ; le congé abusif est sanctionné par une indemnité plafonnée (6 mois de salaire max) et non par la nullité ; il existe des périodes de protection ; chaque norme est classée impérative absolue, impérative relative ou dispositive (art. 361/362). |
| **Suisse, Loi sur le travail (LTr)** | Plafonds hebdomadaires de 45 h ou 50 h ; plafond annuel de travail supplémentaire ; 4 semaines de vacances minimum. |
| **Lisnard (Nouvelle Énergie)** | Contrat unique avec indemnités progressives ; un code recentré sur les principes, dans l'esprit Badinter ; la durée du travail est fixée par accord d'entreprise, avec un plancher de 11 h de repos ; heures supplémentaires majorées de 10 % par défaut. |
| **Knafo (Reconquête)** | Mise en avant de la concision suisse (« 49 pages »). La comparaison est contestée, car la Suisse n'a pas de code unique. |
| **Kasbarian** | Ligne libérale assumée (« Parti de la liberté », 2026). Pas de proposition spécifique trouvée sur le code du travail. |
| **PPL Vercamer (2017)** | Rédaction type : « Le contrat de travail a une seule forme. Il est conclu sans détermination de durée. » |
| **Badinter / Lyon-Caen** | Un code bâti sur environ 50 principes intelligibles. |

**Leçon suisse :** la brièveté du CO tient à ce que beaucoup de choses sont laissées au contrat, aux conventions collectives et au juge. Il faut donc assumer explicitement ce qu'on renvoie ailleurs (cf. §3).

---

## 1. Méta-principes (pour la formalisation)

- **M1. Seuils explicites.** Tout seuil est un nombre (jours, heures, centimes, effectif). Aucun « délai raisonnable ».
- **M2. Notions ouvertes déclarées.** Les notions qui demandent un jugement (*juste motif*…) figurent dans une liste fermée. En Lean, ce sont des prédicats opaques. Les théorèmes sont prouvés pour toute interprétation de ces prédicats.
- **M3. Règle générale puis exceptions**, avec des priorités explicites (logique par défaut à la Catala).
- **M4. Trois niveaux d'impérativité** : `absolue` (non dérogeable), `relative` (dérogeable seulement en faveur du salarié), `dispositive` (librement dérogeable).
  - Chaque disposition chiffrée a un **sens favorable** au salarié (plus grand ou plus petit).
  - `relative` (DÉCIDÉ) : on applique la valeur la plus favorable au salarié parmi la loi, l'accord d'entreprise et le contrat. Une stipulation moins favorable que la loi est sans effet.
- **M5. Temps discret, calcul exact.** Jour, heure, et mois pour l'ancienneté. Calculs intermédiaires en rationnels exacts (`ℚ`), un seul arrondi final au centime inférieur. Jamais de flottants.
- **M6. Procédures = machines à états finies.**
- **M7. Budget.** Au plus 50 articles. Chaque article dit quelle propriété formelle il préserve ou ajoute.
- **M8. Pas d'effet de seuil** (DÉCIDÉ). Une durée ou un montant ne saute jamais quand une donnée (ancienneté, salaire, activité) change un peu. En temps discret, cela se dit par des incréments bornés : un jour d'ancienneté de plus allonge le préavis d'au plus un jour ; un mois d'ancienneté de plus augmente l'indemnité de moins de 3/80 du salaire de référence. Les seuils qui restent sont des limites (plafonds de santé, durée maximale de l'essai), pas des paliers de calcul.

---

## 2. Principes de fond

### Contrat
- **P1. Contrat unique, sans terme** (DÉCIDÉ). Le contrat n'a qu'une seule forme. Aucune date de fin ne peut être convenue à l'embauche : la relation ne prend fin que par un préavis, une résiliation immédiate pour juste motif, un accord écrit des parties ou le décès du salarié.
  - **Pas de préavis anticipé** (DÉCIDÉ). Le préavis ordinaire (P4) ne peut être notifié qu'après la fin de la période d'essai. Pendant l'essai, seule la rupture d'essai (P3) est possible.
  - Théorème : un licenciement après l'essai intervient au plus tôt à *durée d'essai + préavis à la fin de l'essai* (60 jours pour l'essai par défaut), quels que soient l'accord et le contrat. Ce n'est pas vrai de la démission, dont le préavis peut être raccourci jusqu'à zéro (prouvé en Lean).
- **P2. Écrit minimal.** Le contrat écrit indique les parties, la date de début, la fonction, le salaire et la durée de travail convenue.
- **P3. Période d'essai.** 30 jours par défaut, 90 jours au maximum ; rupture libre pendant l'essai, avec le préavis de P4 (7 jours au jour 0, 30 jours au jour 30). Le préavis d'essai peut se terminer après la fin de l'essai (DÉCIDÉ). La fin de l'essai ne crée pas de saut de préavis.

### Rupture
- **P4. Liberté de résiliation des deux parties, sans motif** (DÉCIDÉ). Préavis continu (DÉCIDÉ) : `⌊min(7 + 23j/30, 30 + 6(j − 30)/67, 60 + 3(j − 365)/292, 90)⌋` jours, où `j` est l'ancienneté en jours à la réception de la notification ; soit 7 j au jour 0, 30 j au jour 30, 60 j à 1 an, 90 j à 9 ans (`relative`). Jamais moins que les anciens paliers après un essai de 30 jours. Il court à partir du lendemain de la réception de la notification (DÉCIDÉ). Le préavis dû par l'employeur ne peut qu'être allongé, celui dû par le salarié qu'être raccourci (DÉCIDÉ).
- **P5. Motivation sur demande.** C'est une simple information, pas une condition de validité.
- **P6. Indemnité de rupture** (DÉCIDÉ).

  `indemnité = ⌊ SR × 6 × S(min(m, 240) / 240) ⌋`

  - **S** = smoothstep 3t² − 2t³ ; **m** = ancienneté en mois ; saturation à 240 mois (20 ans) ; plafond de 6 mois de salaire de référence.
  - **Cas où elle est due :** uniquement en cas de résiliation ordinaire **par l'employeur** (P4). Elle n'est pas due en cas de démission ni de résiliation immédiate pour juste motif (P9).
  - **SR = salaire de référence = moyenne pondérée des salaires ramenés à temps plein** (DÉCIDÉ) :
    - **Données :** pour chaque mois, le salaire mensuel (rémunération brute totale, primes et heures supplémentaires comprises) et le taux d'activité τ ∈ [0, 1] (fraction du mois travaillée ou rémunérée, congés payés compris).
    - **Récurrence :** sur tout le contrat, du plus ancien au plus récent, A₀ = B₀ = 0, Aₖ = (1/24)·sₖ + (23/24)·Aₖ₋₁, Bₖ = (1/24)·τₖ + (23/24)·Bₖ₋₁ ; SR = A / B (0 si B = 0).
    - **Continuité :** un mois suspendu ne change rien ; un mois presque suspendu presque rien ; un mois partiel payé au prorata rien du tout. Les mois anciens s'effacent progressivement (ceux de plus de 5 ans pèsent moins de 8 % au total), sans sortie brutale d'une fenêtre.
    - **Propriété anti-manipulation :** une variation Δ du dernier salaire déplace SR d'exactement Δ/(24·B) ; après 5 ans à temps plein, moins de Δ/22, donc moins de 3Δ/11 sur l'indemnité.
- **P7. Congé abusif = liste fermée de motifs interdits.** Sanction : indemnité forfaitaire plafonnée, sans réintégration.
- **P8. Périodes de protection.** Congé nul pendant une incapacité ou une maternité ; un préavis en cours est suspendu.
- **P9. Résiliation immédiate pour juste motif** (notion ouverte, M2).
- **P9 bis. Autres fins de la relation** (DÉCIDÉ). Les parties peuvent mettre fin au contrat d'un commun accord, par écrit, sans préavis. Le contrat prend fin de plein droit au décès du salarié. Aucune de ces fins n'ouvre droit à l'indemnité de rupture (P6).

### Temps de travail (aligné sur la directive 2003/88, DÉCIDÉ)
- **P10. Pas de durée légale.** Seule la durée contractuelle existe.
- **P11. Plafonds de santé** (`absolue`, sauf la pause, `relative`) :
  - 48 h en moyenne par semaine civile, heures supplémentaires comprises, sur une période de référence de 17 semaines (4 mois). Seul un accord d'entreprise peut la modifier, dans la limite de 26 semaines, soit 6 mois (`dispositive`). Au-delà, la directive (art. 19) exige des raisons objectives ou techniques : le code ne l'ouvre pas. Pas d'opt-out individuel (DÉCIDÉ).
  - 11 h de repos consécutives entre deux journées de travail ; une journée s'étend donc sur 13 h au plus.
  - Repos hebdomadaire de 35 h consécutives par semaine civile (24 h cumulées avec les 11 h de repos quotidien).
  - Une pause de 20 minutes au moins avant 6 h de travail d'affilée (DÉCIDÉ). `relative` : une pause plus longue est plus favorable.
  - Travail de nuit : 8 h de travail effectif par journée au plus pour le travailleur de nuit (DÉCIDÉ). La nuit s'entend de 21 h à 6 h (DÉCIDÉ). Est travailleur de nuit qui accomplit au moins 3 h de travail de nuit, au moins deux nuits d'une même semaine civile. Une moyenne de 8 h par 24 h serait impliquée par le plafond de 48 h, donc sans effet.
  - Chacune de ces règles est indépendante des autres : pour chacune, un planning respecte toutes les autres mais pas celle-là (prouvé en Lean).
- **P12. Heures supplémentaires.** Au-delà de la durée hebdomadaire contractuelle, majoration de 10 % par défaut (`dispositive`). La majoration ne peut être négative.
- **P13. Congés.** 4 semaines payées par an, soit 20 jours ouvrés, acquis à raison de 5/3 de jour par mois (DÉCIDÉ). Non remplaçables par une indemnité sauf à la fin du contrat (`absolue`).

### Salaire et collectif
- **P14. Pas de salaire minimum** (DÉCIDÉ). Le salaire est librement convenu et payé au moins une fois par mois.
- **P15. Primauté de l'accord d'entreprise** sur toute disposition `dispositive` (DÉCIDÉ) : l'accord d'entreprise l'emporte sur le contrat, le contrat sur la loi. Il s'impose donc aussi au contrat individuel.
- **P16. Principes généraux** (non-discrimination, santé et sécurité, liberté syndicale), formulés comme invariants.

---

## 3. Hors du code (renvoyés ailleurs)
Représentation du personnel, formation professionnelle, assurance chômage, procédure prud'homale, licenciements collectifs (sauf le minimum exigé par la directive 98/59), régimes spéciaux.

## 4. Contraintes externes et dispositions finales
- **Droit de l'UE** : directives 2003/88 (respectée, cf. P11 et P13) et 98/59. Conformité conservée.
- **OIT** (DÉCIDÉ) : le code s'accompagne d'une disposition finale prévoyant le retrait de la France de l'OIT et la dénonciation de la convention 158.
  - Le retrait prend effet 2 ans après sa notification (Constitution de l'OIT, art. 1 §5).
  - Il ne libère pas, à lui seul, des conventions déjà ratifiées : celles-ci restent en vigueur jusqu'à leur dénonciation selon leurs propres clauses.
  - La C158 ne peut être dénoncée que pendant des fenêtres d'un an, tous les 10 ans.
- **Limite** : plusieurs garanties couvertes par des conventions OIT figurent aussi dans le droit de l'UE (Charte des droits fondamentaux) et dans la CEDH. Le retrait de l'OIT ne les supprime pas. P16 les reprend.

---

## 5. Valeurs indicatives de l'indemnité

IMAX = 6, A = 20 ans, en mois de salaire de référence :

| Ancienneté | Ce code | Droit actuel | Suisse |
|---|---|---|---|
| 1 an | ≈ 0,04 | 0,25 | 0 |
| 5 ans | ≈ 0,94 | 1,25 | 0 |
| 10 ans | 3 | 2,5 | 0 |
| 15 ans | ≈ 5,1 | ≈ 4,2 | 0 |
| 20 ans et + | 6 (plafond) | ≈ 5,8 (sans plafond) | 0 (sauf cas particulier des 50 ans et plus) |

---

## Sources
- SECO, source du droit privé du travail : https://www.seco.admin.ch/fr/faq-source-du-droit-prive-du-travail
- SECO, durée du travail et du repos : https://www.seco.admin.ch/duree-du-travail-et-du-repos
- SECO, résiliation du contrat : https://www.seco.admin.ch/fr/faq-resiliation-du-contrat
- Programme Lisnard (emploi) : https://programmes-2027.fr/candidats/lisnard/emploi/
- PresiTracker, Lisnard : https://presitracker2027.fr/candidats/lisnard
- Les Surligneurs sur l'affirmation de Knafo : https://lessurligneurs.eu/le-code-du-travail-francais-fait-4-000-pages-alors-que-le-suisse-nen-fait-que-49/
- Décideurs, Lisnard et Kasbarian : https://www.decideurs-magazine.com/politique-societe/64120-liberalisme-david-lisnard-et-guillaume-kasbarian-s-affranchissent.html
- PPL Vercamer n° 332 : https://www.assemblee-nationale.fr/15/pdf/propositions/pion0332.pdf
- Directive 2003/88/CE ; directive 98/59/CE ; directive (UE) 2022/2041 ; Constitution de l'OIT ; convention OIT n° 158
