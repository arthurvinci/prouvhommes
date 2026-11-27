// The live thresholds. Each is edited as an integer on a slider and maps to
// one field of the P6 parameters. Values are mirrored in the URL query
// (?plafond=7) so a variant can be shared as a link.

import { q, eq } from "./rational.js";
import { LAW_PARAMS } from "./p6.js";
import { cardinal, ordinal, ordinalPlural } from "./french.js";

export const PARAM_SPECS = {
  capMonths: {
    query: "plafond",
    label: "Plafond de l’indemnité",
    min: 1, max: 12, step: 1,
    law: 6,
    toParam: (n) => q(n),
    display: (n) => String(n),
    describe: (n) => `${n} mois de salaire de référence`,
  },
  saturationMonths: {
    query: "saturation",
    label: "Ancienneté à laquelle le plafond est atteint",
    min: 12, max: 480, step: 12,
    law: 240,
    toParam: (n) => n,
    display: (n) => String(n),
    describe: (n) => `${n} mois, soit ${n / 12} ans`,
  },
  windowSize: {
    query: "fenetre",
    label: "Nombre de mois payés pris en compte",
    min: 2, max: 99, step: 1,
    law: 60,
    toParam: (n) => n,
    display: (n) => cardinal(n),
    describe: (n) => `les ${n} derniers mois payés`,
  },
  alpha: {
    query: "poids",
    label: "Poids de chaque nouveau mois",
    min: 2, max: 60, step: 1,
    law: 24,
    toParam: (n) => q(1, n),
    display: (n) => ordinal(n),
    describe: (n) => `1/${n} du salaire du mois`,
  },
};

/** Words that follow from a parameter ("vingt-trois vingt-quatrièmes"). */
export const DERIVED = {
  alphaComplement: (values) => `${cardinal(values.alpha - 1)} ${ordinalPlural(values.alpha)}`,
};

const lawValues = () => Object.fromEntries(Object.entries(PARAM_SPECS).map(([k, s]) => [k, s.law]));

class ParamStore extends EventTarget {
  constructor() {
    super();
    this.values = lawValues();
    const query = new URLSearchParams(location.search);
    for (const [name, spec] of Object.entries(PARAM_SPECS)) {
      const raw = Number(query.get(spec.query));
      if (Number.isInteger(raw) && raw >= spec.min && raw <= spec.max && (raw - spec.min) % spec.step === 0) {
        this.values[name] = raw;
      }
    }
  }

  set(name, value) {
    if (this.values[name] === value) return;
    this.values[name] = value;
    this.#changed();
  }

  reset() {
    this.values = lawValues();
    this.#changed();
  }

  /** Parameters in the shape p6.js expects. */
  get p6() {
    return Object.freeze(
      Object.fromEntries(Object.entries(PARAM_SPECS).map(([k, s]) => [k, s.toParam(this.values[k])])),
    );
  }

  get isLaw() {
    return Object.entries(PARAM_SPECS).every(([k, s]) => this.values[k] === s.law);
  }

  /** Names of the parameters that differ from the law. */
  get changed() {
    return Object.keys(PARAM_SPECS).filter((k) => this.values[k] !== PARAM_SPECS[k].law);
  }

  #changed() {
    const url = new URL(location.href);
    for (const [name, spec] of Object.entries(PARAM_SPECS)) {
      if (this.values[name] === spec.law) url.searchParams.delete(spec.query);
      else url.searchParams.set(spec.query, String(this.values[name]));
    }
    history.replaceState(null, "", url);
    this.dispatchEvent(new Event("change"));
  }
}

export const params = new ParamStore();

/** True when a p6 parameter object equals the law's. */
export const isLawParams = (p) =>
  eq(p.capMonths, LAW_PARAMS.capMonths) &&
  p.saturationMonths === LAW_PARAMS.saturationMonths &&
  eq(p.alpha, LAW_PARAMS.alpha) &&
  p.windowSize === LAW_PARAMS.windowSize;
