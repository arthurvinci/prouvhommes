// Anti-manipulation demo (salaireReference_sensibilite, T-MANIP): change the
// last salary and watch the reference salary move by only Δ/24, and the
// severance by less than Δ/4 + 1 cent. A bar chart shows each month's weight.

import { params } from "../lib/params.js";
import { referenceSalary, severancePay } from "../lib/p6.js";
import { sub, mul, pow, ONE, toNumber } from "../lib/rational.js";
import { euros, eurosOfRational, parseEuros, seniority } from "../lib/format.js";

const FIRED = { kind: "ordinaryTermination", party: "employer" };

/** `compact`: inside an article, without the weights chart (on `fullUrl`). */
export function initManipulation(root, { compact = false, fullUrl } = {}) {
  root.innerHTML = `
<h2 class="extra-title">${compact ? "Essayer : peut-on gonfler ou dégonfler l'indemnité ?" : "Simulateur"}</h2>
<p class="extra-lede">Un salarié payé le même salaire chaque mois est licencié. Juste avant, l'employeur baisse son dernier salaire (ou le salarié obtient une forte prime). Que devient l'indemnité ?</p>
<div class="simulator">
  <form class="sim-controls" novalidate>
    <div class="field">
      <label for="manip-usual">Salaire habituel</label>
      <span class="input-euro"><input id="manip-usual" inputmode="decimal" autocomplete="off" value="3 000" aria-describedby="manip-usual-error" /><span aria-hidden="true">€</span></span>
      <p id="manip-usual-error" class="field-error" data-out="usual-error"></p>
    </div>
    <div class="field">
      <label for="manip-last">Dernier salaire</label>
      <input id="manip-last" class="slider" type="range" min="0" max="200" step="1" value="100" />
      <output for="manip-last" data-out="last"></output>
    </div>
    <div class="field">
      <label for="manip-seniority">Ancienneté</label>
      <input id="manip-seniority" class="slider" type="range" min="1" max="240" step="1" value="120" />
      <output for="manip-seniority" data-out="seniority"></output>
    </div>
  </form>
  <dl class="sim-compare" aria-live="polite">
    <div><dt>Variation du dernier salaire</dt><dd data-out="delta"></dd></div>
    <div><dt>Salaire de référence</dt><dd data-out="sr"></dd></div>
    <div><dt>Indemnité</dt><dd data-out="pay"></dd></div>
  </dl>
</div>
${
  compact
    ? `<p class="more"><a href="${fullUrl}">Voir le poids de chaque mois dans le salaire de référence</a></p>`
    : `<figure class="chart">
  <figcaption data-out="weights-caption"></figcaption>
  <div class="chart-plot"><svg data-weights role="img"></svg><div class="chart-tooltip" data-tooltip hidden></div></div>
</figure>`
}`;

  const $ = (sel) => root.querySelector(sel);
  const usualInput = $("#manip-usual");
  const lastInput = $("#manip-last");
  const seniorityInput = $("#manip-seniority");
  let usual = 300000n;

  function render() {
    const p = params.p6;
    seniorityInput.max = String(p.saturationMonths); // clamps the value
    const pct = Number(lastInput.value); // last salary, in % of the usual one
    const last = (usual * BigInt(pct)) / 100n;
    const delta = last - usual;
    const m = Number(seniorityInput.value);
    const months = Math.max(2, Math.min(m, p.windowSize));
    const base = Array.from({ length: months - 1 }, () => usual);

    $('[data-out="last"]').textContent = `${euros(last)} (${pct} % du salaire habituel)`;
    lastInput.setAttribute("aria-valuetext", euros(last));
    lastInput.style.setProperty("--fill", `${pct / 2}%`);
    $('[data-out="seniority"]').textContent = seniority(m);
    seniorityInput.setAttribute("aria-valuetext", seniority(m));
    seniorityInput.style.setProperty("--fill", `${((m - 1) / (p.saturationMonths - 1)) * 100}%`);

    const srUsual = referenceSalary([...base, usual], p);
    const srNew = referenceSalary([...base, last], p);
    const payUsual = severancePay([...base, usual], m, FIRED, p);
    const payNew = severancePay([...base, last], m, FIRED, p);
    const sign = (c) => (c > 0n ? "+" : "");

    $('[data-out="delta"]').textContent = `${sign(delta)}${euros(delta)}`;
    $('[data-out="sr"]').innerHTML = `${eurosOfRational(srNew)} <span class="delta">${sign(delta)}${eurosOfRational(sub(srNew, srUsual))}, soit Δ/${p.alpha.d}</span>`;
    const payDelta = payNew - payUsual;
    const absDelta = delta < 0n ? -delta : delta;
    $('[data-out="pay"]').innerHTML = `${euros(payNew)} <span class="delta">${sign(payDelta)}${euros(payDelta)}, ${params.isLaw ? "borne prouvée" : "borne promise"} : moins de ${euros((absDelta + 3n) / 4n + 1n)}</span>`;

    if (compact) return;
    renderWeights($("[data-weights]"), $("[data-tooltip]"), months, p.alpha);
    $('[data-out="weights-caption"]').textContent =
      `Poids de chacun des ${months} mois pris en compte dans le salaire de référence. Le dernier mois pèse 1/${p.alpha.d}.`;
  }

  usualInput.addEventListener("input", () => {
    const cents = parseEuros(usualInput.value);
    const error = $('[data-out="usual-error"]');
    if (cents === null || cents === 0n) {
      error.textContent = "Saisissez un salaire positif, par exemple 3 000.";
      usualInput.setAttribute("aria-invalid", "true");
      return;
    }
    error.textContent = "";
    usualInput.removeAttribute("aria-invalid");
    usual = cents;
    render();
  });
  for (const input of [lastInput, seniorityInput]) input.addEventListener("input", render);
  params.addEventListener("change", render);
  render();
}

/** Weight of each month in the EMA: the first keeps (1 − α)^(n−1), month i
 * gets α(1 − α)^(n−1−i). */
function weights(n, alpha) {
  const keep = sub(ONE, alpha);
  return Array.from({ length: n }, (_, i) =>
    i === 0 ? pow(keep, n - 1) : mul(alpha, pow(keep, n - 1 - i)),
  );
}

function renderWeights(svg, tooltip, n, alpha) {
  const W = 640;
  const H = 180;
  const pad = { top: 12, right: 12, bottom: 28, left: 44 };
  const iw = W - pad.left - pad.right;
  const ih = H - pad.top - pad.bottom;
  const w = weights(n, alpha);
  const values = w.map(toNumber); // display only
  const max = Math.max(...values) * 1.15;
  const band = iw / n;
  const gap = Math.min(2, band / 4);
  const NS = "http://www.w3.org/2000/svg";
  const el = (name, attrs, text) => {
    const e = document.createElementNS(NS, name);
    for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
    if (text !== undefined) e.textContent = text;
    return e;
  };
  svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
  svg.setAttribute("aria-label", `Diagramme en barres : poids de ${n} mois. Le premier mois pèse ${pctText(w[0])}, le dernier ${pctText(w[n - 1])}.`);
  svg.replaceChildren();

  const grid = el("g", { class: "grid" });
  const step = max > 0.2 ? 0.05 : 0.02;
  for (let v = 0; v <= max; v += step) {
    const yy = pad.top + ih - (v / max) * ih;
    grid.append(el("line", { x1: pad.left, x2: pad.left + iw, y1: yy, y2: yy }));
    grid.append(el("text", { x: pad.left - 8, y: yy + 4, "text-anchor": "end" }, `${Math.round(v * 100)} %`));
  }
  grid.append(el("text", { x: pad.left, y: H - 8 }, "plus ancien"));
  grid.append(el("text", { x: pad.left + iw, y: H - 8, "text-anchor": "end" }, "dernier mois"));
  svg.append(grid);

  values.forEach((v, i) => {
    const h = Math.max(0, (v / max) * ih);
    const bar = el("rect", {
      class: i === n - 1 ? "bar bar-last" : "bar",
      x: pad.left + i * band + gap / 2,
      y: pad.top + ih - h,
      width: Math.max(1, band - gap),
      height: h,
      rx: Math.min(4, (band - gap) / 2),
    });
    svg.append(bar);
    const hit = el("rect", { class: "hit", x: pad.left + i * band, y: pad.top, width: band, height: ih });
    hit.addEventListener("pointerenter", () => {
      tooltip.hidden = false;
      tooltip.innerHTML = `<strong>${i === n - 1 ? "Dernier mois" : i === 0 ? "Premier mois de la fenêtre" : `Mois ${i + 1} sur ${n}`}</strong><span>Poids : ${pctText(w[i])}</span>`;
      const box = svg.getBoundingClientRect();
      const left = ((pad.left + i * band) / W) * box.width;
      tooltip.style.left = `${Math.min(left + 8, box.width - tooltip.offsetWidth - 4)}px`;
    });
    hit.addEventListener("pointerleave", () => (tooltip.hidden = true));
    svg.append(hit);
  });
}

const pctText = (r) => `${(toNumber(r) * 100).toFixed(1).replace(".", ",")} %`;
