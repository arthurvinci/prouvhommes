#!/usr/bin/env bash
# Échoue si texte/prouvhommes.pdf n'a pas été compilé à partir des sources
# actuelles de texte/ : par exemple après un commit sans hook (--no-verify,
# hooks non installés) ou une fusion faite sur GitHub. Ne demande pas TeX.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

attendue="$(./scripts/texte-fingerprint.sh)"
if ! LC_ALL=C grep -aqF "/Sources ($attendue)" texte/prouvhommes.pdf; then
  echo "Erreur : texte/prouvhommes.pdf ne correspond pas aux sources de texte/." >&2
  echo "Pour le régénérer : ./scripts/build-pdf.sh, puis commiter le PDF." >&2
  exit 1
fi
echo "PDF à jour (sources $attendue)."
