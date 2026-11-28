// The simulators: each has its own page under /simulateurs/ and a compact
// version inside its article. `extra` names the component in src/main.js;
// `params` are the live thresholds offered on its page.

export const SIMULATORS = [
  {
    slug: "preavis",
    extra: "notice-simulator",
    title: "Préavis",
    question: "Quel préavis, et que change un jour de plus ?",
    lede: "Le préavis croît avec l’ancienneté, sans palier : comparé au droit actuel et à ses effets de seuil.",
    article: "art:resiliation",
    params: [],
  },
  {
    slug: "indemnite",
    extra: "severance-simulator",
    title: "Indemnité de rupture",
    question: "Combien touche un salarié licencié ?",
    lede: "Selon son ancienneté et son salaire, comparé au droit actuel.",
    article: "art:indemnite",
    params: ["capMonths", "saturationMonths"],
  },
  {
    slug: "anti-manipulation",
    extra: "manipulation-demo",
    title: "Anti-manipulation",
    question: "Peut-on gonfler ou dégonfler l’indemnité ?",
    lede: "Ce que change une baisse du dernier salaire, ou une forte prime, juste avant la rupture.",
    article: "art:salaire-reference",
    params: ["alpha"],
  },
];
