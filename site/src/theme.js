// Theme toggle (Modern Web Guidance, "Dark mode toggles"). The inline script
// in each page's <head> applies the stored choice to
// <meta name="color-scheme"> before first paint; CSS maps that meta back to
// `color-scheme`, so the page still follows the system if JS never runs.

const KEY = "color-scheme";
const meta = document.querySelector('meta[name="color-scheme"]');
const systemDark = matchMedia("(prefers-color-scheme: dark)");

const stored = () => {
  try {
    return localStorage.getItem(KEY);
  } catch {
    return null;
  }
};
const rendered = () => {
  const v = meta.content;
  return v === "light" || v === "dark" ? v : systemDark.matches ? "dark" : "light";
};

function apply(value) {
  meta.content = value ?? "light dark";
  render();
}

function render() {
  const dark = rendered() === "dark";
  for (const button of document.querySelectorAll("[data-theme-toggle]")) {
    button.setAttribute("aria-pressed", String(dark));
    button.querySelector("[data-label]").textContent = dark ? "Thème clair" : "Thème sombre";
  }
}

export function initTheme() {
  for (const button of document.querySelectorAll("[data-theme-toggle]")) {
    button.addEventListener("click", () => {
      const target = rendered() === "dark" ? "light" : "dark";
      const system = systemDark.matches ? "dark" : "light";
      // Matching the system means "follow the system" again.
      const value = target === system ? null : target;
      try {
        value ? localStorage.setItem(KEY, value) : localStorage.removeItem(KEY);
      } catch {
        // Storage blocked: the choice still applies to this page.
      }
      apply(value);
    });
  }
  addEventListener("storage", (e) => e.key === KEY && apply(e.newValue));
  systemDark.addEventListener("change", render);
  apply(stored());
}
