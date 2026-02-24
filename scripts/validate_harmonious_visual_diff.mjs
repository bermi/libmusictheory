#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn, spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.LMT_VALIDATION_PORT || "8000", 10);
const timeoutMs = Number.parseInt(process.env.LMT_VISUAL_DIFF_TIMEOUT_MS || "1800000", 10);
const referenceRoot = process.env.LMT_HARMONIOUS_REF_ROOT || "/tmp/harmoniousapp.net";
const defaultOutDir = path.join(rootDir, "tmp", "compat-visual-diff");

function parsePositiveInt(raw, label) {
  if (raw == null || String(raw).trim() === "") return null;
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`invalid ${label}: ${raw}`);
  }
  return value;
}

function parseArgs(argv) {
  const out = {
    samplePerKind: 5,
    kinds: null,
    outDir: defaultOutDir,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--sample-per-kind") {
      const value = argv[i + 1];
      if (value == null) throw new Error("missing value for --sample-per-kind");
      out.samplePerKind = parsePositiveInt(value, "--sample-per-kind");
      i += 1;
      continue;
    }
    if (arg === "--kinds") {
      const value = argv[i + 1];
      if (value == null) throw new Error("missing value for --kinds");
      out.kinds = value
        .split(",")
        .map((name) => name.trim())
        .filter((name) => name.length > 0);
      i += 1;
      continue;
    }
    if (arg === "--out-dir") {
      const value = argv[i + 1];
      if (value == null) throw new Error("missing value for --out-dir");
      out.outDir = path.resolve(rootDir, value);
      i += 1;
      continue;
    }
    throw new Error(`unknown argument: ${arg}`);
  }

  if (out.samplePerKind < 5) {
    throw new Error("--sample-per-kind must be >= 5");
  }

  return out;
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

function startServer() {
  const args = ["-m", "http.server", String(port), "--bind", host, "--directory", rootDir];
  const child = spawn("python3", args, {
    cwd: rootDir,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  return { child, stderrRef: () => stderr };
}

function sanitize(value) {
  return String(value)
    .replaceAll("/", "_")
    .replaceAll("\\", "_")
    .replaceAll(":", "_")
    .replaceAll(" ", "_");
}

function parseTotals(progressText) {
  const totals = {
    kinds: null,
    images: null,
    generated: null,
    exactMatches: null,
    mismatches: null,
    missingRef: null,
  };

  const kindsMatch = progressText.match(/Kinds:\s*(\d+)/);
  const imagesMatch = progressText.match(/Images:\s*(\d+)/);
  const generatedMatch = progressText.match(/Generated:\s*(\d+)/);
  const compareMatch = progressText.match(/Exact matches:\s*(\d+),\s*mismatches:\s*(\d+),\s*missing ref:\s*(\d+)/);

  if (kindsMatch) totals.kinds = Number.parseInt(kindsMatch[1], 10);
  if (imagesMatch) totals.images = Number.parseInt(imagesMatch[1], 10);
  if (generatedMatch) totals.generated = Number.parseInt(generatedMatch[1], 10);
  if (compareMatch) {
    totals.exactMatches = Number.parseInt(compareMatch[1], 10);
    totals.mismatches = Number.parseInt(compareMatch[2], 10);
    totals.missingRef = Number.parseInt(compareMatch[3], 10);
  }

  return totals;
}

function decodePngDataUrl(dataUrl) {
  const prefix = "data:image/png;base64,";
  if (!dataUrl || !dataUrl.startsWith(prefix)) {
    throw new Error("invalid PNG data URL in visual diff payload");
  }
  return Buffer.from(dataUrl.slice(prefix.length), "base64");
}

async function ensureWasmReady(page) {
  const deadline = Date.now() + 5 * 60_000;
  while (true) {
    const statusText = (await page.textContent("#status")) || "";
    if (statusText.includes("WASM loaded")) return;
    if (statusText.includes("Failed to initialize")) throw new Error(statusText);
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for WASM initialization; status=${JSON.stringify(statusText)}`);
    }
    await delay(250);
  }
}

async function collectSampleManifest(page) {
  return page.evaluate(() => {
    const sections = Array.from(document.querySelectorAll(".sample-kind"));
    return sections.map((section) => {
      const header = section.querySelector("h3")?.textContent || "";
      const kind = header.split("(")[0].trim();
      const items = Array.from(section.querySelectorAll(".sample-item"));
      const samples = items.map((item, index) => {
        const meta = item.querySelector(".sample-meta")?.textContent || "";
        const imageMatch = meta.match(/image=([^|]+)/);
        const statusMatch = meta.match(/status=([^|]+)/);
        const image = imageMatch ? imageMatch[1].trim() : `sample-${index}`;
        const status = statusMatch ? statusMatch[1].trim() : "unknown";
        const hosts = item.querySelectorAll(".sample-compare .svg-host");
        const generatedSvg = hosts[0]?.innerHTML || "";
        const referenceSvg = hosts[1]?.innerHTML || "";
        const width = Math.max(1, Math.round((hosts[0]?.clientWidth || 460)));
        const height = Math.max(1, Math.round((hosts[0]?.clientHeight || 110)));
        return {
          key: `${kind}::${image}::${index}`,
          image,
          status,
          width,
          height,
          generatedSvg,
          referenceSvg,
        };
      });
      return { kind, samples };
    });
  });
}

async function computeVisualDiffs(page, entries) {
  return page.evaluate(async (input) => {
    async function rasterize(svgMarkup, width, height) {
      const blob = new Blob([svgMarkup], { type: "image/svg+xml;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      try {
        const img = new Image();
        await new Promise((resolve, reject) => {
          img.onload = resolve;
          img.onerror = () => reject(new Error("failed to rasterize SVG sample"));
          img.src = url;
        });

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(img, 0, 0, width, height);
        const image = ctx.getImageData(0, 0, width, height);
        return { data: image.data, png: canvas.toDataURL("image/png") };
      } finally {
        URL.revokeObjectURL(url);
      }
    }

    const out = [];
    for (const sample of input) {
      if (!sample.generatedSvg || !sample.referenceSvg || sample.status === "missing reference") {
        out.push({
          key: sample.key,
          skipped: true,
          reason: "missing-reference-or-empty-svg",
        });
        continue;
      }

      const generated = await rasterize(sample.generatedSvg, sample.width, sample.height);
      const reference = await rasterize(sample.referenceSvg, sample.width, sample.height);

      const diffCanvas = document.createElement("canvas");
      diffCanvas.width = sample.width;
      diffCanvas.height = sample.height;
      const diffCtx = diffCanvas.getContext("2d");
      const diffImage = diffCtx.createImageData(sample.width, sample.height);

      let mismatchedPixels = 0;
      const totalPixels = sample.width * sample.height;

      for (let i = 0; i < generated.data.length; i += 4) {
        const dr = Math.abs(generated.data[i] - reference.data[i]);
        const dg = Math.abs(generated.data[i + 1] - reference.data[i + 1]);
        const db = Math.abs(generated.data[i + 2] - reference.data[i + 2]);
        const da = Math.abs(generated.data[i + 3] - reference.data[i + 3]);

        if (dr + dg + db + da > 0) {
          mismatchedPixels += 1;
          diffImage.data[i] = 255;
          diffImage.data[i + 1] = 32;
          diffImage.data[i + 2] = 32;
          diffImage.data[i + 3] = 255;
        } else {
          const luma = Math.round((reference.data[i] + reference.data[i + 1] + reference.data[i + 2]) / 3);
          diffImage.data[i] = luma;
          diffImage.data[i + 1] = luma;
          diffImage.data[i + 2] = luma;
          diffImage.data[i + 3] = 80;
        }
      }

      diffCtx.putImageData(diffImage, 0, 0);
      out.push({
        key: sample.key,
        skipped: false,
        mismatchedPixels,
        totalPixels,
        mismatchRatio: totalPixels > 0 ? mismatchedPixels / totalPixels : 0,
        generatedPng: generated.png,
        referencePng: reference.png,
        diffPng: diffCanvas.toDataURL("image/png"),
      });
    }

    return out;
  }, entries);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const validationPath = path.join(rootDir, "zig-out", "wasm-demo", "validation.html");
  const referenceDir = path.join(rootDir, "tmp", "harmoniousapp.net");

  if (!fs.existsSync(validationPath)) {
    throw new Error(`missing validation page: ${validationPath}`);
  }
  if (!fs.existsSync(referenceDir)) {
    console.log(`skip: reference directory not found: ${referenceDir}`);
    return;
  }

  fs.rmSync(args.outDir, { recursive: true, force: true });
  fs.mkdirSync(args.outDir, { recursive: true });

  const playwrightPath = ensurePlaywrightModule();
  const { chromium } = await import(pathToFileURL(playwrightPath).href);

  const { child: server, stderrRef } = startServer();
  const baseUrl = `http://${host}:${port}`;
  const validationUrl = new URL(`${baseUrl}/zig-out/wasm-demo/validation.html`);
  validationUrl.searchParams.set("sample_per_kind", String(args.samplePerKind));
  if (Array.isArray(args.kinds) && args.kinds.length > 0) {
    validationUrl.searchParams.set("kinds", args.kinds.join(","));
  }

  const cleanupServer = () => {
    if (!server.killed) server.kill("SIGTERM");
  };
  process.on("exit", cleanupServer);

  const summary = {
    run: {
      url: validationUrl.toString(),
      samplePerKind: args.samplePerKind,
      kinds: args.kinds,
      outDir: args.outDir,
      referenceRoot,
    },
    totals: null,
    perKind: [],
    artifacts: [],
    generatedAt: new Date().toISOString(),
  };

  try {
    await waitForServer(validationUrl.toString(), 15_000);

    const executablePath = resolveBrowserExecutable();
    const browser = await chromium.launch({
      headless: true,
      ...(executablePath ? { executablePath } : {}),
    });

    try {
      const page = await browser.newPage({ viewport: { width: 1600, height: 1200 } });
      await page.addInitScript(() => {
        let seed = 123456789;
        Math.random = function seededRandom() {
          seed = (1664525 * seed + 1013904223) >>> 0;
          return seed / 0x100000000;
        };
      });

      await page.goto(validationUrl.toString(), { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#run-validation", { timeout: 30_000 });
      await ensureWasmReady(page);

      await page.fill("#ref-root", referenceRoot);
      await page.selectOption("#compare-enabled", "1");
      await page.selectOption("#visual-sample-enabled", "1");
      await page.fill("#visual-sample-size", String(args.samplePerKind));
      await page.click("#run-validation");

      const deadline = Date.now() + timeoutMs;
      while (true) {
        const snapshot = await page.evaluate(() => ({
          status: document.getElementById("status")?.textContent || "",
          progress: document.getElementById("progress")?.textContent || "",
        }));

        if (snapshot.status.includes("Validation failed:")) throw new Error(snapshot.status);
        if (snapshot.progress.includes("Kinds:")) break;
        if (Date.now() > deadline) {
          throw new Error(`timed out waiting for validation completion; last progress=${JSON.stringify(snapshot.progress)}`);
        }
        await delay(1000);
      }

      const progressText = (await page.textContent("#progress")) || "";
      summary.totals = parseTotals(progressText);

      const manifest = await collectSampleManifest(page);
      const flatEntries = [];
      for (const kindEntry of manifest) {
        for (const sample of kindEntry.samples) {
          flatEntries.push({ ...sample, kind: kindEntry.kind });
        }
      }

      const diffResults = await computeVisualDiffs(page, flatEntries);
      const diffByKey = new Map(diffResults.map((row) => [row.key, row]));

      for (const kindEntry of manifest) {
        const kindSlug = sanitize(kindEntry.kind || "unknown-kind");
        const kindDir = path.join(args.outDir, kindSlug);
        fs.mkdirSync(kindDir, { recursive: true });

        let compared = 0;
        let ratioSum = 0;
        let worst = 0;

        for (let i = 0; i < kindEntry.samples.length; i += 1) {
          const sample = kindEntry.samples[i];
          const sampleSlug = `${String(i + 1).padStart(2, "0")}-${sanitize(sample.image)}`;
          const diff = diffByKey.get(sample.key);
          if (!diff || diff.skipped) continue;

          const generatedPath = path.join(kindDir, `${sampleSlug}.generated.png`);
          const referencePath = path.join(kindDir, `${sampleSlug}.reference.png`);
          const diffPath = path.join(kindDir, `${sampleSlug}.diff.png`);
          const metaPath = path.join(kindDir, `${sampleSlug}.json`);

          fs.writeFileSync(generatedPath, decodePngDataUrl(diff.generatedPng));
          fs.writeFileSync(referencePath, decodePngDataUrl(diff.referencePng));
          fs.writeFileSync(diffPath, decodePngDataUrl(diff.diffPng));

          const meta = {
            kind: kindEntry.kind,
            image: sample.image,
            status: sample.status,
            size: { width: sample.width, height: sample.height },
            mismatchedPixels: diff.mismatchedPixels,
            totalPixels: diff.totalPixels,
            mismatchRatio: diff.mismatchRatio,
            files: {
              generated: path.relative(args.outDir, generatedPath),
              reference: path.relative(args.outDir, referencePath),
              diff: path.relative(args.outDir, diffPath),
            },
          };

          fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2));
          summary.artifacts.push(meta);

          compared += 1;
          ratioSum += diff.mismatchRatio;
          worst = Math.max(worst, diff.mismatchRatio);
        }

        summary.perKind.push({
          kind: kindEntry.kind,
          samples: kindEntry.samples.length,
          compared,
          averageMismatchRatio: compared > 0 ? ratioSum / compared : 0,
          worstMismatchRatio: worst,
        });
      }
    } finally {
      await browser.close();
    }
  } finally {
    cleanupServer();
    await delay(150);
    const stderr = stderrRef().trim();
    if (stderr.includes("Address already in use")) {
      throw new Error(`failed to start local server on ${host}:${port}: ${stderr}`);
    }
  }

  const summaryPath = path.join(args.outDir, "summary.json");
  fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));

  const reportLines = [];
  reportLines.push("Harmonious Visual Diff Diagnostics");
  reportLines.push(`out_dir: ${args.outDir}`);
  reportLines.push(`kinds: ${summary.totals?.kinds}`);
  reportLines.push(`images: ${summary.totals?.images}`);
  reportLines.push(`exact_matches: ${summary.totals?.exactMatches}`);
  reportLines.push(`mismatches: ${summary.totals?.mismatches}`);
  reportLines.push(`missing_ref: ${summary.totals?.missingRef}`);
  reportLines.push("");
  reportLines.push("Per-kind sampled visual diff:");

  for (const row of summary.perKind.sort((a, b) => b.worstMismatchRatio - a.worstMismatchRatio)) {
    reportLines.push(
      `- ${row.kind}: compared=${row.compared}, avg=${row.averageMismatchRatio.toFixed(6)}, worst=${row.worstMismatchRatio.toFixed(6)}`,
    );
  }

  const reportPath = path.join(args.outDir, "report.txt");
  fs.writeFileSync(reportPath, `${reportLines.join("\n")}\n`);

  console.log(`visual diff diagnostics written: ${summaryPath}`);
  console.log(`visual diff report written: ${reportPath}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
