// The shell shared by every page: head, header with the four tabs, footer.

import { escapeHtml, REPO } from "./render.js";

export const TABS = [
  { key: "code", href: "/code/", label: "Le code" },
  { key: "promesses", href: "/promesses/", label: "Promesses" },
  { key: "simulateurs", href: "/simulateurs/", label: "Simulateurs" },
  { key: "methode", href: "/methode/", label: "Méthode" },
];

/**
 * @param {{ title: string, description: string, tab?: string, body: string,
 *   current?: boolean }} page `tab` marks the active tab; `current` marks the
 *   tab itself as the current page (its landing page) rather than a section.
 */
export function layout({ title, description, tab, body, current = false }) {
  const nav = TABS.map((t) => {
    const attr = t.key === tab ? (current ? ' aria-current="page"' : ' aria-current="true"') : "";
    return `<a href="${t.href}"${attr}>${t.label}</a>`;
  }).join("\n        ");
  return `<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="color-scheme" content="light dark" />
    <script>
      // Stored theme, applied before first paint (see src/theme.js).
      try {
        document.querySelector('meta[name="color-scheme"]').content =
          localStorage.getItem("color-scheme") ?? "light dark";
      } catch {}
    </script>
    <title>${escapeHtml(title)}</title>
    <meta name="description" content="${escapeHtml(description)}" />
    <script type="module" src="/src/main.js"></script>
  </head>
  <body>
    <a class="skip-link" href="#contenu">Aller au contenu</a>
    <header class="site-header">
      <a class="brand" href="/"${tab ? "" : ' aria-current="page"'}>Prouv’hommes</a>
      <nav class="tabs" aria-label="Rubriques">
        ${nav}
      </nav>
      <button type="button" class="theme-toggle" data-theme-toggle aria-pressed="false">
        <span data-label>Thème sombre</span>
      </button>
    </header>

    <div class="variant-banner" data-variant-banner hidden>
      <p>
        Vous lisez une <strong>variante</strong> du code :
        <span data-variant-summary></span>.
        Les preuves Lean ne portent que sur le texte du code.
      </p>
      <button type="button" data-reset-params>Revenir au texte du code</button>
    </div>

    <div id="contenu">
${body}
    </div>

    <footer class="site-footer">
      <p>
        Prouv’hommes, une proposition de code du travail formalisée en Lean.
        <a href="${REPO}">Sources</a> ·
        <a href="${REPO}/raw/main/texte/prouvhommes.pdf">Texte en PDF</a>
      </p>
    </footer>

    <div id="param-editor" class="param-editor" popover>
      <label class="param-label" for="param-range" data-param-label></label>
      <input id="param-range" type="range" class="slider" />
      <p class="param-value" data-param-value aria-live="polite"></p>
      <p class="param-law" data-param-law></p>
    </div>
  </body>
</html>
`;
}
