# Site web — décisions de conception (v0.1)

> Objectif : montrer le code et sa formalisation comme un seul objet, lisible par un public large.
> Statut : décidé le 27/11/2026, rien d'implémenté.

## Concepts retenus

1. **Deux faces liées mot à mot.** Chaque article a une face *droit* et une face *maths* (Lean). Survoler ou focaliser un passage du texte (« six mois ») surligne son pendant formel (`6`), et réciproquement.
   - La formalisation est **toujours un menu déroulant sous le texte de l'article**, fermé par défaut (décidé le 27/11/2026). Chaque garantie a aussi le sien, avec l'énoncé exact du théorème, sans la preuve.
   - **Alignement** : le texte du site est celui du PDF (y compris ses tableaux et l'apostrophe typographique) ; `site/law/alignment.test.js` vérifie que les seuils du site sont les constantes Lean, que chaque lien trouve son pendant Lean et qu'aucune commande LaTeX n'atteint une page.
2. **Les seuils sont des nombres vivants** (M1). Les nombres de l'article sont des contrôles : on les fait varier, la courbe se redessine et chaque promesse est réévaluée (tenue, ou rompue avec un contre-exemple).
   - Honnêteté : seules les promesses calculables sont revérifiées dans le navigateur. Pour les autres, une valeur modifiée affiche « prouvé pour les valeurs actuelles seulement », jamais une coche verte.
3. **Les notions ouvertes sont des trous** (M2). *Juste motif* et les autres prédicats opaques sont dessinés en cadre pointillé vide, dans le texte comme dans le Lean : le théorème tient quoi que le juge mette dans le cadre.

## Modules de la v1

| Module | Contenu |
|---|---|
| Lecteur d'articles | Concepts 1 à 3 ; niveau d'impérativité en marge (M4) |
| Simulateur d'indemnité | P6 exact, courbe smoothstep comparée au droit actuel |
| Simulateur de préavis | M8 : la courbe continue comparée aux paliers du droit actuel, et ce que change une notification reçue un jour plus tard (`fin_preavis_succ`) |
| Démo anti-manipulation | Varier le dernier salaire : SR ne bouge que de αΔ/B (moins de Δ/22 après 5 ans à temps plein) |
| Tableau des preuves | Promesses en français, statut (prouvé, `sorry`, à écrire), lien vers le théorème |

## Structure du site (décidé le 27/11/2026)

Une page d'accueil, puis quatre onglets.

| Page | Adresse | Contenu |
|---|---|---|
| Accueil | `/` | Accroche, quatre portes d'entrée (une par onglet), quelques promesses choisies à la main |
| Le code | `/code/` | Sommaire par titre : niveau d'impérativité et état de la formalisation de chaque article |
| — un article | `/code/<label>/` | Les deux faces, les garanties, le simulateur lié en version courte, articles voisins. L'adresse vient du `\label` (`art:indemnite` → `/code/indemnite/`), elle survit à la renumérotation |
| — texte intégral | `/code/texte-integral/` | Tous les articles à la suite, et le PDF |
| Promesses | `/promesses/` | Compteurs, puis chaque théorème une seule fois, avec les articles qui le citent ; enfin, sous « Propriétés de l'ensemble », les théorèmes de la vitrine qu'aucun article ne cite (modèle composé) |
| Simulateurs | `/simulateurs/`, `/simulateurs/<nom>/` | Chaque simulateur en version complète, avec ses seuils modifiables |
| Méthode | `/methode/` | L'introduction du texte, lue depuis le LaTeX, puis la légende du site |

Toutes les pages sont générées au build (`site/law/pages.js`) : un nouvel article a sa page sans qu'on ajoute de fichier. Une variante (`?plafond=7`) suit le lecteur de page en page.

## Style : Codex + chiffres suisses

- **Texte de loi** : serif (Source Serif 4) sur fond papier.
- **Chiffres, numéros d'article, résultats, interface** : grotesque (Inter Tight), en grand corps.
- **Lean** : JetBrains Mono. **Formules** : HTML et typographie mathématique, car les seuils vivants (des boutons) ne peuvent pas vivre dans du MathML.
- Polices auto-hébergées (pas d'appel à Google Fonts).
- **Un seul accent** : bordeaux. Lien droit ↔ maths = surlignage bordeaux pâle ; nombre vivant = soulignement pointillé ; trou = cadre pointillé gris.

| Jeton | Clair | Sombre |
|---|---|---|
| `--paper` | `#F7F3EA` | `#1A1714` |
| `--ink` | `#2A2620` | `#E9E2D4` |
| `--ink-soft` | `#6B6355` | `#A79E8D` |
| `--rule` | `#D9CFBC` | `#3A332B` |
| `--accent` (bordeaux) | `#8A2E2A` | `#D98A80` |
| `--link-bg` / `--link-fg` | `#EBD3CF` / `#6E1F1B` | `#4A2522` / `#F2C9C2` |
| `--code-bg` | `#EFE8D8` | `#24201B` |

Valeurs indicatives, à vérifier au contraste (WCAG AA) pendant l'implémentation.

**Thème** : suit le réglage du système (`color-scheme: light dark`, `light-dark()`), avec un bouton qui le remplace et mémorise le choix.

## Technique

- **Vanilla + Vite**, site statique dans `site/`, déployé par Vercel (aperçu sur chaque PR). Fonctionnalités natives (popover ancré, container queries, Highlight API, `color-scheme` piloté par `<meta>`), selon la Modern Web Guidance.
- **Calcul exact** (M5) : rationnels en `BigInt`, un seul arrondi final au centime inférieur, comme en Lean. Jamais de flottants pour un montant affiché.
- **Langue** : les textes du site sont en français ; le code est en anglais (identifiants, commentaires, classes CSS, jetons).
- **Contenu lu à la source** (`site/law/`) : au build, le site lit `texte/` (numéro, titre, impérativité, `\lean`, `\theoreme` de chaque article) et `lean/` (source et docstring des déclarations ; statut « prouvé » pour les théorèmes épinglés dans `Vitrine.lean`). Rien n'est recopié à la main.
- **Articles annotés** (`site/law/enriched.js`) : pour les articles interactifs, une copie du texte avec les liens droit ↔ Lean, les seuils vivants et les notions ouvertes. Le build avertit si le LaTeX de l'article change. Les autres articles sont rendus tels quels depuis le LaTeX.
- **Variantes** : les seuils modifiés passent dans l'URL (`/code/?plafond=7`), pour partager une variante. Une variante n'affiche jamais « prouvé » : soit un contre-exemple, soit « vérifiée par le calcul ».
