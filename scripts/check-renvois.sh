#!/usr/bin/env bash
# Vérifie les renvois du texte vers la formalisation, avec Lean lui-même :
#   - chaque \lean{Nom} désigne une déclaration qui existe ;
#   - chaque \theoreme{Nom} désigne un théorème démontré, qui ne dépend
#     d'aucun axiome autre que propext, Classical.choice et Quot.sound
#     (donc ni de sorry, ni d'un axiome ajouté au projet).
# C'est la garantie qu'annonce l'introduction du texte : « un nom cité ici
# désigne toujours un théorème entièrement démontré ».
#
# À lancer après `lake build` (la CI le fait dans le job Lean).
set -euo pipefail

racine="$(cd "$(dirname "$0")/.." && pwd)"

# Noms cités par une macro, hors commentaires LaTeX (main.tex documente les
# macros dans un commentaire : « % \lean{Nom} »).
noms() {
  sed -E 's/(^|[^\\])%.*/\1/' "$racine"/texte/main.tex "$racine"/texte/titres/*.tex \
    | grep -oE "\\\\$1\{[^}]+\}" | sed -E 's/^[^{]*\{(.*)\}$/\1/' | LC_ALL=C sort -u
}

fichier="$(mktemp "${TMPDIR:-/tmp}/renvois.XXXXXX")"
mv "$fichier" "$fichier.lean"
fichier="$fichier.lean"
trap 'rm -f "$fichier"' EXIT

{
  cat <<'LEAN'
import Prouvhommes
open Lean Elab Command

def axiomesAdmis : List Name := [``propext, ``Classical.choice, ``Quot.sound]

/-- La déclaration citée par `\lean{…}` existe. -/
elab "#renvoi_lean " id:ident : command => do
  let n := `Prouvhommes ++ id.getId
  unless (← getEnv).contains n do
    logError m!"\\lean\{{id.getId}} : aucune déclaration {n}"

/-- Le théorème cité par `\theoreme{…}` est démontré, sans axiome non standard. -/
elab "#renvoi_theoreme " id:ident : command => do
  let n := `Prouvhommes ++ id.getId
  match (← getEnv).find? n with
  | none => logError m!"\\theoreme\{{id.getId}} : aucune déclaration {n}"
  | some (.thmInfo _) =>
    let interdits := (← collectAxioms n).filter (· ∉ axiomesAdmis)
    unless interdits.isEmpty do
      logError m!"\\theoreme\{{id.getId}} dépend de {interdits.toList}"
  | some _ => logError m!"\\theoreme\{{id.getId}} : {n} n'est pas un théorème"
LEAN
  noms lean | sed 's/^/#renvoi_lean /'
  noms theoreme | sed 's/^/#renvoi_theoreme /'
} >"$fichier"

cd "$racine/lean"
if ! lake env lean "$fichier"; then
  echo "Erreur : renvoi du texte vers une déclaration absente ou non démontrée." >&2
  exit 1
fi
echo "Renvois vérifiés : $(noms lean | wc -l | tr -d ' ') déclarations, $(noms theoreme | wc -l | tr -d ' ') théorèmes."
