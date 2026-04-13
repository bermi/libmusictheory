#!/usr/bin/env node

import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import process from "node:process";
import { once } from "node:events";
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
    stdio: ["ignore", "ignore", "ignore"],
  });
  child.unref();
  return { child, stderrRef: () => "" };
}

async function stopServer(child) {
  if (!child || child.exitCode !== null || child.killed) return;
  child.kill("SIGTERM");
  await Promise.race([
    once(child, "exit").catch(() => {}),
    delay(500),
  ]);
}

async function waitForInteractiveReady(page) {
  const deadline = Date.now() + timeoutMs;
  while (true) {
    const statusText = (await page.textContent("#status")) || "";
    if (
      statusText.includes("WASM loaded. Interactive API calls are ready.") ||
      statusText.includes("All sections rendered successfully.") ||
      statusText.includes("Run all completed with")
    ) {
      return;
    }
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
      playability: document.getElementById("out-playability")?.textContent || "",
      phraseAudit: document.getElementById("out-phrase-audit")?.textContent || "",
      svgMeta: document.getElementById("out-svg-meta")?.textContent || "",
      clock: document.getElementById("svg-clock")?.innerHTML || "",
      opticK: document.getElementById("svg-optic-k")?.innerHTML || "",
      evenness: document.getElementById("svg-evenness")?.innerHTML || "",
      evennessField: document.getElementById("svg-evenness-field")?.innerHTML || "",
      fret: document.getElementById("svg-fret")?.innerHTML || "",
      staff: document.getElementById("svg-staff")?.innerHTML || "",
      keyStaff: document.getElementById("svg-key-staff")?.innerHTML || "",
      pianoStaff: document.getElementById("svg-piano-staff")?.innerHTML || "",
      keyboard: document.getElementById("svg-keyboard")?.innerHTML || "",
      clockNormalized: document.querySelector("#svg-clock svg")?.dataset.previewNormalized || "",
      opticKNormalized: document.querySelector("#svg-optic-k svg")?.dataset.previewNormalized || "",
      evennessNormalized: document.querySelector("#svg-evenness svg")?.dataset.previewNormalized || "",
      evennessFieldNormalized: document.querySelector("#svg-evenness-field svg")?.dataset.previewNormalized || "",
      fretNormalized: document.querySelector("#svg-fret svg")?.dataset.previewNormalized || "",
      staffNormalized: document.querySelector("#svg-staff svg")?.dataset.previewNormalized || "",
      keyStaffNormalized: document.querySelector("#svg-key-staff svg")?.dataset.previewNormalized || "",
      pianoStaffNormalized: document.querySelector("#svg-piano-staff svg")?.dataset.previewNormalized || "",
      keyboardNormalized: document.querySelector("#svg-keyboard svg")?.dataset.previewNormalized || "",
      clockBounds: document.querySelector("#svg-clock svg")?.getBoundingClientRect?.() || null,
      opticKBounds: document.querySelector("#svg-optic-k svg")?.getBoundingClientRect?.() || null,
      evennessBounds: document.querySelector("#svg-evenness svg")?.getBoundingClientRect?.() || null,
      evennessFieldBounds: document.querySelector("#svg-evenness-field svg")?.getBoundingClientRect?.() || null,
      fretBounds: document.querySelector("#svg-fret svg")?.getBoundingClientRect?.() || null,
      staffBounds: document.querySelector("#svg-staff svg")?.getBoundingClientRect?.() || null,
      keyStaffBounds: document.querySelector("#svg-key-staff svg")?.getBoundingClientRect?.() || null,
      pianoStaffBounds: document.querySelector("#svg-piano-staff svg")?.getBoundingClientRect?.() || null,
      keyboardBounds: document.querySelector("#svg-keyboard svg")?.getBoundingClientRect?.() || null,
      keyboardFeatures: (() => {
        const svg = document.querySelector("#svg-keyboard svg");
        if (!svg) {
          return {
            selectedKeyCount: 0,
            echoKeyCount: 0,
            blackKeyCount: 0,
            blackEchoSelectedCount: 0,
          };
        }
        return {
          selectedKeyCount: svg.querySelectorAll(".keyboard-key.is-selected").length,
          echoKeyCount: svg.querySelectorAll(".keyboard-key.is-echo").length,
          blackKeyCount: svg.querySelectorAll(".keyboard-key.black-key-base,.keyboard-key.black-key:not(.black-key-overlay)").length,
          blackEchoSelectedCount: svg.querySelectorAll(".keyboard-key.black-key-overlay.is-selected,.keyboard-key.black-key-overlay.is-echo").length,
        };
      })(),
      staffFeatures: (() => {
        const svg = document.querySelector("#svg-staff svg");
        if (!svg) {
          return {
            clefCount: 0,
            noteheadCount: 0,
            sharedStemCount: 0,
            noteColumnSpan: Number.POSITIVE_INFINITY,
          };
        }
        const noteXs = Array.from(svg.querySelectorAll(".notehead.chord-notehead"), (node) =>
          Number.parseFloat(node.getAttribute("cx") || "0"),
        ).filter((value) => Number.isFinite(value));
        const minX = noteXs.length > 0 ? Math.min(...noteXs) : 0;
        const maxX = noteXs.length > 0 ? Math.max(...noteXs) : 0;
        return {
          clefCount: svg.querySelectorAll(".clef").length,
          noteheadCount: noteXs.length,
          sharedStemCount: svg.querySelectorAll(".cluster-stem").length,
          noteColumnSpan: noteXs.length > 0 ? maxX - minX : Number.POSITIVE_INFINITY,
        };
      })(),
      pianoStaffFeatures: (() => {
        const svg = document.querySelector("#svg-piano-staff svg");
        if (!svg) {
          return {
            clefCount: 0,
            noteheadCount: 0,
            barlineCount: 0,
            staffMode: "",
          };
        }
        const system = svg.querySelector(".staff-system");
        const classList = Array.from(system?.classList || []);
        const staffModeClass = classList.find((name) => name.startsWith("staff-mode-")) || "";
        return {
          clefCount: svg.querySelectorAll(".clef").length,
          noteheadCount: svg.querySelectorAll(".notehead").length,
          barlineCount: svg.querySelectorAll(".staff-barline").length,
          staffMode: staffModeClass.replace("staff-mode-", ""),
        };
      })(),
      evennessFieldFeatures: (() => {
        const svg = document.querySelector("#svg-evenness-field svg");
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
      snapshot.guitar.includes("lmt_fret_to_midi_n") &&
      snapshot.guitar.includes("lmt_generate_voicings_n") &&
      snapshot.guitar.includes("lmt_pitch_class_guide_n") &&
      snapshot.guitar.includes("lmt_frets_to_url_n") &&
      snapshot.guitar.includes("lmt_url_to_frets_n") &&
      snapshot.playability.includes("lmt_default_keyboard_hand_profile") &&
      snapshot.playability.includes("lmt_playability_profile_from_preset") &&
      snapshot.playability.includes("lmt_summarize_keyboard_realization_difficulty_n") &&
      snapshot.playability.includes("lmt_suggest_easier_keyboard_fingering_n") &&
      snapshot.playability.includes("lmt_suggest_safer_keyboard_next_step_by_playability") &&
      snapshot.playability.includes("LLM framing:") &&
      snapshot.phraseAudit.includes("lmt_audit_keyboard_phrase_n") &&
      snapshot.phraseAudit.includes("lmt_audit_committed_keyboard_phrase_n") &&
      snapshot.phraseAudit.includes("lmt_keyboard_committed_phrase_push") &&
      snapshot.phraseAudit.includes("lmt_rank_keyboard_phrase_repairs_n") &&
      snapshot.phraseAudit.includes("preview remains host-only") &&
      snapshot.phraseAudit.includes("realization-only repair") &&
      snapshot.phraseAudit.includes("music-changing repair") &&
      snapshot.svgMeta.includes("lmt_svg_clock_optc bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_optic_k_group bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_evenness_chart bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_evenness_field bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_fret_n bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_key_staff bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_piano_staff bytes:") &&
      snapshot.svgMeta.includes("lmt_svg_keyboard bytes:") &&
      snapshot.svgMeta.includes("aligned: yes") &&
      snapshot.clock.includes("<svg") &&
      snapshot.opticK.includes("<svg") &&
      snapshot.evenness.includes("<svg") &&
      snapshot.evennessField.includes("<svg") &&
      snapshot.fret.includes("<svg") &&
      snapshot.staff.includes("<svg") &&
      snapshot.keyStaff.includes("<svg") &&
      snapshot.pianoStaff.includes("<svg") &&
      snapshot.keyboard.includes("<svg") &&
      (snapshot.status.includes("All sections rendered successfully.") ||
        snapshot.status.includes("Run all completed with")) &&
      snapshot.clockNormalized === "1" &&
      snapshot.opticKNormalized === "1" &&
      snapshot.evennessNormalized === "1" &&
      snapshot.evennessFieldNormalized === "1" &&
      snapshot.fretNormalized === "1" &&
      snapshot.staffNormalized === "1" &&
      snapshot.keyStaffNormalized === "1" &&
      snapshot.pianoStaffNormalized === "1" &&
      snapshot.keyboardNormalized === "1" &&
      snapshot.clockBounds &&
      snapshot.opticKBounds &&
      snapshot.evennessBounds &&
      snapshot.evennessFieldBounds &&
      snapshot.fretBounds &&
      snapshot.staffBounds &&
      snapshot.keyStaffBounds &&
      snapshot.pianoStaffBounds &&
      snapshot.keyboardBounds &&
      snapshot.staffFeatures.clefCount >= 1 &&
      snapshot.staffFeatures.noteheadCount >= 3 &&
      snapshot.staffFeatures.sharedStemCount === 1 &&
      snapshot.staffFeatures.noteColumnSpan <= 12 &&
      snapshot.pianoStaffFeatures.clefCount >= 2 &&
      snapshot.pianoStaffFeatures.noteheadCount >= 4 &&
      snapshot.pianoStaffFeatures.barlineCount >= 2 &&
      snapshot.pianoStaffFeatures.staffMode === "grand" &&
      snapshot.evennessFieldFeatures.ringCount >= 5 &&
      snapshot.evennessFieldFeatures.dotCount >= 200 &&
      snapshot.evennessFieldFeatures.highlightCount >= 1 &&
      snapshot.keyboardFeatures.selectedKeyCount >= 3 &&
      snapshot.keyboardFeatures.echoKeyCount >= 3 &&
      snapshot.keyboardFeatures.blackKeyCount >= 10 &&
      visibleBoundsOk(snapshot);

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

  const cleanupServer = () => stopServer(server);

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
      await page.evaluate(() => {
        for (const id of ["out-pcs", "out-classification", "out-scale-mode", "out-chord", "out-guitar", "out-playability", "out-phrase-audit", "out-svg-meta"]) {
          const node = document.getElementById(id);
          if (node) node.textContent = "";
        }
        for (const id of ["svg-clock", "svg-optic-k", "svg-evenness", "svg-evenness-field", "svg-fret", "svg-staff", "svg-key-staff", "svg-piano-staff", "svg-keyboard"]) {
          const node = document.getElementById(id);
          if (node) node.innerHTML = "";
        }
      });
      await page.evaluate(() => document.getElementById("run-all")?.click());
      await waitForRenderedOutputs(page);
      const keyboardSeamCheck = await page.evaluate(async () => {
        const input = document.getElementById("svg-keyboard-notes");
        const runSvg = document.getElementById("run-svg");
        if (!(input instanceof HTMLInputElement) || !(runSvg instanceof HTMLButtonElement)) {
          return { ok: false, reason: "missing keyboard docs controls" };
        }
        input.value = "61,63,64,66,68,69,71,73";
        runSvg.click();

        const deadline = performance.now() + 5000;
        let svg = null;
        while (performance.now() < deadline) {
          svg = document.querySelector("#svg-keyboard svg");
          const overlayCount = svg?.querySelectorAll(".keyboard-key.black-key-overlay.is-selected,.keyboard-key.black-key-overlay.is-echo").length || 0;
          if (svg && overlayCount >= 2) break;
          await new Promise((resolve) => setTimeout(resolve, 60));
        }
        if (!svg) return { ok: false, reason: "keyboard svg missing after non-ionian render" };

        const overlays = [...svg.querySelectorAll(".keyboard-key.black-key-overlay.is-selected,.keyboard-key.black-key-overlay.is-echo")];
        const bases = [...svg.querySelectorAll(".keyboard-key.black-key-base")];
        if (overlays.length === 0) return { ok: false, reason: "no highlighted black overlays present" };
        const baseByMidi = new Map(bases.map((node) => [node.getAttribute("data-midi") || "", node]));
        const samples = overlays.map((node) => {
          const midi = node.getAttribute("data-midi") || "";
          const base = baseByMidi.get(midi);
          return {
            midi,
            maxCenterSeamDelta: 0,
            hasBase: Boolean(base),
            sameX: base?.getAttribute("x") === node.getAttribute("x"),
            sameY: base?.getAttribute("y") === node.getAttribute("y"),
            sameWidth: base?.getAttribute("width") === node.getAttribute("width"),
            sameHeight: base?.getAttribute("height") === node.getAttribute("height"),
          };
        });
        const allLayered = samples.every((one) => one.hasBase && one.sameX && one.sameY && one.sameWidth && one.sameHeight);
        return {
          ok: allLayered,
          blackEchoSelectedCount: overlays.length,
          maxBlackEchoCenterSeamDelta: 0,
          samples,
        };
      });
      if (!keyboardSeamCheck?.ok) {
        throw new Error(`keyboard seam check failed: ${JSON.stringify(keyboardSeamCheck)}`);
      }
      console.log("wasm docs smoke passed: interactive examples rendered successfully");
    } finally {
      await browser.close();
    }
  } finally {
    await cleanupServer();
    await delay(150);
    const stderr = stderrRef().trim();
    if (stderr.includes("Address already in use")) {
      throw new Error(`failed to start local docs server: ${stderr}`);
    }
  }
}

function visibleBoundsOk(snapshot) {
  return (
    snapshot.clockBounds.width >= 100 &&
    snapshot.clockBounds.height >= 100 &&
    snapshot.opticKBounds.width >= 280 &&
    snapshot.opticKBounds.height >= 140 &&
    snapshot.evennessBounds.width >= 160 &&
    snapshot.evennessBounds.height >= 220 &&
    snapshot.evennessFieldBounds.width >= 180 &&
    snapshot.evennessFieldBounds.height >= 240 &&
    snapshot.fretBounds.width >= 150 &&
    snapshot.fretBounds.height >= 150 &&
    snapshot.staffBounds.width >= 220 &&
    snapshot.staffBounds.height >= 120 &&
    snapshot.keyStaffBounds.width >= 380 &&
    snapshot.keyStaffBounds.height >= 90 &&
    snapshot.pianoStaffBounds.width >= 380 &&
    snapshot.pianoStaffBounds.height >= 140 &&
    snapshot.keyboardBounds.width >= 380 &&
    snapshot.keyboardBounds.height >= 100
  );
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
