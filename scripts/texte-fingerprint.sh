#!/usr/bin/env bash
# Affiche l'empreinte des sources du texte (fichiers suivis de texte/, sans le
# PDF) : l'identifiant git de chaque fichier, haché avec son chemin. Ne dépend
# ni de TeX, ni de la date, ni de l'historique.
#
# build-pdf.sh l'inscrit dans les métadonnées du PDF ; check-pdf.sh vérifie que
# le PDF versionné porte l'empreinte des sources versionnées.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git ls-files --cached -- texte ':!texte/prouvhommes.pdf' \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
      if [ -f "$f" ]; then printf '%s %s\n' "$(git hash-object -- "$f")" "$f"; fi
    done \
  | git hash-object --stdin
