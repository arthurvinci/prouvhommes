# Site web — décisions de conception (v0.1)

> Objectif : montrer le code et sa formalisation comme un seul objet, lisible par un public large.
> Statut : décidé le 27/11/2026, rien d'implémenté.

## Concepts retenus

1. **Deux faces liées mot à mot.** Chaque article a une face *droit* et une face *maths* (Lean). Survoler ou focaliser un passage du texte (« six mois ») surligne son pendant formel (`6`), et réciproquement. Côte à côte sur grand écran, bascule sur mobile.
2. **Les seuils sont des nombres vivants** (M1). Les nombres de l'article sont des contrôles : on les fait varier, la courbe se redessine et chaque promesse est réévaluée (tenue, ou rompue avec un contre-exemple).
   - Honnêteté : seules les promesses calculables sont revérifiées dans le navigateur. Pour les autres, une valeur modifiée affiche « prouvé pour les valeurs actuelles seulement », jamais une coche verte.
3. **Les notions ouvertes sont des trous** (M2). *Juste motif* et les autres prédicats opaques sont dessinés en cadre pointillé vide, dans le texte comme dans le Lean : le théorème tient quoi que le juge mette dans le cadre.

## Modules de la v1

| Module | Contenu |
|---|---|
| Lecteur d'articles | Concepts 1 à 3 ; niveau d'impérativité en marge (M4) |
| Simulateur d'indemnité | P6 exact, courbe smoothstep comparée au droit actuel et à la Suisse |
| Démo anti-manipulation | Varier le dernier salaire : SR ne bouge que de Δ/24 |
| Tableau des preuves | Promesses en français, statut (prouvé, `sorry`, à écrire), lien vers le théorème |

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
