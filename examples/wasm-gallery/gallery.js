const NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
const MODE_AEOLIAN = 5;
const SCALE_DIATONIC = 0;
const GUIDE_DOT_BYTES = 8;
const decoder = new TextDecoder();
const encoder = new TextEncoder();
const CUSTOM_PRESET_VALUE = "custom";
const captureMode = new URLSearchParams(window.location.search).get("capture") === "1";
const MIDI_SNAPSHOT_STORAGE_KEY = "lmt.gallery.midi.snapshots";
const MIDI_SCENE_TITLE = "Live MIDI Compass";
const MIDI_DEFAULT_TONIC = 0;
const MIDI_DEFAULT_MODE = 0;
const MODE_OPTIONS = [
  { id: 0, name: "Ionian" },
  { id: 1, name: "Dorian" },
  { id: 2, name: "Phrygian" },
  { id: 3, name: "Lydian" },
  { id: 4, name: "Mixolydian" },
  { id: 5, name: "Aeolian" },
  { id: 6, name: "Locrian" },
  { id: 7, name: "Melodic Minor" },
  { id: 8, name: "Dorian b2" },
  { id: 9, name: "Lydian Aug" },
  { id: 10, name: "Lydian Dom" },
  { id: 11, name: "Mixolydian b6" },
  { id: 12, name: "Locrian nat2" },
  { id: 13, name: "Super Locrian" },
  { id: 14, name: "Half-Whole" },
  { id: 15, name: "Whole-Half" },
  { id: 16, name: "Whole-Tone" },
];

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
  "lmt_svg_evenness_chart",
  "lmt_svg_fret_n",
  "lmt_svg_chord_staff",
  "lmt_svg_key_staff",
];

const statusEl = document.getElementById("status");
const pcsToggleGrid = document.getElementById("pcs-toggle-grid");
const midiCaptionEl = document.getElementById("midi-caption");
const midiStatusPillsEl = document.getElementById("midi-status-pills");
const midiDevicesEl = document.getElementById("midi-devices");
const midiSummaryEl = document.getElementById("midi-summary");
const midiNotesEl = document.getElementById("midi-notes");
const midiClockEl = document.getElementById("midi-clock");
const midiStaffEl = document.getElementById("midi-staff");
const midiSuggestionsEl = document.getElementById("midi-suggestions");
const midiSnapshotsEl = document.getElementById("midi-snapshots");
const connectMidiEl = document.getElementById("connect-midi");
const midiSaveSnapshotEl = document.getElementById("midi-save-snapshot");
const midiReturnLiveEl = document.getElementById("midi-return-live");
const midiTonicEl = document.getElementById("midi-tonic");
const midiModeEl = document.getElementById("midi-mode");

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
const setEvennessEl = document.getElementById("set-evenness");
const keyNotesEl = document.getElementById("key-notes");
const keyDegreesEl = document.getElementById("key-degrees");
const keyClockEl = document.getElementById("key-clock");
const keyStaffEl = document.getElementById("key-staff");
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
    midi: {},
    set: {},
    key: {},
    chord: {},
    progression: {},
    compare: {},
    fret: {},
  },
};
window.__lmtGallerySummary = gallerySummary;

const midiState = {
  supported: typeof navigator !== "undefined" && typeof navigator.requestMIDIAccess === "function",
  accessState: "idle",
  access: null,
  inputs: new Map(),
  channels: new Map(),
  snapshots: [],
  activeSnapshotId: null,
  renderQueued: false,
  lastError: "",
  lastEventText: "Awaiting MIDI note input.",
  lastChangedAt: 0,
};

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

function modeName(modeType) {
  return MODE_OPTIONS.find((one) => one.id === modeType)?.name || `Mode ${modeType}`;
}

function populateModeSelect(select) {
  select.innerHTML = MODE_OPTIONS.map((one) => `<option value="${one.id}">${escapeHtml(one.name)}</option>`).join("");
}

function modeSet(tonic, modeType) {
  return wasm.lmt_mode(modeType, tonic);
}

function inferModeSpellingQuality(modeSetValue, tonic) {
  const minorThird = (modeSetValue & (1 << ((tonic + 3) % 12))) !== 0;
  const majorThird = (modeSetValue & (1 << ((tonic + 4) % 12))) !== 0;
  if (minorThird && !majorThird) return 1;
  return 0;
}

function currentMidiContext() {
  const tonic = Number.parseInt(midiTonicEl.value, 10);
  const modeType = Number.parseInt(midiModeEl.value, 10);
  const setValue = modeSet(tonic, modeType);
  const quality = inferModeSpellingQuality(setValue, tonic);
  return {
    tonic,
    modeType,
    setValue,
    quality,
    label: `${spellNote(tonic, tonic, quality)} ${modeName(modeType)}`,
  };
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

function inspectStaffSvg(svg) {
  if (!svg) {
    return {
      clefCount: 0,
      noteheadCount: 0,
      chordNoteheadCount: 0,
      keyNoteheadCount: 0,
      sharedStemCount: 0,
      noteColumnSpan: Infinity,
      distinctNoteColumns: 0,
      simultaneousCluster: false,
      barlineCount: 0,
    };
  }

  const noteheadNodes = Array.from(svg.querySelectorAll(".notehead"));
  const noteXs = Array.from(noteheadNodes, (node) =>
    Number.parseFloat(node.getAttribute("cx") || "0"),
  ).filter((value) => Number.isFinite(value));
  const chordNoteheadCount = svg.querySelectorAll(".notehead.chord-notehead").length;
  const keyNoteheadCount = svg.querySelectorAll(".notehead.key-notehead").length;

  const roundedColumns = new Set(noteXs.map((value) => value.toFixed(2)));
  const minX = noteXs.length > 0 ? Math.min(...noteXs) : 0;
  const maxX = noteXs.length > 0 ? Math.max(...noteXs) : 0;
  const noteColumnSpan = noteXs.length > 0 ? maxX - minX : Infinity;

  return {
    clefCount: svg.querySelectorAll(".clef").length,
    noteheadCount: noteXs.length,
    chordNoteheadCount,
    keyNoteheadCount,
    sharedStemCount: svg.querySelectorAll(".cluster-stem").length,
    noteColumnSpan,
    distinctNoteColumns: roundedColumns.size,
    simultaneousCluster: chordNoteheadCount >= 2 && noteColumnSpan <= 12,
    barlineCount: svg.querySelectorAll(".staff-barline").length,
  };
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

function rawChordName(setValue) {
  if (setValue === 0) return "";
  return readCString(wasm.lmt_chord_name(setValue));
}

function midiOctave(midi) {
  return Math.floor(midi / 12) - 1;
}

function midiName(midi, tonic = midi % 12, quality = 0) {
  return `${spellNote(midi % 12, tonic, quality)}${midiOctave(midi)}`;
}

function sortedAscendingNumbers(values) {
  return Array.from(values).sort((a, b) => a - b);
}

function uniqueSortedPcsFromMidi(midiNotes) {
  return [...new Set(midiNotes.map((midi) => midi % 12))].sort((a, b) => a - b);
}

function midiListToSet(arena, midiNotes) {
  const pcs = uniqueSortedPcsFromMidi(midiNotes);
  return pcs.length > 0 ? pcsFromList(arena, pcs) : 0;
}

function setMembers(setValue) {
  const members = [];
  for (let pc = 0; pc < 12; pc += 1) {
    if ((setValue & (1 << pc)) !== 0) members.push(pc);
  }
  return members;
}

function detectRenderableTriad(setValue) {
  if (setValue === 0) return null;
  for (let type = 0; type < 4; type += 1) {
    for (let root = 0; root < 12; root += 1) {
      if (wasm.lmt_chord(type, root) === setValue) {
        return { type, root };
      }
    }
  }
  return null;
}

function keyLabel(tonic, quality) {
  return `${noteName(tonic)} ${quality === 0 ? "major" : "minor"}`;
}

function buildKeyCandidates(setValue) {
  const setCardinality = wasm.lmt_pcs_cardinality(setValue);
  const candidates = [];
  for (let tonic = 0; tonic < 12; tonic += 1) {
    for (let quality = 0; quality < 2; quality += 1) {
      const orbit = quality === 0 ? wasm.lmt_scale(SCALE_DIATONIC, tonic) : wasm.lmt_mode(MODE_AEOLIAN, tonic);
      const overlapSet = setValue & orbit;
      const overlap = wasm.lmt_pcs_cardinality(overlapSet);
      const outside = setCardinality - overlap;
      const missing = wasm.lmt_pcs_cardinality(orbit & ~setValue);
      let score = overlap * 24 - outside * 18 - missing;
      if ((setValue & (1 << tonic)) !== 0) score += 4;
      candidates.push({
        tonic,
        quality,
        set: orbit,
        overlap,
        outside,
        missing,
        score,
        label: keyLabel(tonic, quality),
      });
    }
  }
  candidates.sort((a, b) =>
    b.score - a.score
    || b.overlap - a.overlap
    || a.outside - b.outside
    || a.tonic - b.tonic
    || a.quality - b.quality);
  return candidates;
}

function midiChannelKey(inputId, channel) {
  return `${inputId}:${channel}`;
}

function getMidiChannelState(inputId, channel) {
  const key = midiChannelKey(inputId, channel);
  let entry = midiState.channels.get(key);
  if (!entry) {
    entry = {
      inputId,
      channel,
      held: new Set(),
      sustained: new Set(),
      sustainDown: false,
      sostenutoDown: false,
    };
    midiState.channels.set(key, entry);
  }
  return entry;
}

function currentLiveMidiNotes() {
  const aggregate = new Set();
  for (const channel of midiState.channels.values()) {
    for (const note of channel.held) aggregate.add(note);
    for (const note of channel.sustained) aggregate.add(note);
  }
  return sortedAscendingNumbers(aggregate);
}

function currentDisplayMidiNotes() {
  if (midiState.activeSnapshotId != null) {
    const snapshot = midiState.snapshots.find((one) => one.id === midiState.activeSnapshotId);
    if (snapshot) return snapshot.midiNotes.slice();
  }
  return currentLiveMidiNotes();
}

function currentDisplayMidiContext() {
  return currentMidiContext();
}

function persistMidiSnapshots() {
  try {
    window.localStorage?.setItem(MIDI_SNAPSHOT_STORAGE_KEY, JSON.stringify(midiState.snapshots));
  } catch (_error) {
    // Ignore storage failures.
  }
}

function hydrateMidiSnapshots() {
  try {
    const raw = window.localStorage?.getItem(MIDI_SNAPSHOT_STORAGE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return;
    midiState.snapshots = parsed
      .filter((one) => one && Array.isArray(one.midiNotes) && typeof one.id === "string")
      .slice(0, 12)
      .map((one) => ({
        id: String(one.id),
        createdAt: typeof one.createdAt === "number" ? one.createdAt : Date.now(),
        chordName: typeof one.chordName === "string" ? one.chordName : "",
        noteLabel: typeof one.noteLabel === "string" ? one.noteLabel : "",
        tonic: Number.isFinite(Number(one.tonic)) ? Number(one.tonic) : MIDI_DEFAULT_TONIC,
        modeType: Number.isFinite(Number(one.modeType)) ? Number(one.modeType) : MIDI_DEFAULT_MODE,
        contextLabel: typeof one.contextLabel === "string" ? one.contextLabel : "",
        midiNotes: sortedAscendingNumbers(one.midiNotes.map((value) => Number(value)).filter((value) => Number.isFinite(value) && value >= 0 && value <= 127)),
      }))
      .filter((one) => one.midiNotes.length > 0);
  } catch (_error) {
    midiState.snapshots = [];
  }
}

function saveMidiSnapshot() {
  const midiNotes = currentLiveMidiNotes();
  if (midiNotes.length === 0) return false;
  const context = currentMidiContext();
  const duplicate = midiState.snapshots[0];
  if (
    duplicate
    && JSON.stringify(duplicate.midiNotes) === JSON.stringify(midiNotes)
    && duplicate.tonic === context.tonic
    && duplicate.modeType === context.modeType
  ) {
    return false;
  }

  const arena = new ScratchArena();
  try {
    const setValue = midiListToSet(arena, midiNotes);
    const chordName = friendlyChordName(rawChordName(setValue));
    const noteLabel = midiNotes.map((midi) => midiName(midi, context.tonic, context.quality)).join(" · ");
    midiState.snapshots.unshift({
      id: `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
      createdAt: Date.now(),
      chordName,
      noteLabel,
      tonic: context.tonic,
      modeType: context.modeType,
      contextLabel: context.label,
      midiNotes,
    });
    midiState.snapshots = midiState.snapshots.slice(0, 12);
    persistMidiSnapshots();
    return true;
  } finally {
    arena.release();
  }
}

function setMidiSnapshotPreview(snapshotId) {
  const snapshot = midiState.snapshots.find((one) => one.id === snapshotId);
  if (snapshot) {
    midiTonicEl.value = String(snapshot.tonic);
    midiModeEl.value = String(snapshot.modeType);
  }
  midiState.activeSnapshotId = snapshotId;
  renderMidiScene();
}

function returnMidiSceneToLive() {
  midiState.activeSnapshotId = null;
  renderMidiScene();
}

function scheduleMidiRender() {
  if (midiState.renderQueued) return;
  midiState.renderQueued = true;
  window.requestAnimationFrame(() => {
    midiState.renderQueued = false;
    if (wasm && memory) renderMidiScene();
  });
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
  if (!loaded.meta || Number(loaded.meta.sceneCount) < 7) {
    throw new Error("Invalid gallery manifest: meta.sceneCount must be >= 7");
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

function summarizeMidiAccess() {
  if (!midiState.supported) return "Web MIDI unavailable in this browser.";
  switch (midiState.accessState) {
    case "connected":
      return midiState.inputs.size > 0
        ? `Listening to ${midiState.inputs.size} MIDI input${midiState.inputs.size === 1 ? "" : "s"}.`
        : "MIDI access granted. Waiting for input devices.";
    case "connecting":
      return "Connecting to browser MIDI access...";
    case "denied":
      return "MIDI access was denied. Click Connect MIDI to retry.";
    case "error":
      return midiState.lastError || "Unable to initialize MIDI access.";
    default:
      return "Connect MIDI to listen to every browser MIDI input, sustain pedal, and middle-pedal snapshots.";
  }
}

function renderMidiSnapshotCards() {
  if (midiState.snapshots.length === 0) {
    midiSnapshotsEl.innerHTML = `<p class="snapshot-empty">Press the middle pedal while notes are sounding to save a snapshot you can recall later.</p>`;
    return;
  }
  midiSnapshotsEl.innerHTML = midiState.snapshots
    .map((snapshot, index) => `
      <button class="snapshot-card${midiState.activeSnapshotId === snapshot.id ? " is-active" : ""}" type="button" data-midi-snapshot="${escapeHtml(snapshot.id)}">
        <strong>${escapeHtml(String.fromCharCode(65 + index))}. ${escapeHtml(snapshot.chordName || "Snapshot")}</strong>
        <span class="snapshot-context">${escapeHtml(snapshot.contextLabel || "Context pending")}</span>
        <span>${escapeHtml(snapshot.noteLabel)}</span>
        <span>${new Date(snapshot.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}</span>
      </button>
    `)
    .join("");
}

function buildMidiSuggestions(arena, setValue, midiNotes, context) {
  if (setValue === 0) return [];
  const lastPc = midiNotes.length > 0 ? midiNotes[midiNotes.length - 1] % 12 : null;
  const currentOverlap = wasm.lmt_pcs_cardinality(setValue & context.setValue);
  const suggestions = [];
  for (let pc = 0; pc < 12; pc += 1) {
    if ((setValue & (1 << pc)) !== 0) continue;
    const expanded = setValue | (1 << pc);
    const rawName = rawChordName(expanded);
    const chordLabel = friendlyChordName(rawName);
    const inContext = (context.setValue & (1 << pc)) !== 0;
    const overlap = wasm.lmt_pcs_cardinality(expanded & context.setValue);
    const outside = wasm.lmt_pcs_cardinality(expanded) - overlap;
    const overlapGain = overlap - currentOverlap;
    const clusterFree = wasm.lmt_is_cluster_free(expanded) === 1;
    const evenness = wasm.lmt_evenness_distance(expanded);
    const stepDistance = lastPc == null
      ? 0
      : Math.min((pc - lastPc + 12) % 12, (lastPc - pc + 12) % 12);
    const rootDistance = Math.min((pc - context.tonic + 12) % 12, (context.tonic - pc + 12) % 12);
    let score = (inContext ? 16 : -8) + (overlapGain * 8) - (outside * 4) + (clusterFree ? 3 : -4) + ((rawName && rawName !== "Unknown") ? 5 : 0) - (evenness * 0.12) - (stepDistance * 0.4) - (rootDistance * 0.15);
    if ((expanded & context.setValue) === expanded) score += 5;
    if (midiNotes.length <= 2 && rawName && rawName !== "Unknown") score += 3;
    const reason = [];
    reason.push(inContext ? `inside ${context.label}` : `outside ${context.label}`);
    reason.push(`context overlap ${overlap}/${wasm.lmt_pcs_cardinality(expanded)}`);
    if (rawName && rawName !== "Unknown") reason.push(`reads as ${rawName}`);
    reason.push(clusterFree ? "avoids cluster pressure" : "adds cluster pressure");
    suggestions.push({
      pc,
      name: spellNote(pc, context.tonic, context.quality),
      chordLabel,
      reason: reason.join(" · "),
      score,
      expanded,
    });
  }
  suggestions.sort((a, b) => b.score - a.score || a.pc - b.pc);
  return suggestions.slice(0, 4);
}

function renderMidiScene() {
  const liveNotes = currentLiveMidiNotes();
  const displayNotes = currentDisplayMidiNotes();
  const context = currentDisplayMidiContext();
  const viewingSnapshot = midiState.activeSnapshotId != null;

  midiCaptionEl.textContent = summarizeMidiAccess();
  connectMidiEl.disabled = midiState.accessState === "connecting";
  midiSaveSnapshotEl.disabled = liveNotes.length === 0;
  midiReturnLiveEl.disabled = !viewingSnapshot;

  const statusPills = [];
  statusPills.push(`<span class="status-pill ${viewingSnapshot ? "is-snapshot" : "is-live"}">${viewingSnapshot ? "Viewing snapshot" : "Live input"}</span>`);
  statusPills.push(`<span class="status-pill ${liveNotes.length > 0 ? "is-live" : "is-muted"}">${liveNotes.length} sounding</span>`);
  statusPills.push(`<span class="status-pill ${midiState.snapshots.length > 0 ? "is-snapshot" : "is-muted"}">${midiState.snapshots.length} saved</span>`);
  statusPills.push(`<span class="status-pill is-live">${escapeHtml(context.label)}</span>`);
  midiStatusPillsEl.innerHTML = statusPills.join("");
  midiDevicesEl.innerHTML = Array.from(midiState.inputs.values()).map((input) =>
    `<span class="pill">${escapeHtml(input.name || input.manufacturer || input.id || "MIDI input")}</span>`).join("")
    || `<span class="pill">No MIDI input devices reported yet</span>`;

  renderMidiSnapshotCards();

  const arena = new ScratchArena();
  try {
    const setValue = midiListToSet(arena, displayNotes);
    const currentChord = friendlyChordName(rawChordName(setValue));
    const triad = detectRenderableTriad(setValue);
    const contextOverlap = wasm.lmt_pcs_cardinality(setValue & context.setValue);
    const outsideCount = wasm.lmt_pcs_cardinality(setValue) - contextOverlap;
    const suggestions = buildMidiSuggestions(arena, setValue, displayNotes, context);
    const displayNotesLabel = displayNotes.length > 0
      ? displayNotes.map((midi) => midiName(midi, context.tonic, context.quality))
      : [];
    const orbitNames = orderedMembersFromSet(context.setValue, context.tonic).map((pc) => spellNote(pc, context.tonic, context.quality));

    midiSummaryEl.textContent = [
      `mode: ${viewingSnapshot ? "snapshot preview" : "live input"}`,
      `selected context: ${context.label}`,
      `active MIDI notes: ${displayNotes.length > 0 ? displayNotes.join(", ") : "none"}`,
      `set: ${setValue === 0 ? "0x000 []" : `0x${setValue.toString(16).padStart(3, "0")} ${JSON.stringify(setMembers(setValue))}`}`,
      `hearing: ${setValue === 0 ? "awaiting notes" : currentChord}`,
      `context orbit: ${orbitNames.join(" · ")}`,
      `context overlap: ${contextOverlap}/${wasm.lmt_pcs_cardinality(setValue)} inside, ${outsideCount} outside`,
      `next-step suggestions: ${suggestions.length}`,
      `last event: ${midiState.lastEventText}`,
    ].join("\n");

    if (displayNotesLabel.length > 0) {
      setChipRow(midiNotesEl, displayNotesLabel);
    } else {
      midiNotesEl.innerHTML = `<span class="pill">Play a chord or melodic fragment. Sustain is tracked; middle pedal saves snapshots.</span>`;
    }

    midiClockEl.innerHTML = svgString(arena, wasm.lmt_svg_clock_optc, setValue);
    normalizeSvgPreview(midiClockEl, { maxHeight: 420, squareWidth: 420, mediumWidth: 520 });

    if (triad) {
      midiStaffEl.innerHTML = svgString(arena, wasm.lmt_svg_chord_staff, triad.type, triad.root);
      normalizeSvgPreview(midiStaffEl, { maxHeight: 340, squareWidth: 620, mediumWidth: 780, wideWidth: 920, ultraWideWidth: 1040, padXRatio: 0.05, padYRatio: 0.12 });
    } else {
      midiStaffEl.innerHTML = `<div class="output-block">Staff preview appears automatically for major, minor, diminished, and augmented triads.</div>`;
    }

    if (suggestions.length === 0) {
      midiSuggestionsEl.innerHTML = `<p class="snapshot-empty">Once at least one note is sounding, libmusictheory will rank pitch-class additions against ${escapeHtml(context.label)} here.</p>`;
    } else {
      midiSuggestionsEl.innerHTML = suggestions.map((suggestion, index) => `
        <article class="suggestion-card">
          <strong>${String.fromCharCode(65 + index)}. Add ${escapeHtml(suggestion.name)}</strong>
          <p>${escapeHtml(suggestion.chordLabel)}</p>
          <p>${escapeHtml(suggestion.reason)}</p>
          <div class="suggestion-art">${svgString(arena, wasm.lmt_svg_clock_optc, suggestion.expanded)}</div>
        </article>
      `).join("");
      normalizeSvgPreview(midiSuggestionsEl, { maxHeight: 160, squareWidth: 160, mediumWidth: 180, wideWidth: 180, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 });
    }

    updateSummaryScene("midi", {
      supported: midiState.supported,
      accessState: midiState.accessState,
      inputCount: midiState.inputs.size,
      liveCount: liveNotes.length,
      displayCount: displayNotes.length,
      snapshotCount: midiState.snapshots.length,
      viewingSnapshot,
      contextLabel: context.label,
      tonic: context.tonic,
      modeType: context.modeType,
      insideCount: contextOverlap,
      outsideCount,
      chordName: setValue === 0 ? "" : currentChord,
      suggestionCount: suggestions.length,
      suggestionNames: suggestions.map((one) => one.name),
      rendered: true,
    });
  } finally {
    arena.release();
  }
}

function handleMidiEvent(inputId, data) {
  if (!data || data.length < 2) return;
  const status = data[0];
  const kind = status & 0xf0;
  const channel = status & 0x0f;
  const data1 = data[1];
  const data2 = data.length > 2 ? data[2] : 0;
  const state = getMidiChannelState(inputId, channel);

  if (kind === 0x90 && data2 > 0) {
    state.held.add(data1);
    state.sustained.delete(data1);
    midiState.lastEventText = `Note on ${midiName(data1)} on channel ${channel + 1}`;
  } else if (kind === 0x80 || (kind === 0x90 && data2 === 0)) {
    state.held.delete(data1);
    if (state.sustainDown) {
      state.sustained.add(data1);
    } else {
      state.sustained.delete(data1);
    }
    midiState.lastEventText = `Note off ${midiName(data1)} on channel ${channel + 1}`;
  } else if (kind === 0xb0 && data1 === 64) {
    const nextDown = data2 >= 64;
    if (!nextDown && state.sustainDown) {
      state.sustainDown = false;
      state.sustained = new Set(Array.from(state.sustained).filter((note) => state.held.has(note)));
      midiState.lastEventText = `Sustain pedal released on channel ${channel + 1}`;
    } else if (nextDown && !state.sustainDown) {
      state.sustainDown = true;
      midiState.lastEventText = `Sustain pedal engaged on channel ${channel + 1}`;
    }
  } else if (kind === 0xb0 && data1 === 66) {
    const nextDown = data2 >= 64;
    if (nextDown && !state.sostenutoDown) {
      state.sostenutoDown = true;
      const saved = saveMidiSnapshot();
      midiState.lastEventText = saved ? `Middle pedal saved snapshot on channel ${channel + 1}` : `Middle pedal ignored empty state on channel ${channel + 1}`;
    } else if (!nextDown && state.sostenutoDown) {
      state.sostenutoDown = false;
    }
  } else {
    return;
  }

  midiState.lastChangedAt = Date.now();
  scheduleMidiRender();
}

function syncMidiInputs() {
  const nextInputs = new Map();
  if (!midiState.access) {
    midiState.inputs = nextInputs;
    scheduleMidiRender();
    return;
  }

  for (const input of midiState.access.inputs.values()) {
    const wrapped = {
      id: input.id,
      name: input.name || input.manufacturer || input.id || "MIDI input",
      raw: input,
    };
    input.onmidimessage = (event) => handleMidiEvent(input.id, event.data);
    nextInputs.set(input.id, wrapped);
  }
  midiState.inputs = nextInputs;
  scheduleMidiRender();
}

async function connectMidi() {
  if (!midiState.supported) {
    midiState.accessState = "unsupported";
    renderMidiScene();
    return;
  }

  midiState.accessState = "connecting";
  renderMidiScene();
  try {
    midiState.access = await navigator.requestMIDIAccess();
    midiState.accessState = "connected";
    midiState.lastError = "";
    midiState.access.onstatechange = () => {
      syncMidiInputs();
      midiState.lastEventText = "MIDI device topology changed.";
      scheduleMidiRender();
    };
    syncMidiInputs();
  } catch (error) {
    midiState.accessState = error && /denied|security/i.test(String(error.message || error)) ? "denied" : "error";
    midiState.lastError = error.message || String(error);
    renderMidiScene();
  }
}

function renderSetScene() {
  const pcsList = currentSetList();
  if (pcsList.length === 0) {
    setSummaryEl.textContent = "Select at least one pitch class.";
    setClockEl.innerHTML = "";
    setEvennessEl.innerHTML = "";
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
    const evennessSvg = svgString(arena, wasm.lmt_svg_evenness_chart);

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
    setEvennessEl.innerHTML = evennessSvg;
    normalizeSvgPreview(setClockEl, { maxHeight: 420, squareWidth: 420, mediumWidth: 520 });
    normalizeSvgPreview(setEvennessEl, { maxHeight: 520, squareWidth: 420, mediumWidth: 520, wideWidth: 620, ultraWideWidth: 680, padXRatio: 0.05, padYRatio: 0.04 });
    const evennessSvgNode = setEvennessEl.querySelector("svg");
    const setEvennessFeatures = evennessSvgNode ? {
      ringCount: evennessSvgNode.querySelectorAll(".ring").length,
      dotCount: evennessSvgNode.querySelectorAll(".dot").length,
    } : { ringCount: 0, dotCount: 0 };
    updateSummaryScene("set", {
      selectedCount: pcsList.length,
      setHex: `0x${setValue.toString(16).padStart(3, "0")}`,
      chordName,
      primeHex: `0x${prime.toString(16).padStart(3, "0")}`,
      setEvennessFeatures,
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
    keyStaffEl.innerHTML = svgString(arena, wasm.lmt_svg_key_staff, tonic, quality);
    normalizeSvgPreview(keyStaffEl, { maxHeight: 240, squareWidth: 780, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1120, padXRatio: 0.04, padYRatio: 0.12 });
    const keyStaffFeatures = inspectStaffSvg(keyStaffEl.querySelector("svg"));

    updateSummaryScene("key", {
      tonic: noteName(tonic),
      quality: quality === 0 ? "major" : "minor",
      noteCount: orbit.ordered.length,
      degrees: degreeCards.length,
      keyStaffFeatures,
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
    normalizeSvgPreview(chordStaffEl, { maxHeight: 320, squareWidth: 620, mediumWidth: 780, wideWidth: 920, ultraWideWidth: 1040, padXRatio: 0.05, padYRatio: 0.12 });
    const staffFeatures = inspectStaffSvg(chordStaffEl.querySelector("svg"));

    updateSummaryScene("chord", {
      root: noteName(root),
      chordName,
      roman,
      inKey,
      staffFeatures,
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
    ["midi", renderMidiScene],
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
  connectMidiEl.addEventListener("click", async () => {
    await connectMidi();
    if (midiState.accessState === "connected") {
      setStatus(`${MIDI_SCENE_TITLE} connected.`);
    } else if (midiState.accessState === "unsupported") {
      setStatus(`${MIDI_SCENE_TITLE} unavailable in this browser.`, "error");
    } else if (midiState.accessState === "denied" || midiState.accessState === "error") {
      setStatus(`${MIDI_SCENE_TITLE} error: ${midiState.lastError || "unable to connect"}`, "error");
    }
  });
  midiSaveSnapshotEl.addEventListener("click", () => {
    const saved = saveMidiSnapshot();
    renderMidiScene();
    setStatus(saved ? `${MIDI_SCENE_TITLE} snapshot saved for ${currentMidiContext().label}.` : `${MIDI_SCENE_TITLE} snapshot ignored because nothing changed.`);
  });
  midiReturnLiveEl.addEventListener("click", () => {
    returnMidiSceneToLive();
    setStatus(`${MIDI_SCENE_TITLE} returned to live input.`);
  });
  midiSnapshotsEl.addEventListener("click", (event) => {
    const button = event.target.closest("[data-midi-snapshot]");
    if (!button) return;
    setMidiSnapshotPreview(button.getAttribute("data-midi-snapshot"));
    const snapshot = midiState.snapshots.find((one) => one.id === button.getAttribute("data-midi-snapshot"));
    setStatus(`${MIDI_SCENE_TITLE} snapshot recalled${snapshot?.contextLabel ? ` in ${snapshot.contextLabel}` : ""}.`);
  });
  [midiTonicEl, midiModeEl].forEach((node) => node.addEventListener("change", () => {
    renderMidiScene();
    setStatus(`${MIDI_SCENE_TITLE} context set to ${currentMidiContext().label}.`);
  }));
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
  createNoteSelectors(midiTonicEl);
  populateModeSelect(midiModeEl);
  createNoteSelectors(keyTonicEl);
  createNoteSelectors(chordRootEl);
  createNoteSelectors(chordKeyTonicEl);
  buildToggleGrid();
  hydrateMidiSnapshots();
  midiTonicEl.value = String(MIDI_DEFAULT_TONIC);
  midiModeEl.value = String(MIDI_DEFAULT_MODE);
  midiCaptionEl.textContent = "Connect MIDI to listen to every browser MIDI input, sustain pedal, and middle-pedal snapshots.";
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
  gallerySummary.sceneCount = Math.max(Number(manifest.meta.sceneCount || 0), document.querySelectorAll(".scene-card").length);
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
    connectMidi().catch((error) => {
      midiState.accessState = "error";
      midiState.lastError = error.message || String(error);
      renderMidiScene();
    });
  } catch (error) {
    gallerySummary.ready = false;
    gallerySummary.errors = [error.message];
    setStatus(`Failed to initialize gallery: ${error.message}`, "error");
    console.error(error);
  }
}

main();
