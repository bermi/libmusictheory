#!/usr/bin/env node

import fs from "node:fs";
import http from "node:http";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const spaDir = path.join(rootDir, "zig-out", "wasm-harmonious-spa");
const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
const timeoutMs = Number.parseInt(process.env.LMT_HARMONIOUS_SPA_TIMEOUT_MS || "300000", 10);
const requestedPort = parsePort(process.env.LMT_VALIDATION_PORT || "");
const compatRequestPattern = /\/(?:tmp\/harmoniousapp\.net\/)?(?:vert-text-black|even|scale|opc|oc|optc|eadgbe|center-square-text|wide-chord|chord-clipped|grand-chord|majmin|chord|vert-text-b2t-black)\//;
const keyTriRequestPattern = /\/key-tri\//;
const shellHrefForRoute = (route) => `/index.html?route=${encodeURIComponent(route)}`;
const fallbackRoutePattern = /^\/(?:p|keyboard|eadgbe-frets)\//;
const rawShellRoutePattern = /^\/(?:p|keyboard|eadgbe-frets)\//;
const mimeTypes = new Map([
  [".css", "text/css; charset=utf-8"],
  [".gif", "image/gif"],
  [".html", "text/html; charset=utf-8"],
  [".ico", "image/x-icon"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".js", "application/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".png", "image/png"],
  [".svg", "image/svg+xml; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".woff", "font/woff"],
  [".woff2", "font/woff2"],
]);

function parsePort(raw) {
  if (raw == null || String(raw).trim() === "") return null;
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isFinite(value) || value <= 0 || value > 65535) {
    throw new Error(`invalid port: ${raw}`);
  }
  return value;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function resolveBrowserExecutable() {
  const candidates = [
    process.env.LMT_PLAYWRIGHT_BROWSER_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium-browser",
    "/usr/bin/chromium",
  ].filter(Boolean);
  for (const one of candidates) {
    if (fs.existsSync(one)) return one;
  }
  return null;
}

function ensurePlaywrightModule() {
  const toolsDir = path.join(rootDir, ".zig-cache", "playwright-node");
  const modulePath = path.join(toolsDir, "node_modules", "playwright", "index.mjs");
  if (fs.existsSync(modulePath)) return modulePath;

  fs.mkdirSync(toolsDir, { recursive: true });
  const result = spawnSync(
    "npm",
    ["install", "--prefix", toolsDir, "--no-save", "playwright@1.52.0"],
    {
      cwd: rootDir,
      stdio: "inherit",
      env: {
        ...process.env,
        PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: process.env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD || "1",
      },
    },
  );
  if (result.status !== 0) {
    throw new Error(`failed to install playwright toolchain (exit ${result.status})`);
  }
  if (!fs.existsSync(modulePath)) {
    throw new Error(`playwright module not found after install: ${modulePath}`);
  }
  return modulePath;
}

function resolveValidationPort() {
  if (requestedPort != null) return Promise.resolve(requestedPort);
  return new Promise((resolve, reject) => {
    const probe = net.createServer();
    probe.unref();
    probe.once("error", reject);
    probe.listen(0, host, () => {
      const address = probe.address();
      if (!address || typeof address === "string") {
        probe.close(() => reject(new Error("failed to resolve ephemeral validation port")));
        return;
      }
      const resolvedPort = address.port;
      probe.close((err) => {
        if (err) reject(err);
        else resolve(resolvedPort);
      });
    });
  });
}

async function waitForServer(url, deadlineMs) {
  const start = Date.now();
  while (Date.now() - start < deadlineMs) {
    try {
      const res = await fetch(url, { method: "GET" });
      if (res.ok) return;
    } catch (_err) {
      // keep polling
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

function decodePathname(pathname) {
  try {
    return decodeURIComponent(pathname);
  } catch (_err) {
    return pathname;
  }
}

function contentTypeFor(filePath) {
  return mimeTypes.get(path.extname(filePath).toLowerCase()) || "application/octet-stream";
}

function resolveStaticFile(pathname) {
  const decodedPath = decodePathname(pathname);
  const normalized = path.posix.normalize(decodedPath === "/" ? "/index.html" : decodedPath);
  const relative = normalized.replace(/^\/+/, "");
  const absolute = path.resolve(spaDir, relative);
  if (!absolute.startsWith(spaDir)) return null;
  if (fs.existsSync(absolute) && fs.statSync(absolute).isFile()) return absolute;
  if (fs.existsSync(absolute) && fs.statSync(absolute).isDirectory()) {
    const indexPath = path.join(absolute, "index.html");
    if (fs.existsSync(indexPath) && fs.statSync(indexPath).isFile()) return indexPath;
  }
  return null;
}

function serveFile(res, statusCode, filePath, extraHeaders = {}) {
  const body = fs.readFileSync(filePath);
  res.writeHead(statusCode, {
    "content-length": body.length,
    "content-type": contentTypeFor(filePath),
    ...extraHeaders,
  });
  res.end(body);
}

function startServer(port) {
  const fallbackFile = path.join(spaDir, "404.html");
  const server = http.createServer((req, res) => {
    const url = new URL(req.url || "/", `http://${host}:${port}`);
    const filePath = resolveStaticFile(url.pathname);
    if (filePath) {
      serveFile(res, 200, filePath);
      return;
    }

    if (fs.existsSync(fallbackFile) && fallbackRoutePattern.test(url.pathname)) {
      serveFile(res, 404, fallbackFile, { "x-lmt-spa-fallback": "1" });
      return;
    }

    if (fs.existsSync(fallbackFile)) {
      serveFile(res, 404, fallbackFile, { "x-lmt-spa-fallback": "1" });
      return;
    }

    const body = Buffer.from("Not found\n", "utf8");
    res.writeHead(404, {
      "content-length": body.length,
      "content-type": "text/plain; charset=utf-8",
    });
    res.end(body);
  });

  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, host, () => {
      let closing = null;
      resolve({
        close: () => {
          if (closing) return closing;
          closing = new Promise((done, closeErr) => server.close((err) => (err ? closeErr(err) : done())));
          return closing;
        },
      });
    });
  });
}

async function waitForSpaReady(page, expectedRoute = "/index.html") {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      state: window.__lmtHarmoniousSpa || null,
      title: document.title,
      home: !!document.querySelector(".main-home"),
      loadingText: document.getElementById("spa-shell-loading")?.textContent || "",
      pathnameSearch: `${window.location.pathname}${window.location.search}`,
      canonicalHref: document.getElementById("spa-shell-canonical")?.href || "",
    }));
    if (snapshot.state?.bootError) {
      throw new Error(`spa boot error: ${snapshot.state.bootError}`);
    }
    if (snapshot.state?.ready && snapshot.state?.lastRoute === expectedRoute) {
      return snapshot;
    }
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for spa ready at ${expectedRoute}; snapshot=${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}

async function waitForRoute(page, route, extraCheck) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate((expectedRoute) => ({
      state: window.__lmtHarmoniousSpa || null,
      title: document.title,
      keyboardEntries: document.querySelectorAll(".inside-search .entry").length,
      fretEntries: document.querySelectorAll(".inside-frets-search .entry").length,
      sliderEntries: document.querySelectorAll(".only3 .slider-info").length,
      sliderText: Array.from(document.querySelectorAll(".only3 .slider-info .slider-text, .only3 .slider-info .centery"))
        .map((node) => node.textContent?.trim() || "")
        .filter(Boolean)
        .join(" | "),
      sliderImageCount: Object.keys(window.HarmoniousClient?.SliderImages || {}).length,
      currentKeyText: document.getElementById("current")?.textContent?.trim() || "",
      currentKeyHref: document.getElementById("current-href")?.getAttribute("href") || "",
      compatImages: document.querySelectorAll("img[data-lmt-image-source='wasm-compat']").length,
      bodyText: document.body?.textContent || "",
      hrefs: Array.from(document.querySelectorAll("a[href]"), (node) => node.getAttribute("href")).filter(Boolean).slice(0, 50),
      pathnameSearch: `${window.location.pathname}${window.location.search}`,
      canonicalHref: document.getElementById("spa-shell-canonical")?.href || "",
      expectedRoute,
    }), route);
    if (snapshot.state?.bootError) {
      throw new Error(`spa boot error during route wait: ${snapshot.state.bootError}`);
    }
    const routeMatch = route == null || snapshot.state?.lastRoute === route;
    if (routeMatch && (!extraCheck || extraCheck(snapshot))) {
      return snapshot;
    }
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for route ${route}; snapshot=${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}

async function waitForPageValue(page, probe, description) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await probe();
    if (snapshot?.ok) {
      return snapshot;
    }
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for ${description}; snapshot=${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}

async function fragmentLinkSnapshot(page, selector) {
  return page.evaluate((query) => Array.from(document.querySelectorAll(`${query} a[href]`), (node) => ({
    href: node.getAttribute("href") || "",
    shellRoute: node.getAttribute("data-lmt-shell-route") || "",
    text: node.textContent?.trim() || "",
  })), selector);
}

function assertShellFragmentLinks(links, label) {
  if (!links.length) {
    throw new Error(`${label} produced no links`);
  }
  const rawLinks = links.filter((link) => rawShellRoutePattern.test(link.href));
  if (rawLinks.length > 0) {
    throw new Error(`${label} leaked raw route hrefs: ${JSON.stringify(rawLinks.slice(0, 10))}`);
  }
  const shellLinks = links.filter((link) => link.shellRoute);
  if (!shellLinks.length) {
    throw new Error(`${label} did not expose any data-lmt-shell-route anchors: ${JSON.stringify(links.slice(0, 10))}`);
  }
  const mismatchedLinks = shellLinks.filter((link) => link.href !== shellHrefForRoute(link.shellRoute));
  if (mismatchedLinks.length > 0) {
    throw new Error(`${label} reported inconsistent shell-route anchors: ${JSON.stringify(mismatchedLinks.slice(0, 10))}`);
  }
}

async function main() {
  const indexPath = path.join(spaDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing SPA page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const server = await startServer(port);
  const baseUrl = `http://${host}:${port}`;
  const spaUrl = new URL(`${baseUrl}/index.html`);
  const compatRequests = [];
  const keyTriRequests = [];
  const faviconRequests = [];

  const cleanupServer = async () => {
    await server.close();
  };
  process.on("exit", () => {
    void cleanupServer();
  });
  process.on("SIGINT", () => {
    void cleanupServer().finally(() => process.exit(130));
  });
  process.on("SIGTERM", () => {
    void cleanupServer().finally(() => process.exit(143));
  });

  try {
    await waitForServer(spaUrl.toString(), 15_000);

    const playwrightModulePath = ensurePlaywrightModule();
    const { chromium } = await import(pathToFileURL(playwrightModulePath).href);
    const executablePath = resolveBrowserExecutable();
    const browser = await chromium.launch({ headless: true, ...(executablePath ? { executablePath } : {}) });

    try {
      const page = await browser.newPage();
      page.on("request", (request) => {
        const url = request.url();
        const pathname = new URL(url).pathname;
        if (compatRequestPattern.test(pathname)) {
          compatRequests.push(url);
        }
        if (keyTriRequestPattern.test(pathname)) {
          keyTriRequests.push(url);
        }
        if (pathname === "/favicon.ico") {
          faviconRequests.push(url);
        }
      });

      await page.goto(spaUrl.toString(), { waitUntil: "domcontentloaded" });
      const ready = await waitForSpaReady(page, "/index.html");
      if (!ready.home) {
        throw new Error(`home page did not render through SPA shell: ${JSON.stringify(ready)}`);
      }
      if (ready.pathnameSearch !== "/index.html" || ready.canonicalHref !== spaUrl.toString()) {
        throw new Error(`home shell metadata mismatch: ${JSON.stringify(ready)}`);
      }
      const homeAutoLink = await page.evaluate(() => document.querySelector('a[data-lmt-shell-route="/p/a7/Keys.html"]')?.getAttribute("href") || null);
      if (homeAutoLink !== shellHrefForRoute("/p/a7/Keys.html")) {
        throw new Error(`auto:* links were not rewritten on home page; got ${homeAutoLink}`);
      }
      const homeCompatImages = await page.evaluate(() => document.querySelectorAll("img[data-lmt-image-source='wasm-compat']").length);
      if (homeCompatImages < 10) {
        throw new Error(`expected wasm-backed home images, got compat count=${homeCompatImages}`);
      }

      await page.click(`a[href="${shellHrefForRoute("/p/a7/Keys.html")}"]`);
      const keysPage = await waitForRoute(
        page,
        "/p/a7/Keys.html",
        (snapshot) => snapshot.title.includes("Keys - Harmonious") && snapshot.sliderEntries > 0 && snapshot.sliderImageCount > 0,
      );
      if (!keysPage.title.includes("Keys - Harmonious")) {
        throw new Error(`keys page title mismatch: ${keysPage.title}`);
      }
      if (keysPage.sliderEntries <= 0) {
        throw new Error(`keys slider fragment did not populate on initial route load: ${JSON.stringify(keysPage)}`);
      }
      if (keysPage.sliderImageCount <= 0) {
        throw new Error(`keys slider background images did not load locally: ${JSON.stringify(keysPage)}`);
      }

      await page.evaluate(() => window.HarmoniousClient.fakeNavigateTo("/p/7c/E-Major"));
      const eMajorPage = await waitForRoute(
        page,
        "/p/7c/E-Major.html",
        (snapshot) => snapshot.title.includes("E Major")
          && snapshot.currentKeyText.includes("Key of E")
          && snapshot.currentKeyHref === shellHrefForRoute("/p/7c/E-Major")
          && snapshot.sliderEntries > 0
          && snapshot.sliderImageCount > 0
          && snapshot.sliderText.includes("E"),
      );
      if (
        !eMajorPage.title.includes("E Major")
        || !eMajorPage.currentKeyText.includes("Key of E")
        || eMajorPage.currentKeyHref !== shellHrefForRoute("/p/7c/E-Major")
        || eMajorPage.sliderEntries <= 0
        || eMajorPage.sliderImageCount <= 0
        || !eMajorPage.sliderText.includes("E")
      ) {
        throw new Error(`E major key-slider state did not stabilize correctly: ${JSON.stringify(eMajorPage)}`);
      }

      const keySliderVariant = await page.evaluate(() => new Promise((resolve, reject) => {
        window.jQuery.get("/search-key-tri/4s,0,3,2", (html) => resolve(String(html)))
          .fail((err) => reject(new Error(`search-key-tri request failed: ${JSON.stringify(err)}`)));
      }));
      if (!/E(?:\s|<|&)/.test(keySliderVariant)) {
        throw new Error(`search-key-tri variant did not resolve active-key content: ${keySliderVariant.slice(0, 500)}`);
      }
      await page.evaluate((html) => {
        const only3 = document.querySelector(".only3");
        if (!only3) throw new Error("missing .only3 scroller");
        only3.innerHTML = html;
        window.HarmoniousSPA?.refreshCompatImages?.();
      }, keySliderVariant);
      const variantSnapshot = await waitForRoute(
        page,
        "/p/7c/E-Major.html",
        (snapshot) => snapshot.sliderEntries > 0 && /E\s+min|E\s+dim/i.test(snapshot.sliderText),
      );
      if (!/E\s+min|E\s+dim/i.test(variantSnapshot.sliderText)) {
        throw new Error(`key-slider variant did not visibly change after local fragment injection: ${JSON.stringify(variantSnapshot)}`);
      }
      const sliderCardShellHref = await fragmentLinkSnapshot(page, ".only3");
      assertShellFragmentLinks(sliderCardShellHref, "key-slider fragment");

      await page.evaluate(() => window.HarmoniousClient.fakeNavigateTo("/keyboard/C_3,E_3,G_3"));
      const keyboardPage = await waitForRoute(page, "/keyboard/C_3,E_3,G_3.html", (snapshot) => snapshot.keyboardEntries > 0 && snapshot.compatImages > 0);
      if (keyboardPage.keyboardEntries <= 0) {
        throw new Error(`keyboard search pane did not populate: ${JSON.stringify(keyboardPage)}`);
      }
      const keyboardSearchShellHref = await fragmentLinkSnapshot(page, ".inside-search");
      assertShellFragmentLinks(keyboardSearchShellHref, "keyboard search fragment");

      await page.evaluate(() => window.HarmoniousClient.fakeNavigateTo("/eadgbe-frets/0,2,2,1,0,0"));
      const fretPage = await waitForRoute(page, "/eadgbe-frets/0,2,2,1,0,0.html", (snapshot) => snapshot.fretEntries > 0 && snapshot.compatImages > 0);
      if (fretPage.fretEntries <= 0) {
        throw new Error(`fret search pane did not populate: ${JSON.stringify(fretPage)}`);
      }
      const fretSearchShellHref = await fragmentLinkSnapshot(page, ".inside-frets-search");
      assertShellFragmentLinks(fretSearchShellHref, "fret search fragment");

      const beforeRandomRoute = await page.evaluate(() => window.__lmtHarmoniousSpa.lastRoute);
      await page.evaluate(() => window.HarmoniousClient.navigateRandomly());
      const randomPage = await waitForRoute(page, null, (snapshot) => snapshot.state?.lastRoute && snapshot.state.lastRoute !== beforeRandomRoute && snapshot.state.lastRoute !== "/random/");
      if (!randomPage.state?.lastRoute || randomPage.state.lastRoute === beforeRandomRoute) {
        throw new Error(`random navigation did not change route: ${JSON.stringify(randomPage)}`);
      }

      await page.goto(`${spaUrl.toString()}?route=${encodeURIComponent("/p/fb/C-Major")}`, { waitUntil: "domcontentloaded" });
      const directPage = await waitForSpaReady(page, "/p/fb/C-Major.html");
      if (!directPage.title.includes("C Major")) {
        throw new Error(`direct shell boot for /p route failed: ${JSON.stringify(directPage)}`);
      }

      await page.goto(`${spaUrl.toString()}?route=${encodeURIComponent("/keyboard/C_3,E_3,G_3")}`, { waitUntil: "domcontentloaded" });
      const directKeyboard = await waitForSpaReady(page, "/keyboard/C_3,E_3,G_3.html");
      const directKeyboardSnapshot = await waitForRoute(page, "/keyboard/C_3,E_3,G_3.html", (snapshot) => snapshot.keyboardEntries > 0 && snapshot.compatImages > 0);
      if (!directKeyboard.title.includes("Keyboard") || directKeyboardSnapshot.keyboardEntries <= 0) {
        throw new Error(`direct shell boot for keyboard route failed: ${JSON.stringify({ directKeyboard, directKeyboardSnapshot })}`);
      }
      const keyboardEditResult = await page.evaluate(() => {
        const keyTarget = document.getElementById("key-over-59")
          || document.getElementById("key-color-59")
          || document.getElementById("key-59");
        if (!keyTarget) {
          throw new Error("missing keyboard target element for midi note 59");
        }
        window.KeyboardClient.onRectClick({ target: keyTarget });
        const expectedKeyboardRouteAfterEdit = window.HarmoniousClient.PCS.makeNoteUrlStringFromMidinotes(
          "/keyboard/",
          window.KeyboardClient.preferAccid,
          window.KeyboardClient.midinotes,
        );
        const keyboardUrlAfterEdit = `${window.location.pathname}${window.location.search}`;
        return {
          expectedKeyboardRouteAfterEdit,
          keyboardRouteAfterEdit: window.__lmtCurrentPageUrlPath,
          keyboardUrlAfterEdit,
          keyboardMidinotesAfterEdit: [...window.KeyboardClient.midinotes],
          keyboardSearchEntriesAfterEdit: document.querySelectorAll(".inside-search .entry").length,
        };
      });
      const expectedKeyboardShellHref = shellHrefForRoute(keyboardEditResult.expectedKeyboardRouteAfterEdit);
      if (keyboardEditResult.keyboardUrlAfterEdit !== expectedKeyboardShellHref) {
        throw new Error(`keyboard live edit escaped shell-form URL: ${JSON.stringify(keyboardEditResult)}`);
      }
      await waitForPageValue(
        page,
        () => page.evaluate(({ expectedKeyboardRouteAfterEdit, expectedKeyboardShellHref }) => ({
          ok: window.__lmtCurrentPageUrlPath === expectedKeyboardRouteAfterEdit
            && `${window.location.pathname}${window.location.search}` === expectedKeyboardShellHref
            && document.querySelectorAll(".inside-search .entry").length > 0,
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          searchEntries: document.querySelectorAll(".inside-search .entry").length,
          midinotes: window.KeyboardClient ? [...window.KeyboardClient.midinotes] : [],
        }), { expectedKeyboardRouteAfterEdit: keyboardEditResult.expectedKeyboardRouteAfterEdit, expectedKeyboardShellHref }),
        "keyboard live-edit shell-form URL",
      );
      await page.evaluate(() => history.back());
      await waitForPageValue(
        page,
        () => page.evaluate(() => ({
          ok: window.__lmtCurrentPageUrlPath === "/keyboard/C_3,E_3,G_3"
            && `${window.location.pathname}${window.location.search}` === "/index.html?route=%2Fkeyboard%2FC_3%2CE_3%2CG_3"
            && JSON.stringify(window.KeyboardClient ? [...window.KeyboardClient.midinotes] : []) === JSON.stringify([48, 52, 55]),
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          midinotes: window.KeyboardClient ? [...window.KeyboardClient.midinotes] : [],
        })),
        "keyboard back navigation shell-form restore",
      );
      await page.evaluate(() => history.forward());
      await waitForPageValue(
        page,
        () => page.evaluate(({ expectedKeyboardRouteAfterEdit, expectedKeyboardShellHref, expectedMidinotes }) => ({
          ok: window.__lmtCurrentPageUrlPath === expectedKeyboardRouteAfterEdit
            && `${window.location.pathname}${window.location.search}` === expectedKeyboardShellHref
            && JSON.stringify(window.KeyboardClient ? [...window.KeyboardClient.midinotes] : []) === JSON.stringify(expectedMidinotes),
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          midinotes: window.KeyboardClient ? [...window.KeyboardClient.midinotes] : [],
        }), {
          expectedKeyboardRouteAfterEdit: keyboardEditResult.expectedKeyboardRouteAfterEdit,
          expectedKeyboardShellHref,
          expectedMidinotes: keyboardEditResult.keyboardMidinotesAfterEdit,
        }),
        "keyboard forward navigation shell-form restore",
      );

      await page.goto(`${spaUrl.toString()}?route=${encodeURIComponent("/eadgbe-frets/-1,12,12,9,10,-1")}`, { waitUntil: "domcontentloaded" });
      const directFret = await waitForSpaReady(page, "/eadgbe-frets/-1,12,12,9,10,-1.html");
      const directFretSnapshot = await waitForRoute(page, "/eadgbe-frets/-1,12,12,9,10,-1.html", (snapshot) => snapshot.fretEntries > 0 && snapshot.compatImages > 0);
      if (!directFret.title.includes("Interactive Guitar Fretboard") || directFretSnapshot.fretEntries <= 0) {
        throw new Error(`direct shell boot for fret route failed: ${JSON.stringify({ directFret, directFretSnapshot })}`);
      }
      const fretEditResult = await page.evaluate(() => {
        const fretTarget = document.getElementById("fret-rect-0-0")
          || document.getElementById("fret-rect-0-1");
        if (!fretTarget) {
          throw new Error("missing fret target element for interactive mutation");
        }
        window.FretsClient.onRectClick({ target: fretTarget });
        const expectedFretRouteAfterEdit = window.HarmoniousClient.PCS.makeFretsUrlStringFromFretsArray(
          "/eadgbe-frets/",
          window.FretsClient.fretsArray,
          "TODO-multi-and-capo-settings",
        );
        const fretUrlAfterEdit = `${window.location.pathname}${window.location.search}`;
        return {
          expectedFretRouteAfterEdit,
          fretRouteAfterEdit: window.__lmtCurrentPageUrlPath,
          fretUrlAfterEdit,
          fretArrayAfterEdit: JSON.parse(JSON.stringify(window.FretsClient.fretsArray)),
          fretSearchEntriesAfterEdit: document.querySelectorAll(".inside-frets-search .entry").length,
        };
      });
      const expectedFretShellHref = shellHrefForRoute(fretEditResult.expectedFretRouteAfterEdit);
      if (fretEditResult.fretUrlAfterEdit !== expectedFretShellHref) {
        throw new Error(`fret live edit escaped shell-form URL: ${JSON.stringify(fretEditResult)}`);
      }
      await waitForPageValue(
        page,
        () => page.evaluate(({ expectedFretRouteAfterEdit, expectedFretShellHref }) => ({
          ok: window.__lmtCurrentPageUrlPath === expectedFretRouteAfterEdit
            && `${window.location.pathname}${window.location.search}` === expectedFretShellHref
            && document.querySelectorAll(".inside-frets-search .entry").length > 0,
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          frets: window.FretsClient ? JSON.parse(JSON.stringify(window.FretsClient.fretsArray)) : [],
          searchEntries: document.querySelectorAll(".inside-frets-search .entry").length,
        }), { expectedFretRouteAfterEdit: fretEditResult.expectedFretRouteAfterEdit, expectedFretShellHref }),
        "fret live-edit shell-form URL",
      );
      await page.evaluate(() => history.back());
      await waitForPageValue(
        page,
        () => page.evaluate(() => ({
          ok: window.__lmtCurrentPageUrlPath === "/eadgbe-frets/-1,12,12,9,10,-1"
            && `${window.location.pathname}${window.location.search}` === "/index.html?route=%2Feadgbe-frets%2F-1%2C12%2C12%2C9%2C10%2C-1"
            && JSON.stringify(window.FretsClient ? JSON.parse(JSON.stringify(window.FretsClient.fretsArray)) : []) === JSON.stringify([[], [12], [12], [9], [10], []]),
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          frets: window.FretsClient ? JSON.parse(JSON.stringify(window.FretsClient.fretsArray)) : [],
        })),
        "fret back navigation shell-form restore",
      );
      await page.evaluate(() => history.forward());
      await waitForPageValue(
        page,
        () => page.evaluate(({ expectedFretRouteAfterEdit, expectedFretShellHref, expectedFretArrayAfterEdit }) => ({
          ok: window.__lmtCurrentPageUrlPath === expectedFretRouteAfterEdit
            && `${window.location.pathname}${window.location.search}` === expectedFretShellHref
            && JSON.stringify(window.FretsClient ? JSON.parse(JSON.stringify(window.FretsClient.fretsArray)) : []) === JSON.stringify(expectedFretArrayAfterEdit),
          route: window.__lmtCurrentPageUrlPath,
          href: `${window.location.pathname}${window.location.search}`,
          frets: window.FretsClient ? JSON.parse(JSON.stringify(window.FretsClient.fretsArray)) : [],
        }), {
          expectedFretRouteAfterEdit: fretEditResult.expectedFretRouteAfterEdit,
          expectedFretShellHref,
          expectedFretArrayAfterEdit: fretEditResult.fretArrayAfterEdit,
        }),
        "fret forward navigation shell-form restore",
      );

      await page.goto(`${spaUrl.toString()}?route=${encodeURIComponent("/p/7c/E-Major")}`, { waitUntil: "domcontentloaded" });
      const directKey = await waitForSpaReady(page, "/p/7c/E-Major.html");
      const directKeySnapshot = await waitForRoute(
        page,
        "/p/7c/E-Major.html",
        (snapshot) => snapshot.sliderEntries > 0 && snapshot.sliderImageCount > 0 && snapshot.currentKeyText.includes("Key of E"),
      );
      if (
        !directKey.title.includes("E Major")
        || directKeySnapshot.sliderEntries <= 0
        || directKeySnapshot.sliderImageCount <= 0
        || !directKeySnapshot.currentKeyText.includes("Key of E")
      ) {
        throw new Error(`direct shell boot for key route failed: ${JSON.stringify({ directKey, directKeySnapshot })}`);
      }

      for (const [rawRoute, expectedRoute, extraCheck] of [
        ["/p/fb/C-Major", "/p/fb/C-Major.html", (snapshot) => snapshot.title.includes("C Major")],
        ["/keyboard/C_3,E_3,G_3", "/keyboard/C_3,E_3,G_3.html", (snapshot) => snapshot.keyboardEntries > 0],
        ["/eadgbe-frets/-1,12,12,9,10,-1", "/eadgbe-frets/-1,12,12,9,10,-1.html", (snapshot) => snapshot.fretEntries > 0],
      ]) {
        const rawResponsePromise = page.waitForResponse((response) => {
          const url = new URL(response.url());
          return url.origin === baseUrl && url.pathname === rawRoute;
        });
        await page.goto(`${baseUrl}${rawRoute}`, { waitUntil: "domcontentloaded" });
        const rawResponse = await rawResponsePromise;
        if (rawResponse.status() !== 404 || rawResponse.headers()["x-lmt-spa-fallback"] !== "1") {
          throw new Error(`raw route did not traverse SPA fallback: route=${rawRoute} status=${rawResponse.status()} headers=${JSON.stringify(rawResponse.headers())}`);
        }
        const shellUrl = new URL(shellHrefForRoute(rawRoute), baseUrl).toString();
        const fallbackSnapshot = await waitForRoute(
          page,
          expectedRoute,
          (snapshot) => snapshot.pathnameSearch === shellHrefForRoute(rawRoute)
            && snapshot.canonicalHref === shellUrl
            && extraCheck(snapshot),
        );
        if (fallbackSnapshot.pathnameSearch !== shellHrefForRoute(rawRoute) || fallbackSnapshot.canonicalHref !== shellUrl) {
          throw new Error(`fallback shell metadata mismatch for ${rawRoute}: ${JSON.stringify(fallbackSnapshot)}`);
        }
      }

      if (compatRequests.length > 0) {
        throw new Error(`compat svg files were fetched over the network instead of wasm generation: ${compatRequests.slice(0, 20).join(", ")}`);
      }
      if (keyTriRequests.length > 0) {
        throw new Error(`key slider background images were fetched over the network instead of local reconstruction: ${keyTriRequests.slice(0, 20).join(", ")}`);
      }
      if (faviconRequests.length > 0) {
        throw new Error(`favicon.ico was fetched over the network instead of using the built-in icon: ${faviconRequests.slice(0, 20).join(", ")}`);
      }

      const finalState = await page.evaluate(() => window.__lmtHarmoniousSpa);
      if (!finalState?.ready || finalState.compatReplacements <= 0) {
        throw new Error(`unexpected final spa state: ${JSON.stringify(finalState)}`);
      }

      console.log(
        `harmonious SPA passed: lastRoute=${finalState.lastRoute} routeLoads=${finalState.routeLoads} compatReplacements=${finalState.compatReplacements} indexedRefs=${finalState.indexedCompatRefs}`,
      );
    } finally {
      await browser.close();
    }
  } finally {
    await cleanupServer();
    await delay(150);
  }
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
