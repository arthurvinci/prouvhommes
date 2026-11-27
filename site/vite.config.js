import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { readLaw } from "./law/extract.js";
import { buildPages } from "./law/pages.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = resolve(here, "..");

/**
 * Generates every page from texte/ and lean/ (law/pages.js). Pages are
 * virtual HTML entries: a new article gets its page without adding a file.
 */
function sitePages() {
  // route ("/code/indemnite/") ↔ virtual file (<site>/code/indemnite/index.html)
  const fileOf = (route) => resolve(here, `.${route}index.html`);
  let built = null; // Map file → html, for one build

  const generate = (warn) => {
    const pages = buildPages(readLaw(repoRoot), warn);
    return new Map([...pages].map(([route, html]) => [fileOf(route), { route, html }]));
  };
  const inputName = (route) => (route === "/" ? "index" : route.slice(1, -1).replaceAll("/", "--"));

  return {
    name: "prouvhommes-pages",
    enforce: "pre",
    config(_, { command }) {
      if (command !== "build") return;
      built = generate((msg) => console.warn(msg));
      return {
        build: {
          rollupOptions: {
            input: Object.fromEntries([...built].map(([file, { route }]) => [inputName(route), file])),
          },
        },
      };
    },
    resolveId(id) {
      if (built?.has(id)) return id;
    },
    load(id) {
      return built?.get(id)?.html;
    },
    configureServer(server) {
      // Reload the page when the law or its formalisation changes.
      server.watcher.add([resolve(repoRoot, "texte"), resolve(repoRoot, "lean/Prouvhommes")]);
      server.watcher.on("change", (file) => {
        if (/\.(tex|lean)$/.test(file)) server.ws.send({ type: "full-reload" });
      });
      // Served before Vite's own HTML middleware; regenerated on each request.
      server.middlewares.use(async (req, res, next) => {
        const path = decodeURIComponent((req.url ?? "/").split(/[?#]/)[0]);
        if (!(req.method === "GET" || req.method === "HEAD") || /\.[a-z0-9]+$/i.test(path)) return next();
        const route = path.endsWith("/") ? path : `${path}/`;
        const page = generate((msg) => server.config.logger.warn(msg)).get(fileOf(route));
        if (!page) return next();
        if (route !== path) {
          res.statusCode = 301;
          res.setHeader("Location", route + (req.url.slice(path.length) || ""));
          return res.end();
        }
        const html = await server.transformIndexHtml(req.url, page.html);
        res.setHeader("Content-Type", "text/html; charset=utf-8");
        res.end(html);
      });
    },
  };
}

export default defineConfig({
  plugins: [sitePages()],
  build: { target: "es2022" },
  test: { include: ["**/*.test.js"] },
});
