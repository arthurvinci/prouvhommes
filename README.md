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

La dernière version compilée est versionnée : [`texte/prouvhommes.pdf`](texte/prouvhommes.pdf). Pour la régénérer :

```sh
./scripts/build-pdf.sh
```

Un hook git recompile le PDF et l'ajoute à chaque commit. Le build est reproductible : un commit qui ne touche pas au texte ne change pas le PDF. Pour activer le hook, une fois par clone (TeX Live requis) :

```sh
./scripts/install-hooks.sh
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

Chaque PR qui touche `site/` reçoit un aperçu Vercel ; `main` est le site en production. Les tests (`npm test`) lisent le vrai texte et la vraie formalisation : ils vérifient notamment que le niveau d'impérativité de chaque article est celui de la disposition Lean qu'il cite.

## Vérifications

Toute modification passe par une PR, que le propriétaire du dépôt doit approuver (`.github/CODEOWNERS`) ; l'administrateur du dépôt peut passer outre lors de la fusion. La CI lance, selon les fichiers touchés :

| Job | Vérifie |
|---|---|
| Texte (LaTeX) | Le texte compile ; le PDF versionné est issu des sources actuelles (`scripts/check-pdf.sh`). |
| Formalisation (Lean) | Aucun `sorry` ; tout compile, y compris les `#print axioms` de `Vitrine.lean` ; chaque nom cité par `\lean{}` existe et chaque `\theoreme{}` est démontré sans axiome non standard (`scripts/check-renvois.sh`). |
| Site (tests et build) | Les tests du site, puis son build. |

## Méthode

Chaque article du texte a sa contrepartie formelle. Les règles d'écriture (seuils chiffrés, notions ouvertes déclarées, règle générale puis exceptions, trois niveaux d'impérativité) sont décrites dans [`docs/charte.md`](docs/charte.md).

