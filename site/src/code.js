import "./base.js";
import { initReader } from "./reader.js";
import { initSeverance } from "./components/severance.js";
import { initManipulation } from "./components/manipulation.js";

const EXTRAS = {
  "severance-simulator": initSeverance,
  "manipulation-demo": initManipulation,
};

for (const el of document.querySelectorAll("[data-extra]")) EXTRAS[el.dataset.extra]?.(el);
initReader();
