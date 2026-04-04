import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { once } from "node:events";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn, spawnSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const rootDir = path.resolve(__dirname, "../..");
export const galleryDir = path.join(rootDir, "zig-out", "wasm-gallery");
export const host = process.env.LMT_VALIDATION_HOST || "127.0.0.1";
export const timeoutMs = Number.parseInt(process.env.LMT_WASM_GALLERY_TIMEOUT_MS || "300000", 10);
export const requestedPort = parsePort(process.env.LMT_VALIDATION_PORT || "");

export function parsePort(raw) {
  if (raw == null || String(raw).trim() === "") return null;
  const value = Number.parseInt(String(raw), 10);
  if (!Number.isFinite(value) || value <= 0 || value > 65535) {
    throw new Error(`invalid port: ${raw}`);
  }
  return value;
}

export function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function resolveBrowserExecutable() {
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

export function ensurePlaywrightModule() {
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

export function resolveValidationPort() {
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
      const port = address.port;
      probe.close((err) => (err ? reject(err) : resolve(port)));
    });
  });
}

export async function waitForServer(url, deadlineMs) {
  const start = Date.now();
  while (Date.now() - start < deadlineMs) {
    try {
      const res = await fetch(url, { method: "GET" });
      if (res.ok) return;
    } catch (_error) {
      // Keep polling.
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

export function startGalleryServer(port) {
  const args = ["-m", "http.server", String(port), "--bind", host, "--directory", galleryDir];
  const child = spawn("python3", args, {
    cwd: galleryDir,
    stdio: ["ignore", "ignore", "ignore"],
  });
  child.unref();
  return { child, stderrRef: () => "" };
}

export async function stopGalleryServer(child) {
  if (!child || child.exitCode !== null || child.killed) return;
  child.kill("SIGTERM");
  await Promise.race([
    once(child, "exit").catch(() => {}),
    delay(500),
  ]);
}

export function galleryUrl(port, search = "") {
  return `http://${host}:${port}/index.html${search}`;
}

export async function launchChromium() {
  const playwrightModulePath = ensurePlaywrightModule();
  const { chromium } = await import(pathToFileURL(playwrightModulePath).href);
  const executablePath = resolveBrowserExecutable();
  return chromium.launch({
    headless: true,
    ...(executablePath ? { executablePath } : {}),
  });
}

export async function installFakeMidi(page) {
  await page.addInitScript(() => {
    class FakeMidiInput {
      constructor(id, name) {
        this.id = id;
        this.name = name;
        this.manufacturer = "libmusictheory";
        this.type = "input";
        this.state = "connected";
        this.connection = "open";
        this.onmidimessage = null;
      }

      emit(data) {
        const payload = new Uint8Array(data);
        const event = { data: payload, receivedTime: performance.now(), target: this };
        if (typeof this.onmidimessage === "function") this.onmidimessage(event);
      }
    }

    const inputA = new FakeMidiInput("fake-midi-a", "Fake MIDI A");
    const inputB = new FakeMidiInput("fake-midi-b", "Fake MIDI B");
    const inputs = new Map([
      [inputA.id, inputA],
      [inputB.id, inputB],
    ]);
    const access = {
      sysexEnabled: false,
      inputs,
      outputs: new Map(),
      onstatechange: null,
    };

    navigator.requestMIDIAccess = async () => access;
    window.__lmtFakeMidi = {
      inputs,
      access,
      noteOn(note, velocity = 100, channel = 0, inputId = inputA.id) {
        inputs.get(inputId)?.emit([0x90 | (channel & 0x0f), note & 0x7f, velocity & 0x7f]);
      },
      noteOff(note, channel = 0, inputId = inputA.id) {
        inputs.get(inputId)?.emit([0x80 | (channel & 0x0f), note & 0x7f, 0]);
      },
      cc(controller, value, channel = 0, inputId = inputA.id) {
        inputs.get(inputId)?.emit([0xb0 | (channel & 0x0f), controller & 0x7f, value & 0x7f]);
      },
    };
  });
}

export async function driveFakeMidiTriad(page) {
  await page.evaluate(async () => {
    const fake = window.__lmtFakeMidi;
    if (!fake) throw new Error("missing fake midi harness");

    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    fake.noteOn(43, 100, 0, "fake-midi-a");
    await delay(40);
    fake.noteOn(52, 100, 0, "fake-midi-b");
    await delay(40);
    fake.noteOn(60, 100, 0, "fake-midi-a");
    await delay(40);
    fake.noteOn(64, 100, 0, "fake-midi-b");
    await delay(80);
    fake.cc(64, 127, 0, "fake-midi-a");
    fake.cc(64, 127, 0, "fake-midi-b");
    await delay(40);
    fake.cc(66, 127, 0, "fake-midi-a");
    await delay(40);
    fake.cc(66, 0, 0, "fake-midi-a");
    await delay(40);
    fake.noteOff(43, 0, "fake-midi-a");
    fake.noteOff(52, 0, "fake-midi-b");
    fake.noteOff(60, 0, "fake-midi-a");
    fake.noteOff(64, 0, "fake-midi-b");
    await delay(80);
  });
}

export async function releaseFakeMidiSustain(page) {
  await page.evaluate(async () => {
    const fake = window.__lmtFakeMidi;
    if (!fake) throw new Error("missing fake midi harness");

    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    fake.cc(64, 0, 0, "fake-midi-a");
    fake.cc(64, 0, 0, "fake-midi-b");
    await delay(100);
  });
}

export async function waitForMidiSceneActive(page, expectedPreviewMode = null) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      summary: window.__lmtGallerySummary?.scenes?.midi || null,
      galleryPreviewMode: window.__lmtGallerySummary?.previewMode || "",
      snapshotButtons: document.querySelectorAll("#midi-snapshots [data-midi-snapshot]").length,
      suggestionCards: document.querySelectorAll("#midi-suggestions .suggestion-card").length,
      noteChips: document.querySelectorAll("#midi-notes .chip").length,
      clockSvg: document.querySelector("#midi-clock svg")?.outerHTML || "",
      opticKSvg: document.querySelector("#midi-optic-k svg")?.outerHTML || "",
      evennessSvg: document.querySelector("#midi-evenness svg")?.outerHTML || "",
      keyboardSvg: document.querySelector("#midi-keyboard svg")?.outerHTML || "",
      keyboardImg: document.querySelector("#midi-keyboard img")?.getAttribute("src") || "",
      currentFretHtml: document.querySelector("#midi-current-fret")?.innerHTML || "",
      staffHtml: document.querySelector("#midi-staff")?.innerHTML || "",
      keyboardFeaturesFallback: (() => {
        const svg = document.querySelector("#midi-keyboard svg");
        if (!svg) return { selectedKeyCount: 0, echoKeyCount: 0, blackEchoSelectedCount: 0 };
        return {
          selectedKeyCount: svg.querySelectorAll(".keyboard-key.is-selected").length,
          echoKeyCount: svg.querySelectorAll(".keyboard-key.is-echo").length,
          blackEchoSelectedCount: svg.querySelectorAll(".keyboard-key.black-key-overlay.is-selected,.keyboard-key.black-key-overlay.is-echo").length,
        };
      })(),
      midiOpticKFeatures: (() => {
        const svg = document.querySelector("#midi-optic-k svg");
        if (!svg) return { clockCount: 0, linkCount: 0, labelCount: 0 };
        return {
          clockCount: svg.querySelectorAll(".optic-k-ring").length,
          linkCount: svg.querySelectorAll(".optic-k-link").length,
          labelCount: svg.querySelectorAll(".optic-k-label,.optic-k-set,.optic-k-chip,.optic-k-title").length,
        };
      })(),
      midiEvennessFeatures: (() => {
        const svg = document.querySelector("#midi-evenness svg");
        if (!svg) return { ringCount: 0, dotCount: 0, highlightCount: 0 };
        return {
          ringCount: svg.querySelectorAll(".ring").length,
          dotCount: svg.querySelectorAll(".dot").length,
          highlightCount: svg.querySelectorAll(".dot-highlight").length,
        };
      })(),
      midiStaffFeatures: (() => {
        const svg = document.querySelector("#midi-staff svg");
        if (!svg) {
          return {
            staffMode: "",
            clefCount: 0,
            noteheadCount: 0,
            barlineCount: 0,
          };
        }
        const system = svg.querySelector(".staff-system");
        const classList = Array.from(system?.classList || []);
        const staffModeClass = classList.find((name) => name.startsWith("staff-mode-")) || "";
        return {
          staffMode: staffModeClass.replace("staff-mode-", ""),
          clefCount: svg.querySelectorAll(".clef").length,
          noteheadCount: svg.querySelectorAll(".notehead").length,
          barlineCount: svg.querySelectorAll(".staff-barline").length,
        };
      })(),
      midiHorizonFeatures: (() => {
        const svg = document.querySelector("#midi-horizon svg");
        if (!svg) {
          return {
            currentNodeCount: 0,
            candidateNodeCount: 0,
            connectorCount: 0,
            warningCandidateCount: 0,
            reasonTagCount: 0,
          };
        }
        return {
          currentNodeCount: svg.querySelectorAll(".horizon-current-node").length,
          candidateNodeCount: svg.querySelectorAll(".horizon-candidate-node").length,
          connectorCount: svg.querySelectorAll(".horizon-connector").length,
          warningCandidateCount: svg.querySelectorAll(".horizon-warning-ring").length,
          reasonTagCount: svg.querySelectorAll(".horizon-reason-tag").length,
        };
      })(),
      midiBraidFeatures: (() => {
        const svg = document.querySelector("#midi-braid svg");
        if (!svg) {
          return {
            historyColumnCount: 0,
            candidateColumnCount: 0,
            strandCount: 0,
            currentVoiceCount: 0,
            ghostNodeCount: 0,
          };
        }
        return {
          historyColumnCount: svg.querySelectorAll(".braid-history-column").length,
          candidateColumnCount: svg.querySelectorAll(".braid-candidate-column").length,
          strandCount: svg.querySelectorAll(".braid-strand").length,
          currentVoiceCount: svg.querySelectorAll(".braid-current-node").length,
          ghostNodeCount: svg.querySelectorAll(".braid-ghost-node").length,
        };
      })(),
      midiWeatherFeatures: (() => {
        const svg = document.querySelector("#midi-weather svg");
        if (!svg) {
          return {
            currentAnchorCount: 0,
            cellCount: 0,
            warningCellCount: 0,
            positivePressureCount: 0,
            negativePressureCount: 0,
          };
        }
        return {
          currentAnchorCount: svg.querySelectorAll(".weather-current-anchor").length,
          cellCount: svg.querySelectorAll(".weather-cell").length,
          warningCellCount: svg.querySelectorAll(".weather-warning-cell").length,
          positivePressureCount: svg.querySelectorAll(".weather-positive-cell").length,
          negativePressureCount: svg.querySelectorAll(".weather-negative-cell").length,
        };
      })(),
      midiRiskRadarFeatures: (() => {
        const svg = document.querySelector("#midi-risk-radar svg");
        if (!svg) {
          return {
            axisCount: 0,
            populatedAxisCount: 0,
            currentPolygonCount: 0,
            candidatePolygonCount: 0,
            warningAxisCount: 0,
          };
        }
        return {
          axisCount: svg.querySelectorAll(".risk-axis").length,
          populatedAxisCount: svg.querySelectorAll(".risk-axis.is-populated").length,
          currentPolygonCount: svg.querySelectorAll(".risk-current-polygon").length,
          candidatePolygonCount: svg.querySelectorAll(".risk-candidate-polygon").length,
          warningAxisCount: svg.querySelectorAll(".risk-axis.is-warning").length,
        };
      })(),
      midiCadenceFunnelFeatures: (() => {
        const svg = document.querySelector("#midi-cadence-funnel svg");
        if (!svg) {
          return {
            anchorCount: 0,
            branchCount: 0,
            activeBranchCount: 0,
            warningBranchCount: 0,
          };
        }
        return {
          anchorCount: svg.querySelectorAll(".cadence-funnel-anchor").length,
          branchCount: svg.querySelectorAll(".cadence-funnel-branch").length,
          activeBranchCount: svg.querySelectorAll(".cadence-funnel-branch.is-active").length,
          warningBranchCount: svg.querySelectorAll(".cadence-funnel-branch.is-warning").length,
        };
      })(),
      midiSuspensionMachineFeatures: (() => {
        const svg = document.querySelector("#midi-suspension-machine svg");
        if (!svg) {
          return {
            stateLabel: "",
            obligationCount: 0,
            warningCount: 0,
            trackedVoiceCount: 0,
          };
        }
        return {
          stateLabel: svg.querySelector(".counterpoint-node-title")?.textContent?.trim() || "",
          obligationCount: svg.querySelectorAll(".suspension-obligation").length,
          warningCount: svg.querySelectorAll(".suspension-warning").length,
          trackedVoiceCount: /\bvoice\s+\d+\b/i.test(svg.textContent || "") ? 1 : 0,
        };
      })(),
      midiOrbifoldRibbonFeatures: (() => {
        const svg = document.querySelector("#midi-orbifold-ribbon svg");
        if (!svg) {
          return {
            currentAnchorCount: 0,
            candidateAnchorCount: 0,
            highlightedCandidateCount: 0,
            supportedCandidateCount: 0,
            edgeCount: 0,
          };
        }
        return {
          currentAnchorCount: svg.querySelectorAll(".orbifold-ribbon-current-anchor").length,
          candidateAnchorCount: svg.querySelectorAll(".orbifold-ribbon-candidate-anchor").length,
          highlightedCandidateCount: svg.querySelectorAll(".orbifold-ribbon-highlight-ring").length,
          supportedCandidateCount: svg.querySelectorAll(".orbifold-ribbon-ribbon").length,
          edgeCount: svg.querySelectorAll(".orbifold-ribbon-edge").length,
        };
      })(),
      midiCommonToneConstellationFeatures: (() => {
        const svg = document.querySelector("#midi-common-tone-constellation svg");
        if (!svg) {
          return {
            retainedStarCount: 0,
            movingVectorCount: 0,
            historyAnchorCount: 0,
            focusedCandidateIndex: -1,
          };
        }
        return {
          retainedStarCount: svg.querySelectorAll(".common-tone-constellation-retained-star").length,
          movingVectorCount: svg.querySelectorAll(".common-tone-constellation-moving-vector").length,
          historyAnchorCount: svg.querySelectorAll(".common-tone-constellation-history-anchor").length,
          focusedCandidateIndex: -1,
        };
      })(),
      midiInspectorFeatures: (() => {
        const host = document.querySelector("#midi-inspector");
        if (!host) {
          return {
            reasonCount: 0,
            warningCount: 0,
            motionBadgeCount: 0,
            candidateNoteCount: 0,
            pinned: false,
            narrativeReady: false,
          };
        }
        return {
          reasonCount: host.querySelectorAll(".pill").length,
          warningCount: host.querySelectorAll(".warning-chip").length,
          motionBadgeCount: host.querySelectorAll(".inspector-chip-row .pill").length,
          candidateNoteCount: (host.textContent || "").split("·").length,
          pinned: /Pinned/i.test(host.textContent || ""),
          narrativeReady: (host.querySelector(".inspector-narrative")?.textContent || "").trim().length > 0,
        };
      })(),
      midiContinuationLadderFeatures: (() => {
        const host = document.querySelector("#midi-continuation-ladder");
        if (!host) {
          return {
            rootLabel: "",
            continuationCount: 0,
            continuationClockCount: 0,
            continuationMiniCount: 0,
            sourceFocusedIndex: -1,
            firstContinuationLabel: "",
          };
        }
        return {
          rootLabel: (host.querySelector(".continuation-head h4")?.textContent || "").trim(),
          continuationCount: host.querySelectorAll(".continuation-card").length,
          continuationClockCount: host.querySelectorAll("[data-continuation-clock] :is(svg,img)").length,
          continuationMiniCount: host.querySelectorAll("[data-continuation-mini] :is(svg,img)").length,
          sourceFocusedIndex: -1,
          firstContinuationLabel: (host.querySelector(".continuation-card strong")?.textContent || "").trim(),
        };
      })(),
      midiPathWeaverFeatures: (() => {
        const host = document.querySelector("#midi-path-weaver");
        if (!host) {
          return {
            pathCount: 0,
            pathStepCount: 0,
            pathMiniCount: 0,
            rootFocusedIndex: -1,
            terminalLabels: [],
          };
        }
        return {
          pathCount: host.querySelectorAll(".path-weaver-card").length,
          pathStepCount: host.querySelectorAll(".path-weaver-step").length,
          pathMiniCount: host.querySelectorAll("[data-path-weaver-mini] :is(svg,img)").length,
          rootFocusedIndex: -1,
          terminalLabels: Array.from(host.querySelectorAll(".path-weaver-step-meta"), (node) => (node.textContent || "").trim()).filter(Boolean),
        };
      })(),
      midiCadenceGardenFeatures: (() => {
        const host = document.querySelector("#midi-cadence-garden");
        if (!host) {
          return {
            groupCount: 0,
            branchCount: 0,
            terminalClockCount: 0,
            terminalMiniCount: 0,
            rootFocusedIndex: -1,
            cadenceLabels: [],
            warningGroupCount: 0,
          };
        }
        return {
          groupCount: host.querySelectorAll(".cadence-garden-card").length,
          branchCount: Array.from(host.querySelectorAll(".cadence-garden-card .status-pill.is-live"), (node) => node.textContent || "")
            .map((text) => Number.parseInt(text, 10))
            .filter((value) => Number.isFinite(value))
            .reduce((sum, value) => sum + value, 0),
          terminalClockCount: host.querySelectorAll("[data-cadence-garden-clock] :is(svg,img)").length,
          terminalMiniCount: host.querySelectorAll("[data-cadence-garden-mini] :is(svg,img)").length,
          rootFocusedIndex: -1,
          cadenceLabels: Array.from(host.querySelectorAll(".cadence-garden-card h4"), (node) => (node.textContent || "").trim()).filter(Boolean),
          warningGroupCount: host.querySelectorAll(".cadence-garden-card .warning-chip").length,
        };
      })(),
      midiProfileOrchardFeatures: (() => {
        const host = document.querySelector("#midi-profile-orchard");
        if (!host) {
          return {
            profileCardCount: 0,
            populatedProfileCount: 0,
            highlightedCardCount: 0,
            profileClockCount: 0,
            profileMiniCount: 0,
            activeProfileIndex: -1,
            profileNames: [],
            cadenceLabels: [],
            warningCardCount: 0,
            rootFocusedIndex: -1,
          };
        }
        const highlighted = Array.from(host.querySelectorAll(".profile-orchard-card.is-active-profile"));
        return {
          profileCardCount: host.querySelectorAll(".profile-orchard-card").length,
          populatedProfileCount: host.querySelectorAll(".profile-orchard-card:not(.is-empty-profile)").length,
          highlightedCardCount: highlighted.length,
          profileClockCount: host.querySelectorAll("[data-profile-orchard-clock] :is(svg,img)").length,
          profileMiniCount: host.querySelectorAll("[data-profile-orchard-mini] :is(svg,img)").length,
          activeProfileIndex: highlighted.length > 0 ? Number.parseInt(highlighted[0].getAttribute("data-profile-index") || "-1", 10) : -1,
          profileNames: Array.from(host.querySelectorAll(".profile-orchard-card h4"), (node) => (node.textContent || "").trim()).filter(Boolean),
          cadenceLabels: Array.from(host.querySelectorAll(".profile-orchard-cadence"), (node) => (node.textContent || "").trim()).filter(Boolean),
          warningCardCount: host.querySelectorAll(".profile-orchard-card .warning-chip").length,
          rootFocusedIndex: -1,
        };
      })(),
      midiConsensusAtlasFeatures: (() => {
        const host = document.querySelector("#midi-consensus-atlas");
        if (!host) {
          return {
            clusterCount: 0,
            consensusClusterCount: 0,
            singletonClusterCount: 0,
            highlightedClusterCount: 0,
            clusterClockCount: 0,
            clusterMiniCount: 0,
            maxSupportCount: 0,
            focusedSignature: "",
            profileCoverageCount: 0,
            clusterLabels: [],
            cadenceLabels: [],
          };
        }
        const cards = Array.from(host.querySelectorAll(".consensus-atlas-card"));
        const highlighted = cards.filter((node) => node.classList.contains("is-focused-cluster"));
        const uniqueProfiles = new Set(Array.from(host.querySelectorAll("[data-consensus-profile]"), (node) => (node.textContent || "").trim()).filter(Boolean));
        return {
          clusterCount: cards.length,
          consensusClusterCount: cards.filter((node) => node.classList.contains("is-consensus")).length,
          singletonClusterCount: cards.filter((node) => node.classList.contains("is-outlier")).length,
          highlightedClusterCount: highlighted.length,
          clusterClockCount: host.querySelectorAll("[data-consensus-atlas-clock] :is(svg,img)").length,
          clusterMiniCount: host.querySelectorAll("[data-consensus-atlas-mini] :is(svg,img)").length,
          maxSupportCount: cards.reduce((max, node) => Math.max(max, Number.parseInt(node.getAttribute("data-support-count") || "0", 10) || 0), 0),
          focusedSignature: highlighted[0]?.getAttribute("data-consensus-signature") || "",
          profileCoverageCount: uniqueProfiles.size,
          clusterLabels: Array.from(host.querySelectorAll(".consensus-atlas-card h4"), (node) => (node.textContent || "").trim()).filter(Boolean),
          cadenceLabels: Array.from(host.querySelectorAll(".consensus-atlas-cadence, .consensus-atlas-card .status-pill"), (node) => (node.textContent || "").trim()).filter(Boolean),
        };
      })(),
      midiObligationLedgerFeatures: (() => {
        const host = document.querySelector("#midi-obligation-ledger");
        if (!host) {
          return {
            entryCount: 0,
            criticalEntryCount: 0,
            focusedSupportCount: 0,
            focusedDelayCount: 0,
            focusedAggravateCount: 0,
            warningEntryCount: 0,
            focusedSignature: "",
            statusLabels: [],
            entryLabels: [],
          };
        }
        const cards = Array.from(host.querySelectorAll(".obligation-ledger-card"));
        const statusLabels = cards.map((node) => node.getAttribute("data-obligation-status") || "").filter(Boolean);
        return {
          entryCount: cards.length,
          criticalEntryCount: cards.filter((node) => node.classList.contains("is-critical")).length,
          focusedSupportCount: statusLabels.filter((status) => status === "supports" || status === "resolves").length,
          focusedDelayCount: statusLabels.filter((status) => status === "delays").length,
          focusedAggravateCount: statusLabels.filter((status) => status === "aggravates").length,
          warningEntryCount: cards.filter((node) => node.classList.contains("is-critical") || node.classList.contains("is-caution")).length,
          focusedSignature: host.getAttribute("data-focused-signature") || window.__lmtGallerySummary?.scenes?.midi?.focusedSuggestionSignature || "",
          statusLabels,
          entryLabels: Array.from(host.querySelectorAll(".obligation-ledger-card h4"), (node) => (node.textContent || "").trim()).filter(Boolean),
        };
      })(),
      previewKinds: (() => {
        const hostIds = ["midi-clock", "midi-optic-k", "midi-evenness", "midi-keyboard", "midi-staff", "midi-current-fret", "midi-focused-mini"];
        return Object.fromEntries(hostIds.map((id) => {
          const host = document.getElementById(id);
          const image = host?.querySelector("img");
          const kind = image
            ? (image.dataset.previewKind === "svg" ? "svg" : "bitmap")
            : (host?.querySelector("svg") ? "svg" : "none");
          return [id, kind];
        }));
      })(),
      previewMetrics: Array.from(
        document.querySelectorAll("#midi-clock :is(svg,img), #midi-optic-k :is(svg,img), #midi-evenness :is(svg,img), #midi-keyboard :is(svg,img), #midi-staff :is(svg,img), #midi-current-fret :is(svg,img), #midi-focused-mini :is(svg,img)"),
        (node) => {
          const rect = node.getBoundingClientRect();
          return {
            host: node.parentElement?.id || "",
            normalized: node.dataset.previewNormalized || "",
            width: rect.width,
            height: rect.height,
          };
        },
      ),
    }));
    const previewModeOk = expectedPreviewMode == null
      ? ["svg", "bitmap"].includes(snapshot.galleryPreviewMode)
      : snapshot.galleryPreviewMode === expectedPreviewMode
        && Object.entries(snapshot.previewKinds).every(([hostId, kind]) =>
          kind === expectedPreviewMode
          || (
            (hostId === "midi-current-fret" || hostId === "midi-focused-mini")
            && snapshot.summary?.currentMiniMode === "off"
            && kind === "none"
          ));
    const midiOpticKFeatures = snapshot.summary?.midiOpticKFeatures ?? snapshot.midiOpticKFeatures;
    const midiEvennessFeatures = snapshot.summary?.midiEvennessFeatures ?? snapshot.midiEvennessFeatures;
    const midiStaffFeatures = snapshot.summary?.midiStaffFeatures ?? snapshot.midiStaffFeatures;
    const midiHorizonFeatures = snapshot.summary?.midiHorizonFeatures ?? snapshot.midiHorizonFeatures;
    const midiBraidFeatures = snapshot.summary?.midiBraidFeatures ?? snapshot.midiBraidFeatures;
    const midiWeatherFeatures = snapshot.summary?.midiWeatherFeatures ?? snapshot.midiWeatherFeatures;
    const midiRiskRadarFeatures = snapshot.summary?.midiRiskRadarFeatures ?? snapshot.midiRiskRadarFeatures;
    const midiCadenceFunnelFeatures = snapshot.summary?.midiCadenceFunnelFeatures ?? snapshot.midiCadenceFunnelFeatures;
    const midiSuspensionMachineFeatures = snapshot.summary?.midiSuspensionMachineFeatures ?? snapshot.midiSuspensionMachineFeatures;
    const midiOrbifoldRibbonFeatures = snapshot.summary?.midiOrbifoldRibbonFeatures ?? snapshot.midiOrbifoldRibbonFeatures;
    const midiCommonToneConstellationFeatures = snapshot.summary?.midiCommonToneConstellationFeatures ?? snapshot.midiCommonToneConstellationFeatures;
    const midiInspectorFeatures = snapshot.summary?.midiInspectorFeatures ?? snapshot.midiInspectorFeatures;
    const midiContinuationLadderFeatures = snapshot.summary?.midiContinuationLadderFeatures ?? snapshot.midiContinuationLadderFeatures;
    const midiPathWeaverFeatures = snapshot.summary?.midiPathWeaverFeatures ?? snapshot.midiPathWeaverFeatures;
    const midiCadenceGardenFeatures = snapshot.summary?.midiCadenceGardenFeatures ?? snapshot.midiCadenceGardenFeatures;
    const midiProfileOrchardFeatures = snapshot.summary?.midiProfileOrchardFeatures ?? snapshot.midiProfileOrchardFeatures;
    const midiConsensusAtlasFeatures = snapshot.summary?.midiConsensusAtlasFeatures ?? snapshot.midiConsensusAtlasFeatures;
    const midiObligationLedgerFeatures = snapshot.summary?.midiObligationLedgerFeatures ?? snapshot.midiObligationLedgerFeatures;
    const keyboardFeatures = snapshot.summary?.keyboardFeatures ?? snapshot.keyboardFeaturesFallback;
    if (
      snapshot.summary?.rendered === true
      && previewModeOk
      && snapshot.summary?.inputCount >= 2
      && snapshot.summary?.counterpointProfileId >= 0
      && snapshot.summary?.historyFrameCount >= 1
      && snapshot.summary?.viewingSnapshot === false
      && snapshot.summary?.liveCount >= 4
      && snapshot.summary?.displayCount >= 4
      && snapshot.summary?.snapshotCount >= 1
      && snapshot.summary?.suggestionCount >= 1
      && snapshot.noteChips >= 4
      && snapshot.suggestionCards >= 1
      && (snapshot.summary?.currentMiniMode || "off") !== ""
      && (snapshot.summary?.currentMiniRendered === true || snapshot.summary?.currentMiniMode === "off")
      && ((snapshot.summary?.suggestionMiniCount || 0) >= 1 || snapshot.summary?.currentMiniMode === "off")
      && snapshot.previewKinds["midi-clock"] !== "none"
      && snapshot.previewKinds["midi-optic-k"] !== "none"
      && snapshot.previewKinds["midi-evenness"] !== "none"
      && snapshot.previewKinds["midi-keyboard"] !== "none"
      && snapshot.previewKinds["midi-staff"] !== "none"
      && ((snapshot.previewKinds["midi-current-fret"] ?? "none") !== "none" || snapshot.summary?.currentMiniMode === "off")
      && ((snapshot.previewKinds["midi-focused-mini"] ?? "none") !== "none" || snapshot.summary?.currentMiniMode === "off")
      && midiInspectorFeatures.narrativeReady === true
      && midiContinuationLadderFeatures.rootLabel.length > 0
      && midiContinuationLadderFeatures.continuationCount >= 1
      && midiContinuationLadderFeatures.continuationClockCount >= 1
      && (midiContinuationLadderFeatures.continuationMiniCount >= 1 || snapshot.summary?.currentMiniMode === "off")
      && midiPathWeaverFeatures.pathCount >= 1
      && midiPathWeaverFeatures.pathStepCount >= 2
      && (midiPathWeaverFeatures.pathMiniCount >= 1 || snapshot.summary?.currentMiniMode === "off")
      && midiCadenceGardenFeatures.groupCount >= 1
      && midiCadenceGardenFeatures.branchCount >= 1
      && midiCadenceGardenFeatures.terminalClockCount >= 1
      && (midiCadenceGardenFeatures.terminalMiniCount >= 1 || snapshot.summary?.currentMiniMode === "off")
      && midiProfileOrchardFeatures.profileCardCount >= 5
      && midiProfileOrchardFeatures.populatedProfileCount >= 5
      && midiProfileOrchardFeatures.highlightedCardCount === 1
      && midiProfileOrchardFeatures.profileClockCount >= 5
      && (midiProfileOrchardFeatures.profileMiniCount >= 5 || snapshot.summary?.currentMiniMode === "off")
      && midiProfileOrchardFeatures.activeProfileIndex >= 0
      && midiProfileOrchardFeatures.profileNames.length >= 5
      && midiProfileOrchardFeatures.cadenceLabels.length >= 1
      && midiConsensusAtlasFeatures.clusterCount >= 2
      && midiConsensusAtlasFeatures.consensusClusterCount >= 1
      && midiConsensusAtlasFeatures.singletonClusterCount >= 1
      && midiConsensusAtlasFeatures.highlightedClusterCount === 1
      && midiConsensusAtlasFeatures.clusterClockCount >= 2
      && (midiConsensusAtlasFeatures.clusterMiniCount >= 2 || snapshot.summary?.currentMiniMode === "off")
      && midiConsensusAtlasFeatures.maxSupportCount >= 2
      && midiConsensusAtlasFeatures.focusedSignature.length > 0
      && midiConsensusAtlasFeatures.profileCoverageCount >= 5
      && midiConsensusAtlasFeatures.clusterLabels.length >= 2
      && midiObligationLedgerFeatures.entryCount >= 3
      && midiObligationLedgerFeatures.criticalEntryCount >= 1
      && (midiObligationLedgerFeatures.focusedSupportCount + midiObligationLedgerFeatures.focusedDelayCount + midiObligationLedgerFeatures.focusedAggravateCount) >= 1
      && midiObligationLedgerFeatures.warningEntryCount >= 1
      && midiObligationLedgerFeatures.focusedSignature.length > 0
      && midiObligationLedgerFeatures.entryLabels.length >= 3
      && midiOpticKFeatures.clockCount >= 2
      && midiOpticKFeatures.linkCount >= 1
      && midiOpticKFeatures.labelCount >= 5
      && midiEvennessFeatures.ringCount >= 5
      && midiEvennessFeatures.dotCount >= 200
      && midiEvennessFeatures.highlightCount >= 1
      && keyboardFeatures.selectedKeyCount >= 4
      && keyboardFeatures.echoKeyCount >= 4
      && midiStaffFeatures.staffMode === "grand"
      && midiStaffFeatures.clefCount >= 2
      && midiStaffFeatures.noteheadCount >= 4
      && midiStaffFeatures.barlineCount >= 2
      && midiHorizonFeatures.currentNodeCount >= 1
      && midiHorizonFeatures.candidateNodeCount >= 1
      && midiHorizonFeatures.connectorCount >= 1
      && midiBraidFeatures.historyColumnCount >= 1
      && midiBraidFeatures.candidateColumnCount >= 1
      && midiBraidFeatures.strandCount >= 1
      && midiBraidFeatures.currentVoiceCount >= 1
      && midiBraidFeatures.ghostNodeCount >= 1
      && midiWeatherFeatures.currentAnchorCount >= 1
      && midiWeatherFeatures.cellCount >= 1
      && midiRiskRadarFeatures.axisCount >= 6
      && midiRiskRadarFeatures.populatedAxisCount >= 4
      && midiRiskRadarFeatures.currentPolygonCount >= 1
      && midiRiskRadarFeatures.candidatePolygonCount >= 1
      && midiCadenceFunnelFeatures.anchorCount >= 1
      && midiCadenceFunnelFeatures.branchCount >= 2
      && midiSuspensionMachineFeatures.stateLabel.length > 0
      && midiOrbifoldRibbonFeatures.currentAnchorCount >= 1
      && midiOrbifoldRibbonFeatures.candidateAnchorCount >= 1
      && midiOrbifoldRibbonFeatures.highlightedCandidateCount >= 1
      && midiOrbifoldRibbonFeatures.edgeCount >= 1
      && midiCommonToneConstellationFeatures.retainedStarCount >= 1
      && midiCommonToneConstellationFeatures.movingVectorCount >= 1
    ) {
      return snapshot;
    }
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for active midi scene: ${JSON.stringify(snapshot)}`);
    }
    await delay(60);
  }
}

export async function waitForGalleryReady(page, expectedPreviewMode = null) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      status: document.getElementById("status")?.textContent || "",
      summary: window.__lmtGallerySummary || null,
      captureMode: document.documentElement.dataset.captureMode || "",
      midiClockSvg: document.querySelector("#midi-clock svg")?.outerHTML || "",
      midiOpticKSvg: document.querySelector("#midi-optic-k svg")?.outerHTML || "",
      midiEvennessSvg: document.querySelector("#midi-evenness svg")?.outerHTML || "",
      midiKeyboardSvg: document.querySelector("#midi-keyboard svg")?.outerHTML || "",
      midiKeyboardImg: document.querySelector("#midi-keyboard img")?.getAttribute("src") || "",
      midiCurrentFretSvg: document.querySelector("#midi-current-fret svg")?.outerHTML || "",
      midiCurrentFretImg: document.querySelector("#midi-current-fret img")?.getAttribute("src") || "",
      clockSvg: document.querySelector("#set-clock svg")?.outerHTML || "",
      setOpticKSvg: document.querySelector("#set-optic-k svg")?.outerHTML || "",
      setEvennessSvg: document.querySelector("#set-evenness svg")?.outerHTML || "",
      setMiniHtml: document.querySelector("#set-mini")?.innerHTML || "",
      keySvg: document.querySelector("#key-clock svg")?.outerHTML || "",
      chordSvg: document.querySelector("#chord-clock svg")?.outerHTML || "",
      staffSvg: document.querySelector("#chord-staff svg")?.outerHTML || "",
      keyStaffSvg: document.querySelector("#key-staff svg")?.outerHTML || "",
      keyKeyboardSvg: document.querySelector("#key-keyboard svg")?.outerHTML || "",
      keyKeyboardImg: document.querySelector("#key-keyboard img")?.getAttribute("src") || "",
      keyMiniHtml: document.querySelector("#key-mini")?.innerHTML || "",
      progressionSvg: document.querySelector("#progression-clock svg")?.outerHTML || "",
      progressionMiniHtml: document.querySelector("#progression-mini")?.innerHTML || "",
      compareLeftSvg: document.querySelector("#compare-left-clock svg")?.outerHTML || "",
      compareOverlapSvg: document.querySelector("#compare-overlap-clock svg")?.outerHTML || "",
      compareRightSvg: document.querySelector("#compare-right-clock svg")?.outerHTML || "",
      compareMiniHtml: document.querySelector("#compare-mini")?.innerHTML || "",
      fretSvg: document.querySelector("#fret-svg svg")?.outerHTML || "",
      fretMiniHtml: document.querySelector("#fret-mini")?.innerHTML || "",
      chordMiniHtml: document.querySelector("#chord-mini")?.innerHTML || "",
      degreeCards: document.querySelectorAll("#key-degrees .degree-card").length,
      noteChips: document.querySelectorAll("#key-notes .chip").length,
      midiNoteChips: document.querySelectorAll("#midi-notes .chip, #midi-notes .pill").length,
      midiSnapshotCount: document.querySelectorAll("#midi-snapshots [data-midi-snapshot]").length,
      midiSuggestionCount: document.querySelectorAll("#midi-suggestions .suggestion-card").length,
      midiHistoryCount: document.querySelectorAll("#midi-history .history-card").length,
      midiSuggestionMiniCount: document.querySelectorAll("#midi-suggestions [data-suggestion-mini] :is(svg,img)").length,
      voicingPills: document.querySelectorAll("#fret-voicings .pill").length,
      progressionCards: document.querySelectorAll("#progression-cards .progression-card").length,
      compareChips: document.querySelectorAll("#compare-chips .chip, #compare-chips .pill").length,
      toggleCount: document.querySelectorAll("#pcs-toggle-grid .pc-toggle").length,
      sceneCardCount: document.querySelectorAll(".scene-card").length,
      presetSelectCount: document.querySelectorAll("select[id$='-preset']").length,
      miniInstrumentMode: document.getElementById("mini-instrument-mode")?.value || "",
      midiProfileValue: document.getElementById("midi-profile")?.value || "",
      previewMetrics: Array.from(
        document.querySelectorAll("#midi-clock :is(svg,img), #midi-optic-k :is(svg,img), #midi-evenness :is(svg,img), #midi-keyboard :is(svg,img), #midi-staff :is(svg,img), #midi-current-fret :is(svg,img), #set-clock :is(svg,img), #set-optic-k :is(svg,img), #set-evenness :is(svg,img), #set-mini :is(svg,img), #key-clock :is(svg,img), #key-staff :is(svg,img), #key-keyboard :is(svg,img), #key-mini :is(svg,img), #chord-clock :is(svg,img), #chord-staff :is(svg,img), #chord-mini :is(svg,img), #progression-clock :is(svg,img), #progression-mini :is(svg,img), #compare-left-clock :is(svg,img), #compare-overlap-clock :is(svg,img), #compare-right-clock :is(svg,img), #compare-mini :is(svg,img), #fret-svg :is(svg,img), #fret-mini :is(svg,img)"),
        (node) => {
          const rect = node.getBoundingClientRect();
          return {
            host: node.parentElement?.id || "",
            normalized: node.dataset.previewNormalized || "",
            width: rect.width,
            height: rect.height,
          };
        },
      ),
      staffFeatures: (() => {
        const svg = document.querySelector("#chord-staff svg");
        if (!svg) {
          return {
            clefCount: 0,
            noteheadCount: 0,
            sharedStemCount: 0,
            noteColumnSpan: Number.POSITIVE_INFINITY,
            distinctNoteColumns: 0,
            simultaneousCluster: false,
            barlineCount: 0,
          };
        }
        const noteXs = Array.from(svg.querySelectorAll(".notehead.chord-notehead"), (node) =>
          Number.parseFloat(node.getAttribute("cx") || "0"),
        ).filter((value) => Number.isFinite(value));
        const roundedColumns = new Set(noteXs.map((value) => value.toFixed(2)));
        const minX = noteXs.length > 0 ? Math.min(...noteXs) : 0;
        const maxX = noteXs.length > 0 ? Math.max(...noteXs) : 0;
        return {
          clefCount: svg.querySelectorAll(".clef").length,
          noteheadCount: noteXs.length,
          sharedStemCount: svg.querySelectorAll(".cluster-stem").length,
          noteColumnSpan: noteXs.length > 0 ? maxX - minX : Number.POSITIVE_INFINITY,
          distinctNoteColumns: roundedColumns.size,
          simultaneousCluster: noteXs.length >= 2 && maxX - minX <= 12,
          barlineCount: svg.querySelectorAll(".staff-barline").length,
        };
      })(),
      keyStaffFeatures: (() => {
        const svg = document.querySelector("#key-staff svg");
        if (!svg) {
          return {
            clefCount: 0,
            noteheadCount: 0,
            keyNoteheadCount: 0,
            barlineCount: 0,
          };
        }
        return {
          clefCount: svg.querySelectorAll(".clef").length,
          noteheadCount: svg.querySelectorAll(".notehead").length,
          keyNoteheadCount: svg.querySelectorAll(".notehead.key-notehead").length,
          barlineCount: svg.querySelectorAll(".staff-barline").length,
        };
      })(),
      midiKeyboardFeatures: (() => {
        return window.__lmtGallerySummary?.scenes?.midi?.keyboardFeatures || {
          selectedKeyCount: 0,
          echoKeyCount: 0,
          blackEchoSelectedCount: 0,
        };
      })(),
      keyKeyboardFeatures: (() => {
        return window.__lmtGallerySummary?.scenes?.key?.keyboardFeatures || {
          selectedKeyCount: 0,
          echoKeyCount: 0,
          blackEchoSelectedCount: 0,
        };
      })(),
      setEvennessFeatures: (() => {
        const svg = document.querySelector("#set-evenness svg");
        if (!svg) {
          return {
            ringCount: 0,
            dotCount: 0,
            highlightCount: 0,
          };
        }
        return {
          ringCount: svg.querySelectorAll(".ring").length,
          dotCount: svg.querySelectorAll(".dot").length,
          highlightCount: svg.querySelectorAll(".dot-highlight").length,
        };
      })(),
      midiEvennessFeatures: (() => {
        const svg = document.querySelector("#midi-evenness svg");
        if (!svg) {
          return {
            ringCount: 0,
            dotCount: 0,
            highlightCount: 0,
          };
        }
        return {
          ringCount: svg.querySelectorAll(".ring").length,
          dotCount: svg.querySelectorAll(".dot").length,
          highlightCount: svg.querySelectorAll(".dot-highlight").length,
        };
      })(),
      midiOpticKFeatures: (() => {
        const svg = document.querySelector("#midi-optic-k svg");
        if (!svg) {
          return {
            clockCount: 0,
            linkCount: 0,
            labelCount: 0,
          };
        }
        return {
          clockCount: svg.querySelectorAll(".optic-k-ring").length,
          linkCount: svg.querySelectorAll(".optic-k-link").length,
          labelCount: svg.querySelectorAll(".optic-k-label,.optic-k-set,.optic-k-chip,.optic-k-title").length,
        };
      })(),
      setOpticKFeatures: (() => {
        const svg = document.querySelector("#set-optic-k svg");
        if (!svg) {
          return {
            clockCount: 0,
            linkCount: 0,
            labelCount: 0,
          };
        }
        return {
          clockCount: svg.querySelectorAll(".optic-k-ring").length,
          linkCount: svg.querySelectorAll(".optic-k-link").length,
          labelCount: svg.querySelectorAll(".optic-k-label,.optic-k-set,.optic-k-chip,.optic-k-title").length,
        };
      })(),
      previewKinds: (() => {
        const hostIds = [
          "midi-clock",
          "midi-optic-k",
          "midi-evenness",
          "midi-keyboard",
          "midi-staff",
          "midi-current-fret",
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
        return Object.fromEntries(hostIds.map((id) => {
          const host = document.getElementById(id);
          const image = host?.querySelector("img");
          const kind = image
            ? (image.dataset.previewKind === "svg" ? "svg" : "bitmap")
            : (host?.querySelector("svg") ? "svg" : "none");
          return [id, kind];
        }));
      })(),
    }));

    if (snapshot.status.includes("Failed to initialize gallery")) {
      throw new Error(snapshot.status);
    }

    const summary = snapshot.summary;
    const requiredPreviewHosts = [
      "midi-clock",
      "midi-optic-k",
      "midi-evenness",
      "midi-keyboard",
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
    const previewModeOk = expectedPreviewMode == null
      ? ["svg", "bitmap"].includes(summary?.previewMode)
      : summary?.previewMode === expectedPreviewMode
        && requiredPreviewHosts.every((hostId) => snapshot.previewKinds[hostId] === expectedPreviewMode);
    const chordStaffFeatures = summary?.scenes?.chord?.staffFeatures ?? snapshot.staffFeatures;
    const keyStaffFeatures = summary?.scenes?.key?.keyStaffFeatures ?? snapshot.keyStaffFeatures;
    const midiKeyboardFeatures = summary?.scenes?.midi?.keyboardFeatures ?? snapshot.midiKeyboardFeatures;
    const keyKeyboardFeatures = summary?.scenes?.key?.keyboardFeatures ?? snapshot.keyKeyboardFeatures;
    const setEvennessFeatures = summary?.scenes?.set?.setEvennessFeatures ?? snapshot.setEvennessFeatures;
    const midiEvennessFeatures = summary?.scenes?.midi?.midiEvennessFeatures ?? snapshot.midiEvennessFeatures;
    const midiOpticKFeatures = summary?.scenes?.midi?.midiOpticKFeatures ?? snapshot.midiOpticKFeatures;
    const setOpticKFeatures = summary?.scenes?.set?.setOpticKFeatures ?? snapshot.setOpticKFeatures;
    const ready =
      summary?.ready === true &&
      previewModeOk &&
      summary?.manifestLoaded === true &&
      summary?.sceneCount >= 7 &&
      Array.isArray(summary?.errors) &&
      summary.errors.length === 0 &&
      summary.scenes?.midi?.rendered &&
      summary.scenes?.midi?.accessState === "connected" &&
      summary.scenes?.midi?.inputCount >= 2 &&
      summary.scenes?.midi?.counterpointProfileId >= 0 &&
      summary.scenes?.set?.rendered &&
      summary.scenes?.key?.rendered &&
      summary.scenes?.chord?.rendered &&
      summary.scenes?.progression?.rendered &&
      summary.scenes?.compare?.rendered &&
      summary.scenes?.fret?.rendered &&
      requiredPreviewHosts.every((hostId) => snapshot.previewKinds[hostId] !== "none") &&
      snapshot.degreeCards >= 7 &&
      snapshot.noteChips >= 7 &&
      snapshot.voicingPills >= 1 &&
      snapshot.progressionCards >= 4 &&
      snapshot.compareChips >= 4 &&
      snapshot.toggleCount === 12 &&
      snapshot.sceneCardCount >= 7 &&
      snapshot.presetSelectCount >= 6 &&
      snapshot.miniInstrumentMode !== "" &&
      snapshot.midiProfileValue !== "" &&
      snapshot.previewMetrics.length >= 17 &&
      snapshot.previewMetrics.every((metric) => metric.normalized === "1") &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-clock")?.width >= 260 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-clock")?.height >= 260 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-optic-k")?.width >= 260 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-optic-k")?.height >= 130 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-evenness")?.width >= 260 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-evenness")?.height >= 330 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-keyboard")?.width >= 720 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-keyboard")?.height >= 120 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-clock")?.width >= 320 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-clock")?.height >= 320 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-optic-k")?.width >= 560 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-optic-k")?.height >= 200 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-evenness")?.width >= 420 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-evenness")?.height >= 500 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-clock")?.width >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-clock")?.height >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-staff")?.width >= 780 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-staff")?.height >= 160 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-keyboard")?.width >= 720 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-keyboard")?.height >= 120 &&
      snapshot.previewMetrics.find((metric) => metric.host === "chord-clock")?.width >= 240 &&
      snapshot.previewMetrics.find((metric) => metric.host === "chord-clock")?.height >= 240 &&
      snapshot.previewMetrics.find((metric) => metric.host === "chord-staff")?.width >= 620 &&
      snapshot.previewMetrics.find((metric) => metric.host === "chord-staff")?.height >= 180 &&
      snapshot.previewMetrics.find((metric) => metric.host === "progression-clock")?.width >= 300 &&
      snapshot.previewMetrics.find((metric) => metric.host === "progression-clock")?.height >= 250 &&
      snapshot.previewMetrics.find((metric) => metric.host === "compare-left-clock")?.width >= 220 &&
      snapshot.previewMetrics.find((metric) => metric.host === "compare-overlap-clock")?.width >= 220 &&
      snapshot.previewMetrics.find((metric) => metric.host === "compare-right-clock")?.width >= 220 &&
      snapshot.previewMetrics.find((metric) => metric.host === "fret-svg")?.width >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "fret-svg")?.height >= 300 &&
      chordStaffFeatures.clefCount >= 1 &&
      chordStaffFeatures.noteheadCount >= 3 &&
      chordStaffFeatures.sharedStemCount === 1 &&
      chordStaffFeatures.simultaneousCluster === true &&
      chordStaffFeatures.noteColumnSpan <= 12 &&
      chordStaffFeatures.barlineCount >= 1 &&
      keyStaffFeatures.clefCount >= 1 &&
      keyStaffFeatures.noteheadCount >= 8 &&
      keyStaffFeatures.keyNoteheadCount >= 8 &&
      keyStaffFeatures.barlineCount >= 2 &&
      midiKeyboardFeatures.selectedKeyCount >= 3 &&
      midiKeyboardFeatures.echoKeyCount >= 3 &&
      midiOpticKFeatures.clockCount >= 2 &&
      midiOpticKFeatures.linkCount >= 1 &&
      midiOpticKFeatures.labelCount >= 5 &&
      midiEvennessFeatures.ringCount >= 5 &&
      midiEvennessFeatures.dotCount >= 200 &&
      keyKeyboardFeatures.selectedKeyCount >= 7 &&
      keyKeyboardFeatures.echoKeyCount >= 20 &&
      setOpticKFeatures.clockCount >= 2 &&
      setOpticKFeatures.linkCount >= 1 &&
      setOpticKFeatures.labelCount >= 5 &&
      setEvennessFeatures.ringCount >= 5 &&
      setEvennessFeatures.dotCount >= 200 &&
      setEvennessFeatures.highlightCount >= 1 &&
      (summary.scenes?.set?.miniInstrumentMode === snapshot.miniInstrumentMode) &&
      (summary.scenes?.key?.miniInstrumentMode === snapshot.miniInstrumentMode) &&
      (summary.scenes?.chord?.miniInstrumentMode === snapshot.miniInstrumentMode) &&
      (summary.scenes?.progression?.miniInstrumentMode === snapshot.miniInstrumentMode) &&
      (summary.scenes?.compare?.miniInstrumentMode === snapshot.miniInstrumentMode) &&
      (summary.scenes?.fret?.miniInstrumentMode === snapshot.miniInstrumentMode);

    if (ready) return snapshot;
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for gallery readiness: ${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}
