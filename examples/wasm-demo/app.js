const statusEl = document.getElementById("status");

const outPcs = document.getElementById("out-pcs");
const outClassification = document.getElementById("out-classification");
const outScaleMode = document.getElementById("out-scale-mode");
const outChord = document.getElementById("out-chord");
const outGuitar = document.getElementById("out-guitar");
const outPlayability = document.getElementById("out-playability");
const outPhraseAudit = document.getElementById("out-phrase-audit");
const outSvgMeta = document.getElementById("out-svg-meta");

const svgClockHost = document.getElementById("svg-clock");
const svgOpticKHost = document.getElementById("svg-optic-k");
const svgEvennessHost = document.getElementById("svg-evenness");
const svgEvennessFieldHost = document.getElementById("svg-evenness-field");
const svgFretCompatHost = document.getElementById("svg-fret-compat");
const svgFretHost = document.getElementById("svg-fret");
const svgStaffHost = document.getElementById("svg-staff");
const svgKeyStaffHost = document.getElementById("svg-key-staff");
const svgKeyboardHost = document.getElementById("svg-keyboard");
const svgPianoStaffHost = document.getElementById("svg-piano-staff");

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
  "lmt_sizeof_hand_profile",
  "lmt_sizeof_voiced_history",
  "lmt_sizeof_voiced_state",
  "lmt_sizeof_ranked_keyboard_fingering",
  "lmt_sizeof_ranked_keyboard_next_step",
  "lmt_sizeof_ranked_keyboard_context_suggestion",
  "lmt_sizeof_playability_difficulty_summary",
  "lmt_sizeof_next_step_suggestion",
  "lmt_sizeof_keyboard_play_state",
  "lmt_sizeof_keyboard_transition_assessment",
  "lmt_sizeof_keyboard_phrase_event",
  "lmt_sizeof_keyboard_committed_phrase_memory",
  "lmt_sizeof_playability_phrase_issue",
  "lmt_sizeof_playability_phrase_summary",
  "lmt_sizeof_playability_repair_policy",
  "lmt_sizeof_ranked_keyboard_phrase_repair",
  "lmt_playability_phrase_issue_scope_name",
  "lmt_playability_phrase_issue_severity_name",
  "lmt_playability_phrase_family_domain_name",
  "lmt_playability_phrase_strain_bucket_name",
  "lmt_playability_repair_class_name",
  "lmt_keyboard_hand_name",
  "lmt_playability_reason_name",
  "lmt_playability_warning_name",
  "lmt_default_keyboard_hand_profile",
  "lmt_playability_profile_from_preset",
  "lmt_keyboard_committed_phrase_reset",
  "lmt_keyboard_committed_phrase_push",
  "lmt_keyboard_committed_phrase_len",
  "lmt_audit_keyboard_phrase_n",
  "lmt_audit_committed_keyboard_phrase_n",
  "lmt_default_playability_repair_policy",
  "lmt_rank_keyboard_phrase_repairs_n",
  "lmt_summarize_keyboard_realization_difficulty_n",
  "lmt_summarize_keyboard_transition_difficulty_n",
  "lmt_suggest_easier_keyboard_fingering_n",
  "lmt_filter_next_steps_by_playability",
  "lmt_rank_keyboard_next_steps_by_playability",
  "lmt_suggest_safer_keyboard_next_step_by_playability",
  "lmt_rank_keyboard_context_suggestions_by_committed_phrase",
  "lmt_rank_keyboard_next_steps_by_committed_phrase",
  "lmt_suggest_safer_keyboard_next_step_by_committed_phrase",
  "lmt_voiced_history_reset",
  "lmt_voiced_history_push",
  "lmt_svg_clock_optc",
  "lmt_svg_optic_k_group",
  "lmt_svg_evenness_chart",
  "lmt_svg_evenness_field",
  "lmt_svg_fret",
  "lmt_svg_fret_n",
  "lmt_svg_chord_staff",
  "lmt_svg_key_staff",
  "lmt_svg_keyboard",
  "lmt_svg_piano_staff",
];

const C_STRING_CAPACITY = 64 * 1024;
const GUIDE_DOT_BYTES = 8;
const encoder = new TextEncoder();
let jsScratchBase = 0;
let jsScratchTop = 0;
let jsScratchLimit = 0;

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
  svgOpticKHost.innerHTML = "";
  svgEvennessHost.innerHTML = "";
  svgEvennessFieldHost.innerHTML = "";
  svgFretCompatHost.innerHTML = "";
  svgFretHost.innerHTML = "";
  svgStaffHost.innerHTML = "";
  svgKeyStaffHost.innerHTML = "";
  svgKeyboardHost.innerHTML = "";
  svgPianoStaffHost.innerHTML = "";
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
    if (jsScratchBase === 0) {
      jsScratchBase = memory.buffer.byteLength;
      ensureMemory(jsScratchBase + 64 * 1024);
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

function formatMidiList(notes) {
  return `[${notes.join(", ")}]`;
}

function decodeHandProfile(ptr) {
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_hand_profile());
  return {
    fingerCount: view.getUint8(0),
    comfortSpanSteps: view.getUint8(1),
    limitSpanSteps: view.getUint8(2),
    comfortShiftSteps: view.getUint8(3),
    limitShiftSteps: view.getUint8(4),
    prefersLowTension: view.getUint8(5) === 1,
  };
}

function decodePlayabilityDifficultySummary(ptr) {
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_playability_difficulty_summary());
  return {
    accepted: view.getUint8(0) === 1,
    blockerCount: view.getUint8(1),
    warningCount: view.getUint8(2),
    reasonCount: view.getUint8(3),
    bottleneckCost: view.getUint16(4, true),
    cumulativeCost: view.getUint16(6, true),
    spanSteps: view.getUint8(8),
    shiftSteps: view.getUint8(9),
    loadEventCount: view.getUint8(10),
    peakRecentSpanSteps: view.getUint8(11),
    peakRecentShiftSteps: view.getUint8(12),
    comfortSpanMargin: view.getInt16(14, true),
    limitSpanMargin: view.getInt16(16, true),
    comfortShiftMargin: view.getInt16(18, true),
    limitShiftMargin: view.getInt16(20, true),
  };
}

function decodeRankedKeyboardFingering(ptr) {
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_ranked_keyboard_fingering());
  const noteCount = view.getUint8(1);
  return {
    hand: view.getUint8(0),
    noteCount,
    bottleneckCost: view.getUint16(4, true),
    cumulativeCost: view.getUint16(6, true),
    blockerBits: view.getUint32(8, true),
    warningBits: view.getUint32(12, true),
    reasonBits: view.getUint32(16, true),
    fingers: Array.from({ length: noteCount }, (_unused, index) => view.getUint8(20 + index)),
  };
}

function decodeRankedKeyboardNextStep(ptr) {
  const nextStepBytes = wasm.lmt_sizeof_next_step_suggestion();
  const transitionBytes = wasm.lmt_sizeof_keyboard_transition_assessment();
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_ranked_keyboard_next_step());
  const noteCount = view.getUint8(14);
  const notes = Array.from({ length: noteCount }, (_unused, index) => view.getUint8(20 + index));
  const metaBase = nextStepBytes + transitionBytes;
  const transitionBase = nextStepBytes + (wasm.lmt_sizeof_keyboard_play_state() * 2);
  return {
    notes,
    candidateIndex: view.getUint8(metaBase + 0),
    hand: view.getUint8(metaBase + 1),
    policy: view.getUint8(metaBase + 2),
    accepted: view.getUint8(metaBase + 3) === 1,
    bottleneckCost: view.getUint16(transitionBase + 4, true),
    cumulativeCost: view.getUint16(transitionBase + 6, true),
  };
}

function formatHandProfile(profile) {
  return `fingers=${profile.fingerCount}, comfort_span=${profile.comfortSpanSteps}, limit_span=${profile.limitSpanSteps}, comfort_shift=${profile.comfortShiftSteps}, limit_shift=${profile.limitShiftSteps}, prefers_low_tension=${profile.prefersLowTension}`;
}

function formatDifficultySummary(summary) {
  if (!summary) return "unavailable";
  return [
    summary.accepted ? "accepted" : "blocked",
    `blockers=${summary.blockerCount}`,
    `warnings=${summary.warningCount}`,
    `bottleneck=${summary.bottleneckCost}`,
    `strain=${summary.cumulativeCost}`,
    `span=${summary.spanSteps}`,
    `shift=${summary.shiftSteps}`,
    `span_margin=${summary.comfortSpanMargin}/${summary.limitSpanMargin}`,
    `shift_margin=${summary.comfortShiftMargin}/${summary.limitShiftMargin}`,
  ].join(", ");
}

function formatFingerAssignment(fingering) {
  if (!fingering) return "none";
  return `[${fingering.fingers.join(", ")}] bottleneck=${fingering.bottleneckCost} strain=${fingering.cumulativeCost}`;
}

function readExportedName(fnName, index, fallback) {
  const fn = wasm?.[fnName];
  if (typeof fn !== "function") return fallback;
  const ptr = fn(index >>> 0);
  if (!ptr) return fallback;
  return readCString(ptr);
}

function formatOptionalPhraseIndex(value) {
  return value === 0xffff ? "none" : String(value);
}

function parseKeyboardHandToken(token, fallback) {
  const normalized = String(token || "").trim().toUpperCase();
  if (normalized === "") return fallback;
  if (normalized === "0" || normalized === "L" || normalized === "LH" || normalized === "LEFT") return 0;
  if (normalized === "1" || normalized === "R" || normalized === "RH" || normalized === "RIGHT") return 1;
  throw new Error(`Unknown keyboard hand token: ${token}`);
}

function parseKeyboardPhraseEventSpec(raw, defaultHand) {
  const token = String(raw || "").trim();
  if (token.length === 0) {
    throw new Error("Phrase event must not be empty");
  }
  const parts = token.split("@");
  if (parts.length > 2) {
    throw new Error(`Invalid phrase event syntax: ${raw}`);
  }
  const notePart = parts[0].trim();
  const hand = parseKeyboardHandToken(parts[1], defaultHand);
  const notes = notePart
    .split("+")
    .map((one) => one.trim())
    .filter((one) => one.length > 0)
    .map((one) => Number.parseInt(one, 10));
  if (notes.length === 0 || notes.some((note) => Number.isNaN(note) || note < 0 || note > 127)) {
    throw new Error(`Invalid phrase event notes: ${raw}`);
  }
  return { notes, hand };
}

function parseKeyboardPhraseEvents(raw, defaultHand) {
  return String(raw || "")
    .split(";")
    .map((one) => one.trim())
    .filter((one) => one.length > 0)
    .map((one) => parseKeyboardPhraseEventSpec(one, defaultHand));
}

function keyboardPhraseEventNoteCapacity() {
  return wasm.lmt_sizeof_keyboard_phrase_event() - 4;
}

function writeKeyboardPhraseEventAt(ptr, event) {
  const eventBytes = wasm.lmt_sizeof_keyboard_phrase_event();
  const noteCap = keyboardPhraseEventNoteCapacity();
  if (event.notes.length > noteCap) {
    throw new Error(`Phrase event exceeds keyboard note capacity ${noteCap}`);
  }
  const bytes = u8();
  bytes.fill(0, ptr, ptr + eventBytes);
  bytes[ptr + 0] = event.notes.length;
  bytes[ptr + 1] = event.hand;
  bytes.set(event.notes, ptr + 4);
}

function writeKeyboardPhraseEvent(arena, event) {
  const ptr = arena.alloc(wasm.lmt_sizeof_keyboard_phrase_event(), 4);
  writeKeyboardPhraseEventAt(ptr, event);
  return ptr;
}

function writeKeyboardPhraseEventArray(arena, events) {
  const eventBytes = wasm.lmt_sizeof_keyboard_phrase_event();
  const ptr = arena.alloc(Math.max(1, events.length) * eventBytes, 4);
  for (let index = 0; index < events.length; index += 1) {
    writeKeyboardPhraseEventAt(ptr + index * eventBytes, events[index]);
  }
  return ptr;
}

function allocKeyboardCommittedPhraseMemory(arena) {
  const ptr = arena.alloc(wasm.lmt_sizeof_keyboard_committed_phrase_memory(), 4);
  u8().fill(0, ptr, ptr + wasm.lmt_sizeof_keyboard_committed_phrase_memory());
  wasm.lmt_keyboard_committed_phrase_reset(ptr);
  return ptr;
}

function decodeKeyboardPhraseEvent(ptr) {
  const noteCount = u8()[ptr + 0];
  return {
    noteCount,
    hand: u8()[ptr + 1],
    notes: Array.from(u8().subarray(ptr + 4, ptr + 4 + noteCount)),
  };
}

function decodePhraseIssue(ptr) {
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_playability_phrase_issue());
  return {
    scope: view.getUint8(0),
    severity: view.getUint8(1),
    familyDomain: view.getUint8(2),
    familyIndex: view.getUint8(3),
    eventIndex: view.getUint16(4, true),
    relatedEventIndex: view.getUint16(6, true),
    magnitude: view.getUint16(8, true),
  };
}

function decodePhraseSummary(ptr) {
  const summaryBytes = wasm.lmt_sizeof_playability_phrase_summary();
  const view = new DataView(memory.buffer, ptr, summaryBytes);
  return {
    eventCount: view.getUint16(0, true),
    issueCount: view.getUint16(2, true),
    firstBlockedEventIndex: view.getUint16(4, true),
    firstBlockedTransitionFromIndex: view.getUint16(6, true),
    firstBlockedTransitionToIndex: view.getUint16(8, true),
    bottleneckIssueIndex: view.getUint16(10, true),
    bottleneckMagnitude: view.getUint16(12, true),
    bottleneckSeverity: view.getUint8(14),
    bottleneckDomain: view.getUint8(15),
    bottleneckFamilyIndex: view.getUint8(16),
    strainBucket: view.getUint8(17),
    dominantReasonFamily: view.getUint8(18),
    dominantWarningFamily: view.getUint8(19),
    recoveryDeficitStartIndex: view.getUint16(summaryBytes - 6, true),
    recoveryDeficitEndIndex: view.getUint16(summaryBytes - 4, true),
    longestRecoveryDeficitRun: view.getUint16(summaryBytes - 2, true),
  };
}

function decodeRankedKeyboardPhraseRepair(ptr) {
  const summaryBytes = wasm.lmt_sizeof_playability_phrase_summary();
  const beforePtr = ptr + 28;
  const afterPtr = beforePtr + summaryBytes;
  const replacementPtr = afterPtr + summaryBytes;
  const view = new DataView(memory.buffer, ptr, wasm.lmt_sizeof_ranked_keyboard_phrase_repair());
  return {
    repairClass: view.getUint8(0),
    changedFromIndex: view.getUint8(1),
    changedToIndex: view.getUint8(2),
    changedFromValue: view.getUint8(3),
    changedToValue: view.getUint8(4),
    crossedBoundary: view.getUint8(5) === 1,
    hand: view.getUint8(6),
    targetEventIndex: view.getUint16(8, true),
    preservedMask: view.getUint32(12, true),
    changeMask: view.getUint32(16, true),
    bottleneckLift: view.getInt16(20, true),
    issueLift: view.getInt16(22, true),
    blockedIssueLift: view.getInt16(24, true),
    warningIssueLift: view.getInt16(26, true),
    beforeSummary: decodePhraseSummary(beforePtr),
    afterSummary: decodePhraseSummary(afterPtr),
    replacementEvent: decodeKeyboardPhraseEvent(replacementPtr),
  };
}

function decodeRankedKeyboardContextSuggestionRow(ptr) {
  if (!ptr) return null;
  const rowBytes = wasm.lmt_sizeof_ranked_keyboard_context_suggestion();
  const transitionBytes = wasm.lmt_sizeof_keyboard_transition_assessment();
  const metaBytes = 6;
  const contextSuggestionBytes = rowBytes - transitionBytes - metaBytes;
  const view = new DataView(memory.buffer, ptr, rowBytes);
  const metaBase = contextSuggestionBytes + transitionBytes;
  return {
    realizedNote: view.getUint8(metaBase + 0),
    candidateIndex: view.getUint8(metaBase + 1),
    hand: view.getUint8(metaBase + 2),
    policy: view.getUint8(metaBase + 3),
    accepted: view.getUint8(metaBase + 4) === 1,
  };
}

function phraseIssueFamilyLabel(domain, familyIndex) {
  const domainLabel = readExportedName(
    "lmt_playability_phrase_family_domain_name",
    domain,
    `domain#${domain}`,
  );
  if (domainLabel.includes("reason")) {
    return readExportedName("lmt_playability_reason_name", familyIndex, `${domainLabel}#${familyIndex}`);
  }
  if (domainLabel.includes("warning")) {
    return readExportedName("lmt_playability_warning_name", familyIndex, `${domainLabel}#${familyIndex}`);
  }
  return `${domainLabel}#${familyIndex}`;
}

function keyboardHandLabelFull(hand) {
  return readExportedName("lmt_keyboard_hand_name", hand, hand === 0 ? "LEFT" : "RIGHT");
}

function formatKeyboardPhraseEvent(event) {
  return `${formatMidiList(event.notes)} @ ${keyboardHandLabelFull(event.hand)}`;
}

function formatPhraseIssue(issue) {
  const scope = readExportedName("lmt_playability_phrase_issue_scope_name", issue.scope, `scope#${issue.scope}`);
  const severity = readExportedName("lmt_playability_phrase_issue_severity_name", issue.severity, `severity#${issue.severity}`);
  const family = phraseIssueFamilyLabel(issue.familyDomain, issue.familyIndex);
  if (scope === "transition") {
    return `${scope} ${severity}: ${family} at ${issue.eventIndex}->${issue.relatedEventIndex} magnitude=${issue.magnitude}`;
  }
  return `${scope} ${severity}: ${family} at ${issue.eventIndex} magnitude=${issue.magnitude}`;
}

function formatPhraseSummary(summary) {
  const strain = readExportedName(
    "lmt_playability_phrase_strain_bucket_name",
    summary.strainBucket,
    `bucket#${summary.strainBucket}`,
  );
  const bottleneckSeverity = readExportedName(
    "lmt_playability_phrase_issue_severity_name",
    summary.bottleneckSeverity,
    `severity#${summary.bottleneckSeverity}`,
  );
  const bottleneckFamily = phraseIssueFamilyLabel(summary.bottleneckDomain, summary.bottleneckFamilyIndex);
  const dominantReason = summary.dominantReasonFamily === 0xff
    ? "none"
    : readExportedName("lmt_playability_reason_name", summary.dominantReasonFamily, `reason#${summary.dominantReasonFamily}`);
  const dominantWarning = summary.dominantWarningFamily === 0xff
    ? "none"
    : readExportedName("lmt_playability_warning_name", summary.dominantWarningFamily, `warning#${summary.dominantWarningFamily}`);
  return [
    `events=${summary.eventCount}`,
    `issues=${summary.issueCount}`,
    `first_blocked_event=${formatOptionalPhraseIndex(summary.firstBlockedEventIndex)}`,
    `first_blocked_transition=${formatOptionalPhraseIndex(summary.firstBlockedTransitionFromIndex)}->${formatOptionalPhraseIndex(summary.firstBlockedTransitionToIndex)}`,
    `bottleneck=${bottleneckSeverity}:${bottleneckFamily} magnitude=${summary.bottleneckMagnitude}`,
    `dominant_reason=${dominantReason}`,
    `dominant_warning=${dominantWarning}`,
    `recovery_deficit=${formatOptionalPhraseIndex(summary.recoveryDeficitStartIndex)}->${formatOptionalPhraseIndex(summary.recoveryDeficitEndIndex)} run=${summary.longestRecoveryDeficitRun}`,
    `strain=${strain}`,
  ].join(", ");
}

function formatPhraseRepair(repair) {
  if (!repair) return "none";
  const repairClass = readExportedName(
    "lmt_playability_repair_class_name",
    repair.repairClass,
    `repair#${repair.repairClass}`,
  );
  return [
    `class=${repairClass}`,
    `crossed_boundary=${repair.crossedBoundary}`,
    `target_event=${repair.targetEventIndex}`,
    `replacement=${formatKeyboardPhraseEvent(repair.replacementEvent)}`,
    `bottleneck_lift=${repair.bottleneckLift}`,
    `issue_lift=${repair.issueLift}`,
    `blocked_issue_lift=${repair.blockedIssueLift}`,
    `warning_issue_lift=${repair.warningIssueLift}`,
  ].join(", ");
}

function packKeyContext(tonic, quality) {
  return (tonic & 0xff) | ((quality & 0xff) << 8);
}

function setToList(setValue) {
  ensureWasmLoaded();
  const arena = new ScratchArena();
  try {
    const outPtr = arena.alloc(12, 1);
    const count = wasm.lmt_pcs_to_list(setValue, outPtr);
    return Array.from(u8().subarray(outPtr, outPtr + count));
  } finally {
    arena.release();
  }
}

function runPcsApis() {
  ensureWasmLoaded();
  currentMainSet = 0;
  const arena = new ScratchArena();
  try {
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
  } finally {
    arena.release();
  }
}

function resolveMainSet() {
  if (currentMainSet !== 0) return currentMainSet;

  const arena = new ScratchArena();
  try {
    const mainList = parseCsvIntegers(document.getElementById("pcs-main").value, 0, 11);
    const mainPtr = writeU8Array(arena, mainList);
    currentMainSet = wasm.lmt_pcs_from_list(mainPtr, mainList.length);
    return currentMainSet;
  } finally {
    arena.release();
  }
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
  try {
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
  } finally {
    arena.release();
  }
}

function runPlayabilityApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();
  try {
    const notes = parseCsvIntegers(document.getElementById("playability-notes").value, 0, 127);
    if (notes.length === 0) {
      throw new Error("Playability notes must include at least one MIDI note");
    }
    const previousNotes = parseCsvIntegers(document.getElementById("playability-prev-notes").value, 0, 127);
    const hand = getSelectValue("playability-hand");
    const preset = getSelectValue("playability-preset");
    const policy = getSelectValue("playability-policy");
    const counterpointProfile = getSelectValue("playability-counterpoint-profile");
    const tonic = getNumberInput("playability-tonic");
    const modeType = getSelectValue("playability-mode");

    const baseProfilePtr = arena.alloc(wasm.lmt_sizeof_hand_profile(), 4);
    if (!wasm.lmt_default_keyboard_hand_profile(baseProfilePtr)) {
      throw new Error("lmt_default_keyboard_hand_profile failed");
    }
    const tunedProfilePtr = arena.alloc(wasm.lmt_sizeof_hand_profile(), 4);
    if (!wasm.lmt_playability_profile_from_preset(preset, baseProfilePtr, tunedProfilePtr)) {
      throw new Error("lmt_playability_profile_from_preset failed");
    }

    const notesPtr = writeU8Array(arena, notes);
    const previousNotesPtr = previousNotes.length > 0 ? writeU8Array(arena, previousNotes) : 0;

    const realizationPtr = arena.alloc(wasm.lmt_sizeof_playability_difficulty_summary(), 4);
    const wroteRealization = wasm.lmt_summarize_keyboard_realization_difficulty_n(
      notesPtr,
      notes.length,
      hand,
      tunedProfilePtr,
      0,
      realizationPtr,
    );
    const realization = wroteRealization ? decodePlayabilityDifficultySummary(realizationPtr) : null;

    const transitionPtr = arena.alloc(wasm.lmt_sizeof_playability_difficulty_summary(), 4);
    const wroteTransition = previousNotes.length > 0
      ? wasm.lmt_summarize_keyboard_transition_difficulty_n(
        previousNotesPtr,
        previousNotes.length,
        notesPtr,
        notes.length,
        hand,
        tunedProfilePtr,
        0,
        transitionPtr,
      )
      : 0;
    const transition = wroteTransition ? decodePlayabilityDifficultySummary(transitionPtr) : null;

    const fingeringPtr = arena.alloc(wasm.lmt_sizeof_ranked_keyboard_fingering(), 4);
    const wroteFingering = wasm.lmt_suggest_easier_keyboard_fingering_n(
      notesPtr,
      notes.length,
      hand,
      tunedProfilePtr,
      fingeringPtr,
    );
    const easierFingering = wroteFingering ? decodeRankedKeyboardFingering(fingeringPtr) : null;

    const historyPtr = arena.alloc(wasm.lmt_sizeof_voiced_history(), 4);
    wasm.lmt_voiced_history_reset(historyPtr);
    const statePtr = arena.alloc(wasm.lmt_sizeof_voiced_state(), 4);
    if (previousNotes.length > 0) {
      wasm.lmt_voiced_history_push(
        historyPtr,
        previousNotesPtr,
        previousNotes.length,
        0,
        0,
        tonic,
        modeType,
        0,
        4,
        0,
        0,
        statePtr,
      );
    }
    if (!wasm.lmt_voiced_history_push(
      historyPtr,
      notesPtr,
      notes.length,
      0,
      0,
      tonic,
      modeType,
      1,
      4,
      0,
      0,
      statePtr,
    )) {
      throw new Error("lmt_voiced_history_push failed for current notes");
    }

    const filteredCap = 8;
    const filteredPtr = arena.alloc(wasm.lmt_sizeof_next_step_suggestion() * filteredCap, 4);
    const filteredCount = wasm.lmt_filter_next_steps_by_playability(
      historyPtr,
      counterpointProfile,
      hand,
      tunedProfilePtr,
      policy,
      filteredPtr,
      filteredCap,
    );

    const rankedPtr = arena.alloc(wasm.lmt_sizeof_ranked_keyboard_next_step() * filteredCap, 4);
    const rankedCount = wasm.lmt_rank_keyboard_next_steps_by_playability(
      historyPtr,
      counterpointProfile,
      hand,
      tunedProfilePtr,
      policy,
      rankedPtr,
      filteredCap,
    );
    const topRanked = rankedCount > 0 ? decodeRankedKeyboardNextStep(rankedPtr) : null;

    const saferPtr = arena.alloc(wasm.lmt_sizeof_ranked_keyboard_next_step(), 4);
    const wroteSafer = wasm.lmt_suggest_safer_keyboard_next_step_by_playability(
      historyPtr,
      counterpointProfile,
      hand,
      tunedProfilePtr,
      policy,
      saferPtr,
    );
    const safer = wroteSafer ? decodeRankedKeyboardNextStep(saferPtr) : null;

    const saferSummaryPtr = arena.alloc(wasm.lmt_sizeof_playability_difficulty_summary(), 4);
    const saferNotesPtr = safer ? writeU8Array(arena, safer.notes) : 0;
    const wroteSaferSummary = safer
      ? wasm.lmt_summarize_keyboard_transition_difficulty_n(
        notesPtr,
        notes.length,
        saferNotesPtr,
        safer.notes.length,
        hand,
        tunedProfilePtr,
        0,
        saferSummaryPtr,
      )
      : 0;
    const saferSummary = wroteSaferSummary ? decodePlayabilityDifficultySummary(saferSummaryPtr) : null;

    const baseProfile = decodeHandProfile(baseProfilePtr);
    const tunedProfile = decodeHandProfile(tunedProfilePtr);

    outPlayability.textContent = [
      `lmt_default_keyboard_hand_profile: ${formatHandProfile(baseProfile)}`,
      `lmt_playability_profile_from_preset(preset=${preset}): ${formatHandProfile(tunedProfile)}`,
      `current notes: ${formatMidiList(notes)}`,
      `previous notes: ${formatMidiList(previousNotes)}`,
      `lmt_summarize_keyboard_realization_difficulty_n: ${formatDifficultySummary(realization)}`,
      `lmt_summarize_keyboard_transition_difficulty_n: ${formatDifficultySummary(transition)}`,
      `lmt_suggest_easier_keyboard_fingering_n: ${formatFingerAssignment(easierFingering)}`,
      `lmt_filter_next_steps_by_playability: accepted=${filteredCount}`,
      topRanked
        ? `lmt_rank_keyboard_next_steps_by_playability: top notes=${formatMidiList(topRanked.notes)} accepted=${topRanked.accepted} bottleneck=${topRanked.bottleneckCost} strain=${topRanked.cumulativeCost}`
        : "lmt_rank_keyboard_next_steps_by_playability: none",
      safer
        ? `lmt_suggest_safer_keyboard_next_step_by_playability: notes=${formatMidiList(safer.notes)} accepted=${safer.accepted} candidate_index=${safer.candidateIndex}`
        : "lmt_suggest_safer_keyboard_next_step_by_playability: none",
      `safer transition summary: ${formatDifficultySummary(saferSummary)}`,
      "LLM framing: explain the preset as a hand-span assumption, the summary as blocker/warning evidence, and the safer step as an opt-in playable continuation rather than a hidden preference.",
    ].join("\n");
  } finally {
    arena.release();
  }
}

function runPhraseAuditApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();
  try {
    const defaultHand = getSelectValue("phrase-hand");
    const preset = getSelectValue("phrase-preset");
    const policy = getSelectValue("phrase-policy");
    const phraseEvents = parseKeyboardPhraseEvents(document.getElementById("phrase-events").value, defaultHand);
    const previewEvent = parseKeyboardPhraseEventSpec(document.getElementById("phrase-preview-event").value, defaultHand);
    const commitEvent = parseKeyboardPhraseEventSpec(document.getElementById("phrase-commit-event").value, defaultHand);

    if (phraseEvents.length === 0) {
      throw new Error("Phrase events must include at least one realized event");
    }

    const baseProfilePtr = arena.alloc(wasm.lmt_sizeof_hand_profile(), 4);
    if (!wasm.lmt_default_keyboard_hand_profile(baseProfilePtr)) {
      throw new Error("lmt_default_keyboard_hand_profile failed");
    }
    const tunedProfilePtr = arena.alloc(wasm.lmt_sizeof_hand_profile(), 4);
    if (!wasm.lmt_playability_profile_from_preset(preset, baseProfilePtr, tunedProfilePtr)) {
      throw new Error("lmt_playability_profile_from_preset failed");
    }

    const issueBytes = wasm.lmt_sizeof_playability_phrase_issue();
    const summaryBytes = wasm.lmt_sizeof_playability_phrase_summary();
    const issuesCap = 64;

    const phraseEventsPtr = writeKeyboardPhraseEventArray(arena, phraseEvents);
    const phraseIssuesPtr = arena.alloc(issueBytes * issuesCap, 4);
    const phraseSummaryPtr = arena.alloc(summaryBytes, 4);
    u8().fill(0, phraseIssuesPtr, phraseIssuesPtr + issueBytes * issuesCap);
    u8().fill(0, phraseSummaryPtr, phraseSummaryPtr + summaryBytes);

    const logicalPhraseIssues = wasm.lmt_audit_keyboard_phrase_n(
      phraseEventsPtr,
      phraseEvents.length,
      tunedProfilePtr,
      phraseIssuesPtr,
      issuesCap,
      phraseSummaryPtr,
    );
    const phraseSummary = decodePhraseSummary(phraseSummaryPtr);
    const phraseIssuePreview = Array.from(
      { length: Math.min(logicalPhraseIssues, issuesCap, 3) },
      (_unused, index) => formatPhraseIssue(decodePhraseIssue(phraseIssuesPtr + index * issueBytes)),
    );

    const committedMemoryPtr = allocKeyboardCommittedPhraseMemory(arena);
    const committedLenBeforePreview = wasm.lmt_keyboard_committed_phrase_len(committedMemoryPtr);
    const committedLenAfterPreview = wasm.lmt_keyboard_committed_phrase_len(committedMemoryPtr);
    const commitEventPtr = writeKeyboardPhraseEvent(arena, commitEvent);
    const committedLenAfterCommit = wasm.lmt_keyboard_committed_phrase_push(committedMemoryPtr, commitEventPtr);

    const committedIssuesPtr = arena.alloc(issueBytes * issuesCap, 4);
    const committedSummaryPtr = arena.alloc(summaryBytes, 4);
    u8().fill(0, committedIssuesPtr, committedIssuesPtr + issueBytes * issuesCap);
    u8().fill(0, committedSummaryPtr, committedSummaryPtr + summaryBytes);
    const logicalCommittedIssues = wasm.lmt_audit_committed_keyboard_phrase_n(
      committedMemoryPtr,
      tunedProfilePtr,
      committedIssuesPtr,
      issuesCap,
      committedSummaryPtr,
    );
    const committedSummary = decodePhraseSummary(committedSummaryPtr);

    const cMajorRootPtr = writeU8Array(arena, [0]);
    const cMajorRootSet = wasm.lmt_pcs_from_list(cMajorRootPtr, 1);
    const contextCap = 4;
    const contextBytes = wasm.lmt_sizeof_ranked_keyboard_context_suggestion();
    const contextPtr = arena.alloc(contextBytes * contextCap, 4);
    const logicalContext = wasm.lmt_rank_keyboard_context_suggestions_by_committed_phrase(
      committedMemoryPtr,
      cMajorRootSet,
      0,
      0,
      tunedProfilePtr,
      policy,
      contextPtr,
      contextCap,
    );
    const topCommittedContext = logicalContext > 0 ? decodeRankedKeyboardContextSuggestionRow(contextPtr) : null;

    const repairPolicyBytes = wasm.lmt_sizeof_playability_repair_policy();
    const repairRowBytes = wasm.lmt_sizeof_ranked_keyboard_phrase_repair();
    const repairCap = 8;

    const realizationMemoryPtr = allocKeyboardCommittedPhraseMemory(arena);
    for (const event of [
      { notes: [72], hand: 1 },
      { notes: [48], hand: 1 },
    ]) {
      wasm.lmt_keyboard_committed_phrase_push(realizationMemoryPtr, writeKeyboardPhraseEvent(arena, event));
    }
    const realizationPolicyPtr = arena.alloc(repairPolicyBytes, 4);
    if (!wasm.lmt_default_playability_repair_policy(0, realizationPolicyPtr)) {
      throw new Error("lmt_default_playability_repair_policy failed for realization_only");
    }
    const realizationRepairsPtr = arena.alloc(repairRowBytes * repairCap, 4);
    const realizationRepairCount = wasm.lmt_rank_keyboard_phrase_repairs_n(
      realizationMemoryPtr,
      tunedProfilePtr,
      realizationPolicyPtr,
      realizationRepairsPtr,
      repairCap,
    );
    const realizationRepair = realizationRepairCount > 0
      ? decodeRankedKeyboardPhraseRepair(realizationRepairsPtr)
      : null;

    const textureMemoryPtr = allocKeyboardCommittedPhraseMemory(arena);
    for (const event of [
      { notes: [72], hand: 1 },
      { notes: [60, 72], hand: 1 },
    ]) {
      wasm.lmt_keyboard_committed_phrase_push(textureMemoryPtr, writeKeyboardPhraseEvent(arena, event));
    }
    const texturePolicyPtr = arena.alloc(repairPolicyBytes, 4);
    if (!wasm.lmt_default_playability_repair_policy(2, texturePolicyPtr)) {
      throw new Error("lmt_default_playability_repair_policy failed for texture_reduced");
    }
    const textureRepairsPtr = arena.alloc(repairRowBytes * repairCap, 4);
    const textureRepairCount = wasm.lmt_rank_keyboard_phrase_repairs_n(
      textureMemoryPtr,
      tunedProfilePtr,
      texturePolicyPtr,
      textureRepairsPtr,
      repairCap,
    );
    let musicChangingRepair = null;
    for (let index = 0; index < Math.min(textureRepairCount, repairCap); index += 1) {
      const candidate = decodeRankedKeyboardPhraseRepair(textureRepairsPtr + index * repairRowBytes);
      if (candidate.crossedBoundary) {
        musicChangingRepair = candidate;
        break;
      }
    }
    if (!musicChangingRepair && textureRepairCount > 0) {
      musicChangingRepair = decodeRankedKeyboardPhraseRepair(textureRepairsPtr);
    }

    outPhraseAudit.textContent = [
      `lmt_audit_keyboard_phrase_n: ${formatPhraseSummary(phraseSummary)}`,
      `audit input events: ${phraseEvents.map((event) => formatKeyboardPhraseEvent(event)).join(" ; ")}`,
      ...phraseIssuePreview.map((line, index) => `issue[${index}]: ${line}`),
      `preview versus commit: preview=${formatKeyboardPhraseEvent(previewEvent)} commit=${formatKeyboardPhraseEvent(commitEvent)}`,
      `preview remains host-only: committed_len ${committedLenBeforePreview} -> ${committedLenAfterPreview}`,
      `lmt_keyboard_committed_phrase_push(commit): committed_len=${committedLenAfterCommit}`,
      `lmt_audit_committed_keyboard_phrase_n: ${formatPhraseSummary(committedSummary)} (logical_issues=${logicalCommittedIssues})`,
      topCommittedContext
        ? `lmt_rank_keyboard_context_suggestions_by_committed_phrase: top realized_note=${topCommittedContext.realizedNote} hand=${keyboardHandLabelFull(topCommittedContext.hand)} accepted=${topCommittedContext.accepted} candidate_index=${topCommittedContext.candidateIndex}`
        : "lmt_rank_keyboard_context_suggestions_by_committed_phrase: none",
      "host adoption note: use lmt_rank_keyboard_next_steps_by_committed_phrase or lmt_suggest_safer_keyboard_next_step_by_committed_phrase when accepted phrase memory should bias later theory-valid continuations.",
      realizationRepair
        ? `lmt_rank_keyboard_phrase_repairs_n (realization-only repair): ${formatPhraseRepair(realizationRepair)}`
        : "lmt_rank_keyboard_phrase_repairs_n (realization-only repair): none",
      realizationRepair
        ? `realization-only repair summary: before={${formatPhraseSummary(realizationRepair.beforeSummary)}} after={${formatPhraseSummary(realizationRepair.afterSummary)}}`
        : "realization-only repair summary: none",
      musicChangingRepair
        ? `lmt_rank_keyboard_phrase_repairs_n (music-changing repair): ${formatPhraseRepair(musicChangingRepair)}`
        : "lmt_rank_keyboard_phrase_repairs_n (music-changing repair): none",
      musicChangingRepair
        ? `music-changing repair summary: before={${formatPhraseSummary(musicChangingRepair.beforeSummary)}} after={${formatPhraseSummary(musicChangingRepair.afterSummary)}}`
        : "music-changing repair summary: none",
      "LLM framing: audit fixed realizations first, treat preview as host-only inspection, commit accepted events explicitly into library memory, and say out loud when a repair stayed realization-only versus crossed into a music-changing compromise.",
    ].join("\n");
  } finally {
    arena.release();
  }
}

function runSvgApis() {
  ensureWasmLoaded();
  const arena = new ScratchArena();
  try {
    const mainSet = resolveMainSet();
    const chordType = getSelectValue("chord-type");
    const chordRoot = getNumberInput("chord-root");
    const keyTonic = getNumberInput("key-tonic");
    const keyQuality = getSelectValue("key-quality");
    const fretValues = parseCsvIntegers(document.getElementById("svg-frets").value, -1, 127);
    const keyboardNotes = parseCsvIntegers(document.getElementById("svg-keyboard-notes").value, 0, 127);
    const keyboardLow = getNumberInput("svg-keyboard-low");
    const keyboardHigh = getNumberInput("svg-keyboard-high");
    if (fretValues.length === 0) {
      throw new Error("Fret diagram must include at least one string");
    }
    const tuningValues = parseCsvIntegers(document.getElementById("guitar-tuning").value, 0, 127);
    const tuningPtr = writeU8Array(arena, tuningValues);
    const windowStart = getNumberInput("svg-window-start");
    const visibleFrets = getNumberInput("svg-visible-frets");
    const pianoStaffNotes = [43, 52, 60, 64];
    const fretMidiNotes = fretValues
      .map((fret, stringIndex) => (fret < 0 || stringIndex >= tuningValues.length ? null : wasm.lmt_fret_to_midi_n(stringIndex, fret, tuningPtr, tuningValues.length)))
      .filter((value) => value !== null);
    const staffMidiNotes = canonicalChordStaffMidiNotes(chordType, chordRoot);
    const aligned = tuningValues.length === fretValues.length && arraysEqual(fretMidiNotes, staffMidiNotes);

    const svgBufPtr = arena.alloc(C_STRING_CAPACITY, 1);

    const clockLen = wasm.lmt_svg_clock_optc(mainSet, svgBufPtr, C_STRING_CAPACITY);
    const clockSvg = readCString(svgBufPtr);

    const opticKLen = wasm.lmt_svg_optic_k_group(mainSet, svgBufPtr, C_STRING_CAPACITY);
    const opticKSvg = readCString(svgBufPtr);

    const evennessLen = wasm.lmt_svg_evenness_chart(svgBufPtr, C_STRING_CAPACITY);
    const evennessSvg = readCString(svgBufPtr);
    const evennessFieldLen = wasm.lmt_svg_evenness_field(mainSet, svgBufPtr, C_STRING_CAPACITY);
    const evennessFieldSvg = readCString(svgBufPtr);

    const fretsPtr = writeI8Array(arena, fretValues);
    const compatFretLen = fretValues.length === 6 ? wasm.lmt_svg_fret(fretsPtr, svgBufPtr, C_STRING_CAPACITY) : null;
    const compatFretSvg = compatFretLen !== null ? readCString(svgBufPtr) : "";
    const fretLen = wasm.lmt_svg_fret_n(fretsPtr, fretValues.length, windowStart, visibleFrets, svgBufPtr, C_STRING_CAPACITY);
    const fretSvg = readCString(svgBufPtr);

    const staffLen = wasm.lmt_svg_chord_staff(chordType, chordRoot, svgBufPtr, C_STRING_CAPACITY);
    const staffSvg = readCString(svgBufPtr);

    const keyStaffLen = wasm.lmt_svg_key_staff(keyTonic, keyQuality, svgBufPtr, C_STRING_CAPACITY);
    const keyStaffSvg = readCString(svgBufPtr);

    const keyboardPtr = writeU8Array(arena, keyboardNotes);
    const keyboardLen = wasm.lmt_svg_keyboard(keyboardPtr, keyboardNotes.length, keyboardLow, keyboardHigh, svgBufPtr, C_STRING_CAPACITY);
    const keyboardSvg = readCString(svgBufPtr);
    const pianoStaffPtr = writeU8Array(arena, pianoStaffNotes);
    const pianoStaffLen = wasm.lmt_svg_piano_staff(pianoStaffPtr, pianoStaffNotes.length, keyTonic, keyQuality, svgBufPtr, C_STRING_CAPACITY);
    const pianoStaffSvg = readCString(svgBufPtr);

    const lines = [
      `lmt_svg_clock_optc bytes: ${clockLen}`,
      `lmt_svg_optic_k_group bytes: ${opticKLen}`,
      `lmt_svg_evenness_chart bytes: ${evennessLen}`,
      `lmt_svg_evenness_field bytes: ${evennessFieldLen}`,
      compatFretLen !== null ? `lmt_svg_fret bytes: ${compatFretLen}` : `lmt_svg_fret bytes: unavailable for string_count=${fretValues.length}`,
      `lmt_svg_fret_n bytes: ${fretLen}`,
      `lmt_svg_chord_staff bytes: ${staffLen}`,
      `lmt_svg_key_staff bytes: ${keyStaffLen}`,
      `lmt_svg_keyboard bytes: ${keyboardLen}`,
      `lmt_svg_piano_staff bytes: ${pianoStaffLen}`,
      `string_count: ${fretValues.length}`,
      `window_start: ${windowStart}`,
      `visible_frets: ${visibleFrets}`,
      `keyboard notes: ${JSON.stringify(keyboardNotes)}`,
      `piano staff notes: ${JSON.stringify(pianoStaffNotes)}`,
      `keyboard range: ${Math.min(keyboardLow, keyboardHigh)}-${Math.max(keyboardLow, keyboardHigh)}`,
      `fret voicing midi: ${JSON.stringify(fretMidiNotes)}`,
      `chord staff midi: ${JSON.stringify(staffMidiNotes)}`,
      `key staff context: tonic=${keyTonic}, quality=${keyQuality === 0 ? "major" : "minor"}`,
      `aligned: ${aligned ? "yes" : "no"}`,
    ];
    if (tuningValues.length !== fretValues.length) {
      lines.push("note: tuning/fret counts differ, so MIDI alignment is semantic-only for overlapping strings");
    }
    outSvgMeta.textContent = lines.join("\n");

    svgClockHost.innerHTML = clockSvg;
    svgOpticKHost.innerHTML = opticKSvg;
    svgEvennessHost.innerHTML = evennessSvg;
    svgEvennessFieldHost.innerHTML = evennessFieldSvg;
    svgFretCompatHost.innerHTML = compatFretSvg;
    svgFretHost.innerHTML = fretSvg;
    svgStaffHost.innerHTML = staffSvg;
    svgKeyStaffHost.innerHTML = keyStaffSvg;
    svgKeyboardHost.innerHTML = keyboardSvg;
    svgPianoStaffHost.innerHTML = pianoStaffSvg;

    normalizeSvgPreview(svgClockHost);
    normalizeSvgPreview(svgOpticKHost, { maxHeight: 320, squareWidth: 620, mediumWidth: 760, wideWidth: 840, ultraWideWidth: 920, padXRatio: 0.04, padYRatio: 0.08 });
    normalizeSvgPreview(svgEvennessHost, { maxHeight: 520, squareWidth: 420, mediumWidth: 500, wideWidth: 520, ultraWideWidth: 540, padXRatio: 0.06, padYRatio: 0.06 });
    normalizeSvgPreview(svgEvennessFieldHost, { maxHeight: 520, squareWidth: 420, mediumWidth: 520, wideWidth: 620, ultraWideWidth: 680, padXRatio: 0.06, padYRatio: 0.06 });
    normalizeSvgPreview(svgFretCompatHost);
    normalizeSvgPreview(svgFretHost);
    normalizeSvgPreview(svgStaffHost);
    normalizeSvgPreview(svgKeyStaffHost);
    normalizeSvgPreview(svgKeyboardHost, { maxHeight: 240, squareWidth: 820, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1160, padXRatio: 0.03, padYRatio: 0.08 });
    normalizeSvgPreview(svgPianoStaffHost, { maxHeight: 340, squareWidth: 760, mediumWidth: 920, wideWidth: 1040, ultraWideWidth: 1160, padXRatio: 0.05, padYRatio: 0.12 });
  } finally {
    arena.release();
  }
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

function normalizeSvgPreview(host, options = {}) {
  const {
    maxHeight = 160,
    squareWidth = 220,
    mediumWidth = 320,
    wideWidth = 560,
    ultraWideWidth = 560,
    padXRatio = 0.08,
    padYRatio = 0.12,
    minPad = 4,
  } = options;
  const svg = host.querySelector("svg");
  if (!svg) return;

  svg.style.display = "block";
  svg.style.height = "auto";
  svg.style.maxWidth = "100%";
  svg.style.maxHeight = `${maxHeight}px`;

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
      svg.style.width = `${squareWidth}px`;
    } else if (aspect <= 2.8) {
      svg.style.width = `${mediumWidth}px`;
    } else if (aspect <= 4.4) {
      svg.style.width = `${wideWidth}px`;
    } else {
      svg.style.width = `${ultraWideWidth}px`;
    }

    const padX = Math.max(minPad, bbox.width * padXRatio);
    const padY = Math.max(minPad, bbox.height * padYRatio);
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
    ["Playability APIs", runPlayabilityApis, (err) => renderSectionError("Playability APIs", outPlayability, err)],
    ["Phrase Audit APIs", runPhraseAuditApis, (err) => renderSectionError("Phrase Audit APIs", outPhraseAudit, err)],
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
  document.getElementById("run-playability").addEventListener("click", () => runSafe("Playability APIs", runPlayabilityApis, (err) => renderSectionError("Playability APIs", outPlayability, err)));
  document.getElementById("run-phrase-audit").addEventListener("click", () => runSafe("Phrase Audit APIs", runPhraseAuditApis, (err) => renderSectionError("Phrase Audit APIs", outPhraseAudit, err)));
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
    window.__lmtDocsWasm = { exports: wasm, memory };

    setStatus("WASM loaded. Interactive API calls are ready.");

    wireUi();
    runAll();
  } catch (err) {
    window.__lmtDocsWasm = null;
    setStatus(`Failed to initialize: ${err.message}`, "error");
  }
}

main();
