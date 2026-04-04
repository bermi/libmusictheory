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
const midiInspectorEl = document.getElementById("midi-inspector");
const midiConsensusAtlasEl = document.getElementById("midi-consensus-atlas");
const midiObligationLedgerEl = document.getElementById("midi-obligation-ledger");
const midiResolutionThreaderEl = document.getElementById("midi-resolution-threader");
const midiObligationTimelineEl = document.getElementById("midi-obligation-timeline");
const midiVoiceDutiesEl = document.getElementById("midi-voice-duties");
const midiContinuationLadderEl = document.getElementById("midi-continuation-ladder");
const midiPathWeaverEl = document.getElementById("midi-path-weaver");
const midiCadenceGardenEl = document.getElementById("midi-cadence-garden");
const midiProfileOrchardEl = document.getElementById("midi-profile-orchard");
const midiClearPinEl = document.getElementById("midi-clear-pin");
const midiClockEl = document.getElementById("midi-clock");
const midiOpticKEl = document.getElementById("midi-optic-k");
const midiEvennessEl = document.getElementById("midi-evenness");
const midiStaffEl = document.getElementById("midi-staff");
const midiKeyboardEl = document.getElementById("midi-keyboard");
const midiCurrentFretEl = document.getElementById("midi-current-fret");
const midiFocusedMiniEl = document.getElementById("midi-focused-mini");
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
  pinnedSuggestionIndex: null,
  pinnedSuggestionSignature: "",
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
    return { currentAnchorCount: 0, cellCount: 0, warningCellCount: 0, positivePressureCount: 0, negativePressureCount: 0, hoveredCandidateIndex: -1, focusedCandidateIndex: -1 };
  }
  if (!currentState || currentState.voices.length === 0 || suggestions.length === 0) {
    host.innerHTML = `<div class="output-block">Play or recall a voiced state to see the local pressure field around the strongest next moves.</div>`;
    return { currentAnchorCount: 0, cellCount: 0, warningCellCount: 0, positivePressureCount: 0, negativePressureCount: 0, hoveredCandidateIndex: -1, focusedCandidateIndex: -1 };
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
    focusedCandidateIndex: chosenIndex,
  };
}

function renderParallelRiskRadar(host, currentAnalysis, suggestions, focusedIndex) {
  if (!host) {
    return { axisCount: 0, populatedAxisCount: 0, currentPolygonCount: 0, candidatePolygonCount: 0, warningAxisCount: 0, hoveredCandidateIndex: -1, focusedCandidateIndex: -1 };
  }
  if (!currentAnalysis || !currentAnalysis.motion || suggestions.length === 0) {
    host.innerHTML = `<div class="output-block">Risk axes appear once there is enough voice motion to compare the current slice against likely next moves.</div>`;
    return { axisCount: 0, populatedAxisCount: 0, currentPolygonCount: 0, candidatePolygonCount: 0, warningAxisCount: 0, hoveredCandidateIndex: -1, focusedCandidateIndex: -1 };
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
    focusedCandidateIndex: chosenIndex,
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
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: 0, focusedCandidateIndex: -1 };
  }
  if (!currentState || !Array.isArray(suggestions) || suggestions.length === 0 || orbifoldTriadNodes.length === 0) {
    host.innerHTML = `<div class="output-block">Orbifold ribbon appears once the live sonority and at least one next-step candidate map to triadic harmonic anchors.</div>`;
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: 0, focusedCandidateIndex: -1 };
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
    return { currentAnchorCount: 0, candidateAnchorCount: 0, highlightedCandidateCount: 0, supportedCandidateCount: 0, edgeCount: orbifoldTriadEdges.length, focusedCandidateIndex: -1 };
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
    focusedCandidateIndex: chosen.index,
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

function suggestionSignature(suggestion) {
  if (!suggestion) return "";
  const notes = Array.isArray(suggestion.notes) ? suggestion.notes.join(",") : "";
  return `${suggestion.setValue || 0}|${notes}|${suggestion.cadenceEffect || 0}|${suggestion.score || 0}`;
}

function clearPinnedMidiSuggestion() {
  midiState.pinnedSuggestionIndex = null;
  midiState.pinnedSuggestionSignature = "";
}

function resolveFocusedMidiSuggestionIndex(suggestions) {
  if (!Array.isArray(suggestions) || suggestions.length === 0) {
    midiState.hoveredSuggestionIndex = null;
    clearPinnedMidiSuggestion();
    return { hoveredSuggestionIndex: null, pinnedSuggestionIndex: null, focusedSuggestionIndex: null };
  }

  if (midiState.hoveredSuggestionIndex == null || midiState.hoveredSuggestionIndex < 0 || midiState.hoveredSuggestionIndex >= suggestions.length) {
    midiState.hoveredSuggestionIndex = 0;
  }

  let pinnedSuggestionIndex = null;
  if (midiState.pinnedSuggestionIndex != null) {
    const pinnedCandidate = suggestions[midiState.pinnedSuggestionIndex] || null;
    if (pinnedCandidate && suggestionSignature(pinnedCandidate) === midiState.pinnedSuggestionSignature) {
      pinnedSuggestionIndex = midiState.pinnedSuggestionIndex;
    } else {
      clearPinnedMidiSuggestion();
    }
  }

  const hoveredSuggestionIndex = clamp(midiState.hoveredSuggestionIndex ?? 0, 0, suggestions.length - 1);
  const focusedSuggestionIndex = pinnedSuggestionIndex ?? hoveredSuggestionIndex;
  return { hoveredSuggestionIndex, pinnedSuggestionIndex, focusedSuggestionIndex };
}

function describeCounterpointSuggestion(suggestion, profileLabel) {
  if (!suggestion) return "Select or pin a ranked next move to see why it fits the current counterpoint state.";
  const motion = suggestion.motion || {};
  const reasons = suggestion.reasonNames || [];
  const warnings = suggestion.warningNames || [];
  const parts = [];

  if (reasons.includes("minimal-motion")) parts.push("keeps the texture close to the current voicing");
  if (reasons.includes("contrary-motion")) parts.push("uses contrary motion to open space between voices");
  if (reasons.includes("common-tone-retention") || (motion.commonToneCount || 0) > 0) {
    parts.push(`retains ${motion.commonToneCount || 0} common tone${(motion.commonToneCount || 0) === 1 ? "" : "s"}`);
  }
  if (reasons.includes("cadence-pull")) parts.push(`strengthens a ${suggestion.cadenceLabel} reading`);
  if (reasons.includes("preserves-spacing")) parts.push("keeps the spacing compact");
  if (reasons.includes("releases-tension")) parts.push("releases local pressure");
  if (reasons.includes("builds-tension")) parts.push("builds local pressure");
  if (reasons.includes("leap-compensation")) parts.push("balances a prior leap with a steadier response");

  let warningText = "";
  if (warnings.length > 0) {
    warningText = ` Watch for ${warnings.map(shortWarningLabel).join(", ")} under ${humanizeCounterpointLabel(profileLabel)}.`;
  } else {
    warningText = ` This reads cleanly under ${humanizeCounterpointLabel(profileLabel)}.`;
  }

  const base = parts.length > 0
    ? `${humanizeCounterpointLabel(profileLabel)} favors this move because it ${parts.join(", ")}.`
    : `${humanizeCounterpointLabel(profileLabel)} treats this as a neutral continuation.`;
  return `${base}${warningText}`;
}

function renderMidiCounterpointInspector(host, suggestion, context, profileLabel, options = {}) {
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

  if (!suggestion) {
    host.innerHTML = `<div class="output-block">Play or recall a voiced state to inspect the strongest next move here.</div>`;
    return {
      reasonCount: 0,
      warningCount: 0,
      motionBadgeCount: 0,
      candidateNoteCount: 0,
      pinned: false,
      narrativeReady: false,
    };
  }

  const motion = suggestion.motion || {};
  const badges = [
    `${suggestion.noteCount || 0} voices`,
    `${motion.commonToneCount || 0} common tones`,
    `${motion.stepCount || 0} steps`,
    `${motion.leapCount || 0} leaps`,
  ];
  if ((motion.contraryCount || 0) > 0) badges.push(`${motion.contraryCount} contrary`);
  if ((motion.parallelCount || 0) > 0) badges.push(`${motion.parallelCount} parallel`);
  if ((motion.obliqueCount || 0) > 0) badges.push(`${motion.obliqueCount} oblique`);
  if ((motion.crossingCount || 0) > 0) badges.push(`${motion.crossingCount} crossing`);

  const narrative = describeCounterpointSuggestion(suggestion, profileLabel);
  const titlePrefix = options.focusedIndex != null ? `${String.fromCharCode(65 + options.focusedIndex)}.` : "Focused";
  const pinLabel = options.pinned ? "Pinned" : "Hover preview";

  host.innerHTML = `
    <div class="inspector-shell">
      <div class="inspector-head">
        <div>
          <p class="eyebrow">${escapeHtml(pinLabel)}</p>
          <h4>${escapeHtml(titlePrefix)} ${escapeHtml(suggestion.noteNames.join(" · "))}</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill ${options.pinned ? "is-snapshot" : "is-live"}">${escapeHtml(pinLabel)}</span>
          <span class="status-pill is-live">${escapeHtml(suggestion.cadenceLabel)}</span>
        </div>
      </div>
      <p class="inspector-narrative">${escapeHtml(narrative)}</p>
      <div class="chip-row inspector-chip-row">
        ${suggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}
      </div>
      <div class="chip-row inspector-chip-row">
        ${suggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
      </div>
      <div class="inspector-metric-grid">
        <article class="inspector-metric"><strong>${escapeHtml(String(suggestion.score))}</strong><span>score</span></article>
        <article class="inspector-metric"><strong>${escapeHtml(suggestion.tensionDelta >= 0 ? `+${suggestion.tensionDelta}` : String(suggestion.tensionDelta))}</strong><span>tension</span></article>
        <article class="inspector-metric"><strong>${escapeHtml(String(motion.totalMotion || 0))}</strong><span>total motion</span></article>
        <article class="inspector-metric"><strong>${escapeHtml(String(motion.commonToneCount || 0))}</strong><span>retained</span></article>
      </div>
      <div class="chip-row inspector-chip-row">
        ${badges.map((badge) => `<span class="pill">${escapeHtml(badge)}</span>`).join("")}
      </div>
    </div>
  `;

  return {
    reasonCount: suggestion.reasonNames.length,
    warningCount: suggestion.warningNames.length,
    motionBadgeCount: badges.length,
    candidateNoteCount: suggestion.noteCount || suggestion.notes.length,
    pinned: !!options.pinned,
    narrativeReady: narrative.length > 0,
  };
}

function countSuggestionsWithTag(suggestions, kind, tag) {
  if (!Array.isArray(suggestions) || suggestions.length === 0) return 0;
  return suggestions.reduce((sum, suggestion) => {
    const values = kind === "warning" ? (suggestion.warningNames || []) : (suggestion.reasonNames || []);
    return sum + (values.includes(tag) ? 1 : 0);
  }, 0);
}

function noteSignature(suggestion) {
  return Array.isArray(suggestion?.notes) ? suggestion.notes.join(",") : "";
}

function summarizeActiveHazards(suggestions, currentMotionAnalysis) {
  const hazardNames = ["parallels", "crossing", "overlap", "wide-spacing", "consecutive-leap", "outside-context", "cluster-pressure"];
  const counts = hazardNames.map((name) => ({
    name,
    count: countSuggestionsWithTag(suggestions, "warning", name) + ((currentMotionAnalysis?.warningNames || []).includes(name) ? 1 : 0),
  })).filter((entry) => entry.count > 0);
  counts.sort((left, right) => right.count - left.count || left.name.localeCompare(right.name));
  return counts.slice(0, 3);
}

function topCadenceDestination(destinations) {
  if (!Array.isArray(destinations) || destinations.length === 0) return null;
  return destinations[0] || null;
}

function obligationSupportRatio(count, total) {
  if (!total || total <= 0) return 0;
  return clamp(count / total, 0, 1);
}

function buildObligationLedgerEntries(currentState, currentMotionAnalysis, cadenceDestinations, suspensionMachine, suggestions, focusedSuggestion) {
  const topSuggestions = Array.isArray(suggestions) ? suggestions.slice(0, 5) : [];
  const suggestionCount = Math.max(1, topSuggestions.length);
  const focusedWarnings = focusedSuggestion?.warningNames || [];
  const focusedReasons = focusedSuggestion?.reasonNames || [];
  const entries = [];

  if (suspensionMachine && ((suspensionMachine.obligationCount || 0) > 0 || (suspensionMachine.warningCount || 0) > 0 || (suspensionMachine.stateLabel && suspensionMachine.stateLabel !== "none" && suspensionMachine.stateLabel !== "resolved"))) {
    const obligationText = suspensionMachine.obligationCount > 0 && suspensionMachine.expectedResolutionLabel
      ? `resolve ${suspensionMachine.heldNoteLabel || "held tone"} ${suspensionMachine.resolutionDirection < 0 ? "down" : suspensionMachine.resolutionDirection > 0 ? "up" : "by step"} to ${suspensionMachine.expectedResolutionLabel}`
      : "stabilize the held dissonance before adding more pressure";
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      const resolves = suspensionMachine.expectedResolutionMidi <= 127 && focusedSuggestion.notes.includes(suspensionMachine.expectedResolutionMidi);
      const aggravates = focusedWarnings.includes("consecutive-leap") || focusedWarnings.includes("cluster-pressure");
      if (resolves) {
        status = "resolves";
        verdict = `Focused move lands on ${suspensionMachine.expectedResolutionLabel}, so it actively resolves the held tension.`;
      } else if (focusedReasons.includes("releases-tension")) {
        status = "supports";
        verdict = "Focused move lowers local pressure, but it leaves the explicit suspension obligation open.";
      } else if (aggravates) {
        status = "aggravates";
        verdict = "Focused move adds extra instability before the suspension fully settles.";
      } else {
        status = "delays";
        verdict = "Focused move keeps the suspension alive without resolving it yet.";
      }
    }
    entries.push({
      key: "suspension",
      label: "Resolve held tension",
      tone: (suspensionMachine.warningCount || 0) > 0 ? "critical" : "caution",
      supportCount: Math.max(1, suspensionMachine.obligationCount || 0),
      supportRatio: obligationSupportRatio(Math.max(1, suspensionMachine.obligationCount || 0), suggestionCount),
      sourceLabel: humanizeCounterpointLabel(suspensionMachine.stateLabel || "suspension"),
      pressureText: obligationText,
      verdict,
      status,
      tags: ["suspension", suspensionMachine.expectedResolutionLabel ? `to ${suspensionMachine.expectedResolutionLabel}` : "hold-aware"],
      expectedResolutionMidi: suspensionMachine.expectedResolutionMidi,
    });
  }

  const destination = topCadenceDestination(cadenceDestinations);
  if (destination && ((destination.score || 0) > 0 || (destination.candidateCount || 0) > 0 || (currentState?.cadenceState || 0) > 0)) {
    const desiredDestination = destination.destination;
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      const focusedDestination = cadenceDestinationFromCadenceEffect(focusedSuggestion.cadenceEffect);
      if (focusedDestination === desiredDestination) {
        status = "supports";
        verdict = `Focused move reinforces the strongest cadence pull toward ${humanizeCounterpointLabel(destination.label)}.`;
      } else if (focusedReasons.includes("cadence-pull")) {
        status = "delays";
        verdict = `Focused move still leans cadentially, but it redirects away from the strongest ${humanizeCounterpointLabel(destination.label)} path.`;
      } else if (focusedWarnings.includes("outside-context")) {
        status = "aggravates";
        verdict = "Focused move breaks away from the current cadence gravity instead of clarifying it.";
      } else {
        verdict = "Focused move neither clearly strengthens nor clearly contradicts the current cadence pull.";
      }
    }
    entries.push({
      key: "cadence-vector",
      label: "Honor cadence gravity",
      tone: destination.warningCount > 0 ? "caution" : "opportunity",
      supportCount: Math.max(1, destination.candidateCount || 0),
      supportRatio: obligationSupportRatio(Math.max(1, destination.candidateCount || 0), suggestionCount),
      sourceLabel: humanizeCounterpointLabel(destination.label),
      pressureText: `top destination ${humanizeCounterpointLabel(destination.label)} · score ${destination.score} · ${destination.candidateCount} of the sampled paths already point there`,
      verdict,
      status,
      tags: [destination.currentMatch ? "already active" : "available", `tension ${destination.tensionBias >= 0 ? `+${destination.tensionBias}` : String(destination.tensionBias)}`],
      targetCadenceLabel: destination.label,
    });
  }

  const preserveSpacingCount = countSuggestionsWithTag(topSuggestions, "reason", "preserves-spacing");
  const wideSpacingCount = countSuggestionsWithTag(topSuggestions, "warning", "wide-spacing");
  if (preserveSpacingCount > 0 || wideSpacingCount > 0 || (currentMotionAnalysis?.warningNames || []).includes("wide-spacing")) {
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      if (focusedReasons.includes("preserves-spacing")) {
        status = "supports";
        verdict = "Focused move keeps the voicing compact enough to preserve the current spacing shape.";
      } else if (focusedWarnings.includes("wide-spacing")) {
        status = "aggravates";
        verdict = "Focused move stretches the spacing and makes the registral frame harder to control.";
      } else {
        status = "delays";
        verdict = "Focused move is usable, but it does not directly reinforce the compact spacing favored by the field.";
      }
    }
    entries.push({
      key: "spacing",
      label: "Keep the spacing coherent",
      tone: wideSpacingCount > 0 ? "caution" : "opportunity",
      supportCount: Math.max(preserveSpacingCount, wideSpacingCount, 1),
      supportRatio: obligationSupportRatio(Math.max(preserveSpacingCount, wideSpacingCount, 1), suggestionCount),
      sourceLabel: preserveSpacingCount >= wideSpacingCount ? "compact field" : "wide-span risk",
      pressureText: `${preserveSpacingCount}/${suggestionCount} sampled moves preserve spacing; ${wideSpacingCount}/${suggestionCount} trigger width strain`,
      verdict,
      status,
      tags: ["spacing", preserveSpacingCount >= wideSpacingCount ? "compact favored" : "watch register"],
    });
  }

  const releaseCount = countSuggestionsWithTag(topSuggestions, "reason", "releases-tension");
  const buildCount = countSuggestionsWithTag(topSuggestions, "reason", "builds-tension");
  if (releaseCount > 0 || buildCount > 0 || (suspensionMachine && Math.abs((suspensionMachine.currentTension || 0) - (suspensionMachine.previousTension || 0)) > 0)) {
    const releasePreferred = releaseCount >= buildCount;
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      if (releasePreferred && focusedReasons.includes("releases-tension")) {
        status = "supports";
        verdict = "Focused move follows the field’s bias toward easing the current local pressure.";
      } else if (!releasePreferred && focusedReasons.includes("builds-tension")) {
        status = "supports";
        verdict = "Focused move intentionally intensifies the line in the same direction the field is already leaning.";
      } else if (releasePreferred && focusedReasons.includes("builds-tension")) {
        status = "aggravates";
        verdict = "Focused move adds more pressure when most nearby paths are trying to settle.";
      } else if (!releasePreferred && focusedReasons.includes("releases-tension")) {
        status = "delays";
        verdict = "Focused move cools the texture instead of following the field’s stronger intensifying pull.";
      } else {
        verdict = "Focused move does not strongly reshape the current pressure field either way.";
      }
    }
    entries.push({
      key: "tension",
      label: releasePreferred ? "Let pressure settle" : "Lean into the tension",
      tone: "opportunity",
      supportCount: Math.max(releaseCount, buildCount, 1),
      supportRatio: obligationSupportRatio(Math.max(releaseCount, buildCount, 1), suggestionCount),
      sourceLabel: releasePreferred ? "release bias" : "build bias",
      pressureText: `${releaseCount}/${suggestionCount} sampled moves release tension; ${buildCount}/${suggestionCount} build it`,
      verdict,
      status,
      tags: [releasePreferred ? "release" : "build", suspensionMachine ? `tension ${suspensionMachine.previousTension || 0}→${suspensionMachine.currentTension || 0}` : "field summary"],
      releasePreferred,
    });
  }

  const retentionCount = countSuggestionsWithTag(topSuggestions, "reason", "common-tone-retention");
  const currentRetained = currentMotionAnalysis?.motion?.commonToneCount || 0;
  if (retentionCount > 0 || currentRetained > 0) {
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      if (focusedReasons.includes("common-tone-retention") || (focusedSuggestion.motion?.commonToneCount || 0) > 0) {
        status = "supports";
        verdict = `Focused move preserves ${focusedSuggestion.motion?.commonToneCount || 0} common tone${(focusedSuggestion.motion?.commonToneCount || 0) === 1 ? "" : "s"}, keeping the texture anchored.`;
      } else if (focusedWarnings.includes("crossing") || focusedWarnings.includes("overlap")) {
        status = "aggravates";
        verdict = "Focused move trades away too much anchor and adds voice entanglement at the same time.";
      } else {
        status = "delays";
        verdict = "Focused move changes more material at once, so the common-tone anchor becomes weaker.";
      }
    }
    entries.push({
      key: "anchor",
      label: "Keep anchor tones audible",
      tone: "opportunity",
      supportCount: Math.max(retentionCount, currentRetained, 1),
      supportRatio: obligationSupportRatio(Math.max(retentionCount, currentRetained, 1), suggestionCount),
      sourceLabel: "common-tone anchor",
      pressureText: `${retentionCount}/${suggestionCount} sampled moves preserve anchor tones; current motion retained ${currentRetained}`,
      verdict,
      status,
      tags: ["common tones", currentRetained > 0 ? `${currentRetained} retained now` : "next-step anchor"],
    });
  }

  const activeHazards = summarizeActiveHazards(topSuggestions, currentMotionAnalysis);
  if (activeHazards.length > 0) {
    let status = "neutral";
    let verdict = "No focused move is selected yet.";
    if (focusedSuggestion) {
      if (focusedWarnings.length === 0) {
        status = "supports";
        verdict = "Focused move stays clear of the main hazards lighting up around this state.";
      } else if (focusedWarnings.some((warning) => activeHazards.some((hazard) => hazard.name === warning))) {
        status = "aggravates";
        verdict = `Focused move steps directly into ${focusedWarnings.filter((warning) => activeHazards.some((hazard) => hazard.name === warning)).map(shortWarningLabel).join(", ")}.`;
      } else {
        status = "delays";
        verdict = "Focused move avoids the worst traps but still carries secondary caution flags.";
      }
    }
    entries.push({
      key: "hazards",
      label: "Stay off the red rails",
      tone: "critical",
      supportCount: activeHazards[0]?.count || 1,
      supportRatio: obligationSupportRatio(activeHazards[0]?.count || 1, suggestionCount + 1),
      sourceLabel: activeHazards.map((hazard) => shortWarningLabel(hazard.name)).join(" · "),
      pressureText: `most active hazards across the current field: ${activeHazards.map((hazard) => `${shortWarningLabel(hazard.name)} (${hazard.count})`).join(", ")}`,
      verdict,
      status,
      tags: activeHazards.map((hazard) => shortWarningLabel(hazard.name)),
      hazardNames: activeHazards.map((hazard) => hazard.name),
    });
  }

  return entries.slice(0, 5);
}

function evaluateResolutionThreadStatus(entry, suggestion) {
  if (!entry || !suggestion) return "open";
  const reasons = suggestion.reasonNames || [];
  const warnings = suggestion.warningNames || [];
  switch (entry.key) {
    case "suspension":
      if (Number.isFinite(entry.expectedResolutionMidi) && suggestion.notes.includes(entry.expectedResolutionMidi)) return "resolves";
      if (reasons.includes("releases-tension")) return "supports";
      if (warnings.includes("cluster-pressure") || warnings.includes("consecutive-leap")) return "aggravates";
      return "open";
    case "cadence-vector":
      if (entry.targetCadenceLabel && suggestion.cadenceLabel === entry.targetCadenceLabel) return "supports";
      if (reasons.includes("cadence-pull")) return "supports";
      if (warnings.includes("outside-context")) return "aggravates";
      return "open";
    case "spacing":
      if (reasons.includes("preserves-spacing")) return "supports";
      if (warnings.includes("wide-spacing")) return "aggravates";
      return "open";
    case "tension":
      if (entry.releasePreferred) {
        if (reasons.includes("releases-tension") || suggestion.tensionDelta < 0) return "supports";
        if (reasons.includes("builds-tension") || suggestion.tensionDelta > 0) return "aggravates";
      } else {
        if (reasons.includes("builds-tension") || suggestion.tensionDelta > 0) return "supports";
        if (reasons.includes("releases-tension") || suggestion.tensionDelta < 0) return "delays";
      }
      return "open";
    case "anchor":
      if (reasons.includes("common-tone-retention") || (suggestion.motion?.commonToneCount || 0) > 0) return "supports";
      if (warnings.includes("crossing") || warnings.includes("overlap")) return "aggravates";
      return "open";
    case "hazards":
      if (warnings.some((warning) => (entry.hazardNames || []).includes(warning))) return "aggravates";
      if (warnings.length === 0) return "supports";
      return "open";
    default:
      return "open";
  }
}

function buildResolutionThreaderRows(entries, paths) {
  const visiblePaths = Array.isArray(paths) ? paths.slice(0, 3) : [];
  return (Array.isArray(entries) ? entries : []).map((entry) => {
    const threads = visiblePaths.map((path, visibleIndex) => {
      const stepStatuses = (path.steps || []).map((step, stepIndex) => ({
        status: evaluateResolutionThreadStatus(entry, step),
        step,
        stepIndex,
      }));
      const firstResolved = stepStatuses.find((item) => item.status === "resolves");
      const firstSupported = stepStatuses.find((item) => item.status === "supports");
      const firstAggravated = stepStatuses.find((item) => item.status === "aggravates");
      const chosen = firstResolved || firstSupported || firstAggravated || null;
      const status = chosen?.status || "open";
      const stepOffset = chosen ? chosen.stepIndex + 1 : Math.max(1, path.steps?.length || 1);
      const noteLabel = chosen?.step?.noteNames?.join(" · ") || path.terminalLabel || "";
      let summary = `stays open through +${stepOffset}`;
      if (status === "resolves") summary = `resolves by +${stepOffset}`;
      else if (status === "supports") summary = `supports by +${stepOffset}`;
      else if (status === "aggravates") summary = `aggravates by +${stepOffset}`;
      else if (status === "delays") summary = `delays through +${stepOffset}`;
      return {
        pathIndex: visibleIndex,
        status,
        stepOffset,
        noteLabel,
        summary,
      };
    });
    return { ...entry, threads };
  }).filter((entry) => entry.threads.length > 0);
}

function renderMidiObligationLedger(host, entries, focusedSuggestion, profileLabel) {
  const empty = {
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
  if (!host) return empty;
  if (!Array.isArray(entries) || entries.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">Once a voiced state is active, the ledger will summarize what this moment is asking for next and how the focused move responds.</div>`;
    return empty;
  }

  const focusedSignature = focusedSuggestion?.notes?.join(",") || "";
  const supportCount = entries.filter((entry) => entry.status === "supports" || entry.status === "resolves").length;
  const delayCount = entries.filter((entry) => entry.status === "delays").length;
  const aggravateCount = entries.filter((entry) => entry.status === "aggravates").length;
  host.dataset.focusedSignature = focusedSignature;

  host.innerHTML = `
    <div class="obligation-ledger-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Current duties and relief valves</p>
          <h4>${escapeHtml(humanizeCounterpointLabel(profileLabel))} obligation readout</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill is-live">${escapeHtml(`${supportCount} helping`)}</span>
          <span class="status-pill ${aggravateCount > 0 ? "is-snapshot" : "is-live"}">${escapeHtml(`${aggravateCount} aggravating`)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("The ledger turns the current state’s pressure into readable duties. Each row says why that duty exists now, then grades the focused or pinned move against it.")}</p>
        <div class="chip-row">
          <span class="pill">${escapeHtml("current state pressure comes from suspension, cadence, motion memory, and the top-ranked local field")}</span>
          <span class="pill">${escapeHtml("focused move verdict stays synchronized with hover and pin state")}</span>
        </div>
      </article>
      <div class="obligation-ledger-grid">
        ${entries.map((entry, index) => `
          <article class="obligation-ledger-card is-${entry.tone} is-${entry.status}" data-obligation-ledger-card="${index}" data-obligation-status="${entry.status}">
            <div class="obligation-ledger-card-head">
              <div>
                <p class="eyebrow">${escapeHtml(entry.sourceLabel)}</p>
                <h4>${escapeHtml(entry.label)}</h4>
              </div>
              <div class="pill-list">
                <span class="status-pill ${entry.tone === "critical" ? "is-snapshot" : entry.tone === "caution" ? "is-muted" : "is-live"}">${escapeHtml(humanizeCounterpointLabel(entry.tone))}</span>
                <span class="status-pill ${entry.status === "aggravates" ? "is-snapshot" : entry.status === "delays" ? "is-muted" : "is-live"}">${escapeHtml(humanizeCounterpointLabel(entry.status === "resolves" ? "resolves" : entry.status))}</span>
              </div>
            </div>
            <p class="obligation-ledger-pressure">${escapeHtml(entry.pressureText)}</p>
            <div class="obligation-ledger-meter" aria-hidden="true">
              <span style="width:${(entry.supportRatio * 100).toFixed(1)}%"></span>
            </div>
            <p class="obligation-ledger-verdict">${escapeHtml(entry.verdict)}</p>
            <div class="chip-row">
              ${entry.tags.map((tag) => `<span class="pill">${escapeHtml(tag)}</span>`).join("")}
            </div>
          </article>
        `).join("")}
      </div>
    </div>
  `;

  return {
    entryCount: entries.length,
    criticalEntryCount: entries.filter((entry) => entry.tone === "critical").length,
    focusedSupportCount: supportCount,
    focusedDelayCount: delayCount,
    focusedAggravateCount: aggravateCount,
    warningEntryCount: entries.filter((entry) => entry.tone === "critical" || entry.tone === "caution").length,
    focusedSignature,
    statusLabels: entries.map((entry) => entry.status),
    entryLabels: entries.map((entry) => entry.label),
  };
}

function renderMidiResolutionThreader(host, entries, focusedSuggestion, paths, profileLabel) {
  const empty = {
    rowCount: 0,
    threadCount: 0,
    resolvedThreadCount: 0,
    aggravateThreadCount: 0,
    openThreadCount: 0,
    focusedSignature: "",
    entryLabels: [],
  };
  if (!host) return empty;
  if (!focusedSuggestion || !Array.isArray(entries) || entries.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to see how the strongest short continuations actually settle, sustain, or worsen the current duties.</div>`;
    return empty;
  }

  const rows = buildResolutionThreaderRows(entries.slice(0, 4), paths);
  if (rows.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">The threader needs at least one focused move and one short continuation path to project the current obligations forward.</div>`;
    return empty;
  }

  const focusedSignature = focusedSuggestion.notes.join(",");
  host.dataset.focusedSignature = focusedSignature;
  const allThreads = rows.flatMap((row) => row.threads);
  const resolvedThreadCount = allThreads.filter((thread) => thread.status === "resolves" || thread.status === "supports").length;
  const aggravateThreadCount = allThreads.filter((thread) => thread.status === "aggravates").length;
  const openThreadCount = allThreads.filter((thread) => thread.status === "open" || thread.status === "delays").length;

  host.innerHTML = `
    <div class="resolution-threader-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">How the duties cash out</p>
          <h4>${escapeHtml(humanizeCounterpointLabel(profileLabel))} obligation threads</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill is-live">${escapeHtml(`${resolvedThreadCount} settling`)}</span>
          <span class="status-pill ${aggravateThreadCount > 0 ? "is-snapshot" : "is-muted"}">${escapeHtml(`${aggravateThreadCount} worsening`)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("The ledger tells us what this moment asks for. The threader follows the strongest short continuations after the focused move and shows when each duty actually settles, stays open, or turns rougher.")}</p>
        <div class="chip-row">
          <span class="pill">${escapeHtml("focused move verdict first")}</span>
          <span class="pill">${escapeHtml("short ranked continuations projected afterward")}</span>
        </div>
      </article>
      <div class="resolution-threader-grid">
        ${rows.map((entry, index) => `
          <article class="resolution-threader-card is-${entry.tone}" data-resolution-thread="${index}">
            <div class="resolution-threader-card-head">
              <div>
                <p class="eyebrow">${escapeHtml(entry.sourceLabel)}</p>
                <h4>${escapeHtml(entry.label)}</h4>
              </div>
              <div class="pill-list">
                <span class="status-pill ${entry.tone === "critical" ? "is-snapshot" : entry.tone === "caution" ? "is-muted" : "is-live"}">${escapeHtml(humanizeCounterpointLabel(entry.tone))}</span>
                <span class="status-pill ${entry.status === "aggravates" ? "is-snapshot" : entry.status === "delays" ? "is-muted" : "is-live"}">${escapeHtml(humanizeCounterpointLabel(entry.status === "resolves" ? "resolves" : entry.status))}</span>
              </div>
            </div>
            <p class="resolution-threader-meta">${escapeHtml(entry.pressureText)}</p>
            <div class="resolution-threader-flow">
              <article class="resolution-threader-node is-${entry.status}" data-resolution-thread-status="${entry.status}">
                <p class="eyebrow">Focused move</p>
                <strong>${escapeHtml(entry.status === "resolves" ? "resolves now" : entry.status === "supports" ? "supports now" : entry.status === "aggravates" ? "aggravates now" : entry.status === "delays" ? "delays now" : "stays open now")}</strong>
                <p>${escapeHtml(entry.verdict)}</p>
              </article>
              ${entry.threads.map((thread) => `
                <article class="resolution-threader-node is-${thread.status}" data-resolution-thread-status="${thread.status}" data-resolution-path="${thread.pathIndex}">
                  <p class="eyebrow">${escapeHtml(`Path ${thread.pathIndex + 1}`)}</p>
                  <strong>${escapeHtml(thread.summary)}</strong>
                  <p>${escapeHtml(thread.noteLabel || "no terminal label available")}</p>
                </article>
              `).join("")}
            </div>
          </article>
        `).join("")}
      </div>
    </div>
  `;

  return {
    rowCount: rows.length,
    threadCount: allThreads.length,
    resolvedThreadCount,
    aggravateThreadCount,
    openThreadCount,
    focusedSignature,
    entryLabels: rows.map((row) => row.label),
  };
}

function buildObligationTimelineColumns(arena, historyFrames, context, profile, currentEntries, focusedSuggestion) {
  const rows = Array.isArray(currentEntries) ? currentEntries.slice(0, 4) : [];
  if (rows.length === 0 || !focusedSuggestion) return [];

  const columns = [];
  const startIndex = Math.max(0, historyFrames.length - 4);
  for (let index = startIndex; index < historyFrames.length - 1; index += 1) {
    const prefixFrames = historyFrames.slice(0, index + 1).map(cloneHistoryFrame);
    if (prefixFrames.length === 0) continue;
    const historyBundle = buildCounterpointHistory(arena, prefixFrames, context);
    const voicedHistory = decodeVoicedHistoryFromPointer(historyBundle.historyPtr);
    const currentState = voicedHistory.states[voicedHistory.states.length - 1] || null;
    const currentMotionAnalysis = buildCurrentMotionAnalysis(arena, historyBundle, voicedHistory, profile);
    const cadenceDestinations = decodeCadenceDestinations(arena, historyBundle.historyPtr, profile);
    const suspensionMachine = decodeSuspensionMachine(arena, historyBundle.historyPtr, profile, context);
    const rankedSuggestions = decodeRankedNextSteps(arena, historyBundle.historyPtr, profile, context);
    const nextFrame = historyFrames[index + 1];
    const actual = buildActualSuggestionFromFrame(arena, historyBundle, nextFrame, context, profile, rankedSuggestions);
    const entries = buildObligationLedgerEntries(
      currentState,
      currentMotionAnalysis,
      cadenceDestinations,
      suspensionMachine,
      rankedSuggestions,
      actual.suggestion,
    );
    const beforeOffset = historyFrames.length - index - 1;
    const afterOffset = Math.max(0, beforeOffset - 1);
    columns.push({
      kind: "history",
      label: afterOffset === 0 ? `T-${beforeOffset} → Now` : `T-${beforeOffset} → T-${afterOffset}`,
      signature: noteSignature(actual.suggestion),
      matched: actual.matched,
      noteLabel: actual.suggestion?.noteNames?.join(" · ") || historyFrameDescription(nextFrame, context),
      entries,
    });
  }

  columns.push({
    kind: "focused",
    label: "Focused",
    signature: noteSignature(focusedSuggestion),
    matched: true,
    noteLabel: focusedSuggestion.noteNames?.join(" · ") || "",
    entries: rows,
  });
  return columns;
}

function buildObligationTimelineRows(currentEntries, columns) {
  const rows = Array.isArray(currentEntries) ? currentEntries.slice(0, 4) : [];
  return rows.map((entry) => {
    const cells = columns.map((column) => {
      const match = column.entries.find((one) => one.label === entry.label);
      if (!match) {
        return {
          status: "inactive",
          summary: column.kind === "focused" ? "not active now" : "not active yet",
          noteLabel: column.kind === "focused" ? "focused move does not engage this duty" : "this duty had not formed at that step",
        };
      }
      const status = match.status === "neutral" ? "open" : (match.status || "open");
      return {
        status,
        summary: status === "resolves"
          ? "resolves it"
          : status === "supports"
            ? "supports it"
            : status === "aggravates"
              ? "feeds it"
              : status === "delays"
                ? "keeps it open"
                : "leaves it live",
        noteLabel: column.noteLabel || match.pressureText,
        verdict: match.verdict,
      };
    });
    return { ...entry, cells };
  });
}

function renderMidiObligationTimeline(host, arena, historyFrames, context, profile, currentEntries, focusedSuggestion, profileLabel) {
  const empty = {
    rowCount: 0,
    historyColumnCount: 0,
    focusedColumnCount: 0,
    actualMatchCount: 0,
    resolvedCellCount: 0,
    aggravateCellCount: 0,
    inactiveCellCount: 0,
    focusedSignature: "",
    rowLabels: [],
  };
  if (!host) return empty;
  if (!focusedSuggestion || !Array.isArray(currentEntries) || currentEntries.length === 0 || !Array.isArray(historyFrames) || historyFrames.length < 2) {
    host.innerHTML = `<div class="output-block continuation-empty">Play at least two voiced changes, then focus or pin a move to see how the current duties grew out of the recent line and how the focused move would answer them now.</div>`;
    return empty;
  }

  const columns = buildObligationTimelineColumns(arena, historyFrames, context, profile, currentEntries, focusedSuggestion);
  const historyColumns = columns.filter((column) => column.kind === "history");
  const rows = buildObligationTimelineRows(currentEntries, columns);
  if (rows.length === 0 || historyColumns.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">The timeline needs current duties plus at least one recent actual move to replay how those duties emerged.</div>`;
    return empty;
  }

  const focusedSignature = noteSignature(focusedSuggestion);
  host.dataset.focusedSignature = focusedSignature;
  host.dataset.historyColumnCount = String(historyColumns.length);
  host.dataset.actualMatchCount = String(historyColumns.filter((column) => column.matched).length);
  const allCells = rows.flatMap((row) => row.cells);
  const resolvedCellCount = allCells.filter((cell) => cell.status === "resolves" || cell.status === "supports").length;
  const aggravateCellCount = allCells.filter((cell) => cell.status === "aggravates").length;
  const inactiveCellCount = allCells.filter((cell) => cell.status === "inactive").length;
  const gridColumns = `minmax(210px, 1.05fr) repeat(${columns.length}, minmax(150px, 1fr))`;

  host.innerHTML = `
    <div class="obligation-timeline-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">How the duties got here</p>
          <h4>${escapeHtml(humanizeCounterpointLabel(profileLabel))} obligation memory</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill is-live">${escapeHtml(`${historyColumns.length} recent moves`)}</span>
          <span class="status-pill ${aggravateCellCount > 0 ? "is-snapshot" : "is-muted"}">${escapeHtml(`${resolvedCellCount} settling cells`)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("Each row is a duty that exists now. The history columns replay how the actual recent moves treated that duty, and the focused column shows what the active next move would do with it from here.")}</p>
        <div class="obligation-timeline-chip-row">
          <span class="pill">${escapeHtml("history columns use actual recent moves")}</span>
          <span class="pill">${escapeHtml("focused column stays synchronized with hover and pin state")}</span>
        </div>
      </article>
      <div class="obligation-timeline-grid" style="grid-template-columns:${gridColumns}">
        <article class="obligation-timeline-corner">
          <p class="eyebrow">Current duties</p>
          <strong>Read the rows first</strong>
          <p>We keep the present duty set stable, then replay how the recent line handled those same obligations.</p>
        </article>
        ${columns.map((column) => `
          <article class="obligation-timeline-column${column.kind === "focused" ? " is-focused" : ""}" data-obligation-timeline-column="${column.kind}">
            <p class="eyebrow">${escapeHtml(column.kind === "focused" ? "Active next move" : "Recent actual move")}</p>
            <strong>${escapeHtml(column.label)}</strong>
            <p>${escapeHtml(column.noteLabel || "no move label available")}</p>
          </article>
        `).join("")}
        ${rows.map((row, rowIndex) => `
          <article class="obligation-timeline-row-label" data-obligation-timeline-row="${rowIndex}">
            <p class="eyebrow">${escapeHtml(row.sourceLabel)}</p>
            <strong>${escapeHtml(row.label)}</strong>
            <p>${escapeHtml(row.pressureText)}</p>
          </article>
          ${row.cells.map((cell, cellIndex) => `
            <article class="obligation-timeline-cell is-${cell.status}" data-obligation-timeline-status="${cell.status}" data-obligation-timeline-cell="${rowIndex}:${cellIndex}">
              <p class="eyebrow">${escapeHtml(cell.summary)}</p>
              <strong>${escapeHtml(cell.noteLabel || "no move label available")}</strong>
              <p>${escapeHtml(cell.verdict || "This duty was not active at that step.")}</p>
            </article>
          `).join("")}
        `).join("")}
      </div>
    </div>
  `;

  return {
    rowCount: rows.length,
    historyColumnCount: historyColumns.length,
    focusedColumnCount: columns.filter((column) => column.kind === "focused").length,
    actualMatchCount: historyColumns.filter((column) => column.matched).length,
    resolvedCellCount,
    aggravateCellCount,
    inactiveCellCount,
    focusedSignature,
    rowLabels: rows.map((row) => row.label),
  };
}

function voiceRegisterRole(index, count) {
  if (count <= 1) return "solo";
  if (index === 0) return "top";
  if (index === count - 1) return "bass";
  if (index === 1) return "upper inner";
  if (index === count - 2) return "lower inner";
  return "inner";
}

function describeRecentVoiceMotion(previousVoice, currentVoice, context) {
  if (!currentVoice) return "voice unavailable";
  if (!previousVoice) return `enters on ${midiName(currentVoice.midi, context.tonic, context.quality)}`;
  const delta = currentVoice.midi - previousVoice.midi;
  if (delta === 0) return `holds ${midiName(currentVoice.midi, context.tonic, context.quality)}`;
  const direction = delta > 0 ? "up" : "down";
  const absDelta = Math.abs(delta);
  if (absDelta <= 2) return `steps ${direction} from ${midiName(previousVoice.midi, context.tonic, context.quality)}`;
  if (absDelta <= 4) return `skips ${direction} from ${midiName(previousVoice.midi, context.tonic, context.quality)}`;
  return `leaps ${direction} from ${midiName(previousVoice.midi, context.tonic, context.quality)}`;
}

function voiceDutyCueDeltaLabel(delta) {
  if (!Number.isFinite(delta) || delta === 0) return "hold";
  const direction = delta > 0 ? "up" : "down";
  const absDelta = Math.abs(delta);
  if (absDelta === 1) return `step ${direction}`;
  if (absDelta === 2) return `whole step ${direction}`;
  return `${absDelta}-semitone ${direction}`;
}

function deriveVoiceDuty(currentVoice, previousVoice, focusedVoice, context, suspensionMachine) {
  const currentLabel = midiName(currentVoice.midi, context.tonic, context.quality);
  const focusedLabel = focusedVoice ? midiName(focusedVoice.midi, context.tonic, context.quality) : "missing in focused move";
  const previousDelta = previousVoice ? currentVoice.midi - previousVoice.midi : 0;
  const leadingTonePc = ((context.tonic + 11) % 12 + 12) % 12;

  let dutyType = "smooth";
  let dutyLabel = "Keep the motion compact";
  let cueLabel = previousVoice ? describeRecentVoiceMotion(previousVoice, currentVoice, context) : "new entry";
  let targetMidi = null;

  if (suspensionMachine && suspensionMachine.trackedVoiceId === currentVoice.id && suspensionMachine.expectedResolutionMidi <= 127) {
    dutyType = "suspension";
    targetMidi = suspensionMachine.expectedResolutionMidi;
    dutyLabel = `Resolve suspension to ${midiName(targetMidi, context.tonic, context.quality)}`;
    cueLabel = `${suspensionMachine.heldNoteLabel || currentLabel} held above the line`;
  } else if (currentVoice.pitchClass === leadingTonePc) {
    dutyType = "leading-tone";
    targetMidi = currentVoice.midi + 1;
    dutyLabel = `Lift the leading tone to ${midiName(targetMidi, context.tonic, context.quality)}`;
    cueLabel = `cadence gravity toward ${spellNote(context.tonic, context.tonic, context.quality)}`;
  } else if (previousVoice && Math.abs(previousDelta) >= 5) {
    dutyType = "leap-recovery";
    targetMidi = currentVoice.midi + (previousDelta > 0 ? -1 : 1);
    dutyLabel = `Recover the leap by ${voiceDutyCueDeltaLabel(targetMidi - currentVoice.midi)}`;
    cueLabel = describeRecentVoiceMotion(previousVoice, currentVoice, context);
  } else if (previousVoice && previousVoice.midi === currentVoice.midi) {
    dutyType = "anchor";
    targetMidi = currentVoice.midi;
    dutyLabel = `Keep ${currentLabel} audible as an anchor`;
    cueLabel = "common tone held across the line";
  } else if (!previousVoice) {
    dutyType = "entry";
    dutyLabel = `Place ${currentLabel} cleanly into the texture`;
    cueLabel = "newly entered voice";
  }

  let status = "delays";
  let outcomeLabel = focusedLabel;
  let verdict = "Focused move not available for this voice.";
  if (focusedVoice) {
    const focusedDelta = focusedVoice.midi - currentVoice.midi;
    const targetDelta = targetMidi == null ? 0 : targetMidi - currentVoice.midi;
    if (dutyType === "suspension" || dutyType === "leading-tone" || dutyType === "leap-recovery") {
      if (targetMidi != null && focusedVoice.midi === targetMidi) {
        status = "resolves";
        verdict = `Focused move lands exactly on ${midiName(targetMidi, context.tonic, context.quality)}.`;
      } else if (focusedDelta !== 0 && Math.sign(focusedDelta) === Math.sign(targetDelta) && Math.abs(focusedDelta) <= Math.max(2, Math.abs(targetDelta))) {
        status = "supports";
        verdict = `Focused move heads ${voiceDutyCueDeltaLabel(focusedDelta)} toward the expected resolution without finishing it yet.`;
      } else if (focusedDelta === 0) {
        status = "delays";
        verdict = "Focused move keeps the pressure in place instead of resolving it.";
      } else {
        status = "aggravates";
        verdict = `Focused move heads away from the needed ${voiceDutyCueDeltaLabel(targetDelta)} release.`;
      }
    } else if (dutyType === "anchor") {
      if (focusedVoice.midi === currentVoice.midi) {
        status = "supports";
        verdict = "Focused move keeps the anchor tone steady.";
      } else if (Math.abs(focusedDelta) <= 2) {
        status = "delays";
        verdict = "Focused move releases the anchor gently, but the held support disappears.";
      } else {
        status = "aggravates";
        verdict = "Focused move throws away the anchor with a larger displacement.";
      }
    } else {
      if (Math.abs(focusedDelta) <= 2) {
        status = "supports";
        verdict = "Focused move keeps this voice compact and readable.";
      } else if (Math.abs(focusedDelta) >= 5) {
        status = "aggravates";
        verdict = "Focused move asks this voice for another large displacement.";
      } else {
        status = "delays";
        verdict = "Focused move is workable, but it is less compact than the line currently suggests.";
      }
    }
  }

  return {
    voiceId: currentVoice.id,
    currentMidi: currentVoice.midi,
    currentLabel,
    focusedLabel,
    recentMotionLabel: describeRecentVoiceMotion(previousVoice, currentVoice, context),
    dutyType,
    dutyLabel,
    cueLabel,
    targetMidi,
    targetLabel: targetMidi == null ? "" : midiName(targetMidi, context.tonic, context.quality),
    status,
    verdict,
  };
}

function buildVoiceDutyRows(currentState, previousState, focusedCandidateState, context, suspensionMachine) {
  if (!currentState || !Array.isArray(currentState.voices) || currentState.voices.length === 0) return [];
  const previousById = new Map((previousState?.voices || []).map((voice) => [voice.id, voice]));
  const focusedById = new Map((focusedCandidateState?.voices || []).map((voice) => [voice.id, voice]));
  const orderedVoices = currentState.voices.slice().sort((left, right) => right.midi - left.midi);

  return orderedVoices.map((voice, index) => {
    const previousVoice = previousById.get(voice.id) || null;
    const focusedVoice = focusedById.get(voice.id) || null;
    return {
      ...deriveVoiceDuty(voice, previousVoice, focusedVoice, context, suspensionMachine),
      voiceLabel: `V${voice.id} · ${voiceRegisterRole(index, orderedVoices.length)}`,
      voiceColor: voiceColor(voice.id),
      currentRoleIndex: index,
    };
  });
}

function renderMidiVoiceDuties(host, currentState, previousState, focusedCandidateState, context, suspensionMachine, focusedSuggestion) {
  const empty = {
    rowCount: 0,
    activeDutyCount: 0,
    resolveCount: 0,
    aggravateCount: 0,
    suspensionVoiceCount: 0,
    leadingToneVoiceCount: 0,
    leapRecoveryCount: 0,
    currentNoteCount: 0,
    focusedNoteCount: 0,
    focusedSignature: "",
    rowLabels: [],
  };
  if (!host) return empty;
  if (!currentState || !focusedSuggestion) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to see which exact voices are carrying today’s duties and how that move treats each one.</div>`;
    return empty;
  }

  const rows = buildVoiceDutyRows(currentState, previousState, focusedCandidateState, context, suspensionMachine);
  if (rows.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">Voice duties need a current voiced state plus a focused candidate state to compare voice-by-voice outcomes.</div>`;
    return empty;
  }

  const activeDutyCount = rows.filter((row) => row.dutyType !== "smooth" && row.dutyType !== "entry").length;
  const resolveCount = rows.filter((row) => row.status === "resolves" || row.status === "supports").length;
  const aggravateCount = rows.filter((row) => row.status === "aggravates").length;
  const focusedSignature = noteSignature(focusedSuggestion);
  host.dataset.focusedSignature = focusedSignature;
  host.dataset.activeDutyCount = String(activeDutyCount);
  host.dataset.suspensionVoiceCount = String(rows.filter((row) => row.dutyType === "suspension").length);
  host.dataset.leadingToneVoiceCount = String(rows.filter((row) => row.dutyType === "leading-tone").length);
  host.dataset.leapRecoveryCount = String(rows.filter((row) => row.dutyType === "leap-recovery").length);

  host.innerHTML = `
    <div class="voice-duties-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Who is carrying the pressure</p>
          <h4>Persistent voice duties</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill is-live">${escapeHtml(`${resolveCount} helping`)}</span>
          <span class="status-pill ${aggravateCount > 0 ? "is-snapshot" : "is-muted"}">${escapeHtml(`${aggravateCount} aggravating`)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("The ledger talks about the state. This panel shows which exact voices are carrying that pressure right now, using the persistent voice ids from temporal memory and the currently focused move.")}</p>
        <div class="chip-row">
          <span class="pill">${escapeHtml("rows stay matched by persistent voice id")}</span>
          <span class="pill">${escapeHtml("current note, present duty, and focused outcome stay synchronized together")}</span>
        </div>
      </article>
      <div class="voice-duties-grid">
        ${rows.map((row, index) => `
          <article class="voice-duty-card is-${row.status}" data-voice-duty-row="${index}" data-voice-duty-status="${row.status}" data-voice-duty-type="${row.dutyType}" data-voice-id="${row.voiceId}">
            <div class="voice-duty-card-head">
              <div class="voice-duty-title">
                <span class="voice-duty-swatch" style="background:${escapeHtml(row.voiceColor)}"></span>
                <div>
                  <p class="eyebrow">${escapeHtml(`voice ${row.voiceId}`)}</p>
                  <h4>${escapeHtml(row.voiceLabel)}</h4>
                </div>
              </div>
              <div class="pill-list">
                <span class="status-pill is-muted">${escapeHtml(humanizeCounterpointLabel(row.dutyType))}</span>
                <span class="status-pill ${row.status === "aggravates" ? "is-snapshot" : row.status === "delays" ? "is-muted" : "is-live"}">${escapeHtml(humanizeCounterpointLabel(row.status === "resolves" ? "resolves" : row.status))}</span>
              </div>
            </div>
            <div class="voice-duty-grid">
              <article class="voice-duty-cell">
                <p class="eyebrow">Recent motion</p>
                <strong class="voice-duties-current-note">${escapeHtml(row.currentLabel)}</strong>
                <p>${escapeHtml(row.recentMotionLabel)}</p>
              </article>
              <article class="voice-duty-cell">
                <p class="eyebrow">Present duty</p>
                <strong class="voice-duties-duty-label">${escapeHtml(row.dutyLabel)}</strong>
                <p>${escapeHtml(row.targetLabel ? `${row.cueLabel} · target ${row.targetLabel}` : row.cueLabel)}</p>
              </article>
              <article class="voice-duty-cell is-outcome">
                <p class="eyebrow">Focused move</p>
                <strong class="voice-duties-focused-note">${escapeHtml(row.focusedLabel)}</strong>
                <p>${escapeHtml(row.verdict)}</p>
              </article>
            </div>
          </article>
        `).join("")}
      </div>
    </div>
  `;

  return {
    rowCount: rows.length,
    activeDutyCount,
    resolveCount,
    aggravateCount,
    suspensionVoiceCount: rows.filter((row) => row.dutyType === "suspension").length,
    leadingToneVoiceCount: rows.filter((row) => row.dutyType === "leading-tone").length,
    leapRecoveryCount: rows.filter((row) => row.dutyType === "leap-recovery").length,
    currentNoteCount: rows.filter((row) => row.currentLabel.length > 0).length,
    focusedNoteCount: rows.filter((row) => row.focusedLabel.length > 0).length,
    focusedSignature,
    rowLabels: rows.map((row) => row.voiceLabel),
  };
}

function renderMidiContinuationLadder(host, arena, rootSuggestion, continuationSuggestions, context, options = {}) {
  const empty = {
    rootLabel: "",
    continuationCount: 0,
    continuationClockCount: 0,
    continuationMiniCount: 0,
    sourceFocusedIndex: -1,
    firstContinuationLabel: "",
  };
  if (!host) return empty;
  if (!rootSuggestion) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to see what libmusictheory thinks it naturally opens next.</div>`;
    return empty;
  }

  const visible = continuationSuggestions.slice(0, 3);
  const focusedLetter = options.sourceFocusedIndex != null && options.sourceFocusedIndex >= 0
    ? String.fromCharCode(65 + options.sourceFocusedIndex)
    : "Focused";
  const rootLabel = rootSuggestion.noteNames.join(" · ");
  const rootNarrative = `${focusedLetter} becomes the new present tense: libmusictheory re-ranks the next local continuations from that voiced state instead of guessing in JavaScript.`;

  host.innerHTML = `
    <div class="continuation-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">After the focused move</p>
          <h4>${escapeHtml(focusedLetter)}. ${escapeHtml(rootLabel)}</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill ${options.pinned ? "is-snapshot" : "is-live"}">${escapeHtml(options.pinned ? "Pinned source" : "Focused source")}</span>
          <span class="status-pill is-live">${escapeHtml(rootSuggestion.cadenceLabel)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml(rootNarrative)}</p>
        <div class="chip-row">
          ${rootSuggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">neutral continuation</span>`}
        </div>
        <div class="chip-row">
          ${rootSuggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
        </div>
      </article>
      <div class="continuation-grid">
        ${visible.length > 0
          ? visible.map((suggestion, index) => `
            <article class="continuation-card" data-continuation-index="${index}">
              <strong>${escapeHtml(focusedLetter)} -> ${index + 1}. ${escapeHtml(suggestion.noteNames.join(" · "))}</strong>
              <p>${escapeHtml(suggestion.chordLabel)}</p>
              <p>score ${escapeHtml(String(suggestion.score))} · cadence ${escapeHtml(suggestion.cadenceLabel)} · tension ${escapeHtml(suggestion.tensionDelta >= 0 ? `+${suggestion.tensionDelta}` : String(suggestion.tensionDelta))}</p>
              <div class="chip-row">${suggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}</div>
              <div class="chip-row">${suggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}</div>
              <div class="continuation-art-grid">
                <div class="continuation-art" data-continuation-clock="${index}"></div>
                <div class="continuation-art continuation-mini" data-continuation-mini="${index}"></div>
              </div>
            </article>
          `).join("")
          : `<div class="output-block continuation-empty">No stable second-step continuations yet for this source move.</div>`}
      </div>
    </div>
  `;

  let continuationClockCount = 0;
  let continuationMiniCount = 0;
  visible.forEach((suggestion, index) => {
    const clockHost = host.querySelector(`[data-continuation-clock="${index}"]`);
    if (clockHost) {
      renderPreviewSvgOrBitmap(clockHost, {
        svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, suggestion.setValue),
        bitmapRenderer: {
          renderRgba: (width, height) => clockBitmapRgba(arena, suggestion.setValue, width, height),
        },
        alt: `${suggestion.noteNames.join(" ")} continuation clock preview`,
        options: { maxHeight: 138, squareWidth: 150, mediumWidth: 160, wideWidth: 170, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
      });
      continuationClockCount += 1;
    }
    const miniHost = host.querySelector(`[data-continuation-mini="${index}"]`);
    if (miniHost) {
      const rendered = renderMiniInstrumentPreview(
        arena,
        miniHost,
        {
          midiNotes: suggestion.notes,
          setValue: suggestion.setValue,
          tonic: context.tonic,
          preferredBassPc: suggestion.notes.length > 0 ? Math.min(...suggestion.notes) % 12 : null,
          fretVoicing: suggestion.fretPreview,
        },
        `${suggestion.noteNames.join(" ")} continuation mini preview`,
        {
          maxHeight: 150,
          squareWidth: 170,
          mediumWidth: 180,
          wideWidth: 190,
          ultraWideWidth: 200,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
      if (rendered) continuationMiniCount += 1;
    }
  });

  return {
    rootLabel,
    continuationCount: visible.length,
    continuationClockCount,
    continuationMiniCount,
    sourceFocusedIndex: options.sourceFocusedIndex ?? -1,
    firstContinuationLabel: visible[0]?.noteNames?.join(" · ") || "",
  };
}

function buildContinuationPaths(arena, rootBundle, rootSuggestion, context, profile, options = {}) {
  if (!rootBundle || !rootSuggestion) return [];
  const branchCount = clamp(options.branchCount ?? 3, 1, 6);
  const maxDepth = clamp(options.maxDepth ?? 3, 1, 4);
  const firstLayer = Array.isArray(rootBundle.suggestions) ? rootBundle.suggestions.slice(0, branchCount) : [];
  return firstLayer.map((firstSuggestion, branchIndex) => {
    const steps = [firstSuggestion];
    let inputFrames = rootBundle.historyFrames.map(cloneHistoryFrame);
    let cursorSuggestion = firstSuggestion;
    for (let depthIndex = 1; depthIndex < maxDepth; depthIndex += 1) {
      const nextBundle = buildFocusedContinuationContext(arena, inputFrames, cursorSuggestion, context, profile);
      inputFrames = nextBundle.historyFrames.map(cloneHistoryFrame);
      const nextSuggestion = nextBundle.suggestions[0];
      if (!nextSuggestion) break;
      steps.push(nextSuggestion);
      cursorSuggestion = nextSuggestion;
    }
    const terminal = steps[steps.length - 1];
    return {
      branchIndex,
      steps,
      terminal,
      terminalLabel: terminal?.noteNames?.join(" · ") || "",
      totalScore: steps.reduce((sum, suggestion) => sum + (suggestion.score || 0), 0),
      cadenceTrail: [rootSuggestion.cadenceLabel, ...steps.map((suggestion) => suggestion.cadenceLabel)],
      reasonNames: Array.from(new Set(steps.flatMap((suggestion) => suggestion.reasonNames || []))).slice(0, 4),
      warningNames: Array.from(new Set(steps.flatMap((suggestion) => suggestion.warningNames || []))).slice(0, 4),
    };
  });
}

function pathTensionSum(path) {
  return (path?.steps || []).reduce((sum, suggestion) => sum + (suggestion?.tensionDelta || 0), 0);
}

function summarizeTensionTrend(value) {
  if (value >= 2) return "builds tension";
  if (value <= -2) return "releases tension";
  return "balances tension";
}

function buildCadenceGardenGroups(paths) {
  if (!Array.isArray(paths) || paths.length === 0) return [];
  const groups = new Map();
  for (const path of paths) {
    const terminal = path?.terminal || path?.steps?.[path.steps.length - 1] || null;
    if (!terminal) continue;
    const cadenceLabel = terminal.cadenceLabel || path.cadenceTrail?.[path.cadenceTrail.length - 1] || "stable continuation";
    const cadenceEffect = Number.isFinite(Number(terminal.cadenceEffect)) ? Number(terminal.cadenceEffect) : -1;
    const key = `${cadenceEffect}|${cadenceLabel}`;
    const tensionSum = pathTensionSum(path);
    const entry = {
      ...path,
      terminal,
      cadenceLabel,
      cadenceEffect,
      tensionSum,
    };
    if (!groups.has(key)) {
      groups.set(key, {
        cadenceLabel,
        cadenceEffect,
        paths: [],
      });
    }
    groups.get(key).paths.push(entry);
  }

  return Array.from(groups.values()).map((group) => {
    group.paths.sort((left, right) =>
      (left.warningNames?.length || 0) - (right.warningNames?.length || 0)
      || (right.totalScore || 0) - (left.totalScore || 0)
      || Math.abs(left.tensionSum || 0) - Math.abs(right.tensionSum || 0));
    const representative = group.paths[0] || null;
    const branchCount = group.paths.length;
    const cleanBranchCount = group.paths.filter((path) => (path.warningNames?.length || 0) === 0).length;
    const tensionAverage = representative
      ? group.paths.reduce((sum, path) => sum + (path.tensionSum || 0), 0) / Math.max(1, branchCount)
      : 0;
    return {
      cadenceLabel: group.cadenceLabel,
      cadenceEffect: group.cadenceEffect,
      branchCount,
      cleanBranchCount,
      tensionAverage,
      tensionTrendLabel: summarizeTensionTrend(tensionAverage),
      warningCount: group.paths.reduce((sum, path) => sum + (path.warningNames?.length || 0), 0),
      representative,
      terminalLabels: group.paths.map((path) => path.terminalLabel).filter(Boolean),
      alternates: group.paths.slice(1, 4).map((path) => path.terminalLabel).filter(Boolean),
    };
  }).sort((left, right) =>
    (right.representative?.totalScore || 0) - (left.representative?.totalScore || 0)
    || right.cleanBranchCount - left.cleanBranchCount
    || left.warningCount - right.warningCount);
}

function buildProfileOrchardEntries(arena, historyFrames, rootSuggestion, context, activeProfile) {
  const profileCount = Math.max(counterpointProfileNames.length, DEFAULT_COUNTERPOINT_PROFILE_NAMES.length, 1);
  return Array.from({ length: profileCount }, (_unused, profileIndex) => {
    const profileLabel = counterpointProfileNames[profileIndex] || DEFAULT_COUNTERPOINT_PROFILE_NAMES[profileIndex] || `profile ${profileIndex + 1}`;
    const continuationBundle = buildFocusedContinuationContext(arena, historyFrames, rootSuggestion, context, profileIndex);
    const topSuggestion = continuationBundle.suggestions[0] || null;
    const cadenceDestinations = continuationBundle.historyBundle
      ? decodeCadenceDestinations(arena, continuationBundle.historyBundle.historyPtr, profileIndex)
      : [];
    const topDestination = cadenceDestinations[0] || null;
    const paths = topSuggestion
      ? buildContinuationPaths(arena, continuationBundle, topSuggestion, context, profileIndex, { branchCount: 2, maxDepth: 3 })
      : [];
    const topGroup = buildCadenceGardenGroups(paths)[0] || null;
    return {
      profileIndex,
      profileLabel,
      active: profileIndex === activeProfile,
      topSuggestion,
      topDestination,
      topPath: paths[0] || null,
      topGroup,
      warningCount: topSuggestion?.warningNames?.length || 0,
    };
  });
}

function buildConsensusAtlasEntries(arena, historyBundle, context, activeProfile, focusedSuggestion) {
  if (!historyBundle?.historyPtr) return [];
  const profileCount = Math.max(counterpointProfileNames.length, DEFAULT_COUNTERPOINT_PROFILE_NAMES.length, 1);
  const clusters = new Map();
  const focusedSignature = focusedSuggestion?.notes?.join(",") || "";
  for (let profileIndex = 0; profileIndex < profileCount; profileIndex += 1) {
    const profileLabel = counterpointProfileNames[profileIndex] || DEFAULT_COUNTERPOINT_PROFILE_NAMES[profileIndex] || `profile ${profileIndex + 1}`;
    const suggestions = decodeRankedNextSteps(arena, historyBundle.historyPtr, profileIndex, context).slice(0, 3);
    suggestions.forEach((suggestion, rankIndex) => {
      const signature = suggestion.notes.join(",");
      if (!clusters.has(signature)) {
        clusters.set(signature, {
          signature,
          setValue: suggestion.setValue,
          noteNames: suggestion.noteNames.slice(),
          chordLabel: suggestion.chordLabel,
          bestSuggestion: suggestion,
          bestRank: rankIndex,
          bestScore: suggestion.score,
          memberProfiles: [],
          memberProfileIndexes: [],
          cadenceLabels: [],
          reasonNames: [],
          warningNames: [],
          supportCount: 0,
          topRankCount: 0,
          activeProfileIncluded: false,
          activeProfileRank: Number.POSITIVE_INFINITY,
          matchesFocused: focusedSignature !== "" && signature === focusedSignature,
        });
      }
      const cluster = clusters.get(signature);
      if (!cluster.memberProfileIndexes.includes(profileIndex)) {
        cluster.memberProfileIndexes.push(profileIndex);
        cluster.memberProfiles.push(profileLabel);
        cluster.supportCount += 1;
      }
      if (rankIndex === 0) cluster.topRankCount += 1;
      if (profileIndex === activeProfile) {
        cluster.activeProfileIncluded = true;
        cluster.activeProfileRank = Math.min(cluster.activeProfileRank, rankIndex);
      }
      suggestion.reasonNames.forEach((reason) => {
        if (!cluster.reasonNames.includes(reason) && cluster.reasonNames.length < 5) cluster.reasonNames.push(reason);
      });
      suggestion.warningNames.forEach((warning) => {
        if (!cluster.warningNames.includes(warning) && cluster.warningNames.length < 4) cluster.warningNames.push(warning);
      });
      if (suggestion.cadenceLabel && !cluster.cadenceLabels.includes(suggestion.cadenceLabel) && cluster.cadenceLabels.length < 4) {
        cluster.cadenceLabels.push(suggestion.cadenceLabel);
      }
      if (
        rankIndex < cluster.bestRank
        || (rankIndex === cluster.bestRank && suggestion.score > cluster.bestScore)
      ) {
        cluster.bestSuggestion = suggestion;
        cluster.bestRank = rankIndex;
        cluster.bestScore = suggestion.score;
      }
    });
  }
  return Array.from(clusters.values())
    .sort((left, right) =>
      right.supportCount - left.supportCount
      || right.topRankCount - left.topRankCount
      || (left.activeProfileRank - right.activeProfileRank)
      || (right.bestScore - left.bestScore)
      || left.warningNames.length - right.warningNames.length)
    .map((cluster) => ({
      ...cluster,
      supportLabel: cluster.supportCount > 1
        ? `${cluster.supportCount}-profile consensus`
        : "style outlier",
      cadenceLabel: cluster.cadenceLabels[0] || cluster.bestSuggestion?.cadenceLabel || "stable continuation",
      terminalLabel: cluster.bestSuggestion?.noteNames?.join(" · ") || "",
    }));
}

function renderMidiPathWeaver(host, arena, rootSuggestion, paths, context, options = {}) {
  const empty = {
    pathCount: 0,
    pathStepCount: 0,
    pathMiniCount: 0,
    rootFocusedIndex: -1,
    terminalLabels: [],
  };
  if (!host) return empty;
  if (!rootSuggestion) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to weave a few short continuation paths from it.</div>`;
    return empty;
  }

  const visiblePaths = Array.isArray(paths) ? paths.slice(0, 3) : [];
  const focusedLetter = options.rootFocusedIndex != null && options.rootFocusedIndex >= 0
    ? String.fromCharCode(65 + options.rootFocusedIndex)
    : "Focused";
  const rootLabel = rootSuggestion.noteNames.join(" · ");

  host.innerHTML = `
    <div class="path-weaver-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Short recursive futures</p>
          <h4>${escapeHtml(focusedLetter)}. ${escapeHtml(rootLabel)}</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill ${options.pinned ? "is-snapshot" : "is-live"}">${escapeHtml(options.pinned ? "Pinned root" : "Focused root")}</span>
          <span class="status-pill is-live">${escapeHtml(rootSuggestion.cadenceLabel)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("Each branch commits the focused move, then asks the same library-owned next-step ranker where the line most naturally wants to go over the next few local continuations.")}</p>
        <div class="chip-row">
          ${rootSuggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">neutral continuation</span>`}
        </div>
        <div class="chip-row">
          ${rootSuggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
        </div>
      </article>
      <div class="path-weaver-grid">
        ${visiblePaths.length > 0
          ? visiblePaths.map((path, index) => `
            <article class="path-weaver-card" data-path-weaver-path="${index}">
              <strong>${escapeHtml(focusedLetter)} → ${index + 1}. ${escapeHtml(path.steps[0]?.noteNames?.join(" · ") || "No continuation")}</strong>
              <p class="path-weaver-path-meta">path score ${escapeHtml(String(path.totalScore))} · cadence ${escapeHtml(path.cadenceTrail.join(" → "))}</p>
              <div class="path-weaver-step-flow">
                ${path.steps.map((step, stepIndex) => `
                  <span class="path-weaver-step">
                    <span class="path-weaver-step-label">${escapeHtml(stepIndex === 0 ? "Then" : `+${stepIndex}`)}</span>
                    <span>${escapeHtml(step.noteNames.join(" · "))}</span>
                  </span>
                  ${stepIndex < path.steps.length - 1 ? `<span class="path-weaver-arrow">→</span>` : ""}
                `).join("")}
              </div>
              <div class="chip-row">
                ${path.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}
              </div>
              <div class="chip-row">
                ${path.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
              </div>
              <p class="path-weaver-step-meta">terminal: ${escapeHtml(path.terminalLabel || "")}</p>
              <div class="path-weaver-terminal-grid">
                <div class="path-weaver-terminal-art" data-path-weaver-clock="${index}"></div>
                <div class="path-weaver-terminal-art" data-path-weaver-mini="${index}"></div>
              </div>
            </article>
          `).join("")
          : `<div class="output-block continuation-empty">No stable multi-step branches yet for this focused move.</div>`}
      </div>
    </div>
  `;

  let pathMiniCount = 0;
  visiblePaths.forEach((path, index) => {
    const terminal = path.terminal || path.steps[path.steps.length - 1] || null;
    if (!terminal) return;
    const clockHost = host.querySelector(`[data-path-weaver-clock="${index}"]`);
    if (clockHost) {
      renderPreviewSvgOrBitmap(clockHost, {
        svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, terminal.setValue),
        bitmapRenderer: {
          renderRgba: (width, height) => clockBitmapRgba(arena, terminal.setValue, width, height),
        },
        alt: `${terminal.noteNames.join(" ")} path terminal clock preview`,
        options: { maxHeight: 138, squareWidth: 150, mediumWidth: 160, wideWidth: 170, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
      });
    }
    const miniHost = host.querySelector(`[data-path-weaver-mini="${index}"]`);
    if (miniHost) {
      const rendered = renderMiniInstrumentPreview(
        arena,
        miniHost,
        {
          midiNotes: terminal.notes,
          setValue: terminal.setValue,
          tonic: context.tonic,
          preferredBassPc: terminal.notes.length > 0 ? Math.min(...terminal.notes) % 12 : null,
          fretVoicing: terminal.fretPreview,
        },
        `${terminal.noteNames.join(" ")} path terminal mini preview`,
        {
          maxHeight: 150,
          squareWidth: 170,
          mediumWidth: 180,
          wideWidth: 190,
          ultraWideWidth: 200,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
      if (rendered) pathMiniCount += 1;
    }
  });

  return {
    pathCount: visiblePaths.length,
    pathStepCount: visiblePaths.reduce((sum, path) => sum + path.steps.length, 0),
    pathMiniCount,
    rootFocusedIndex: options.rootFocusedIndex ?? -1,
    terminalLabels: visiblePaths.map((path) => path.terminalLabel),
  };
}

function renderMidiCadenceGarden(host, arena, rootSuggestion, groups, context, options = {}) {
  const empty = {
    groupCount: 0,
    branchCount: 0,
    terminalClockCount: 0,
    terminalMiniCount: 0,
    rootFocusedIndex: -1,
    cadenceLabels: [],
    warningGroupCount: 0,
  };
  if (!host) return empty;
  if (!rootSuggestion) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to see which cadence destinations actually open over the next few local branches.</div>`;
    return empty;
  }

  const visibleGroups = Array.isArray(groups) ? groups.slice(0, 4) : [];
  const focusedLetter = options.rootFocusedIndex != null && options.rootFocusedIndex >= 0
    ? String.fromCharCode(65 + options.rootFocusedIndex)
    : "Focused";
  const rootLabel = rootSuggestion.noteNames.join(" · ");

  host.innerHTML = `
    <div class="cadence-garden-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Reachable arrival beds</p>
          <h4>${escapeHtml(focusedLetter)}. ${escapeHtml(rootLabel)}</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill ${options.pinned ? "is-snapshot" : "is-live"}">${escapeHtml(options.pinned ? "Pinned root" : "Focused root")}</span>
          <span class="status-pill is-live">${escapeHtml(rootSuggestion.cadenceLabel)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("The garden regroups the short recursive branches by where they want to arrive. This turns several raw path strips into a map of reachable cadence regions from the current focused move.")}</p>
        <div class="chip-row">
          ${rootSuggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">neutral continuation</span>`}
        </div>
        <div class="chip-row">
          ${rootSuggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
        </div>
      </article>
      <div class="cadence-garden-grid">
        ${visibleGroups.length > 0
          ? visibleGroups.map((group, index) => {
            const representative = group.representative;
            return `
              <article class="cadence-garden-card" data-cadence-garden-group="${index}">
                <div class="cadence-garden-card-head">
                  <div>
                    <p class="eyebrow">Cadence region ${index + 1}</p>
                    <h4>${escapeHtml(group.cadenceLabel)}</h4>
                  </div>
                  <div class="pill-list">
                    <span class="status-pill is-live">${escapeHtml(`${group.branchCount} branch${group.branchCount === 1 ? "" : "es"}`)}</span>
                    <span class="status-pill ${group.warningCount > 0 ? "is-snapshot" : "is-live"}">${escapeHtml(group.tensionTrendLabel)}</span>
                  </div>
                </div>
                <p class="cadence-garden-meta">best path score ${escapeHtml(String(representative?.totalScore || 0))} · clean ${escapeHtml(String(group.cleanBranchCount))}/${escapeHtml(String(group.branchCount))} · terminal ${escapeHtml(representative?.terminalLabel || "")}</p>
                <div class="path-weaver-step-flow">
                  ${(representative?.steps || []).map((step, stepIndex) => `
                    <span class="path-weaver-step">
                      <span class="path-weaver-step-label">${escapeHtml(stepIndex === 0 ? "Then" : `+${stepIndex}`)}</span>
                      <span>${escapeHtml(step.noteNames.join(" · "))}</span>
                    </span>
                    ${stepIndex < (representative?.steps?.length || 0) - 1 ? `<span class="path-weaver-arrow">→</span>` : ""}
                  `).join("")}
                </div>
                <div class="chip-row">
                  ${(representative?.reasonNames || []).map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}
                </div>
                <div class="chip-row">
                  ${(representative?.warningNames || []).map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
                </div>
                <p class="cadence-garden-alternates">${escapeHtml(group.alternates.length > 0 ? `also reaches ${group.alternates.join(" · ")}` : "single strongest arrival region so far")}</p>
                <div class="cadence-garden-art-grid">
                  <div class="cadence-garden-art" data-cadence-garden-clock="${index}"></div>
                  <div class="cadence-garden-art" data-cadence-garden-mini="${index}"></div>
                </div>
              </article>
            `;
          }).join("")
          : `<div class="output-block continuation-empty">No cadence regions are populated yet for this focused move.</div>`}
      </div>
    </div>
  `;

  let terminalClockCount = 0;
  let terminalMiniCount = 0;
  visibleGroups.forEach((group, index) => {
    const terminal = group.representative?.terminal || null;
    if (!terminal) return;
    const clockHost = host.querySelector(`[data-cadence-garden-clock="${index}"]`);
    if (clockHost) {
      renderPreviewSvgOrBitmap(clockHost, {
        svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, terminal.setValue),
        bitmapRenderer: {
          renderRgba: (width, height) => clockBitmapRgba(arena, terminal.setValue, width, height),
        },
        alt: `${terminal.noteNames.join(" ")} cadence garden terminal clock preview`,
        options: { maxHeight: 138, squareWidth: 150, mediumWidth: 160, wideWidth: 170, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
      });
      terminalClockCount += 1;
    }
    const miniHost = host.querySelector(`[data-cadence-garden-mini="${index}"]`);
    if (miniHost) {
      const rendered = renderMiniInstrumentPreview(
        arena,
        miniHost,
        {
          midiNotes: terminal.notes,
          setValue: terminal.setValue,
          tonic: context.tonic,
          preferredBassPc: terminal.notes.length > 0 ? Math.min(...terminal.notes) % 12 : null,
          fretVoicing: terminal.fretPreview,
        },
        `${terminal.noteNames.join(" ")} cadence garden terminal mini preview`,
        {
          maxHeight: 150,
          squareWidth: 170,
          mediumWidth: 180,
          wideWidth: 190,
          ultraWideWidth: 200,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
      if (rendered) terminalMiniCount += 1;
    }
  });

  return {
    groupCount: visibleGroups.length,
    branchCount: visibleGroups.reduce((sum, group) => sum + group.branchCount, 0),
    terminalClockCount,
    terminalMiniCount,
    rootFocusedIndex: options.rootFocusedIndex ?? -1,
    cadenceLabels: visibleGroups.map((group) => group.cadenceLabel),
    warningGroupCount: visibleGroups.filter((group) => group.warningCount > 0).length,
  };
}

function renderMidiProfileOrchard(host, arena, rootSuggestion, entries, context, options = {}) {
  const empty = {
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
  if (!host) return empty;
  if (!rootSuggestion) {
    host.innerHTML = `<div class="output-block continuation-empty">Focus or pin a ranked move to compare how the same musical moment evolves under each counterpoint rule profile.</div>`;
    return empty;
  }

  const visibleEntries = Array.isArray(entries)
    ? entries.slice(0, Math.max(counterpointProfileNames.length, DEFAULT_COUNTERPOINT_PROFILE_NAMES.length, 1))
    : [];
  const focusedLetter = options.rootFocusedIndex != null && options.rootFocusedIndex >= 0
    ? String.fromCharCode(65 + options.rootFocusedIndex)
    : "Focused";
  const rootLabel = rootSuggestion.noteNames.join(" · ");

  host.innerHTML = `
    <div class="profile-orchard-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Same root, different rule worlds</p>
          <h4>${escapeHtml(focusedLetter)}. ${escapeHtml(rootLabel)}</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill ${options.pinned ? "is-snapshot" : "is-live"}">${escapeHtml(options.pinned ? "Pinned root" : "Focused root")}</span>
          <span class="status-pill is-live">${escapeHtml(rootSuggestion.cadenceLabel)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("Each card commits the same focused move, then asks a different counterpoint profile what should happen next. The selected profile stays highlighted, but the whole orchard remains visible for comparison.")}</p>
        <div class="chip-row">
          ${rootSuggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">neutral continuation</span>`}
        </div>
        <div class="chip-row">
          ${rootSuggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
        </div>
      </article>
      <div class="profile-orchard-grid">
        ${visibleEntries.map((entry, index) => {
          const populated = !!entry.topSuggestion;
          const cadenceLabel = entry.topDestination?.label || entry.topGroup?.cadenceLabel || entry.topSuggestion?.cadenceLabel || "stable continuation";
          return `
            <article class="profile-orchard-card${entry.active ? " is-active-profile" : ""}${populated ? "" : " is-empty-profile"}" data-profile-orchard-card="${index}" data-profile-index="${entry.profileIndex}">
              <div class="profile-orchard-card-head">
                <div>
                  <p class="eyebrow">${escapeHtml(entry.active ? "Selected profile" : "Comparison profile")}</p>
                  <h4>${escapeHtml(humanizeCounterpointLabel(entry.profileLabel))}</h4>
                </div>
                <div class="pill-list">
                  ${entry.active ? `<span class="status-pill is-live">active</span>` : `<span class="status-pill is-muted">compare</span>`}
                  <span class="status-pill ${entry.warningCount > 0 ? "is-snapshot" : "is-live"}">${escapeHtml(cadenceLabel)}</span>
                </div>
              </div>
              ${populated ? `
                <p class="profile-orchard-meta">best next move ${escapeHtml(entry.topSuggestion.noteNames.join(" · "))} · score ${escapeHtml(String(entry.topSuggestion.score))}</p>
                <p class="profile-orchard-alternates">arrival tendency <span class="profile-orchard-cadence">${escapeHtml(cadenceLabel)}</span>${entry.topPath?.terminalLabel ? ` · terminal ${escapeHtml(entry.topPath.terminalLabel)}` : ""}</p>
                <div class="chip-row">
                  ${entry.topSuggestion.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}
                </div>
                <div class="chip-row">
                  ${entry.topSuggestion.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
                </div>
                <div class="profile-orchard-art-grid">
                  <div class="profile-orchard-art" data-profile-orchard-clock="${index}"></div>
                  <div class="profile-orchard-art" data-profile-orchard-mini="${index}"></div>
                </div>
              ` : `
                <div class="output-block continuation-empty">No stable continuation ranked yet for this profile from the shared root.</div>
              `}
            </article>
          `;
        }).join("")}
      </div>
    </div>
  `;

  let profileClockCount = 0;
  let profileMiniCount = 0;
  visibleEntries.forEach((entry, index) => {
    if (!entry.topSuggestion) return;
    const clockHost = host.querySelector(`[data-profile-orchard-clock="${index}"]`);
    if (clockHost) {
      renderPreviewSvgOrBitmap(clockHost, {
        svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, entry.topSuggestion.setValue),
        bitmapRenderer: {
          renderRgba: (width, height) => clockBitmapRgba(arena, entry.topSuggestion.setValue, width, height),
        },
        alt: `${entry.profileLabel} profile orchard clock preview`,
        options: { maxHeight: 138, squareWidth: 150, mediumWidth: 160, wideWidth: 170, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
      });
      profileClockCount += 1;
    }
    const miniHost = host.querySelector(`[data-profile-orchard-mini="${index}"]`);
    if (miniHost) {
      const rendered = renderMiniInstrumentPreview(
        arena,
        miniHost,
        {
          midiNotes: entry.topSuggestion.notes,
          setValue: entry.topSuggestion.setValue,
          tonic: context.tonic,
          preferredBassPc: entry.topSuggestion.notes.length > 0 ? Math.min(...entry.topSuggestion.notes) % 12 : null,
          fretVoicing: entry.topSuggestion.fretPreview,
        },
        `${entry.profileLabel} profile orchard mini preview`,
        {
          maxHeight: 150,
          squareWidth: 170,
          mediumWidth: 180,
          wideWidth: 190,
          ultraWideWidth: 200,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
      if (rendered) profileMiniCount += 1;
    }
  });

  return {
    profileCardCount: visibleEntries.length,
    populatedProfileCount: visibleEntries.filter((entry) => !!entry.topSuggestion).length,
    highlightedCardCount: visibleEntries.filter((entry) => entry.active).length,
    profileClockCount,
    profileMiniCount,
    activeProfileIndex: options.activeProfileIndex ?? -1,
    profileNames: visibleEntries.map((entry) => entry.profileLabel),
    cadenceLabels: visibleEntries.map((entry) => entry.topDestination?.label || entry.topGroup?.cadenceLabel || entry.topSuggestion?.cadenceLabel || "").filter(Boolean),
    warningCardCount: visibleEntries.filter((entry) => (entry.warningCount || 0) > 0).length,
    rootFocusedIndex: options.rootFocusedIndex ?? -1,
  };
}

function renderMidiConsensusAtlas(host, arena, entries, context, options = {}) {
  const empty = {
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
  if (!host) return empty;
  if (!Array.isArray(entries) || entries.length === 0) {
    host.innerHTML = `<div class="output-block continuation-empty">Play a voiced fragment to see which immediate next moves are shared across profiles and which ones are stylistic outliers.</div>`;
    return empty;
  }

  const visibleEntries = entries.slice(0, 6);
  const focusedSignature = options.focusedSignature || visibleEntries[0]?.signature || "";
  host.innerHTML = `
    <div class="consensus-atlas-shell">
      <div class="continuation-head">
        <div>
          <p class="eyebrow">Shared next moves before commitment</p>
          <h4>${escapeHtml(context.label)} immediate continuations</h4>
        </div>
        <div class="pill-list">
          <span class="status-pill is-live">${escapeHtml(`${visibleEntries.filter((entry) => entry.supportCount > 1).length} consensus clusters`)}</span>
          <span class="status-pill ${visibleEntries.some((entry) => entry.supportCount === 1) ? "is-snapshot" : "is-live"}">${escapeHtml(`${visibleEntries.filter((entry) => entry.supportCount === 1).length} outliers`)}</span>
        </div>
      </div>
      <article class="continuation-root">
        <p>${escapeHtml("The atlas regroups the best immediate continuations from all counterpoint profiles. Shared clusters reveal broad agreement; outliers show moves that only one style really wants.")}</p>
        <div class="chip-row">
          <span class="pill">${escapeHtml("highlighted cluster follows the active-profile focused or pinned candidate")}</span>
          <span class="pill">${escapeHtml("cards stay before the orchard so you can decide what deserves deeper comparison")}</span>
        </div>
      </article>
      <div class="consensus-atlas-grid">
        ${visibleEntries.map((entry, index) => `
          <article class="consensus-atlas-card${entry.supportCount > 1 ? " is-consensus" : " is-outlier"}${entry.signature === focusedSignature ? " is-focused-cluster" : ""}" data-consensus-atlas-card="${index}" data-consensus-signature="${entry.signature}" data-support-count="${entry.supportCount}">
            <div class="consensus-atlas-card-head">
              <div>
                <p class="eyebrow">${escapeHtml(entry.signature === focusedSignature ? "Focused cluster" : entry.supportLabel)}</p>
                <h4>${escapeHtml(entry.noteNames.join(" · "))}</h4>
              </div>
              <div class="pill-list">
                <span class="status-pill ${entry.supportCount > 1 ? "is-live" : "is-muted"}">${escapeHtml(`${entry.supportCount} profile${entry.supportCount === 1 ? "" : "s"}`)}</span>
                <span class="status-pill ${entry.warningNames.length > 0 ? "is-snapshot" : "is-live"}">${escapeHtml(entry.cadenceLabel)}</span>
              </div>
            </div>
            <p class="consensus-atlas-meta">best next move ${escapeHtml(entry.terminalLabel)} · top-ranked in ${escapeHtml(String(entry.topRankCount))} profile${entry.topRankCount === 1 ? "" : "s"} · score ${escapeHtml(String(entry.bestSuggestion?.score ?? 0))}</p>
            <p class="consensus-atlas-alternates">active profile ${entry.activeProfileIncluded ? `includes this cluster at rank ${entry.activeProfileRank + 1}` : "does not currently favor this move"} · cadence <span class="consensus-atlas-cadence">${escapeHtml(entry.cadenceLabel)}</span></p>
            <div class="consensus-atlas-profile-list">
              ${entry.memberProfiles.map((profileName, profileListIndex) => `<span class="consensus-atlas-profile-pill${entry.memberProfileIndexes[profileListIndex] === options.activeProfileIndex ? " is-active-profile" : ""}" data-consensus-profile="${escapeHtml(profileName)}">${escapeHtml(humanizeCounterpointLabel(profileName))}</span>`).join("")}
            </div>
            <div class="chip-row">
              ${entry.reasonNames.map((reason) => `<span class="pill">${escapeHtml(reason)}</span>`).join("") || `<span class="pill">no dominant reason</span>`}
            </div>
            <div class="chip-row">
              ${entry.warningNames.map((warning) => `<span class="chip warning-chip">${escapeHtml(warning)}</span>`).join("") || `<span class="chip safe-chip">clean motion</span>`}
            </div>
            <div class="consensus-atlas-art-grid">
              <div class="consensus-atlas-art" data-consensus-atlas-clock="${index}"></div>
              <div class="consensus-atlas-art" data-consensus-atlas-mini="${index}"></div>
            </div>
          </article>
        `).join("")}
      </div>
    </div>
  `;

  let clusterClockCount = 0;
  let clusterMiniCount = 0;
  visibleEntries.forEach((entry, index) => {
    const clockHost = host.querySelector(`[data-consensus-atlas-clock="${index}"]`);
    if (clockHost) {
      renderPreviewSvgOrBitmap(clockHost, {
        svgMarkup: svgString(arena, wasm.lmt_svg_clock_optc, entry.bestSuggestion.setValue),
        bitmapRenderer: {
          renderRgba: (width, height) => clockBitmapRgba(arena, entry.bestSuggestion.setValue, width, height),
        },
        alt: `${entry.noteNames.join(" ")} consensus atlas clock preview`,
        options: { maxHeight: 138, squareWidth: 150, mediumWidth: 160, wideWidth: 170, ultraWideWidth: 180, padXRatio: 0.08, padYRatio: 0.12 },
      });
      clusterClockCount += 1;
    }
    const miniHost = host.querySelector(`[data-consensus-atlas-mini="${index}"]`);
    if (miniHost) {
      const rendered = renderMiniInstrumentPreview(
        arena,
        miniHost,
        {
          midiNotes: entry.bestSuggestion.notes,
          setValue: entry.bestSuggestion.setValue,
          tonic: context.tonic,
          preferredBassPc: entry.bestSuggestion.notes.length > 0 ? Math.min(...entry.bestSuggestion.notes) % 12 : null,
          fretVoicing: entry.bestSuggestion.fretPreview,
        },
        `${entry.noteNames.join(" ")} consensus atlas mini preview`,
        {
          maxHeight: 150,
          squareWidth: 170,
          mediumWidth: 180,
          wideWidth: 190,
          ultraWideWidth: 200,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      );
      if (rendered) clusterMiniCount += 1;
    }
  });

  const profileCoverage = new Set(visibleEntries.flatMap((entry) => entry.memberProfiles));
  return {
    clusterCount: visibleEntries.length,
    consensusClusterCount: visibleEntries.filter((entry) => entry.supportCount > 1).length,
    singletonClusterCount: visibleEntries.filter((entry) => entry.supportCount === 1).length,
    highlightedClusterCount: visibleEntries.filter((entry) => entry.signature === focusedSignature).length,
    clusterClockCount,
    clusterMiniCount,
    maxSupportCount: visibleEntries.reduce((max, entry) => Math.max(max, entry.supportCount), 0),
    focusedSignature,
    profileCoverageCount: profileCoverage.size,
    clusterLabels: visibleEntries.map((entry) => entry.noteNames.join(" · ")),
    cadenceLabels: visibleEntries.map((entry) => entry.cadenceLabel).filter(Boolean),
  };
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

function buildFocusedContinuationContext(arena, historyFrames, focusedSuggestion, context, profile) {
  if (!focusedSuggestion || !Array.isArray(focusedSuggestion.notes) || focusedSuggestion.notes.length === 0) {
    return { historyFrames: [], historyBundle: null, voicedHistory: { len: 0, states: [] }, suggestions: [] };
  }
  const frames = historyFrames.map(cloneHistoryFrame);
  const nextStepIndex = frames.length > 0 ? frames[frames.length - 1].stepIndex + 1 : 0;
  frames.push({
    notes: focusedSuggestion.notes.slice(),
    sustained: [],
    timestamp: Date.now(),
    stepIndex: nextStepIndex,
  });
  const cap = Math.max(1, counterpointStructSizes.historyCapacity || 4);
  const continuationFrames = frames.slice(-cap);
  const historyBundle = buildCounterpointHistory(arena, continuationFrames, context);
  const suggestions = decodeRankedNextSteps(arena, historyBundle.historyPtr, profile, context);
  const voicedHistory = decodeVoicedHistoryFromPointer(historyBundle.historyPtr);
  return {
    historyFrames: continuationFrames,
    historyBundle,
    voicedHistory,
    suggestions,
  };
}

function buildActualSuggestionFromFrame(arena, historyBundle, frame, context, profile, rankedSuggestions = []) {
  if (!frame || !Array.isArray(frame.notes) || frame.notes.length === 0) {
    return { suggestion: null, matched: false };
  }

  const signature = frame.notes.join(",");
  const rankedMatch = rankedSuggestions.find((one) => noteSignature(one) === signature) || null;
  if (rankedMatch) {
    return { suggestion: rankedMatch, matched: true };
  }

  const candidatePtr = arena.alloc(counterpointStructSizes.voicedState || 96, 4);
  const notesPtr = writeU8Array(arena, frame.notes);
  const sustainedPtr = writeU8Array(arena, frame.sustained || []);
  const beatInBar = ((frame.stepIndex ?? 0) % 4 + 4) % 4;
  const written = wasm.lmt_build_voiced_state(
    notesPtr,
    frame.notes.length,
    sustainedPtr,
    (frame.sustained || []).length,
    context.tonic,
    context.modeType,
    beatInBar,
    4,
    0,
    255,
    historyBundle?.statePtr || null,
    candidatePtr,
  );
  if (!written) {
    return { suggestion: null, matched: false };
  }

  const candidateState = decodeVoicedStateFromPointer(candidatePtr);
  const summaryPtr = arena.alloc(96, 4);
  const evaluationPtr = arena.alloc(32, 4);
  let motion = null;
  let evaluation = null;
  if (historyBundle?.statePtr && wasm.lmt_classify_motion(historyBundle.statePtr, candidatePtr, summaryPtr)) {
    motion = decodeMotionSummaryFromPointer(summaryPtr);
    if (wasm.lmt_evaluate_motion_profile(profile, summaryPtr, evaluationPtr)) {
      evaluation = decodeMotionEvaluationFromPointer(evaluationPtr);
    }
  }

  const setValue = midiListToSet(arena, frame.notes);
  const reasonNames = deriveMotionReasonNames(motion, evaluation, candidateState?.voiceCount || frame.notes.length);
  if ((evaluation?.score || 0) < 0 && !reasonNames.includes("builds-tension")) {
    reasonNames.push("builds-tension");
  }
  const warningNames = deriveMotionWarningNames(motion, evaluation);
  const overlapCount = wasm.lmt_pcs_cardinality(setValue & context.setValue);
  if (overlapCount < wasm.lmt_pcs_cardinality(setValue) && !warningNames.includes("outside-context")) {
    warningNames.push("outside-context");
  }

  return {
    matched: true,
    suggestion: {
      score: evaluation?.score || 0,
      reasonMask: 0,
      warningMask: 0,
      cadenceEffect: candidateState?.cadenceState || 0,
      cadenceLabel: cadenceLabel(candidateState?.cadenceState || 0),
      tensionDelta: evaluation?.score || 0,
      noteCount: frame.notes.length,
      setValue,
      notes: frame.notes.slice(),
      noteNames: frame.notes.map((midi) => midiName(midi, context.tonic, context.quality)),
      chordLabel: friendlyChordName(rawChordName(setValue)),
      reasonNames,
      warningNames,
      motion,
      evaluation,
      fretPreview: preferredFretVoicing(arena, setValue, {
        preferredBassPc: frame.notes.length > 0 ? Math.min(...frame.notes) % 12 : null,
      }),
    },
  };
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

function renderVoiceLeadingHorizon(host, currentState, suggestions, focusedIndex, context) {
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
  const chosenIndex = visibleSuggestions.length === 0 ? -1 : clamp(focusedIndex ?? 0, 0, visibleSuggestions.length - 1);
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
        const focusedClass = index === chosenIndex ? " is-focused" : "";
        return `
          <path class="horizon-connector" d="M ${centerX + 44} ${centerY} C ${centerX + 132} ${centerY}, ${candidateX - 96} ${y}, ${candidateX - nodeRadius - 20} ${y}" stroke="${stroke}" stroke-width="${(2.4 + normalized * 2.4).toFixed(2)}" opacity="${(0.52 + normalized * 0.38).toFixed(2)}" />
          <circle class="horizon-candidate-node${focusedClass}" cx="${candidateX}" cy="${y}" r="${nodeRadius.toFixed(1)}" fill="${fill}" stroke="${stroke}" />
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
              <rect class="horizon-reason-tag${focusedClass}" x="${(tagX - tagWidth / 2).toFixed(1)}" y="${(tagY - 10).toFixed(1)}" width="${tagWidth.toFixed(1)}" height="16" rx="8" />
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

function renderVoiceBraid(host, historyStates, candidateStates, focusedIndex, context) {
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
  const chosenIndex = visibleCandidates.length === 0 ? -1 : clamp(focusedIndex ?? 0, 0, visibleCandidates.length - 1);
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
      return `<line class="braid-ghost-strand${candidateIndex === chosenIndex ? " is-focused" : ""}" x1="${historyXs[historyXs.length - 1].toFixed(1)}" y1="${yForMidi(currentVoice.midi).toFixed(1)}" x2="${candidateXs[candidateIndex].toFixed(1)}" y2="${yForMidi(voice.midi).toFixed(1)}" stroke="${voiceColor(voice.id)}" />`;
    }).join("");
  }).join("");

  const historyColumns = historyXs.map((x, index) => `
      <line class="braid-column braid-history-column" x1="${x.toFixed(1)}" y1="${(top - 10).toFixed(1)}" x2="${x.toFixed(1)}" y2="${(height - bottom + 4).toFixed(1)}" />
      <text x="${x.toFixed(1)}" y="${height - 12}" text-anchor="middle" class="braid-column-label">${historyLabels[index]}</text>
    `).join("");

  const candidateColumns = candidateXs.map((x, index) => `
      <line class="braid-column braid-candidate-column${index === chosenIndex ? " is-focused" : ""}" x1="${x.toFixed(1)}" y1="${(top - 10).toFixed(1)}" x2="${x.toFixed(1)}" y2="${(height - bottom + 4).toFixed(1)}" stroke-dasharray="5 7" />
      <text x="${x.toFixed(1)}" y="${height - 12}" text-anchor="middle" class="braid-column-label braid-column-label-ghost">${escapeHtml(String.fromCharCode(65 + index))}</text>
    `).join("");

  const voiceNodes = historyStates.map((state, index) => state.voices.map((voice) => `
      <circle class="braid-node ${index === historyStates.length - 1 ? "braid-current-node" : "braid-history-node"}" cx="${historyXs[index].toFixed(1)}" cy="${yForMidi(voice.midi).toFixed(1)}" r="${index === historyStates.length - 1 ? "8.5" : "6.8"}" fill="${pitchClassColor(voice.pitchClass)}" stroke="${voiceColor(voice.id)}" />
    `).join("")).join("");

  const ghostNodes = visibleCandidates.map((state, candidateIndex) => state.voices.map((voice) => `
      <circle class="braid-node braid-ghost-node${candidateIndex === chosenIndex ? " is-focused" : ""}" cx="${candidateXs[candidateIndex].toFixed(1)}" cy="${yForMidi(voice.midi).toFixed(1)}" r="6.5" fill="${pitchClassColor(voice.pitchClass)}" stroke="${voiceColor(voice.id)}" />
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
    const previousVoicedState = voicedHistory.states.length >= 2 ? voicedHistory.states[voicedHistory.states.length - 2] : null;
    const currentMotionAnalysis = buildCurrentMotionAnalysis(arena, historyBundle, voicedHistory, profile);
    const cadenceDestinations = historyBundle ? decodeCadenceDestinations(arena, historyBundle.historyPtr, profile) : [];
    const suspensionMachine = historyBundle ? decodeSuspensionMachine(arena, historyBundle.historyPtr, profile, context) : null;
    const { hoveredSuggestionIndex, pinnedSuggestionIndex, focusedSuggestionIndex } = resolveFocusedMidiSuggestionIndex(suggestions);
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
    const focusedSuggestion = focusedSuggestionIndex == null ? null : suggestions[focusedSuggestionIndex] || null;
    const focusedCandidateState = focusedSuggestionIndex == null ? null : candidateStates[focusedSuggestionIndex] || null;
    const continuationBundle = focusedSuggestion
      ? buildFocusedContinuationContext(arena, historyFrames, focusedSuggestion, context, profile)
      : null;
    const continuationSuggestions = continuationBundle?.suggestions || [];
    const continuationPaths = focusedSuggestion
      ? buildContinuationPaths(arena, continuationBundle, focusedSuggestion, context, profile, { branchCount: 3, maxDepth: 3 })
      : [];
    const cadenceGardenGroups = buildCadenceGardenGroups(continuationPaths);
    const consensusAtlasEntries = buildConsensusAtlasEntries(arena, historyBundle, context, profile, focusedSuggestion);
    const obligationLedgerEntries = buildObligationLedgerEntries(
      currentVoicedState,
      currentMotionAnalysis,
      cadenceDestinations,
      suspensionMachine,
      suggestions,
      focusedSuggestion,
    );
    const profileOrchardEntries = focusedSuggestion
      ? buildProfileOrchardEntries(arena, historyFrames, focusedSuggestion, context, profile)
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
      `focused next move: ${focusedSuggestion ? focusedSuggestion.noteNames.join(" · ") : "none"}`,
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

    midiClearPinEl.disabled = pinnedSuggestionIndex == null;
    const midiInspectorFeatures = renderMidiCounterpointInspector(midiInspectorEl, focusedSuggestion, context, profileLabel, {
      pinned: pinnedSuggestionIndex != null,
      focusedIndex: focusedSuggestionIndex,
    });
    const midiConsensusAtlasFeatures = renderMidiConsensusAtlas(
      midiConsensusAtlasEl,
      arena,
      consensusAtlasEntries,
      context,
      {
        activeProfileIndex: profile,
        focusedSignature: focusedSuggestion?.notes?.join(",") || "",
      },
    );
    const midiObligationLedgerFeatures = renderMidiObligationLedger(
      midiObligationLedgerEl,
      obligationLedgerEntries,
      focusedSuggestion,
      profileLabel,
    );
    const midiResolutionThreaderFeatures = renderMidiResolutionThreader(
      midiResolutionThreaderEl,
      obligationLedgerEntries,
      focusedSuggestion,
      continuationPaths,
      profileLabel,
    );
    const midiObligationTimelineFeatures = renderMidiObligationTimeline(
      midiObligationTimelineEl,
      arena,
      historyFrames,
      context,
      profile,
      obligationLedgerEntries,
      focusedSuggestion,
      profileLabel,
    );
    const midiVoiceDutiesFeatures = renderMidiVoiceDuties(
      midiVoiceDutiesEl,
      currentVoicedState,
      previousVoicedState,
      focusedCandidateState,
      context,
      suspensionMachine,
      focusedSuggestion,
    );
    const midiContinuationLadderFeatures = renderMidiContinuationLadder(
      midiContinuationLadderEl,
      arena,
      focusedSuggestion,
      continuationSuggestions,
      context,
      {
        pinned: pinnedSuggestionIndex != null,
        sourceFocusedIndex: focusedSuggestionIndex,
      },
    );
    const midiPathWeaverFeatures = renderMidiPathWeaver(
      midiPathWeaverEl,
      arena,
      focusedSuggestion,
      continuationPaths,
      context,
      {
        pinned: pinnedSuggestionIndex != null,
        rootFocusedIndex: focusedSuggestionIndex,
      },
    );
    const midiCadenceGardenFeatures = renderMidiCadenceGarden(
      midiCadenceGardenEl,
      arena,
      focusedSuggestion,
      cadenceGardenGroups,
      context,
      {
        pinned: pinnedSuggestionIndex != null,
        rootFocusedIndex: focusedSuggestionIndex,
      },
    );
    const midiProfileOrchardFeatures = renderMidiProfileOrchard(
      midiProfileOrchardEl,
      arena,
      focusedSuggestion,
      profileOrchardEntries,
      context,
      {
        pinned: pinnedSuggestionIndex != null,
        activeProfileIndex: profile,
        rootFocusedIndex: focusedSuggestionIndex,
      },
    );

    const midiHorizonFeatures = renderVoiceLeadingHorizon(midiHorizonEl, currentVoicedState, suggestions, focusedSuggestionIndex, context);
    const midiBraidFeatures = renderVoiceBraid(midiBraidEl, voicedHistory.states, candidateStates, focusedSuggestionIndex, context);
    const midiWeatherFeatures = renderCounterpointWeatherMap(midiWeatherEl, currentVoicedState, suggestions, focusedSuggestionIndex, context);
    const midiRiskRadarFeatures = renderParallelRiskRadar(midiRiskRadarEl, currentMotionAnalysis, suggestions, focusedSuggestionIndex);
    const midiCadenceFunnelFeatures = renderCadenceFunnel(midiCadenceFunnelEl, currentVoicedState, cadenceDestinations, suggestions, context);
    const midiSuspensionMachineFeatures = renderSuspensionMachine(midiSuspensionMachineEl, suspensionMachine);
    const midiOrbifoldRibbonFeatures = renderOrbifoldRibbon(midiOrbifoldRibbonEl, currentVoicedState, suggestions, focusedSuggestionIndex, context);
    const midiCommonToneConstellationFeatures = renderCommonToneConstellation(
      midiCommonToneConstellationEl,
      currentVoicedState,
      candidateStates,
      suggestions,
      focusedSuggestionIndex,
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

    const currentMiniRendered = displayNotes.length > 0
      ? renderMiniInstrumentPreview(
        arena,
        midiCurrentFretEl,
        {
          midiNotes: displayNotes,
          setValue,
          tonic: context.tonic,
          preferredBassPc: displayNotes.length > 0 ? Math.min(...displayNotes) % 12 : null,
        },
        "Current selection mini preview",
        {
          maxHeight: 280,
          squareWidth: 260,
          mediumWidth: 320,
          wideWidth: 360,
          ultraWideWidth: 400,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      )
      : false;
    if (displayNotes.length === 0) {
      midiCurrentFretEl.innerHTML = `<div class="output-block">Play notes to mirror the current selection on the chosen mini instrument.</div>`;
    }

    const focusedMiniRendered = focusedSuggestion
      ? renderMiniInstrumentPreview(
        arena,
        midiFocusedMiniEl,
        {
          midiNotes: focusedSuggestion.notes,
          setValue: focusedSuggestion.setValue,
          tonic: context.tonic,
          preferredBassPc: focusedSuggestion.notes.length > 0 ? Math.min(...focusedSuggestion.notes) % 12 : null,
          fretVoicing: focusedSuggestion.fretPreview,
        },
        "Focused next move mini preview",
        {
          maxHeight: 280,
          squareWidth: 260,
          mediumWidth: 320,
          wideWidth: 360,
          ultraWideWidth: 400,
          padXRatio: 0.08,
          padYRatio: 0.14,
        },
      )
      : false;
    if (!focusedSuggestion) {
      midiFocusedMiniEl.innerHTML = `<div class="output-block">Focus or pin a ranked move to compare the next voicing on the chosen mini instrument.</div>`;
    }

    if (suggestions.length === 0) {
      midiSuggestionsEl.innerHTML = `<p class="snapshot-empty">Once at least one note is sounding, libmusictheory will rank voiced next moves against ${escapeHtml(context.label)} here.</p>`;
    } else {
      midiSuggestionsEl.innerHTML = suggestions.map((suggestion, index) => `
        <article class="suggestion-card${focusedSuggestionIndex === index ? " is-focused" : ""}${pinnedSuggestionIndex === index ? " is-pinned" : ""}" data-suggestion-index="${index}" tabindex="0" aria-pressed="${pinnedSuggestionIndex === index ? "true" : "false"}">
          <strong>${String.fromCharCode(65 + index)}. ${escapeHtml(suggestion.noteNames.join(" · "))}</strong>
          <p>${escapeHtml(suggestion.chordLabel)}</p>
          <p>score ${escapeHtml(String(suggestion.score))} · cadence ${escapeHtml(suggestion.cadenceLabel)} · tension ${escapeHtml(suggestion.tensionDelta >= 0 ? `+${suggestion.tensionDelta}` : String(suggestion.tensionDelta))}</p>
          <div class="chip-row suggestion-pin-row">${pinnedSuggestionIndex === index ? `<span class="status-pill is-snapshot">Pinned</span>` : `<span class="status-pill is-muted">Click to pin</span>`}</div>
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
            `${suggestion.noteNames.join(" ")} mini preview`,
            {
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
      suggestionSignatures: suggestions.map((one) => one.notes.join(",")),
      topSuggestionSignature: suggestions[0]?.notes?.join(",") || "",
      focusedSuggestionSignature: focusedSuggestion?.notes?.join(",") || "",
      hoveredCandidateIndex: hoveredSuggestionIndex == null ? -1 : hoveredSuggestionIndex,
      focusedCandidateIndex: focusedSuggestionIndex == null ? -1 : focusedSuggestionIndex,
      pinnedCandidateIndex: pinnedSuggestionIndex == null ? -1 : pinnedSuggestionIndex,
      currentMiniMode: miniInstrumentMode(),
      currentMiniRendered,
      focusedMiniRendered,
      suggestionMiniCount: miniInstrumentMode() === MINI_INSTRUMENT_OFF ? 0 : suggestions.length,
      focusedSuggestionName: focusedSuggestion?.noteNames?.join(" · ") || "",
      midiInspectorFeatures,
      midiConsensusAtlasFeatures,
      midiObligationLedgerFeatures,
      midiResolutionThreaderFeatures,
      midiObligationTimelineFeatures,
      midiVoiceDutiesFeatures,
      midiContinuationLadderFeatures,
      midiPathWeaverFeatures,
      midiCadenceGardenFeatures,
      midiProfileOrchardFeatures,
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
  midiClearPinEl.addEventListener("click", () => {
    clearPinnedMidiSuggestion();
    midiState.hoveredSuggestionIndex = 0;
    renderMidiScene();
    setStatus(`${MIDI_SCENE_TITLE} returned to hover-driven focus.`);
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
  midiSuggestionsEl.addEventListener("click", (event) => {
    const card = event.target.closest("[data-suggestion-index]");
    if (!card) return;
    const nextIndex = Number.parseInt(card.getAttribute("data-suggestion-index") || "-1", 10);
    if (!Number.isInteger(nextIndex) || nextIndex < 0) return;
    if (midiState.pinnedSuggestionIndex === nextIndex) {
      clearPinnedMidiSuggestion();
      renderMidiScene();
      setStatus(`${MIDI_SCENE_TITLE} unpinned candidate ${String.fromCharCode(65 + nextIndex)}.`);
      return;
    }
    midiState.hoveredSuggestionIndex = nextIndex;
    const arena = new ScratchArena();
    try {
      const historyFrames = effectiveHistoryFrames(currentDisplayMidiNotes());
      const context = currentDisplayMidiContext();
      const historyBundle = historyFrames.length > 0 ? buildCounterpointHistory(arena, historyFrames, context) : null;
      const suggestions = historyBundle ? decodeRankedNextSteps(arena, historyBundle.historyPtr, currentMidiProfile(), context) : [];
      const suggestion = suggestions[nextIndex] || null;
      if (!suggestion) return;
      midiState.pinnedSuggestionIndex = nextIndex;
      midiState.pinnedSuggestionSignature = suggestionSignature(suggestion);
    } finally {
      arena.release();
    }
    renderMidiScene();
    setStatus(`${MIDI_SCENE_TITLE} pinned candidate ${String.fromCharCode(65 + nextIndex)}.`);
  });
  midiSuggestionsEl.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    const card = event.target.closest("[data-suggestion-index]");
    if (!card) return;
    event.preventDefault();
    card.click();
  });
  midiSuggestionsEl.addEventListener("mouseleave", () => {
    if (midiState.pinnedSuggestionIndex != null) return;
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
