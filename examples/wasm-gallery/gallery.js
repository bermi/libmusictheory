const NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
const MODE_IONIAN = 0;
const MODE_AEOLIAN = 5;
const SCALE_DIATONIC = 0;
const GUIDE_DOT_BYTES = 8;
const decoder = new TextDecoder();
const encoder = new TextEncoder();

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

const setPresets = [
  [0, 4, 7],
  [0, 2, 4, 7, 9],
  [0, 1, 4, 6, 8],
  [0, 2, 5, 7, 10],
  [0, 3, 6, 9],
  [0, 1, 5, 6],
  [0, 3, 5, 8, 10],
  [0, 2, 3, 7, 9],
];

const keyPresets = [
  { tonic: 0, quality: 0 },
  { tonic: 7, quality: 0 },
  { tonic: 2, quality: 0 },
  { tonic: 9, quality: 1 },
  { tonic: 4, quality: 1 },
  { tonic: 10, quality: 1 },
];

const chordPresets = [
  { root: 0, type: 0, keyTonic: 0, keyQuality: 0 },
  { root: 9, type: 1, keyTonic: 0, keyQuality: 0 },
  { root: 11, type: 2, keyTonic: 0, keyQuality: 0 },
  { root: 5, type: 0, keyTonic: 0, keyQuality: 0 },
  { root: 2, type: 1, keyTonic: 9, keyQuality: 1 },
  { root: 8, type: 3, keyTonic: 8, keyQuality: 1 },
];

const fretPresets = [
  {
    tuning: [40, 45, 50, 55, 59, 64],
    frets: [-1, 3, 2, 0, 1, 0],
    windowStart: 0,
    visibleFrets: 5,
    maxFret: 12,
    maxSpan: 4,
  },
  {
    tuning: [67, 60, 64, 69],
    frets: [0, 0, 0, 3],
    windowStart: 0,
    visibleFrets: 5,
    maxFret: 12,
    maxSpan: 4,
  },
  {
    tuning: [28, 33, 38, 43],
    frets: [3, 2, 0, 0],
    windowStart: 0,
    visibleFrets: 5,
    maxFret: 12,
    maxSpan: 4,
  },
  {
    tuning: [55, 62, 69, 76],
    frets: [0, 2, 3, 2],
    windowStart: 0,
    visibleFrets: 5,
    maxFret: 12,
    maxSpan: 5,
  },
  {
    tuning: [35, 40, 45, 50, 55, 59, 64],
    frets: [-1, 3, 2, 0, 1, 0, -1],
    windowStart: 0,
    visibleFrets: 5,
    maxFret: 12,
    maxSpan: 4,
  },
];

const statusEl = document.getElementById("status");
const pcsToggleGrid = document.getElementById("pcs-toggle-grid");

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

const setSummaryEl = document.getElementById("set-summary");
const setClockEl = document.getElementById("set-clock");
const keyNotesEl = document.getElementById("key-notes");
const keyDegreesEl = document.getElementById("key-degrees");
const keyClockEl = document.getElementById("key-clock");
const chordSummaryEl = document.getElementById("chord-summary");
const chordNotesEl = document.getElementById("chord-notes");
const chordClockEl = document.getElementById("chord-clock");
const chordStaffEl = document.getElementById("chord-staff");
const fretSvgEl = document.getElementById("fret-svg");
const fretSummaryEl = document.getElementById("fret-summary");
const fretNotesEl = document.getElementById("fret-notes");
const fretVoicingsEl = document.getElementById("fret-voicings");

let wasm = null;
let memory = null;
let currentSetPreset = 0;
let currentKeyPreset = 0;
let currentChordPreset = 0;
let currentFretPreset = 0;
let jsScratchBase = 0;
let jsScratchTop = 0;
let jsScratchLimit = 0;

const gallerySummary = {
  ready: false,
  errors: [],
  scenes: {
    set: {},
    key: {},
    chord: {},
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

function normalizeSvgPreview(host, maxHeight = 280) {
  const svg = host.querySelector("svg");
  if (!svg) return;
  svg.style.display = "block";
  svg.style.maxWidth = "100%";
  svg.style.maxHeight = `${maxHeight}px`;
  svg.style.height = "auto";
}

function updateSummaryScene(name, data) {
  gallerySummary.scenes[name] = { ...data, rendered: true };
}

function setChipRow(target, items, klass = "chip") {
  target.innerHTML = items.map((one) => `<span class="${klass}">${one}</span>`).join("");
}

function createNoteSelectors(select) {
  select.innerHTML = NOTE_NAMES.map((name, index) => `<option value="${index}">${name}</option>`).join("");
}

function buildToggleGrid() {
  pcsToggleGrid.innerHTML = NOTE_NAMES.map(
    (name, pc) =>
      `<button class="pc-toggle" data-pc="${pc}" type="button" aria-pressed="false">${name}</button>`,
  ).join("");
  pcsToggleGrid.addEventListener("click", (event) => {
    const button = event.target.closest(".pc-toggle");
    if (!button) return;
    button.classList.toggle("is-active");
    button.setAttribute("aria-pressed", button.classList.contains("is-active") ? "true" : "false");
    renderSetScene();
  });
}

function applySetPreset(index) {
  currentSetPreset = index % setPresets.length;
  const active = new Set(setPresets[currentSetPreset]);
  for (const button of pcsToggleGrid.querySelectorAll(".pc-toggle")) {
    const pc = Number.parseInt(button.dataset.pc, 10);
    const isActive = active.has(pc);
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", isActive ? "true" : "false");
  }
}

function applyKeyPreset(index) {
  currentKeyPreset = index % keyPresets.length;
  const preset = keyPresets[currentKeyPreset];
  keyTonicEl.value = String(preset.tonic);
  keyQualityEl.value = String(preset.quality);
}

function applyChordPreset(index) {
  currentChordPreset = index % chordPresets.length;
  const preset = chordPresets[currentChordPreset];
  chordRootEl.value = String(preset.root);
  chordTypeEl.value = String(preset.type);
  chordKeyTonicEl.value = String(preset.keyTonic);
  chordKeyQualityEl.value = String(preset.keyQuality);
}

function applyFretPreset(index) {
  currentFretPreset = index % fretPresets.length;
  const preset = fretPresets[currentFretPreset];
  fretTuningEl.value = preset.tuning.join(",");
  fretFretsEl.value = preset.frets.join(",");
  fretWindowStartEl.value = String(preset.windowStart);
  fretVisibleFretsEl.value = String(preset.visibleFrets);
  fretMaxFretEl.value = String(preset.maxFret);
  fretMaxSpanEl.value = String(preset.maxSpan);
}

function currentSetList() {
  return Array.from(pcsToggleGrid.querySelectorAll(".pc-toggle.is-active"), (button) =>
    Number.parseInt(button.dataset.pc, 10),
  ).sort((a, b) => a - b);
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
    const chordName = readCString(wasm.lmt_chord_name(setValue));
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
      `chord reading: ${chordName || "no canonical triadic label"}`,
    ].join("\n");
    setClockEl.innerHTML = svg;
    normalizeSvgPreview(setClockEl, 260);
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
    const majorScale = wasm.lmt_scale(SCALE_DIATONIC, tonic);
    const modeSet = quality === 0 ? majorScale : wasm.lmt_mode(MODE_AEOLIAN, tonic);
    const ordered = orderedMembersFromSet(modeSet, tonic);
    const noteNames = ordered.map((pc) => spellNote(pc, tonic, quality));
    const degreeCards = [];

    for (let i = 0; i < ordered.length; i += 1) {
      const triadList = [
        ordered[i],
        ordered[(i + 2) % ordered.length],
        ordered[(i + 4) % ordered.length],
      ];
      const triad = pcsFromList(arena, triadList);
      const roman = readCString(wasm.lmt_roman_numeral_parts(triad, tonic, quality));
      const chordName = readCString(wasm.lmt_chord_name(triad));
      const triadNotes = triadList.map((pc) => spellNote(pc, tonic, quality)).join(" · ");
      degreeCards.push(
        `<article class="degree-card"><strong>${roman}</strong><div>${chordName || "set-class chord"}</div><div>${triadNotes}</div></article>`,
      );
    }

    setChipRow(keyNotesEl, noteNames);
    keyDegreesEl.innerHTML = degreeCards.join("");
    keyClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, modeSet);
    normalizeSvgPreview(keyClockEl, 280);

    updateSummaryScene("key", {
      tonic: noteName(tonic),
      quality: quality === 0 ? "major" : "minor",
      noteCount: ordered.length,
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
    const chordName = readCString(wasm.lmt_chord_name(chordSet));
    const roman = readCString(wasm.lmt_roman_numeral_parts(chordSet, keyTonic, keyQuality));
    const prime = wasm.lmt_prime_form(chordSet);
    const fortePrime = wasm.lmt_forte_prime(chordSet);
    const keySet = keyQuality === 0 ? wasm.lmt_scale(SCALE_DIATONIC, keyTonic) : wasm.lmt_mode(MODE_AEOLIAN, keyTonic);
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
    normalizeSvgPreview(chordClockEl, 260);
    chordStaffEl.innerHTML = svgString(arena, wasm.lmt_svg_chord_staff, chordType, root);
    normalizeSvgPreview(chordStaffEl, 180);

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
      selected.push({
        string: stringIndex,
        fret,
        midi,
        pc: midi % 12,
      });
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
      guidePreview.push(
        `s${guideView.getUint8(offset) + 1}:f${guideView.getUint8(offset + 1)} ${noteName(guideView.getUint8(offset + 2))}`,
      );
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
    if (chordSet !== 0) {
      const rowCap = 48;
      const voicingPtr = arena.alloc(rowCap * tuning.length, 1);
      const rowCount = wasm.lmt_generate_voicings_n(chordSet, tuningPtr, tuning.length, maxFret, maxSpan, voicingPtr, rowCap);
      voicings = [];
      for (let row = 0; row < Math.min(rowCount, 8); row += 1) {
        const start = voicingPtr + row * tuning.length;
        voicings.push(Array.from(i8().subarray(start, start + tuning.length)).join(","));
      }
      updateSummaryScene("fret", {
        tuningCount: tuning.length,
        selectedCount: selected.length,
        voicingCount: rowCount,
        url: fretUrl,
      });
    } else {
      updateSummaryScene("fret", {
        tuningCount: tuning.length,
        selectedCount: 0,
        voicingCount: 0,
        url: fretUrl,
      });
    }

    fretSvgEl.innerHTML = svgString(arena, wasm.lmt_svg_fret_n, fretsPtr, frets.length, windowStart, visibleFrets);
    normalizeSvgPreview(fretSvgEl, 280);
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

  if (errors.length > 0) {
    gallerySummary.ready = false;
    setStatus(`Gallery render completed with ${errors.length} error(s): ${errors.join("; ")}`, "error");
    return;
  }

  gallerySummary.ready = true;
  setStatus("Gallery ready. Public API scenes rendered successfully.");
}

function wireSceneEvents() {
  document.getElementById("render-set").addEventListener("click", renderSetScene);
  document.getElementById("render-key").addEventListener("click", renderKeyScene);
  document.getElementById("render-chord").addEventListener("click", renderChordScene);
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

  [keyTonicEl, keyQualityEl].forEach((node) => node.addEventListener("change", renderKeyScene));
  [chordRootEl, chordTypeEl, chordKeyTonicEl, chordKeyQualityEl].forEach((node) =>
    node.addEventListener("change", renderChordScene),
  );
  [fretTuningEl, fretFretsEl, fretWindowStartEl, fretVisibleFretsEl, fretMaxFretEl, fretMaxSpanEl].forEach((node) =>
    node.addEventListener("change", () => {
      try {
        renderFretScene();
      } catch (error) {
        fretSummaryEl.textContent = error.message;
      }
    }),
  );

  document.getElementById("shuffle-scenes").addEventListener("click", () => {
    currentSetPreset = (currentSetPreset + 1) % setPresets.length;
    currentKeyPreset = (currentKeyPreset + 1) % keyPresets.length;
    currentChordPreset = (currentChordPreset + 1) % chordPresets.length;
    currentFretPreset = (currentFretPreset + 1) % fretPresets.length;
    applySetPreset(currentSetPreset);
    applyKeyPreset(currentKeyPreset);
    applyChordPreset(currentChordPreset);
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
  applySetPreset(0);
  applyKeyPreset(0);
  applyChordPreset(0);
  applyFretPreset(0);
  wireSceneEvents();
}

async function main() {
  initializeUi();
  try {
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
