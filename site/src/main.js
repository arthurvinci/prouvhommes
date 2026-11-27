// The one script of every page. Pages are static HTML (law/pages.js); this
// adds the theme toggle, the reader (linked faces, live thresholds) and the
// simulators found on the page.
import "./base.js";
import { initReader } from "./reader.js";
import { initSeverance } from "./components/severance.js";
import { initManipulation } from "./components/manipulation.js";

const EXTRAS = {
  "severance-simulator": initSeverance,
  "manipulation-demo": initManipulation,
};

for (const el of document.querySelectorAll("[data-extra]")) {
  EXTRAS[el.dataset.extra]?.(el, { compact: "compact" in el.dataset, fullUrl: el.dataset.fullUrl });
}
initReader();

// Links from the single-page reader (/code/#art-indemnite) now go to the
// article's own page.
if (location.pathname === "/code/" && location.hash.startsWith("#art-")) {
  location.replace(`/code/${location.hash.slice("#art-".length)}/`);
}
