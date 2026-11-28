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
const PARAM_LINK = { capMonths: "cap", saturationMonths: "saturation", alpha: "alpha" };
const live = (param, text) =>
  `<button type="button" class="live-number link" data-param="${param}" data-link="${PARAM_LINK[param]}">${text}</button>`;

// Open notions (M2): phrase in the text → Lean predicate left to the judge.
// Every article draws them as holes, in the text and in the Lean code.
export const OPEN_NOTIONS = {
  "juste motif": "Interpretation.justeMotif",
};

export const ENRICHED = {
  "art:indemnite": {
    sourceHash: "76d40289e341",
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
<p><span class="para">I. —</span> En cas de <span class="link" data-link="due">résiliation ordinaire du contrat par l’employeur</span>, le salarié a droit à une indemnité de rupture.</p>
<p><span class="para">II. —</span> Le montant de l’indemnité est</p>
<div class="formula" role="math" aria-label="I égale la partie entière de S R fois plafond fois S de min de m et saturation, divisé par saturation, avec S de t égale 3 t carré moins 2 t cube">
  <span class="formula-main"><var>I</var> = <span class="link" data-link="floor">⌊</span> <span class="link" data-link="sr"><var>SR</var></span> × ${live("capMonths", "6")} × <span class="link" data-link="smoothstep"><var>S</var></span><span class="paren">(</span><span class="frac"><span><span class="link" data-link="seniority">min(<var>m</var>, ${live("saturationMonths", "240")})</span></span><span>${live("saturationMonths", "240")}</span></span><span class="paren">)</span> <span class="link" data-link="floor">⌋</span></span>
  <span class="formula-aside">avec <span class="link" data-link="smoothstep"><var>S</var>(<var>t</var>) = 3<var>t</var><sup>2</sup> − 2<var>t</var><sup>3</sup></span></span>
</div>
<p>où <span class="link" data-link="sr"><var>SR</var></span> est le salaire de référence défini à l’article&nbsp;{{ref:art:salaire-reference}} et <span class="link" data-link="seniority"><var>m</var> l’ancienneté du salarié en mois révolus</span> au dernier jour du contrat (article&nbsp;{{ref:art:delais}}). Le montant est <span class="link" data-link="floor">arrondi au centime d’euro inférieur</span>. Aucun calcul intermédiaire n’est arrondi.</p>
<p><span class="para">III. —</span> <span class="link" data-link="notDue">L’indemnité n’est due ni en cas de démission, ni en cas de rupture pendant la période d’essai, ni en cas de résiliation immédiate pour <span class="open-notion">juste motif</span>, ni en cas d’accord écrit des parties ou de décès du salarié</span>.</p>
`,
    // Replaces the LaTeX table: simulator, curve and live values table.
    extra: "severance-simulator",
  },

  "art:resiliation": {
    sourceHash: "8eac7805bc13",
    leanDecls: ["preavis", "dispPreavisEmployeur", "dispPreavisSalarie"],
    links: {
      curve: String.raw`min \(min \(7 \+ 23 \* j / 30\)`,
      longer: String.raw`sens := \.plusGrand`,
      shorter: String.raw`sens := \.plusPetit`,
    },
    body: `
<p><span class="para">I. —</span> Après la période d’essai, chaque partie peut résilier le contrat à tout moment, sans motif, moyennant un préavis. Aucune résiliation ordinaire ne peut être notifiée pendant la période d’essai.</p>
<p><span class="para">II. —</span> <span class="link" data-link="curve">La durée du préavis, en jours, est la partie entière de la plus petite des quatre quantités suivantes</span>, où <var>j</var> est l’ancienneté du salarié en jours au jour de la réception de la notification :</p>
<div class="formula" role="math" aria-label="7 plus 23 trentièmes de j ; 30 plus 6 soixante-septièmes de j moins 30 ; 60 plus 3 deux-cent-quatre-vingt-douzièmes de j moins 365 ; 90">
  <span class="formula-main"><span class="link" data-link="curve">7 + <span class="frac"><span>23</span><span>30</span></span> <var>j</var>, &emsp; 30 + <span class="frac"><span>6</span><span>67</span></span> (<var>j</var> − 30), &emsp; 60 + <span class="frac"><span>3</span><span>292</span></span> (<var>j</var> − 365), &emsp; 90.</span></span>
</div>
<p>Le préavis est ainsi de sept jours au début du contrat, de trente jours après trente jours, de soixante jours après un an et de quatre-vingt-dix jours après neuf ans ; entre ces dates, il croît régulièrement, d’au plus un jour par jour d’ancienneté.</p>
<p><span class="para">III. —</span> Un accord d’entreprise ou le contrat peut <span class="link" data-link="longer">allonger le préavis dû par l’employeur</span> et <span class="link" data-link="shorter">raccourcir celui dû par le salarié</span> (article&nbsp;{{ref:art:relatives}}).</p>
`,
  },

  "art:salaire-reference": {
    sourceHash: "5e82cb2453b6",
    leanDecls: ["MoisTravaille", "salaireReference", "masseSalaires", "masseActivite", "sommeExp", "pasEMA", "alphaSR"],
    links: {
      activity: String.raw`activite : ℚ := 1`,
      all: String.raw`h\.map`,
      zero: String.raw`\(pasEMA α\) 0`,
      step: String.raw`α \* x \+ \(1 - α\) \* e`,
      quotient: String.raw`masseSalaires h / masseActivite h`,
      alpha: String.raw`alphaSR|1 / 24`,
    },
    body: `
<p><span class="para">I. —</span> Le salaire mensuel est la rémunération brute totale versée au titre d’un mois, primes et heures supplémentaires comprises. <span class="link" data-link="activity">Le taux d’activité d’un mois est la fraction de ce mois pendant laquelle le salarié a travaillé ou a été rémunéré, congés payés compris ; il est compris entre zéro et un.</span></p>
<p><span class="para">II. —</span> <span class="link" data-link="all">Tous les mois du contrat sont pris en compte</span>, du plus ancien au plus récent. <span class="link" data-link="zero">La masse des salaires et la masse d’activité sont nulles avant le premier mois.</span> À chaque mois, <span class="link" data-link="step">la masse des salaires devient la somme d’un ${live("alpha", "vingt-quatrième")} du salaire de ce mois et des <span data-derived="alphaComplement">vingt-trois vingt-quatrièmes</span> de la masse des salaires précédente</span> ; <span class="link" data-link="step">la masse d’activité devient la somme d’un ${live("alpha", "vingt-quatrième")} du taux d’activité de ce mois et des <span data-derived="alphaComplement">vingt-trois vingt-quatrièmes</span> de la masse d’activité précédente</span>.</p>
<p><span class="para">III. —</span> <span class="link" data-link="quotient">Le salaire de référence est le quotient de la masse des salaires par la masse d’activité.</span> Il est nul si la masse d’activité est nulle.</p>
`,
    extra: "manipulation-demo",
  },
};
