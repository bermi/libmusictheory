#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import {
  delay,
  driveFakeMidiTriad,
  galleryDir,
  galleryUrl,
  installFakeMidi,
  launchChromium,
  releaseFakeMidiSustain,
  resolveValidationPort,
  rootDir,
  startGalleryServer,
  stopGalleryServer,
  waitForGalleryReady,
  waitForMidiSceneActive,
  waitForServer,
} from "./lib/wasm_gallery_playwright_common.mjs";

const defaultOutputDir = path.join(rootDir, "zig-out", "wasm-gallery-captures");

function parseArgs(argv) {
  let outputDir = defaultOutputDir;
  for (let index = 2; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--output-dir") {
      index += 1;
      outputDir = path.resolve(argv[index] || "");
      continue;
    }
    throw new Error(`unknown argument: ${token}`);
  }
  return { outputDir };
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

async function captureElement(page, selector, outPath) {
  const locator = page.locator(selector);
  await locator.scrollIntoViewIfNeeded();
  await locator.screenshot({ path: outPath });
  const buffer = fs.readFileSync(outPath);
  const size = parsePngSize(buffer);
  return {
    path: outPath,
    fileSize: buffer.byteLength,
    width: size.width,
    height: size.height,
  };
}

async function main() {
  const { outputDir } = parseArgs(process.argv);
  const indexPath = path.join(galleryDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing gallery page: ${indexPath}`);
  }

  fs.mkdirSync(outputDir, { recursive: true });
  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startGalleryServer(port);
  const url = galleryUrl(port, "?capture=1");

  const cleanupServer = () => stopGalleryServer(server);

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
    await waitForServer(url, 15000);
    const browser = await launchChromium();
    try {
      const page = await browser.newPage({
        viewport: { width: 1680, height: 1200 },
        deviceScaleFactor: 2,
      });
      await installFakeMidi(page);
      await page.goto(url, { waitUntil: "domcontentloaded" });
      await waitForGalleryReady(page);
      await page.waitForFunction(() => window.__lmtGallerySummary?.scenes?.midi?.inputCount >= 2, { timeout: 30000 });
      await driveFakeMidiTriad(page);
      await waitForMidiSceneActive(page);
      await page.click("#midi-snapshots [data-midi-snapshot]");
      await page.waitForFunction(() => window.__lmtGallerySummary?.scenes?.midi?.viewingSnapshot === true, { timeout: 30000 });
      await releaseFakeMidiSustain(page);
      await page.evaluate(() => document.fonts?.ready ?? Promise.resolve());
      await delay(300);

      const shots = {};
      shots.overview = await page.screenshot({
        path: path.join(outputDir, "gallery-overview.png"),
        fullPage: true,
      }).then(() => {
        const outPath = path.join(outputDir, "gallery-overview.png");
        const buffer = fs.readFileSync(outPath);
        const size = parsePngSize(buffer);
        return { path: outPath, fileSize: buffer.byteLength, width: size.width, height: size.height };
      });

      shots.hero = await captureElement(page, ".hero", path.join(outputDir, "gallery-hero.png"));
      const sceneMap = [
        ["midi", "#scene-midi"],
        ["set", "#scene-set"],
        ["key", "#scene-key"],
        ["chord", "#scene-chord"],
        ["progression", "#scene-progression"],
        ["compare", "#scene-compare"],
        ["fret", "#scene-fret"],
      ];
      for (const [name, selector] of sceneMap) {
        shots[name] = await captureElement(page, selector, path.join(outputDir, `scene-${name}.png`));
      }

      const summary = await page.evaluate(() => ({
        status: document.getElementById("status")?.textContent || "",
        captureMode: document.documentElement.dataset.captureMode || "",
        sceneCount: document.querySelectorAll(".scene-card").length,
        gallerySummary: window.__lmtGallerySummary || null,
      }));

      const manifest = {
        route: "/index.html?capture=1",
        viewport: { width: 1680, height: 1200, deviceScaleFactor: 2 },
        summary,
        shots,
      };
      fs.writeFileSync(path.join(outputDir, "captures.json"), `${JSON.stringify(manifest, null, 2)}\n`);

      const requiredShots = ["overview", "hero", "midi", "set", "key", "chord", "progression", "compare", "fret"];
      for (const name of requiredShots) {
        const shot = shots[name];
        if (!shot) throw new Error(`missing screenshot metadata: ${name}`);
        if (shot.width < 900 || shot.height < 500) {
          throw new Error(`screenshot too small: ${name} ${shot.width}x${shot.height}`);
        }
        if (shot.fileSize < 40000) {
          throw new Error(`screenshot unexpectedly small on disk: ${name} ${shot.fileSize}`);
        }
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
    await cleanupServer();
    await delay(150);
  }
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
