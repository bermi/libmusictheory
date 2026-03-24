const statusEl = document.getElementById("status");
const atlasGrid = document.getElementById("atlas-grid");
const summaryMethodsEl = document.getElementById("summary-methods");
const sourceFrame = document.getElementById("qa-source");

const BITMAP_REVIEW_WIDTH = 840;
const textDecoder = new TextDecoder();
const BITMAP_TARGETS = {
  lmt_svg_clock_optc: { width: BITMAP_REVIEW_WIDTH, height: 840 },
  lmt_svg_optic_k_group: { width: BITMAP_REVIEW_WIDTH, height: 420 },
  lmt_svg_evenness_chart: { width: BITMAP_REVIEW_WIDTH, height: Math.round((BITMAP_REVIEW_WIDTH * 650) / 500) },
  lmt_svg_fret: { width: BITMAP_REVIEW_WIDTH, height: 840 },
  lmt_svg_fret_n: { width: BITMAP_REVIEW_WIDTH, height: 840 },
  lmt_svg_chord_staff: { width: BITMAP_REVIEW_WIDTH, height: Math.round((BITMAP_REVIEW_WIDTH * 126) / 210) },
  lmt_svg_key_staff: { width: BITMAP_REVIEW_WIDTH, height: Math.round((BITMAP_REVIEW_WIDTH * 126) / 520) },
};

const ATLAS_SAMPLES = {
  lmt_svg_clock_optc: { pcsMain: [0, 7] },
  lmt_svg_optic_k_group: { pcsMain: [0, 4, 7] },
  lmt_svg_fret: { frets: [1, 3, 3, 2, 1, 1] },
  lmt_svg_fret_n: { frets: [2, 0, 1, 0], stringCount: 4, windowStart: 0, visibleFrets: 4 },
  lmt_svg_chord_staff: { chordType: 0, chordRoot: 0 },
  lmt_svg_key_staff: { keyTonic: 0, keyQuality: 0 },
};

const IMAGE_METHODS = [
  { section: "SVG Diagram APIs", method: "lmt_svg_clock_optc", bitmapExport: "lmt_bitmap_clock_optc_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_optic_k_group", bitmapExport: "lmt_bitmap_optic_k_group_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_evenness_chart", bitmapExport: "lmt_bitmap_evenness_chart_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_fret", bitmapExport: "lmt_bitmap_fret_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_fret_n", bitmapExport: "lmt_bitmap_fret_n_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_chord_staff", bitmapExport: "lmt_bitmap_chord_staff_rgba" },
  { section: "SVG Diagram APIs", method: "lmt_svg_key_staff", bitmapExport: "lmt_bitmap_key_staff_rgba" },
];

function setStatus(message, tone = "ready") {
  statusEl.textContent = message;
  statusEl.style.color = tone === "error" ? "#b03620" : "#1d6b74";
}

function labelForIndex(index) {
  let value = index + 1;
  let out = "";
  while (value > 0) {
    value -= 1;
    out = String.fromCharCode(65 + (value % 26)) + out;
    value = Math.floor(value / 26);
  }
  return out;
}

function parseCsvIntegers(raw) {
  return raw
    .split(",")
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .map((token) => Number.parseInt(token, 10));
}

function readNumberInput(sourceDoc, id, fallback = 0) {
  const value = Number.parseInt(sourceDoc.getElementById(id)?.value ?? "", 10);
  return Number.isFinite(value) ? value : fallback;
}

function collectDefaults(sourceDoc) {
  return {
    pcsMain: parseCsvIntegers(sourceDoc.getElementById("pcs-main")?.value || "0,4,7"),
    chordType: readNumberInput(sourceDoc, "chord-type", 0),
    chordRoot: readNumberInput(sourceDoc, "chord-root", 0),
    keyTonic: readNumberInput(sourceDoc, "key-tonic", 0),
    keyQuality: readNumberInput(sourceDoc, "key-quality", 0),
    tuning: parseCsvIntegers(sourceDoc.getElementById("guitar-tuning")?.value || "40,45,50,55,59,64"),
    svgFrets: parseCsvIntegers(sourceDoc.getElementById("svg-frets")?.value || "-1,-1,10,9,8,-1"),
    windowStart: readNumberInput(sourceDoc, "svg-window-start", 0),
    visibleFrets: readNumberInput(sourceDoc, "svg-visible-frets", 4),
  };
}

function atlasSampleForMethod(method, defaults) {
  switch (method) {
    case "lmt_svg_clock_optc":
    case "lmt_svg_optic_k_group":
      return { pcsMain: ATLAS_SAMPLES[method].pcsMain.slice() };
    case "lmt_svg_fret":
      return { svgFrets: ATLAS_SAMPLES[method].frets.slice() };
    case "lmt_svg_fret_n":
      return {
        svgFrets: ATLAS_SAMPLES[method].frets.slice(),
        windowStart: ATLAS_SAMPLES[method].windowStart,
        visibleFrets: ATLAS_SAMPLES[method].visibleFrets,
        stringCount: ATLAS_SAMPLES[method].stringCount,
      };
    case "lmt_svg_chord_staff":
      return {
        chordType: ATLAS_SAMPLES[method].chordType,
        chordRoot: ATLAS_SAMPLES[method].chordRoot,
      };
    case "lmt_svg_key_staff":
      return {
        keyTonic: ATLAS_SAMPLES[method].keyTonic,
        keyQuality: ATLAS_SAMPLES[method].keyQuality,
      };
    default:
      return defaults;
  }
}

function createScratchArena(wasm, memory) {
  const base = wasm.lmt_wasm_scratch_ptr();
  const size = wasm.lmt_wasm_scratch_size();
  let top = 0;
  return {
    reset() {
      top = 0;
    },
    alloc(bytes, align = 1) {
      const mask = align - 1;
      if (mask > 0) top = (top + mask) & ~mask;
      if (top + bytes > size) {
        throw new Error(`scratch overflow: need ${bytes} bytes, have ${size - top}`);
      }
      const ptr = base + top;
      top += bytes;
      return ptr;
    },
    u8() {
      return new Uint8Array(memory.buffer);
    },
    i8() {
      return new Int8Array(memory.buffer);
    },
  };
}

function writeU8Array(arena, values) {
  const ptr = arena.alloc(values.length, 1);
  arena.u8().set(values, ptr);
  return ptr;
}

function writeI8Array(arena, values) {
  const ptr = arena.alloc(values.length, 1);
  arena.i8().set(values, ptr);
  return ptr;
}

function copyRgba(memory, ptr, byteLength) {
  return new Uint8ClampedArray(new Uint8Array(memory.buffer, ptr, byteLength));
}

function readUtf8(memory, ptr, byteLength) {
  return textDecoder.decode(new Uint8Array(memory.buffer, ptr, byteLength));
}

async function bitmapUrlFromRgba(rgba, width, height) {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  ctx.putImageData(new ImageData(rgba, width, height), 0, 0);
  const blob = await new Promise((resolve, reject) => {
    canvas.toBlob((value) => {
      if (value) resolve(value);
      else reject(new Error("failed to encode bitmap blob"));
    }, "image/png");
  });
  return URL.createObjectURL(blob);
}

async function rasterizeSvgMarkup(svgMarkup, width, height) {
  const blob = new Blob([svgMarkup], { type: "image/svg+xml;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  try {
    const image = new Image();
    image.decoding = "sync";
    const loaded = new Promise((resolve, reject) => {
      image.onload = () => resolve();
      image.onerror = () => reject(new Error("failed to rasterize SVG reference"));
    });
    image.src = url;
    await loaded;
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(image, 0, 0, width, height);
    return ctx.getImageData(0, 0, width, height).data;
  } finally {
    URL.revokeObjectURL(url);
  }
}

function compareRgba(candidate, reference) {
  const len = Math.min(candidate.length, reference.length);
  let totalDiff = 0;
  let changedPixels = 0;
  let candidateInk = 0;
  for (let i = 0; i < len; i += 4) {
    let pixelChanged = false;
    for (let channel = 0; channel < 4; channel += 1) {
      const diff = Math.abs(candidate[i + channel] - reference[i + channel]);
      totalDiff += diff;
      if (diff > 8) pixelChanged = true;
    }
    if (pixelChanged) changedPixels += 1;
    if (candidate[i + 3] > 0) candidateInk += 1;
  }
  return {
    drift: len > 0 ? totalDiff / (len * 255) : 1,
    changedPixels,
    candidateInkPixels: candidateInk,
  };
}

function buildMainSet(wasm, arena, values) {
  const pcsPtr = writeU8Array(arena, values);
  return wasm.lmt_pcs_from_list(pcsPtr, values.length);
}

function renderClockBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_clock_optc;
  const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_clock_optc_rgba(mainSet, dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_clock_optc_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `set=${defaults.pcsMain.join(",")} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderOpticKBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_optic_k_group;
  const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_optic_k_group_rgba(mainSet, dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_optic_k_group_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `set=${defaults.pcsMain.join(",")} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderEvennessBitmap(wasm, memory, arena) {
  const dims = BITMAP_TARGETS.lmt_svg_evenness_chart;
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_evenness_chart_rgba(dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_evenness_chart_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `bitmap=${dims.width}x${dims.height}`,
  };
}

function renderFretBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_fret;
  const fretsPtr = writeI8Array(arena, defaults.svgFrets);
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_fret_rgba(fretsPtr, dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_fret_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `frets=${defaults.svgFrets.join(",")} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderFretNBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_fret_n;
  const fretsPtr = writeI8Array(arena, defaults.svgFrets);
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_fret_n_rgba(
    fretsPtr,
    defaults.stringCount ?? defaults.svgFrets.length,
    defaults.windowStart,
    defaults.visibleFrets,
    dims.width,
    dims.height,
    rgbaPtr,
    rgbaBytes,
  );
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_fret_n_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `frets=${defaults.svgFrets.join(",")} | window_start=${defaults.windowStart} | visible_frets=${defaults.visibleFrets} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderChordStaffBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_chord_staff;
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_chord_staff_rgba(defaults.chordType, defaults.chordRoot, dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_chord_staff_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `chord_type=${defaults.chordType} | chord_root=${defaults.chordRoot} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderKeyStaffBitmap(wasm, memory, arena, defaults) {
  const dims = BITMAP_TARGETS.lmt_svg_key_staff;
  const rgbaBytes = dims.width * dims.height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 4);
  const written = wasm.lmt_bitmap_key_staff_rgba(defaults.keyTonic, defaults.keyQuality, dims.width, dims.height, rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) throw new Error(`lmt_bitmap_key_staff_rgba wrote ${written}/${rgbaBytes}`);
  return {
    width: dims.width,
    height: dims.height,
    rgba: copyRgba(memory, rgbaPtr, rgbaBytes),
    meta: `key_tonic=${defaults.keyTonic} | key_quality=${defaults.keyQuality === 0 ? "major" : "minor"} | bitmap=${dims.width}x${dims.height}`,
  };
}

function renderSvgString(entry, wasm, memory, defaults) {
  const arena = createScratchArena(wasm, memory);
  let total = 0;
  switch (entry.method) {
    case "lmt_svg_clock_optc": {
      const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
      total = wasm.lmt_svg_clock_optc(mainSet, 0, 0);
      break;
    }
    case "lmt_svg_optic_k_group": {
      const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
      total = wasm.lmt_svg_optic_k_group(mainSet, 0, 0);
      break;
    }
    case "lmt_svg_evenness_chart":
      total = wasm.lmt_svg_evenness_chart(0, 0);
      break;
    case "lmt_svg_fret": {
      const fretsPtr = writeI8Array(arena, defaults.svgFrets);
      total = wasm.lmt_svg_fret(fretsPtr, 0, 0);
      break;
    }
    case "lmt_svg_fret_n": {
      const fretsPtr = writeI8Array(arena, defaults.svgFrets);
      total = wasm.lmt_svg_fret_n(
        fretsPtr,
        defaults.stringCount ?? defaults.svgFrets.length,
        defaults.windowStart,
        defaults.visibleFrets,
        0,
        0,
      );
      break;
    }
    case "lmt_svg_chord_staff":
      total = wasm.lmt_svg_chord_staff(defaults.chordType, defaults.chordRoot, 0, 0);
      break;
    case "lmt_svg_key_staff":
      total = wasm.lmt_svg_key_staff(defaults.keyTonic, defaults.keyQuality, 0, 0);
      break;
    default:
      throw new Error(`unsupported svg method ${entry.method}`);
  }
  if (total <= 0) throw new Error(`${entry.method} returned empty SVG`);
  const svgPtr = arena.alloc(total + 1, 1);
  let written = 0;
  switch (entry.method) {
    case "lmt_svg_clock_optc": {
      const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
      written = wasm.lmt_svg_clock_optc(mainSet, svgPtr, total + 1);
      break;
    }
    case "lmt_svg_optic_k_group": {
      const mainSet = buildMainSet(wasm, arena, defaults.pcsMain);
      written = wasm.lmt_svg_optic_k_group(mainSet, svgPtr, total + 1);
      break;
    }
    case "lmt_svg_evenness_chart":
      written = wasm.lmt_svg_evenness_chart(svgPtr, total + 1);
      break;
    case "lmt_svg_fret": {
      const fretsPtr = writeI8Array(arena, defaults.svgFrets);
      written = wasm.lmt_svg_fret(fretsPtr, svgPtr, total + 1);
      break;
    }
    case "lmt_svg_fret_n": {
      const fretsPtr = writeI8Array(arena, defaults.svgFrets);
      written = wasm.lmt_svg_fret_n(
        fretsPtr,
        defaults.stringCount ?? defaults.svgFrets.length,
        defaults.windowStart,
        defaults.visibleFrets,
        svgPtr,
        total + 1,
      );
      break;
    }
    case "lmt_svg_chord_staff":
      written = wasm.lmt_svg_chord_staff(defaults.chordType, defaults.chordRoot, svgPtr, total + 1);
      break;
    case "lmt_svg_key_staff":
      written = wasm.lmt_svg_key_staff(defaults.keyTonic, defaults.keyQuality, svgPtr, total + 1);
      break;
    default:
      break;
  }
  if (written !== total) throw new Error(`${entry.method} wrote ${written}/${total} SVG bytes`);
  return readUtf8(memory, svgPtr, total);
}

async function renderBitmapCard(entry, wasm, memory, defaults) {
  const arena = createScratchArena(wasm, memory);
  let rendered;
  switch (entry.method) {
    case "lmt_svg_clock_optc":
      rendered = renderClockBitmap(wasm, memory, arena, defaults);
      break;
    case "lmt_svg_optic_k_group":
      rendered = renderOpticKBitmap(wasm, memory, arena, defaults);
      break;
    case "lmt_svg_evenness_chart":
      rendered = renderEvennessBitmap(wasm, memory, arena);
      break;
    case "lmt_svg_fret":
      rendered = renderFretBitmap(wasm, memory, arena, defaults);
      break;
    case "lmt_svg_fret_n":
      rendered = renderFretNBitmap(wasm, memory, arena, defaults);
      break;
    case "lmt_svg_chord_staff":
      rendered = renderChordStaffBitmap(wasm, memory, arena, defaults);
      break;
    case "lmt_svg_key_staff":
      rendered = renderKeyStaffBitmap(wasm, memory, arena, defaults);
      break;
    default:
      throw new Error(`unsupported image method ${entry.method}`);
  }
  const pngUrl = await bitmapUrlFromRgba(rendered.rgba, rendered.width, rendered.height);
  const svgMarkup = renderSvgString(entry, wasm, memory, defaults);
  const referenceRgba = await rasterizeSvgMarkup(svgMarkup, rendered.width, rendered.height);
  const comparison = compareRgba(rendered.rgba, referenceRgba);
  return {
    ...entry,
    rendered: true,
    bitmapUrl: pngUrl,
    bitmapWidth: rendered.width,
    bitmapHeight: rendered.height,
    meta: rendered.meta,
    referenceHasBarre: svgMarkup.includes('class="barre"'),
    comparison,
  };
}

function renderVisualCard(card, index) {
  const article = document.createElement("article");
  article.className = "atlas-card";
  article.dataset.kind = "bitmap";
  article.dataset.method = card.method;

  const header = document.createElement("div");
  header.className = "atlas-card-header";

  const letter = document.createElement("div");
  letter.className = "atlas-letter";
  letter.textContent = labelForIndex(index);

  const textWrap = document.createElement("div");
  const section = document.createElement("p");
  section.className = "atlas-section";
  section.textContent = card.section;
  const title = document.createElement("h2");
  title.textContent = card.method;
  textWrap.append(section, title);
  header.append(letter, textWrap);
  article.append(header);

  const link = document.createElement("a");
  link.className = "atlas-bitmap-link";
  link.href = card.bitmapUrl;
  link.target = "_blank";
  link.rel = "noopener noreferrer";
  link.title = `Open ${card.method} bitmap`;

  const image = document.createElement("img");
  image.className = "atlas-bitmap";
  image.src = card.bitmapUrl;
  image.alt = `${card.method} bitmap`;
  image.width = card.bitmapWidth;
  image.height = card.bitmapHeight;
  image.loading = "eager";
  image.decoding = "sync";
  image.dataset.bitmapWidth = String(card.bitmapWidth);
  image.dataset.bitmapHeight = String(card.bitmapHeight);
  link.append(image);
  article.append(link);

  const meta = document.createElement("p");
  meta.className = "atlas-meta";
  meta.textContent = `${card.meta} | drift=${card.comparison.drift.toFixed(8)} | changed=${card.comparison.changedPixels} | ink=${card.comparison.candidateInkPixels} | open=png`;
  article.append(meta);

  return article;
}

async function waitForSourceReady(frame) {
  const deadline = Date.now() + 300000;
  while (Date.now() < deadline) {
    const doc = frame.contentDocument;
    const win = frame.contentWindow;
    if (doc && win) {
      const status = doc.getElementById("status")?.textContent || "";
      const docsWasm = win.__lmtDocsWasm;
      if (status.includes("All sections rendered successfully.") && docsWasm?.exports && docsWasm?.memory) {
        return { sourceDoc: doc, docsWasm };
      }
      if (status.includes("Failed to initialize:") || status.includes("Error:")) {
        throw new Error(status);
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error("timed out waiting for docs source to render");
}

async function buildAtlas() {
  setStatus("Waiting for docs source render…");
  const { sourceDoc, docsWasm } = await waitForSourceReady(sourceFrame);
  const wasm = docsWasm.exports;
  const memory = docsWasm.memory;
  if (!wasm.lmt_raster_is_enabled || wasm.lmt_raster_is_enabled() !== 1) {
    throw new Error("wasm-docs bundle does not expose raster backend");
  }

  const defaults = collectDefaults(sourceDoc);
  const cards = [];
  for (const entry of IMAGE_METHODS) {
    cards.push(await renderBitmapCard(entry, wasm, memory, atlasSampleForMethod(entry.method, defaults)));
  }

  atlasGrid.innerHTML = "";
  cards.forEach((card, index) => {
    atlasGrid.append(renderVisualCard(card, index));
  });

  const imageWidths = Array.from(atlasGrid.querySelectorAll(".atlas-bitmap"), (img) => Math.round(img.getBoundingClientRect().width));
  const maxDrift = Math.max(...cards.map((card) => card.comparison.drift));
  summaryMethodsEl.textContent = String(cards.length);
  window.__lmtQaAtlasSummary = {
    ready: true,
    cardCount: cards.length,
    svgCount: 0,
    imageMethodCount: cards.length,
    renderedImageCount: cards.length,
    rasterEnabled: true,
    displayWidths: imageWidths,
    maxDrift,
    methods: cards.map((card, index) => ({
      label: labelForIndex(index),
      method: card.method,
      kind: "bitmap",
      section: card.section,
      rendered: true,
      bitmapWidth: card.bitmapWidth,
      bitmapHeight: card.bitmapHeight,
      drift: card.comparison.drift,
      changedPixels: card.comparison.changedPixels,
      candidateInkPixels: card.comparison.candidateInkPixels,
      referenceHasBarre: card.referenceHasBarre,
    })),
  };
  setStatus(`QA atlas ready with ${cards.length} labeled bitmap image methods.`);
}

buildAtlas().catch((error) => {
  window.__lmtQaAtlasSummary = { ready: false, error: error.message };
  setStatus(`QA atlas failed: ${error.message}`, "error");
});
