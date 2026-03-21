const NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
const MODE_AEOLIAN = 5;
const SCALE_DIATONIC = 0;
const GUIDE_DOT_BYTES = 8;
const decoder = new TextDecoder();
const encoder = new TextEncoder();
const CUSTOM_PRESET_VALUE = "custom";
const captureMode = new URLSearchParams(window.location.search).get("capture") === "1";

if (captureMode) {
  document.documentElement.dataset.captureMode = "1";
}

const REQUIRED_EXPORTS = [
  "memory",
  "lmt_pcs_from_list",
  "lmt_pcs_to_list",
  "lmt_pcs_cardinality",
  "lmt_pcs_transpose",
  "lmt_pcs_invert",
  "lmt_pcs_complement",
  "lmt_prime_form",
  "lmt_forte_prime",
  "lmt_is_cluster_free",
  "lmt_evenness_distance",
  "lmt_scale",
  "lmt_mode",
  "lmt_spell_note",
  "lmt_spell_note_parts",
  "lmt_chord",
  "lmt_chord_name",
  "lmt_roman_numeral",
  "lmt_roman_numeral_parts",
  "lmt_fret_to_midi_n",
  "lmt_midi_to_fret_positions_n",
  "lmt_generate_voicings_n",
  "lmt_pitch_class_guide_n",
  "lmt_frets_to_url_n",
  "lmt_url_to_frets_n",
  "lmt_svg_clock_optc",
  "lmt_svg_fret_n",
  "lmt_svg_chord_staff",
];

const statusEl = document.getElementById("status");
const pcsToggleGrid = document.getElementById("pcs-toggle-grid");

const setPresetEl = document.getElementById("set-preset");
const keyPresetEl = document.getElementById("key-preset");
const chordPresetEl = document.getElementById("chord-preset");
const progressionPresetEl = document.getElementById("progression-preset");
const comparePresetEl = document.getElementById("compare-preset");
const fretPresetEl = document.getElementById("fret-preset");

const keyTonicEl = document.getElementById("key-tonic");
const keyQualityEl = document.getElementById("key-quality");
const chordRootEl = document.getElementById("chord-root");
const chordTypeEl = document.getElementById("chord-type");
const chordKeyTonicEl = document.getElementById("chord-key-tonic");
const chordKeyQualityEl = document.getElementById("chord-key-quality");
const fretTuningEl = document.getElementById("fret-tuning");
const fretFretsEl = document.getElementById("fret-frets");
const fretWindowStartEl = document.getElementById("fret-window-start");
const fretVisibleFretsEl = document.getElementById("fret-visible-frets");
const fretMaxFretEl = document.getElementById("fret-max-fret");
const fretMaxSpanEl = document.getElementById("fret-max-span");

const setCaptionEl = document.getElementById("set-caption");
const keyCaptionEl = document.getElementById("key-caption");
const chordCaptionEl = document.getElementById("chord-caption");
const progressionCaptionEl = document.getElementById("progression-caption");
const compareCaptionEl = document.getElementById("compare-caption");
const fretCaptionEl = document.getElementById("fret-caption");

const setSummaryEl = document.getElementById("set-summary");
const setClockEl = document.getElementById("set-clock");
const keyNotesEl = document.getElementById("key-notes");
const keyDegreesEl = document.getElementById("key-degrees");
const keyClockEl = document.getElementById("key-clock");
const chordSummaryEl = document.getElementById("chord-summary");
const chordNotesEl = document.getElementById("chord-notes");
const chordClockEl = document.getElementById("chord-clock");
const chordStaffEl = document.getElementById("chord-staff");
const progressionSummaryEl = document.getElementById("progression-summary");
const progressionCardsEl = document.getElementById("progression-cards");
const progressionClockEl = document.getElementById("progression-clock");
const progressionNotesEl = document.getElementById("progression-notes");
const compareLeftClockEl = document.getElementById("compare-left-clock");
const compareOverlapClockEl = document.getElementById("compare-overlap-clock");
const compareRightClockEl = document.getElementById("compare-right-clock");
const compareSummaryEl = document.getElementById("compare-summary");
const compareChipsEl = document.getElementById("compare-chips");
const fretSvgEl = document.getElementById("fret-svg");
const fretSummaryEl = document.getElementById("fret-summary");
const fretNotesEl = document.getElementById("fret-notes");
const fretVoicingsEl = document.getElementById("fret-voicings");

let wasm = null;
let memory = null;
let manifest = null;
let currentSetPreset = 0;
let currentKeyPreset = 0;
let currentChordPreset = 0;
let currentProgressionPreset = 0;
let currentComparePreset = 0;
let currentFretPreset = 0;
let jsScratchBase = 0;
let jsScratchTop = 0;
let jsScratchLimit = 0;

const gallerySummary = {
  ready: false,
  manifestLoaded: false,
  sceneCount: 0,
  errors: [],
  scenes: {
    set: {},
    key: {},
    chord: {},
    progression: {},
    compare: {},
    fret: {},
  },
};
window.__lmtGallerySummary = gallerySummary;

function setStatus(message, tone = "ready") {
  statusEl.textContent = message;
  statusEl.style.color = tone === "error" ? "#b03620" : "#1e7c84";
}

class ScratchArena {
  constructor() {
    if (jsScratchBase === 0) {
      jsScratchBase = memory.buffer.byteLength;
      ensureMemory(jsScratchBase + 65536);
      jsScratchTop = jsScratchBase;
      jsScratchLimit = memory.buffer.byteLength;
    }
    this.mark = jsScratchTop;
  }

  alloc(size, align = 1) {
    const mask = align - 1;
    let next = jsScratchTop;
    if (mask > 0) {
      next = (next + mask) & ~mask;
    }
    if (next + size > jsScratchLimit) {
      ensureMemory(next + size + 65536);
      jsScratchLimit = memory.buffer.byteLength;
    }
    const out = next;
    jsScratchTop = next + size;
    return out;
  }

  release() {
    jsScratchTop = this.mark;
  }
}

function ensureMemory(requiredBytes) {
  const pageSize = 65536;
  if (memory.buffer.byteLength >= requiredBytes) return;
  const currentPages = memory.buffer.byteLength / pageSize;
  const neededPages = Math.ceil(requiredBytes / pageSize);
  memory.grow(neededPages - currentPages);
}

function u8() {
  return new Uint8Array(memory.buffer);
}

function i8() {
  return new Int8Array(memory.buffer);
}

function readCString(ptr) {
  const bytes = u8();
  let end = ptr;
  while (bytes[end] !== 0) end += 1;
  return decoder.decode(bytes.subarray(ptr, end));
}

function writeU8Array(arena, values) {
  const ptr = arena.alloc(values.length || 1, 1);
  if (values.length > 0) u8().set(values, ptr);
  return ptr;
}

function writeI8Array(arena, values) {
  const ptr = arena.alloc(values.length || 1, 1);
  if (values.length > 0) i8().set(values, ptr);
  return ptr;
}

function writeCString(arena, text) {
  const bytes = encoder.encode(text);
  const ptr = arena.alloc(bytes.length + 1, 1);
  u8().set(bytes, ptr);
  u8()[ptr + bytes.length] = 0;
  return ptr;
}

function parseCsvIntegers(raw, min, max) {
  const values = raw
    .split(",")
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .map((token) => Number.parseInt(token, 10));

  if (values.some((value) => Number.isNaN(value) || value < min || value > max)) {
    throw new Error(`Invalid csv list: ${raw}`);
  }
  return values;
}

function pcsFromList(arena, values) {
  const ptr = writeU8Array(arena, values);
  return wasm.lmt_pcs_from_list(ptr, values.length);
}

function pcsToList(arena, setValue) {
  const outPtr = arena.alloc(12, 1);
  const count = wasm.lmt_pcs_to_list(setValue, outPtr);
  return Array.from(u8().subarray(outPtr, outPtr + count));
}

function orderedMembersFromSet(setValue, tonic = 0) {
  const ordered = [];
  for (let step = 0; step < 12; step += 1) {
    const pc = (tonic + step) % 12;
    if ((setValue & (1 << pc)) !== 0) ordered.push(pc);
  }
  return ordered;
}

function noteName(pc) {
  return NOTE_NAMES[pc % 12];
}

function spellNote(pc, tonic, quality) {
  return readCString(wasm.lmt_spell_note_parts(pc % 12, tonic % 12, quality));
}

function svgString(arena, renderFn, ...args) {
  const required = renderFn(...args, 0, 0);
  const bufPtr = arena.alloc(required + 1, 1);
  renderFn(...args, bufPtr, required + 1);
  return readCString(bufPtr);
}

function normalizeSvgPreview(host, options = {}) {
  const {
    maxHeight = 320,
    squareWidth = 320,
    mediumWidth = 480,
    wideWidth = 720,
    ultraWideWidth = 920,
    padXRatio = 0.08,
    padYRatio = 0.12,
    minPad = 6,
  } = options;
  const svgs = host.querySelectorAll("svg");
  for (const svg of svgs) {
    svg.style.display = "block";
    svg.style.maxWidth = "100%";
    svg.style.maxHeight = `${maxHeight}px`;
    svg.style.height = "auto";
    if (!svg.dataset.originalViewBox) {
      const originalViewBox = svg.getAttribute("viewBox");
      if (originalViewBox) svg.dataset.originalViewBox = originalViewBox;
    }

    try {
      const bbox = svg.getBBox();
      if (!Number.isFinite(bbox.width) || !Number.isFinite(bbox.height) || bbox.width <= 0 || bbox.height <= 0) {
        svg.dataset.previewNormalized = "0";
        continue;
      }

      const aspect = bbox.width / bbox.height;
      const availableWidth = Math.max(180, host.clientWidth - 32);
      let targetWidth = mediumWidth;
      if (aspect <= 1.15) {
        targetWidth = squareWidth;
      } else if (aspect <= 2.4) {
        targetWidth = mediumWidth;
      } else if (aspect <= 4.4) {
        targetWidth = wideWidth;
      } else {
        targetWidth = ultraWideWidth;
      }

      const padX = Math.max(minPad, bbox.width * padXRatio);
      const padY = Math.max(minPad, bbox.height * padYRatio);
      svg.style.width = `${Math.min(availableWidth, targetWidth)}px`;
      svg.setAttribute(
        "viewBox",
        [
          (bbox.x - padX).toFixed(2),
          (bbox.y - padY).toFixed(2),
          (bbox.width + padX * 2).toFixed(2),
          (bbox.height + padY * 2).toFixed(2),
        ].join(" "),
      );
      svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
      svg.dataset.previewNormalized = "1";
      svg.dataset.previewAspect = aspect.toFixed(3);
    } catch (_error) {
      svg.dataset.previewNormalized = "0";
    }
  }
}

function updateSummaryScene(name, data) {
  gallerySummary.scenes[name] = { ...data, rendered: true };
}

function setChipRow(target, items, klass = "chip") {
  target.innerHTML = items.map((one) => `<span class="${klass}">${escapeHtml(one)}</span>`).join("");
}

function createNoteSelectors(select) {
  select.innerHTML = NOTE_NAMES.map((name, index) => `<option value="${index}">${name}</option>`).join("");
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function friendlyChordName(name) {
  return !name || name === "Unknown" ? "set-class color" : name;
}

function manifestList(key) {
  const value = manifest?.[key];
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`Preset manifest entry missing or empty: ${key}`);
  }
  return value;
}

async function loadManifest() {
  const response = await fetch("./gallery-presets.json");
  if (!response.ok) {
    throw new Error(`Failed to fetch gallery-presets.json: ${response.status}`);
  }
  const loaded = await response.json();
  const requiredLists = ["setPresets", "keyPresets", "chordPresets", "progressionPresets", "comparePresets", "fretPresets"];
  for (const key of requiredLists) {
    if (!Array.isArray(loaded[key]) || loaded[key].length === 0) {
      throw new Error(`Invalid gallery manifest: ${key}`);
    }
  }
  if (!loaded.meta || Number(loaded.meta.sceneCount) < 6) {
    throw new Error("Invalid gallery manifest: meta.sceneCount must be >= 6");
  }
  return loaded;
}

function populatePresetSelect(select, presets) {
  const options = [`<option value="${CUSTOM_PRESET_VALUE}">Custom</option>`];
  presets.forEach((preset, index) => {
    options.push(`<option value="${index}">${escapeHtml(preset.label)}</option>`);
  });
  select.innerHTML = options.join("");
}

function setPresetSelection(select, index) {
  select.value = String(index);
}

function markPresetCustom(select, captionEl, noun) {
  select.value = CUSTOM_PRESET_VALUE;
  captionEl.textContent = `Custom — manual ${noun} selection using only the stable public API.`;
}

function updateSceneCaption(captionEl, preset) {
  captionEl.textContent = `${preset.label} — ${preset.story}`;
}

function buildToggleGrid() {
  pcsToggleGrid.innerHTML = NOTE_NAMES.map(
    (name, pc) => `<button class="pc-toggle" data-pc="${pc}" type="button" aria-pressed="false">${name}</button>`,
  ).join("");
  pcsToggleGrid.addEventListener("click", (event) => {
    const button = event.target.closest(".pc-toggle");
    if (!button) return;
    button.classList.toggle("is-active");
    button.setAttribute("aria-pressed", button.classList.contains("is-active") ? "true" : "false");
    markPresetCustom(setPresetEl, setCaptionEl, "pitch-class");
    renderSetScene();
  });
}

function applySetPreset(index) {
  const presets = manifestList("setPresets");
  currentSetPreset = index % presets.length;
  const preset = presets[currentSetPreset];
  const active = new Set(preset.pcs);
  for (const button of pcsToggleGrid.querySelectorAll(".pc-toggle")) {
    const pc = Number.parseInt(button.dataset.pc, 10);
    const isActive = active.has(pc);
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", isActive ? "true" : "false");
  }
  setPresetSelection(setPresetEl, currentSetPreset);
  updateSceneCaption(setCaptionEl, preset);
}

function applyKeyPreset(index) {
  const presets = manifestList("keyPresets");
  currentKeyPreset = index % presets.length;
  const preset = presets[currentKeyPreset];
  keyTonicEl.value = String(preset.tonic);
  keyQualityEl.value = String(preset.quality);
  setPresetSelection(keyPresetEl, currentKeyPreset);
  updateSceneCaption(keyCaptionEl, preset);
}

function applyChordPreset(index) {
  const presets = manifestList("chordPresets");
  currentChordPreset = index % presets.length;
  const preset = presets[currentChordPreset];
  chordRootEl.value = String(preset.root);
  chordTypeEl.value = String(preset.type);
  chordKeyTonicEl.value = String(preset.keyTonic);
  chordKeyQualityEl.value = String(preset.keyQuality);
  setPresetSelection(chordPresetEl, currentChordPreset);
  updateSceneCaption(chordCaptionEl, preset);
}

function applyProgressionPreset(index) {
  const presets = manifestList("progressionPresets");
  currentProgressionPreset = index % presets.length;
  const preset = presets[currentProgressionPreset];
  setPresetSelection(progressionPresetEl, currentProgressionPreset);
  updateSceneCaption(progressionCaptionEl, preset);
}

function applyComparePreset(index) {
  const presets = manifestList("comparePresets");
  currentComparePreset = index % presets.length;
  const preset = presets[currentComparePreset];
  setPresetSelection(comparePresetEl, currentComparePreset);
  updateSceneCaption(compareCaptionEl, preset);
}

function applyFretPreset(index) {
  const presets = manifestList("fretPresets");
  currentFretPreset = index % presets.length;
  const preset = presets[currentFretPreset];
  fretTuningEl.value = preset.tuning.join(",");
  fretFretsEl.value = preset.frets.join(",");
  fretWindowStartEl.value = String(preset.windowStart);
  fretVisibleFretsEl.value = String(preset.visibleFrets);
  fretMaxFretEl.value = String(preset.maxFret);
  fretMaxSpanEl.value = String(preset.maxSpan);
  setPresetSelection(fretPresetEl, currentFretPreset);
  updateSceneCaption(fretCaptionEl, preset);
}

function currentSetList() {
  return Array.from(pcsToggleGrid.querySelectorAll(".pc-toggle.is-active"), (button) =>
    Number.parseInt(button.dataset.pc, 10),
  ).sort((a, b) => a - b);
}

function buildScaleOrbit(tonic, quality) {
  const setValue = quality === 0 ? wasm.lmt_scale(SCALE_DIATONIC, tonic) : wasm.lmt_mode(MODE_AEOLIAN, tonic);
  const ordered = orderedMembersFromSet(setValue, tonic);
  const names = ordered.map((pc) => spellNote(pc, tonic, quality));
  return { tonic, quality, setValue, ordered, names };
}

function buildTriadFromDegree(arena, orbit, degreeIndex) {
  const pcsList = [
    orbit.ordered[degreeIndex % orbit.ordered.length],
    orbit.ordered[(degreeIndex + 2) % orbit.ordered.length],
    orbit.ordered[(degreeIndex + 4) % orbit.ordered.length],
  ];
  const setValue = pcsFromList(arena, pcsList);
  return {
    degreeIndex,
    pcsList,
    setValue,
    roman: readCString(wasm.lmt_roman_numeral_parts(setValue, orbit.tonic, orbit.quality)),
    chordName: friendlyChordName(readCString(wasm.lmt_chord_name(setValue))),
    noteNames: pcsList.map((pc) => spellNote(pc, orbit.tonic, orbit.quality)),
  };
}

function describeRelation(leftSet, rightSet) {
  let transposeMatch = null;
  let inversionMatch = null;
  const inverted = wasm.lmt_pcs_invert(leftSet);
  for (let t = 0; t < 12; t += 1) {
    if (transposeMatch == null && wasm.lmt_pcs_transpose(leftSet, t) === rightSet) {
      transposeMatch = t;
    }
    if (inversionMatch == null && wasm.lmt_pcs_transpose(inverted, t) === rightSet) {
      inversionMatch = t;
    }
  }
  return { transposeMatch, inversionMatch };
}

function renderSetScene() {
  const pcsList = currentSetList();
  if (pcsList.length === 0) {
    setSummaryEl.textContent = "Select at least one pitch class.";
    setClockEl.innerHTML = "";
    updateSummaryScene("set", { selectedCount: 0, setHex: "0x000" });
    return;
  }

  const arena = new ScratchArena();
  try {
    const setValue = pcsFromList(arena, pcsList);
    const transposed = wasm.lmt_pcs_transpose(setValue, 1);
    const inverted = wasm.lmt_pcs_invert(setValue);
    const complement = wasm.lmt_pcs_complement(setValue);
    const prime = wasm.lmt_prime_form(setValue);
    const fortePrime = wasm.lmt_forte_prime(setValue);
    const clusterFree = wasm.lmt_is_cluster_free(setValue) === 1;
    const evenness = wasm.lmt_evenness_distance(setValue);
    const chordName = friendlyChordName(readCString(wasm.lmt_chord_name(setValue)));
    const svg = svgString(arena, wasm.lmt_svg_clock_optc, setValue);

    setSummaryEl.textContent = [
      `set: 0x${setValue.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, setValue))}`,
      `cardinality: ${wasm.lmt_pcs_cardinality(setValue)}`,
      `prime: 0x${prime.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, prime))}`,
      `forte prime: 0x${fortePrime.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, fortePrime))}`,
      `transpose +1: ${JSON.stringify(pcsToList(arena, transposed))}`,
      `invert: ${JSON.stringify(pcsToList(arena, inverted))}`,
      `complement: ${JSON.stringify(pcsToList(arena, complement))}`,
      `cluster-free: ${clusterFree ? "yes" : "no"}`,
      `evenness distance: ${evenness.toFixed(6)}`,
      `chord reading: ${chordName}`,
    ].join("\n");
    setClockEl.innerHTML = svg;
    normalizeSvgPreview(setClockEl, { maxHeight: 420, squareWidth: 420, mediumWidth: 520 });
    updateSummaryScene("set", {
      selectedCount: pcsList.length,
      setHex: `0x${setValue.toString(16).padStart(3, "0")}`,
      chordName,
      primeHex: `0x${prime.toString(16).padStart(3, "0")}`,
    });
  } finally {
    arena.release();
  }
}

function renderKeyScene() {
  const arena = new ScratchArena();
  try {
    const tonic = Number.parseInt(keyTonicEl.value, 10);
    const quality = Number.parseInt(keyQualityEl.value, 10);
    const orbit = buildScaleOrbit(tonic, quality);
    const degreeCards = [];

    for (let i = 0; i < orbit.ordered.length; i += 1) {
      const triad = buildTriadFromDegree(arena, orbit, i);
      degreeCards.push(
        `<article class="degree-card"><strong>${escapeHtml(triad.roman)}</strong><div>${escapeHtml(triad.chordName)}</div><div>${escapeHtml(triad.noteNames.join(" · "))}</div></article>`,
      );
    }

    setChipRow(keyNotesEl, orbit.names);
    keyDegreesEl.innerHTML = degreeCards.join("");
    keyClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, orbit.setValue);
    normalizeSvgPreview(keyClockEl, { maxHeight: 440, squareWidth: 440, mediumWidth: 560 });

    updateSummaryScene("key", {
      tonic: noteName(tonic),
      quality: quality === 0 ? "major" : "minor",
      noteCount: orbit.ordered.length,
      degrees: degreeCards.length,
    });
  } finally {
    arena.release();
  }
}

function renderChordScene() {
  const arena = new ScratchArena();
  try {
    const root = Number.parseInt(chordRootEl.value, 10);
    const chordType = Number.parseInt(chordTypeEl.value, 10);
    const keyTonic = Number.parseInt(chordKeyTonicEl.value, 10);
    const keyQuality = Number.parseInt(chordKeyQualityEl.value, 10);

    const chordSet = wasm.lmt_chord(chordType, root);
    const orderedNotes = orderedMembersFromSet(chordSet, root).map((pc) => spellNote(pc, keyTonic, keyQuality));
    const chordName = friendlyChordName(readCString(wasm.lmt_chord_name(chordSet)));
    const roman = readCString(wasm.lmt_roman_numeral_parts(chordSet, keyTonic, keyQuality));
    const prime = wasm.lmt_prime_form(chordSet);
    const fortePrime = wasm.lmt_forte_prime(chordSet);
    const keySet = buildScaleOrbit(keyTonic, keyQuality).setValue;
    const inKey = (chordSet & keySet) === chordSet;

    chordSummaryEl.textContent = [
      `chord: ${chordName}`,
      `roman: ${roman}`,
      `set: 0x${chordSet.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, chordSet))}`,
      `prime: 0x${prime.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, prime))}`,
      `forte prime: 0x${fortePrime.toString(16).padStart(3, "0")}`,
      `inside key orbit: ${inKey ? "yes" : "no"}`,
    ].join("\n");
    setChipRow(chordNotesEl, orderedNotes);

    chordClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, chordSet);
    normalizeSvgPreview(chordClockEl, { maxHeight: 360, squareWidth: 320, mediumWidth: 380 });
    chordStaffEl.innerHTML = svgString(arena, wasm.lmt_svg_chord_staff, chordType, root);
    normalizeSvgPreview(chordStaffEl, { maxHeight: 280, squareWidth: 520, mediumWidth: 680, wideWidth: 860, ultraWideWidth: 980, padXRatio: 0.1, padYRatio: 0.16 });

    updateSummaryScene("chord", {
      root: noteName(root),
      chordName,
      roman,
      inKey,
    });
  } finally {
    arena.release();
  }
}

function renderProgressionScene() {
  const presets = manifestList("progressionPresets");
  const preset = presets[currentProgressionPreset];
  const arena = new ScratchArena();
  try {
    const orbit = buildScaleOrbit(preset.tonic, preset.quality);
    const cards = [];
    let unionSet = 0;
    let previousSet = null;
    let strongestLink = 0;

    for (const degreeIndex of preset.degrees) {
      const triad = buildTriadFromDegree(arena, orbit, degreeIndex);
      const sharedSet = previousSet == null ? triad.setValue : previousSet & triad.setValue;
      const sharedCount = previousSet == null ? 0 : wasm.lmt_pcs_cardinality(sharedSet);
      strongestLink = Math.max(strongestLink, sharedCount);
      unionSet |= triad.setValue;
      cards.push(`
        <article class="progression-card">
          <div>
            <strong>${escapeHtml(triad.roman)}</strong>
            <div class="progression-title">${escapeHtml(triad.chordName)}</div>
            <div class="progression-notes">${escapeHtml(triad.noteNames.join(" · "))}</div>
            <div class="progression-shared">${previousSet == null ? "entry chord" : `shared with previous: ${sharedCount}`}</div>
          </div>
          <div class="mini-clock">${svgString(arena, wasm.lmt_svg_clock_optc, triad.setValue)}</div>
        </article>
      `);
      previousSet = triad.setValue;
    }

    const unionNotes = orderedMembersFromSet(unionSet, preset.tonic).map((pc) => spellNote(pc, preset.tonic, preset.quality));
    progressionSummaryEl.textContent = [
      `key center: ${noteName(preset.tonic)} ${preset.quality === 0 ? "major" : "minor"}`,
      `steps: ${preset.degrees.map((degree) => degree + 1).join(" → ")}`,
      `unique pitch classes: ${wasm.lmt_pcs_cardinality(unionSet)}`,
      `strongest shared-tone link: ${strongestLink}`,
      `union set: 0x${unionSet.toString(16).padStart(3, "0")}`,
    ].join("\n");
    progressionCardsEl.innerHTML = cards.join("");
    progressionClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, unionSet);
    progressionNotesEl.innerHTML = unionNotes.map((note) => `<span class="chip">${escapeHtml(note)}</span>`).join("");
    normalizeSvgPreview(progressionCardsEl, { maxHeight: 132, squareWidth: 124, mediumWidth: 132, wideWidth: 146, ultraWideWidth: 146, padXRatio: 0.14, padYRatio: 0.18 });
    normalizeSvgPreview(progressionClockEl, { maxHeight: 340, squareWidth: 320, mediumWidth: 460 });

    updateSummaryScene("progression", {
      tonic: noteName(preset.tonic),
      quality: preset.quality === 0 ? "major" : "minor",
      steps: preset.degrees.length,
      unionCardinality: wasm.lmt_pcs_cardinality(unionSet),
      strongestLink,
    });
  } finally {
    arena.release();
  }
}

function renderCompareScene() {
  const presets = manifestList("comparePresets");
  const preset = presets[currentComparePreset];
  const arena = new ScratchArena();
  try {
    const leftSet = pcsFromList(arena, preset.left);
    const rightSet = pcsFromList(arena, preset.right);
    const overlapSet = leftSet & rightSet;
    const unionSet = leftSet | rightSet;
    const relation = describeRelation(leftSet, rightSet);
    const leftNotes = pcsToList(arena, leftSet).map(noteName);
    const rightNotes = pcsToList(arena, rightSet).map(noteName);
    const overlapNotes = pcsToList(arena, overlapSet).map(noteName);
    const unionNotes = pcsToList(arena, unionSet).map(noteName);

    compareLeftClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, leftSet);
    compareOverlapClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, overlapSet);
    compareRightClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, rightSet);
    normalizeSvgPreview(compareLeftClockEl, { maxHeight: 260, squareWidth: 260, mediumWidth: 280 });
    normalizeSvgPreview(compareOverlapClockEl, { maxHeight: 260, squareWidth: 260, mediumWidth: 280 });
    normalizeSvgPreview(compareRightClockEl, { maxHeight: 260, squareWidth: 260, mediumWidth: 280 });

    compareSummaryEl.textContent = [
      `left: 0x${leftSet.toString(16).padStart(3, "0")}`,
      `right: 0x${rightSet.toString(16).padStart(3, "0")}`,
      `shared tones: ${wasm.lmt_pcs_cardinality(overlapSet)}${overlapNotes.length > 0 ? ` -> ${overlapNotes.join(", ")}` : ""}`,
      `union size: ${wasm.lmt_pcs_cardinality(unionSet)}`,
      `transpose relation: ${relation.transposeMatch == null ? "none" : `T${relation.transposeMatch}`}`,
      `inversion relation: ${relation.inversionMatch == null ? "none" : `I+T${relation.inversionMatch}`}`,
    ].join("\n");

    compareChipsEl.innerHTML = [
      ...leftNotes.map((note) => `<span class="chip left-chip">L · ${escapeHtml(note)}</span>`),
      ...overlapNotes.map((note) => `<span class="chip overlap-chip">∩ · ${escapeHtml(note)}</span>`),
      ...rightNotes.filter((note) => !overlapNotes.includes(note)).map((note) => `<span class="chip right-chip">R · ${escapeHtml(note)}</span>`),
      `<span class="pill">Union: ${escapeHtml(unionNotes.join(" · "))}</span>`,
    ].join("");

    updateSummaryScene("compare", {
      leftCardinality: wasm.lmt_pcs_cardinality(leftSet),
      rightCardinality: wasm.lmt_pcs_cardinality(rightSet),
      sharedCardinality: wasm.lmt_pcs_cardinality(overlapSet),
      transposeMatch: relation.transposeMatch,
      inversionMatch: relation.inversionMatch,
    });
  } finally {
    arena.release();
  }
}

function renderFretScene() {
  const tuning = parseCsvIntegers(fretTuningEl.value, 0, 127);
  const frets = parseCsvIntegers(fretFretsEl.value, -1, 127);
  if (tuning.length === 0) {
    throw new Error("Tuning must contain at least one string.");
  }
  if (tuning.length !== frets.length) {
    throw new Error("Tuning and fret csv lists must have the same length.");
  }

  const arena = new ScratchArena();
  try {
    const tuningPtr = writeU8Array(arena, tuning);
    const fretsPtr = writeI8Array(arena, frets);
    const windowStart = Number.parseInt(fretWindowStartEl.value, 10);
    const visibleFrets = Number.parseInt(fretVisibleFretsEl.value, 10);
    const maxFret = Number.parseInt(fretMaxFretEl.value, 10);
    const maxSpan = Number.parseInt(fretMaxSpanEl.value, 10);

    const selected = [];
    for (let stringIndex = 0; stringIndex < frets.length; stringIndex += 1) {
      const fret = frets[stringIndex];
      if (fret < 0) continue;
      const midi = wasm.lmt_fret_to_midi_n(stringIndex, fret, tuningPtr, tuning.length);
      selected.push({ string: stringIndex, fret, midi, pc: midi % 12 });
    }

    const uniquePcs = [...new Set(selected.map((one) => one.pc))];
    const chordSet = uniquePcs.length > 0 ? pcsFromList(arena, uniquePcs) : 0;
    const urlPtr = arena.alloc(256, 1);
    const urlBytes = wasm.lmt_frets_to_url_n(fretsPtr, frets.length, urlPtr, 256);
    if (urlBytes === 0 && frets.length > 0) {
      throw new Error("Unable to serialize fret url with current buffer.");
    }
    const fretUrl = readCString(urlPtr);

    const parsedPtr = arena.alloc(frets.length || 1, 1);
    const parsedCount = wasm.lmt_url_to_frets_n(writeCString(arena, fretUrl), parsedPtr, frets.length);
    const roundTrip = Array.from(i8().subarray(parsedPtr, parsedPtr + Math.min(parsedCount, frets.length)));

    const selectedPosPtr = arena.alloc(Math.max(1, selected.length) * 2, 1);
    const bytes = u8();
    selected.forEach((one, index) => {
      bytes[selectedPosPtr + index * 2] = one.string;
      bytes[selectedPosPtr + index * 2 + 1] = one.fret;
    });

    const guideCap = 128;
    const guidePtr = arena.alloc(guideCap * GUIDE_DOT_BYTES, 4);
    const guideCount = wasm.lmt_pitch_class_guide_n(
      selectedPosPtr,
      selected.length,
      0,
      maxFret,
      tuningPtr,
      tuning.length,
      guidePtr,
      guideCap,
    );
    const guideView = new DataView(memory.buffer, guidePtr, Math.min(guideCount, guideCap) * GUIDE_DOT_BYTES);
    const guidePreview = [];
    for (let index = 0; index < Math.min(guideCount, 6); index += 1) {
      const offset = index * GUIDE_DOT_BYTES;
      guidePreview.push(`s${guideView.getUint8(offset) + 1}:f${guideView.getUint8(offset + 1)} ${noteName(guideView.getUint8(offset + 2))}`);
    }

    let bassPositions = [];
    if (selected.length > 0) {
      const outPosPtr = arena.alloc(tuning.length * 2, 1);
      const posCount = wasm.lmt_midi_to_fret_positions_n(selected[0].midi, tuningPtr, tuning.length, outPosPtr, tuning.length);
      bassPositions = [];
      for (let index = 0; index < posCount; index += 1) {
        bassPositions.push(`s${bytes[outPosPtr + index * 2] + 1}:f${bytes[outPosPtr + index * 2 + 1]}`);
      }
    }

    let voicings = [];
    let rowCount = 0;
    if (chordSet !== 0) {
      const rowCap = 48;
      const voicingPtr = arena.alloc(rowCap * tuning.length, 1);
      rowCount = wasm.lmt_generate_voicings_n(chordSet, tuningPtr, tuning.length, maxFret, maxSpan, voicingPtr, rowCap);
      for (let row = 0; row < Math.min(rowCount, 8); row += 1) {
        const start = voicingPtr + row * tuning.length;
        voicings.push(Array.from(i8().subarray(start, start + tuning.length)).join(","));
      }
    }

    fretSvgEl.innerHTML = svgString(arena, wasm.lmt_svg_fret_n, fretsPtr, frets.length, windowStart, visibleFrets);
    normalizeSvgPreview(fretSvgEl, { maxHeight: 420, squareWidth: 360, mediumWidth: 520, wideWidth: 680, ultraWideWidth: 760, padXRatio: 0.12, padYRatio: 0.18 });
    setChipRow(
      fretNotesEl,
      selected.map((one) => `s${one.string + 1}:f${one.fret} ${noteName(one.pc)} (${one.midi})`),
    );
    setChipRow(fretVoicingsEl, voicings.length > 0 ? voicings : ["no alternate voicings within constraints"], "pill");

    fretSummaryEl.textContent = [
      `serialized: ${fretUrl}`,
      `round trip: ${JSON.stringify(roundTrip)}`,
      `pitch-class set: ${chordSet === 0 ? "0x000 []" : `0x${chordSet.toString(16).padStart(3, "0")} ${JSON.stringify(pcsToList(arena, chordSet))}`}`,
      `guide dots: ${guideCount}${guidePreview.length > 0 ? ` -> ${guidePreview.join(" | ")}` : ""}`,
      `lowest note positions: ${bassPositions.length > 0 ? bassPositions.join(", ") : "n/a"}`,
      `generated voicings shown: ${voicings.length}`,
    ].join("\n");

    updateSummaryScene("fret", {
      tuningCount: tuning.length,
      selectedCount: selected.length,
      voicingCount: rowCount,
      url: fretUrl,
    });
  } finally {
    arena.release();
  }
}

function renderAll() {
  const errors = [];
  const tasks = [
    ["set", renderSetScene],
    ["key", renderKeyScene],
    ["chord", renderChordScene],
    ["progression", renderProgressionScene],
    ["compare", renderCompareScene],
    ["fret", renderFretScene],
  ];

  gallerySummary.errors = [];
  for (const [name, fn] of tasks) {
    try {
      fn();
    } catch (error) {
      const message = `${name}: ${error.message}`;
      errors.push(message);
      gallerySummary.errors.push(message);
    }
  }

  gallerySummary.sceneCount = document.querySelectorAll(".scene-card").length;
  if (errors.length > 0) {
    gallerySummary.ready = false;
    setStatus(`Gallery render completed with ${errors.length} error(s): ${errors.join("; ")}`, "error");
    return;
  }

  gallerySummary.ready = true;
  setStatus("Gallery ready. Curated public API scenes rendered successfully.");
}

function wireSceneEvents() {
  document.getElementById("render-set").addEventListener("click", () => {
    renderSetScene();
    setStatus("Set Observatory refreshed.");
  });
  document.getElementById("render-key").addEventListener("click", () => {
    renderKeyScene();
    setStatus("Key Bloom refreshed.");
  });
  document.getElementById("render-chord").addEventListener("click", () => {
    renderChordScene();
    setStatus("Chord Atelier refreshed.");
  });
  document.getElementById("render-progression").addEventListener("click", () => {
    renderProgressionScene();
    setStatus("Progression Drift refreshed.");
  });
  document.getElementById("render-compare").addEventListener("click", () => {
    renderCompareScene();
    setStatus("Constellation Delta refreshed.");
  });
  document.getElementById("render-fret").addEventListener("click", () => {
    try {
      renderFretScene();
      setStatus("Fret Atlas refreshed.");
    } catch (error) {
      gallerySummary.errors = [`fret: ${error.message}`];
      gallerySummary.ready = false;
      setStatus(`Fret Atlas error: ${error.message}`, "error");
    }
  });

  setPresetEl.addEventListener("change", () => {
    if (setPresetEl.value === CUSTOM_PRESET_VALUE) return;
    applySetPreset(Number.parseInt(setPresetEl.value, 10));
    renderSetScene();
  });
  keyPresetEl.addEventListener("change", () => {
    if (keyPresetEl.value === CUSTOM_PRESET_VALUE) return;
    applyKeyPreset(Number.parseInt(keyPresetEl.value, 10));
    renderKeyScene();
  });
  chordPresetEl.addEventListener("change", () => {
    if (chordPresetEl.value === CUSTOM_PRESET_VALUE) return;
    applyChordPreset(Number.parseInt(chordPresetEl.value, 10));
    renderChordScene();
  });
  progressionPresetEl.addEventListener("change", () => {
    if (progressionPresetEl.value === CUSTOM_PRESET_VALUE) return;
    applyProgressionPreset(Number.parseInt(progressionPresetEl.value, 10));
    renderProgressionScene();
  });
  comparePresetEl.addEventListener("change", () => {
    if (comparePresetEl.value === CUSTOM_PRESET_VALUE) return;
    applyComparePreset(Number.parseInt(comparePresetEl.value, 10));
    renderCompareScene();
  });
  fretPresetEl.addEventListener("change", () => {
    if (fretPresetEl.value === CUSTOM_PRESET_VALUE) return;
    applyFretPreset(Number.parseInt(fretPresetEl.value, 10));
    renderFretScene();
  });

  [keyTonicEl, keyQualityEl].forEach((node) => node.addEventListener("change", () => {
    markPresetCustom(keyPresetEl, keyCaptionEl, "key");
    renderKeyScene();
  }));
  [chordRootEl, chordTypeEl, chordKeyTonicEl, chordKeyQualityEl].forEach((node) =>
    node.addEventListener("change", () => {
      markPresetCustom(chordPresetEl, chordCaptionEl, "chord");
      renderChordScene();
    }),
  );
  [fretTuningEl, fretFretsEl, fretWindowStartEl, fretVisibleFretsEl, fretMaxFretEl, fretMaxSpanEl].forEach((node) =>
    node.addEventListener("change", () => {
      markPresetCustom(fretPresetEl, fretCaptionEl, "fretboard");
      try {
        renderFretScene();
      } catch (error) {
        fretSummaryEl.textContent = error.message;
      }
    }),
  );

  document.getElementById("shuffle-scenes").addEventListener("click", () => {
    currentSetPreset = (currentSetPreset + 1) % manifestList("setPresets").length;
    currentKeyPreset = (currentKeyPreset + 1) % manifestList("keyPresets").length;
    currentChordPreset = (currentChordPreset + 1) % manifestList("chordPresets").length;
    currentProgressionPreset = (currentProgressionPreset + 1) % manifestList("progressionPresets").length;
    currentComparePreset = (currentComparePreset + 1) % manifestList("comparePresets").length;
    currentFretPreset = (currentFretPreset + 1) % manifestList("fretPresets").length;
    applySetPreset(currentSetPreset);
    applyKeyPreset(currentKeyPreset);
    applyChordPreset(currentChordPreset);
    applyProgressionPreset(currentProgressionPreset);
    applyComparePreset(currentComparePreset);
    applyFretPreset(currentFretPreset);
    renderAll();
  });
}

function verifyExports(exportsObj) {
  const missing = REQUIRED_EXPORTS.filter((name) => !(name in exportsObj));
  if (missing.length > 0) {
    throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
  }
}

async function instantiateWasm() {
  const wasmUrl = "./libmusictheory.wasm";
  if (WebAssembly.instantiateStreaming) {
    try {
      const streaming = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
      return streaming.instance;
    } catch (_error) {
      // Fallback below.
    }
  }

  const response = await fetch(wasmUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${wasmUrl}: ${response.status}`);
  }
  const bytes = await response.arrayBuffer();
  const module = await WebAssembly.instantiate(bytes, {});
  return module.instance;
}

function initializeUi() {
  createNoteSelectors(keyTonicEl);
  createNoteSelectors(chordRootEl);
  createNoteSelectors(chordKeyTonicEl);
  buildToggleGrid();
  populatePresetSelect(setPresetEl, manifestList("setPresets"));
  populatePresetSelect(keyPresetEl, manifestList("keyPresets"));
  populatePresetSelect(chordPresetEl, manifestList("chordPresets"));
  populatePresetSelect(progressionPresetEl, manifestList("progressionPresets"));
  populatePresetSelect(comparePresetEl, manifestList("comparePresets"));
  populatePresetSelect(fretPresetEl, manifestList("fretPresets"));
  applySetPreset(0);
  applyKeyPreset(0);
  applyChordPreset(0);
  applyProgressionPreset(0);
  applyComparePreset(0);
  applyFretPreset(0);
  wireSceneEvents();
  gallerySummary.sceneCount = Number(manifest.meta.sceneCount);
}

async function main() {
  try {
    manifest = await loadManifest();
    gallerySummary.manifestLoaded = true;
    initializeUi();
    const instance = await instantiateWasm();
    verifyExports(instance.exports);
    wasm = instance.exports;
    memory = wasm.memory;
    renderAll();
  } catch (error) {
    gallerySummary.ready = false;
    gallerySummary.errors = [error.message];
    setStatus(`Failed to initialize gallery: ${error.message}`, "error");
    console.error(error);
  }
}

main();
