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
  stopGalleryServer,
  waitForGalleryReady,
  waitForMidiSceneActive,
  waitForServer,
} from "./lib/wasm_gallery_playwright_common.mjs";

const maxPreviewDrift = Number.parseFloat(process.env.LMT_WASM_GALLERY_PREVIEW_MAX_DRIFT || "0.07");
const criticalPreviewHosts = new Set([
  "midi-clock",
  "midi-optic-k",
  "midi-evenness",
  "set-clock",
  "set-optic-k",
  "set-evenness",
]);

async function captureHostScreenshots(page, hostIds) {
  const out = {};
  for (const hostId of hostIds) {
    const preview = page.locator(`#${hostId} :is(svg,img)`).first();
    out[hostId] = (await preview.screenshot({ type: "png" })).toString("base64");
  }
  return out;
}

async function main() {
  const indexPath = path.join(galleryDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing gallery page: ${indexPath}`);
  }

  const port = await resolveValidationPort();
  const { child: server, stderrRef } = startGalleryServer(port);
  const url = galleryUrl(port);

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
      await page.waitForSelector("#shuffle-scenes", { timeout: 30000 });
      const svgReady = await waitForGalleryReady(page, "svg");
      await page.waitForFunction(() => window.__lmtGallerySummary?.scenes?.midi?.inputCount >= 2, { timeout: 30000 });
      const previewDiffHostIds = [
        "midi-clock",
        "midi-optic-k",
        "midi-evenness",
        "midi-keyboard",
        "midi-staff",
        "set-clock",
        "set-optic-k",
        "set-evenness",
        "key-clock",
        "key-staff",
        "key-keyboard",
        "chord-clock",
        "chord-staff",
        "progression-clock",
        "compare-left-clock",
        "compare-overlap-clock",
        "compare-right-clock",
        "fret-svg",
      ];

      await driveFakeMidiTriad(page);
      const midiActiveSvg = await waitForMidiSceneActive(page, "svg");
      const svgPreviewScreenshots = await captureHostScreenshots(page, previewDiffHostIds);
      await page.click("#preview-mode-bitmap");
      const bitmapReady = await waitForGalleryReady(page, "bitmap");
      const midiActive = await waitForMidiSceneActive(page, "bitmap");
      const bitmapPreviewScreenshots = await captureHostScreenshots(page, previewDiffHostIds);
      const midiActiveStaffFeatures = midiActive.summary?.midiStaffFeatures ?? midiActive.midiStaffFeatures;
      const midiActiveOpticKFeatures = midiActive.summary?.midiOpticKFeatures ?? midiActive.midiOpticKFeatures;
      const midiActiveEvennessFeatures = midiActive.summary?.midiEvennessFeatures ?? midiActive.midiEvennessFeatures;
      const previewModeDrift = (() => {
        const hosts = ["midi-clock", "midi-optic-k", "midi-evenness", "midi-keyboard", "midi-staff", "set-clock", "set-optic-k", "set-evenness"];
        const byHost = (snapshot, host) => snapshot.previewMetrics.find((one) => one.host === host) || null;
        return hosts.map((host) => {
          const svgMetric = byHost(svgReady, host);
          const bitmapMetric = byHost(bitmapReady, host);
          return {
            host,
            svgWidth: svgMetric?.width || 0,
            svgHeight: svgMetric?.height || 0,
            bitmapWidth: bitmapMetric?.width || 0,
            bitmapHeight: bitmapMetric?.height || 0,
            widthDelta: Math.abs((svgMetric?.width || 0) - (bitmapMetric?.width || 0)),
            heightDelta: Math.abs((svgMetric?.height || 0) - (bitmapMetric?.height || 0)),
          };
        });
      })();
      const previewModeFailures = previewModeDrift.filter((one) => one.widthDelta > 6 || one.heightDelta > 6);
      if (previewModeFailures.length > 0) {
        throw new Error(`preview mode size drift too large: ${JSON.stringify(previewModeFailures)}`);
      }
      const previewVisualDiffs = await page.evaluate(({ svgShots, bitmapShots }) => {
        const dataUrlToImage = async (src) => {
          const image = new Image();
          image.decoding = "sync";
          await new Promise((resolve, reject) => {
            image.onload = () => resolve();
            image.onerror = () => reject(new Error(`failed to load raster image: ${src.slice(0, 96)}`));
            image.src = src;
          });
          return image;
        };

        const compareRgba = (candidate, reference) => {
          const len = Math.min(candidate.length, reference.length);
          let totalDiff = 0;
          let changedPixels = 0;
          for (let i = 0; i < len; i += 4) {
            let pixelChanged = false;
            for (let channel = 0; channel < 4; channel += 1) {
              const diff = Math.abs(candidate[i + channel] - reference[i + channel]);
              totalDiff += diff;
              if (diff > 8) pixelChanged = true;
            }
            if (pixelChanged) changedPixels += 1;
          }
          return {
            drift: len > 0 ? totalDiff / (len * 255) : 1,
            changedPixels,
          };
        };

        const hostIds = Object.keys(svgShots).filter((id) => svgShots[id] && bitmapShots[id]);
        return Promise.all(hostIds.map(async (id) => {
          const svgImage = await dataUrlToImage(`data:image/png;base64,${svgShots[id]}`);
          const bitmapImage = await dataUrlToImage(`data:image/png;base64,${bitmapShots[id]}`);
          const width = Math.min(svgImage.naturalWidth, bitmapImage.naturalWidth);
          const height = Math.min(svgImage.naturalHeight, bitmapImage.naturalHeight);
          if (width <= 0 || height <= 0) {
            return { host: id, error: "invalid host screenshot dimensions" };
          }
          const referenceCanvas = document.createElement("canvas");
          referenceCanvas.width = width;
          referenceCanvas.height = height;
          const referenceCtx = referenceCanvas.getContext("2d", { willReadFrequently: true });
          referenceCtx.drawImage(svgImage, 0, 0, width, height);
          const reference = referenceCtx.getImageData(0, 0, width, height).data;
          const canvas = document.createElement("canvas");
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext("2d", { willReadFrequently: true });
          ctx.drawImage(bitmapImage, 0, 0, width, height);
          const candidate = ctx.getImageData(0, 0, width, height).data;
          const diff = compareRgba(candidate, reference);
          return { host: id, width, height, ...diff };
        }));
      }, { svgShots: svgPreviewScreenshots, bitmapShots: bitmapPreviewScreenshots });
      const previewVisualFailures = previewVisualDiffs.filter((one) =>
        criticalPreviewHosts.has(one.host)
          && (one.error || !Number.isFinite(one.drift) || one.drift > maxPreviewDrift));
      if (previewVisualFailures.length > 0) {
        throw new Error(`preview mode visual drift too large: ${JSON.stringify(previewVisualFailures)}`);
      }
      if (midiActiveStaffFeatures?.staffMode !== "grand" || (midiActiveStaffFeatures?.clefCount || 0) < 2) {
        throw new Error(`live midi scene did not render a grand staff: ${JSON.stringify(midiActiveStaffFeatures)}`);
      }
      if ((midiActiveOpticKFeatures?.clockCount || 0) < 2 || (midiActiveEvennessFeatures?.highlightCount || 0) < 1) {
        throw new Error(`live midi scene did not render OPTIC/K and evenness focus correctly: ${JSON.stringify({ optic: midiActiveOpticKFeatures, evenness: midiActiveEvennessFeatures })}`);
      }
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
      await releaseFakeMidiSustain(page);
      await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === false && midi?.liveCount === 0 && midi?.displayCount === 0 && midi?.contextLabel === "C Phrygian";
      }, { timeout: 30000 });
      const keyboardSeamCheck = await page.evaluate(async () => {
        const host = document.querySelector("#midi-keyboard");
        const image = host?.querySelector("img");
        const svg = host?.querySelector("svg");
        const sample = {
          notes: [60, 61, 63, 65, 67, 68, 70],
          low: 48,
          high: 83,
          marginX: 16,
          marginY: 16,
          whiteKeyWidth: 24,
          whiteKeyHeight: 124,
          blackKeyWidth: 14,
          blackKeyHeight: 76,
        };
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
        const selectedPcs = new Set(sample.notes.map((note) => note % 12));

        let rasterImage = null;
        if (image instanceof HTMLImageElement && image.complete && image.naturalWidth > 0) {
          rasterImage = image;
        } else if (svg instanceof SVGSVGElement) {
          const xml = new XMLSerializer().serializeToString(svg);
          const url = URL.createObjectURL(new Blob([xml], { type: "image/svg+xml;charset=utf-8" }));
          try {
            const generated = new Image();
            generated.decoding = "sync";
            const loaded = new Promise((resolve, reject) => {
              generated.onload = resolve;
              generated.onerror = reject;
            });
            generated.src = url;
            await loaded;
            rasterImage = generated;
          } finally {
            URL.revokeObjectURL(url);
          }
        }
        if (!(rasterImage instanceof HTMLImageElement)) {
          return { ok: false, reason: "missing live keyboard raster surface" };
        }

        const sourceWidth = sample.marginX * 2 + countWhiteKeys(sample.low, sample.high) * sample.whiteKeyWidth;
        const sourceHeight = sample.marginY * 2 + sample.whiteKeyHeight;
        const scaleX = rasterImage.naturalWidth / sourceWidth;
        const scaleY = rasterImage.naturalHeight / sourceHeight;

        const canvas = document.createElement("canvas");
        canvas.width = rasterImage.naturalWidth;
        canvas.height = rasterImage.naturalHeight;
        const ctx = canvas.getContext("2d", { willReadFrequently: true });
        if (!ctx) return { ok: false, reason: "missing 2d context" };
        ctx.drawImage(rasterImage, 0, 0);

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
          const seamDeltas = sampleYs.map((sampleY) => {
            const center = ctx.getImageData(sampleX, sampleY, 1, 1).data;
            const left = ctx.getImageData(sampleX - 1, sampleY, 1, 1).data;
            const right = ctx.getImageData(sampleX + 1, sampleY, 1, 1).data;
            const centerLightness = (center[0] + center[1] + center[2]) / 3;
            const neighborLightness = ((left[0] + left[1] + left[2]) + (right[0] + right[1] + right[2])) / 6;
            return centerLightness - neighborLightness;
          });
          samples.push({
            midi,
            maxCenterSeamDelta: Math.max(...seamDeltas),
          });
        }

        if (samples.length === 0) return { ok: false, reason: "no black-key seam probes generated" };
        const maxBlackEchoCenterSeamDelta = Math.max(...samples.map((one) => one.maxCenterSeamDelta));
        return {
          ok: maxBlackEchoCenterSeamDelta < 18,
          blackEchoSelectedCount: samples.length,
          maxBlackEchoCenterSeamDelta,
          samples,
        };
      });
      if (!keyboardSeamCheck?.ok) {
        throw new Error(`live keyboard seam check failed: ${JSON.stringify(keyboardSeamCheck)}`);
      }
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
      await page.click("#midi-return-live");
      const backToLive = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === false && midi?.liveCount === 0 && midi?.displayCount === 0;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      await page.click("#preview-mode-svg");
      const svgReadyAgain = await waitForGalleryReady(page, "svg");

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
            svgPreviewMode: svgReady.summary.previewMode,
            bitmapPreviewMode: bitmapReady.summary.previewMode,
            svgPreviewKinds: svgReady.previewKinds,
            bitmapPreviewKinds: bitmapReady.previewKinds,
            svgReadyAgainPreviewMode: svgReadyAgain.summary.previewMode,
            previewModeDrift,
            previewVisualDiffs,
            maxPreviewDrift,
            midiActiveSvg,
            midiActive,
            contextChanged,
            keyboardSeamCheck,
            snapshotContextRestored,
            snapshotView,
            backToLive,
            scenes: finalSnapshot.summary.scenes,
            previewMetrics: finalSnapshot.previewMetrics,
            staffFeatures: finalSnapshot.staffFeatures,
            keyStaffFeatures: finalSnapshot.keyStaffFeatures,
            setOpticKFeatures: finalSnapshot.setOpticKFeatures,
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
    await cleanupServer();
    await delay(150);
  }
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
