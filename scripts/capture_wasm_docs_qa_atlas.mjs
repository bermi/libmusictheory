#!/usr/bin/env node

import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { spawn, spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");
const docsDir = path.join(rootDir, "zig-out", "wasm-docs");
const outputDir = path.join(rootDir, "zig-out", "wasm-docs-qa");
const host = "127.0.0.1";

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

function parsePngSize(buffer) {
  if (buffer.length < 24 || buffer.toString("ascii", 1, 4) !== "PNG") {
    throw new Error("not a PNG buffer");
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
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
    stdio: ["ignore", "pipe", "pipe"],
  });
  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });
  return { child, stderrRef: () => stderr };
}

async function main() {
  if (!fs.existsSync(path.join(docsDir, "qa-atlas.html"))) {
    throw new Error(`missing qa atlas page in ${docsDir}; run 'zig build wasm-docs' first`);
  }

  fs.mkdirSync(outputDir, { recursive: true });
  const port = await resolvePort();
  const { child: server, stderrRef } = startServer(port);
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
    const url = `http://${host}:${port}/qa-atlas.html`;
    await waitForServer(url);
    const browser = await launchChromium();
    try {
      const page = await browser.newPage({
        viewport: { width: 1920, height: 1200 },
        deviceScaleFactor: 2,
      });
      await page.goto(url, { waitUntil: "domcontentloaded" });
      await page.waitForFunction(() => window.__lmtQaAtlasSummary?.ready === true, null, { timeout: 300000 });
      await delay(300);

      const summary = await page.evaluate(() => ({
        status: document.getElementById("status")?.textContent || "",
        atlas: window.__lmtQaAtlasSummary || null,
      }));

      const outPath = path.join(outputDir, "qa-atlas.png");
      await page.locator("#qa-atlas-root").screenshot({ path: outPath });
      const buffer = fs.readFileSync(outPath);
      const size = parsePngSize(buffer);
      const manifest = {
        route: "/qa-atlas.html",
        summary,
        shot: {
          path: outPath,
          fileSize: buffer.byteLength,
          width: size.width,
          height: size.height,
        },
      };
      fs.writeFileSync(path.join(outputDir, "qa-atlas.json"), `${JSON.stringify(manifest, null, 2)}\n`);

      if ((summary.atlas?.imageMethodCount || 0) !== 4) {
        throw new Error(`qa atlas captured wrong image method count: ${summary.atlas?.imageMethodCount || 0}`);
      }
      if ((summary.atlas?.svgCount || 0) !== 4) {
        throw new Error(`qa atlas captured wrong svg panel count: ${summary.atlas?.svgCount || 0}`);
      }
      if ((summary.atlas?.renderedImageCount || 0) !== 4) {
        throw new Error(`qa atlas captured missing image rows: ${summary.atlas?.renderedImageCount || 0}/4 rendered`);
      }
      if (size.width < 2200 || size.height < 2600) {
        throw new Error(`qa atlas image unexpectedly small: ${size.width}x${size.height}`);
      }

      console.log(JSON.stringify(manifest, null, 2));
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
