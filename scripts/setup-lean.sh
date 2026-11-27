#!/usr/bin/env bash
# Première installation : récupère les dépendances épinglées et le cache de Mathlib.
# Ne change aucune version (pour cela, voir update-mathlib.sh).
set -euo pipefail
cd "$(dirname "$0")/../lean"
lake exe cache get
