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
const galleryDir = path.join(rootDir, "zig-out", "wasm-gallery");
const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
const timeoutMs = Number.parseInt(process.env.LMT_WASM_GALLERY_TIMEOUT_MS || "300000", 10);
const requestedPort = parsePort(process.env.LMT_VALIDATION_PORT || "");

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
      const port = address.port;
      probe.close((err) => (err ? reject(err) : resolve(port)));
    });
  });
}

async function waitForServer(url, deadlineMs) {
  const start = Date.now();
  while (Date.now() - start < deadlineMs) {
    try {
      const res = await fetch(url, { method: "GET" });
      if (res.ok) return;
    } catch (_error) {
      // Keep polling.
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

function startServer(port) {
  const args = ["-m", "http.server", String(port), "--bind", host, "--directory", galleryDir];
  const child = spawn("python3", args, {
    cwd: galleryDir,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  return { child, stderrRef: () => stderr };
}

async function waitForGalleryReady(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      status: document.getElementById("status")?.textContent || "",
      summary: window.__lmtGallerySummary || null,
      clockSvg: document.querySelector("#set-clock svg")?.outerHTML || "",
      keySvg: document.querySelector("#key-clock svg")?.outerHTML || "",
      chordSvg: document.querySelector("#chord-clock svg")?.outerHTML || "",
      staffSvg: document.querySelector("#chord-staff svg")?.outerHTML || "",
      progressionSvg: document.querySelector("#progression-clock svg")?.outerHTML || "",
      compareLeftSvg: document.querySelector("#compare-left-clock svg")?.outerHTML || "",
      compareOverlapSvg: document.querySelector("#compare-overlap-clock svg")?.outerHTML || "",
      compareRightSvg: document.querySelector("#compare-right-clock svg")?.outerHTML || "",
      fretSvg: document.querySelector("#fret-svg svg")?.outerHTML || "",
      degreeCards: document.querySelectorAll("#key-degrees .degree-card").length,
      noteChips: document.querySelectorAll("#key-notes .chip").length,
      voicingPills: document.querySelectorAll("#fret-voicings .pill").length,
      progressionCards: document.querySelectorAll("#progression-cards .progression-card").length,
      compareChips: document.querySelectorAll("#compare-chips .chip, #compare-chips .pill").length,
      toggleCount: document.querySelectorAll("#pcs-toggle-grid .pc-toggle").length,
      sceneCardCount: document.querySelectorAll(".scene-card").length,
      presetSelectCount: document.querySelectorAll("select[id$='-preset']").length,
    }));

    if (snapshot.status.includes("Failed to initialize gallery")) {
      throw new Error(snapshot.status);
    }

    const summary = snapshot.summary;
    const ready =
      summary?.ready === true &&
      summary?.manifestLoaded === true &&
      summary?.sceneCount >= 6 &&
      Array.isArray(summary?.errors) &&
      summary.errors.length === 0 &&
      summary.scenes?.set?.rendered &&
      summary.scenes?.key?.rendered &&
      summary.scenes?.chord?.rendered &&
      summary.scenes?.progression?.rendered &&
      summary.scenes?.compare?.rendered &&
      summary.scenes?.fret?.rendered &&
      snapshot.clockSvg.includes("<svg") &&
      snapshot.keySvg.includes("<svg") &&
      snapshot.chordSvg.includes("<svg") &&
      snapshot.staffSvg.includes("<svg") &&
      snapshot.progressionSvg.includes("<svg") &&
      snapshot.compareLeftSvg.includes("<svg") &&
      snapshot.compareOverlapSvg.includes("<svg") &&
      snapshot.compareRightSvg.includes("<svg") &&
      snapshot.fretSvg.includes("<svg") &&
      snapshot.degreeCards >= 7 &&
      snapshot.noteChips >= 7 &&
      snapshot.voicingPills >= 1 &&
      snapshot.progressionCards >= 4 &&
      snapshot.compareChips >= 4 &&
      snapshot.toggleCount === 12 &&
      snapshot.sceneCardCount >= 6 &&
      snapshot.presetSelectCount >= 6;

    if (ready) return snapshot;
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for gallery readiness: ${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}

async function main() {
  const indexPath = path.join(galleryDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing gallery page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startServer(port);
  const galleryUrl = `http://${host}:${port}/index.html`;

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
    await waitForServer(galleryUrl, 15000);
    const playwrightModulePath = ensurePlaywrightModule();
    const { chromium } = await import(pathToFileURL(playwrightModulePath).href);
    const executablePath = resolveBrowserExecutable();
    const browser = await chromium.launch({
      headless: true,
      ...(executablePath ? { executablePath } : {}),
    });

    try {
      const page = await browser.newPage();
      await page.goto(galleryUrl, { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#shuffle-scenes", { timeout: 30000 });
      await waitForGalleryReady(page);

      await page.click("#shuffle-scenes");
      await waitForGalleryReady(page);

      await page.click("#render-set");
      await page.click("#render-key");
      await page.click("#render-chord");
      await page.click("#render-progression");
      await page.click("#render-compare");
      await page.click("#render-fret");
      const finalSnapshot = await waitForGalleryReady(page);

      console.log(
        JSON.stringify(
          {
            status: finalSnapshot.status,
            manifestLoaded: finalSnapshot.summary.manifestLoaded,
            sceneCount: finalSnapshot.summary.sceneCount,
            scenes: finalSnapshot.summary.scenes,
            degreeCards: finalSnapshot.degreeCards,
            progressionCards: finalSnapshot.progressionCards,
            compareChips: finalSnapshot.compareChips,
            voicingPills: finalSnapshot.voicingPills,
          },
          null,
          2,
        ),
      );
    } finally {
      await browser.close();
    }
  } catch (error) {
    const stderr = stderrRef();
    if (stderr.trim().length > 0) {
      console.error(stderr.trim());
    }
    throw error;
  } finally {
    cleanupServer();
    await delay(150);
  }
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
