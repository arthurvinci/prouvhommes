#!/usr/bin/env bash
# Aligne la toolchain Lean sur celle de Mathlib, récupère les dépendances et le cache.
set -euo pipefail
cd "$(dirname "$0")/../lean"
curl -fsSL https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o lean-toolchain
echo "Toolchain : $(cat lean-toolchain)"
lake update
lake exe cache get
