# Charte des principes — Prouv'hommes (v0.5, brouillon)

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
- **M5. Temps discret, calcul exact.** Jour, heure, et mois pour l'ancienneté. Calculs intermédiaires en rationnels exacts (`ℚ`), un seul arrondi final au centime inférieur. Jamais de flottants.
- **M6. Procédures = machines à états finies.**
- **M7. Budget.** Au plus 50 articles. Chaque article dit quelle propriété formelle il préserve ou ajoute.

---

## 2. Principes de fond

### Contrat
- **P1. Contrat unique, sans terme** (DÉCIDÉ). Le contrat n'a qu'une seule forme. Aucune date de fin ne peut être convenue : la relation ne prend fin que par un préavis ou une résiliation immédiate pour juste motif.
  - **Pas de préavis anticipé** (DÉCIDÉ). Le préavis ordinaire (P4) ne peut être notifié qu'après la fin de la période d'essai. Pendant l'essai, seule la rupture d'essai (P3) est possible.
  - Théorème visé : toute relation qui survit à la période d'essai dure au moins *durée d'essai + 30 jours*, sauf résiliation immédiate pour juste motif.
- **P2. Écrit minimal.** Le contrat écrit indique les parties, la date de début, la fonction, le salaire et la durée de travail convenue.
- **P3. Période d'essai.** 1 mois par défaut, 3 mois au maximum ; rupture libre avec 7 jours de préavis pendant l'essai.

### Rupture
- **P4. Liberté de résiliation des deux parties, sans motif** (DÉCIDÉ). Préavis progressif : 1 mois la 1ʳᵉ année, 2 mois de la 2ᵉ à la 9ᵉ, 3 mois ensuite (`relative`).
- **P5. Motivation sur demande.** C'est une simple information, pas une condition de validité.
- **P6. Indemnité de rupture** (DÉCIDÉ).

  `indemnité = ⌊ SR × 6 × S(min(m, 240) / 240) ⌋`

  - **S** = smoothstep 3t² − 2t³ ; **m** = ancienneté en mois ; saturation à 240 mois (20 ans) ; plafond de 6 mois de salaire de référence.
  - **Cas où elle est due :** uniquement en cas de résiliation ordinaire **par l'employeur** (P4). Elle n'est pas due en cas de démission ni de résiliation immédiate pour juste motif (P9).
  - **SR = salaire de référence = EMA des salaires mensuels :**
    - **Fenêtre :** les 60 derniers mois **payés**. Les mois sans salaire (suspension, période de protection) sont exclus et la fenêtre remonte d'autant. Si le contrat compte moins de 60 mois payés, on prend tous ses mois.
    - **Récurrence :** du plus ancien au plus récent, e₁ = s₁ puis eₖ = (1/24)·sₖ + (23/24)·eₖ₋₁.
    - **Salaire mensuel :** rémunération brute totale du mois, primes et heures supplémentaires comprises.
    - **Propriété anti-manipulation :** une variation Δ du dernier salaire ne déplace SR que de Δ/24.
- **P7. Congé abusif = liste fermée de motifs interdits.** Sanction : indemnité forfaitaire plafonnée, sans réintégration.
- **P8. Périodes de protection.** Congé nul pendant une incapacité ou une maternité ; un préavis en cours est suspendu.
- **P9. Résiliation immédiate pour juste motif** (notion ouverte, M2).

### Temps de travail (aligné sur la directive 2003/88, DÉCIDÉ)
- **P10. Pas de durée légale.** Seule la durée contractuelle existe.
- **P11. Plafonds de santé** (`absolue`) :
  - 48 h en moyenne par période de 7 jours, heures supplémentaires comprises, sur une période de référence de 4 mois. Un accord collectif peut l'étendre à 6 mois, et à 12 mois au maximum.
  - 11 h de repos consécutives par 24 h.
  - Repos hebdomadaire de 24 h sans interruption, cumulé avec les 11 h de repos quotidien.
  - Une pause dès que la journée dépasse 6 h.
  - Travail de nuit : 8 h en moyenne par 24 h.
  - [À TRANCHER] Ouvrir l'opt-out individuel permis par l'art. 22 de la directive ?
- **P12. Heures supplémentaires.** Au-delà de la durée contractuelle, majoration de 10 % par défaut (`dispositive`).
- **P13. Congés.** 4 semaines payées par an, non remplaçables par une indemnité sauf à la fin du contrat (`absolue`).

### Salaire et collectif
- **P14. Pas de salaire minimum** (DÉCIDÉ). Le salaire est librement convenu et payé au moins une fois par mois.
- **P15. Primauté de l'accord d'entreprise** sur toute disposition `dispositive`.
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
