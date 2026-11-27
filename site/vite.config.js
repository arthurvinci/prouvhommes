import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { readLaw } from "./law/extract.js";
import { renderArticles, renderPromises, renderToc } from "./law/render.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = resolve(here, "..");

/** Fills the <!--law:…--> placeholders of each page from texte/ and lean/. */
function law() {
  return {
    name: "prouvhommes-law",
    configureServer(server) {
      // Reload the page when the law or its formalisation changes.
      server.watcher.add([resolve(repoRoot, "texte"), resolve(repoRoot, "lean/Prouvhommes")]);
      server.watcher.on("change", (file) => {
        if (/\.(tex|lean)$/.test(file)) server.ws.send({ type: "full-reload" });
      });
    },
    transformIndexHtml(html) {
      const data = readLaw(repoRoot);
      const warn = (msg) => this?.warn?.(msg) ?? console.warn(msg);
      return html
        .replace("<!--law:articles-->", () => renderArticles(data, warn))
        .replace("<!--law:toc-->", () => renderToc(data))
        .replace("<!--law:promises-->", () => renderPromises(data))
        .replace("<!--law:article-count-->", () => String(data.articles.length));
    },
  };
}

export default defineConfig({
  plugins: [law()],
  build: {
    target: "es2022",
    rollupOptions: {
      input: {
        home: resolve(here, "index.html"),
        code: resolve(here, "code/index.html"),
      },
    },
  },
  test: {
    include: ["**/*.test.js"],
  },
});
