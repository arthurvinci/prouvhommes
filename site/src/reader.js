// Interactivity for the pre-rendered articles of /code/.

import { params, PARAM_SPECS, DERIVED } from "./lib/params.js";
import { checkPromise } from "./lib/promises.js";

export function initReader() {
  for (const faces of document.querySelectorAll(".faces")) initFaceSwitch(faces);
  for (const article of document.querySelectorAll(".law-article[data-links]")) initLinks(article);
  initParamEditor();
  params.addEventListener("change", renderParams);
  renderParams();
}

/* Two faces --------------------------------------------------------------- */

// Side by side when there is room (CSS container query); otherwise one face
// at a time, picked with these buttons.
function initFaceSwitch(faces) {
  faces.dataset.active = "law";
  faces.addEventListener("click", (e) => {
    const button = e.target.closest(".face-switch button");
    if (!button) return;
    faces.dataset.active = button.dataset.face;
    for (const b of faces.querySelectorAll(".face-switch button")) {
      b.setAttribute("aria-pressed", String(b === button));
    }
  });
}

/* Linked phrases (CSS Custom Highlight API) ------------------------------ */

const HIGHLIGHT = "law-link";
const supportsHighlights = typeof CSS !== "undefined" && "highlights" in CSS;

function initLinks(article) {
  const patterns = JSON.parse(article.dataset.links);
  const lean = article.querySelector(".face-lean");
  const leanRanges = rangesByKey(lean, patterns);

  /** @type {Map<string, Range[]>} */
  const ranges = new Map();
  for (const key of Object.keys(patterns)) {
    const lawRanges = [...article.querySelectorAll(`.face-law [data-link="${key}"]`)].map((el) => {
      const r = document.createRange();
      r.selectNodeContents(el);
      return r;
    });
    ranges.set(key, [...lawRanges, ...(leanRanges.get(key) ?? [])]);
  }

  let active = null;
  const activate = (key) => {
    if (key === active) return;
    active = key;
    for (const el of article.querySelectorAll(".face-law [data-link]")) {
      el.classList.toggle("is-linked", el.dataset.link === key);
    }
    if (!supportsHighlights) return;
    if (key && ranges.get(key)?.length) CSS.highlights.set(HIGHLIGHT, new Highlight(...ranges.get(key)));
    else CSS.highlights.delete(HIGHLIGHT);
  };

  const law = article.querySelector(".face-law");
  for (const el of law.querySelectorAll("[data-link]")) {
    if (!el.matches("button")) el.tabIndex = 0;
  }
  law.addEventListener("pointerover", (e) => activate(e.target.closest("[data-link]")?.dataset.link ?? null));
  law.addEventListener("pointerleave", () => activate(null));
  law.addEventListener("focusin", (e) => activate(e.target.closest("[data-link]")?.dataset.link ?? null));
  law.addEventListener("focusout", () => activate(null));

  // Hovering the Lean code lights up the law phrase too.
  lean.addEventListener("pointermove", (e) => {
    const pos = caretAt(e.clientX, e.clientY);
    if (!pos || !lean.contains(pos.node)) return activate(null);
    for (const [key, list] of leanRanges) {
      if (list.some((r) => r.isPointInRange(pos.node, pos.offset))) return activate(key);
    }
    activate(null);
  });
  lean.addEventListener("pointerleave", () => activate(null));
}

/** Finds each key's regular expression in the text of `root`, as Ranges. */
function rangesByKey(root, patterns) {
  const nodes = [];
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  let text = "";
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    // Skip figure captions (file names) and comments.
    if (n.parentElement.closest("figcaption, .lean-comment")) continue;
    nodes.push({ node: n, start: text.length });
    text += n.data;
  }
  const locate = (offset) => {
    let lo = 0;
    let hi = nodes.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (nodes[mid].start <= offset) lo = mid;
      else hi = mid - 1;
    }
    return { node: nodes[lo].node, offset: offset - nodes[lo].start };
  };
  const result = new Map();
  for (const [key, source] of Object.entries(patterns)) {
    const list = [];
    for (const m of text.matchAll(new RegExp(source, "gu"))) {
      if (!m[0]) continue;
      const a = locate(m.index);
      const b = locate(m.index + m[0].length - 1);
      const r = document.createRange();
      r.setStart(a.node, a.offset);
      r.setEnd(b.node, b.offset + 1);
      list.push(r);
    }
    result.set(key, list);
  }
  return result;
}

function caretAt(x, y) {
  if (document.caretPositionFromPoint) {
    const p = document.caretPositionFromPoint(x, y);
    return p && { node: p.offsetNode, offset: p.offset };
  }
  const r = document.caretRangeFromPoint?.(x, y);
  return r && { node: r.startContainer, offset: r.startOffset };
}

/* Live thresholds --------------------------------------------------------- */

function initParamEditor() {
  const editor = document.getElementById("param-editor");
  if (!editor) return;
  const range = editor.querySelector("input");
  const label = editor.querySelector("[data-param-label]");
  const value = editor.querySelector("[data-param-value]");
  const lawNote = editor.querySelector("[data-param-law]");
  const anchorSupported = CSS.supports("anchor-name: --a");
  let current = null;
  let anchor = null;

  const sync = () => {
    const spec = PARAM_SPECS[current];
    const v = params.values[current];
    value.textContent = spec.describe(v);
    range.setAttribute("aria-valuetext", spec.describe(v));
    range.style.setProperty("--fill", `${((v - spec.min) / (spec.max - spec.min)) * 100}%`);
    lawNote.textContent = v === spec.law ? "Valeur du code." : `Le code dit : ${spec.describe(spec.law)}.`;
  };

  document.addEventListener("click", (e) => {
    const button = e.target.closest(".live-number");
    if (!button) return;
    current = button.dataset.param;
    const spec = PARAM_SPECS[current];
    Object.assign(range, { min: spec.min, max: spec.max, step: spec.step });
    range.value = String(params.values[current]);
    label.textContent = spec.label;
    sync();

    anchor?.style.removeProperty("anchor-name");
    anchor = button;
    if (anchorSupported) button.style.setProperty("anchor-name", "--param-anchor");
    editor.showPopover({ source: button });
    if (!anchorSupported) {
      const r = button.getBoundingClientRect();
      editor.style.top = `${r.bottom + 8}px`;
      editor.style.left = `${Math.max(8, Math.min(r.left, innerWidth - editor.offsetWidth - 8))}px`;
    }
    range.focus();
  });

  range.addEventListener("input", () => {
    params.set(current, Number(range.value));
    sync();
  });
  editor.addEventListener("toggle", (e) => {
    if (e.newState === "closed") anchor?.focus();
  });

  for (const b of document.querySelectorAll("[data-reset-params]")) {
    b.addEventListener("click", () => params.reset());
  }
}

function renderParams() {
  const v = params.values;
  for (const el of document.querySelectorAll(".live-number")) {
    const spec = PARAM_SPECS[el.dataset.param];
    el.textContent = spec.display(v[el.dataset.param]);
    el.classList.toggle("is-variant", v[el.dataset.param] !== spec.law);
    el.setAttribute("aria-label", `${spec.label} : ${spec.describe(v[el.dataset.param])}. Modifier.`);
  }
  for (const el of document.querySelectorAll("[data-derived]")) {
    el.textContent = DERIVED[el.dataset.derived](v);
  }

  const banner = document.querySelector("[data-variant-banner]");
  if (banner) {
    banner.hidden = params.isLaw;
    banner.querySelector("[data-variant-summary]").textContent = params.changed
      .map((k) => `${PARAM_SPECS[k].label.toLowerCase()} : ${PARAM_SPECS[k].describe(v[k])}`)
      .join(" ; ");
  }

  const p = params.p6;
  for (const el of document.querySelectorAll("[data-check]")) {
    const item = el.closest(".guarantee");
    const result = params.isLaw ? null : checkPromise(el.dataset.check, p);
    item.dataset.state = result?.state ?? (params.isLaw ? "law" : "unknown");
    el.textContent = result?.text ?? (params.isLaw ? "" : "Pas de vérification automatique pour cette variante.");
  }
}
