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
  startGalleryServer,
  waitForGalleryReady,
  waitForMidiSceneActive,
  waitForServer,
} from "./lib/wasm_gallery_playwright_common.mjs";

async function main() {
  const indexPath = path.join(galleryDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing gallery page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startGalleryServer(port);
  const url = galleryUrl(port);

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
    await waitForServer(url, 15000);
    const browser = await launchChromium();

    try {
      const page = await browser.newPage({
        viewport: { width: 1680, height: 1200 },
        deviceScaleFactor: 2,
      });
      await installFakeMidi(page);
      await page.goto(url, { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#shuffle-scenes", { timeout: 30000 });
      await waitForGalleryReady(page);
      await page.waitForFunction(() => window.__lmtGallerySummary?.scenes?.midi?.inputCount >= 2, { timeout: 30000 });

      await driveFakeMidiTriad(page);
      const midiActive = await waitForMidiSceneActive(page);
      const defaultContext = await page.evaluate(() => ({
        label: window.__lmtGallerySummary?.scenes?.midi?.contextLabel || "",
        suggestionNames: window.__lmtGallerySummary?.scenes?.midi?.suggestionNames || [],
      }));
      await page.selectOption("#midi-tonic", "0");
      await page.selectOption("#midi-mode", "2");
      const contextChanged = await page.waitForFunction(({ beforeLabel, beforeFirstSuggestion }) => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        if (!midi?.rendered) return false;
        const nextFirstSuggestion = Array.isArray(midi.suggestionNames) ? (midi.suggestionNames[0] || "") : "";
        return midi.contextLabel !== beforeLabel && nextFirstSuggestion !== beforeFirstSuggestion && midi.displayCount >= 3;
      }, { beforeLabel: defaultContext.label, beforeFirstSuggestion: defaultContext.suggestionNames[0] || "" }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      await page.click("#midi-snapshots [data-midi-snapshot]");
      const snapshotContextRestored = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === true
          && midi?.contextLabel === "C Ionian"
          && document.querySelector("#midi-tonic")?.value === "0"
          && document.querySelector("#midi-mode")?.value === "0";
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      const snapshotView = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === true && midi?.displayCount >= 3 && midi?.snapshotCount >= 1;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      await releaseFakeMidiSustain(page);
      await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === true && midi?.liveCount === 0 && midi?.displayCount >= 3;
      }, { timeout: 30000 });
      await page.click("#midi-return-live");
      const backToLive = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === false && midi?.liveCount === 0 && midi?.displayCount === 0;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());

      await page.click("#shuffle-scenes");
      await waitForGalleryReady(page);

      await page.click("#render-set");
      await page.click("#render-key");
      await page.click("#render-chord");
      await page.click("#render-progression");
      await page.click("#render-compare");
      await page.click("#render-fret");
      const finalSnapshot = await waitForGalleryReady(page);
      const clockPaletteMetrics = await page.evaluate(() => {
        const palette = ["#00c", "#a4f", "#f0f", "#a16", "#e02", "#f91", "#ff0", "#1e0", "#094", "#0bb", "#16b", "#28f"];
        const hosts = ["midi-clock", "set-clock", "key-clock", "chord-clock", "progression-clock", "compare-left-clock", "compare-overlap-clock", "compare-right-clock"];
        return hosts.map((host) => {
          const html = document.getElementById(host)?.innerHTML || "";
          const paletteMatches = palette.filter((color) => html.includes(color));
          return { host, paletteMatches, matchCount: paletteMatches.length };
        });
      });
      const paletteFailures = clockPaletteMetrics.filter((one) => one.matchCount < 3);
      if (paletteFailures.length > 0) {
        throw new Error(`gallery clocks missing pitch-class palette coverage: ${paletteFailures.map((one) => `${one.host}:${one.paletteMatches.join(",") || "none"}`).join("; ")}`);
      }

      console.log(
        JSON.stringify(
          {
            status: finalSnapshot.status,
            manifestLoaded: finalSnapshot.summary.manifestLoaded,
            sceneCount: finalSnapshot.summary.sceneCount,
            midiActive,
            contextChanged,
            snapshotContextRestored,
            snapshotView,
            backToLive,
            scenes: finalSnapshot.summary.scenes,
            previewMetrics: finalSnapshot.previewMetrics,
            staffFeatures: finalSnapshot.staffFeatures,
            keyStaffFeatures: finalSnapshot.keyStaffFeatures,
            setEvennessFeatures: finalSnapshot.setEvennessFeatures,
            degreeCards: finalSnapshot.degreeCards,
            progressionCards: finalSnapshot.progressionCards,
            compareChips: finalSnapshot.compareChips,
            voicingPills: finalSnapshot.voicingPills,
            clockPaletteMetrics,
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
