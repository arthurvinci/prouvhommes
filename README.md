# Prouv'hommes

> Un code du travail au régime, prouvé en Lean.

**Prouv'hommes** propose un code du travail français radicalement simplifié (environ 50 pages, d'inspiration libérale) et le formalise mathématiquement pour prouver des propriétés sur lui. Par exemple :

- l'indemnité de rupture ne dépasse jamais 6 mois de salaire de référence ;
- baisser le dernier salaire avant un licenciement ne change presque rien à l'indemnité ;
- aucune relation de travail ne se termine sans préavis ou juste motif.

## Organisation du dépôt

| Dossier | Contenu |
|---|---|
| `docs/` | La charte des principes et les décisions de conception |
| `texte/` | Le texte du code, en LaTeX (un fichier par titre) |
| `lean/` | La formalisation en Lean 4 + Mathlib : définitions et théorèmes |
| `catala/` | La version exécutable en [Catala](https://catala-lang.org/), pour calculer des cas concrets |
| `site/` | Le site web (Vite), déployé par Vercel ; conception dans [`docs/frontend.md`](docs/frontend.md) |

## Compiler

**Le texte (PDF)**

```sh
cd texte && latexmk -pdf main.tex
```

**La formalisation Lean**

Il faut [elan](https://github.com/leanprover/elan). La version de Lean et la révision de Mathlib sont épinglées dans le dépôt (`lean/lean-toolchain`, `lean/lake-manifest.json`). Au premier lancement, le script télécharge le cache de Mathlib :

```sh
./scripts/setup-lean.sh
cd lean && lake build
```

La compilation échoue si une preuve contient `sorry` (cf. `lean/Prouvhommes/Vitrine.lean` et `scripts/check-sorry.sh`). Pour passer à une version plus récente de Mathlib, lancer `./scripts/update-mathlib.sh` puis commiter les deux fichiers épinglés.

**La version Catala** : à venir.

**Le site web**

Il faut Node 20 ou plus récent :

```sh
cd site && npm install && npm run dev
```

Chaque PR qui touche `site/` reçoit un aperçu Vercel ; `main` est le site en production.

## Méthode

Chaque article du texte a sa contrepartie formelle. Les règles d'écriture (seuils chiffrés, notions ouvertes déclarées, règle générale puis exceptions, trois niveaux d'impérativité) sont décrites dans [`docs/charte.md`](docs/charte.md).

