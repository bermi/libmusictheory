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
const trace = process.env.LMT_TRACE_GALLERY_VALIDATE === "1";
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
    if (trace) console.log(`trace:capture-host:${hostId}`);
    const selector = `#${hostId} :is(svg,img)`;
    const count = await page.locator(selector).count();
    if (count === 0) {
      out[hostId] = null;
      continue;
    }
    const preview = page.locator(selector).first();
    out[hostId] = (await preview.screenshot({ type: "png" })).toString("base64");
  }
  return out;
}

async function waitForPreviewAssets(page) {
  await page.evaluate(async () => {
    await (document.fonts?.ready ?? Promise.resolve());
  });
  await delay(220);
}

function traceStep(step) {
  if (trace) console.error(`trace:${step}`);
}

async function main() {
  const indexPath = path.join(galleryDir, "index.html");
  if (!fs.existsSync(indexPath)) {
    throw new Error(`missing gallery page: ${indexPath}`);
  }

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
    traceStep("wait-for-server");
    await waitForServer(url, 15000);
    const browser = await launchChromium();

    try {
      traceStep("new-page");
      const page = await browser.newPage({
        viewport: { width: 1680, height: 1200 },
        deviceScaleFactor: 2,
      });
      await installFakeMidi(page);
      traceStep("goto");
      await page.goto(url, { waitUntil: "domcontentloaded" });
      await page.waitForSelector("#shuffle-scenes", { timeout: 30000 });
      traceStep("gallery-ready-svg");
      const svgReady = await waitForGalleryReady(page, "svg");
      traceStep("preview-assets-svg");
      await waitForPreviewAssets(page);
      traceStep("midi-inputs");
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

      traceStep("drive-midi");
      await driveFakeMidiTriad(page);
      traceStep("midi-active-svg");
      const midiActiveSvg = await waitForMidiSceneActive(page, "svg");
      traceStep("capture-svg");
      await waitForPreviewAssets(page);
      const svgPreviewScreenshots = await captureHostScreenshots(page, previewDiffHostIds);
      traceStep("toggle-bitmap");
      await page.click("#preview-mode-bitmap");
      traceStep("gallery-ready-bitmap");
      const bitmapReady = await waitForGalleryReady(page, "bitmap");
      traceStep("midi-active-bitmap");
      const midiActive = await waitForMidiSceneActive(page, "bitmap");
      traceStep("capture-bitmap");
      await waitForPreviewAssets(page);
      const bitmapPreviewScreenshots = await captureHostScreenshots(page, previewDiffHostIds);
      const midiActiveStaffFeatures = midiActive.summary?.midiStaffFeatures ?? midiActive.midiStaffFeatures;
      const midiActiveOpticKFeatures = midiActive.summary?.midiOpticKFeatures ?? midiActive.midiOpticKFeatures;
      const midiActiveEvennessFeatures = midiActive.summary?.midiEvennessFeatures ?? midiActive.midiEvennessFeatures;
      const midiActiveHorizonFeatures = midiActive.summary?.midiHorizonFeatures ?? midiActive.midiHorizonFeatures;
      const midiActiveBraidFeatures = midiActive.summary?.midiBraidFeatures ?? midiActive.midiBraidFeatures;
      const midiActiveWeatherFeatures = midiActive.summary?.midiWeatherFeatures ?? midiActive.midiWeatherFeatures;
      const midiActiveRiskRadarFeatures = midiActive.summary?.midiRiskRadarFeatures ?? midiActive.midiRiskRadarFeatures;
      const midiActiveCadenceFunnelFeatures = midiActive.summary?.midiCadenceFunnelFeatures ?? midiActive.midiCadenceFunnelFeatures;
      const midiActiveSuspensionMachineFeatures = midiActive.summary?.midiSuspensionMachineFeatures ?? midiActive.midiSuspensionMachineFeatures;
      const midiActiveOrbifoldRibbonFeatures = midiActive.summary?.midiOrbifoldRibbonFeatures ?? midiActive.midiOrbifoldRibbonFeatures;
      const midiActiveCommonToneConstellationFeatures = midiActive.summary?.midiCommonToneConstellationFeatures ?? midiActive.midiCommonToneConstellationFeatures;
      const midiActiveInspectorFeatures = midiActive.summary?.midiInspectorFeatures ?? midiActive.midiInspectorFeatures;
      const midiActivePathWeaverFeatures = midiActive.summary?.midiPathWeaverFeatures ?? midiActive.midiPathWeaverFeatures;
      const midiActiveCadenceGardenFeatures = midiActive.summary?.midiCadenceGardenFeatures ?? midiActive.midiCadenceGardenFeatures;
      const midiActiveProfileOrchardFeatures = midiActive.summary?.midiProfileOrchardFeatures ?? midiActive.midiProfileOrchardFeatures;
      const midiActiveConsensusAtlasFeatures = midiActive.summary?.midiConsensusAtlasFeatures ?? midiActive.midiConsensusAtlasFeatures;
      const midiActiveObligationLedgerFeatures = midiActive.summary?.midiObligationLedgerFeatures ?? midiActive.midiObligationLedgerFeatures;
      const midiActiveResolutionThreaderFeatures = midiActive.summary?.midiResolutionThreaderFeatures ?? midiActive.midiResolutionThreaderFeatures;
      const midiActiveObligationTimelineFeatures = midiActive.summary?.midiObligationTimelineFeatures ?? midiActive.midiObligationTimelineFeatures;
      const midiActiveVoiceDutiesFeatures = midiActive.summary?.midiVoiceDutiesFeatures ?? midiActive.midiVoiceDutiesFeatures;
      if (
        midiActive.summary?.currentMiniMode !== "off"
        || midiActive.summary?.currentMiniRendered !== false
        || midiActive.summary?.focusedMiniRendered !== false
        || (midiActive.summary?.suggestionMiniCount || 0) !== 0
        || (midiActive.summary?.historyFrameCount || 0) < 1
        || (midiActive.summary?.focusedCandidateIndex ?? -1) < 0
        || (midiActive.summary?.pinnedCandidateIndex ?? -1) !== -1
        || (midiActiveInspectorFeatures?.narrativeReady !== true)
      ) {
        throw new Error(`live midi scene did not expose counterpoint miniview metadata correctly: ${JSON.stringify(midiActive.summary)}`);
      }
      traceStep("preview-compare");
      const previewModeDrift = (() => {
        const hosts = ["midi-clock", "midi-optic-k", "midi-evenness", "midi-keyboard", "midi-staff", "set-clock", "set-optic-k", "set-evenness"];
        const byHost = (snapshot, host) => snapshot.previewMetrics.find((one) => one.host === host) || null;
        return hosts.map((host) => {
          const svgSnapshot = host.startsWith("midi-") ? midiActiveSvg : svgReady;
          const bitmapSnapshot = host.startsWith("midi-") ? midiActive : bitmapReady;
          const svgMetric = byHost(svgSnapshot, host);
          const bitmapMetric = byHost(bitmapSnapshot, host);
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
      if (
        (midiActiveHorizonFeatures?.candidateNodeCount || 0) < 1
        || (midiActiveHorizonFeatures?.connectorCount || 0) < 1
        || (midiActiveBraidFeatures?.historyColumnCount || 0) < 1
        || (midiActiveBraidFeatures?.candidateColumnCount || 0) < 1
        || (midiActiveBraidFeatures?.strandCount || 0) < 1
      ) {
        throw new Error(`live midi scene did not render voice-leading horizon and braid correctly: ${JSON.stringify({ horizon: midiActiveHorizonFeatures, braid: midiActiveBraidFeatures })}`);
      }
      if (
        (midiActive.summary?.suggestionCount || 0) < 2
        || (midiActiveWeatherFeatures?.currentAnchorCount || 0) < 1
        || (midiActiveWeatherFeatures?.cellCount || 0) < 2
        || (midiActiveRiskRadarFeatures?.axisCount || 0) < 6
        || (midiActiveRiskRadarFeatures?.populatedAxisCount || 0) < 4
        || (midiActiveRiskRadarFeatures?.currentPolygonCount || 0) < 1
        || (midiActiveRiskRadarFeatures?.candidatePolygonCount || 0) < 1
      ) {
        throw new Error(`live midi scene did not render weather/radar diagnostics correctly: ${JSON.stringify({ weather: midiActiveWeatherFeatures, radar: midiActiveRiskRadarFeatures, summary: midiActive.summary })}`);
      }
      if (
        (midiActiveCadenceFunnelFeatures?.anchorCount || 0) < 1
        || (midiActiveCadenceFunnelFeatures?.branchCount || 0) < 2
        || !midiActiveSuspensionMachineFeatures?.stateLabel
      ) {
        throw new Error(`live midi scene did not render cadence/suspension diagnostics correctly: ${JSON.stringify({ cadence: midiActiveCadenceFunnelFeatures, suspension: midiActiveSuspensionMachineFeatures, summary: midiActive.summary })}`);
      }
      if (
        (midiActiveOrbifoldRibbonFeatures?.currentAnchorCount || 0) < 1
        || (midiActiveOrbifoldRibbonFeatures?.candidateAnchorCount || 0) < 1
        || (midiActiveOrbifoldRibbonFeatures?.highlightedCandidateCount || 0) < 1
        || (midiActiveOrbifoldRibbonFeatures?.edgeCount || 0) < 1
        || (midiActiveCommonToneConstellationFeatures?.retainedStarCount || 0) < 1
        || (midiActiveCommonToneConstellationFeatures?.movingVectorCount || 0) < 1
      ) {
        throw new Error(`live midi scene did not render orbifold/constellation diagnostics correctly: ${JSON.stringify({ orbifold: midiActiveOrbifoldRibbonFeatures, constellation: midiActiveCommonToneConstellationFeatures, summary: midiActive.summary })}`);
      }
      if (
        (midiActive.summary?.midiContinuationLadderFeatures?.continuationCount || 0) < 1
        || (midiActive.summary?.midiContinuationLadderFeatures?.continuationClockCount || 0) < 1
        || !midiActive.summary?.midiContinuationLadderFeatures?.rootLabel
      ) {
        throw new Error(`live midi scene did not render continuation ladder correctly: ${JSON.stringify({ continuation: midiActive.summary?.midiContinuationLadderFeatures, summary: midiActive.summary })}`);
      }
      if (
        (midiActiveProfileOrchardFeatures?.profileCardCount || 0) < 5
        || (midiActiveProfileOrchardFeatures?.populatedProfileCount || 0) < 5
        || (midiActiveProfileOrchardFeatures?.highlightedCardCount || 0) !== 1
        || (midiActiveProfileOrchardFeatures?.profileClockCount || 0) < 5
        || (midiActive.summary?.currentMiniMode === "off" ? false : (midiActiveProfileOrchardFeatures?.profileMiniCount || 0) < 5)
        || (midiActiveProfileOrchardFeatures?.activeProfileIndex ?? -1) < 0
        || (midiActiveProfileOrchardFeatures?.profileNames?.length || 0) < 5
      ) {
        throw new Error(`live midi scene did not render profile orchard correctly: ${JSON.stringify(midiActiveProfileOrchardFeatures)}`);
      }
      if (
        (midiActiveConsensusAtlasFeatures?.clusterCount || 0) < 2
        || (midiActiveConsensusAtlasFeatures?.consensusClusterCount || 0) < 1
        || (midiActiveConsensusAtlasFeatures?.singletonClusterCount || 0) < 1
        || (midiActiveConsensusAtlasFeatures?.highlightedClusterCount || 0) !== 1
        || (midiActiveConsensusAtlasFeatures?.clusterClockCount || 0) < 2
        || (midiActive.summary?.currentMiniMode === "off" ? false : (midiActiveConsensusAtlasFeatures?.clusterMiniCount || 0) < 2)
        || (midiActiveConsensusAtlasFeatures?.maxSupportCount || 0) < 2
        || (midiActiveConsensusAtlasFeatures?.profileCoverageCount || 0) < 5
        || !midiActiveConsensusAtlasFeatures?.focusedSignature
      ) {
        throw new Error(`live midi scene did not render consensus atlas correctly: ${JSON.stringify(midiActiveConsensusAtlasFeatures)}`);
      }
      if (
        (midiActiveObligationLedgerFeatures?.entryCount || 0) < 3
        || (midiActiveObligationLedgerFeatures?.criticalEntryCount || 0) < 1
        || ((midiActiveObligationLedgerFeatures?.focusedSupportCount || 0) + (midiActiveObligationLedgerFeatures?.focusedDelayCount || 0) + (midiActiveObligationLedgerFeatures?.focusedAggravateCount || 0)) < 1
        || (midiActiveObligationLedgerFeatures?.warningEntryCount || 0) < 1
        || ((midiActiveObligationLedgerFeatures?.entryLabels || []).length) < 3
        || (midiActiveObligationLedgerFeatures?.focusedSignature || "") !== (midiActive.summary?.focusedSuggestionSignature || "")
      ) {
        throw new Error(`live midi scene did not render obligation ledger correctly: ${JSON.stringify(midiActiveObligationLedgerFeatures)}`);
      }
      if (
        (midiActiveResolutionThreaderFeatures?.rowCount || 0) < 2
        || (midiActiveResolutionThreaderFeatures?.threadCount || 0) < 4
        || (midiActiveResolutionThreaderFeatures?.resolvedThreadCount || 0) < 1
        || ((midiActiveResolutionThreaderFeatures?.entryLabels || []).length) < 2
        || (midiActiveResolutionThreaderFeatures?.focusedSignature || "") !== (midiActive.summary?.focusedSuggestionSignature || "")
      ) {
        throw new Error(`live midi scene did not render resolution threader correctly: ${JSON.stringify(midiActiveResolutionThreaderFeatures)}`);
      }
      if (
        (midiActiveObligationTimelineFeatures?.rowCount || 0) < 2
        || (midiActiveObligationTimelineFeatures?.historyColumnCount || 0) < 2
        || (midiActiveObligationTimelineFeatures?.focusedColumnCount || 0) !== 1
        || (midiActiveObligationTimelineFeatures?.actualMatchCount || 0) < 1
        || ((midiActiveObligationTimelineFeatures?.rowLabels || []).length) < 2
        || (midiActiveObligationTimelineFeatures?.focusedSignature || "") !== (midiActive.summary?.focusedSuggestionSignature || "")
      ) {
        throw new Error(`live midi scene did not render obligation timeline correctly: ${JSON.stringify(midiActiveObligationTimelineFeatures)}`);
      }
      if (
        (midiActiveVoiceDutiesFeatures?.rowCount || 0) < 3
        || (midiActiveVoiceDutiesFeatures?.activeDutyCount || 0) < 1
        || (midiActiveVoiceDutiesFeatures?.currentNoteCount || 0) < (midiActiveVoiceDutiesFeatures?.rowCount || 0)
        || (midiActiveVoiceDutiesFeatures?.focusedNoteCount || 0) < (midiActiveVoiceDutiesFeatures?.rowCount || 0)
        || ((midiActiveVoiceDutiesFeatures?.rowLabels || []).length) < 3
        || (midiActiveVoiceDutiesFeatures?.focusedSignature || "") !== (midiActive.summary?.focusedSuggestionSignature || "")
      ) {
        throw new Error(`live midi scene did not render voice duties correctly: ${JSON.stringify(midiActiveVoiceDutiesFeatures)}`);
      }
      if (
        (midiActivePathWeaverFeatures?.pathCount || 0) < 1
        || (midiActivePathWeaverFeatures?.pathStepCount || 0) < 2
        || ((midiActivePathWeaverFeatures?.pathMiniCount || 0) < 1 && midiActive.summary?.currentMiniMode !== "off")
        || !Array.isArray(midiActivePathWeaverFeatures?.terminalLabels)
        || midiActivePathWeaverFeatures.terminalLabels.length < 1
      ) {
        throw new Error(`live midi scene did not render path weaver correctly: ${JSON.stringify({ pathWeaver: midiActivePathWeaverFeatures, summary: midiActive.summary })}`);
      }
      if (
        (midiActiveCadenceGardenFeatures?.groupCount || 0) < 1
        || (midiActiveCadenceGardenFeatures?.branchCount || 0) < 1
        || (midiActiveCadenceGardenFeatures?.terminalClockCount || 0) < 1
        || (((midiActiveCadenceGardenFeatures?.terminalMiniCount || 0) < 1) && midiActive.summary?.currentMiniMode !== "off")
        || !Array.isArray(midiActiveCadenceGardenFeatures?.cadenceLabels)
        || midiActiveCadenceGardenFeatures.cadenceLabels.length < 1
      ) {
        throw new Error(`live midi scene did not render cadence garden correctly: ${JSON.stringify({ cadenceGarden: midiActiveCadenceGardenFeatures, summary: midiActive.summary })}`);
      }
      traceStep("hover-candidate");
      const hoverCandidateIndex = Math.min(1, Math.max(0, (midiActive.summary?.suggestionCount || 1) - 1));
      await page.locator(`#midi-suggestions [data-suggestion-index="${hoverCandidateIndex}"]`).hover();
      const hoveredCandidate = await page.waitForFunction(({ targetIndex, targetSignature }) => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.hoveredCandidateIndex === targetIndex
          && midi?.focusedCandidateIndex === targetIndex
          && midi?.pinnedCandidateIndex === -1
          && (midi?.midiWeatherFeatures?.hoveredCandidateIndex ?? -1) === targetIndex
          && (midi?.midiWeatherFeatures?.focusedCandidateIndex ?? -1) === targetIndex
          && (midi?.midiRiskRadarFeatures?.focusedCandidateIndex ?? -1) === targetIndex
          && (midi?.midiOrbifoldRibbonFeatures?.highlightedCandidateCount || 0) >= 1
          && (midi?.midiCommonToneConstellationFeatures?.focusedCandidateIndex ?? -1) === targetIndex
          && (midi?.midiContinuationLadderFeatures?.sourceFocusedIndex ?? -1) === targetIndex
          && (midi?.midiContinuationLadderFeatures?.continuationCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiPathWeaverFeatures?.pathCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.pathStepCount || 0) >= 2
          && (midi?.midiCadenceGardenFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiCadenceGardenFeatures?.groupCount || 0) >= 1
          && (midi?.midiCadenceGardenFeatures?.terminalClockCount || 0) >= 1
          && (midi?.midiProfileOrchardFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiProfileOrchardFeatures?.profileCardCount || 0) >= 5
          && (midi?.midiConsensusAtlasFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationLedgerFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi?.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi?.midiConsensusAtlasFeatures?.clusterCount || 0) >= 2
          && (midi?.midiInspectorFeatures?.candidateNoteCount || 0) >= 1
          && (midi?.midiWeatherFeatures?.cellCount || 0) >= 2
          && (midi?.midiRiskRadarFeatures?.candidatePolygonCount || 0) >= 1
          && (midi?.midiRiskRadarFeatures?.populatedAxisCount || 0) >= 4;
      }, {
        targetIndex: hoverCandidateIndex,
        targetSignature: midiActive.summary?.suggestionSignatures?.[hoverCandidateIndex] || "",
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("pin-candidate");
      await page.click(`#midi-suggestions [data-suggestion-index="${hoverCandidateIndex}"]`);
      const pinnedCandidate = await page.waitForFunction(({ targetIndex, targetSignature }) => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.pinnedCandidateIndex === targetIndex
          && midi?.focusedCandidateIndex === targetIndex
          && midi?.hoveredCandidateIndex === targetIndex
          && midi?.midiInspectorFeatures?.pinned === true
          && (midi?.midiContinuationLadderFeatures?.sourceFocusedIndex ?? -1) === targetIndex
          && (midi?.midiContinuationLadderFeatures?.continuationCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiPathWeaverFeatures?.pathCount || 0) >= 1
          && (midi?.midiCadenceGardenFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiCadenceGardenFeatures?.groupCount || 0) >= 1
          && (midi?.midiProfileOrchardFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiProfileOrchardFeatures?.profileCardCount || 0) >= 5
          && (midi?.midiConsensusAtlasFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationLedgerFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi?.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi?.midiInspectorFeatures?.reasonCount || 0) >= 1;
      }, {
        targetIndex: hoverCandidateIndex,
        targetSignature: midiActive.summary?.suggestionSignatures?.[hoverCandidateIndex] || "",
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      await page.mouse.move(8, 8);
      const pinPersistsAfterMouseleave = await page.waitForFunction(({ targetIndex, targetSignature }) => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.pinnedCandidateIndex === targetIndex
          && midi?.focusedCandidateIndex === targetIndex
          && (midi?.midiCommonToneConstellationFeatures?.focusedCandidateIndex ?? -1) === targetIndex
          && (midi?.midiContinuationLadderFeatures?.sourceFocusedIndex ?? -1) === targetIndex
          && (midi?.midiPathWeaverFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiCadenceGardenFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiProfileOrchardFeatures?.rootFocusedIndex ?? -1) === targetIndex
          && (midi?.midiConsensusAtlasFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationLedgerFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiResolutionThreaderFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiObligationTimelineFeatures?.focusedSignature || "") === targetSignature
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === targetSignature;
      }, {
        targetIndex: hoverCandidateIndex,
        targetSignature: midiActive.summary?.suggestionSignatures?.[hoverCandidateIndex] || "",
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("clear-pin");
      await page.click("#midi-clear-pin");
      const hoverReset = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.pinnedCandidateIndex === -1
          && midi?.focusedCandidateIndex === 0
          && (midi?.midiWeatherFeatures?.focusedCandidateIndex ?? -1) === 0
          && (midi?.midiCommonToneConstellationFeatures?.focusedCandidateIndex ?? -1) === 0
          && (midi?.midiContinuationLadderFeatures?.sourceFocusedIndex ?? -1) === 0
          && (midi?.midiPathWeaverFeatures?.rootFocusedIndex ?? -1) === 0
          && (midi?.midiCadenceGardenFeatures?.rootFocusedIndex ?? -1) === 0
          && (midi?.midiProfileOrchardFeatures?.rootFocusedIndex ?? -1) === 0
          && (midi?.midiConsensusAtlasFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiObligationLedgerFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiResolutionThreaderFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiObligationTimelineFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "");
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("context-change");
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
        return midi.contextLabel !== beforeLabel
          && nextFirstSuggestion !== beforeFirstSuggestion
          && midi.displayCount >= 3
          && (midi.midiContinuationLadderFeatures?.continuationCount || 0) >= 1
          && (midi.midiPathWeaverFeatures?.pathCount || 0) >= 1
          && (midi.midiPathWeaverFeatures?.pathStepCount || 0) >= 2
          && (midi.midiCadenceGardenFeatures?.groupCount || 0) >= 1
          && (midi.midiProfileOrchardFeatures?.profileCardCount || 0) >= 5
          && (midi.midiProfileOrchardFeatures?.highlightedCardCount || 0) === 1
          && (midi.midiProfileOrchardFeatures?.activeProfileIndex ?? -1) === 0
          && (midi.midiConsensusAtlasFeatures?.clusterCount || 0) >= 2
          && (midi.midiConsensusAtlasFeatures?.consensusClusterCount || 0) >= 1
          && (midi.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi.midiConsensusAtlasFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi.midiObligationLedgerFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi.midiResolutionThreaderFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi.midiObligationTimelineFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi.midiVoiceDutiesFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi.midiHorizonFeatures?.candidateNodeCount || 0) >= 1
          && (midi.midiBraidFeatures?.candidateColumnCount || 0) >= 1
          && (midi.midiWeatherFeatures?.cellCount || 0) >= 2
          && (midi.midiRiskRadarFeatures?.populatedAxisCount || 0) >= 4
          && (midi.midiCadenceFunnelFeatures?.branchCount || 0) >= 2
          && !!midi.midiSuspensionMachineFeatures?.stateLabel
          && (midi.midiOrbifoldRibbonFeatures?.candidateAnchorCount || 0) >= 1
          && (midi.midiCommonToneConstellationFeatures?.retainedStarCount || 0) >= 1;
      }, { beforeLabel: defaultContext.label, beforeFirstSuggestion: defaultContext.suggestionNames[0] || "" }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("profile-change");
      await page.selectOption("#midi-profile", "3");
      const profileChanged = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.counterpointProfileId === 3
          && midi?.counterpointProfile === "jazz-close-leading"
          && midi?.suggestionCount >= 1
          && (midi?.midiContinuationLadderFeatures?.continuationCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.pathCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.pathStepCount || 0) >= 2
          && (midi?.midiCadenceGardenFeatures?.groupCount || 0) >= 1
          && (midi?.midiProfileOrchardFeatures?.profileCardCount || 0) >= 5
          && (midi?.midiProfileOrchardFeatures?.highlightedCardCount || 0) === 1
          && (midi?.midiProfileOrchardFeatures?.activeProfileIndex ?? -1) === 3
          && (midi?.midiConsensusAtlasFeatures?.clusterCount || 0) >= 2
          && (midi?.midiConsensusAtlasFeatures?.consensusClusterCount || 0) >= 1
          && (midi?.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi?.midiConsensusAtlasFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiObligationLedgerFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiResolutionThreaderFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && (midi?.midiHorizonFeatures?.candidateNodeCount || 0) >= 1
          && (midi?.midiBraidFeatures?.candidateColumnCount || 0) >= 1
          && (midi?.midiWeatherFeatures?.cellCount || 0) >= 2
          && (midi?.midiRiskRadarFeatures?.populatedAxisCount || 0) >= 4
          && (midi?.midiCadenceFunnelFeatures?.branchCount || 0) >= 2
          && !!midi?.midiSuspensionMachineFeatures?.stateLabel
          && (midi?.midiOrbifoldRibbonFeatures?.candidateAnchorCount || 0) >= 1
          && (midi?.midiCommonToneConstellationFeatures?.retainedStarCount || 0) >= 1;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("mini-piano");
      await page.selectOption("#mini-instrument-mode", "piano");
      const pianoMiniState = await page.waitForFunction(() => {
        const summary = window.__lmtGallerySummary;
        const midi = summary?.scenes?.midi;
        return summary?.ready === true
          && midi?.currentMiniMode === "piano"
          && midi?.currentMiniRendered === true
          && midi?.focusedMiniRendered === true
          && midi?.suggestionMiniCount >= 1
          && (midi?.midiContinuationLadderFeatures?.continuationMiniCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.pathMiniCount || 0) >= 1
          && (midi?.midiCadenceGardenFeatures?.terminalMiniCount || 0) >= 1
          && (midi?.midiProfileOrchardFeatures?.profileMiniCount || 0) >= 5
          && (midi?.midiConsensusAtlasFeatures?.clusterMiniCount || 0) >= 2
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && summary?.scenes?.set?.miniInstrumentMode === "piano"
          && summary?.scenes?.set?.miniRendered === true
          && summary?.scenes?.key?.miniRendered === true
          && summary?.scenes?.chord?.miniRendered === true
          && summary?.scenes?.progression?.miniRendered === true
          && summary?.scenes?.compare?.miniRendered === true
          && summary?.scenes?.fret?.miniRendered === true;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      const pianoMiniHosts = await page.evaluate(() => {
        const hostIds = ["midi-current-fret", "midi-focused-mini", "set-mini", "key-mini", "chord-mini", "progression-mini", "compare-mini", "fret-mini"];
        return Object.fromEntries(hostIds.map((id) => [id, !!document.querySelector(`#${id} :is(svg,img)`)]));
      });
      traceStep("mini-fret");
      await page.selectOption("#mini-instrument-mode", "fret");
      const fretMiniState = await page.waitForFunction(() => {
        const summary = window.__lmtGallerySummary;
        const midi = summary?.scenes?.midi;
        return summary?.ready === true
          && midi?.currentMiniMode === "fret"
          && midi?.currentMiniRendered === true
          && midi?.focusedMiniRendered === true
          && midi?.suggestionMiniCount >= 1
          && (midi?.midiContinuationLadderFeatures?.continuationMiniCount || 0) >= 1
          && (midi?.midiPathWeaverFeatures?.pathMiniCount || 0) >= 1
          && (midi?.midiCadenceGardenFeatures?.terminalMiniCount || 0) >= 1
          && (midi?.midiProfileOrchardFeatures?.profileMiniCount || 0) >= 5
          && (midi?.midiConsensusAtlasFeatures?.clusterMiniCount || 0) >= 2
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && summary?.scenes?.set?.miniInstrumentMode === "fret"
          && summary?.scenes?.set?.miniRendered === true
          && summary?.scenes?.key?.miniRendered === true
          && summary?.scenes?.chord?.miniRendered === true
          && summary?.scenes?.progression?.miniRendered === true
          && summary?.scenes?.compare?.miniRendered === true
          && summary?.scenes?.fret?.miniRendered === true;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      const fretMiniHosts = await page.evaluate(() => {
        const hostIds = ["midi-current-fret", "midi-focused-mini", "set-mini", "key-mini", "chord-mini", "progression-mini", "compare-mini", "fret-mini"];
        return Object.fromEntries(hostIds.map((id) => [id, !!document.querySelector(`#${id} :is(svg,img)`)]));
      });
      traceStep("release-sustain");
      await releaseFakeMidiSustain(page);
      await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === false && midi?.liveCount === 0 && midi?.displayCount === 0 && midi?.contextLabel === "C Phrygian";
      }, { timeout: 30000 });
      await waitForPreviewAssets(page);
      traceStep("keyboard-seam");
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
        const previewMinX = Number.parseFloat(rasterImage.dataset.previewMinX || "0");
        const previewMinY = Number.parseFloat(rasterImage.dataset.previewMinY || "0");
        const previewWidth = Number.parseFloat(rasterImage.dataset.previewWidth || String(sourceWidth));
        const previewHeight = Number.parseFloat(rasterImage.dataset.previewHeight || String(sourceHeight));
        const scaleX = rasterImage.naturalWidth / Math.max(previewWidth, 1);
        const scaleY = rasterImage.naturalHeight / Math.max(previewHeight, 1);

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
          const sampleX = Math.max(1, Math.min(canvas.width - 2, Math.round(((keyX + sample.blackKeyWidth / 2) - previewMinX) * scaleX)));
          const sampleYs = [
            sample.marginY + sample.blackKeyHeight * 0.42,
            sample.marginY + sample.blackKeyHeight * 0.52,
            sample.marginY + sample.blackKeyHeight * 0.62,
          ].map((value) => Math.max(0, Math.min(canvas.height - 1, Math.round((value - previewMinY) * scaleY))));
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
          ok: maxBlackEchoNeutralSeamLightness < 110,
          blackEchoSelectedCount: samples.length,
          maxBlackEchoNeutralSeamLightness,
          samples,
        };
      });
      if (!keyboardSeamCheck?.ok) {
        throw new Error(`live keyboard seam check failed: ${JSON.stringify(keyboardSeamCheck)}`);
      }
      traceStep("snapshot-restore");
      await page.click("#midi-snapshots [data-midi-snapshot]");
      const snapshotContextRestored = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === true
          && midi?.contextLabel === "C Ionian"
          && midi?.counterpointProfileId === 0
          && midi?.historyFrameCount >= 1
          && (midi?.midiCadenceFunnelFeatures?.branchCount || 0) >= 2
          && (midi?.midiProfileOrchardFeatures?.highlightedCardCount || 0) === 1
          && (midi?.midiProfileOrchardFeatures?.activeProfileIndex ?? -1) === 0
          && (midi?.midiConsensusAtlasFeatures?.clusterCount || 0) >= 2
          && (midi?.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && !!midi?.midiSuspensionMachineFeatures?.stateLabel
          && (midi?.midiOrbifoldRibbonFeatures?.candidateAnchorCount || 0) >= 1
          && (midi?.midiCommonToneConstellationFeatures?.retainedStarCount || 0) >= 1
          && document.querySelector("#midi-tonic")?.value === "0"
          && document.querySelector("#midi-mode")?.value === "0"
          && document.querySelector("#midi-profile")?.value === "0";
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      const snapshotView = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === true
          && midi?.displayCount >= 3
          && midi?.snapshotCount >= 1
          && (midi?.midiCadenceFunnelFeatures?.branchCount || 0) >= 2
          && (midi?.midiProfileOrchardFeatures?.highlightedCardCount || 0) === 1
          && (midi?.midiConsensusAtlasFeatures?.clusterCount || 0) >= 2
          && (midi?.midiConsensusAtlasFeatures?.highlightedClusterCount || 0) === 1
          && (midi?.midiObligationLedgerFeatures?.entryCount || 0) >= 3
          && (midi?.midiResolutionThreaderFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.rowCount || 0) >= 2
          && (midi?.midiObligationTimelineFeatures?.historyColumnCount || 0) >= 2
          && (midi?.midiVoiceDutiesFeatures?.rowCount || 0) >= 3
          && (midi?.midiVoiceDutiesFeatures?.activeDutyCount || 0) >= 1
          && (midi?.midiVoiceDutiesFeatures?.focusedSignature || "") === (midi?.focusedSuggestionSignature || "")
          && !!midi?.midiSuspensionMachineFeatures?.stateLabel
          && (midi?.midiOrbifoldRibbonFeatures?.candidateAnchorCount || 0) >= 1
          && (midi?.midiCommonToneConstellationFeatures?.retainedStarCount || 0) >= 1;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      await page.click("#midi-return-live");
      const backToLive = await page.waitForFunction(() => {
        const midi = window.__lmtGallerySummary?.scenes?.midi;
        return midi?.viewingSnapshot === false && midi?.liveCount === 0 && midi?.displayCount === 0;
      }, { timeout: 30000 }).then((handle) => handle.jsonValue());
      traceStep("toggle-svg");
      await page.click("#preview-mode-svg");
      traceStep("gallery-ready-svg-again");
      const svgReadyAgain = await waitForGalleryReady(page, "svg");
      traceStep("shuffle");
      await waitForPreviewAssets(page);

      await page.click("#shuffle-scenes");
      await waitForGalleryReady(page);

      await page.click("#render-set");
      await page.click("#render-key");
      await page.click("#render-chord");
      await page.click("#render-progression");
      await page.click("#render-compare");
      await page.click("#render-fret");
      traceStep("final-ready");
      const finalSnapshot = await waitForGalleryReady(page);
      const clockPaletteMetrics = await page.evaluate(() => {
        const palette = ["#00c", "#a4f", "#f0f", "#a16", "#e02", "#f91", "#ff0", "#1e0", "#094", "#0bb", "#16b", "#28f"];
        const hosts = ["midi-clock", "set-clock", "key-clock", "chord-clock", "progression-clock", "compare-left-clock", "compare-overlap-clock", "compare-right-clock"];
        const decodeSvgDataUrl = (src) => {
          const prefix = "data:image/svg+xml;charset=utf-8,";
          if (!src || !src.startsWith(prefix)) return "";
          try {
            return decodeURIComponent(src.slice(prefix.length));
          } catch (_error) {
            return "";
          }
        };
        return hosts.map((host) => {
          const image = document.querySelector(`#${host} img[data-preview-kind="svg"]`);
          const html = image instanceof HTMLImageElement ? decodeSvgDataUrl(image.src) : (document.getElementById(host)?.innerHTML || "");
          const paletteMatches = palette.filter((color) => html.toLowerCase().includes(color));
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
            midiActiveHorizonFeatures,
            midiActiveBraidFeatures,
            midiActiveWeatherFeatures,
            midiActiveRiskRadarFeatures,
            midiActiveOrbifoldRibbonFeatures,
            midiActiveCommonToneConstellationFeatures,
            midiActiveInspectorFeatures,
            hoveredCandidate,
            pinnedCandidate,
            pinPersistsAfterMouseleave,
            hoverReset,
            contextChanged,
            keyboardSeamCheck,
            profileChanged,
            pianoMiniState,
            pianoMiniHosts,
            fretMiniState,
            fretMiniHosts,
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
