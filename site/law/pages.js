// Every page of the site, generated from the law at build time:
// the welcome page, then the four tabs (Le code, Promesses, Simulateurs,
// Méthode). Returns route → full HTML.

import { layout } from "./layout.js";
import {
  allPromises,
  articleUrl,
  escapeHtml,
  parts,
  renderArticle,
  renderArticleNav,
  renderContents,
  renderDashboard,
  renderFullText,
  renderIntroduction,
  renderPromiseCards,
  renderToc,
  REPO,
} from "./render.js";
import { SIMULATORS } from "./simulators.js";

/** Promises shown on the welcome page, picked by hand (missing ones are skipped). */
const FEATURED = [
  "indemniteRupture_le_plafond",
  "indemniteRupture_manipulation",
  "duree_minimale",
  "fin_resiliationImmediate",
];

/** Text of each live threshold before the script runs (the law's values). */
const PARAM_TEXT = { capMonths: "6", saturationMonths: "240", alpha: "vingt-quatrième" };
const PARAM_LABEL = {
  capMonths: ["Plafond", "mois de salaire de référence"],
  saturationMonths: ["Plafond atteint après", "mois d’ancienneté"],
  alpha: ["Poids du dernier mois : un", "du salaire"],
};
const PARAM_LINK = { capMonths: "cap", saturationMonths: "saturation", alpha: "alpha" };

export function buildPages(law, warn = console.warn) {
  const pages = new Map();
  const add = (route, page) => pages.set(route, layout(page));
  const n = law.articles.length;
  const promises = allPromises(law);
  const proved = promises.filter((p) => p.status === "proved").length;

  /* Welcome ---------------------------------------------------------------- */
  const doors = [
    ["/code/", "Le code", "Lire le texte", `${n} articles, chacun face à sa formalisation en Lean.`],
    [
      "/promesses/",
      "Promesses",
      "Ce que le code garantit",
      proved === promises.length
        ? `${promises.length} promesses, toutes démontrées et vérifiées par la machine.`
        : `${promises.length} promesses, dont ${proved} démontrées.`,
    ],
    ["/simulateurs/", "Simulateurs", "Ce qu’il change pour vous", "Calculez une indemnité, comparez-la au droit actuel, cherchez la faille."],
    ["/methode/", "Méthode", "Comment c’est prouvé", "Seuils chiffrés, notions ouvertes, niveaux d’impérativité : les règles d’écriture du texte."],
  ];
  const featured = FEATURED.map((name) => promises.find((p) => p.name === name)).filter(Boolean);
  add("/", {
    title: "Prouv’hommes — un code du travail prouvé",
    description: "Un code du travail français radicalement simplifié, formalisé en Lean pour prouver ses propriétés.",
    body: `<main class="page home">
  <section class="hero">
    <p class="eyebrow">Proposition de code du travail</p>
    <h1>Des promesses, prouvées.</h1>
    <p class="lede">Un code du travail court, dont chaque article est doublé de sa formalisation en Lean. Ce que le code promet, une machine le vérifie.</p>
  </section>
  <nav class="doors" aria-label="Par où commencer">
    ${doors
      .map(
        ([href, tab, question, text]) => `<a class="door" href="${href}">
      <span class="door-tab">${tab}</span>
      <span class="door-question">${question}</span>
      <span class="door-text">${text}</span>
    </a>`,
      )
      .join("\n    ")}
  </nav>
  <section class="featured" aria-labelledby="featured-title">
    <h2 id="featured-title">Quelques promesses</h2>
    ${renderPromiseCards(featured, law)}
    <p><a class="more" href="/promesses/">Toutes les promesses</a></p>
  </section>
</main>`,
  });

  /* Le code ---------------------------------------------------------------- */
  add("/code/", {
    title: "Le code — Prouv’hommes",
    description: "Le sommaire du code du travail Prouv’hommes, article par article.",
    tab: "code",
    current: true,
    body: `<main class="page">
  <header class="page-head">
    <h1>Le code</h1>
    <p class="section-lede">${n} articles. Chacun a deux faces : son texte, et sa traduction en Lean, avec les garanties qu’elle démontre.</p>
    <p class="page-actions"><a href="/code/texte-integral/">Lire le texte intégral</a><a href="${REPO}/raw/main/texte/prouvhommes.pdf">Télécharger le PDF</a></p>
  </header>
  ${renderContents(law)}
</main>`,
  });

  for (const a of law.articles) {
    add(articleUrl(a), {
      title: `Article ${a.number} : ${a.title} — Prouv’hommes`,
      description: `Article ${a.number} du code Prouv’hommes, ${a.title.toLowerCase()}, et sa formalisation en Lean.`,
      tab: "code",
      body: `<div class="reader">
  <nav class="reader-toc" aria-label="Articles">${renderToc(law, a)}</nav>
  <main class="reader-main">
    <nav class="breadcrumb" aria-label="Fil d’Ariane"><ol><li><a href="/code/">Le code</a></li><li>${escapeHtml(a.part)}</li></ol></nav>
    ${renderArticle(a, law, warn, { standalone: true })}
    ${renderArticleNav(a, law)}
  </main>
</div>`,
    });
  }

  add("/code/texte-integral/", {
    title: "Texte intégral — Prouv’hommes",
    description: "Le texte intégral du code Prouv’hommes, face à sa formalisation en Lean.",
    tab: "code",
    body: `<div class="reader">
  <nav class="reader-toc" aria-label="Articles">${parts(law)
    .map(
      (p) => `<p class="toc-part">${escapeHtml(p.title)}</p><ol class="toc">${p.articles
        .map((a) => `<li><a href="#${a.id}"><span class="toc-number">${a.number}</span> ${escapeHtml(a.title)}</a></li>`)
        .join("")}</ol>`,
    )
    .join("")}</nav>
  <main class="reader-main">
    <nav class="breadcrumb" aria-label="Fil d’Ariane"><ol><li><a href="/code/">Le code</a></li><li>Texte intégral</li></ol></nav>
    <h1>Texte intégral</h1>
    <p class="page-actions"><button type="button" class="button" data-toggle-lean aria-pressed="false">Déplier toutes les formalisations</button></p>
    ${renderFullText(law, warn)}
  </main>
</div>`,
  });

  /* Promesses -------------------------------------------------------------- */
  add("/promesses/", {
    title: "Promesses — Prouv’hommes",
    description: "Ce que le code Prouv’hommes garantit, théorème par théorème.",
    tab: "promesses",
    current: true,
    body: `<main class="page">
  <header class="page-head">
    <h1>Promesses</h1>
    <p class="section-lede">Chaque promesse est un théorème Lean. « Prouvé » signifie que la démonstration est vérifiée par la machine à chaque modification du dépôt, sans aucune étape admise (aucun <code>sorry</code>). Les théorèmes restent vrais quelle que soit l’interprétation que le juge retient des notions ouvertes.</p>
  </header>
  ${renderDashboard(law)}
</main>`,
  });

  /* Simulateurs ------------------------------------------------------------ */
  add("/simulateurs/", {
    title: "Simulateurs — Prouv’hommes",
    description: "Calculer ce que le code Prouv’hommes change dans une situation donnée.",
    tab: "simulateurs",
    current: true,
    body: `<main class="page">
  <header class="page-head">
    <h1>Simulateurs</h1>
    <p class="section-lede">Les calculs suivent les définitions Lean au centime près : fractions exactes, un seul arrondi, au centime inférieur.</p>
  </header>
  <ul class="sim-cards">
    ${SIMULATORS.map(
      (s) => `<li><a class="door" href="/simulateurs/${s.slug}/">
      <span class="door-tab">${escapeHtml(s.title)}</span>
      <span class="door-question">${escapeHtml(s.question)}</span>
      <span class="door-text">${escapeHtml(s.lede)}</span>
    </a></li>`,
    ).join("\n    ")}
  </ul>
</main>`,
  });

  for (const s of SIMULATORS) {
    const article = law.articles.find((a) => a.label === s.article);
    add(`/simulateurs/${s.slug}/`, {
      title: `${s.title} — Simulateurs — Prouv’hommes`,
      description: `${s.question} ${s.lede}`,
      tab: "simulateurs",
      body: `<main class="page">
  <nav class="breadcrumb" aria-label="Fil d’Ariane"><ol><li><a href="/simulateurs/">Simulateurs</a></li><li>${escapeHtml(s.title)}</li></ol></nav>
  <header class="page-head">
    <h1>${escapeHtml(s.question)}</h1>
    <p class="section-lede">${escapeHtml(s.lede)}</p>
    ${article ? `<p class="rule-link">La règle : <a href="${articleUrl(article)}">article ${article.number}, ${escapeHtml(article.title.toLowerCase())}</a>.</p>` : ""}
    <p class="thresholds">Seuils du calcul, modifiables : ${s.params
      .map(
        (p) =>
          `<span class="threshold">${PARAM_LABEL[p][0]} <button type="button" class="live-number" data-param="${p}" data-link="${PARAM_LINK[p]}">${PARAM_TEXT[p]}</button> ${PARAM_LABEL[p][1]}</span>`,
      )
      .join("")}</p>
  </header>
  <div class="article-extra" data-extra="${s.extra}"></div>
</main>`,
    });
  }

  /* Méthode ---------------------------------------------------------------- */
  add("/methode/", {
    title: "Méthode — Prouv’hommes",
    description: "Comment le code Prouv’hommes est écrit pour être prouvé, et comment lire ce site.",
    tab: "methode",
    current: true,
    body: `<main class="page method">
  <header class="page-head">
    <h1>Méthode</h1>
  </header>
  ${renderIntroduction(law)}
  <section class="method-section" aria-labelledby="lire-le-site">
    <h2 id="lire-le-site">Lire ce site</h2>
    <dl class="legend-marks">
      <dt><span class="lean-dropdown-sample">Formalisation Lean</span></dt>
      <dd>Sous le texte de chaque article, un menu déroulant contient sa traduction en Lean. Sous chaque garantie, un autre contient l’énoncé exact du théorème.</dd>
      <dt><span class="link sample">expression soulignée</span></dt>
      <dd>Survolez-la ou sélectionnez-la : une fois la formalisation dépliée, son pendant s’y éclaire, et inversement.</dd>
      <dt><span class="live-number sample">6</span></dt>
      <dd>Un seuil modifiable. Changez-le : les garanties sont recalculées. Une variante n’est jamais « prouvée » : on montre un contre-exemple, ou un calcul sur des exemples.</dd>
      <dt><span class="open-notion">juste motif</span></dt>
      <dd>Une notion ouverte, laissée à l’appréciation du juge. En Lean, c’est un prédicat dont on ne sait rien : les théorèmes tiennent quoi que le juge y mette.</dd>
      <dt><span class="level" data-level="absolue"><span class="level-mark" aria-hidden="true"></span>absolue</span>
          <span class="level" data-level="relative"><span class="level-mark" aria-hidden="true"></span>relative</span>
          <span class="level" data-level="dispositive"><span class="level-mark" aria-hidden="true"></span>dispositive</span></dt>
      <dd>Le niveau d’impérativité de l’article : plein, à moitié, en pointillé.</dd>
      <dt><span class="status" data-status="proved">Prouvé en Lean</span></dt>
      <dd>Le théorème est démontré, et la démonstration est vérifiée par la machine à chaque modification.</dd>
    </dl>
  </section>
</main>`,
  });

  return pages;
}
