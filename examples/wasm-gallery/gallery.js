const NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
const MODE_AEOLIAN = 5;
const SCALE_DIATONIC = 0;
const GUIDE_DOT_BYTES = 8;
const CONTEXT_SUGGESTION_BYTES = 12;
const decoder = new TextDecoder();
const encoder = new TextEncoder();
const CUSTOM_PRESET_VALUE = "custom";
const captureMode = new URLSearchParams(window.location.search).get("capture") === "1";
const MIDI_SNAPSHOT_STORAGE_KEY = "lmt.gallery.midi.snapshots";
const GALLERY_PREVIEW_MODE_STORAGE_KEY = "lmt.gallery.preview.mode";
const GALLERY_MINI_INSTRUMENT_STORAGE_KEY = "lmt.gallery.mini.instrument";
const MIDI_SCENE_TITLE = "Live MIDI Compass";
const MIDI_DEFAULT_TONIC = 0;
const MIDI_DEFAULT_MODE = 0;
const MIDI_DEFAULT_PROFILE = 0;
const PREVIEW_MODE_SVG = "svg";
const PREVIEW_MODE_BITMAP = "bitmap";
const MINI_INSTRUMENT_OFF = "off";
const MINI_INSTRUMENT_PIANO = "piano";
const MINI_INSTRUMENT_FRET = "fret";
const STANDARD_GUITAR_TUNING = Object.freeze([40, 45, 50, 55, 59, 64]);
const STANDARD_GUITAR_LABEL = "EADGBE";
const MIDI_FRET_MAX_FRET = 12;
const MIDI_FRET_MAX_SPAN = 4;
const MIDI_FRET_ROW_CAP = 48;
const PC_COLORS = Object.freeze([
  "#0000cc",
  "#aa44ff",
  "#ff00ff",
  "#a11666",
  "#ee0022",
  "#ff9911",
  "#ffee00",
  "#11ee00",
  "#009944",
  "#00bbbb",
  "#1166bb",
  "#2288ff",
]);
const VOICE_COLORS = Object.freeze([
  "#db6a38",
  "#1f7d86",
  "#7d526c",
  "#2b4fa2",
  "#9a3c56",
  "#2b8454",
  "#87561f",
  "#475569",
]);
const DEFAULT_COUNTERPOINT_PROFILE_NAMES = Object.freeze([
  "species",
  "tonal-chorale",
  "modal-polyphony",
  "jazz-close-leading",
  "free-contemporary",
]);
const DEFAULT_CADENCE_DESTINATION_NAMES = Object.freeze([
  "stable-continuation",
  "pre-dominant-arrival",
  "dominant-arrival",
  "authentic-arrival",
  "half-arrival",
  "deceptive-pull",
]);
const DEFAULT_SUSPENSION_STATE_NAMES = Object.freeze([
  "none",
  "preparation",
  "suspension",
  "resolution",
  "unresolved",
]);
const ORBIFOLD_QUALITY_NAMES = Object.freeze([
  "major",
  "minor",
  "diminished",
  "augmented",
]);
const CADENCE_LABELS = Object.freeze([
  "none",
  "stable",
  "pre-dominant",
  "dominant",
  "cadential six-four",
  "authentic arrival",
  "half arrival",
  "deceptive pull",
]);
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
  "lmt_counterpoint_max_voices",
  "lmt_counterpoint_history_capacity",
  "lmt_counterpoint_rule_profile_count",
  "lmt_counterpoint_rule_profile_name",
  "lmt_sizeof_voiced_state",
  "lmt_sizeof_voiced_history",
  "lmt_sizeof_next_step_suggestion",
  "lmt_cadence_destination_count",
  "lmt_cadence_destination_name",
  "lmt_suspension_state_count",
  "lmt_suspension_state_name",
  "lmt_sizeof_cadence_destination_score",
  "lmt_sizeof_suspension_machine_summary",
  "lmt_orbifold_triad_node_count",
  "lmt_sizeof_orbifold_triad_node",
  "lmt_orbifold_triad_node_at",
  "lmt_find_orbifold_triad_node",
  "lmt_orbifold_triad_edge_count",
  "lmt_sizeof_orbifold_triad_edge",
  "lmt_orbifold_triad_edge_at",
  "lmt_voiced_history_reset",
  "lmt_build_voiced_state",
  "lmt_voiced_history_push",
  "lmt_classify_motion",
  "lmt_evaluate_motion_profile",
  "lmt_rank_next_steps",
  "lmt_rank_cadence_destinations",
  "lmt_analyze_suspension_machine",
  "lmt_next_step_reason_count",
  "lmt_next_step_reason_name",
  "lmt_next_step_warning_count",
  "lmt_next_step_warning_name",
  "lmt_mode_spelling_quality",
  "lmt_spell_note",
  "lmt_spell_note_parts",
  "lmt_chord",
  "lmt_chord_name",
  "lmt_roman_numeral",
  "lmt_roman_numeral_parts",
  "lmt_fret_to_midi_n",
  "lmt_midi_to_fret_positions_n",
  "lmt_generate_voicings_n",
  "lmt_rank_context_suggestions",
  "lmt_preferred_voicing_n",
  "lmt_pitch_class_guide_n",
  "lmt_frets_to_url_n",
  "lmt_url_to_frets_n",
  "lmt_svg_clock_optc",
  "lmt_svg_optic_k_group",
  "lmt_svg_evenness_chart",
  "lmt_svg_evenness_field",
  "lmt_svg_fret",
  "lmt_svg_fret_n",
  "lmt_svg_fret_tuned_n",
  "lmt_svg_chord_staff",
  "lmt_svg_key_staff",
  "lmt_svg_keyboard",
  "lmt_svg_piano_staff",
  "lmt_bitmap_clock_optc_rgba",
  "lmt_bitmap_optic_k_group_rgba",
  "lmt_bitmap_evenness_chart_rgba",
  "lmt_bitmap_evenness_field_rgba",
  "lmt_bitmap_fret_rgba",
  "lmt_bitmap_fret_n_rgba",
  "lmt_bitmap_fret_tuned_n_rgba",
  "lmt_bitmap_chord_staff_rgba",
  "lmt_bitmap_key_staff_rgba",
  "lmt_bitmap_keyboard_rgba",
  "lmt_bitmap_piano_staff_rgba",
];

const statusEl = document.getElementById("status");
const previewModeSvgEl = document.getElementById("preview-mode-svg");
const previewModeBitmapEl = document.getElementById("preview-mode-bitmap");
const miniInstrumentModeEl = document.getElementById("mini-instrument-mode");
const pcsToggleGrid = document.getElementById("pcs-toggle-grid");
const midiCaptionEl = document.getElementById("midi-caption");
const midiStatusPillsEl = document.getElementById("midi-status-pills");
const midiDevicesEl = document.getElementById("midi-devices");
const midiSummaryEl = document.getElementById("midi-summary");
const midiNotesEl = document.getElementById("midi-notes");
const midiHistoryEl = document.getElementById("midi-history");
const midiClockEl = document.getElementById("midi-clock");
const midiOpticKEl = document.getElementById("midi-optic-k");
const midiEvennessEl = document.getElementById("midi-evenness");
const midiStaffEl = document.getElementById("midi-staff");
const midiKeyboardEl = document.getElementById("midi-keyboard");
const midiCurrentFretEl = document.getElementById("midi-current-fret");
const midiHorizonEl = document.getElementById("midi-horizon");
const midiBraidEl = document.getElementById("midi-braid");
const midiWeatherEl = document.getElementById("midi-weather");
const midiRiskRadarEl = document.getElementById("midi-risk-radar");
const midiCadenceFunnelEl = document.getElementById("midi-cadence-funnel");
const midiSuspensionMachineEl = document.getElementById("midi-suspension-machine");
const midiOrbifoldRibbonEl = document.getElementById("midi-orbifold-ribbon");
const midiCommonToneConstellationEl = document.getElementById("midi-common-tone-constellation");
const midiSuggestionsEl = document.getElementById("midi-suggestions");
const midiSnapshotsEl = document.getElementById("midi-snapshots");
const connectMidiEl = document.getElementById("connect-midi");
const midiSaveSnapshotEl = document.getElementById("midi-save-snapshot");
const midiReturnLiveEl = document.getElementById("midi-return-live");
const midiTonicEl = document.getElementById("midi-tonic");
const midiModeEl = document.getElementById("midi-mode");
const midiProfileEl = document.getElementById("midi-profile");

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
const setOpticKEl = document.getElementById("set-optic-k");
const setEvennessEl = document.getElementById("set-evenness");
const setMiniEl = document.getElementById("set-mini");
const keyNotesEl = document.getElementById("key-notes");
const keyDegreesEl = document.getElementById("key-degrees");
const keyClockEl = document.getElementById("key-clock");
const keyStaffEl = document.getElementById("key-staff");
const keyKeyboardEl = document.getElementById("key-keyboard");
const keyMiniEl = document.getElementById("key-mini");
const chordSummaryEl = document.getElementById("chord-summary");
const chordNotesEl = document.getElementById("chord-notes");
const chordClockEl = document.getElementById("chord-clock");
const chordStaffEl = document.getElementById("chord-staff");
const chordMiniEl = document.getElementById("chord-mini");
const progressionSummaryEl = document.getElementById("progression-summary");
const progressionCardsEl = document.getElementById("progression-cards");
const progressionClockEl = document.getElementById("progression-clock");
const progressionNotesEl = document.getElementById("progression-notes");
const progressionMiniEl = document.getElementById("progression-mini");
const compareLeftClockEl = document.getElementById("compare-left-clock");
const compareOverlapClockEl = document.getElementById("compare-overlap-clock");
const compareRightClockEl = document.getElementById("compare-right-clock");
const compareSummaryEl = document.getElementById("compare-summary");
const compareChipsEl = document.getElementById("compare-chips");
const compareMiniEl = document.getElementById("compare-mini");
const fretSvgEl = document.getElementById("fret-svg");
const fretSummaryEl = document.getElementById("fret-summary");
const fretNotesEl = document.getElementById("fret-notes");
const fretVoicingsEl = document.getElementById("fret-voicings");
const fretMiniEl = document.getElementById("fret-mini");

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
let counterpointReasonNames = [];
let counterpointWarningNames = [];
let counterpointProfileNames = DEFAULT_COUNTERPOINT_PROFILE_NAMES.slice();
let counterpointCadenceDestinationNames = DEFAULT_CADENCE_DESTINATION_NAMES.slice();
let counterpointSuspensionStateNames = DEFAULT_SUSPENSION_STATE_NAMES.slice();
let counterpointStructSizes = {
  voicedState: 0,
  voicedHistory: 0,
  nextStepSuggestion: 0,
  cadenceDestinationScore: 0,
  suspensionMachineSummary: 0,
  orbifoldTriadNode: 0,
  orbifoldTriadEdge: 0,
  maxVoices: 8,
  historyCapacity: 4,
};
let orbifoldTriadNodes = [];
let orbifoldTriadEdges = [];
const galleryUiState = {
  previewMode: PREVIEW_MODE_SVG,
  miniInstrument: MINI_INSTRUMENT_OFF,
};

const gallerySummary = {
  ready: false,
  manifestLoaded: false,
  sceneCount: 0,
  previewMode: PREVIEW_MODE_SVG,
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
  historyFrames: [],
  snapshots: [],
  activeSnapshotId: null,
  hoveredSuggestionIndex: null,
  renderQueued: false,
  lastError: "",
  lastEventText: "Awaiting MIDI note input.",
  lastChangedAt: 0,
};

function setStatus(message, tone = "ready") {
  statusEl.textContent = message;
  statusEl.style.color = tone === "error" ? "#b03620" : "#1e7c84";
}

function loadPreviewModePreference() {
  try {
    const raw = window.localStorage?.getItem(GALLERY_PREVIEW_MODE_STORAGE_KEY);
    if (raw === PREVIEW_MODE_BITMAP || raw === PREVIEW_MODE_SVG) return raw;
  } catch (_error) {
    // Ignore storage failures.
  }
  return PREVIEW_MODE_SVG;
}

function persistPreviewMode(mode) {
  try {
    window.localStorage?.setItem(GALLERY_PREVIEW_MODE_STORAGE_KEY, mode);
  } catch (_error) {
    // Ignore storage failures.
  }
}

function loadMiniInstrumentPreference() {
  try {
    const raw = window.localStorage?.getItem(GALLERY_MINI_INSTRUMENT_STORAGE_KEY);
    if (raw === MINI_INSTRUMENT_PIANO || raw === MINI_INSTRUMENT_FRET || raw === MINI_INSTRUMENT_OFF) return raw;
  } catch (_error) {
    // Ignore storage failures.
  }
  return MINI_INSTRUMENT_OFF;
}

function persistMiniInstrument(mode) {
  try {
    window.localStorage?.setItem(GALLERY_MINI_INSTRUMENT_STORAGE_KEY, mode);
  } catch (_error) {
    // Ignore storage failures.
  }
}

function updatePreviewModeUi() {
  const isBitmap = galleryUiState.previewMode === PREVIEW_MODE_BITMAP;
  previewModeSvgEl.classList.toggle("is-active", !isBitmap);
  previewModeBitmapEl.classList.toggle("is-active", isBitmap);
  previewModeSvgEl.setAttribute("aria-pressed", isBitmap ? "false" : "true");
  previewModeBitmapEl.setAttribute("aria-pressed", isBitmap ? "true" : "false");
  gallerySummary.previewMode = galleryUiState.previewMode;
}

function setPreviewMode(mode, { persist = true, rerender = true } = {}) {
  galleryUiState.previewMode = mode === PREVIEW_MODE_BITMAP ? PREVIEW_MODE_BITMAP : PREVIEW_MODE_SVG;
  updatePreviewModeUi();
  if (persist) persistPreviewMode(galleryUiState.previewMode);
  if (rerender && wasm && memory) renderAll();
}

function isBitmapPreviewMode() {
  return galleryUiState.previewMode === PREVIEW_MODE_BITMAP;
}

function setMiniInstrumentMode(mode, { persist = true, rerender = true } = {}) {
  if (mode !== MINI_INSTRUMENT_PIANO && mode !== MINI_INSTRUMENT_FRET) {
    galleryUiState.miniInstrument = MINI_INSTRUMENT_OFF;
  } else {
    galleryUiState.miniInstrument = mode;
  }
  miniInstrumentModeEl.value = galleryUiState.miniInstrument;
  if (persist) persistMiniInstrument(galleryUiState.miniInstrument);
  if (rerender && wasm && memory) renderAll();
}

function miniInstrumentMode() {
  return galleryUiState.miniInstrument;
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

function populateCounterpointProfileSelect(select) {
  select.innerHTML = counterpointProfileNames.map((name, index) =>
    `<option value="${index}">${escapeHtml(name)}</option>`).join("");
}

function readCStringPtr(ptr) {
  return ptr ? readCString(ptr) : "";
}

function loadCounterpointMetadata() {
  const profileCount = wasm.lmt_counterpoint_rule_profile_count();
  counterpointProfileNames = Array.from({ length: profileCount }, (_unused, index) =>
    readCStringPtr(wasm.lmt_counterpoint_rule_profile_name(index))) || DEFAULT_COUNTERPOINT_PROFILE_NAMES.slice();
  if (counterpointProfileNames.length === 0) {
    counterpointProfileNames = DEFAULT_COUNTERPOINT_PROFILE_NAMES.slice();
  }

  const cadenceDestinationCount = wasm.lmt_cadence_destination_count();
  counterpointCadenceDestinationNames = Array.from({ length: cadenceDestinationCount }, (_unused, index) =>
    readCStringPtr(wasm.lmt_cadence_destination_name(index))) || DEFAULT_CADENCE_DESTINATION_NAMES.slice();
  if (counterpointCadenceDestinationNames.length === 0) {
    counterpointCadenceDestinationNames = DEFAULT_CADENCE_DESTINATION_NAMES.slice();
  }

  const suspensionStateCount = wasm.lmt_suspension_state_count();
  counterpointSuspensionStateNames = Array.from({ length: suspensionStateCount }, (_unused, index) =>
    readCStringPtr(wasm.lmt_suspension_state_name(index))) || DEFAULT_SUSPENSION_STATE_NAMES.slice();
  if (counterpointSuspensionStateNames.length === 0) {
    counterpointSuspensionStateNames = DEFAULT_SUSPENSION_STATE_NAMES.slice();
  }

  const reasonCount = wasm.lmt_next_step_reason_count();
  counterpointReasonNames = Array.from({ length: reasonCount }, (_unused, index) =>
    readCStringPtr(wasm.lmt_next_step_reason_name(index)));
  const warningCount = wasm.lmt_next_step_warning_count();
  counterpointWarningNames = Array.from({ length: warningCount }, (_unused, index) =>
    readCStringPtr(wasm.lmt_next_step_warning_name(index)));

  counterpointStructSizes = {
    maxVoices: wasm.lmt_counterpoint_max_voices(),
    historyCapacity: wasm.lmt_counterpoint_history_capacity(),
    voicedState: wasm.lmt_sizeof_voiced_state(),
    voicedHistory: wasm.lmt_sizeof_voiced_history(),
    nextStepSuggestion: wasm.lmt_sizeof_next_step_suggestion(),
    cadenceDestinationScore: wasm.lmt_sizeof_cadence_destination_score(),
    suspensionMachineSummary: wasm.lmt_sizeof_suspension_machine_summary(),
    orbifoldTriadNode: wasm.lmt_sizeof_orbifold_triad_node(),
    orbifoldTriadEdge: wasm.lmt_sizeof_orbifold_triad_edge(),
  };

  const arena = new ScratchArena();
  try {
    const nodeCount = wasm.lmt_orbifold_triad_node_count();
    orbifoldTriadNodes = Array.from({ length: nodeCount }, (_unused, index) => {
      const ptr = arena.alloc(counterpointStructSizes.orbifoldTriadNode || 16, 4);
      const written = wasm.lmt_orbifold_triad_node_at(index, ptr);
      if (!written) return null;
      const view = new DataView(memory.buffer, ptr, counterpointStructSizes.orbifoldTriadNode || 16);
      return {
        index,
        setValue: view.getUint16(0, true),
        root: view.getUint8(2),
        quality: view.getUint8(3),
        x: view.getFloat32(4, true),
        y: view.getFloat32(8, true),
      };
    }).filter(Boolean);

    const edgeCount = wasm.lmt_orbifold_triad_edge_count();
    orbifoldTriadEdges = Array.from({ length: edgeCount }, (_unused, index) => {
      const ptr = arena.alloc(counterpointStructSizes.orbifoldTriadEdge || 4, 4);
      const written = wasm.lmt_orbifold_triad_edge_at(index, ptr);
      if (!written) return null;
      const view = new DataView(memory.buffer, ptr, counterpointStructSizes.orbifoldTriadEdge || 4);
      return {
        fromIndex: view.getUint8(0),
        toIndex: view.getUint8(1),
      };
    }).filter(Boolean);
  } finally {
    arena.release();
  }
}

function modeSet(tonic, modeType) {
  return wasm.lmt_mode(modeType, tonic);
}

function modeSpellingQuality(tonic, modeType) {
  return wasm.lmt_mode_spelling_quality(tonic % 12, modeType);
}

function currentMidiProfile() {
  return Number.parseInt(midiProfileEl.value || String(MIDI_DEFAULT_PROFILE), 10);
}

function cadenceLabel(value) {
  return CADENCE_LABELS[value] || "none";
}

function cadenceDestinationLabel(value) {
  return counterpointCadenceDestinationNames[value] || DEFAULT_CADENCE_DESTINATION_NAMES[value] || "stable-continuation";
}

function suspensionStateLabel(value) {
  return counterpointSuspensionStateNames[value] || DEFAULT_SUSPENSION_STATE_NAMES[value] || "none";
}

function orbifoldTriadNodeForIndex(index) {
  return Number.isInteger(index) && index >= 0 && index < orbifoldTriadNodes.length ? orbifoldTriadNodes[index] : null;
}

function orbifoldTriadNodeIndexForSet(setValue) {
  if (!setValue || typeof wasm?.lmt_find_orbifold_triad_node !== "function") return -1;
  const index = wasm.lmt_find_orbifold_triad_node(setValue);
  return index >= 0 && index < orbifoldTriadNodes.length ? index : -1;
}

function orbifoldTriadQualityName(value) {
  return ORBIFOLD_QUALITY_NAMES[value] || "major";
}

function orbifoldTriadQualityFill(value) {
  switch (value) {
    case 1:
      return "#0b007e";
    case 2:
      return "#004700";
    case 3:
      return "#a11666";
    default:
      return "#02fe02";
  }
}

function orbifoldTriadQualityStroke(value) {
  return value === 0 ? "#000000" : "#ffffff";
}

function orbifoldTriadLabel(node) {
  if (!node) return "";
  const suffix = (() => {
    switch (node.quality) {
      case 1:
        return "m";
      case 2:
        return "o";
      case 3:
        return "+";
      default:
        return "";
    }
  })();
  return `${noteName(node.root)}${suffix}`;
}

function cadenceDestinationFromCadenceEffect(cadenceEffect) {
  switch (cadenceEffect) {
    case 2:
      return 1;
    case 3:
    case 4:
      return 2;
    case 5:
      return 3;
    case 6:
      return 4;
    case 7:
      return 5;
    default:
      return 0;
  }
}

function decodeMotionSummaryFromView(view, base = 0) {
  const voiceMotionCount = view.getUint8(base + 0);
  const voiceMotions = [];
  for (let index = 0; index < Math.min(voiceMotionCount, counterpointStructSizes.maxVoices || 8); index += 1) {
    const offset = base + 17 + index * 8;
    voiceMotions.push({
      voiceId: view.getUint8(offset + 0),
      fromMidi: view.getUint8(offset + 1),
      toMidi: view.getUint8(offset + 2),
      delta: view.getInt8(offset + 3),
      absDelta: view.getUint8(offset + 4),
      motionClass: view.getUint8(offset + 5),
      retained: view.getUint8(offset + 6) !== 0,
    });
  }
  return {
    voiceMotionCount,
    commonToneCount: view.getUint8(base + 1),
    stepCount: view.getUint8(base + 2),
    leapCount: view.getUint8(base + 3),
    contraryCount: view.getUint8(base + 4),
    similarCount: view.getUint8(base + 5),
    parallelCount: view.getUint8(base + 6),
    obliqueCount: view.getUint8(base + 7),
    crossingCount: view.getUint8(base + 8),
    overlapCount: view.getUint8(base + 9),
    totalMotion: view.getUint16(base + 10, true),
    outerIntervalBefore: view.getInt8(base + 12),
    outerIntervalAfter: view.getInt8(base + 13),
    outerMotion: view.getUint8(base + 14),
    previousCadenceState: view.getUint8(base + 15),
    currentCadenceState: view.getUint8(base + 16),
    voiceMotions,
  };
}

function decodeMotionSummaryFromPointer(ptr) {
  if (!ptr) return null;
  const view = new DataView(memory.buffer, ptr, 96);
  return decodeMotionSummaryFromView(view, 0);
}

function decodeMotionEvaluationFromView(view, base = 0) {
  return {
    score: view.getInt32(base + 0, true),
    preferredScore: view.getInt16(base + 4, true),
    penaltyScore: view.getInt16(base + 6, true),
    cadenceScore: view.getInt16(base + 8, true),
    spacingPenalty: view.getInt16(base + 10, true),
    leapPenalty: view.getInt16(base + 12, true),
    disallowedCount: view.getUint8(base + 14),
    disallowed: view.getUint8(base + 15) !== 0,
  };
}

function decodeMotionEvaluationFromPointer(ptr) {
  if (!ptr) return null;
  const view = new DataView(memory.buffer, ptr, 32);
  return decodeMotionEvaluationFromView(view, 0);
}

function namesFromMask(mask, names) {
  const out = [];
  for (let index = 0; index < names.length; index += 1) {
    if ((mask & (1 << index)) !== 0) out.push(names[index]);
  }
  return out;
}

function contextSuggestions(arena, setValue, midiNotes, context) {
  if (setValue === 0) return [];
  const midiPtr = writeU8Array(arena, midiNotes);
  const outCap = 12;
  const outPtr = arena.alloc(outCap * CONTEXT_SUGGESTION_BYTES, 4);
  const total = wasm.lmt_rank_context_suggestions(
    setValue,
    midiPtr,
    midiNotes.length,
    context.tonic,
    context.modeType,
    outPtr,
    outCap,
  );
  const count = Math.min(total, outCap);
  const view = new DataView(memory.buffer, outPtr, count * CONTEXT_SUGGESTION_BYTES);
  const suggestions = [];
  for (let index = 0; index < count; index += 1) {
    const offset = index * CONTEXT_SUGGESTION_BYTES;
    const expanded = view.getUint16(offset + 4, true);
    const pc = view.getUint8(offset + 6);
    const overlap = view.getUint8(offset + 7);
    const outsideCount = view.getUint8(offset + 8);
    const inContext = view.getUint8(offset + 9) === 1;
    const clusterFree = view.getUint8(offset + 10) === 1;
    const readsAsNamedChord = view.getUint8(offset + 11) === 1;
    const rawName = rawChordName(expanded);
    const reason = [];
    reason.push(inContext ? `inside ${context.label}` : `outside ${context.label}`);
    reason.push(`context overlap ${overlap}/${wasm.lmt_pcs_cardinality(expanded)}`);
    if (readsAsNamedChord && rawName && rawName !== "Unknown") reason.push(`reads as ${rawName}`);
    reason.push(clusterFree ? "avoids cluster pressure" : "adds cluster pressure");
    suggestions.push({
      pc,
      name: spellNote(pc, context.tonic, context.quality),
      chordLabel: friendlyChordName(rawName),
      reason: reason.join(" · "),
      score: view.getInt32(offset, true),
      expanded,
      overlap,
      outsideCount,
      inContext,
      clusterFree,
      readsAsNamedChord,
    });
  }
  return suggestions.slice(0, 4);
}

function currentMidiContext() {
  const tonic = Number.parseInt(midiTonicEl.value, 10);
  const modeType = Number.parseInt(midiModeEl.value, 10);
  const setValue = modeSet(tonic, modeType);
  const quality = modeSpellingQuality(tonic, modeType);
  return {
    tonic,
    modeType,
    setValue,
    quality,
    label: `${spellNote(tonic, tonic, quality)} ${modeName(modeType)}`,
  };
}

function keyboardPreviewNotesForSet(setValue, tonic) {
  const ordered = orderedMembersFromSet(setValue, tonic);
  const tonicAnchor = 60 + tonic;
  return ordered.map((pc) => {
    let midi = 60 + pc;
    if (midi < tonicAnchor) midi += 12;
    return midi;
  });
}

function keyboardPreviewNotesForContext(context) {
  return keyboardPreviewNotesForSet(context.setValue, context.tonic);
}

function keyboardRangeForNotes(notes, fallbackLow = 48, fallbackHigh = 84) {
  if (!Array.isArray(notes) || notes.length === 0) {
    return { low: fallbackLow, high: fallbackHigh };
  }

  const minNote = Math.min(...notes);
  const maxNote = Math.max(...notes);
  let low = Math.max(21, Math.floor((minNote - 3) / 12) * 12);
  let high = Math.min(108, (Math.ceil((maxNote + 4) / 12) * 12) - 1);

  if (high - low < 35) {
    const center = (minNote + maxNote) / 2;
    low = Math.max(21, Math.floor((center - 18) / 12) * 12);
    high = Math.min(108, low + 35);
  }

  if (high <= low) {
    return { low: fallbackLow, high: fallbackHigh };
  }
  return { low, high };
}

function svgString(arena, renderFn, ...args) {
  const required = renderFn(...args, 0, 0);
  const bufPtr = arena.alloc(required + 1, 1);
  renderFn(...args, bufPtr, required + 1);
  return readCString(bufPtr);
}

function rgbaToPngDataUrl(rgbaBytes, width, height, cropBox = null, outputWidth = width, outputHeight = height) {
  const sourceCanvas = document.createElement("canvas");
  sourceCanvas.width = width;
  sourceCanvas.height = height;
  const sourceCtx = sourceCanvas.getContext("2d");
  if (!sourceCtx) {
    throw new Error("failed to acquire 2d context for bitmap preview");
  }
  const imageData = new ImageData(new Uint8ClampedArray(rgbaBytes), width, height);
  sourceCtx.putImageData(imageData, 0, 0);

  if (!cropBox) {
    return sourceCanvas.toDataURL("image/png");
  }

  const outputCanvas = document.createElement("canvas");
  outputCanvas.width = outputWidth;
  outputCanvas.height = outputHeight;
  const outputCtx = outputCanvas.getContext("2d");
  if (!outputCtx) {
    throw new Error("failed to acquire crop context for bitmap preview");
  }
  outputCtx.clearRect(0, 0, outputWidth, outputHeight);
  outputCtx.drawImage(
    sourceCanvas,
    cropBox.x,
    cropBox.y,
    cropBox.width,
    cropBox.height,
    0,
    0,
    outputWidth,
    outputHeight,
  );
  return outputCanvas.toDataURL("image/png");
}

function bitmapRgbaFromCall(arena, width, height, renderFn, label) {
  const rgbaBytes = width * height * 4;
  const rgbaPtr = arena.alloc(rgbaBytes, 1);
  const written = renderFn(rgbaPtr, rgbaBytes);
  if (written !== rgbaBytes) {
    throw new Error(`${label} wrote ${written}/${rgbaBytes}`);
  }
  return new Uint8Array(memory.buffer.slice(rgbaPtr, rgbaPtr + rgbaBytes));
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
    preserveViewBox = false,
  } = options;
  const svgs = host.querySelectorAll("svg");
  for (const svg of svgs) {
    svg.style.display = "block";
    svg.style.maxWidth = "100%";
    if (!svg.dataset.originalViewBox) {
      const originalViewBox = svg.getAttribute("viewBox");
      if (originalViewBox) svg.dataset.originalViewBox = originalViewBox;
    }

    try {
      if (preserveViewBox) {
        const viewBox = parseViewBox(svg.dataset.originalViewBox || svg.getAttribute("viewBox"));
        if (!viewBox || viewBox.width <= 0 || viewBox.height <= 0) {
          svg.dataset.previewNormalized = "0";
          continue;
        }

        const aspect = viewBox.width / viewBox.height;
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

        const fitted = fitPreviewDisplaySize(Math.min(availableWidth, targetWidth), aspect, maxHeight);
        svg.style.width = `${fitted.width}px`;
        svg.style.height = `${fitted.height}px`;
        svg.style.maxHeight = `${fitted.height}px`;
        svg.setAttribute("width", String(fitted.width));
        svg.setAttribute("height", String(fitted.height));
        svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
        svg.dataset.previewNormalized = "1";
        svg.dataset.previewAspect = aspect.toFixed(3);
        continue;
      }

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
      const fitted = fitPreviewDisplaySize(Math.min(availableWidth, targetWidth), aspect, maxHeight);
      svg.style.width = `${fitted.width}px`;
      svg.style.height = `${fitted.height}px`;
      svg.style.maxHeight = `${fitted.height}px`;
      svg.setAttribute("width", String(fitted.width));
      svg.setAttribute("height", String(fitted.height));
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

function setSvgPreview(host, svgMarkup, options = {}) {
  host.innerHTML = svgMarkup;
  normalizeSvgPreview(host, options);
}

function svgMarkupToDataUrl(svgMarkup) {
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgMarkup)}`;
}

function measureSvgPreviewLayout(host, svgMarkup, options = {}) {
  setSvgPreview(host, svgMarkup, options);
  const svg = host.querySelector("svg");
  if (!svg) {
    throw new Error("missing svg preview during bitmap measurement");
  }
  const rect = svg.getBoundingClientRect();
  const originalViewBox = parseViewBox(svg.dataset.originalViewBox || svg.getAttribute("viewBox"));
  const previewViewBox = parseViewBox(svg.getAttribute("viewBox"));
  return {
    displayWidth: Math.max(1, Math.round(rect.width)),
    displayHeight: Math.max(1, Math.round(rect.height)),
    originalViewBox,
    previewViewBox,
  };
}

function setSvgImagePreview(host, svgMarkup, alt, layout) {
  host.innerHTML = `<img class="svg-preview" data-preview-kind="svg" data-preview-normalized="1" src="${svgMarkupToDataUrl(svgMarkup)}" alt="${escapeHtml(alt)}" />`;
  const image = host.querySelector("img");
  if (!image) return;
  const aspect = layout.displayWidth / Math.max(layout.displayHeight, 1);
  image.dataset.previewAspect = aspect.toFixed(3);
  image.style.display = "block";
  image.style.width = `${layout.displayWidth}px`;
  image.style.height = `${layout.displayHeight}px`;
  image.style.maxWidth = "100%";
  image.style.maxHeight = `${layout.displayHeight}px`;
  if (layout.originalViewBox) {
    image.dataset.originalMinX = String(layout.originalViewBox.minX);
    image.dataset.originalMinY = String(layout.originalViewBox.minY);
    image.dataset.originalWidth = String(layout.originalViewBox.width);
    image.dataset.originalHeight = String(layout.originalViewBox.height);
  }
  if (layout.previewViewBox) {
    image.dataset.previewMinX = String(layout.previewViewBox.minX);
    image.dataset.previewMinY = String(layout.previewViewBox.minY);
    image.dataset.previewWidth = String(layout.previewViewBox.width);
    image.dataset.previewHeight = String(layout.previewViewBox.height);
  }
}

function setBitmapPreview(host, dataUrl, pixelWidth, pixelHeight, alt, displayWidth, displayHeight, layout = null) {
  const aspect = pixelWidth / pixelHeight;
  host.innerHTML = `<img class="bitmap-preview" data-preview-kind="bitmap" data-preview-normalized="1" data-preview-aspect="${aspect.toFixed(3)}" width="${pixelWidth}" height="${pixelHeight}" src="${dataUrl}" alt="${escapeHtml(alt)}" />`;
  const image = host.querySelector("img");
  if (!image) return;
  image.style.display = "block";
  image.style.width = `${displayWidth}px`;
  image.style.height = `${displayHeight}px`;
  image.style.maxWidth = "100%";
  image.style.maxHeight = `${displayHeight}px`;
  if (layout?.originalViewBox) {
    image.dataset.originalMinX = String(layout.originalViewBox.minX);
    image.dataset.originalMinY = String(layout.originalViewBox.minY);
    image.dataset.originalWidth = String(layout.originalViewBox.width);
    image.dataset.originalHeight = String(layout.originalViewBox.height);
  }
  if (layout?.previewViewBox) {
    image.dataset.previewMinX = String(layout.previewViewBox.minX);
    image.dataset.previewMinY = String(layout.previewViewBox.minY);
    image.dataset.previewWidth = String(layout.previewViewBox.width);
    image.dataset.previewHeight = String(layout.previewViewBox.height);
  }
}

function fitPreviewDisplaySize(targetWidth, aspect, maxHeight) {
  let width = Math.max(1, targetWidth);
  let height = width / Math.max(aspect, 0.0001);
  if (height > maxHeight) {
    height = maxHeight;
    width = height * Math.max(aspect, 0.0001);
  }
  return {
    width: Math.max(1, Math.round(width)),
    height: Math.max(1, Math.round(height)),
  };
}

function parseViewBox(raw) {
  const parts = String(raw || "")
    .trim()
    .split(/[\s,]+/)
    .map((value) => Number.parseFloat(value));
  if (parts.length !== 4 || parts.some((value) => !Number.isFinite(value))) {
    return null;
  }
  return {
    minX: parts[0],
    minY: parts[1],
    width: parts[2],
    height: parts[3],
  };
}

function renderPreviewSvgOrBitmap(host, { svgMarkup, bitmapRenderer, alt, options = {} }) {
  if (!isBitmapPreviewMode()) {
    const layout = measureSvgPreviewLayout(host, svgMarkup, options);
    const normalizedSvg = host.querySelector("svg")?.outerHTML || svgMarkup;
    setSvgImagePreview(host, normalizedSvg, alt, layout);
    return;
  }
  const layout = measureSvgPreviewLayout(host, svgMarkup, options);
  const deviceScale = Math.max(1, Math.min(2, window.devicePixelRatio || 1));
  const supersampleFactor = Math.max(1, options.supersampleFactor || 1);
  const pixelWidth = Math.max(1, Math.round(layout.displayWidth * deviceScale));
  const pixelHeight = Math.max(1, Math.round(layout.displayHeight * deviceScale));
  const widthScale = layout.originalViewBox && layout.previewViewBox
    ? layout.originalViewBox.width / Math.max(layout.previewViewBox.width, 1)
    : 1;
  const heightScale = layout.originalViewBox && layout.previewViewBox
    ? layout.originalViewBox.height / Math.max(layout.previewViewBox.height, 1)
    : 1;
  const sourcePixelWidth = Math.max(pixelWidth, Math.round(pixelWidth * widthScale * supersampleFactor));
  const sourcePixelHeight = Math.max(pixelHeight, Math.round(pixelHeight * heightScale * supersampleFactor));
  const cropBox = layout.originalViewBox && layout.previewViewBox ? {
    x: ((layout.previewViewBox.minX - layout.originalViewBox.minX) / Math.max(layout.originalViewBox.width, 1)) * sourcePixelWidth,
    y: ((layout.previewViewBox.minY - layout.originalViewBox.minY) / Math.max(layout.originalViewBox.height, 1)) * sourcePixelHeight,
    width: (layout.previewViewBox.width / Math.max(layout.originalViewBox.width, 1)) * sourcePixelWidth,
    height: (layout.previewViewBox.height / Math.max(layout.originalViewBox.height, 1)) * sourcePixelHeight,
  } : null;
  const sourceRgba = bitmapRenderer.renderRgba(sourcePixelWidth, sourcePixelHeight);
  const dataUrl = rgbaToPngDataUrl(sourceRgba, sourcePixelWidth, sourcePixelHeight, cropBox, pixelWidth, pixelHeight);
  setBitmapPreview(host, dataUrl, pixelWidth, pixelHeight, alt, layout.displayWidth, layout.displayHeight, layout);
}

function clockBitmapRgba(arena, setValue, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_clock_optc_rgba(setValue, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_clock_optc_rgba");
}

function opticKBitmapRgba(arena, setValue, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_optic_k_group_rgba(setValue, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_optic_k_group_rgba");
}

function evennessChartBitmapRgba(arena, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_evenness_chart_rgba(width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_evenness_chart_rgba");
}

function evennessFieldBitmapRgba(arena, setValue, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_evenness_field_rgba(setValue, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_evenness_field_rgba");
}

function chordStaffBitmapRgba(arena, chordType, root, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_chord_staff_rgba(chordType, root, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_chord_staff_rgba");
}

function keyStaffBitmapRgba(arena, tonic, quality, width, height) {
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_key_staff_rgba(tonic, quality, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_key_staff_rgba");
}

function keyboardBitmapRgba(arena, notes, rangeLow, rangeHigh, width, height) {
  const notesPtr = writeU8Array(arena, notes);
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_keyboard_rgba(notesPtr, notes.length, rangeLow, rangeHigh, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_keyboard_rgba");
}

function pianoStaffBitmapRgba(arena, notes, tonic, quality, width, height) {
  const notesPtr = writeU8Array(arena, notes);
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_piano_staff_rgba(notesPtr, notes.length, tonic, quality, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_piano_staff_rgba");
}

function standardFretBitmapRgba(arena, frets, width, height) {
  const fretsPtr = writeI8Array(arena, frets);
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_fret_rgba(fretsPtr, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_fret_rgba");
}

function fretBitmapRgba(arena, frets, windowStart, visibleFrets, width, height) {
  const fretsPtr = writeI8Array(arena, frets);
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_fret_n_rgba(fretsPtr, frets.length, windowStart, visibleFrets, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_fret_n_rgba");
}

function tunedFretBitmapRgba(arena, frets, tuning, windowStart, visibleFrets, width, height) {
  const fretsPtr = writeI8Array(arena, frets);
  const tuningPtr = writeU8Array(arena, tuning);
  return bitmapRgbaFromCall(arena, width, height, (rgbaPtr, rgbaBytes) =>
    wasm.lmt_bitmap_fret_tuned_n_rgba(fretsPtr, frets.length, tuningPtr, tuning.length, windowStart, visibleFrets, width, height, rgbaPtr, rgbaBytes),
  "lmt_bitmap_fret_tuned_n_rgba");
}

function isStandardTuning(tuning) {
  return Array.isArray(tuning)
    && tuning.length === STANDARD_GUITAR_TUNING.length
    && tuning.every((value, index) => value === STANDARD_GUITAR_TUNING[index]);
}

function fretWindowForVoicing(frets) {
  const positiveFrets = frets.filter((fret) => fret > 0);
  if (positiveFrets.length === 0) {
    return { windowStart: 0, visibleFrets: 4 };
  }
  const minPositive = Math.min(...positiveFrets);
  const maxPositive = Math.max(...positiveFrets);
  if (maxPositive <= 4) {
    return { windowStart: 0, visibleFrets: 4 };
  }
  const windowStart = Math.max(0, Math.min(minPositive - 1, maxPositive - 3));
  const visibleFrets = Math.max(4, Math.min(7, maxPositive - windowStart + 1));
  return { windowStart, visibleFrets };
}

function serializeFrets(arena, frets) {
  const fretsPtr = writeI8Array(arena, frets);
  const urlPtr = arena.alloc(128, 1);
  const urlBytes = wasm.lmt_frets_to_url_n(fretsPtr, frets.length, urlPtr, 128);
  return urlBytes > 0 ? readCString(urlPtr) : frets.join(",");
}

function fretBassMidi(frets, tuning) {
  let bass = null;
  for (let index = 0; index < Math.min(frets.length, tuning.length); index += 1) {
    const fret = frets[index];
    if (fret < 0) continue;
    const midi = tuning[index] + fret;
    if (bass == null || midi < bass) bass = midi;
  }
  return bass;
}

function preferredFretVoicing(arena, setValue, {
  tuning = STANDARD_GUITAR_TUNING,
  tuningLabel = STANDARD_GUITAR_LABEL,
  maxFret = MIDI_FRET_MAX_FRET,
  maxSpan = MIDI_FRET_MAX_SPAN,
  preferredBassPc = null,
} = {}) {
  if (!setValue) return null;
  const tuningPtr = writeU8Array(arena, tuning);
  const voicingPtr = arena.alloc(Math.max(1, tuning.length), 1);
  const preferredBassValue = preferredBassPc == null ? 255 : preferredBassPc;
  const rowCount = wasm.lmt_preferred_voicing_n(setValue, tuningPtr, tuning.length, maxFret, maxSpan, preferredBassValue, voicingPtr, tuning.length);
  if (rowCount === 0) {
    return null;
  }

  const bestFrets = Array.from(i8().subarray(voicingPtr, voicingPtr + tuning.length));
  const { windowStart, visibleFrets } = fretWindowForVoicing(bestFrets);
  return {
    frets: bestFrets,
    rowCount,
    windowStart,
    visibleFrets,
    url: serializeFrets(arena, bestFrets),
    tuningLabel,
    tuning: tuning.slice(),
    isStandardTuning: isStandardTuning(tuning),
    bassMidi: fretBassMidi(bestFrets, tuning),
  };
}

function genericFretVoicingForNotes(notes, tuningLabel = "Generic fret") {
  const ordered = Array.from(new Set((notes || []).filter((note) => Number.isFinite(note)))).sort((left, right) => left - right);
  if (ordered.length === 0) return null;
  const preferredFrets = [2, 4, 5, 7, 9, 11, 12, 14];
  const frets = ordered.map((midi, index) => {
    const preferred = preferredFrets[index % preferredFrets.length];
    return Math.max(0, Math.min(preferred, midi));
  });
  const tuning = ordered.map((midi, index) => Math.max(0, midi - frets[index]));
  const { windowStart, visibleFrets } = fretWindowForVoicing(frets);
  return {
    frets,
    rowCount: frets.length,
    windowStart,
    visibleFrets,
    url: frets.join(","),
    tuningLabel,
    tuning,
    isStandardTuning: false,
    bassMidi: ordered[0],
  };
}

function renderFretVoicingPreview(arena, host, voicing, alt, options = {}) {
  if (!voicing) {
    host.innerHTML = `<div class="output-block">No compact ${escapeHtml(STANDARD_GUITAR_LABEL)} voicing within ${MIDI_FRET_MAX_FRET} frets / span ${MIDI_FRET_MAX_SPAN}.</div>`;
    return false;
  }
  const fretsPtr = writeI8Array(arena, voicing.frets);
  const useStandard = voicing.isStandardTuning === true;
  const useTunedGeneric = !useStandard && Array.isArray(voicing.tuning) && voicing.tuning.length === voicing.frets.length;
  const tuningPtr = useTunedGeneric ? writeU8Array(arena, voicing.tuning) : 0;
  const svgMarkup = useStandard
    ? svgString(arena, wasm.lmt_svg_fret, fretsPtr)
    : (useTunedGeneric
      ? svgString(arena, wasm.lmt_svg_fret_tuned_n, fretsPtr, voicing.frets.length, tuningPtr, voicing.tuning.length, voicing.windowStart, voicing.visibleFrets)
      : svgString(arena, wasm.lmt_svg_fret_n, fretsPtr, voicing.frets.length, voicing.windowStart, voicing.visibleFrets));
  renderPreviewSvgOrBitmap(host, {
    svgMarkup,
    bitmapRenderer: {
      renderRgba: (width, height) => (useStandard
        ? standardFretBitmapRgba(arena, voicing.frets, width, height)
        : (useTunedGeneric
          ? tunedFretBitmapRgba(arena, voicing.frets, voicing.tuning, voicing.windowStart, voicing.visibleFrets, width, height)
          : fretBitmapRgba(arena, voicing.frets, voicing.windowStart, voicing.visibleFrets, width, height))),
    },
    alt,
    options,
  });
  return true;
}

function inspectKeyboardSvg(svg) {
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
}

function inspectKeyboardNotes(notes, rangeLow, rangeHigh) {
  const exact = new Set(notes);
  const pcs = new Set(notes.map((note) => note % 12));
  let selectedKeyCount = 0;
  let echoKeyCount = 0;
  let blackKeyCount = 0;
  let blackEchoSelectedCount = 0;
  for (let midi = rangeLow; midi <= rangeHigh; midi += 1) {
    const isBlack = [1, 3, 6, 8, 10].includes(midi % 12);
    if (isBlack) blackKeyCount += 1;
    if (exact.has(midi)) {
      selectedKeyCount += 1;
      if (isBlack) blackEchoSelectedCount += 1;
    } else if (pcs.has(midi % 12)) {
      echoKeyCount += 1;
      if (isBlack) blackEchoSelectedCount += 1;
    }
  }
  return { selectedKeyCount, echoKeyCount, blackKeyCount, blackEchoSelectedCount };
}

function parseSvgMarkup(svgMarkup) {
  if (!svgMarkup || !svgMarkup.includes("<svg")) return null;
  return new DOMParser().parseFromString(svgMarkup, "image/svg+xml").documentElement;
}

function inspectOpticKSvg(svg) {
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
}

function inspectOpticKMarkup(svgMarkup) {
  return inspectOpticKSvg(parseSvgMarkup(svgMarkup));
}

function inspectEvennessSvg(svg) {
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
}

function inspectEvennessMarkup(svgMarkup) {
  return inspectEvennessSvg(parseSvgMarkup(svgMarkup));
}

function inspectStaffSvg(svg) {
  if (!svg) {
    return {
      staffMode: "",
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
  const system = svg.querySelector(".staff-system");
  const classList = Array.from(system?.classList || []);
  const staffModeClass = classList.find((name) => name.startsWith("staff-mode-")) || "";

  return {
    staffMode: staffModeClass.replace("staff-mode-", ""),
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

function inspectStaffMarkup(svgMarkup) {
  return inspectStaffSvg(parseSvgMarkup(svgMarkup));
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

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function pitchClassColor(pc) {
  return PC_COLORS[((pc % 12) + 12) % 12];
}

function voiceColor(voiceId) {
  return VOICE_COLORS[voiceId % VOICE_COLORS.length];
}

function shortReasonLabel(reason) {
  if (!reason) return "neutral";
  return String(reason)
    .replaceAll("-", " ")
    .split(/\s+/)
    .slice(0, 2)
    .join(" ");
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

function decodeVoicedStateFromPointer(ptr) {
  if (!ptr || !counterpointStructSizes.voicedState) return null;
  const view = new DataView(memory.buffer, ptr, counterpointStructSizes.voicedState);
  const voiceCount = view.getUint8(2);
  const voices = [];
  for (let index = 0; index < Math.min(voiceCount, counterpointStructSizes.maxVoices || 8); index += 1) {
    const base = 14 + index * 8;
    voices.push({
      id: view.getUint8(base + 0),
      midi: view.getUint8(base + 1),
      octave: view.getInt8(base + 2),
      pitchClass: view.getUint8(base + 3),
      sustained: view.getUint8(base + 4) !== 0,
    });
  }
  return {
    setValue: view.getUint16(0, true),
    voiceCount,
    tonic: view.getUint8(3),
    modeType: view.getUint8(4),
    keyQuality: view.getUint8(5),
    metric: {
      beatInBar: view.getUint8(6),
      beatsPerBar: view.getUint8(7),
      subdivision: view.getUint8(8),
    },
    cadenceState: view.getUint8(10),
    stateIndex: view.getUint8(11),
    nextVoiceId: view.getUint8(12),
    voices,
  };
}

function decodeVoicedHistoryFromPointer(ptr) {
  if (!ptr || !counterpointStructSizes.voicedHistory || !counterpointStructSizes.voicedState) {
    return { len: 0, states: [] };
  }
  const view = new DataView(memory.buffer, ptr, counterpointStructSizes.voicedHistory);
  const len = Math.min(view.getUint8(0), counterpointStructSizes.historyCapacity || 4);
  const states = [];
  for (let index = 0; index < len; index += 1) {
    const statePtr = ptr + 4 + index * counterpointStructSizes.voicedState;
    const state = decodeVoicedStateFromPointer(statePtr);
    if (state) states.push(state);
  }
  return {
    len,
    nextVoiceId: view.getUint8(1),
    states,
  };
}

function buildCandidateVoicedState(arena, notes, context, previousPtr, stepIndex) {
  if (!Array.isArray(notes) || notes.length === 0) return null;
  const outPtr = arena.alloc(counterpointStructSizes.voicedState || 96, 4);
  const notesPtr = writeU8Array(arena, notes);
  const beatInBar = ((stepIndex ?? 0) % 4 + 4) % 4;
  const written = wasm.lmt_build_voiced_state(
    notesPtr,
    notes.length,
    null,
    0,
    context.tonic,
    context.modeType,
    beatInBar,
    4,
    0,
    255,
    previousPtr || null,
    outPtr,
  );
  return written > 0 ? decodeVoicedStateFromPointer(outPtr) : null;
}

function buildCurrentMotionAnalysis(arena, historyBundle, voicedHistory, profile) {
  if (!historyBundle || !voicedHistory || voicedHistory.states.length < 2) return null;
  const stateSize = counterpointStructSizes.voicedState || 96;
  const previousPtr = historyBundle.historyPtr + 4 + (voicedHistory.states.length - 2) * stateSize;
  const currentPtr = historyBundle.historyPtr + 4 + (voicedHistory.states.length - 1) * stateSize;
  const summaryPtr = arena.alloc(96, 4);
  const evaluationPtr = arena.alloc(32, 4);
  if (!wasm.lmt_classify_motion(previousPtr, currentPtr, summaryPtr)) return null;
  const motion = decodeMotionSummaryFromPointer(summaryPtr);
  if (!motion) return null;
  const evaluation = wasm.lmt_evaluate_motion_profile(profile, summaryPtr, evaluationPtr)
    ? decodeMotionEvaluationFromPointer(evaluationPtr)
    : null;
  const currentState = voicedHistory.states[voicedHistory.states.length - 1] || null;
  return {
    motion,
    evaluation,
    noteCount: currentState?.voiceCount || 0,
    cadenceEffect: currentState?.cadenceState || 0,
    reasonNames: deriveMotionReasonNames(motion, evaluation, currentState?.voiceCount || 0),
    warningNames: deriveMotionWarningNames(motion, evaluation),
  };
}

function deriveMotionReasonNames(motion, evaluation, voiceCount) {
  if (!motion) return [];
  const reasons = [];
  if (motion.totalMotion <= Math.max(2, voiceCount * 2)) reasons.push("minimal-motion");
  if (motion.contraryCount > 0) reasons.push("contrary-motion");
  if (motion.commonToneCount > 0) reasons.push("common-tone-retention");
  if ((evaluation?.cadenceScore || 0) > 0 || cadenceStrength(motion.currentCadenceState) > cadenceStrength(motion.previousCadenceState)) {
    reasons.push("cadence-pull");
  }
  if ((evaluation?.spacingPenalty || 0) === 0) reasons.push("preserves-spacing");
  if ((evaluation?.score || 0) >= 0) reasons.push("releases-tension");
  return reasons;
}

function deriveMotionWarningNames(motion, evaluation) {
  if (!motion) return [];
  const warnings = [];
  if (motion.parallelCount > 0) warnings.push("parallels");
  if (motion.crossingCount > 0) warnings.push("crossing");
  if (motion.overlapCount > 0) warnings.push("overlap");
  if ((evaluation?.spacingPenalty || 0) > 0) warnings.push("wide-spacing");
  if ((evaluation?.leapPenalty || 0) > 0 || motion.leapCount >= 2) warnings.push("consecutive-leap");
  return warnings;
}

function isPerfectOuterInterval(interval) {
  const normalized = Math.abs(interval) % 12;
  return normalized === 0 || normalized === 7;
}

function hiddenPerfectRisk(motion) {
  if (!motion) return 0;
  return motion.outerMotion === 2 && isPerfectOuterInterval(motion.outerIntervalAfter) ? 1 : 0;
}

function cadenceStrength(cadenceState) {
  switch (cadenceState) {
    case 7:
      return 0.65;
    case 6:
      return 0.72;
    case 5:
      return 1;
    case 4:
      return 0.92;
    case 3:
      return 0.78;
    case 2:
      return 0.44;
    case 1:
      return 0.18;
    default:
      return 0;
  }
}

function shortWarningLabel(warning) {
  if (!warning) return "clean";
  return String(warning)
    .replaceAll("-", " ")
    .split(/\s+/)
    .slice(0, 2)
    .join(" ");
}

function buildRiskAxes(target) {
  const motion = target?.motion || null;
  const evaluation = target?.evaluation || null;
  const noteCount = Math.max(1, target?.noteCount || 1);
  const warningNames = target?.warningNames || [];
  const hasWarning = (name) => warningNames.includes(name);
  const cadenceValue = target?.cadenceEffect ?? motion?.currentCadenceState ?? 0;
  const outerSpan = Math.abs(motion?.outerIntervalAfter || 0);
  const rangeStrain = clamp(Math.max(0, outerSpan - 12) / 18, 0, 1);
  const hiddenPerfectPressure = clamp(
    hiddenPerfectRisk(motion)
      + ((motion?.outerMotion || 0) === 2 ? 0.18 : 0)
      + ((motion?.outerMotion || 0) > 0 ? 0.04 : 0),
    0,
    1,
  );
  const axes = [
    {
      key: "parallels",
      label: "Parallels",
      tone: "warning",
      value: clamp((motion?.parallelCount || 0) * 0.65 + (hasWarning("parallels") ? 0.35 : 0), 0, 1),
    },
    {
      key: "hidden-perfects",
      label: "Hidden perfects",
      tone: "warning",
      value: hiddenPerfectPressure,
    },
    {
      key: "crossing",
      label: "Crossing",
      tone: "warning",
      value: clamp((motion?.crossingCount || 0) * 0.7 + (hasWarning("crossing") ? 0.3 : 0), 0, 1),
    },
    {
      key: "overlap",
      label: "Overlap",
      tone: "warning",
      value: clamp((motion?.overlapCount || 0) * 0.7 + (hasWarning("overlap") ? 0.3 : 0), 0, 1),
    },
    {
      key: "spacing",
      label: "Spacing",
      tone: "warning",
      value: clamp(((evaluation?.spacingPenalty || 0) / 12) + rangeStrain * 0.7 + (hasWarning("wide-spacing") ? 0.35 : 0), 0, 1),
    },
    {
      key: "leap-strain",
      label: "Leap strain",
      tone: "warning",
      value: clamp(((motion?.leapCount || 0) / noteCount) + ((evaluation?.leapPenalty || 0) / 12) + (hasWarning("consecutive-leap") ? 0.25 : 0), 0, 1),
    },
    {
      key: "retention",
      label: "Retention",
      tone: "positive",
      value: clamp(((motion?.commonToneCount || 0) + ((target?.reasonNames || []).includes("common-tone-retention") ? 1 : 0)) / noteCount, 0, 1),
    },
    {
      key: "cadence-pull",
      label: "Cadence pull",
      tone: "positive",
      value: clamp(cadenceStrength(cadenceValue) + Math.max(0, evaluation?.cadenceScore || 0) / 12, 0, 1),
    },
  ];
  return axes;
}

function renderCounterpointWeatherMap(host, currentState, suggestions, focusedIndex, context) {
  if (!host) {
    return { currentAnchorCount: 0, cellCount: 0, warningCellCount: 0, positivePressureCount: 0, negativePressureCount: 0, hoveredCandidateIndex: -1 };
  }
  if (!currentState || currentState.voices.length === 0 || suggestions.length === 0) {
    host.innerHTML = `<div class="output-block">Play or recall a voiced state to see the local pressure field around the strongest next moves.</div>`;
    return { currentAnchorCount: 0, cellCount: 0, warningCellCount: 0, positivePressureCount: 0, negativePressureCount: 0, hoveredCandidateIndex: -1 };
  }

  const cells = suggestions.slice(0, 6);
  const width = 720;
  const height = 360;
  const centerX = 220;
  const centerY = 194;
  const maxAbsTension = Math.max(1, ...cells.map((suggestion) => Math.abs(suggestion.tensionDelta)));
  const maxScore = Math.max(...cells.map((suggestion) => suggestion.score));
  const minScore = Math.min(...cells.map((suggestion) => suggestion.score));
  const maxMotion = Math.max(1, ...cells.map((suggestion) => (suggestion.motion?.totalMotion || 0) + (suggestion.evaluation?.leapPenalty || 0)));
  const chosenIndex = clamp(focusedIndex ?? 0, 0, Math.max(0, cells.length - 1));
  const field = cells.map((suggestion, index) => {
    const normalizedScore = maxScore === minScore ? 1 : (suggestion.score - minScore) / Math.max(1, maxScore - minScore);
    const motionPressure = ((suggestion.motion?.totalMotion || 0) + (suggestion.evaluation?.leapPenalty || 0) + (suggestion.evaluation?.spacingPenalty || 0)) / maxMotion;
    const cadencePull = cadenceStrength(suggestion.cadenceEffect) + Math.max(0, suggestion.evaluation?.cadenceScore || 0) / 12;
    const retention = (suggestion.motion?.commonToneCount || 0) / Math.max(1, suggestion.noteCount || 1);
    const tensionVector = suggestion.tensionDelta / maxAbsTension;
    const stability = clamp((normalizedScore * 0.55) + (retention * 0.25) + (cadencePull * 0.2) - motionPressure * 0.22 - suggestion.warningNames.length * 0.08, -1, 1);
    return {
      ...suggestion,
      index,
      normalizedScore,
      motionPressure,
      cadencePull,
      retention,
      tensionVector,
      stability,
      x: centerX + tensionVector * 170,
      y: centerY + (motionPressure - 0.45) * 118 - cadencePull * 34,
      radius: 18 + normalizedScore * 10,
      isFocused: index === chosenIndex,
    };
  });

  const weatherSvg = `
    <svg class="counterpoint-figure weather-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Counterpoint weather map">
      <defs>
        <radialGradient id="weather-glow" cx="42%" cy="48%" r="68%">
          <stop offset="0%" stop-color="rgba(31,125,134,0.16)" />
          <stop offset="100%" stop-color="rgba(255,255,255,0)" />
        </radialGradient>
        <linearGradient id="weather-band" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stop-color="rgba(42,132,84,0.08)" />
          <stop offset="50%" stop-color="rgba(255,255,255,0)" />
          <stop offset="100%" stop-color="rgba(176,54,32,0.10)" />
        </linearGradient>
      </defs>
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <rect x="40" y="${centerY - 88}" width="360" height="176" rx="88" fill="url(#weather-band)" />
      <circle cx="${centerX}" cy="${centerY}" r="148" fill="url(#weather-glow)" />
      <line x1="52" y1="${centerY}" x2="392" y2="${centerY}" class="weather-axis" />
      <line x1="${centerX}" y1="52" x2="${centerX}" y2="${height - 44}" class="weather-axis" />
      <circle cx="${centerX}" cy="${centerY}" r="46" class="weather-guide-ring" />
      <circle cx="${centerX}" cy="${centerY}" r="90" class="weather-guide-ring is-mid" />
      <text x="42" y="50" class="counterpoint-label eyebrow">Counterpoint Weather Map</text>
      <text x="${centerX}" y="${height - 16}" text-anchor="middle" class="weather-axis-label">release tension ← local motion field → build tension</text>
      <text x="82" y="${centerY - 98}" class="weather-axis-label">cadential pull</text>
      <text x="92" y="${centerY + 126}" class="weather-axis-label">mobile / strained</text>
      <circle class="weather-current-anchor" cx="${centerX}" cy="${centerY}" r="30" />
      <text x="${centerX}" y="${centerY - 2}" text-anchor="middle" class="counterpoint-node-title">${escapeHtml(friendlyChordName(rawChordName(currentState.setValue)) || "Current")}</text>
      <text x="${centerX}" y="${centerY + 18}" text-anchor="middle" class="counterpoint-node-notes">${escapeHtml(currentState.voices.map((voice) => midiName(voice.midi, context.tonic, context.quality)).join(" · "))}</text>
      ${field.map((cell) => {
        const toneClass = cell.stability >= 0 ? "weather-positive-cell" : "weather-negative-cell";
        const warningClass = cell.warningNames.length > 0 ? "weather-warning-cell" : "";
        const focusedClass = cell.isFocused ? "weather-focused-cell" : "";
        const scoreLabel = cell.stability >= 0 ? "attract" : "unstable";
        return `
          <line x1="${centerX}" y1="${centerY}" x2="${cell.x.toFixed(1)}" y2="${cell.y.toFixed(1)}" class="weather-trace ${cell.isFocused ? "is-focused" : ""}" />
          <circle class="weather-cell ${toneClass} ${warningClass} ${focusedClass}" cx="${cell.x.toFixed(1)}" cy="${cell.y.toFixed(1)}" r="${cell.radius.toFixed(1)}" />
          ${cell.cadencePull > 0.72 ? `<circle class="weather-cadence-ring" cx="${cell.x.toFixed(1)}" cy="${cell.y.toFixed(1)}" r="${(cell.radius + 8).toFixed(1)}" />` : ""}
          <text x="${cell.x.toFixed(1)}" y="${(cell.y - 4).toFixed(1)}" text-anchor="middle" class="weather-cell-label">${escapeHtml(String.fromCharCode(65 + cell.index))}</text>
          <text x="${cell.x.toFixed(1)}" y="${(cell.y + 14).toFixed(1)}" text-anchor="middle" class="weather-cell-meta">${escapeHtml(scoreLabel)}</text>
        `;
      }).join("")}
      <g transform="translate(430 58)">
        <text x="0" y="0" class="counterpoint-node-title">Focused candidate</text>
        <text x="0" y="22" class="counterpoint-node-notes">${escapeHtml(String.fromCharCode(65 + chosenIndex))}. ${escapeHtml(field[chosenIndex]?.noteNames?.join(" · ") || "")}</text>
        <text x="0" y="44" class="counterpoint-node-meta">score ${escapeHtml(String(field[chosenIndex]?.score ?? 0))} · cadence ${escapeHtml(field[chosenIndex]?.cadenceLabel || "none")}</text>
        <text x="0" y="66" class="counterpoint-node-meta">${escapeHtml(shortReasonLabel(field[chosenIndex]?.reasonNames?.[0] || ""))} · ${escapeHtml(shortWarningLabel(field[chosenIndex]?.warningNames?.[0] || "clean"))}</text>
      </g>
    </svg>`;

  host.innerHTML = weatherSvg;
  return {
    currentAnchorCount: 1,
    cellCount: field.length,
    warningCellCount: field.filter((cell) => cell.warningNames.length > 0).length,
    positivePressureCount: field.filter((cell) => cell.stability >= 0).length,
    negativePressureCount: field.filter((cell) => cell.stability < 0).length,
    hoveredCandidateIndex: chosenIndex,
  };
}

function renderParallelRiskRadar(host, currentAnalysis, suggestions, focusedIndex) {
  if (!host) {
    return { axisCount: 0, populatedAxisCount: 0, currentPolygonCount: 0, candidatePolygonCount: 0, warningAxisCount: 0, hoveredCandidateIndex: -1 };
  }
  if (!currentAnalysis || !currentAnalysis.motion || suggestions.length === 0) {
    host.innerHTML = `<div class="output-block">Risk axes appear once there is enough voice motion to compare the current slice against likely next moves.</div>`;
    return { axisCount: 0, populatedAxisCount: 0, currentPolygonCount: 0, candidatePolygonCount: 0, warningAxisCount: 0, hoveredCandidateIndex: -1 };
  }

  const chosenIndex = clamp(focusedIndex ?? 0, 0, Math.max(0, suggestions.length - 1));
  const candidate = suggestions[chosenIndex] || null;
  const currentAxes = buildRiskAxes(currentAnalysis);
  const candidateAxes = buildRiskAxes(candidate);
  const axisCount = Math.max(currentAxes.length, candidateAxes.length);
  const width = 720;
  const height = 360;
  const centerX = 250;
  const centerY = 188;
  const outerRadius = 120;
  const ringFractions = [0.25, 0.5, 0.75, 1];
  const axes = currentAxes.map((axis, index) => ({
    ...axis,
    candidateValue: candidateAxes[index]?.value || 0,
    angle: (-Math.PI / 2) + (index * Math.PI * 2) / axisCount,
  }));

  const pointForAxis = (axis, value) => ({
    x: centerX + Math.cos(axis.angle) * outerRadius * value,
    y: centerY + Math.sin(axis.angle) * outerRadius * value,
  });
  const currentPoints = axes.map((axis) => pointForAxis(axis, axis.value));
  const candidatePoints = axes.map((axis) => pointForAxis(axis, axis.candidateValue));
  const currentPolygon = currentPoints.map((point) => `${point.x.toFixed(1)},${point.y.toFixed(1)}`).join(" ");
  const candidatePolygon = candidatePoints.map((point) => `${point.x.toFixed(1)},${point.y.toFixed(1)}`).join(" ");
  const populatedAxisCount = axes.filter((axis) => axis.value > 0.02 || axis.candidateValue > 0.02).length;
  const warningAxisCount = axes.filter((axis) => axis.tone === "warning" && Math.max(axis.value, axis.candidateValue) >= 0.62).length;

  const radarSvg = `
    <svg class="counterpoint-figure risk-radar-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Parallel-risk radar">
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <text x="42" y="50" class="counterpoint-label eyebrow">Parallel-Risk Radar</text>
      ${ringFractions.map((fraction, index) => `<circle cx="${centerX}" cy="${centerY}" r="${(outerRadius * fraction).toFixed(1)}" class="risk-ring ${index === ringFractions.length - 1 ? "is-outer" : ""}" />`).join("")}
      ${axes.map((axis) => {
        const outerPoint = pointForAxis(axis, 1);
        const labelPoint = pointForAxis(axis, 1.18);
        const maxValue = Math.max(axis.value, axis.candidateValue);
        const axisClasses = ["risk-axis"];
        if (maxValue > 0.02) axisClasses.push("is-populated");
        if (axis.tone === "warning" && maxValue >= 0.62) axisClasses.push("is-warning");
        return `
          <line x1="${centerX}" y1="${centerY}" x2="${outerPoint.x.toFixed(1)}" y2="${outerPoint.y.toFixed(1)}" class="${axisClasses.join(" ")}" />
          <text x="${labelPoint.x.toFixed(1)}" y="${(labelPoint.y + 4).toFixed(1)}" text-anchor="middle" class="risk-axis-label">${escapeHtml(axis.label)}</text>
        `;
      }).join("")}
      <polygon class="risk-current-polygon" points="${currentPolygon}" />
      <polygon class="risk-candidate-polygon" points="${candidatePolygon}" />
      ${currentPoints.map((point) => `<circle class="risk-point risk-current-point" cx="${point.x.toFixed(1)}" cy="${point.y.toFixed(1)}" r="4.5" />`).join("")}
      ${candidatePoints.map((point) => `<circle class="risk-point risk-candidate-point" cx="${point.x.toFixed(1)}" cy="${point.y.toFixed(1)}" r="4.5" />`).join("")}
      <g transform="translate(468 74)">
        <text x="0" y="0" class="counterpoint-node-title">Current vs candidate</text>
        <rect x="0" y="18" width="16" height="16" rx="8" class="risk-legend risk-legend-current" />
        <text x="26" y="31" class="counterpoint-node-notes">current slice</text>
        <rect x="0" y="46" width="16" height="16" rx="8" class="risk-legend risk-legend-candidate" />
        <text x="26" y="59" class="counterpoint-node-notes">${escapeHtml(String.fromCharCode(65 + chosenIndex))}. ${escapeHtml(candidate?.chordLabel || "candidate")}</text>
        <text x="0" y="90" class="counterpoint-node-meta">${escapeHtml(shortWarningLabel(candidate?.warningNames?.[0] || "clean"))} · ${escapeHtml(shortReasonLabel(candidate?.reasonNames?.[0] || ""))}</text>
        <text x="0" y="112" class="counterpoint-node-meta">cadence ${escapeHtml(candidate?.cadenceLabel || "none")} · tension ${escapeHtml(candidate?.tensionDelta >= 0 ? `+${candidate.tensionDelta}` : String(candidate?.tensionDelta || 0))}</text>
      </g>
    </svg>`;

  host.innerHTML = radarSvg;
  return {
    axisCount,
    populatedAxisCount,
    currentPolygonCount: 1,
    candidatePolygonCount: candidate ? 1 : 0,
    warningAxisCount,
    hoveredCandidateIndex: chosenIndex,
  };
}

function humanizeCounterpointLabel(label) {
  return String(label || "")
    .replaceAll("-", " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function renderCadenceFunnel(host, currentState, destinations, suggestions, context) {
  if (!host) {
    return { anchorCount: 0, branchCount: 0, activeBranchCount: 0, warningBranchCount: 0 };
  }
  if (!currentState || currentState.voices.length === 0 || !Array.isArray(destinations) || destinations.length === 0) {
    host.innerHTML = `<div class="output-block">Cadential direction appears once a voiced state has enough temporal memory to imply near-term arrivals.</div>`;
    return { anchorCount: 0, branchCount: 0, activeBranchCount: 0, warningBranchCount: 0 };
  }

  const visible = destinations.slice(0, 5);
  const width = 720;
  const height = 360;
  const anchorX = 176;
  const anchorY = 182;
  const branchX = 508;
  const branchYs = visible.length <= 1
    ? [anchorY]
    : visible.map((_unused, index) => 70 + ((height - 140) * index) / (visible.length - 1));
  const maxScore = Math.max(...visible.map((destination) => destination.score), 1);
  const anchorLabel = currentState.voices.map((voice) => midiName(voice.midi, context.tonic, context.quality)).join(" · ");

  const svg = `
    <svg class="counterpoint-figure cadence-funnel-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Cadence funnel">
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <path d="M ${anchorX + 24} ${anchorY - 132} C ${anchorX + 112} ${anchorY - 120}, ${branchX - 62} 72, ${branchX - 12} 72" class="cadence-funnel-axis" />
      <path d="M ${anchorX + 24} ${anchorY + 132} C ${anchorX + 112} ${anchorY + 120}, ${branchX - 62} ${height - 72}, ${branchX - 12} ${height - 72}" class="cadence-funnel-axis" />
      <text x="42" y="52" class="counterpoint-label eyebrow">Cadence Funnel</text>
      <circle cx="${anchorX}" cy="${anchorY}" r="34" class="cadence-funnel-anchor" />
      <text x="${anchorX}" y="${anchorY - 2}" text-anchor="middle" class="counterpoint-node-title">${escapeHtml(friendlyChordName(rawChordName(currentState.setValue)) || "Current")}</text>
      <text x="${anchorX}" y="${anchorY + 18}" text-anchor="middle" class="counterpoint-node-notes">${escapeHtml(anchorLabel)}</text>
      ${visible.map((destination, index) => {
        const y = branchYs[index];
        const branchWidth = 90 + Math.max(0, destination.score / Math.max(1, maxScore)) * 96;
        const x = branchX - branchWidth / 2;
        const matchingSuggestion = suggestions.find((suggestion) => cadenceDestinationFromCadenceEffect(suggestion.cadenceEffect) === destination.destination)
          || suggestions[index]
          || null;
        const warningClass = destination.warningCount > 0 ? " is-warning" : "";
        const activeClass = destination.currentMatch ? " is-active" : "";
        return `
          <path d="M ${anchorX + 34} ${anchorY} C ${anchorX + 126} ${anchorY}, ${x - 24} ${y}, ${x} ${y}" class="cadence-funnel-link${activeClass}${warningClass}" />
          <rect x="${x.toFixed(1)}" y="${(y - 24).toFixed(1)}" width="${branchWidth.toFixed(1)}" height="48" rx="24" class="cadence-funnel-branch${activeClass}${warningClass}" />
          <text x="${branchX}" y="${(y - 5).toFixed(1)}" text-anchor="middle" class="cadence-funnel-label">${escapeHtml(humanizeCounterpointLabel(destination.label))}</text>
          <text x="${branchX}" y="${(y + 13).toFixed(1)}" text-anchor="middle" class="counterpoint-node-meta">score ${escapeHtml(String(destination.score))} · ${escapeHtml(destination.candidateCount)} paths · ${escapeHtml(destination.tensionBias >= 0 ? `+${destination.tensionBias}` : String(destination.tensionBias))}</text>
          ${matchingSuggestion ? `<text x="${branchX}" y="${(y + 31).toFixed(1)}" text-anchor="middle" class="counterpoint-node-meta">${escapeHtml(shortReasonLabel(matchingSuggestion.reasonNames[0] || ""))}</text>` : ""}
        `;
      }).join("")}
    </svg>`;

  host.innerHTML = svg;
  return {
    anchorCount: 1,
    branchCount: visible.length,
    activeBranchCount: visible.filter((destination) => destination.currentMatch).length,
    warningBranchCount: visible.filter((destination) => destination.warningCount > 0).length,
  };
}

function renderSuspensionMachine(host, summary) {
  if (!host) {
    return { stateLabel: "", obligationCount: 0, warningCount: 0, trackedVoiceCount: 0 };
  }
  if (!summary) {
    host.innerHTML = `<div class="output-block">Suspension state appears once at least two voiced frames let us tell preparation from held dissonance and resolution.</div>`;
    return { stateLabel: "", obligationCount: 0, warningCount: 0, trackedVoiceCount: 0 };
  }

  const states = counterpointSuspensionStateNames.slice();
  const width = 720;
  const height = 260;
  const startX = 90;
  const endX = width - 90;
  const step = states.length <= 1 ? 0 : (endX - startX) / (states.length - 1);
  const activeIndex = clamp(summary.state ?? 0, 0, Math.max(0, states.length - 1));
  const trackedVoice = summary.trackedVoiceId != null && summary.trackedVoiceId < 255;
  const trackedLabel = trackedVoice ? `voice ${summary.trackedVoiceId}` : "no tracked voice";
  const obligationText = summary.obligationCount > 0 && summary.expectedResolutionLabel
    ? `resolve ${summary.heldNoteLabel || "held tone"} ${summary.resolutionDirection < 0 ? "down" : summary.resolutionDirection > 0 ? "up" : "by step"} to ${summary.expectedResolutionLabel}`
    : "no active resolution obligation";

  const svg = `
    <svg class="counterpoint-figure suspension-machine-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Suspension machine">
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <text x="42" y="52" class="counterpoint-label eyebrow">Suspension Machine</text>
      <line x1="${startX}" y1="126" x2="${endX}" y2="126" class="suspension-track" />
      ${states.map((stateLabel, index) => {
        const x = startX + step * index;
        const classes = ["suspension-node"];
        if (index === activeIndex) classes.push("is-active");
        if (summary.warningCount > 0 && (index === activeIndex || stateLabel === "unresolved")) classes.push("is-warning");
        return `
          ${index < states.length - 1 ? `<line x1="${x}" y1="126" x2="${(x + step).toFixed(1)}" y2="126" class="suspension-link" />` : ""}
          <circle cx="${x.toFixed(1)}" cy="126" r="18" class="${classes.join(" ")}" />
          <text x="${x.toFixed(1)}" y="96" text-anchor="middle" class="suspension-label">${escapeHtml(humanizeCounterpointLabel(stateLabel))}</text>
        `;
      }).join("")}
      <g transform="translate(74 172)">
        <text x="0" y="0" class="counterpoint-node-title">${escapeHtml(humanizeCounterpointLabel(summary.stateLabel || "none"))}</text>
        <text x="0" y="22" class="counterpoint-node-notes">${escapeHtml(trackedLabel)} · retained ${escapeHtml(String(summary.retainedCount || 0))} · candidates ${escapeHtml(String(summary.candidateResolutionCount || 0))}</text>
        <text x="0" y="44" class="suspension-obligation">${escapeHtml(obligationText)}</text>
        <text x="0" y="66" class="counterpoint-node-meta">tension ${escapeHtml(String(summary.previousTension || 0))} → ${escapeHtml(String(summary.currentTension || 0))}</text>
        ${summary.warningCount > 0 ? `<text x="0" y="88" class="suspension-warning">${escapeHtml(`${summary.warningCount} warning${summary.warningCount === 1 ? "" : "s"}`)}</text>` : ""}
      </g>
    </svg>`;

  host.innerHTML = svg;
  return {
    stateLabel: summary.stateLabel || "",
    obligationCount: summary.obligationCount || 0,
    warningCount: summary.warningCount || 0,
    trackedVoiceCount: trackedVoice ? 1 : 0,
  };
}

function starPolygonPoints(cx, cy, outerRadius, innerRadius, pointCount = 5) {
  const points = [];
  for (let index = 0; index < pointCount * 2; index += 1) {
    const radius = index % 2 === 0 ? outerRadius : innerRadius;
    const angle = -Math.PI / 2 + (index * Math.PI) / pointCount;
    points.push(`${(cx + Math.cos(angle) * radius).toFixed(1)},${(cy + Math.sin(angle) * radius).toFixed(1)}`);
  }
  return points.join(" ");
}

function renderOrbifoldRibbon(host, currentState, suggestions, focusedIndex, context) {
  if (!host) {
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: 0 };
  }
  if (!currentState || !Array.isArray(suggestions) || suggestions.length === 0 || orbifoldTriadNodes.length === 0) {
    host.innerHTML = `<div class="output-block">Orbifold ribbon appears once the live sonority and at least one next-step candidate map to triadic harmonic anchors.</div>`;
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: 0 };
  }

  const currentNode = orbifoldTriadNodeForIndex(orbifoldTriadNodeIndexForSet(currentState.setValue));
  const supportedCandidates = suggestions
    .map((suggestion, index) => {
      const nodeIndex = orbifoldTriadNodeIndexForSet(suggestion.setValue);
      const node = orbifoldTriadNodeForIndex(nodeIndex);
      return node ? { ...suggestion, index, node, nodeIndex } : null;
    })
    .filter(Boolean)
    .slice(0, 4);

  if (!currentNode || supportedCandidates.length === 0) {
    host.innerHTML = `<div class="output-block">This phrase is currently outside the triadic orbifold slice. Try a clearer triad or hover a simpler continuation.</div>`;
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: orbifoldTriadEdges.length };
  }

  const chosen = supportedCandidates.find((candidate) => candidate.index === focusedIndex) || supportedCandidates[0];
  const width = 760;
  const height = 360;
  const mapX = (x) => 34 + x * 0.56;
  const mapY = (y) => 26 + y * 0.56;
  const currentX = mapX(currentNode.x);
  const currentY = mapY(currentNode.y);

  const svg = `
    <svg class="counterpoint-figure orbifold-ribbon-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Orbifold ribbon">
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <ellipse cx="${mapX(270).toFixed(1)}" cy="${mapY(270).toFixed(1)}" rx="${(156.25 * 0.56).toFixed(1)}" ry="${(247.5 * 0.56).toFixed(1)}" class="orbifold-ribbon-shell" />
      ${orbifoldTriadEdges.map((edge) => {
        const from = orbifoldTriadNodeForIndex(edge.fromIndex);
        const to = orbifoldTriadNodeForIndex(edge.toIndex);
        if (!from || !to) return "";
        return `<line class="orbifold-ribbon-edge" x1="${mapX(from.x).toFixed(1)}" y1="${mapY(from.y).toFixed(1)}" x2="${mapX(to.x).toFixed(1)}" y2="${mapY(to.y).toFixed(1)}" />`;
      }).join("")}
      ${orbifoldTriadNodes.map((node) => `
        <circle class="orbifold-ribbon-node" cx="${mapX(node.x).toFixed(1)}" cy="${mapY(node.y).toFixed(1)}" r="5.5" fill="${orbifoldTriadQualityFill(node.quality)}" stroke="${orbifoldTriadQualityStroke(node.quality)}" />
      `).join("")}
      <text x="36" y="46" class="counterpoint-label eyebrow">Orbifold Ribbon</text>
      ${supportedCandidates.map((candidate) => {
        const x = mapX(candidate.node.x);
        const y = mapY(candidate.node.y);
        const focusedClass = candidate.index === chosen.index ? " is-focused" : "";
        return `
          <path class="orbifold-ribbon-ribbon${focusedClass}" d="M ${currentX.toFixed(1)} ${currentY.toFixed(1)} C ${(currentX + 54).toFixed(1)} ${(currentY - 8).toFixed(1)}, ${(x - 54).toFixed(1)} ${(y + 8).toFixed(1)}, ${x.toFixed(1)} ${y.toFixed(1)}" />
          <circle class="orbifold-ribbon-candidate-anchor${focusedClass}" cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="11.5" />
          ${candidate.index === chosen.index ? `<circle class="orbifold-ribbon-highlight-ring" cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="18" />` : ""}
        `;
      }).join("")}
      <circle class="orbifold-ribbon-current-anchor" cx="${currentX.toFixed(1)}" cy="${currentY.toFixed(1)}" r="14" />
      ${[currentNode, ...supportedCandidates.map((candidate) => candidate.node)].map((node) => `
        <text x="${mapX(node.x).toFixed(1)}" y="${(mapY(node.y) + 2).toFixed(1)}" text-anchor="middle" class="orbifold-ribbon-node-label">${escapeHtml(orbifoldTriadLabel(node))}</text>
      `).join("")}
      <g transform="translate(420 78)">
        <text x="0" y="0" class="counterpoint-node-title">${escapeHtml(orbifoldTriadLabel(currentNode))}</text>
        <text x="0" y="22" class="counterpoint-node-notes">${escapeHtml(currentState.voices.map((voice) => midiName(voice.midi, context.tonic, context.quality)).join(" · "))}</text>
        <text x="0" y="44" class="counterpoint-node-meta">current triadic anchor · ${escapeHtml(orbifoldTriadQualityName(currentNode.quality))}</text>
        ${supportedCandidates.map((candidate, index) => `
          <g transform="translate(0 ${76 + index * 54})">
            <circle cx="10" cy="-8" r="8" fill="${orbifoldTriadQualityFill(candidate.node.quality)}" stroke="${orbifoldTriadQualityStroke(candidate.node.quality)}" />
            <text x="28" y="-4" class="counterpoint-node-title">${escapeHtml(String.fromCharCode(65 + candidate.index))}. ${escapeHtml(orbifoldTriadLabel(candidate.node))}</text>
            <text x="28" y="14" class="counterpoint-node-meta">score ${escapeHtml(String(candidate.score))} · ${escapeHtml(shortReasonLabel(candidate.reasonNames[0] || ""))} · common tones ${escapeHtml(String(candidate.motion?.commonToneCount || 0))}</text>
          </g>
        `).join("")}
      </g>
    </svg>`;

  host.innerHTML = svg;
  return {
    currentAnchorCount: 1,
    candidateAnchorCount: supportedCandidates.length,
    highlightedCandidateCount: 1,
    supportedCandidateCount: supportedCandidates.length,
    edgeCount: orbifoldTriadEdges.length,
  };
}

function renderCommonToneConstellation(host, currentState, candidateStates, suggestions, focusedIndex, historyStates, context) {
  if (!host) {
    return { retainedStarCount: 0, movingVectorCount: 0, historyAnchorCount: 0, focusedCandidateIndex: -1 };
  }
  if (!currentState || !Array.isArray(candidateStates) || !Array.isArray(suggestions) || suggestions.length === 0) {
    host.innerHTML = `<div class="output-block">Common-tone constellations appear once there is a current voiced state and at least one candidate continuation.</div>`;
    return { retainedStarCount: 0, movingVectorCount: 0, historyAnchorCount: 0, focusedCandidateIndex: -1 };
  }

  const chosenIndex = clamp(focusedIndex ?? 0, 0, Math.max(0, suggestions.length - 1));
  const candidate = suggestions[chosenIndex] || suggestions[0] || null;
  const chosenState = candidateStates[chosenIndex] || candidateStates[0] || null;
  const currentMidis = currentState.voices.map((voice) => voice.midi).sort((a, b) => a - b);
  const targetMidis = (chosenState?.voices?.map((voice) => voice.midi) || candidate?.notes || []).slice().sort((a, b) => a - b);
  const motionCount = Math.min(currentMidis.length, targetMidis.length);
  const motions = Array.from({ length: motionCount }, (_unused, index) => {
    const fromMidi = currentMidis[index];
    const toMidi = targetMidis[index];
    const delta = toMidi - fromMidi;
    return {
      voiceId: index,
      fromMidi,
      toMidi,
      delta,
      absDelta: Math.abs(delta),
    };
  });
  if (!candidate || motionCount === 0) {
    host.innerHTML = `<div class="output-block">Common-tone constellations need voice-motion assignments from the ranked next-step engine.</div>`;
    return { retainedStarCount: 0, movingVectorCount: 0, historyAnchorCount: 0, focusedCandidateIndex: -1 };
  }

  const previousState = Array.isArray(historyStates) && historyStates.length >= 2 ? historyStates[historyStates.length - 2] : null;
  const retained = motions.filter((motion) => motion.fromMidi === motion.toMidi);
  const moving = motions.filter((motion) => motion.fromMidi !== motion.toMidi);
  const stepCount = moving.filter((motion) => motion.absDelta <= 2).length;
  const leapCount = moving.filter((motion) => motion.absDelta > 2).length;
  const allMidis = [
    ...currentState.voices.map((voice) => voice.midi),
    ...motions.flatMap((motion) => [motion.fromMidi, motion.toMidi]),
    ...(previousState ? previousState.voices.map((voice) => voice.midi) : []),
  ];
  const minMidi = Math.min(...allMidis) - 2;
  const maxMidi = Math.max(...allMidis) + 2;
  const width = 720;
  const height = 320;
  const previousX = 120;
  const currentX = 320;
  const candidateX = 548;
  const top = 48;
  const bottom = 38;
  const usableHeight = height - top - bottom;
  const yForMidi = (midi) => top + (maxMidi - midi) * (usableHeight / Math.max(1, maxMidi - minMidi));

  const svg = `
    <svg class="counterpoint-figure common-tone-constellation-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Common-tone constellation">
      <defs>
        <marker id="constellation-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
          <path d="M 0 0 L 10 5 L 0 10 z" fill="rgba(31,125,134,0.86)" />
        </marker>
      </defs>
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <text x="36" y="46" class="counterpoint-label eyebrow">Common-Tone Constellation</text>
      <line x1="${previousX}" y1="${top - 10}" x2="${previousX}" y2="${height - bottom}" class="common-tone-constellation-axis" />
      <line x1="${currentX}" y1="${top - 10}" x2="${currentX}" y2="${height - bottom}" class="common-tone-constellation-axis" />
      <line x1="${candidateX}" y1="${top - 10}" x2="${candidateX}" y2="${height - bottom}" class="common-tone-constellation-axis" />
      <text x="${previousX}" y="${height - 10}" text-anchor="middle" class="counterpoint-node-meta">memory</text>
      <text x="${currentX}" y="${height - 10}" text-anchor="middle" class="counterpoint-node-meta">current</text>
      <text x="${candidateX}" y="${height - 10}" text-anchor="middle" class="counterpoint-node-meta">${escapeHtml(String.fromCharCode(65 + chosenIndex))}</text>
      ${previousState ? previousState.voices.map((voice) => `
        <circle class="common-tone-constellation-history-anchor" cx="${previousX}" cy="${yForMidi(voice.midi).toFixed(1)}" r="5.5" fill="${pitchClassColor(voice.pitchClass)}" />
      `).join("") : ""}
      ${motions.map((motion) => {
        const currentY = yForMidi(motion.fromMidi);
        const targetY = yForMidi(motion.toMidi);
        const color = pitchClassColor(motion.toMidi % 12);
        if (motion.fromMidi === motion.toMidi) {
          const points = starPolygonPoints(currentX, currentY, 10, 4.8);
          const targetPoints = starPolygonPoints(candidateX, targetY, 10, 4.8);
          return `
            <line x1="${currentX}" y1="${currentY.toFixed(1)}" x2="${candidateX}" y2="${targetY.toFixed(1)}" class="common-tone-constellation-retained-link" />
            <polygon class="common-tone-constellation-retained-star" points="${points}" fill="${color}" />
            <polygon class="common-tone-constellation-retained-star" points="${targetPoints}" fill="${color}" />
          `;
        }
        return `
          <line x1="${currentX}" y1="${currentY.toFixed(1)}" x2="${candidateX}" y2="${targetY.toFixed(1)}" class="common-tone-constellation-moving-vector" stroke="${color}" marker-end="url(#constellation-arrow)" />
          <circle class="common-tone-constellation-current-node" cx="${currentX}" cy="${currentY.toFixed(1)}" r="7" fill="${pitchClassColor(motion.fromMidi % 12)}" />
          <circle class="common-tone-constellation-candidate-node" cx="${candidateX}" cy="${targetY.toFixed(1)}" r="7" fill="${color}" />
        `;
      }).join("")}
      <g transform="translate(388 54)">
        <text x="0" y="0" class="counterpoint-node-title">${escapeHtml(candidate.chordLabel)}</text>
        <text x="0" y="22" class="counterpoint-node-notes">${escapeHtml(candidate.noteNames.join(" · "))}</text>
        <text x="0" y="44" class="counterpoint-node-meta">retained ${escapeHtml(String(retained.length))} · steps ${escapeHtml(String(stepCount))} · leaps ${escapeHtml(String(leapCount))}</text>
        <text x="0" y="66" class="counterpoint-node-meta">${escapeHtml(shortReasonLabel(candidate.reasonNames[0] || "common-tone-retention"))} · ${escapeHtml(candidate.cadenceLabel)}</text>
      </g>
    </svg>`;

  host.innerHTML = svg;
  return {
    retainedStarCount: retained.length * 2,
    movingVectorCount: moving.length,
    historyAnchorCount: previousState ? previousState.voices.length : 0,
    focusedCandidateIndex: chosenIndex,
  };
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

function currentSustainedOnlyMidiNotes() {
  const aggregate = new Set();
  for (const channel of midiState.channels.values()) {
    for (const note of channel.sustained) {
      if (!channel.held.has(note)) aggregate.add(note);
    }
  }
  return sortedAscendingNumbers(aggregate);
}

function sameNumberArray(left, right) {
  if (!Array.isArray(left) || !Array.isArray(right) || left.length !== right.length) return false;
  for (let index = 0; index < left.length; index += 1) {
    if (left[index] !== right[index]) return false;
  }
  return true;
}

function cloneHistoryFrame(frame) {
  return {
    notes: frame.notes.slice(),
    sustained: frame.sustained.slice(),
    timestamp: frame.timestamp,
    stepIndex: frame.stepIndex,
  };
}

function sanitizeHistoryFrames(raw) {
  if (!Array.isArray(raw)) return [];
  const frames = [];
  for (const entry of raw) {
    const notes = sortedAscendingNumbers((entry?.notes || []).map((value) => Number(value)).filter((value) => Number.isFinite(value) && value >= 0 && value <= 127));
    const sustained = sortedAscendingNumbers((entry?.sustained || []).map((value) => Number(value)).filter((value) => Number.isFinite(value) && value >= 0 && value <= 127));
    if (notes.length === 0) continue;
    frames.push({
      notes,
      sustained,
      timestamp: Number.isFinite(Number(entry?.timestamp)) ? Number(entry.timestamp) : Date.now(),
      stepIndex: Number.isFinite(Number(entry?.stepIndex)) ? Number(entry.stepIndex) : frames.length,
    });
  }
  return frames.slice(-Math.max(1, counterpointStructSizes.historyCapacity || 4));
}

function captureMidiHistoryFrame(force = false) {
  const notes = currentLiveMidiNotes();
  const sustained = currentSustainedOnlyMidiNotes();
  if (!force && notes.length === 0) return;

  const nextFrame = {
    notes,
    sustained,
    timestamp: Date.now(),
    stepIndex: midiState.historyFrames.length > 0 ? (midiState.historyFrames[midiState.historyFrames.length - 1].stepIndex + 1) : 0,
  };
  const last = midiState.historyFrames[midiState.historyFrames.length - 1];
  if (!force && last && sameNumberArray(last.notes, nextFrame.notes) && sameNumberArray(last.sustained, nextFrame.sustained)) {
    return;
  }
  midiState.historyFrames.push(nextFrame);
  const cap = Math.max(1, counterpointStructSizes.historyCapacity || 4);
  if (midiState.historyFrames.length > cap) {
    midiState.historyFrames = midiState.historyFrames.slice(-cap);
  }
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

function currentDisplayHistoryFrames() {
  if (midiState.activeSnapshotId != null) {
    const snapshot = midiState.snapshots.find((one) => one.id === midiState.activeSnapshotId);
    if (snapshot?.historyFrames?.length > 0) return snapshot.historyFrames.map(cloneHistoryFrame);
    if (snapshot?.midiNotes?.length > 0) {
      return [{ notes: snapshot.midiNotes.slice(), sustained: [], timestamp: snapshot.createdAt || Date.now(), stepIndex: 0 }];
    }
  }
  return midiState.historyFrames.map(cloneHistoryFrame);
}

function effectiveHistoryFrames(displayNotes) {
  const frames = currentDisplayHistoryFrames();
  if (displayNotes.length === 0) return [];
  if (frames.length === 0 || !sameNumberArray(frames[frames.length - 1].notes, displayNotes)) {
    frames.push({
      notes: displayNotes.slice(),
      sustained: midiState.activeSnapshotId == null ? currentSustainedOnlyMidiNotes() : [],
      timestamp: Date.now(),
      stepIndex: frames.length > 0 ? frames[frames.length - 1].stepIndex + 1 : 0,
    });
  }
  const cap = Math.max(1, counterpointStructSizes.historyCapacity || 4);
  return frames.slice(-cap);
}

function bestSetAnchor(setValue) {
  if (!setValue) return { tonic: 0, quality: 0 };
  const candidates = buildKeyCandidates(setValue);
  if (candidates.length > 0) {
    return { tonic: candidates[0].tonic, quality: candidates[0].quality };
  }
  for (let pc = 0; pc < 12; pc += 1) {
    if ((setValue & (1 << pc)) !== 0) return { tonic: pc, quality: 0 };
  }
  return { tonic: 0, quality: 0 };
}

function defaultMiniInstrumentOptions() {
  return {
    maxHeight: 190,
    squareWidth: 220,
    mediumWidth: 240,
    wideWidth: 260,
    ultraWideWidth: 280,
    padXRatio: 0.08,
    padYRatio: 0.12,
  };
}

function mergePreviewOptions(base, extra = {}) {
  return { ...base, ...extra };
}

function renderMiniInstrumentPreview(arena, host, spec, alt, options = {}) {
  if (!host) return false;
  const mode = options.modeOverride || miniInstrumentMode();
  host.dataset.miniInstrument = mode;

  if (mode === MINI_INSTRUMENT_OFF) {
    host.innerHTML = `<div class="output-block">Mini instrument off.</div>`;
    return false;
  }

  const previewOptions = mergePreviewOptions(defaultMiniInstrumentOptions(), options);
  if (mode === MINI_INSTRUMENT_PIANO) {
    const notes = spec.midiNotes?.length > 0
      ? spec.midiNotes.slice()
      : (spec.setValue ? keyboardPreviewNotesForSet(spec.setValue, spec.tonic ?? 0) : []);
    if (notes.length === 0) {
      host.innerHTML = `<div class="output-block">No note material for piano mini view.</div>`;
      return false;
    }
    const range = keyboardRangeForNotes(notes, spec.fallbackLow ?? 36, spec.fallbackHigh ?? 96);
    renderPreviewSvgOrBitmap(host, {
      svgMarkup: svgString(arena, wasm.lmt_svg_keyboard, writeU8Array(arena, notes), notes.length, range.low, range.high),
      bitmapRenderer: {
        renderRgba: (width, height) => keyboardBitmapRgba(arena, notes, range.low, range.high, width, height),
      },
      alt,
      options: previewOptions,
    });
    return true;
  }

  const setValue = spec.setValue || (spec.midiNotes?.length > 0 ? midiListToSet(arena, spec.midiNotes) : 0);
  if (!setValue) {
    host.innerHTML = `<div class="output-block">No fret view for an empty set.</div>`;
    return false;
  }
  const preferredBassPc = spec.preferredBassPc ?? (spec.midiNotes?.length > 0 ? Math.min(...spec.midiNotes) % 12 : null);
  const midiNotes = spec.midiNotes?.length > 0 ? spec.midiNotes.slice() : keyboardPreviewNotesForSet(setValue, spec.tonic ?? 0);
  const voicing = spec.fretVoicing
    || preferredFretVoicing(arena, setValue, { preferredBassPc })
    || genericFretVoicingForNotes(midiNotes, "Generic fret");
  return renderFretVoicingPreview(arena, host, voicing, alt, previewOptions);
}

function buildCounterpointHistory(arena, frames, context) {
  const historyPtr = arena.alloc(counterpointStructSizes.voicedHistory || 1024, 4);
  const statePtr = arena.alloc(counterpointStructSizes.voicedState || 256, 4);
  wasm.lmt_voiced_history_reset(historyPtr);
  const beatsPerBar = 4;
  for (const frame of frames) {
    const notesPtr = writeU8Array(arena, frame.notes);
    const sustainedPtr = writeU8Array(arena, frame.sustained);
    const beatInBar = ((frame.stepIndex ?? 0) % beatsPerBar + beatsPerBar) % beatsPerBar;
    wasm.lmt_voiced_history_push(
      historyPtr,
      notesPtr,
      frame.notes.length,
      sustainedPtr,
      frame.sustained.length,
      context.tonic,
      context.modeType,
      beatInBar,
      beatsPerBar,
      0,
      255,
      statePtr,
    );
  }
  return { historyPtr, statePtr };
}

function decodeRankedNextSteps(arena, historyPtr, profile, context) {
  const cap = 8;
  const rowBytes = counterpointStructSizes.nextStepSuggestion || 160;
  const outPtr = arena.alloc(rowBytes * cap, 4);
  const total = wasm.lmt_rank_next_steps(historyPtr, profile, outPtr, cap);
  const count = Math.min(total, cap);
  const view = new DataView(memory.buffer, outPtr, count * rowBytes);
  const suggestions = [];
  const maxVoices = counterpointStructSizes.maxVoices || 8;
  for (let index = 0; index < count; index += 1) {
    const base = index * rowBytes;
    const score = view.getInt32(base + 0, true);
    const reasonMask = view.getUint32(base + 4, true);
    const warningMask = view.getUint32(base + 8, true);
    const cadenceEffect = view.getUint8(base + 12);
    const tensionDelta = view.getInt8(base + 13);
    const noteCount = view.getUint8(base + 14);
    const setValue = view.getUint16(base + 18, true);
    const notes = [];
    for (let voiceIndex = 0; voiceIndex < Math.min(noteCount, maxVoices); voiceIndex += 1) {
      notes.push(view.getUint8(base + 20 + voiceIndex));
    }
    const motion = decodeMotionSummaryFromView(view, base + 28);
    const evaluation = decodeMotionEvaluationFromView(view, base + 112);
    const reasonNames = namesFromMask(reasonMask, counterpointReasonNames);
    const warningNames = namesFromMask(warningMask, counterpointWarningNames);
    suggestions.push({
      score,
      reasonMask,
      warningMask,
      cadenceEffect,
      cadenceLabel: cadenceLabel(cadenceEffect),
      tensionDelta,
      noteCount,
      setValue,
      notes,
      noteNames: notes.map((midi) => midiName(midi, context.tonic, context.quality)),
      chordLabel: friendlyChordName(rawChordName(setValue)),
      reasonNames,
      warningNames,
      motion,
      evaluation,
      fretPreview: preferredFretVoicing(arena, setValue, {
        preferredBassPc: notes.length > 0 ? Math.min(...notes) % 12 : null,
      }),
    });
  }
  return suggestions;
}

function decodeCadenceDestinations(arena, historyPtr, profile) {
  const cap = 6;
  const rowBytes = counterpointStructSizes.cadenceDestinationScore || 12;
  const outPtr = arena.alloc(rowBytes * cap, 4);
  const total = wasm.lmt_rank_cadence_destinations(historyPtr, profile, outPtr, cap);
  const count = Math.min(total, cap);
  const view = new DataView(memory.buffer, outPtr, count * rowBytes);
  const destinations = [];
  for (let index = 0; index < count; index += 1) {
    const base = index * rowBytes;
    const destination = view.getUint8(base + 4);
    destinations.push({
      score: view.getInt32(base + 0, true),
      destination,
      label: cadenceDestinationLabel(destination),
      candidateCount: view.getUint8(base + 5),
      warningCount: view.getUint8(base + 6),
      currentMatch: view.getUint8(base + 7) !== 0,
      tensionBias: view.getInt8(base + 8),
    });
  }
  return destinations;
}

function decodeSuspensionMachine(arena, historyPtr, profile, context) {
  const rowBytes = counterpointStructSizes.suspensionMachineSummary || 16;
  const outPtr = arena.alloc(rowBytes, 4);
  const written = wasm.lmt_analyze_suspension_machine(historyPtr, profile, outPtr);
  if (!written) return null;
  const view = new DataView(memory.buffer, outPtr, rowBytes);
  const state = view.getUint8(0);
  const heldMidi = view.getUint8(2);
  const expectedResolutionMidi = view.getUint8(3);
  return {
    state,
    stateLabel: suspensionStateLabel(state),
    trackedVoiceId: view.getUint8(1),
    heldMidi,
    heldNoteLabel: heldMidi <= 127 ? midiName(heldMidi, context.tonic, context.quality) : "",
    expectedResolutionMidi,
    expectedResolutionLabel: expectedResolutionMidi <= 127 ? midiName(expectedResolutionMidi, context.tonic, context.quality) : "",
    resolutionDirection: view.getInt8(4),
    obligationCount: view.getUint8(5),
    warningCount: view.getUint8(6),
    retainedCount: view.getUint8(7),
    currentTension: view.getInt16(8, true),
    previousTension: view.getInt16(10, true),
    candidateResolutionCount: view.getUint8(12),
  };
}

function historyFrameDescription(frame, context) {
  const notes = frame.notes.map((midi) => midiName(midi, context.tonic, context.quality));
  const sustained = frame.sustained.length > 0 ? ` · sustain ${frame.sustained.length}` : "";
  return `${notes.join(" · ")}${sustained}`;
}

function renderVoiceLeadingHorizon(host, currentState, suggestions, context) {
  if (!host) return { currentNodeCount: 0, candidateNodeCount: 0, connectorCount: 0, warningCandidateCount: 0, reasonTagCount: 0 };
  if (!currentState || currentState.voices.length === 0) {
    host.innerHTML = `<div class="output-block">Play or recall a voiced state to map the local motion field.</div>`;
    return { currentNodeCount: 0, candidateNodeCount: 0, connectorCount: 0, warningCandidateCount: 0, reasonTagCount: 0 };
  }

  const visibleSuggestions = suggestions.slice(0, 4);
  const width = 720;
  const height = 340;
  const centerX = 188;
  const centerY = 170;
  const candidateX = 518;
  const candidateYs = visibleSuggestions.length <= 1
    ? [centerY]
    : visibleSuggestions.map((_unused, index) => 68 + ((height - 136) * index) / (visibleSuggestions.length - 1));
  const currentLabel = currentState.voices.map((voice) => midiName(voice.midi, context.tonic, context.quality)).join(" · ");
  const maxScore = visibleSuggestions.reduce((max, suggestion) => Math.max(max, suggestion.score), visibleSuggestions[0]?.score || 1);
  const minScore = visibleSuggestions.reduce((min, suggestion) => Math.min(min, suggestion.score), visibleSuggestions[0]?.score || 0);

  const horizonSvg = `
    <svg class="counterpoint-figure horizon-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Voice-leading horizon">
      <defs>
        <linearGradient id="horizon-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="rgba(255,255,255,0.92)" />
          <stop offset="100%" stop-color="rgba(242,233,220,0.92)" />
        </linearGradient>
      </defs>
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="url(#horizon-bg)" stroke="rgba(24,36,47,0.10)" />
      <circle cx="${centerX}" cy="${centerY}" r="108" fill="rgba(31,125,134,0.05)" />
      <circle cx="${centerX}" cy="${centerY}" r="76" fill="rgba(31,125,134,0.08)" />
      <circle cx="${centerX}" cy="${centerY}" r="44" fill="rgba(31,125,134,0.12)" />
      <text x="42" y="52" class="counterpoint-label eyebrow">Voice-Leading Horizon</text>
      <text x="${centerX}" y="${centerY - 56}" text-anchor="middle" class="counterpoint-current-label">Current</text>
      <circle class="horizon-current-node" cx="${centerX}" cy="${centerY}" r="42" />
      ${currentState.voices.map((voice, index) => {
        const angle = (-90 + (index * 360) / Math.max(1, currentState.voices.length)) * (Math.PI / 180);
        const x = centerX + Math.cos(angle) * 28;
        const y = centerY + Math.sin(angle) * 28;
        return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="8.5" fill="${pitchClassColor(voice.pitchClass)}" stroke="white" stroke-width="2" />`;
      }).join("")}
      <text x="${centerX}" y="${centerY + 5}" text-anchor="middle" class="counterpoint-node-title">${escapeHtml(friendlyChordName(rawChordName(currentState.setValue)) || "Voiced state")}</text>
      <text x="${centerX}" y="${centerY + 24}" text-anchor="middle" class="counterpoint-node-notes">${escapeHtml(currentLabel)}</text>
      ${visibleSuggestions.map((suggestion, index) => {
        const y = candidateYs[index];
        const normalized = maxScore === minScore ? 1 : (suggestion.score - minScore) / Math.max(1, maxScore - minScore);
        const nodeRadius = 22 + normalized * 8;
        const stroke = suggestion.warningNames.length > 0 ? "rgba(161,22,102,0.82)" : "rgba(31,125,134,0.86)";
        const fill = suggestion.warningNames.length > 0 ? "rgba(161,22,102,0.10)" : "rgba(31,125,134,0.12)";
        const scoreText = `score ${suggestion.score}`;
        const notePreview = escapeHtml(suggestion.noteNames.join(" · "));
        const reason = escapeHtml(shortReasonLabel(suggestion.reasonNames[0] || ""));
        return `
          <path class="horizon-connector" d="M ${centerX + 44} ${centerY} C ${centerX + 132} ${centerY}, ${candidateX - 96} ${y}, ${candidateX - nodeRadius - 20} ${y}" stroke="${stroke}" stroke-width="${(2.4 + normalized * 2.4).toFixed(2)}" opacity="${(0.52 + normalized * 0.38).toFixed(2)}" />
          <circle class="horizon-candidate-node" cx="${candidateX}" cy="${y}" r="${nodeRadius.toFixed(1)}" fill="${fill}" stroke="${stroke}" />
          ${suggestion.warningNames.length > 0 ? `<circle class="horizon-warning-ring" cx="${candidateX}" cy="${y}" r="${(nodeRadius + 8).toFixed(1)}" />` : ""}
          ${suggestion.notes.map((midi, noteIndex) => {
            const angle = (-90 + (noteIndex * 360) / Math.max(1, suggestion.notes.length)) * (Math.PI / 180);
            const dotX = candidateX + Math.cos(angle) * Math.max(12, nodeRadius - 8);
            const dotY = y + Math.sin(angle) * Math.max(12, nodeRadius - 8);
            return `<circle cx="${dotX.toFixed(1)}" cy="${dotY.toFixed(1)}" r="5.6" fill="${pitchClassColor(midi % 12)}" stroke="white" stroke-width="1.5" />`;
          }).join("")}
          ${suggestion.reasonNames.slice(0, 2).map((reasonName, reasonIndex) => {
            const short = shortReasonLabel(reasonName);
            const tagX = candidateX - nodeRadius - 42;
            const tagY = y + 18 + reasonIndex * 18;
            const tagWidth = clamp(short.length * 6.4 + 18, 54, 112);
            return `
              <rect class="horizon-reason-tag" x="${(tagX - tagWidth / 2).toFixed(1)}" y="${(tagY - 10).toFixed(1)}" width="${tagWidth.toFixed(1)}" height="16" rx="8" />
              <text x="${tagX.toFixed(1)}" y="${(tagY + 1).toFixed(1)}" text-anchor="middle" class="counterpoint-reason-tag-label">${escapeHtml(short)}</text>
            `;
          }).join("")}
          <text x="${candidateX + 42}" y="${y - 12}" class="counterpoint-node-title">${escapeHtml(String.fromCharCode(65 + index))}. ${escapeHtml(suggestion.chordLabel)}</text>
          <text x="${candidateX + 42}" y="${y + 6}" class="counterpoint-node-notes">${notePreview}</text>
          <text x="${candidateX + 42}" y="${y + 24}" class="counterpoint-node-meta">${escapeHtml(scoreText)} · ${escapeHtml(suggestion.cadenceLabel)} · ${reason}</text>
        `;
      }).join("")}
    </svg>`;

  host.innerHTML = horizonSvg;
  return {
    currentNodeCount: 1,
    candidateNodeCount: visibleSuggestions.length,
    connectorCount: visibleSuggestions.length,
    warningCandidateCount: visibleSuggestions.filter((suggestion) => suggestion.warningNames.length > 0).length,
    reasonTagCount: visibleSuggestions.filter((suggestion) => suggestion.reasonNames.length > 0).length,
  };
}

function renderVoiceBraid(host, historyStates, candidateStates, context) {
  if (!host) return { historyColumnCount: 0, candidateColumnCount: 0, strandCount: 0, currentVoiceCount: 0, ghostNodeCount: 0 };
  if (!Array.isArray(historyStates) || historyStates.length === 0) {
    host.innerHTML = `<div class="output-block">The braid appears once we have a voiced history to compare against the current state.</div>`;
    return { historyColumnCount: 0, candidateColumnCount: 0, strandCount: 0, currentVoiceCount: 0, ghostNodeCount: 0 };
  }

  const visibleCandidates = candidateStates.filter(Boolean).slice(0, 3);
  const allStates = [...historyStates, ...visibleCandidates];
  const allMidis = allStates.flatMap((state) => state.voices.map((voice) => voice.midi));
  const minMidi = Math.min(...allMidis) - 2;
  const maxMidi = Math.max(...allMidis) + 2;
  const width = 720;
  const height = 320;
  const left = 72;
  const right = 46;
  const top = 42;
  const bottom = 40;
  const usableHeight = height - top - bottom;
  const historyStep = historyStates.length <= 1 ? 1 : (width - left - right - 220) / Math.max(1, historyStates.length - 1);
  const historyXs = historyStates.map((_state, index) => left + index * historyStep);
  const candidateBaseX = left + Math.max(1, historyStates.length - 1) * historyStep + 96;
  const candidateXs = visibleCandidates.map((_state, index) => candidateBaseX + index * 88);
  const currentState = historyStates[historyStates.length - 1];
  const voiceIds = [...new Set(allStates.flatMap((state) => state.voices.map((voice) => voice.id)))].sort((a, b) => a - b);
  const yForMidi = (midi) => top + (maxMidi - midi) * (usableHeight / Math.max(1, maxMidi - minMidi));
  const historyLabels = historyStates.map((_state, index) => index === historyStates.length - 1 ? "Current" : `T-${historyStates.length - index - 1}`);

  const gridLines = [];
  const guideCount = 5;
  for (let index = 0; index < guideCount; index += 1) {
    const midi = Math.round(maxMidi - (index * (maxMidi - minMidi)) / Math.max(1, guideCount - 1));
    const y = yForMidi(midi);
    gridLines.push(`
      <line x1="${left - 8}" y1="${y.toFixed(1)}" x2="${width - right}" y2="${y.toFixed(1)}" class="braid-guide" />
      <text x="12" y="${(y + 4).toFixed(1)}" class="braid-guide-label">${escapeHtml(midiName(midi, context.tonic, context.quality))}</text>
    `);
  }

  const solidStrands = voiceIds.map((voiceId) => {
    const points = historyStates
      .map((state, index) => {
        const voice = state.voices.find((one) => one.id === voiceId);
        return voice ? `${historyXs[index].toFixed(1)},${yForMidi(voice.midi).toFixed(1)}` : null;
      })
      .filter(Boolean);
    if (points.length < 2) return "";
    return `<polyline class="braid-strand" points="${points.join(" ")}" stroke="${voiceColor(voiceId)}" />`;
  }).join("");

  const ghostStrands = visibleCandidates.map((state, candidateIndex) => {
    return state.voices.map((voice) => {
      const currentVoice = currentState.voices.find((one) => one.id === voice.id);
      if (!currentVoice) return "";
      return `<line class="braid-ghost-strand" x1="${historyXs[historyXs.length - 1].toFixed(1)}" y1="${yForMidi(currentVoice.midi).toFixed(1)}" x2="${candidateXs[candidateIndex].toFixed(1)}" y2="${yForMidi(voice.midi).toFixed(1)}" stroke="${voiceColor(voice.id)}" />`;
    }).join("");
  }).join("");

  const historyColumns = historyXs.map((x, index) => `
      <line class="braid-column braid-history-column" x1="${x.toFixed(1)}" y1="${(top - 10).toFixed(1)}" x2="${x.toFixed(1)}" y2="${(height - bottom + 4).toFixed(1)}" />
      <text x="${x.toFixed(1)}" y="${height - 12}" text-anchor="middle" class="braid-column-label">${historyLabels[index]}</text>
    `).join("");

  const candidateColumns = candidateXs.map((x, index) => `
      <line class="braid-column braid-candidate-column" x1="${x.toFixed(1)}" y1="${(top - 10).toFixed(1)}" x2="${x.toFixed(1)}" y2="${(height - bottom + 4).toFixed(1)}" stroke-dasharray="5 7" />
      <text x="${x.toFixed(1)}" y="${height - 12}" text-anchor="middle" class="braid-column-label braid-column-label-ghost">${escapeHtml(String.fromCharCode(65 + index))}</text>
    `).join("");

  const voiceNodes = historyStates.map((state, index) => state.voices.map((voice) => `
      <circle class="braid-node ${index === historyStates.length - 1 ? "braid-current-node" : "braid-history-node"}" cx="${historyXs[index].toFixed(1)}" cy="${yForMidi(voice.midi).toFixed(1)}" r="${index === historyStates.length - 1 ? "8.5" : "6.8"}" fill="${pitchClassColor(voice.pitchClass)}" stroke="${voiceColor(voice.id)}" />
    `).join("")).join("");

  const ghostNodes = visibleCandidates.map((state, candidateIndex) => state.voices.map((voice) => `
      <circle class="braid-node braid-ghost-node" cx="${candidateXs[candidateIndex].toFixed(1)}" cy="${yForMidi(voice.midi).toFixed(1)}" r="6.5" fill="${pitchClassColor(voice.pitchClass)}" stroke="${voiceColor(voice.id)}" />
    `).join("")).join("");

  const braidSvg = `
    <svg class="counterpoint-figure braid-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Voice braid">
      <rect x="0" y="0" width="${width}" height="${height}" rx="28" fill="rgba(255,255,255,0.92)" stroke="rgba(24,36,47,0.10)" />
      <text x="${left}" y="26" class="counterpoint-label eyebrow">Voice Braid</text>
      ${gridLines.join("")}
      ${historyColumns}
      ${candidateColumns}
      ${solidStrands}
      ${ghostStrands}
      ${voiceNodes}
      ${ghostNodes}
    </svg>`;

  host.innerHTML = braidSvg;
  return {
    historyColumnCount: historyStates.length,
    candidateColumnCount: visibleCandidates.length,
    strandCount: voiceIds.length,
    currentVoiceCount: currentState.voices.length,
    ghostNodeCount: visibleCandidates.reduce((sum, state) => sum + state.voices.length, 0),
  };
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
        profile: Number.isFinite(Number(one.profile)) ? Number(one.profile) : MIDI_DEFAULT_PROFILE,
        contextLabel: typeof one.contextLabel === "string" ? one.contextLabel : "",
        historyFrames: sanitizeHistoryFrames(one.historyFrames),
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
  const profile = currentMidiProfile();
  const duplicate = midiState.snapshots[0];
  if (
    duplicate
    && JSON.stringify(duplicate.midiNotes) === JSON.stringify(midiNotes)
    && duplicate.tonic === context.tonic
    && duplicate.modeType === context.modeType
    && duplicate.profile === profile
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
        profile,
        contextLabel: context.label,
        historyFrames: midiState.historyFrames.map(cloneHistoryFrame),
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
    midiProfileEl.value = String(snapshot.profile ?? MIDI_DEFAULT_PROFILE);
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
        <span>${escapeHtml(counterpointProfileNames[snapshot.profile ?? MIDI_DEFAULT_PROFILE] || "species")}</span>
        <span>${escapeHtml(snapshot.noteLabel)}</span>
        <span>${new Date(snapshot.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}</span>
      </button>
    `)
    .join("");
}

function renderMidiScene() {
  const liveNotes = currentLiveMidiNotes();
  const displayNotes = currentDisplayMidiNotes();
  const context = currentDisplayMidiContext();
  const viewingSnapshot = midiState.activeSnapshotId != null;
  const profile = currentMidiProfile();
  const profileLabel = counterpointProfileNames[profile] || DEFAULT_COUNTERPOINT_PROFILE_NAMES[profile] || "species";

  midiCaptionEl.textContent = summarizeMidiAccess();
  connectMidiEl.disabled = midiState.accessState === "connecting";
  midiSaveSnapshotEl.disabled = liveNotes.length === 0;
  midiReturnLiveEl.disabled = !viewingSnapshot;

  const statusPills = [];
  statusPills.push(`<span class="status-pill ${viewingSnapshot ? "is-snapshot" : "is-live"}">${viewingSnapshot ? "Viewing snapshot" : "Live input"}</span>`);
  statusPills.push(`<span class="status-pill ${liveNotes.length > 0 ? "is-live" : "is-muted"}">${liveNotes.length} sounding</span>`);
  statusPills.push(`<span class="status-pill ${midiState.snapshots.length > 0 ? "is-snapshot" : "is-muted"}">${midiState.snapshots.length} saved</span>`);
  statusPills.push(`<span class="status-pill is-live">${escapeHtml(context.label)}</span>`);
  statusPills.push(`<span class="status-pill is-live">${escapeHtml(profileLabel)}</span>`);
  statusPills.push(`<span class="status-pill ${miniInstrumentMode() === MINI_INSTRUMENT_OFF ? "is-muted" : "is-live"}">mini ${escapeHtml(miniInstrumentMode())}</span>`);
  midiStatusPillsEl.innerHTML = statusPills.join("");
  midiDevicesEl.innerHTML = Array.from(midiState.inputs.values()).map((input) =>
    `<span class="pill">${escapeHtml(input.name || input.manufacturer || input.id || "MIDI input")}</span>`).join("")
    || `<span class="pill">No MIDI input devices reported yet</span>`;

  renderMidiSnapshotCards();

  const arena = new ScratchArena();
  try {
    const setValue = midiListToSet(arena, displayNotes);
    const currentChord = friendlyChordName(rawChordName(setValue));
    const keyboardNotes = displayNotes.length > 0 ? displayNotes : keyboardPreviewNotesForContext(context);
    const keyboardRange = keyboardRangeForNotes(keyboardNotes, 48, 84);
    const contextOverlap = wasm.lmt_pcs_cardinality(setValue & context.setValue);
    const outsideCount = wasm.lmt_pcs_cardinality(setValue) - contextOverlap;
    const historyFrames = effectiveHistoryFrames(displayNotes);
    const historyBundle = historyFrames.length > 0 ? buildCounterpointHistory(arena, historyFrames, context) : null;
    const suggestions = historyBundle ? decodeRankedNextSteps(arena, historyBundle.historyPtr, profile, context) : [];
    const voicedHistory = historyBundle ? decodeVoicedHistoryFromPointer(historyBundle.historyPtr) : { len: 0, states: [] };
    const currentVoicedState = voicedHistory.states[voicedHistory.states.length - 1] || null;
    const currentMotionAnalysis = buildCurrentMotionAnalysis(arena, historyBundle, voicedHistory, profile);
    const cadenceDestinations = historyBundle ? decodeCadenceDestinations(arena, historyBundle.historyPtr, profile) : [];
    const suspensionMachine = historyBundle ? decodeSuspensionMachine(arena, historyBundle.historyPtr, profile, context) : null;
    if (suggestions.length === 0) {
      midiState.hoveredSuggestionIndex = null;
    } else if (midiState.hoveredSuggestionIndex == null || midiState.hoveredSuggestionIndex >= suggestions.length) {
      midiState.hoveredSuggestionIndex = 0;
    }
    const hoveredSuggestionIndex = suggestions.length > 0
      ? clamp(midiState.hoveredSuggestionIndex ?? 0, 0, suggestions.length - 1)
      : null;
    const candidateStates = currentVoicedState
      ? suggestions.map((suggestion, index) =>
        buildCandidateVoicedState(
          arena,
          suggestion.notes,
          context,
          historyBundle?.statePtr || null,
          (currentVoicedState.stateIndex || historyFrames.length || 0) + index + 1,
        ))
      : [];
    const displayNotesLabel = displayNotes.length > 0
      ? displayNotes.map((midi) => midiName(midi, context.tonic, context.quality))
      : [];
    const orbitNames = orderedMembersFromSet(context.setValue, context.tonic).map((pc) => spellNote(pc, context.tonic, context.quality));
    const clockSvg = svgString(arena, wasm.lmt_svg_clock_optc, setValue);
    const opticKSvg = svgString(arena, wasm.lmt_svg_optic_k_group, setValue);
    const evennessFieldSvg = svgString(arena, wasm.lmt_svg_evenness_field, setValue);
    const staffSvg = displayNotes.length > 0 ? svgString(arena, wasm.lmt_svg_piano_staff, writeU8Array(arena, displayNotes), displayNotes.length, context.tonic, context.quality) : "";

    midiSummaryEl.textContent = [
      `mode: ${viewingSnapshot ? "snapshot preview" : "live input"}`,
      `selected context: ${context.label}`,
      `counterpoint profile: ${profileLabel}`,
      `active MIDI notes: ${displayNotes.length > 0 ? displayNotes.join(", ") : "none"}`,
      `set: ${setValue === 0 ? "0x000 []" : `0x${setValue.toString(16).padStart(3, "0")} ${JSON.stringify(setMembers(setValue))}`}`,
      `hearing: ${setValue === 0 ? "awaiting notes" : currentChord}`,
      `context orbit: ${orbitNames.join(" · ")}`,
      `context overlap: ${contextOverlap}/${wasm.lmt_pcs_cardinality(setValue)} inside, ${outsideCount} outside`,
      `temporal memory frames: ${historyFrames.length}`,
      `next-step suggestions: ${suggestions.length}`,
      `last event: ${midiState.lastEventText}`,
    ].join("\n");

    if (displayNotesLabel.length > 0) {
      setChipRow(midiNotesEl, displayNotesLabel);
    } else {
      midiNotesEl.innerHTML = `<span class="pill">Play a chord or melodic fragment. Sustain is tracked; middle pedal saves snapshots.</span>`;
    }

    midiHistoryEl.innerHTML = historyFrames.length > 0
      ? historyFrames.map((frame, index) => `
        <div class="history-card${index === historyFrames.length - 1 ? " is-current" : ""}">
          <strong>${index === historyFrames.length - 1 ? "Current" : `T-${historyFrames.length - index - 1}`}</strong>
          <span>${escapeHtml(historyFrameDescription(frame, context))}</span>
        </div>
      `).join("")
      : `<div class="output-block">Recent motion memory appears here after at least one voiced change.</div>`;

    const midiHorizonFeatures = renderVoiceLeadingHorizon(midiHorizonEl, currentVoicedState, suggestions, context);
    const midiBraidFeatures = renderVoiceBraid(midiBraidEl, voicedHistory.states, candidateStates, context);
    const midiWeatherFeatures = renderCounterpointWeatherMap(midiWeatherEl, currentVoicedState, suggestions, hoveredSuggestionIndex, context);
    const midiRiskRadarFeatures = renderParallelRiskRadar(midiRiskRadarEl, currentMotionAnalysis, suggestions, hoveredSuggestionIndex);
    const midiCadenceFunnelFeatures = renderCadenceFunnel(midiCadenceFunnelEl, currentVoicedState, cadenceDestinations, suggestions, context);
    const midiSuspensionMachineFeatures = renderSuspensionMachine(midiSuspensionMachineEl, suspensionMachine);
    const midiOrbifoldRibbonFeatures = renderOrbifoldRibbon(midiOrbifoldRibbonEl, currentVoicedState, suggestions, hoveredSuggestionIndex, context);
    const midiCommonToneConstellationFeatures = renderCommonToneConstellation(
      midiCommonToneConstellationEl,
      currentVoicedState,
      candidateStates,
      suggestions,
      hoveredSuggestionIndex,
      voicedHistory.states,
      context,
    );

    renderPreviewSvgOrBitmap(midiClockEl, {
      svgMarkup: clockSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => clockBitmapRgba(arena, setValue, width, height),
      },
      alt: "Live clock preview",
      options: { maxHeight: 420, squareWidth: 420, mediumWidth: 520, preserveViewBox: true },
    });
    renderPreviewSvgOrBitmap(midiOpticKEl, {
      svgMarkup: opticKSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => opticKBitmapRgba(arena, setValue, width, height),
      },
      alt: "Live OPTIC/K bitmap preview",
      options: { maxHeight: 300, squareWidth: 520, mediumWidth: 620, wideWidth: 720, ultraWideWidth: 760, preserveViewBox: true },
    });
    renderPreviewSvgOrBitmap(midiEvennessEl, {
      svgMarkup: evennessFieldSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => evennessFieldBitmapRgba(arena, setValue, width, height),
      },
      alt: "Live evenness bitmap preview",
      options: { maxHeight: 560, squareWidth: 420, mediumWidth: 520, wideWidth: 620, ultraWideWidth: 680, preserveViewBox: true },
    });
    renderPreviewSvgOrBitmap(midiKeyboardEl, {
      svgMarkup: svgString(arena, wasm.lmt_svg_keyboard, writeU8Array(arena, keyboardNotes), keyboardNotes.length, keyboardRange.low, keyboardRange.high),
      bitmapRenderer: {
        renderRgba: (width, height) => keyboardBitmapRgba(arena, keyboardNotes, keyboardRange.low, keyboardRange.high, width, height),
      },
      alt: "Live keyboard bitmap preview",
      options: { maxHeight: 260, squareWidth: 780, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1160, padXRatio: 0.02, padYRatio: 0.08 },
    });

    if (displayNotes.length > 0) {
      renderPreviewSvgOrBitmap(midiStaffEl, {
        svgMarkup: staffSvg,
        bitmapRenderer: {
          renderRgba: (width, height) => pianoStaffBitmapRgba(arena, displayNotes, context.tonic, context.quality, width, height),
        },
        alt: "Live piano staff bitmap preview",
        options: { maxHeight: 420, squareWidth: 700, mediumWidth: 840, wideWidth: 980, ultraWideWidth: 1120, padXRatio: 0.05, padYRatio: 0.12 },
      });
    } else {
      midiStaffEl.innerHTML = `<div class="output-block">Play notes across the keyboard to paint treble, bass, or grand staff directly from the live MIDI state.</div>`;
    }

    if (displayNotes.length > 0) {
      renderMiniInstrumentPreview(
        arena,
        midiCurrentFretEl,
        {
          midiNotes: displayNotes,
          setValue,
          tonic: context.tonic,
          preferredBassPc: displayNotes.length > 0 ? Math.min(...displayNotes) % 12 : null,
        },
        "Current selection fret preview",
        {
          modeOverride: MINI_INSTRUMENT_FRET,
          maxHeight: 280,
          squareWidth: 260,
          mediumWidth: 320,
          wideWidth: 360,
          ultraWideWidth: 400,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
    } else {
      midiCurrentFretEl.innerHTML = `<div class="output-block">Play notes to see the current voicing on frets and the suggested next fret shapes.</div>`;
    }
    const currentMiniRendered = displayNotes.length > 0 && miniInstrumentMode() !== MINI_INSTRUMENT_OFF;

    if (suggestions.length === 0) {
      midiSuggestionsEl.innerHTML = `<p class="snapshot-empty">Once at least one note is sounding, libmusictheory will rank voiced next moves against ${escapeHtml(context.label)} here.</p>`;
    } else {
      midiSuggestionsEl.innerHTML = suggestions.map((suggestion, index) => `
        <article class="suggestion-card${hoveredSuggestionIndex === index ? " is-focused" : ""}" data-suggestion-index="${index}" tabindex="0">
          <strong>${String.fromCharCode(65 + index)}. ${escapeHtml(suggestion.noteNames.join(" · "))}</strong>
          <p>${escapeHtml(suggestion.chordLabel)}</p>
          <p>score ${escapeHtml(String(suggestion.score))} · cadence ${escapeHtml(suggestion.cadenceLabel)} · tension ${escapeHtml(suggestion.tensionDelta >= 0 ? `+${suggestion.tensionDelta}` : String(suggestion.tensionDelta))}</p>
          <div class="chip-row suggestion-reasons">${suggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}</div>
          <div class="chip-row suggestion-warnings">${suggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}</div>
          <div class="suggestion-art-grid">
            <div class="suggestion-art" data-suggestion-clock="${index}"></div>
            <div class="suggestion-art suggestion-art-fret suggestion-mini" data-suggestion-mini="${index}"></div>
          </div>
          <div class="suggestion-fret-meta">${escapeHtml(suggestion.noteNames.join(" · "))}</div>
        </article>
      `).join("");
      suggestions.forEach((suggestion, index) => {
        const clockHost = midiSuggestionsEl.querySelector(`[data-suggestion-clock="${index}"]`);
        if (clockHost) {
          renderPreviewSvgOrBitmap(clockHost, {
            svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, suggestion.setValue),
            bitmapRenderer: {
              renderRgba: (width, height) => clockBitmapRgba(arena, suggestion.setValue, width, height),
            },
            alt: `${suggestion.noteNames.join(" ")} clock bitmap preview`,
            options: { maxHeight: 160, squareWidth: 160, mediumWidth: 180, wideWidth: 180, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
          });
        }
        const miniHost = midiSuggestionsEl.querySelector(`[data-suggestion-mini="${index}"]`);
        if (miniHost) {
          renderMiniInstrumentPreview(
            arena,
            miniHost,
            {
              midiNotes: suggestion.notes,
              setValue: suggestion.setValue,
              tonic: context.tonic,
              preferredBassPc: suggestion.notes.length > 0 ? Math.min(...suggestion.notes) % 12 : null,
              fretVoicing: suggestion.fretPreview,
            },
            `${suggestion.noteNames.join(" ")} fret preview`,
            {
              modeOverride: MINI_INSTRUMENT_FRET,
              maxHeight: 160,
              squareWidth: 170,
              mediumWidth: 180,
              wideWidth: 190,
              ultraWideWidth: 200,
              padXRatio: 0.08,
              padYRatio: 0.14,
            },
          );
        }
      });
    }

    const keyboardFeatures = inspectKeyboardNotes(keyboardNotes, keyboardRange.low, keyboardRange.high);
    const midiOpticKFeatures = inspectOpticKMarkup(opticKSvg);
    const midiEvennessFeatures = inspectEvennessMarkup(evennessFieldSvg);
    const midiStaffFeatures = inspectStaffMarkup(staffSvg);

    updateSummaryScene("midi", {
      supported: midiState.supported,
      accessState: midiState.accessState,
      inputCount: midiState.inputs.size,
      liveCount: liveNotes.length,
      displayCount: displayNotes.length,
      snapshotCount: midiState.snapshots.length,
      viewingSnapshot,
      contextLabel: context.label,
      counterpointProfile: profileLabel,
      counterpointProfileId: profile,
      tonic: context.tonic,
      modeType: context.modeType,
      historyFrameCount: historyFrames.length,
      insideCount: contextOverlap,
      outsideCount,
      chordName: setValue === 0 ? "" : currentChord,
      suggestionCount: suggestions.length,
      suggestionNames: suggestions.map((one) => one.noteNames.join(" · ")),
      topSuggestionSignature: suggestions[0]?.notes?.join(",") || "",
      hoveredCandidateIndex: hoveredSuggestionIndex == null ? -1 : hoveredSuggestionIndex,
      currentMiniMode: miniInstrumentMode(),
      currentMiniRendered,
      suggestionMiniCount: suggestions.length,
      midiOpticKFeatures,
      midiEvennessFeatures,
      midiStaffFeatures,
      midiHorizonFeatures,
      midiBraidFeatures,
      midiWeatherFeatures,
      midiRiskRadarFeatures,
      midiCadenceFunnelFeatures,
      midiSuspensionMachineFeatures,
      midiOrbifoldRibbonFeatures,
      midiCommonToneConstellationFeatures,
      keyboardFeatures,
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
  captureMidiHistoryFrame();
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
    setOpticKEl.innerHTML = "";
    setEvennessEl.innerHTML = "";
    setMiniEl.innerHTML = `<div class="output-block">Select at least one pitch class to mirror it on the chosen mini instrument.</div>`;
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
    const opticKSvg = svgString(arena, wasm.lmt_svg_optic_k_group, setValue);
    const evennessSvg = svgString(arena, wasm.lmt_svg_evenness_field, setValue);

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
    renderPreviewSvgOrBitmap(setClockEl, {
      svgMarkup: svg,
      bitmapRenderer: {
        renderRgba: (width, height) => clockBitmapRgba(arena, setValue, width, height),
      },
      alt: "Set clock bitmap preview",
      options: { maxHeight: 420, squareWidth: 420, mediumWidth: 520, preserveViewBox: true },
    });
    renderPreviewSvgOrBitmap(setOpticKEl, {
      svgMarkup: opticKSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => opticKBitmapRgba(arena, setValue, width, height),
      },
      alt: "Set OPTIC/K bitmap preview",
      options: { maxHeight: 320, squareWidth: 620, mediumWidth: 760, wideWidth: 840, ultraWideWidth: 920, preserveViewBox: true },
    });
    renderPreviewSvgOrBitmap(setEvennessEl, {
      svgMarkup: evennessSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => evennessFieldBitmapRgba(arena, setValue, width, height),
      },
      alt: "Set evenness bitmap preview",
      options: { maxHeight: 560, squareWidth: 420, mediumWidth: 520, wideWidth: 620, ultraWideWidth: 680, preserveViewBox: true },
    });
    const anchor = bestSetAnchor(setValue);
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      setMiniEl,
      { setValue, tonic: anchor.tonic, quality: anchor.quality },
      "Set mini instrument preview",
      { maxHeight: 220, squareWidth: 240, mediumWidth: 260, wideWidth: 280, ultraWideWidth: 300 },
    );
    const setOpticKFeatures = inspectOpticKMarkup(opticKSvg);
    const setEvennessFeatures = inspectEvennessMarkup(evennessSvg);
    updateSummaryScene("set", {
      selectedCount: pcsList.length,
      setHex: `0x${setValue.toString(16).padStart(3, "0")}`,
      chordName,
      primeHex: `0x${prime.toString(16).padStart(3, "0")}`,
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
      setOpticKFeatures,
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
    const keyClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, orbit.setValue);
    const keyStaffSvg = svgString(arena, wasm.lmt_svg_key_staff, tonic, quality);
    renderPreviewSvgOrBitmap(keyClockEl, {
      svgMarkup: keyClockSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => clockBitmapRgba(arena, orbit.setValue, width, height),
      },
      alt: "Key orbit bitmap preview",
      options: { maxHeight: 440, squareWidth: 440, mediumWidth: 560 },
    });
    renderPreviewSvgOrBitmap(keyStaffEl, {
      svgMarkup: keyStaffSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => keyStaffBitmapRgba(arena, tonic, quality, width, height),
      },
      alt: "Key staff bitmap preview",
      options: { maxHeight: 240, squareWidth: 780, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1120, padXRatio: 0.04, padYRatio: 0.12 },
    });
    const keyKeyboardNotes = keyboardPreviewNotesForSet(orbit.setValue, orbit.tonic);
    renderPreviewSvgOrBitmap(keyKeyboardEl, {
      svgMarkup: svgString(arena, wasm.lmt_svg_keyboard, writeU8Array(arena, keyKeyboardNotes), keyKeyboardNotes.length, 36, 96),
      bitmapRenderer: {
        renderRgba: (width, height) => keyboardBitmapRgba(arena, keyKeyboardNotes, 36, 96, width, height),
      },
      alt: "Key keyboard bitmap preview",
      options: { maxHeight: 260, squareWidth: 780, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1160, padXRatio: 0.02, padYRatio: 0.08 },
    });
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      keyMiniEl,
      { setValue: orbit.setValue, tonic: orbit.tonic, quality, midiNotes: keyKeyboardNotes },
      "Key mini instrument preview",
      { maxHeight: 220, squareWidth: 260, mediumWidth: 300, wideWidth: 320, ultraWideWidth: 340 },
    );
    const keyStaffFeatures = inspectStaffMarkup(keyStaffSvg);
    const keyboardFeatures = inspectKeyboardNotes(keyKeyboardNotes, 36, 96);

    updateSummaryScene("key", {
      tonic: noteName(tonic),
      quality: quality === 0 ? "major" : "minor",
      noteCount: orbit.ordered.length,
      degrees: degreeCards.length,
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
      keyStaffFeatures,
      keyboardFeatures,
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

    const chordClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, chordSet);
    const chordStaffSvg = svgString(arena, wasm.lmt_svg_chord_staff, chordType, root);
    renderPreviewSvgOrBitmap(chordClockEl, {
      svgMarkup: chordClockSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => clockBitmapRgba(arena, chordSet, width, height),
      },
      alt: "Chord clock bitmap preview",
      options: { maxHeight: 360, squareWidth: 320, mediumWidth: 380 },
    });
    renderPreviewSvgOrBitmap(chordStaffEl, {
      svgMarkup: chordStaffSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => chordStaffBitmapRgba(arena, chordType, root, width, height),
      },
      alt: "Chord staff bitmap preview",
      options: { maxHeight: 320, squareWidth: 620, mediumWidth: 780, wideWidth: 920, ultraWideWidth: 1040, padXRatio: 0.05, padYRatio: 0.12 },
    });
    const chordMidiNotes = keyboardPreviewNotesForSet(chordSet, root);
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      chordMiniEl,
      { setValue: chordSet, tonic: root, quality: keyQuality, midiNotes: chordMidiNotes, preferredBassPc: root },
      "Chord mini instrument preview",
      { maxHeight: 220, squareWidth: 240, mediumWidth: 280, wideWidth: 300, ultraWideWidth: 320 },
    );
    const staffFeatures = inspectStaffMarkup(chordStaffSvg);

    updateSummaryScene("chord", {
      root: noteName(root),
      chordName,
      roman,
      inKey,
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
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
    const progressionClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, unionSet);
    renderPreviewSvgOrBitmap(progressionClockEl, {
      svgMarkup: progressionClockSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => clockBitmapRgba(arena, unionSet, width, height),
      },
      alt: "Progression clock bitmap preview",
      options: { maxHeight: 340, squareWidth: 320, mediumWidth: 460 },
    });
    progressionNotesEl.innerHTML = unionNotes.map((note) => `<span class="chip">${escapeHtml(note)}</span>`).join("");
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      progressionMiniEl,
      { setValue: unionSet, tonic: preset.tonic, quality: preset.quality },
      "Progression mini instrument preview",
      { maxHeight: 220, squareWidth: 240, mediumWidth: 280, wideWidth: 300, ultraWideWidth: 320 },
    );
    normalizeSvgPreview(progressionCardsEl, { maxHeight: 132, squareWidth: 124, mediumWidth: 132, wideWidth: 146, ultraWideWidth: 146, padXRatio: 0.14, padYRatio: 0.18 });

    updateSummaryScene("progression", {
      tonic: noteName(preset.tonic),
      quality: preset.quality === 0 ? "major" : "minor",
      steps: preset.degrees.length,
      unionCardinality: wasm.lmt_pcs_cardinality(unionSet),
      strongestLink,
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
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

    const leftClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, leftSet);
    const overlapClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, overlapSet);
    const rightClockSvg = svgString(arena, wasm.lmt_svg_clock_optc, rightSet);
    const comparePreviewOptions = { maxHeight: 260, squareWidth: 260, mediumWidth: 280 };
    renderPreviewSvgOrBitmap(compareLeftClockEl, {
      svgMarkup: leftClockSvg,
      bitmapRenderer: { renderRgba: (width, height) => clockBitmapRgba(arena, leftSet, width, height) },
      alt: "Compare left bitmap preview",
      options: comparePreviewOptions,
    });
    renderPreviewSvgOrBitmap(compareOverlapClockEl, {
      svgMarkup: overlapClockSvg,
      bitmapRenderer: { renderRgba: (width, height) => clockBitmapRgba(arena, overlapSet, width, height) },
      alt: "Compare overlap bitmap preview",
      options: comparePreviewOptions,
    });
    renderPreviewSvgOrBitmap(compareRightClockEl, {
      svgMarkup: rightClockSvg,
      bitmapRenderer: { renderRgba: (width, height) => clockBitmapRgba(arena, rightSet, width, height) },
      alt: "Compare right bitmap preview",
      options: comparePreviewOptions,
    });

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
    const anchor = bestSetAnchor(unionSet);
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      compareMiniEl,
      { setValue: unionSet, tonic: anchor.tonic, quality: anchor.quality },
      "Compare mini instrument preview",
      { maxHeight: 220, squareWidth: 240, mediumWidth: 280, wideWidth: 300, ultraWideWidth: 320 },
    );

    updateSummaryScene("compare", {
      leftCardinality: wasm.lmt_pcs_cardinality(leftSet),
      rightCardinality: wasm.lmt_pcs_cardinality(rightSet),
      sharedCardinality: wasm.lmt_pcs_cardinality(overlapSet),
      transposeMatch: relation.transposeMatch,
      inversionMatch: relation.inversionMatch,
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
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

    const fretSvg = svgString(arena, wasm.lmt_svg_fret_n, fretsPtr, frets.length, windowStart, visibleFrets);
    renderPreviewSvgOrBitmap(fretSvgEl, {
      svgMarkup: fretSvg,
      bitmapRenderer: {
        renderRgba: (width, height) => fretBitmapRgba(arena, frets, windowStart, visibleFrets, width, height),
      },
      alt: "Fretboard bitmap preview",
      options: { maxHeight: 500, squareWidth: 360, mediumWidth: 520, wideWidth: 680, ultraWideWidth: 760, padXRatio: 0.12, padYRatio: 0.18 },
    });
    setChipRow(
      fretNotesEl,
      selected.map((one) => `s${one.string + 1}:f${one.fret} ${noteName(one.pc)} (${one.midi})`),
    );
    setChipRow(fretVoicingsEl, voicings.length > 0 ? voicings : ["no alternate voicings within constraints"], "pill");
    const miniRendered = renderMiniInstrumentPreview(
      arena,
      fretMiniEl,
      {
        midiNotes: selected.map((one) => one.midi),
        setValue: chordSet,
        tonic: selected.length > 0 ? selected[0].pc : 0,
        fretVoicing: {
          frets: frets.slice(),
          windowStart,
          visibleFrets,
          tuning: tuning.slice(),
          tuningLabel: tuning.join(","),
          isStandardTuning: isStandardTuning(tuning),
          url: fretUrl,
        },
      },
      "Fret scene mini instrument preview",
      { maxHeight: 220, squareWidth: 240, mediumWidth: 280, wideWidth: 300, ultraWideWidth: 320 },
    );

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
      miniInstrumentMode: miniInstrumentMode(),
      miniRendered,
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
  setStatus(`Gallery ready in ${galleryUiState.previewMode.toUpperCase()} preview mode. Curated public API scenes rendered successfully.`);
}

function wireSceneEvents() {
  [previewModeSvgEl, previewModeBitmapEl].forEach((button) => {
    button.addEventListener("click", () => {
      const nextMode = button.dataset.previewMode === PREVIEW_MODE_BITMAP ? PREVIEW_MODE_BITMAP : PREVIEW_MODE_SVG;
      if (nextMode === galleryUiState.previewMode) return;
      setPreviewMode(nextMode);
    });
  });
  miniInstrumentModeEl.addEventListener("change", () => {
    setMiniInstrumentMode(miniInstrumentModeEl.value);
    setStatus(`Mini instrument set to ${galleryUiState.miniInstrument}.`);
  });
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
  const focusSuggestionIndex = (event) => {
    const card = event.target.closest("[data-suggestion-index]");
    if (!card) return;
    const nextIndex = Number.parseInt(card.getAttribute("data-suggestion-index") || "-1", 10);
    if (!Number.isInteger(nextIndex) || nextIndex < 0 || midiState.hoveredSuggestionIndex === nextIndex) return;
    midiState.hoveredSuggestionIndex = nextIndex;
    renderMidiScene();
  };
  midiSuggestionsEl.addEventListener("mouseover", focusSuggestionIndex);
  midiSuggestionsEl.addEventListener("focusin", focusSuggestionIndex);
  midiSuggestionsEl.addEventListener("mouseleave", () => {
    if (midiState.hoveredSuggestionIndex !== 0 && midiState.hoveredSuggestionIndex != null) {
      midiState.hoveredSuggestionIndex = 0;
      renderMidiScene();
    }
  });
  [midiTonicEl, midiModeEl].forEach((node) => node.addEventListener("change", () => {
    renderMidiScene();
    setStatus(`${MIDI_SCENE_TITLE} context set to ${currentMidiContext().label}.`);
  }));
  midiProfileEl.addEventListener("change", () => {
    renderMidiScene();
    setStatus(`${MIDI_SCENE_TITLE} counterpoint profile set to ${counterpointProfileNames[currentMidiProfile()] || "species"}.`);
  });
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
  populateCounterpointProfileSelect(midiProfileEl);
  createNoteSelectors(keyTonicEl);
  createNoteSelectors(chordRootEl);
  createNoteSelectors(chordKeyTonicEl);
  buildToggleGrid();
  hydrateMidiSnapshots();
  midiTonicEl.value = String(MIDI_DEFAULT_TONIC);
  midiModeEl.value = String(MIDI_DEFAULT_MODE);
  midiProfileEl.value = String(MIDI_DEFAULT_PROFILE);
  setPreviewMode(loadPreviewModePreference(), { persist: false, rerender: false });
  setMiniInstrumentMode(loadMiniInstrumentPreference(), { persist: false, rerender: false });
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
    loadCounterpointMetadata();
    populateCounterpointProfileSelect(midiProfileEl);
    midiProfileEl.value = String(MIDI_DEFAULT_PROFILE);
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
