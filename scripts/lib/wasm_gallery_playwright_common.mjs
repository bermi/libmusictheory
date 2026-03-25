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
      previewKinds: (() => {
        const hostIds = ["midi-clock", "midi-optic-k", "midi-evenness", "midi-keyboard", "midi-staff", "midi-current-fret"];
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
        document.querySelectorAll("#midi-clock :is(svg,img), #midi-optic-k :is(svg,img), #midi-evenness :is(svg,img), #midi-keyboard :is(svg,img), #midi-staff :is(svg,img), #midi-current-fret :is(svg,img)"),
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
        && Object.values(snapshot.previewKinds).every((kind) => kind === expectedPreviewMode);
    const midiOpticKFeatures = snapshot.summary?.midiOpticKFeatures ?? snapshot.midiOpticKFeatures;
    const midiEvennessFeatures = snapshot.summary?.midiEvennessFeatures ?? snapshot.midiEvennessFeatures;
    const midiStaffFeatures = snapshot.summary?.midiStaffFeatures ?? snapshot.midiStaffFeatures;
    const keyboardFeatures = snapshot.summary?.keyboardFeatures ?? snapshot.keyboardFeaturesFallback;
    if (
      snapshot.summary?.rendered === true
      && previewModeOk
      && snapshot.summary?.inputCount >= 2
      && snapshot.summary?.viewingSnapshot === false
      && snapshot.summary?.liveCount >= 4
      && snapshot.summary?.displayCount >= 4
      && snapshot.summary?.snapshotCount >= 1
      && snapshot.summary?.suggestionCount >= 1
      && snapshot.noteChips >= 4
      && snapshot.suggestionCards >= 1
      && (snapshot.summary?.currentFretRendered === true)
      && (snapshot.summary?.suggestionFretCount || 0) >= 1
      && snapshot.previewKinds["midi-clock"] !== "none"
      && snapshot.previewKinds["midi-optic-k"] !== "none"
      && snapshot.previewKinds["midi-evenness"] !== "none"
      && snapshot.previewKinds["midi-keyboard"] !== "none"
      && snapshot.previewKinds["midi-staff"] !== "none"
      && snapshot.previewKinds["midi-current-fret"] !== "none"
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
      keySvg: document.querySelector("#key-clock svg")?.outerHTML || "",
      chordSvg: document.querySelector("#chord-clock svg")?.outerHTML || "",
      staffSvg: document.querySelector("#chord-staff svg")?.outerHTML || "",
      keyStaffSvg: document.querySelector("#key-staff svg")?.outerHTML || "",
      keyKeyboardSvg: document.querySelector("#key-keyboard svg")?.outerHTML || "",
      keyKeyboardImg: document.querySelector("#key-keyboard img")?.getAttribute("src") || "",
      progressionSvg: document.querySelector("#progression-clock svg")?.outerHTML || "",
      compareLeftSvg: document.querySelector("#compare-left-clock svg")?.outerHTML || "",
      compareOverlapSvg: document.querySelector("#compare-overlap-clock svg")?.outerHTML || "",
      compareRightSvg: document.querySelector("#compare-right-clock svg")?.outerHTML || "",
      fretSvg: document.querySelector("#fret-svg svg")?.outerHTML || "",
      degreeCards: document.querySelectorAll("#key-degrees .degree-card").length,
      noteChips: document.querySelectorAll("#key-notes .chip").length,
      midiNoteChips: document.querySelectorAll("#midi-notes .chip, #midi-notes .pill").length,
      midiSnapshotCount: document.querySelectorAll("#midi-snapshots [data-midi-snapshot]").length,
      midiSuggestionCount: document.querySelectorAll("#midi-suggestions .suggestion-card").length,
      midiSuggestionFretCount: document.querySelectorAll("#midi-suggestions [data-suggestion-fret-host] :is(svg,img)").length,
      voicingPills: document.querySelectorAll("#fret-voicings .pill").length,
      progressionCards: document.querySelectorAll("#progression-cards .progression-card").length,
      compareChips: document.querySelectorAll("#compare-chips .chip, #compare-chips .pill").length,
      toggleCount: document.querySelectorAll("#pcs-toggle-grid .pc-toggle").length,
      sceneCardCount: document.querySelectorAll(".scene-card").length,
      presetSelectCount: document.querySelectorAll("select[id$='-preset']").length,
      previewMetrics: Array.from(
        document.querySelectorAll("#midi-clock :is(svg,img), #midi-optic-k :is(svg,img), #midi-evenness :is(svg,img), #midi-keyboard :is(svg,img), #midi-staff :is(svg,img), #midi-current-fret :is(svg,img), #set-clock :is(svg,img), #set-optic-k :is(svg,img), #set-evenness :is(svg,img), #key-clock :is(svg,img), #key-staff :is(svg,img), #key-keyboard :is(svg,img), #chord-clock :is(svg,img), #chord-staff :is(svg,img), #progression-clock :is(svg,img), #compare-left-clock :is(svg,img), #compare-overlap-clock :is(svg,img), #compare-right-clock :is(svg,img), #fret-svg :is(svg,img)"),
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
      setEvennessFeatures.highlightCount >= 1;

    if (ready) return snapshot;
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for gallery readiness: ${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}
