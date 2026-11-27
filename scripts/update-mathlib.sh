#!/usr/bin/env bash
# Met à jour Mathlib vers la dernière version de master, puis aligne la toolchain
# Lean sur celle de la révision obtenue. À lancer volontairement, jamais en CI :
# le résultat (lean-toolchain + lake-manifest.json) doit être commité.
set -euo pipefail
cd "$(dirname "$0")/../lean"

curl -fsSL https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o lean-toolchain
lake update mathlib

# Garde-fou : la toolchain du projet doit être celle de la révision épinglée.
if ! cmp -s lean-toolchain .lake/packages/mathlib/lean-toolchain; then
  cp .lake/packages/mathlib/lean-toolchain lean-toolchain
  echo "Toolchain réalignée sur la révision épinglée de Mathlib."
fi

lake exe cache get
echo "Toolchain : $(cat lean-toolchain)"
echo "Mathlib   : $(git -C .lake/packages/mathlib rev-parse --short HEAD)"
echo "Pensez à commiter lean/lean-toolchain et lean/lake-manifest.json."
