import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
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
    stdio: ["ignore", "pipe", "pipe"],
  });

  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  return { child, stderrRef: () => stderr };
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

    fake.noteOn(60, 100, 0, "fake-midi-a");
    await delay(40);
    fake.noteOn(64, 100, 0, "fake-midi-b");
    await delay(40);
    fake.noteOn(67, 100, 0, "fake-midi-a");
    await delay(80);
    fake.cc(64, 127, 0, "fake-midi-a");
    fake.cc(64, 127, 0, "fake-midi-b");
    await delay(40);
    fake.cc(66, 127, 0, "fake-midi-a");
    await delay(40);
    fake.cc(66, 0, 0, "fake-midi-a");
    await delay(40);
    fake.noteOff(60, 0, "fake-midi-a");
    fake.noteOff(64, 0, "fake-midi-b");
    fake.noteOff(67, 0, "fake-midi-a");
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

export async function waitForMidiSceneActive(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      summary: window.__lmtGallerySummary?.scenes?.midi || null,
      snapshotButtons: document.querySelectorAll("#midi-snapshots [data-midi-snapshot]").length,
      suggestionCards: document.querySelectorAll("#midi-suggestions .suggestion-card").length,
      noteChips: document.querySelectorAll("#midi-notes .chip").length,
      clockSvg: document.querySelector("#midi-clock svg")?.outerHTML || "",
      staffHtml: document.querySelector("#midi-staff")?.innerHTML || "",
    }));
    if (
      snapshot.summary?.rendered === true
      && snapshot.summary?.inputCount >= 2
      && snapshot.summary?.viewingSnapshot === false
      && snapshot.summary?.liveCount >= 3
      && snapshot.summary?.displayCount >= 3
      && snapshot.summary?.snapshotCount >= 1
      && snapshot.summary?.suggestionCount >= 1
      && snapshot.noteChips >= 3
      && snapshot.suggestionCards >= 1
      && snapshot.clockSvg.includes("<svg")
      && snapshot.staffHtml.includes("<svg")
    ) {
      return snapshot;
    }
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for active midi scene: ${JSON.stringify(snapshot)}`);
    }
    await delay(60);
  }
}

export async function waitForGalleryReady(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const snapshot = await page.evaluate(() => ({
      status: document.getElementById("status")?.textContent || "",
      summary: window.__lmtGallerySummary || null,
      captureMode: document.documentElement.dataset.captureMode || "",
      midiClockSvg: document.querySelector("#midi-clock svg")?.outerHTML || "",
      clockSvg: document.querySelector("#set-clock svg")?.outerHTML || "",
      keySvg: document.querySelector("#key-clock svg")?.outerHTML || "",
      chordSvg: document.querySelector("#chord-clock svg")?.outerHTML || "",
      staffSvg: document.querySelector("#chord-staff svg")?.outerHTML || "",
      keyStaffSvg: document.querySelector("#key-staff svg")?.outerHTML || "",
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
      voicingPills: document.querySelectorAll("#fret-voicings .pill").length,
      progressionCards: document.querySelectorAll("#progression-cards .progression-card").length,
      compareChips: document.querySelectorAll("#compare-chips .chip, #compare-chips .pill").length,
      toggleCount: document.querySelectorAll("#pcs-toggle-grid .pc-toggle").length,
      sceneCardCount: document.querySelectorAll(".scene-card").length,
      presetSelectCount: document.querySelectorAll("select[id$='-preset']").length,
      previewMetrics: Array.from(
        document.querySelectorAll("#midi-clock svg, #set-clock svg, #key-clock svg, #key-staff svg, #chord-clock svg, #chord-staff svg, #progression-clock svg, #compare-left-clock svg, #compare-overlap-clock svg, #compare-right-clock svg, #fret-svg svg"),
        (svg) => {
          const rect = svg.getBoundingClientRect();
          return {
            host: svg.parentElement?.id || "",
            normalized: svg.dataset.previewNormalized || "",
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
    }));

    if (snapshot.status.includes("Failed to initialize gallery")) {
      throw new Error(snapshot.status);
    }

    const summary = snapshot.summary;
    const ready =
      summary?.ready === true &&
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
      snapshot.midiClockSvg.includes("<svg") &&
      snapshot.clockSvg.includes("<svg") &&
      snapshot.keySvg.includes("<svg") &&
      snapshot.keyStaffSvg.includes("<svg") &&
      snapshot.chordSvg.includes("<svg") &&
      snapshot.staffSvg.includes("<svg") &&
      snapshot.progressionSvg.includes("<svg") &&
      snapshot.compareLeftSvg.includes("<svg") &&
      snapshot.compareOverlapSvg.includes("<svg") &&
      snapshot.compareRightSvg.includes("<svg") &&
      snapshot.fretSvg.includes("<svg") &&
      snapshot.degreeCards >= 7 &&
      snapshot.noteChips >= 7 &&
      snapshot.voicingPills >= 1 &&
      snapshot.progressionCards >= 4 &&
      snapshot.compareChips >= 4 &&
      snapshot.toggleCount === 12 &&
      snapshot.sceneCardCount >= 7 &&
      snapshot.presetSelectCount >= 6 &&
      snapshot.previewMetrics.length >= 11 &&
      snapshot.previewMetrics.every((metric) => metric.normalized === "1") &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-clock")?.width >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "midi-clock")?.height >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-clock")?.width >= 320 &&
      snapshot.previewMetrics.find((metric) => metric.host === "set-clock")?.height >= 320 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-clock")?.width >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-clock")?.height >= 360 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-staff")?.width >= 780 &&
      snapshot.previewMetrics.find((metric) => metric.host === "key-staff")?.height >= 160 &&
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
      snapshot.staffFeatures.clefCount >= 1 &&
      snapshot.staffFeatures.noteheadCount >= 3 &&
      snapshot.staffFeatures.sharedStemCount === 1 &&
      snapshot.staffFeatures.simultaneousCluster === true &&
      snapshot.staffFeatures.noteColumnSpan <= 12 &&
      snapshot.staffFeatures.barlineCount >= 1 &&
      snapshot.keyStaffFeatures.clefCount >= 1 &&
      snapshot.keyStaffFeatures.noteheadCount >= 8 &&
      snapshot.keyStaffFeatures.keyNoteheadCount >= 8 &&
      snapshot.keyStaffFeatures.barlineCount >= 2;

    if (ready) return snapshot;
    if (Date.now() > deadline) {
      throw new Error(`timed out waiting for gallery readiness: ${JSON.stringify(snapshot)}`);
    }
    await delay(250);
  }
}
