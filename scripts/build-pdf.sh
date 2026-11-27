#!/usr/bin/env bash
# Compile le texte du code en PDF : texte/prouvhommes.pdf (versionné).
# Avec --stage, ajoute le PDF à l'index (utilisé par les hooks git).
#
# Le build est reproductible : tant que texte/ ne change pas, le PDF est
# identique octet pour octet, donc un commit qui ne touche pas au texte ne
# modifie pas le PDF. La date (\today et métadonnées) est celle, arrondie au
# jour, du dernier commit qui touche texte/, ou d'aujourd'hui si texte/ a des
# modifications en cours.
#
# Le PDF porte dans ses métadonnées l'empreinte des sources dont il est issu
# (scripts/texte-fingerprint.sh) : la CI vérifie ainsi qu'il est à jour.
#
# Les commandes git tournent depuis la racine : dans un hook, git définit
# GIT_DIR et prendrait le répertoire courant pour la racine du dépôt.
set -euo pipefail

racine="$(git rev-parse --show-toplevel)"
cd "$racine"
export PATH="/Library/TeX/texbin:$PATH"

if ! command -v latexmk >/dev/null; then
  echo "build-pdf : latexmk introuvable (TeX Live requis)." >&2
  echo "Pour committer sans recompiler : git commit --no-verify" >&2
  exit 1
fi

sources=(texte ':!texte/prouvhommes.pdf')
epoch=""
if git diff --cached --quiet -- "${sources[@]}" && git diff --quiet -- "${sources[@]}"; then
  epoch="$(git log -1 --format=%ct -- "${sources[@]}" 2>/dev/null || true)"
fi
[ -n "$epoch" ] || epoch="$(date +%s)"
export SOURCE_DATE_EPOCH=$(( epoch - epoch % 86400 ))
export FORCE_SOURCE_DATE=1

empreinte="$(./scripts/texte-fingerprint.sh)"

mkdir -p texte/build
if ! (cd texte && latexmk -g -pdf -interaction=nonstopmode -halt-on-error \
    -usepretex="\\def\\empreinte{$empreinte}" \
    -outdir=build main.tex >build/build-pdf.log 2>&1); then
  echo "build-pdf : échec de la compilation LaTeX. Fin du journal :" >&2
  tail -20 texte/build/build-pdf.log >&2
  exit 1
fi

cp texte/build/main.pdf texte/prouvhommes.pdf
if [ "${1:-}" = "--stage" ]; then
  git add texte/prouvhommes.pdf
fi
echo "build-pdf : texte/prouvhommes.pdf à jour."
