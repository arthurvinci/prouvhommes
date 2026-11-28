// "Essayer" panel of the ordinary termination article: the notice for a
// notification received on a given day, what one more day changes (M8: no
// threshold effect), and, on the full page, the curve compared with current
// law and the values table (the chart's table view).

import { NOTICE_POINTS, currentLawNotice, lastDay, notice } from "../lib/notice.js";
import { days, seniorityDays } from "../lib/format.js";

const MAX_DAYS = 3650; // 10 years: the curve is flat from 9 years on.

const SERIES = [
  { key: "code", label: "Ce code", fn: notice },
  { key: "current", label: "Droit actuel", fn: currentLawNotice },
];

const currentLastDay = (j) => j + currentLawNotice(j);

/** "+1 jour" / "+31 jours" */
const later = (n) => `+${days(n)}`;

/**
 * `compact`: the calculator only, inside the article, with a link to the full
 * page (`fullUrl`) that adds the curve, the table and the comparison.
 */
export function initNotice(root, { compact = false, fullUrl } = {}) {
  root.innerHTML = `
<h2 class="extra-title">${compact ? "Essayer" : "Simulateur"}</h2>
<div class="simulator">
  <form class="sim-controls" novalidate>
    <div class="field">
      <label for="notice-day">Ancienneté au jour de la notification</label>
      <input id="notice-day" class="slider" type="range" min="0" max="${MAX_DAYS}" step="1" value="364" />
      <output for="notice-day" data-out="seniority"></output>
    </div>
    <p class="field-hint">Flèches du clavier : un jour de plus ou de moins.</p>
  </form>
  <div class="sim-result" aria-live="polite">
    <p class="sim-amount" data-out="notice"></p>
    <p class="sim-detail" data-out="detail"></p>
  </div>
</div>
<dl class="sim-compare notice-next" aria-live="polite">
  <div><dt>Notifié un jour plus tard</dt><dd data-out="next"></dd></div>
  <div><dt>Droit actuel, licenciement</dt><dd data-out="current"></dd></div>
</dl>
${
  compact
    ? `<p class="more"><a href="${fullUrl}">Voir la courbe et la comparaison avec le droit actuel</a></p>`
    : `<figure class="chart">
  <figcaption>Préavis selon l’ancienneté, en jours</figcaption>
  <ul class="legend">${SERIES.map((s) => `<li data-series="${s.key}"><span class="swatch" aria-hidden="true"></span>${s.label}</li>`).join("")}</ul>
  <div class="chart-plot"><svg data-chart role="img" aria-label="Courbes du préavis selon l’ancienneté : ce code, continu, et le droit actuel, en paliers. Valeurs dans le tableau ci-dessous."></svg><div class="chart-tooltip" data-tooltip hidden></div></div>
</figure>
<div class="table-wrap">
  <table class="values">
    <caption>Préavis, en jours</caption>
    <thead><tr><th scope="col">Ancienneté</th>${SERIES.map((s) => `<th scope="col">${s.label}</th>`).join("")}</tr></thead>
    <tbody>${[0, 30, 182, 183, 364, 365, 729, 730, 1825, 3285]
      .map((j) => `<tr><th scope="row">${seniorityDays(j)}</th>${SERIES.map((s) => `<td>${s.fn(j)}</td>`).join("")}</tr>`)
      .join("")}</tbody>
  </table>
</div>
<p class="note">Ce code : un seul préavis, pendant l’essai comme après, le même pour les deux parties ; un accord d’entreprise ou le contrat peut allonger celui de l’employeur et raccourcir celui du salarié. Droit actuel : article L1234-1 du code du travail (licenciement ; aucun préavis légal avant 6 mois, la convention collective ou l’usage en fixe un), un mois compté ici 30 jours. La démission n’a pas de préavis légal en droit actuel.</p>`
}`;

  const $ = (sel) => root.querySelector(sel);
  const input = $("#notice-day");
  const chart = compact
    ? null
    : buildChart($("[data-chart]"), $("[data-tooltip]"), () => Number(input.value), (j) => {
        input.value = String(j);
        render();
      });

  function render() {
    const j = Number(input.value);
    $('[data-out="seniority"]').textContent = `${seniorityDays(j)}${j >= 365 ? ` (${days(j)})` : ""}`;
    input.setAttribute("aria-valuetext", seniorityDays(j));
    input.style.setProperty("--fill", `${(j / MAX_DAYS) * 100}%`);

    const n = notice(j);
    $('[data-out="notice"]').textContent = `${days(n)} de préavis`;
    $('[data-out="detail"]').textContent =
      `Notification reçue au jour ${j} : le préavis court à partir du lendemain, le dernier jour du contrat est le jour ${lastDay(j)}.`;

    const step = lastDay(j + 1) - lastDay(j);
    $('[data-out="next"]').innerHTML =
      `Fin au jour ${lastDay(j + 1)}<span class="delta">${later(step)} : jamais plus de 2 jours, jamais plus tôt (<code>fin_preavis_succ</code>).</span>`;

    const c = currentLawNotice(j);
    const cStep = currentLastDay(j + 1) - currentLastDay(j);
    $('[data-out="current"]').innerHTML =
      `${c === 0 ? "Aucun préavis légal" : days(c)}<span class="delta">${
        cStep > 2
          ? `Un jour plus tard : fin ${later(cStep)}. C’est un effet de seuil.`
          : `Un jour plus tard : fin ${later(cStep)}.`
      }</span>`;
    chart?.render();
  }

  input.addEventListener("input", render);
  render();
}

/* Chart -------------------------------------------------------------------- */

function buildChart(svg, tooltip, selected, select) {
  const W = 640;
  const H = 280;
  const pad = { top: 12, right: 96, bottom: 32, left: 36 };
  const iw = W - pad.left - pad.right;
  const ih = H - pad.top - pad.bottom;
  const yMax = 100;
  svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
  const x = (j) => pad.left + (j / MAX_DAYS) * iw;
  const y = (v) => pad.top + ih - (v / yMax) * ih;
  const NS = "http://www.w3.org/2000/svg";
  const el = (name, attrs, text) => {
    const e = document.createElementNS(NS, name);
    for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
    if (text !== undefined) e.textContent = text;
    return e;
  };
  const range = Array.from({ length: MAX_DAYS + 1 }, (_, j) => j);

  // The curves don't depend on any live threshold: drawn once.
  const grid = el("g", { class: "grid" });
  for (let v = 0; v <= 90; v += 30) {
    grid.append(el("line", { x1: pad.left, x2: pad.left + iw, y1: y(v), y2: y(v) }));
    grid.append(el("text", { x: pad.left - 8, y: y(v) + 4, "text-anchor": "end" }, String(v)));
  }
  for (let yr = 0; yr <= MAX_DAYS / 365; yr += 2) {
    grid.append(el("text", { x: x(yr * 365), y: H - 10, "text-anchor": "middle" }, `${yr} ans`));
  }
  svg.append(grid);

  const labels = [];
  for (const s of SERIES) {
    const pts = range.map((j) => `${x(j).toFixed(1)},${y(s.fn(j)).toFixed(1)}`).join(" ");
    svg.append(el("polyline", { class: `series series-${s.key}`, points: pts }));
    labels.push({ s, y: y(s.fn(MAX_DAYS)) });
  }
  labels.sort((a, b) => a.y - b.y);
  for (let i = 1; i < labels.length; i++) labels[i].y = Math.max(labels[i].y, labels[i - 1].y + 16);
  for (const { s, y: ly } of labels) {
    svg.append(el("text", { class: `direct-label label-${s.key}`, x: pad.left + iw + 8, y: ly + 4 }, s.label));
  }
  // The points the text names: 7 days, 30 days after 30 days, 60 after a year, 90 after nine.
  for (const [j, n] of NOTICE_POINTS) {
    svg.append(el("circle", { class: "waypoint", cx: x(j), cy: y(n), r: 3 }));
  }

  const marker = el("circle", { class: "marker", r: 5 });
  const cross = el("line", { class: "crosshair", y1: pad.top, y2: pad.top + ih, visibility: "hidden" });
  const hit = el("rect", { class: "hit", x: pad.left, y: pad.top, width: iw, height: ih });
  svg.append(marker, cross, hit);

  const dayAt = (e) => {
    const box = svg.getBoundingClientRect();
    const px = ((e.clientX - box.left) / box.width) * W;
    return Math.round(Math.min(MAX_DAYS, Math.max(0, ((px - pad.left) / iw) * MAX_DAYS)));
  };
  // Pointer only; the slider is the keyboard way to pick a day.
  hit.addEventListener("click", (e) => select(dayAt(e)));
  hit.addEventListener("pointermove", (e) => {
    const box = svg.getBoundingClientRect();
    const j = dayAt(e);
    cross.setAttribute("x1", x(j));
    cross.setAttribute("x2", x(j));
    cross.setAttribute("visibility", "visible");
    tooltip.hidden = false;
    tooltip.innerHTML = `<strong>${seniorityDays(j)}</strong>${SERIES.map(
      (s) => `<span data-series="${s.key}"><span class="swatch" aria-hidden="true"></span>${s.label} : ${days(s.fn(j))}</span>`,
    ).join("")}`;
    const left = (x(j) / W) * box.width;
    tooltip.style.left = `${Math.min(left + 12, box.width - tooltip.offsetWidth - 4)}px`;
  });
  hit.addEventListener("pointerleave", () => {
    cross.setAttribute("visibility", "hidden");
    tooltip.hidden = true;
  });

  return {
    render() {
      const j = selected();
      marker.setAttribute("cx", x(j));
      marker.setAttribute("cy", y(notice(j)));
    },
  };
}
