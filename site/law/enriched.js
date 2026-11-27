// Hand-annotated versions of selected articles. The wording must stay the
// text's own (texte/titres/*.tex); the annotations add:
//   data-link="key"      a phrase and its Lean counterpart, highlighted together
//   data-param="name"    a live threshold (see src/lib/params.js)
//   class="open-notion"  a notion left to the judge (charter rule M2)
// `{{ref:label}}` becomes a link to that article, with its current number.
// An article without an entry here is rendered from its LaTeX as it is.
//
// `sourceHash` fingerprints the LaTeX the copy was made from: when the text
// changes, the build warns and prints the new fingerprint (see render.js).
//
// `links` maps each key to a regular expression matched against the Lean
// source shown beside the article.

// Each live threshold is also linked to the Lean constant that holds it.
const PARAM_LINK = { capMonths: "cap", saturationMonths: "saturation", windowSize: "window", alpha: "alpha" };
const live = (param, text) =>
  `<button type="button" class="live-number link" data-param="${param}" data-link="${PARAM_LINK[param]}">${text}</button>`;

// Open notions (M2): phrase in the text → Lean predicate left to the judge.
// Every article draws them as holes, in the text and in the Lean code.
export const OPEN_NOTIONS = {
  "juste motif": "Interpretation.justeMotif",
};

export const ENRICHED = {
  "art:indemnite": {
    sourceHash: "5397499dea8b",
    leanDecls: [
      "indemniteRupture", "indemniteDue", "indemnite", "indemniteQ", "coefficient",
      "fractionAnciennete", "plafondMois", "ancienneteSaturation", "smoothstep",
    ],
    links: {
      due: String.raw`\.resiliationOrdinaire \.employeur|indemniteDue`,
      sr: String.raw`salaireReference|\bsr\b`,
      cap: String.raw`plafondMois`,
      saturation: String.raw`ancienneteSaturation`,
      smoothstep: String.raw`smoothstep`,
      seniority: String.raw`fractionAnciennete|\bm\b`,
      floor: String.raw`⌊|⌋₊`,
      notDue: String.raw`_ => false`,
    },
    body: `
<p><span class="para">I. —</span> En cas de <span class="link" data-link="due">résiliation ordinaire du contrat par l'employeur</span>, le salarié a droit à une indemnité de rupture.</p>
<p><span class="para">II. —</span> Le montant de l'indemnité est</p>
<div class="formula" role="math" aria-label="I égale la partie entière de S R fois plafond fois S de min de m et saturation, divisé par saturation, avec S de t égale 3 t carré moins 2 t cube">
  <span class="formula-main"><var>I</var> = <span class="link" data-link="floor">⌊</span> <span class="link" data-link="sr"><var>SR</var></span> × ${live("capMonths", "6")} × <span class="link" data-link="smoothstep"><var>S</var></span><span class="paren">(</span><span class="frac"><span><span class="link" data-link="seniority">min(<var>m</var>, ${live("saturationMonths", "240")})</span></span><span>${live("saturationMonths", "240")}</span></span><span class="paren">)</span> <span class="link" data-link="floor">⌋</span></span>
  <span class="formula-aside">avec <span class="link" data-link="smoothstep"><var>S</var>(<var>t</var>) = 3<var>t</var><sup>2</sup> − 2<var>t</var><sup>3</sup></span></span>
</div>
<p>où <span class="link" data-link="sr"><var>SR</var></span> est le salaire de référence défini à l'article&nbsp;{{ref:art:salaire-reference}} et <span class="link" data-link="seniority"><var>m</var> l'ancienneté du salarié en mois révolus</span> au dernier jour du contrat (article&nbsp;{{ref:art:delais}}). Le montant est <span class="link" data-link="floor">arrondi au centime d'euro inférieur</span>. Aucun calcul intermédiaire n'est arrondi.</p>
<p><span class="para">III. —</span> <span class="link" data-link="notDue">L'indemnité n'est due ni en cas de démission, ni en cas de rupture pendant la période d'essai, ni en cas de résiliation immédiate pour <span class="open-notion">juste motif</span>, ni en cas d'accord écrit des parties ou de décès du salarié</span>.</p>
`,
    // Replaces the LaTeX table: simulator, curve and live values table.
    extra: "severance-simulator",
  },

  "art:salaire-reference": {
    sourceHash: "91633a621501",
    leanDecls: ["salaireReference", "fenetre", "moisPayes", "tailleFenetre", "ema", "pasEMA", "alphaSR"],
    links: {
      unpaid: String.raw`filter \(· ≠ 0\)|moisPayes`,
      window: String.raw`tailleFenetre`,
      first: String.raw`\| s :: reste => reste\.foldl \(pasEMA α\) s`,
      step: String.raw`α \* x \+ \(1 - α\) \* e`,
      alpha: String.raw`alphaSR|1 / 24`,
    },
    body: `
<p><span class="para">I. —</span> Le salaire mensuel est la rémunération brute totale versée au titre d'un mois, primes et heures supplémentaires comprises. <span class="link" data-link="unpaid">Un mois sans salaire n'est pas pris en compte.</span></p>
<p><span class="para">II. —</span> Sont pris en compte les ${live("windowSize", "soixante")} <span class="link" data-link="window">derniers mois pour lesquels un salaire a été versé</span> ou, si le contrat en compte moins, tous ces mois.</p>
<p><span class="para">III. —</span> Les mois pris en compte sont parcourus du plus ancien au plus récent. <span class="link" data-link="first">Le salaire de référence est d'abord égal au salaire du premier mois.</span> <span class="link" data-link="step">À chaque mois suivant, il devient la somme d'un ${live("alpha", "vingt-quatrième")} du salaire de ce mois et des <span data-derived="alphaComplement">vingt-trois vingt-quatrièmes</span> du salaire de référence précédent.</span></p>
`,
    extra: "manipulation-demo",
  },
};
