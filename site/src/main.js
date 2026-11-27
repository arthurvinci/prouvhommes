import "@fontsource-variable/source-serif-4";
import "@fontsource-variable/inter-tight";
import "@fontsource-variable/jetbrains-mono";
import "./style.css";

// Theme toggle: follow the system by default; a click forces the opposite
// of the current theme and remembers it.
const root = document.documentElement;
const toggle = document.getElementById("theme-toggle");
const systemDark = matchMedia("(prefers-color-scheme: dark)");

const isDark = () =>
  root.dataset.theme ? root.dataset.theme === "dark" : systemDark.matches;

function render() {
  const dark = isDark();
  toggle.textContent = dark ? "Thème clair" : "Thème sombre";
  toggle.setAttribute("aria-pressed", String(dark));
}

toggle.addEventListener("click", () => {
  const theme = isDark() ? "light" : "dark";
  root.dataset.theme = theme;
  localStorage.setItem("theme", theme);
  render();
});
systemDark.addEventListener("change", render);
render();
