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
  "lmt_midi_to_fret_positions",
  "lmt_svg_clock_optc",
  "lmt_svg_fret",
  "lmt_svg_chord_staff",
];

const SCRATCH_BASE = 1 << 20;
const C_STRING_CAPACITY = 64 * 1024;

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

  const tuningValues = parseCsvIntegers(document.getElementById("guitar-tuning").value, 0, 127, 6);
  const stringValue = getNumberInput("guitar-string");
  const fretValue = getNumberInput("guitar-fret");
  const midiValue = getNumberInput("guitar-midi");

  const tuningPtr = writeU8Array(arena, tuningValues);

  const fretToMidi = wasm.lmt_fret_to_midi(stringValue, fretValue, tuningPtr);

  const outPosPtr = arena.alloc(6 * 2, 1);
  const posCount = wasm.lmt_midi_to_fret_positions(midiValue, tuningPtr, outPosPtr);

  const positions = [];
  const bytes = u8();
  for (let i = 0; i < posCount; i += 1) {
    positions.push({
      string: bytes[outPosPtr + i * 2],
      fret: bytes[outPosPtr + i * 2 + 1],
    });
  }

  outGuitar.textContent = [
    `lmt_fret_to_midi(string=${stringValue}, fret=${fretValue}): ${fretToMidi}`,
    `lmt_midi_to_fret_positions(note=${midiValue}): ${JSON.stringify(positions)}`,
  ].join("\n");
}

function runSvgApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();

  const mainSet = resolveMainSet();
  const chordType = getSelectValue("chord-type");
  const chordRoot = getNumberInput("chord-root");
  const fretValues = parseCsvIntegers(document.getElementById("svg-frets").value, -1, 24, 6);

  const svgBufPtr = arena.alloc(C_STRING_CAPACITY, 1);

  const clockLen = wasm.lmt_svg_clock_optc(mainSet, svgBufPtr, C_STRING_CAPACITY);
  const clockSvg = readCString(svgBufPtr);

  const fretsPtr = writeI8Array(arena, fretValues);
  const fretLen = wasm.lmt_svg_fret(fretsPtr, svgBufPtr, C_STRING_CAPACITY);
  const fretSvg = readCString(svgBufPtr);

  const staffLen = wasm.lmt_svg_chord_staff(chordType, chordRoot, svgBufPtr, C_STRING_CAPACITY);
  const staffSvg = readCString(svgBufPtr);

  outSvgMeta.textContent = [
    `lmt_svg_clock_optc bytes: ${clockLen}`,
    `lmt_svg_fret bytes: ${fretLen}`,
    `lmt_svg_chord_staff bytes: ${staffLen}`,
  ].join("\n");

  svgClockHost.innerHTML = clockSvg;
  svgFretHost.innerHTML = fretSvg;
  svgStaffHost.innerHTML = staffSvg;
}

function runAll() {
  runPcsApis();
  runClassificationApis();
  runScaleModeApis();
  runChordApis();
  runGuitarApis();
  runSvgApis();
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
  document.getElementById("run-pcs").addEventListener("click", () => runSafe(runPcsApis));
  document.getElementById("run-classification").addEventListener("click", () => runSafe(runClassificationApis));
  document.getElementById("run-scale-mode").addEventListener("click", () => runSafe(runScaleModeApis));
  document.getElementById("run-chord").addEventListener("click", () => runSafe(runChordApis));
  document.getElementById("run-guitar").addEventListener("click", () => runSafe(runGuitarApis));
  document.getElementById("run-svg").addEventListener("click", () => runSafe(runSvgApis));
  document.getElementById("run-all").addEventListener("click", () => runSafe(runAll));
}

function runSafe(fn) {
  try {
    fn();
  } catch (err) {
    statusEl.textContent = `Error: ${err.message}`;
    statusEl.style.color = "#b03620";
  }
}

async function main() {
  try {
    const instance = await instantiateWasm();
    wasm = instance.exports;
    verifyExports(wasm);
    memory = wasm.memory;

    statusEl.textContent = "WASM loaded. Interactive API calls are ready.";
    statusEl.style.color = "#1f6c72";

    wireUi();
    runAll();
  } catch (err) {
    statusEl.textContent = `Failed to initialize: ${err.message}`;
    statusEl.style.color = "#b03620";
  }
}

main();
