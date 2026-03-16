const statusEl = document.getElementById("status");

const outPcs = document.getElementById("out-pcs");
const outClassification = document.getElementById("out-classification");
const outScaleMode = document.getElementById("out-scale-mode");
const outChord = document.getElementById("out-chord");
const outGuitar = document.getElementById("out-guitar");
const outSvgMeta = document.getElementById("out-svg-meta");

const svgClockHost = document.getElementById("svg-clock");
const svgFretHost = document.getElementById("svg-fret");
const svgStaffHost = document.getElementById("svg-staff");

let wasm = null;
let memory = null;
let currentMainSet = 0;

const REQUIRED_EXPORTS = [
  "memory",
  "lmt_pcs_from_list",
  "lmt_pcs_to_list",
  "lmt_pcs_cardinality",
  "lmt_pcs_transpose",
  "lmt_pcs_invert",
  "lmt_pcs_complement",
  "lmt_pcs_is_subset",
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
  "lmt_fret_to_midi",
  "lmt_fret_to_midi_n",
  "lmt_midi_to_fret_positions",
  "lmt_midi_to_fret_positions_n",
  "lmt_generate_voicings_n",
  "lmt_pitch_class_guide_n",
  "lmt_frets_to_url_n",
  "lmt_url_to_frets_n",
  "lmt_svg_clock_optc",
  "lmt_svg_fret",
  "lmt_svg_fret_n",
  "lmt_svg_chord_staff",
];

const SCRATCH_BASE = 1 << 20;
const C_STRING_CAPACITY = 64 * 1024;
const GUIDE_DOT_BYTES = 8;
const encoder = new TextEncoder();

function setStatus(message, tone = "ready") {
  statusEl.textContent = message;
  statusEl.style.color = tone === "error" ? "#b03620" : "#1f6c72";
}

function renderSectionError(label, target, err) {
  if (target) {
    target.textContent = `${label} error: ${err.message}`;
  }
}

function clearSvgHosts() {
  svgClockHost.innerHTML = "";
  svgFretHost.innerHTML = "";
  svgStaffHost.innerHTML = "";
}

function executeSection(label, fn, onError = null) {
  try {
    fn();
    return null;
  } catch (err) {
    if (onError) onError(err);
    return `${label}: ${err.message}`;
  }
}

class ScratchArena {
  constructor() {
    this.ptr = SCRATCH_BASE;
    ensureMemory(this.ptr + 64 * 1024);
  }

  alloc(size, align = 1) {
    this.ptr = Math.ceil(this.ptr / align) * align;
    const out = this.ptr;
    this.ptr += size;
    ensureMemory(this.ptr + 1);
    return out;
  }
}

function ensureWasmLoaded() {
  if (!wasm || !memory) {
    throw new Error("WASM module is not ready");
  }
}

function ensureMemory(requiredBytes) {
  const pageSize = 65536;
  const haveBytes = memory.buffer.byteLength;
  if (haveBytes >= requiredBytes) return;

  const havePages = haveBytes / pageSize;
  const needPages = Math.ceil(requiredBytes / pageSize);
  memory.grow(needPages - havePages);
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
  return new TextDecoder().decode(bytes.subarray(ptr, end));
}

function writeU8Array(arena, values) {
  const ptr = arena.alloc(values.length, 1);
  u8().set(values, ptr);
  return ptr;
}

function writeI8Array(arena, values) {
  const ptr = arena.alloc(values.length, 1);
  i8().set(values, ptr);
  return ptr;
}

function writeCString(arena, text) {
  const bytes = encoder.encode(text);
  const ptr = arena.alloc(bytes.length + 1, 1);
  u8().set(bytes, ptr);
  u8()[ptr + bytes.length] = 0;
  return ptr;
}

function parseCsvIntegers(raw, min, max, expectedLength = null) {
  const values = raw
    .split(",")
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .map((token) => Number.parseInt(token, 10));

  if (values.some((value) => Number.isNaN(value))) {
    throw new Error(`Invalid list: ${raw}`);
  }

  if (expectedLength !== null && values.length !== expectedLength) {
    throw new Error(`Expected ${expectedLength} values, got ${values.length}`);
  }

  for (const value of values) {
    if (value < min || value > max) {
      throw new Error(`Value ${value} is outside allowed range [${min}, ${max}]`);
    }
  }

  return values;
}

function getNumberInput(id) {
  return Number.parseInt(document.getElementById(id).value, 10);
}

function getSelectValue(id) {
  return Number.parseInt(document.getElementById(id).value, 10);
}

function setToHex(setValue) {
  return `0x${setValue.toString(16).padStart(3, "0")}`;
}

function packKeyContext(tonic, quality) {
  return (tonic & 0xff) | ((quality & 0xff) << 8);
}

function setToList(setValue) {
  ensureWasmLoaded();
  const arena = new ScratchArena();
  const outPtr = arena.alloc(12, 1);
  const count = wasm.lmt_pcs_to_list(setValue, outPtr);
  return Array.from(u8().subarray(outPtr, outPtr + count));
}

function runPcsApis() {
  ensureWasmLoaded();
  currentMainSet = 0;
  const arena = new ScratchArena();

  const mainList = parseCsvIntegers(document.getElementById("pcs-main").value, 0, 11);
  const subsetList = parseCsvIntegers(document.getElementById("pcs-subset").value, 0, 11);
  const transpose = getNumberInput("pcs-transpose") & 0xff;

  const mainPtr = writeU8Array(arena, mainList);
  const subsetPtr = writeU8Array(arena, subsetList);

  const mainSet = wasm.lmt_pcs_from_list(mainPtr, mainList.length);
  const subsetSet = wasm.lmt_pcs_from_list(subsetPtr, subsetList.length);
  currentMainSet = mainSet;

  const outListPtr = arena.alloc(12, 1);
  const outCount = wasm.lmt_pcs_to_list(mainSet, outListPtr);
  const roundTripList = Array.from(u8().subarray(outListPtr, outListPtr + outCount));

  const cardinality = wasm.lmt_pcs_cardinality(mainSet);
  const transposed = wasm.lmt_pcs_transpose(mainSet, transpose);
  const inverted = wasm.lmt_pcs_invert(mainSet);
  const complement = wasm.lmt_pcs_complement(mainSet);
  const isSubset = !!wasm.lmt_pcs_is_subset(subsetSet, mainSet);

  outPcs.textContent = [
    `lmt_pcs_from_list(main): ${setToHex(mainSet)} ${JSON.stringify(setToList(mainSet))}`,
    `lmt_pcs_from_list(subset): ${setToHex(subsetSet)} ${JSON.stringify(setToList(subsetSet))}`,
    `lmt_pcs_to_list(main): ${JSON.stringify(roundTripList)}`,
    `lmt_pcs_cardinality(main): ${cardinality}`,
    `lmt_pcs_transpose(main, ${transpose}): ${setToHex(transposed)} ${JSON.stringify(setToList(transposed))}`,
    `lmt_pcs_invert(main): ${setToHex(inverted)} ${JSON.stringify(setToList(inverted))}`,
    `lmt_pcs_complement(main): ${setToHex(complement)} ${JSON.stringify(setToList(complement))}`,
    `lmt_pcs_is_subset(subset, main): ${isSubset}`,
  ].join("\n");
}

function resolveMainSet() {
  if (currentMainSet !== 0) return currentMainSet;

  const arena = new ScratchArena();
  const mainList = parseCsvIntegers(document.getElementById("pcs-main").value, 0, 11);
  const mainPtr = writeU8Array(arena, mainList);
  currentMainSet = wasm.lmt_pcs_from_list(mainPtr, mainList.length);
  return currentMainSet;
}

function runClassificationApis() {
  ensureWasmLoaded();
  const mainSet = resolveMainSet();

  const prime = wasm.lmt_prime_form(mainSet);
  const fortePrime = wasm.lmt_forte_prime(mainSet);
  const clusterFree = !!wasm.lmt_is_cluster_free(mainSet);
  const evenness = wasm.lmt_evenness_distance(mainSet);

  outClassification.textContent = [
    `input set: ${setToHex(mainSet)} ${JSON.stringify(setToList(mainSet))}`,
    `lmt_prime_form: ${setToHex(prime)} ${JSON.stringify(setToList(prime))}`,
    `lmt_forte_prime: ${setToHex(fortePrime)} ${JSON.stringify(setToList(fortePrime))}`,
    `lmt_is_cluster_free: ${clusterFree}`,
    `lmt_evenness_distance: ${evenness.toFixed(6)}`,
  ].join("\n");
}

function runScaleModeApis() {
  ensureWasmLoaded();

  const scaleType = getSelectValue("scale-type");
  const scaleTonic = getNumberInput("scale-tonic");
  const modeType = getSelectValue("mode-type");
  const modeRoot = getNumberInput("mode-root");
  const spellPc = getNumberInput("spell-pc");
  const keyTonic = getNumberInput("key-tonic");
  const keyQuality = getSelectValue("key-quality");
  const packedKeyCtx = packKeyContext(keyTonic, keyQuality);

  const scaleSet = wasm.lmt_scale(scaleType, scaleTonic);
  const modeSet = wasm.lmt_mode(modeType, modeRoot);
  const spelledViaStruct = readCString(wasm.lmt_spell_note(spellPc, packedKeyCtx));
  const spelledPtr = wasm.lmt_spell_note_parts(spellPc, keyTonic, keyQuality);
  const spelledViaParts = readCString(spelledPtr);

  outScaleMode.textContent = [
    `lmt_scale(type=${scaleType}, tonic=${scaleTonic}): ${setToHex(scaleSet)} ${JSON.stringify(setToList(scaleSet))}`,
    `lmt_mode(type=${modeType}, root=${modeRoot}): ${setToHex(modeSet)} ${JSON.stringify(setToList(modeSet))}`,
    `lmt_spell_note(pc=${spellPc}, key_ctx={tonic:${keyTonic},quality:${keyQuality}}): ${spelledViaStruct}`,
    `lmt_spell_note_parts(pc=${spellPc}, tonic=${keyTonic}, quality=${keyQuality}): ${spelledViaParts}`,
  ].join("\n");
}

function runChordApis() {
  ensureWasmLoaded();

  const chordType = getSelectValue("chord-type");
  const chordRoot = getNumberInput("chord-root");
  const romanKeyTonic = getNumberInput("roman-key-tonic");
  const romanKeyQuality = getSelectValue("roman-key-quality");
  const packedRomanCtx = packKeyContext(romanKeyTonic, romanKeyQuality);

  const chordSet = wasm.lmt_chord(chordType, chordRoot);
  const chordName = readCString(wasm.lmt_chord_name(chordSet));
  const romanViaStruct = readCString(wasm.lmt_roman_numeral(chordSet, packedRomanCtx));
  const romanNumeral = readCString(wasm.lmt_roman_numeral_parts(chordSet, romanKeyTonic, romanKeyQuality));

  outChord.textContent = [
    `lmt_chord(type=${chordType}, root=${chordRoot}): ${setToHex(chordSet)} ${JSON.stringify(setToList(chordSet))}`,
    `lmt_chord_name(chord_set): ${chordName}`,
    `lmt_roman_numeral(chord_set, key_ctx={tonic:${romanKeyTonic},quality:${romanKeyQuality}}): ${romanViaStruct}`,
    `lmt_roman_numeral_parts(chord_set, tonic=${romanKeyTonic}, quality=${romanKeyQuality}): ${romanNumeral}`,
  ].join("\n");
}

function runGuitarApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();

  const tuningValues = parseCsvIntegers(document.getElementById("guitar-tuning").value, 0, 127);
  if (tuningValues.length === 0) {
    throw new Error("Tuning must include at least one MIDI note");
  }
  const stringValue = getNumberInput("guitar-string");
  const fretValue = getNumberInput("guitar-fret");
  const midiValue = getNumberInput("guitar-midi");
  const maxFret = getNumberInput("guitar-max-fret");
  const maxSpan = getNumberInput("guitar-max-span");
  const guideMinFret = getNumberInput("guitar-guide-min-fret");
  const guideMaxFret = getNumberInput("guitar-guide-max-fret");
  const chordSet = resolveMainSet();
  const fretValues = parseCsvIntegers(document.getElementById("svg-frets").value, -1, 127);

  const tuningPtr = writeU8Array(arena, tuningValues);

  const fretToMidiGeneric = wasm.lmt_fret_to_midi_n(stringValue, fretValue, tuningPtr, tuningValues.length);
  const fretToMidiCompat = tuningValues.length === 6 ? wasm.lmt_fret_to_midi(stringValue, fretValue, tuningPtr) : null;

  const outPosPtr = arena.alloc(Math.max(1, tuningValues.length) * 2, 1);
  const posCount = wasm.lmt_midi_to_fret_positions_n(midiValue, tuningPtr, tuningValues.length, outPosPtr, tuningValues.length);
  const compatPosCount = tuningValues.length === 6 ? wasm.lmt_midi_to_fret_positions(midiValue, tuningPtr, outPosPtr) : null;

  const positions = [];
  const bytes = u8();
  for (let i = 0; i < posCount; i += 1) {
    positions.push({
      string: bytes[outPosPtr + i * 2],
      fret: bytes[outPosPtr + i * 2 + 1],
    });
  }

  const voicingRowCap = 64;
  const voicingPtr = arena.alloc(voicingRowCap * tuningValues.length, 1);
  const voicingCount = wasm.lmt_generate_voicings_n(
    chordSet,
    tuningPtr,
    tuningValues.length,
    maxFret,
    maxSpan,
    voicingPtr,
    voicingRowCap,
  );
  const previewVoicings = [];
  const fretBytes = i8();
  for (let row = 0; row < Math.min(voicingCount, 5); row += 1) {
    const start = voicingPtr + row * tuningValues.length;
    previewVoicings.push(Array.from(fretBytes.subarray(start, start + tuningValues.length)));
  }

  const selectedPositions = [];
  for (let stringIndex = 0; stringIndex < Math.min(fretValues.length, tuningValues.length); stringIndex += 1) {
    const selectedFret = fretValues[stringIndex];
    if (selectedFret >= 0) {
      selectedPositions.push({ string: stringIndex, fret: selectedFret });
    }
  }
  const selectedPtr = arena.alloc(Math.max(1, selectedPositions.length) * 2, 1);
  for (let index = 0; index < selectedPositions.length; index += 1) {
    bytes[selectedPtr + index * 2] = selectedPositions[index].string;
    bytes[selectedPtr + index * 2 + 1] = selectedPositions[index].fret;
  }

  const guideCap = 64;
  const guidePtr = arena.alloc(guideCap * GUIDE_DOT_BYTES, 4);
  const guideCount = wasm.lmt_pitch_class_guide_n(
    selectedPtr,
    selectedPositions.length,
    guideMinFret,
    guideMaxFret,
    tuningPtr,
    tuningValues.length,
    guidePtr,
    guideCap,
  );
  const guideView = new DataView(memory.buffer, guidePtr, Math.min(guideCount, guideCap) * GUIDE_DOT_BYTES);
  const guideDots = [];
  for (let index = 0; index < Math.min(guideCount, 8); index += 1) {
    const offset = index * GUIDE_DOT_BYTES;
    guideDots.push({
      string: guideView.getUint8(offset),
      fret: guideView.getUint8(offset + 1),
      pitch_class: guideView.getUint8(offset + 2),
      opacity: Number(guideView.getFloat32(offset + 4, true).toFixed(3)),
    });
  }

  const urlBufPtr = arena.alloc(256, 1);
  const fretsPtr = writeI8Array(arena, fretValues);
  const urlLength = wasm.lmt_frets_to_url_n(fretsPtr, fretValues.length, urlBufPtr, 256);
  const fretUrl = urlLength > 0 || fretValues.length === 0 ? readCString(urlBufPtr) : "<buffer-too-small>";
  const urlPtr = writeCString(arena, fretUrl);
  const parsedFretsPtr = arena.alloc(Math.max(1, fretValues.length), 1);
  const parsedCount = wasm.lmt_url_to_frets_n(urlPtr, parsedFretsPtr, fretValues.length);
  const parsedFrets = Array.from(i8().subarray(parsedFretsPtr, parsedFretsPtr + Math.min(parsedCount, fretValues.length)));

  const lines = [
    `lmt_fret_to_midi_n(string=${stringValue}, fret=${fretValue}, tuning_count=${tuningValues.length}): ${fretToMidiGeneric}`,
    `lmt_midi_to_fret_positions_n(note=${midiValue}, tuning_count=${tuningValues.length}): ${JSON.stringify(positions)}`,
    `lmt_generate_voicings_n(chord_set=${setToHex(chordSet)}, tuning_count=${tuningValues.length}, max_fret=${maxFret}, max_span=${maxSpan}): rows=${voicingCount}, preview=${JSON.stringify(previewVoicings)}`,
    `lmt_pitch_class_guide_n(selected=${JSON.stringify(selectedPositions)}, fret_range=${guideMinFret}-${guideMaxFret}, tuning_count=${tuningValues.length}): rows=${guideCount}, preview=${JSON.stringify(guideDots)}`,
    `lmt_frets_to_url_n(fret_count=${fretValues.length}): ${fretUrl}`,
    `lmt_url_to_frets_n(url): ${JSON.stringify(parsedFrets)}`,
  ];
  if (fretToMidiCompat !== null && compatPosCount !== null) {
    lines.push(`compat wrapper lmt_fret_to_midi(...): ${fretToMidiCompat}`);
    lines.push(`compat wrapper lmt_midi_to_fret_positions(...): ${compatPosCount} positions`);
  }

  outGuitar.textContent = lines.join("\n");
}

function runSvgApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();

  const mainSet = resolveMainSet();
  const chordType = getSelectValue("chord-type");
  const chordRoot = getNumberInput("chord-root");
  const fretValues = parseCsvIntegers(document.getElementById("svg-frets").value, -1, 127);
  if (fretValues.length === 0) {
    throw new Error("Fret diagram must include at least one string");
  }
  const tuningValues = parseCsvIntegers(document.getElementById("guitar-tuning").value, 0, 127);
  const tuningPtr = writeU8Array(arena, tuningValues);
  const windowStart = getNumberInput("svg-window-start");
  const visibleFrets = getNumberInput("svg-visible-frets");
  const fretMidiNotes = fretValues
    .map((fret, stringIndex) => (fret < 0 || stringIndex >= tuningValues.length ? null : wasm.lmt_fret_to_midi_n(stringIndex, fret, tuningPtr, tuningValues.length)))
    .filter((value) => value !== null);
  const staffMidiNotes = canonicalChordStaffMidiNotes(chordType, chordRoot);
  const aligned = tuningValues.length === fretValues.length && arraysEqual(fretMidiNotes, staffMidiNotes);

  const svgBufPtr = arena.alloc(C_STRING_CAPACITY, 1);

  const clockLen = wasm.lmt_svg_clock_optc(mainSet, svgBufPtr, C_STRING_CAPACITY);
  const clockSvg = readCString(svgBufPtr);

  const fretsPtr = writeI8Array(arena, fretValues);
  const fretLen = wasm.lmt_svg_fret_n(fretsPtr, fretValues.length, windowStart, visibleFrets, svgBufPtr, C_STRING_CAPACITY);
  const fretSvg = readCString(svgBufPtr);
  const compatFretLen = fretValues.length === 6 ? wasm.lmt_svg_fret(fretsPtr, svgBufPtr, C_STRING_CAPACITY) : null;

  const staffLen = wasm.lmt_svg_chord_staff(chordType, chordRoot, svgBufPtr, C_STRING_CAPACITY);
  const staffSvg = readCString(svgBufPtr);

  const lines = [
    `lmt_svg_clock_optc bytes: ${clockLen}`,
    `lmt_svg_fret_n bytes: ${fretLen}`,
    `lmt_svg_chord_staff bytes: ${staffLen}`,
    `string_count: ${fretValues.length}`,
    `window_start: ${windowStart}`,
    `visible_frets: ${visibleFrets}`,
    `fret voicing midi: ${JSON.stringify(fretMidiNotes)}`,
    `chord staff midi: ${JSON.stringify(staffMidiNotes)}`,
    `aligned: ${aligned ? "yes" : "no"}`,
  ];
  if (compatFretLen !== null) {
    lines.push(`compat wrapper lmt_svg_fret bytes: ${compatFretLen}`);
  }
  if (tuningValues.length !== fretValues.length) {
    lines.push("note: tuning/fret counts differ, so MIDI alignment is semantic-only for overlapping strings");
  }
  outSvgMeta.textContent = lines.join("\n");

  svgClockHost.innerHTML = clockSvg;
  svgFretHost.innerHTML = fretSvg;
  svgStaffHost.innerHTML = staffSvg;

  normalizeSvgPreview(svgClockHost);
  normalizeSvgPreview(svgFretHost);
  normalizeSvgPreview(svgStaffHost);
}

function canonicalChordStaffMidiNotes(chordType, chordRoot) {
  const rootMidi = 60 + (chordRoot % 12);
  switch (chordType) {
    case 1:
      return [rootMidi, rootMidi + 3, rootMidi + 7];
    case 2:
      return [rootMidi, rootMidi + 3, rootMidi + 6];
    case 3:
      return [rootMidi, rootMidi + 4, rootMidi + 8];
    default:
      return [rootMidi, rootMidi + 4, rootMidi + 7];
  }
}

function arraysEqual(a, b) {
  if (a.length !== b.length) return false;
  return a.every((value, index) => value === b[index]);
}

function normalizeSvgPreview(host) {
  const svg = host.querySelector("svg");
  if (!svg) return;

  svg.style.display = "block";
  svg.style.height = "auto";
  svg.style.maxWidth = "100%";
  svg.style.maxHeight = "160px";

  const originalViewBox = svg.getAttribute("viewBox");
  if (originalViewBox && !svg.dataset.originalViewBox) {
    svg.dataset.originalViewBox = originalViewBox;
  }

  try {
    const bbox = svg.getBBox();
    if (!Number.isFinite(bbox.width) || !Number.isFinite(bbox.height) || bbox.width <= 0 || bbox.height <= 0) {
      svg.dataset.previewNormalized = "0";
      return;
    }

    const aspect = bbox.width / bbox.height;
    if (aspect <= 1.5) {
      svg.style.width = "220px";
    } else if (aspect <= 2.8) {
      svg.style.width = "320px";
    } else {
      svg.style.width = "560px";
    }

    const padX = Math.max(4, bbox.width * 0.08);
    const padY = Math.max(4, bbox.height * 0.12);
    const viewBox = [
      (bbox.x - padX).toFixed(2),
      (bbox.y - padY).toFixed(2),
      (bbox.width + padX * 2).toFixed(2),
      (bbox.height + padY * 2).toFixed(2),
    ].join(" ");

    svg.setAttribute("viewBox", viewBox);
    svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
    svg.dataset.previewNormalized = "1";
  } catch (_error) {
    svg.dataset.previewNormalized = "0";
  }
}

function runAll() {
  const errors = [];
  currentMainSet = 0;

  const steps = [
    ["PCS APIs", runPcsApis, (err) => renderSectionError("PCS APIs", outPcs, err)],
    ["Classification APIs", runClassificationApis, (err) => renderSectionError("Classification APIs", outClassification, err)],
    ["Scale/Mode APIs", runScaleModeApis, (err) => renderSectionError("Scale/Mode APIs", outScaleMode, err)],
    ["Chord APIs", runChordApis, (err) => renderSectionError("Chord APIs", outChord, err)],
    ["Guitar APIs", runGuitarApis, (err) => renderSectionError("Guitar APIs", outGuitar, err)],
    ["SVG APIs", runSvgApis, (err) => {
      renderSectionError("SVG APIs", outSvgMeta, err);
      clearSvgHosts();
    }],
  ];

  for (const [label, fn, onError] of steps) {
    const error = executeSection(label, fn, onError);
    if (error) errors.push(error);
  }

  if (errors.length === 0) {
    setStatus("All sections rendered successfully.");
    return;
  }

  setStatus(`Run all completed with ${errors.length} section error(s): ${errors.join("; ")}`, "error");
}

async function instantiateWasm() {
  const wasmUrl = "./libmusictheory.wasm";

  if (WebAssembly.instantiateStreaming) {
    try {
      const streaming = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
      return streaming.instance;
    } catch (_error) {
      // Fallback below for dev servers without wasm MIME type.
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

function verifyExports(exportsObj) {
  const missing = REQUIRED_EXPORTS.filter((name) => !(name in exportsObj));
  if (missing.length > 0) {
    throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
  }
}

function wireUi() {
  document.getElementById("run-pcs").addEventListener("click", () => runSafe("PCS APIs", runPcsApis, (err) => renderSectionError("PCS APIs", outPcs, err)));
  document.getElementById("run-classification").addEventListener("click", () => runSafe("Classification APIs", runClassificationApis, (err) => renderSectionError("Classification APIs", outClassification, err)));
  document.getElementById("run-scale-mode").addEventListener("click", () => runSafe("Scale/Mode APIs", runScaleModeApis, (err) => renderSectionError("Scale/Mode APIs", outScaleMode, err)));
  document.getElementById("run-chord").addEventListener("click", () => runSafe("Chord APIs", runChordApis, (err) => renderSectionError("Chord APIs", outChord, err)));
  document.getElementById("run-guitar").addEventListener("click", () => runSafe("Guitar APIs", runGuitarApis, (err) => renderSectionError("Guitar APIs", outGuitar, err)));
  document.getElementById("run-svg").addEventListener("click", () => runSafe("SVG APIs", runSvgApis, (err) => {
    renderSectionError("SVG APIs", outSvgMeta, err);
    clearSvgHosts();
  }));
  document.getElementById("run-all").addEventListener("click", () => runSafe("All sections", runAll));
}

function runSafe(label, fn, onError = null) {
  const error = executeSection(label, fn, onError);
  if (error) {
    setStatus(`Error: ${error}`, "error");
    return;
  }

  if (label !== "All sections") {
    setStatus(`${label} rendered successfully.`);
  }
}

async function main() {
  try {
    const instance = await instantiateWasm();
    wasm = instance.exports;
    verifyExports(wasm);
    memory = wasm.memory;

    setStatus("WASM loaded. Interactive API calls are ready.");

    wireUi();
    runAll();
  } catch (err) {
    setStatus(`Failed to initialize: ${err.message}`, "error");
  }
}

main();
