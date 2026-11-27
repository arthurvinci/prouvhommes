#!/usr/bin/env bash
# Échoue si la formalisation contient `sorry` ou `admit`.
# Complète la vérification par `#print axioms` de Vitrine.lean.
set -euo pipefail
cd "$(dirname "$0")/../lean"
if grep -rnwE 'sorry|admit' --include='*.lean' Prouvhommes Prouvhommes.lean; then
  echo "Erreur : sorry/admit trouvé dans la formalisation." >&2
  exit 1
fi
echo "Aucun sorry."
