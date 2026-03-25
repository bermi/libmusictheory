#!/usr/bin/env node

import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { once } from "node:events";
import { fileURLToPath } from "node:url";
import { spawn, spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const docsDir = path.join(rootDir, "zig-out", "wasm-docs");
const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
const maxDrift = Number.parseFloat(process.env.LMT_WASM_DOCS_BITMAP_MAX_DRIFT || "0.005");
const minInkPixels = Number.parseInt(process.env.LMT_WASM_DOCS_BITMAP_MIN_INK || "1000", 10);
const expectedBitmapSizes = {
  lmt_svg_clock_optc: { width: 840, height: 840 },
  lmt_svg_optic_k_group: { width: 840, height: 420 },
  lmt_svg_evenness_chart: { width: 840, height: 1092 },
  lmt_svg_evenness_field: { width: 840, height: 1092 },
  lmt_svg_fret: { width: 840, height: 840 },
  lmt_svg_fret_n: { width: 840, height: 840 },
  lmt_svg_chord_staff: { width: 840, height: 504 },
  lmt_svg_key_staff: { width: 840, height: 204 },
  lmt_svg_piano_staff: { width: 840, height: 869 },
  lmt_svg_keyboard: { width: 840, height: 220 },
};
const keyboardSeamSample = {
  notes: [61, 63, 64, 66, 68, 69, 71, 73],
  low: 48,
  high: 84,
  marginX: 16,
  marginY: 16,
  whiteKeyWidth: 24,
  whiteKeyHeight: 124,
  blackKeyWidth: 14,
  blackKeyHeight: 76,
  maxBlackEchoNeutralSeamLightness: 110,
};

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
  return modulePath;
}

async function launchChromium() {
  const modulePath = ensurePlaywrightModule();
  const playwright = await import(pathToFileUrl(modulePath));
  const executablePath = [
    process.env.LMT_PLAYWRIGHT_BROWSER_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium-browser",
    "/usr/bin/chromium",
  ].find((one) => one && fs.existsSync(one));
  return playwright.chromium.launch({
    headless: true,
    executablePath: executablePath || undefined,
  });
}

function pathToFileUrl(filePath) {
  const resolved = path.resolve(filePath).replace(/\\/g, "/");
  return `file://${resolved}`;
}

function resolvePort() {
  return new Promise((resolve, reject) => {
    const probe = net.createServer();
    probe.unref();
    probe.once("error", reject);
    probe.listen(0, host, () => {
      const address = probe.address();
      if (!address || typeof address === "string") {
        probe.close(() => reject(new Error("failed to resolve port")));
        return;
      }
      const port = address.port;
      probe.close((error) => {
        if (error) reject(error);
        else resolve(port);
      });
    });
  });
}

async function waitForServer(url, timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const response = await fetch(url, { method: "GET" });
      if (response.ok) return;
    } catch (_error) {
      // keep polling
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

function startServer(port) {
  const child = spawn("python3", ["-m", "http.server", String(port), "--bind", host, "--directory", docsDir], {
    cwd: docsDir,
    stdio: ["ignore", "ignore", "ignore"],
  });
  child.unref();
  return { child, stderrRef: () => "" };
}

async function stopServer(child) {
  if (!child || child.exitCode !== null || child.killed) return;
  child.kill("SIGTERM");
  await Promise.race([
    once(child, "exit").catch(() => {}),
    delay(500),
  ]);
}

async function main() {
  if (!fs.existsSync(path.join(docsDir, "qa-atlas.html"))) {
    throw new Error(`missing qa atlas page in ${docsDir}; run 'zig build wasm-docs' first`);
  }

  const port = await resolvePort();
  const { child: server, stderrRef } = startServer(port);
  const cleanupServer = () => stopServer(server);

  process.on("exit", cleanupServer);
  process.on("SIGINT", () => {
    void cleanupServer();
    process.exit(130);
  });
  process.on("SIGTERM", () => {
    void cleanupServer();
    process.exit(143);
  });

  try {
    const url = `http://${host}:${port}/qa-atlas.html`;
    await waitForServer(url);
    const browser = await launchChromium();
    try {
      const page = await browser.newPage({ viewport: { width: 1920, height: 1200 }, deviceScaleFactor: 2 });
      await page.goto(url, { waitUntil: "domcontentloaded" });
      await page.waitForFunction(() => window.__lmtQaAtlasSummary?.ready === true, null, { timeout: 300000 });
      await delay(250);

      const summary = await page.evaluate(() => window.__lmtQaAtlasSummary);
      if (!summary) throw new Error("qa atlas summary missing");
      if (!summary.rasterEnabled) throw new Error("qa atlas raster backend disabled");
      if ((summary.methods || []).length !== 10) throw new Error(`qa atlas method count mismatch: ${(summary.methods || []).length}`);

      const failures = [];
      for (const method of summary.methods || []) {
        const expectedSize = expectedBitmapSizes[method.method];
        if (expectedSize && (method.bitmapWidth !== expectedSize.width || method.bitmapHeight !== expectedSize.height)) {
          failures.push(`${method.label}:${method.method}:size=${method.bitmapWidth}x${method.bitmapHeight}`);
        }
        if (method.method === "lmt_svg_fret" && method.referenceHasBarre !== true) {
          failures.push(`${method.label}:${method.method}:missing-barre-sample`);
        }
        if ((method.candidateInkPixels || 0) < minInkPixels) {
          failures.push(`${method.label}:${method.method}:ink=${method.candidateInkPixels}`);
        }
        if (!Number.isFinite(method.drift) || method.drift > maxDrift) {
          failures.push(`${method.label}:${method.method}:drift=${method.drift}`);
        }
      }

      if (failures.length > 0) {
        throw new Error(`qa atlas bitmap diff failures: ${failures.join(", ")}`);
      }

      const keyboardSeamCheck = await page.evaluate((sample) => {
        const isBlackKey = (midi) => [1, 3, 6, 8, 10].includes(midi % 12);
        const whiteIndexBefore = (rangeLow, midiNote) => {
          let total = 0;
          for (let midi = rangeLow; midi < midiNote; midi += 1) {
            if (!isBlackKey(midi)) total += 1;
          }
          return total;
        };
        const countWhiteKeys = (rangeLow, rangeHigh) => {
          let total = 0;
          for (let midi = rangeLow; midi <= rangeHigh; midi += 1) {
            if (!isBlackKey(midi)) total += 1;
          }
          return total;
        };

        const card = document.querySelector('[data-method="lmt_svg_keyboard"]');
        const image = card?.querySelector("img");
        if (!(image instanceof HTMLImageElement) || !image.complete || image.naturalWidth <= 0 || image.naturalHeight <= 0) {
          return { ok: false, reason: "keyboard bitmap row missing image" };
        }

        const selectedPcs = new Set(sample.notes.map((note) => note % 12));
        const sourceWidth = sample.marginX * 2 + countWhiteKeys(sample.low, sample.high) * sample.whiteKeyWidth;
        const sourceHeight = sample.marginY * 2 + sample.whiteKeyHeight;
        const scaleX = image.naturalWidth / sourceWidth;
        const scaleY = image.naturalHeight / sourceHeight;

        const canvas = document.createElement("canvas");
        canvas.width = image.naturalWidth;
        canvas.height = image.naturalHeight;
        const ctx = canvas.getContext("2d", { willReadFrequently: true });
        if (!ctx) return { ok: false, reason: "missing 2d context" };
        ctx.drawImage(image, 0, 0);

        const samples = [];
        for (let midi = sample.low; midi <= sample.high; midi += 1) {
          if (!isBlackKey(midi) || !selectedPcs.has(midi % 12)) continue;
          const keyX = sample.marginX + whiteIndexBefore(sample.low, midi) * sample.whiteKeyWidth - sample.blackKeyWidth / 2;
          const sampleX = Math.max(1, Math.min(canvas.width - 2, Math.round((keyX + sample.blackKeyWidth / 2) * scaleX)));
          const sampleYs = [
            sample.marginY + sample.blackKeyHeight * 0.42,
            sample.marginY + sample.blackKeyHeight * 0.52,
            sample.marginY + sample.blackKeyHeight * 0.62,
          ].map((value) => Math.max(0, Math.min(canvas.height - 1, Math.round(value * scaleY))));
          const seamLightness = sampleYs.map((sampleY) => {
            const center = ctx.getImageData(sampleX, sampleY, 1, 1).data;
            const centerLightness = (center[0] + center[1] + center[2]) / 3;
            const chroma = Math.max(center[0], center[1], center[2]) - Math.min(center[0], center[1], center[2]);
            return chroma < 24 ? centerLightness : 0;
          });
          samples.push({
            midi,
            maxNeutralSeamLightness: Math.max(...seamLightness),
          });
        }

        if (samples.length === 0) return { ok: false, reason: "no black-key seam probes generated" };
        const maxBlackEchoNeutralSeamLightness = Math.max(...samples.map((one) => one.maxNeutralSeamLightness));
        return {
          ok: maxBlackEchoNeutralSeamLightness < sample.maxBlackEchoNeutralSeamLightness,
          maxBlackEchoNeutralSeamLightness,
          samples,
        };
      }, keyboardSeamSample);
      if (!keyboardSeamCheck?.ok) {
        throw new Error(`qa atlas keyboard seam check failed: ${JSON.stringify(keyboardSeamCheck)}`);
      }

      console.log(JSON.stringify({ maxDrift, minInkPixels, keyboardSeamCheck, summary }, null, 2));
    } finally {
      await browser.close();
    }
  } catch (error) {
    const stderr = stderrRef();
    if (stderr.trim().length > 0) console.error(stderr.trim());
    throw error;
  } finally {
    await cleanupServer();
    await delay(150);
  }
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
