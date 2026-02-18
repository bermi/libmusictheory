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
const timeoutMs = Number.parseInt(process.env.LMT_VALIDATION_TIMEOUT_MS || "1800000", 10);
const referenceRoot = process.env.LMT_HARMONIOUS_REF_ROOT || "/tmp/harmoniousapp.net";
const samplePerKindFromEnv = process.env.LMT_VALIDATION_SAMPLE_PER_KIND || "";
const kindsFromEnv = process.env.LMT_VALIDATION_KINDS || "";

const validationPath = path.join(rootDir, "zig-out", "wasm-demo", "validation.html");
const referenceDir = path.join(rootDir, "tmp", "harmoniousapp.net");

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
    samplePerKind: parsePositiveInt(samplePerKindFromEnv, "LMT_VALIDATION_SAMPLE_PER_KIND"),
    kinds: null,
  };

  if (String(kindsFromEnv).trim() !== "") {
    out.kinds = kindsFromEnv
      .split(",")
      .map((name) => name.trim())
      .filter((name) => name.length > 0);
  }

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--sample-per-kind") {
      const value = argv[index + 1];
      if (value == null) {
        throw new Error("missing value for --sample-per-kind");
      }
      out.samplePerKind = parsePositiveInt(value, "--sample-per-kind");
      index += 1;
      continue;
    }
    if (arg === "--kinds") {
      const value = argv[index + 1];
      if (value == null) {
        throw new Error("missing value for --kinds");
      }
      out.kinds = value
        .split(",")
        .map((name) => name.trim())
        .filter((name) => name.length > 0);
      index += 1;
      continue;
    }
    throw new Error(`unknown argument: ${arg}`);
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
      // Continue polling until timeout.
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

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (!fs.existsSync(validationPath)) {
    throw new Error(`missing validation page: ${validationPath}`);
  }
  if (!fs.existsSync(referenceDir)) {
    console.log(`skip: reference directory not found: ${referenceDir}`);
    return;
  }

  const { child: server, stderrRef } = startServer();
  const baseUrl = `http://${host}:${port}`;
  const validationUrl = new URL(`${baseUrl}/zig-out/wasm-demo/validation.html`);
  if (args.samplePerKind != null) {
    validationUrl.searchParams.set("sample_per_kind", String(args.samplePerKind));
  }
  if (Array.isArray(args.kinds) && args.kinds.length > 0) {
    validationUrl.searchParams.set("kinds", args.kinds.join(","));
  }

  const cleanupServer = () => {
    if (!server.killed) {
      server.kill("SIGTERM");
    }
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
    await waitForServer(validationUrl.toString(), 15_000);

    const playwrightModulePath = ensurePlaywrightModule();
    const { chromium } = await import(pathToFileURL(playwrightModulePath).href);

    const executablePath = resolveBrowserExecutable();
    const browser = await chromium.launch({
      headless: true,
      ...(executablePath ? { executablePath } : {}),
    });

    try {
      const page = await browser.newPage();
      await page.goto(validationUrl.toString(), { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#run-validation", { timeout: 30_000 });
      await page.waitForSelector("#status", { timeout: 30_000 });

      const wasmReadyDeadline = Date.now() + 5 * 60_000;
      while (true) {
        const initStatus = (await page.textContent("#status")) || "";
        if (initStatus.includes("WASM loaded")) {
          break;
        }
        if (initStatus.includes("Failed to initialize")) {
          throw new Error(initStatus);
        }
        if (Date.now() > wasmReadyDeadline) {
          throw new Error(`timed out waiting for WASM initialization; status=${JSON.stringify(initStatus)}`);
        }
        await delay(250);
      }

      await page.fill("#ref-root", referenceRoot);
      await page.selectOption("#compare-enabled", "1");
      await page.click("#run-validation");

      const deadline = Date.now() + timeoutMs;
      let lastProgressLogAt = 0;
      while (true) {
        const snapshot = await page.evaluate(() => ({
          status: document.getElementById("status")?.textContent || "",
          progress: document.getElementById("progress")?.textContent || "",
        }));

        if (snapshot.status.includes("Validation failed:")) {
          throw new Error(snapshot.status);
        }
        if (snapshot.progress.includes("Kinds:")) {
          break;
        }
        if (Date.now() > deadline) {
          throw new Error(`timed out waiting for validation completion; last progress=${JSON.stringify(snapshot.progress)}`);
        }

        if (Date.now() - lastProgressLogAt > 10_000) {
          const oneLine = snapshot.progress.split("\n")[0] || "(no progress text yet)";
          console.log(`validation progress: ${oneLine}`);
          lastProgressLogAt = Date.now();
        }
        await delay(1000);
      }

      const statusText = (await page.textContent("#status")) || "";
      if (statusText.includes("Validation failed:")) {
        throw new Error(statusText);
      }

      const progressText = (await page.textContent("#progress")) || "";
      const totals = parseTotals(progressText);
      if (totals.mismatches == null || totals.missingRef == null) {
        throw new Error(`could not parse totals from progress text: ${JSON.stringify(progressText)}`);
      }

      const preview = await page.evaluate(() => ({
        mismatchMeta: (document.getElementById("mismatch-meta")?.textContent || "").trim(),
        generated: (document.getElementById("generated-host")?.innerHTML || "").trim(),
        reference: (document.getElementById("reference-host")?.innerHTML || "").trim(),
        runMeta: window.__lmtLastValidation || null,
      }));

      if (args.samplePerKind != null) {
        const runMeta = preview.runMeta;
        if (!runMeta || !runMeta.sampledRun) {
          throw new Error("sample run requested but validation metadata is missing");
        }
        if (runMeta.samplePerKind !== args.samplePerKind) {
          throw new Error(
            `sample run mismatch: expected samplePerKind=${args.samplePerKind}, got ${runMeta.samplePerKind}`,
          );
        }
        if (!Array.isArray(runMeta.rows) || runMeta.rows.length === 0) {
          throw new Error("sample run metadata has no rows");
        }
        for (const row of runMeta.rows) {
          const expectedSample = Math.min(args.samplePerKind, row.total);
          if (row.sampleTotal !== expectedSample) {
            throw new Error(
              `sample run coverage mismatch for kind=${row.kind}: expected sample=${expectedSample}, got ${row.sampleTotal}`,
            );
          }
          if (row.generated !== row.sampleTotal) {
            throw new Error(
              `sample run generation mismatch for kind=${row.kind}: generated=${row.generated}, sample=${row.sampleTotal}`,
            );
          }
        }
      }

      if (totals.mismatches > 0) {
        if (!preview.generated || !preview.reference || preview.mismatchMeta.includes("No mismatches captured")) {
          throw new Error(
            `mismatches=${totals.mismatches} but mismatch preview is not persisted in UI: ${JSON.stringify(preview)}`,
          );
        }
        throw new Error(
          `compat validation failed: mismatches=${totals.mismatches}, missing_ref=${totals.missingRef}, first=${preview.mismatchMeta}`,
        );
      }

      if (totals.missingRef > 0) {
        throw new Error(`compat validation failed: missing_ref=${totals.missingRef}`);
      }

      if (totals.images != null && totals.generated != null && totals.generated !== totals.images) {
        throw new Error(`compat validation failed: generated=${totals.generated}, images=${totals.images}`);
      }

      console.log(
        `compat validation passed: kinds=${totals.kinds}, images=${totals.images}, exact_matches=${totals.exactMatches}, mismatches=0, missing_ref=0`,
      );
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
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
