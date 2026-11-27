// "Essayer" panel of the severance article: a simulator, the curve compared
// with current law and Switzerland, and the values table (the chart's table
// view). Everything follows the live thresholds.

import { params } from "../lib/params.js";
import { coefficient, currentLawCoefficient, isSeveranceDue, severancePay } from "../lib/p6.js";
import { toNumber, q } from "../lib/rational.js";
import { decimal, euros, fraction, parseEuros, seniority } from "../lib/format.js";

const CAUSES = [
  ["ordinaryTermination:employer", "Licenciement (résiliation ordinaire par l'employeur)"],
  ["ordinaryTermination:employee", "Démission"],
  ["trialTermination:employer", "Rupture pendant la période d'essai"],
  ["immediateTermination:employer", "Résiliation immédiate pour juste motif"],
  ["mutualAgreement:", "Accord écrit des parties"],
  ["death:", "Décès du salarié"],
];

// What current French law and Swiss law do in the cases where this code
// owes nothing (shown instead of an all-zero chart).
const NOT_DUE_NOTES = {
  mutualAgreement:
    "Ce code ne prévoit pas d'indemnité en cas d'accord. En droit actuel, la rupture conventionnelle ouvre droit à une indemnité au moins égale à l'indemnité légale de licenciement (article L1237-13 du code du travail) ; le droit suisse n'en prévoit pas.",
  default:
    "Rien à comparer : dans ce cas, le droit actuel et le droit suisse ne prévoient pas non plus d'indemnité légale, quelle que soit l'ancienneté.",
};

const SERIES = [
  { key: "code", label: "Ce code", fn: (m) => coefficient(m, params.p6) },
  { key: "current", label: "Droit actuel", fn: currentLawCoefficient },
  { key: "swiss", label: "Suisse", fn: () => q(0) },
];

// The chart runs to 30 years at least, to compare with current law (no cap).
const chartMonths = () => Math.max(360, params.p6.saturationMonths);

/**
 * `compact`: the calculator only, inside an article, with a link to the full
 * page (`fullUrl`) that adds the curve, the table and the comparison notes.
 */
export function initSeverance(root, { compact = false, fullUrl } = {}) {
  root.innerHTML = `
<h2 class="extra-title">${compact ? "Essayer" : "Simulateur"}</h2>
<div class="simulator">
  <form class="sim-controls" novalidate>
    <div class="field">
      <label for="sim-seniority">Ancienneté</label>
      <input id="sim-seniority" class="slider" type="range" min="0" max="240" step="1" value="120" />
      <output for="sim-seniority" data-out="seniority"></output>
    </div>
    <div class="field">
      <label for="sim-salary">Salaire mensuel brut, constant</label>
      <span class="input-euro"><input id="sim-salary" inputmode="decimal" autocomplete="off" value="3 000" aria-describedby="sim-salary-error" /><span aria-hidden="true">€</span></span>
      <p id="sim-salary-error" class="field-error" data-out="salary-error"></p>
    </div>
    <div class="field">
      <label for="sim-cause">Fin du contrat</label>
      <select id="sim-cause">${CAUSES.map(([v, l]) => `<option value="${v}">${l}</option>`).join("")}</select>
    </div>
  </form>
  <div class="sim-result" aria-live="polite">
    <p class="sim-amount" data-out="amount"></p>
    <p class="sim-detail" data-out="detail"></p>
  </div>
</div>
<p class="note not-due" data-out="not-due" hidden></p>
${
  compact
    ? `<p class="more"><a href="${fullUrl}">Voir la courbe et la comparaison avec le droit actuel et la Suisse</a></p>`
    : `<figure class="chart" data-due-only>
  <figcaption>Indemnité selon l'ancienneté, en mois de salaire</figcaption>
  <ul class="legend">${SERIES.map((s) => `<li data-series="${s.key}"><span class="swatch" aria-hidden="true"></span>${s.label}</li>`).join("")}</ul>
  <div class="chart-plot"><svg data-chart role="img" aria-label="Courbes de l'indemnité selon l'ancienneté : ce code, le droit actuel et la Suisse. Valeurs dans le tableau ci-dessous."></svg><div class="chart-tooltip" data-tooltip hidden></div></div>
</figure>
<div class="table-wrap" data-due-only>
  <table class="values">
    <caption>Valeurs, en mois de salaire de référence</caption>
    <thead><tr><th scope="col">Ancienneté</th>${SERIES.map((s) => `<th scope="col">${s.label}</th>`).join("")}</tr></thead>
    <tbody data-out="table"></tbody>
  </table>
</div>
<p class="note">Le simulateur suppose un salaire constant : le salaire de référence est alors égal au salaire. Pour un salaire qui varie, voir le simulateur <a href="/simulateurs/anti-manipulation/">anti-manipulation</a>. Droit actuel : articles L1234-9 et R1234-2 du code du travail (1/4 de mois par année jusqu'à 10 ans, 1/3 au-delà, dès 8 mois d'ancienneté). Suisse : pas d'indemnité légale de licenciement, sauf cas particulier des salariés de 50 ans et plus.</p>`
}`;

  const $ = (sel) => root.querySelector(sel);
  const seniorityInput = $("#sim-seniority");
  const salaryInput = $("#sim-salary");
  const causeInput = $("#sim-cause");
  const chart = compact ? null : buildChart($("[data-chart]"), $("[data-tooltip]"), () => Number(seniorityInput.value));
  let salary = 300000n;

  function render() {
    // Past the saturation the amount can't grow: the slider stops there
    // (setting max clamps the value).
    const sat = params.p6.saturationMonths;
    seniorityInput.max = String(sat);
    const m = Number(seniorityInput.value);
    $('[data-out="seniority"]').textContent = m === sat ? `${seniority(m)}, plafond atteint` : seniority(m);
    seniorityInput.setAttribute("aria-valuetext", seniority(m));
    seniorityInput.style.setProperty("--fill", `${(m / sat) * 100}%`);

    const [kind, party] = causeInput.value.split(":");
    const due = isSeveranceDue({ kind, party });
    const history = Array.from({ length: Math.max(1, m) }, () => salary);
    const pay = severancePay(history, m, { kind, party }, params.p6);
    const coef = coefficient(m, params.p6);
    $('[data-out="amount"]').textContent = euros(pay);
    $('[data-out="detail"]').innerHTML =
      due
        ? `${decimal(coef)} mois de salaire de référence${coef.d === 1n ? "" : ` (exactement ${fraction(coef)})`}. Calcul : ⌊ ${euros(salary)} × ${fraction(coef)} ⌋, arrondi une seule fois, au centime inférieur.`
        : "Pas d'indemnité : elle n'est due qu'en cas de licenciement ordinaire (III).";

    // Nothing to plot when no severance is due: every curve would be 0.
    for (const el of root.querySelectorAll("[data-due-only]")) el.hidden = !due;
    const notDue = $('[data-out="not-due"]');
    notDue.hidden = due;
    notDue.textContent = due
      ? ""
      : (NOT_DUE_NOTES[kind] ?? NOT_DUE_NOTES.default);
    if (!due || compact) return;

    $('[data-out="table"]').innerHTML = [12, 60, 120, 180, 240, 300]
      .map((mm) => `<tr><th scope="row">${seniority(mm)}</th>${SERIES.map((s) => `<td>${decimal(s.fn(mm))}</td>`).join("")}</tr>`)
      .join("");
    chart?.render();
  }

  salaryInput.addEventListener("input", () => {
    const cents = parseEuros(salaryInput.value);
    const error = $('[data-out="salary-error"]');
    if (cents === null) {
      error.textContent = "Saisissez un montant en euros, par exemple 3 000 ou 2 450,50.";
      salaryInput.setAttribute("aria-invalid", "true");
      return;
    }
    error.textContent = "";
    salaryInput.removeAttribute("aria-invalid");
    salary = cents;
    render();
  });
  seniorityInput.addEventListener("input", render);
  causeInput.addEventListener("change", render);
  params.addEventListener("change", render);
  render();
}

/* Chart -------------------------------------------------------------------- */

function buildChart(svg, tooltip, selected) {
  const W = 640;
  const H = 280;
  const pad = { top: 12, right: 96, bottom: 32, left: 36 };
  const iw = W - pad.left - pad.right;
  const ih = H - pad.top - pad.bottom;
  svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
  let maxMonths = chartMonths();
  const x = (m) => pad.left + (m / maxMonths) * iw;
  let yMax = 8;
  const y = (v) => pad.top + ih - (v / yMax) * ih;
  const NS = "http://www.w3.org/2000/svg";
  const el = (name, attrs, text) => {
    const e = document.createElementNS(NS, name);
    for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
    if (text !== undefined) e.textContent = text;
    return e;
  };

  let values = {};

  function render() {
    maxMonths = chartMonths();
    // Display only: exact values are converted to numbers for drawing.
    values = Object.fromEntries(
      SERIES.map((s) => [s.key, Array.from({ length: maxMonths + 1 }, (_, m) => toNumber(s.fn(m)))]),
    );
    const peak = Math.max(...Object.values(values).flat());
    yMax = Math.max(8, 2 * Math.ceil((peak + 0.5) / 2));
    svg.replaceChildren();

    const grid = el("g", { class: "grid" });
    for (let v = 0; v <= yMax; v += 2) {
      grid.append(el("line", { x1: pad.left, x2: pad.left + iw, y1: y(v), y2: y(v) }));
      grid.append(el("text", { x: pad.left - 8, y: y(v) + 4, "text-anchor": "end" }, String(v)));
    }
    for (let yr = 0; yr <= maxMonths / 12; yr += 5) {
      grid.append(el("text", { x: x(yr * 12), y: H - 10, "text-anchor": "middle" }, `${yr} ans`));
    }
    svg.append(grid);

    const law = el("line", { class: "cap-line", x1: pad.left, x2: pad.left + iw, y1: y(6), y2: y(6) });
    svg.append(law);

    const labels = [];
    for (const s of SERIES) {
      const pts = values[s.key].map((v, m) => `${x(m).toFixed(1)},${y(v).toFixed(1)}`).join(" ");
      svg.append(el("polyline", { class: `series series-${s.key}`, points: pts }));
      labels.push({ s, y: y(values[s.key][maxMonths]) });
    }
    // Direct labels at the right end, nudged apart so they never collide.
    labels.sort((a, b) => a.y - b.y);
    for (let i = 1; i < labels.length; i++) labels[i].y = Math.max(labels[i].y, labels[i - 1].y + 16);
    for (const { s, y: ly } of labels) {
      svg.append(el("text", { class: `direct-label label-${s.key}`, x: pad.left + iw + 8, y: ly + 4 }, s.label));
    }

    const m = selected();
    svg.append(el("circle", { class: "marker", cx: x(m), cy: y(values.code[m]), r: 5 }));

    const hit = el("rect", { class: "hit", x: pad.left, y: pad.top, width: iw, height: ih });
    const cross = el("line", { class: "crosshair", y1: pad.top, y2: pad.top + ih, visibility: "hidden" });
    svg.append(cross, hit);
    hit.addEventListener("pointermove", (e) => {
      const box = svg.getBoundingClientRect();
      const px = ((e.clientX - box.left) / box.width) * W;
      const mm = Math.round(Math.min(maxMonths, Math.max(0, ((px - pad.left) / iw) * maxMonths)));
      cross.setAttribute("x1", x(mm));
      cross.setAttribute("x2", x(mm));
      cross.setAttribute("visibility", "visible");
      tooltip.hidden = false;
      tooltip.innerHTML = `<strong>${seniority(mm)}</strong>${SERIES.map(
        (s) => `<span data-series="${s.key}"><span class="swatch" aria-hidden="true"></span>${s.label} : ${decimal(s.fn(mm))} mois</span>`,
      ).join("")}`;
      const left = (x(mm) / W) * box.width;
      tooltip.style.left = `${Math.min(left + 12, box.width - tooltip.offsetWidth - 4)}px`;
    });
    hit.addEventListener("pointerleave", () => {
      cross.setAttribute("visibility", "hidden");
      tooltip.hidden = true;
    });
  }

  return { render };
}
