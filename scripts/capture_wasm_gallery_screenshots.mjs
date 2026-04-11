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

async function captureElement(page, selector, outPath, options = {}) {
  const locator = page.locator(selector);
  const maxCssHeight = Number.isFinite(options.maxCssHeight) ? Math.max(1, options.maxCssHeight) : null;
  if (maxCssHeight != null) {
    await page.evaluate((sel) => {
      document.querySelector(sel)?.scrollIntoView({ block: "start", inline: "nearest" });
    }, selector);
    await delay(150);
    const handle = await locator.elementHandle();
    const box = await handle?.boundingBox();
    if (!box) throw new Error(`missing bounding box for ${selector}`);
    await page.screenshot({
      path: outPath,
      clip: {
        x: Math.max(0, box.x),
        y: Math.max(0, box.y),
        width: Math.max(1, box.width),
        height: Math.max(1, Math.min(box.height, maxCssHeight)),
      },
    });
  } else {
    await locator.scrollIntoViewIfNeeded();
    await locator.screenshot({ path: outPath });
  }
  const buffer = fs.readFileSync(outPath);
  const size = parsePngSize(buffer);
  return {
    path: outPath,
    fileSize: buffer.byteLength,
    width: size.width,
    height: size.height,
  };
}

async function captureParentCard(page, selector, outPath) {
  const locator = page.locator(selector);
  await locator.scrollIntoViewIfNeeded();
  const card = locator.locator("xpath=..");
  await card.screenshot({ path: outPath });
  const buffer = fs.readFileSync(outPath);
  const size = parsePngSize(buffer);
  return {
    path: outPath,
    fileSize: buffer.byteLength,
    width: size.width,
    height: size.height,
  };
}

async function waitForMidiPlayabilityCaptureState(page, expected) {
  await page.waitForFunction((state) => {
    const gallery = window.__lmtGallerySummary || null;
    const midi = gallery?.scenes?.midi || null;
    const guideText = document.getElementById("midi-playability-guide")?.textContent || "";
    if (!gallery || !midi) return false;
    if (midi.viewingSnapshot !== true) return false;
    if ((midi.suggestionCount || 0) < 1) return false;
    if ((midi.historyFrameCount || 0) < 1) return false;
    if (state.mini && midi.currentMiniMode !== state.mini) return false;
    if (state.overlay && gallery.playabilityOverlayMode !== state.overlay) return false;
    if (state.overlay && midi.playabilityOverlayMode !== state.overlay) return false;
    if (state.preset && midi.playabilityPreset !== state.preset) return false;
    if (state.policy && midi.playabilityPolicy !== state.policy) return false;
    if (state.guideIncludes && !guideText.includes(state.guideIncludes)) return false;
    if (state.mini !== "off" && midi.currentMiniRendered !== true) return false;
    if (state.overlay && state.overlay !== "off" && midi.currentMiniOverlay?.overlayRendered !== true) return false;
    return true;
  }, expected, { timeout: 30000 });
  await page.evaluate(() => document.fonts?.ready ?? Promise.resolve());
  await delay(300);
}

async function setMidiPlayabilityCaptureState(page, {
  mini,
  overlay,
  presetLabel,
  policyLabel,
}) {
  if (typeof presetLabel === "string") {
    await page.selectOption("#midi-playability-preset", { label: presetLabel });
  }
  if (typeof policyLabel === "string") {
    await page.selectOption("#midi-playability-policy", { label: policyLabel });
  }
  if (typeof mini === "string") {
    await page.selectOption("#mini-instrument-mode", mini);
  }
  if (typeof overlay === "string") {
    await page.selectOption("#playability-overlay-mode", overlay);
  }
  await waitForMidiPlayabilityCaptureState(page, {
    mini,
    overlay,
    preset: presetLabel,
    policy: policyLabel,
    guideIncludes: presetLabel,
  });
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

      await setMidiPlayabilityCaptureState(page, {
        mini: "off",
        overlay: "off",
        presetLabel: "balanced-standard",
        policyLabel: "balanced",
      });
      shots.midiPlayabilityGuide = await captureElement(
        page,
        "#scene-midi",
        path.join(outputDir, "scene-midi-playability-guide.png"),
        { maxCssHeight: 1500 },
      );

      await setMidiPlayabilityCaptureState(page, {
        mini: "piano",
        overlay: "basic",
        presetLabel: "compact-beginner",
        policyLabel: "minimax-bottleneck",
      });
      shots.midiPlayabilityPiano = await captureParentCard(
        page,
        "#midi-current-fret",
        path.join(outputDir, "scene-midi-playability-piano.png"),
      );

      await setMidiPlayabilityCaptureState(page, {
        mini: "fret",
        overlay: "detailed",
        presetLabel: "compact-beginner",
        policyLabel: "minimax-bottleneck",
      });
      shots.midiPlayabilityFret = await captureParentCard(
        page,
        "#midi-current-fret",
        path.join(outputDir, "scene-midi-playability-fret.png"),
      );

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

      const requiredShots = [
        "overview",
        "hero",
        "midi",
        "set",
        "key",
        "chord",
        "progression",
        "compare",
        "fret",
        "midiPlayabilityGuide",
        "midiPlayabilityPiano",
        "midiPlayabilityFret",
      ];
      const minDimensions = {
        midiPlayabilityPiano: { width: 600, height: 700 },
        midiPlayabilityFret: { width: 600, height: 700 },
      };
      for (const name of requiredShots) {
        const shot = shots[name];
        if (!shot) throw new Error(`missing screenshot metadata: ${name}`);
        const expected = minDimensions[name] || { width: 900, height: 500 };
        if (shot.width < expected.width || shot.height < expected.height) {
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
