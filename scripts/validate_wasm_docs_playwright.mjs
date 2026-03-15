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
const docsDir = path.join(rootDir, "zig-out", "wasm-docs");

const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
const timeoutMs = Number.parseInt(process.env.LMT_WASM_DOCS_TIMEOUT_MS || "300000", 10);
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
      const resolvedPort = address.port;
      probe.close((err) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(resolvedPort);
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
      // Keep polling.
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

function startServer(port) {
  const args = ["-m", "http.server", String(port), "--bind", host, "--directory", docsDir];
  const child = spawn("python3", args, {
    cwd: docsDir,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  return { child, stderrRef: () => stderr };
}

async function waitForInteractiveReady(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const statusText = (await page.textContent("#status")) || "";
    if (statusText.includes("WASM loaded. Interactive API calls are ready.")) return;
    if (statusText.includes("Failed to initialize:")) throw new Error(statusText);
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for docs initialization; status=${JSON.stringify(statusText)}`);
    }
    await delay(250);
  }
}

async function waitForRenderedOutputs(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      pcs: document.getElementById("out-pcs")?.textContent || "",
      classification: document.getElementById("out-classification")?.textContent || "",
      scaleMode: document.getElementById("out-scale-mode")?.textContent || "",
      chord: document.getElementById("out-chord")?.textContent || "",
      guitar: document.getElementById("out-guitar")?.textContent || "",
      svgMeta: document.getElementById("out-svg-meta")?.textContent || "",
      clock: document.getElementById("svg-clock")?.innerHTML || "",
      fret: document.getElementById("svg-fret")?.innerHTML || "",
      staff: document.getElementById("svg-staff")?.innerHTML || "",
      clockNormalized: document.querySelector("#svg-clock svg")?.dataset.previewNormalized || "",
      fretNormalized: document.querySelector("#svg-fret svg")?.dataset.previewNormalized || "",
      staffNormalized: document.querySelector("#svg-staff svg")?.dataset.previewNormalized || "",
      status: document.getElementById("status")?.textContent || "",
    }));

    if (snapshot.status.includes("Error:")) {
      throw new Error(snapshot.status);
    }

    const ready =
      snapshot.pcs.includes("lmt_pcs_from_list") &&
      snapshot.classification.includes("lmt_prime_form") &&
      snapshot.scaleMode.includes("lmt_scale") &&
      snapshot.chord.includes("lmt_chord") &&
      snapshot.guitar.includes("lmt_fret_to_midi") &&
      snapshot.svgMeta.includes("lmt_svg_clock_optc bytes:") &&
      snapshot.svgMeta.includes("aligned: yes") &&
      snapshot.clock.includes("<svg") &&
      snapshot.fret.includes("<svg") &&
      snapshot.staff.includes("<svg") &&
      snapshot.clockNormalized === "1" &&
      snapshot.fretNormalized === "1" &&
      snapshot.staffNormalized === "1";

    if (ready) return;

    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for docs outputs; last snapshot=${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}

async function main() {
  const indexPath = path.join(docsDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing docs page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startServer(port);
  const baseUrl = `http://${host}:${port}`;
  const docsUrl = new URL(`${baseUrl}/index.html`);

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
    await waitForServer(docsUrl.toString(), 15_000);

    const playwrightModulePath = ensurePlaywrightModule();
    const { chromium } = await import(pathToFileURL(playwrightModulePath).href);
    const executablePath = resolveBrowserExecutable();
    const browser = await chromium.launch({
      headless: true,
      ...(executablePath ? { executablePath } : {}),
    });

    try {
      const page = await browser.newPage();
      await page.goto(docsUrl.toString(), { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#run-all", { timeout: 30_000 });
      await waitForInteractiveReady(page);
      await page.click("#run-all");
      await waitForRenderedOutputs(page);
      console.log("wasm docs smoke passed: interactive examples rendered successfully");
    } finally {
      await browser.close();
    }
  } finally {
    cleanupServer();
    await delay(150);
    const stderr = stderrRef().trim();
    if (stderr.includes("Address already in use")) {
      throw new Error(`failed to start local docs server: ${stderr}`);
    }
  }
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
