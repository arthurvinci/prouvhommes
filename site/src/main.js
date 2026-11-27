import "@fontsource-variable/source-serif-4";
import "@fontsource-variable/inter-tight";
import "@fontsource-variable/jetbrains-mono";
import "./style.css";

// Bouton de thème : par défaut on suit le système ; un clic force l'inverse
// du thème affiché et le mémorise.
const racine = document.documentElement;
const bouton = document.getElementById("theme");
const systemeSombre = matchMedia("(prefers-color-scheme: dark)");

const estSombre = () =>
  racine.dataset.theme ? racine.dataset.theme === "dark" : systemeSombre.matches;

function afficher() {
  const sombre = estSombre();
  bouton.textContent = sombre ? "Thème clair" : "Thème sombre";
  bouton.setAttribute("aria-pressed", String(sombre));
}

bouton.addEventListener("click", () => {
  const theme = estSombre() ? "light" : "dark";
  racine.dataset.theme = theme;
  localStorage.setItem("theme", theme);
  afficher();
});
systemeSombre.addEventListener("change", afficher);
afficher();
