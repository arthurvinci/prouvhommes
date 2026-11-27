#!/usr/bin/env bash
# Active les hooks versionnés du dépôt (.githooks/) : à chaque commit, le PDF
# du texte est recompilé et ajouté au commit. À lancer une fois par clone.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
# Lors d'une fusion, on garde notre PDF ; le hook pre-merge-commit le recompile.
git config merge.ours.driver true
echo "Hooks activés (.githooks/)."
