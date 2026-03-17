#!/usr/bin/env node

import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn, spawnSync } from "node:child_process";

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

function startServer(port) {
  const args = ["-m", "http.server", String(port), "--bind", host, "--directory", spaDir];
  const child = spawn("python3", args, {
    cwd: spaDir,
    stdio: ["ignore", "pipe", "pipe"],
  });
  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });
  return { child, stderrRef: () => stderr };
}

async function waitForSpaReady(page, expectedRoute = "/index.html") {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      state: window.__lmtHarmoniousSpa || null,
      title: document.title,
      home: !!document.querySelector(".main-home"),
      loadingText: document.getElementById("spa-shell-loading")?.textContent || "",
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

async function main() {
  const indexPath = path.join(spaDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing SPA page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startServer(port);
  const baseUrl = `http://${host}:${port}`;
  const spaUrl = new URL(`${baseUrl}/index.html`);
  const compatRequests = [];
  const keyTriRequests = [];

  const cleanupServer = () => {
    if (!server.killed) server.kill("SIGTERM");
  };
  process.on("exit", cleanupServer);
  process.on("SIGINT", () => {
    cleanupServer();
    process.exit(130);
  });
  process.on("SIGTERM", () => {
    cleanupServer();
    process.exit(143);
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
        if (compatRequestPattern.test(new URL(url).pathname)) {
          compatRequests.push(url);
        }
        if (keyTriRequestPattern.test(new URL(url).pathname)) {
          keyTriRequests.push(url);
        }
      });

      await page.goto(spaUrl.toString(), { waitUntil: "domcontentloaded" });
      const ready = await waitForSpaReady(page, "/index.html");
      if (!ready.home) {
        throw new Error(`home page did not render through SPA shell: ${JSON.stringify(ready)}`);
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

      await page.evaluate(() => window.HarmoniousClient.fakeNavigateTo("/keyboard/C_3,E_3,G_3"));
      const keyboardPage = await waitForRoute(page, "/keyboard/C_3,E_3,G_3.html", (snapshot) => snapshot.keyboardEntries > 0 && snapshot.compatImages > 0);
      if (keyboardPage.keyboardEntries <= 0) {
        throw new Error(`keyboard search pane did not populate: ${JSON.stringify(keyboardPage)}`);
      }

      await page.evaluate(() => window.HarmoniousClient.fakeNavigateTo("/eadgbe-frets/0,2,2,1,0,0"));
      const fretPage = await waitForRoute(page, "/eadgbe-frets/0,2,2,1,0,0.html", (snapshot) => snapshot.fretEntries > 0 && snapshot.compatImages > 0);
      if (fretPage.fretEntries <= 0) {
        throw new Error(`fret search pane did not populate: ${JSON.stringify(fretPage)}`);
      }

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

      await page.goto(`${spaUrl.toString()}?route=${encodeURIComponent("/eadgbe-frets/-1,12,12,9,10,-1")}`, { waitUntil: "domcontentloaded" });
      const directFret = await waitForSpaReady(page, "/eadgbe-frets/-1,12,12,9,10,-1.html");
      const directFretSnapshot = await waitForRoute(page, "/eadgbe-frets/-1,12,12,9,10,-1.html", (snapshot) => snapshot.fretEntries > 0 && snapshot.compatImages > 0);
      if (!directFret.title.includes("Interactive Guitar Fretboard") || directFretSnapshot.fretEntries <= 0) {
        throw new Error(`direct shell boot for fret route failed: ${JSON.stringify({ directFret, directFretSnapshot })}`);
      }

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

      if (compatRequests.length > 0) {
        throw new Error(`compat svg files were fetched over the network instead of wasm generation: ${compatRequests.slice(0, 20).join(", ")}`);
      }
      if (keyTriRequests.length > 0) {
        throw new Error(`key slider background images were fetched over the network instead of local reconstruction: ${keyTriRequests.slice(0, 20).join(", ")}`);
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
    cleanupServer();
    await delay(150);
    const stderr = stderrRef().trim();
    if (stderr.includes("Address already in use")) {
      throw new Error(`failed to start local SPA server: ${stderr}`);
    }
  }
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
