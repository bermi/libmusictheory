const std = @import("std");
const build_options = @import("build_options");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const cluster = @import("cluster.zig");
const evenness = @import("evenness.zig");
const scale = @import("scale.zig");
const mode = @import("mode.zig");
const ordered_scale = @import("ordered_scale.zig");
const modal_interchange = @import("modal_interchange.zig");
const key = @import("key.zig");
const note_spelling = @import("note_spelling.zig");
const chord_type = @import("chord_type.zig");
const chord = @import("chord_construction.zig");
const chord_detection = @import("chord_detection.zig");
const harmony = @import("harmony.zig");
const counterpoint = @import("counterpoint.zig");
const voice_leading_rules = @import("voice_leading_rules.zig");
const choir = @import("choir.zig");
const playability = @import("playability.zig");
const guitar = @import("guitar.zig");
const keyboard_logic = @import("keyboard.zig");
const svg_clock = @import("svg/clock.zig");
const svg_evenness_chart = @import("svg/evenness_chart.zig");
const svg_fret = @import("svg/fret.zig");
const svg_keyboard = @import("svg/keyboard_svg.zig");
const svg_orbifold = @import("svg/orbifold.zig");
const svg_staff = @import("svg/staff.zig");
const svg_compat = @import("harmonious_svg_compat.zig");
const raster = @import("render/raster.zig");
const bitmap_compat = @import("bitmap_compat.zig");

pub const LmtKeyContext = extern struct {
    tonic: u8,
    quality: u8,
};

pub const LmtFretPos = extern struct {
    string: u8,
    fret: u8,
};

pub const LmtGuideDot = extern struct {
    position: LmtFretPos,
    pitch_class: u8,
    opacity: f32,
};

pub const LmtContextSuggestion = extern struct {
    score: i32,
    expanded_set: u16,
    pitch_class: u8,
    overlap: u8,
    outside_count: u8,
    in_context: u8,
    cluster_free: u8,
    reads_as_named_chord: u8,
};

pub const LmtScaleSnapCandidates = extern struct {
    in_scale: u8,
    has_lower: u8,
    has_upper: u8,
    reserved0: u8,
    lower: u8,
    upper: u8,
    lower_distance: u8,
    upper_distance: u8,
};

pub const LmtContainingModeMatch = extern struct {
    mode: u8,
    degree: u8,
    reserved0: u8,
    reserved1: u8,
};

pub const LmtChordMatch = extern struct {
    root: u8,
    bass: u8,
    pattern: u8,
    interval_count: u8,
    bass_known: u8,
    root_is_bass: u8,
    bass_degree: u8,
    reserved0: u8,
};

pub const LmtHandProfile = extern struct {
    finger_count: u8,
    comfort_span_steps: u8,
    limit_span_steps: u8,
    comfort_shift_steps: u8,
    limit_shift_steps: u8,
    prefers_low_tension: u8,
    reserved0: u8,
    reserved1: u8,
};

pub const LmtPlayabilityDifficultySummary = extern struct {
    accepted: u8,
    blocker_count: u8,
    warning_count: u8,
    reason_count: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    span_steps: u8,
    shift_steps: u8,
    load_event_count: u8,
    peak_recent_span_steps: u8,
    peak_recent_shift_steps: u8,
    reserved0: u8,
    comfort_span_margin: i16,
    limit_span_margin: i16,
    comfort_shift_margin: i16,
    limit_shift_margin: i16,
};

pub const LmtKeyboardPhraseEvent = extern struct {
    note_count: u8,
    hand: u8,
    reserved0: u8,
    reserved1: u8,
    notes: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8,
};

pub const LmtFretPhraseEvent = extern struct {
    fret_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    frets: [guitar.MAX_GENERIC_STRINGS]i8,
};

pub const LmtKeyboardCommittedPhraseMemory = extern struct {
    event_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    events: [playability.phrase.MAX_PHRASE_EVENTS]LmtKeyboardPhraseEvent,
};

pub const LmtFretCommittedPhraseMemory = extern struct {
    event_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    events: [playability.phrase.MAX_PHRASE_EVENTS]LmtFretPhraseEvent,
};

pub const LmtPlayabilityPhraseIssue = extern struct {
    scope: u8,
    severity: u8,
    family_domain: u8,
    family_index: u8,
    event_index: u16,
    related_event_index: u16,
    magnitude: u16,
    reserved0: u16,
};

pub const LmtPlayabilityPhraseSummary = extern struct {
    event_count: u16,
    issue_count: u16,
    first_blocked_event_index: u16,
    first_blocked_transition_from_index: u16,
    first_blocked_transition_to_index: u16,
    bottleneck_issue_index: u16,
    bottleneck_magnitude: u16,
    bottleneck_severity: u8,
    bottleneck_domain: u8,
    bottleneck_family_index: u8,
    strain_bucket: u8,
    dominant_reason_family: u8,
    dominant_warning_family: u8,
    reserved0: u8,
    severity_counts: [3]u16,
    reason_family_counts: [playability.types.REASON_NAMES.len]u16,
    warning_family_counts: [playability.types.WARNING_NAMES.len]u16,
    recovery_deficit_start_index: u16,
    recovery_deficit_end_index: u16,
    longest_recovery_deficit_run: u16,
};

pub const LmtTemporalLoadState = extern struct {
    event_count: u8,
    last_anchor_step: u8,
    last_span_steps: u8,
    last_shift_steps: u8,
    peak_span_steps: u8,
    peak_shift_steps: u8,
    cumulative_span_steps: u16,
    cumulative_shift_steps: u16,
};

pub const LmtFretCandidateLocation = extern struct {
    position: LmtFretPos,
    in_window: u8,
    shift_steps: u8,
};

pub const LmtFretPlayState = extern struct {
    anchor_fret: u8,
    window_start: u8,
    window_end: u8,
    lowest_string: u8,
    highest_string: u8,
    active_string_count: u8,
    fretted_note_count: u8,
    open_string_count: u8,
    span_steps: u8,
    comfort_fit: u8,
    limit_fit: u8,
    reserved0: u8,
    load: LmtTemporalLoadState,
};

pub const LmtFretRealizationAssessment = extern struct {
    state: LmtFretPlayState,
    string_span_steps: u8,
    profile: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_fingers: [guitar.MAX_GENERIC_STRINGS]u8,
};

pub const LmtFretTransitionAssessment = extern struct {
    from_state: LmtFretPlayState,
    to_state: LmtFretPlayState,
    anchor_delta_steps: u8,
    changed_string_count: u8,
    profile: u8,
    reserved0: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_fingers: [guitar.MAX_GENERIC_STRINGS]u8,
};

pub const LmtRankedFretRealization = extern struct {
    location: LmtFretCandidateLocation,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_finger: u8,
    profile: u8,
    reserved0: u8,
    reserved1: u8,
};

pub const LmtKeybedKeyCoord = extern struct {
    midi: u8,
    is_black: u8,
    octave: u8,
    degree_in_octave: u8,
    x: f32,
    y: f32,
};

pub const LmtKeyboardPlayState = extern struct {
    anchor_midi: u8,
    low_midi: u8,
    high_midi: u8,
    active_note_count: u8,
    black_key_count: u8,
    white_key_count: u8,
    span_semitones: u8,
    comfort_fit: u8,
    limit_fit: u8,
    reserved0: u8,
    load: LmtTemporalLoadState,
};

pub const LmtKeyboardRealizationAssessment = extern struct {
    state: LmtKeyboardPlayState,
    hand: u8,
    note_count: u8,
    outer_black_count: u8,
    reserved0: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_fingers: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8,
};

pub const LmtKeyboardTransitionAssessment = extern struct {
    from_state: LmtKeyboardPlayState,
    to_state: LmtKeyboardPlayState,
    hand: u8,
    note_count: u8,
    anchor_delta_semitones: u8,
    reserved0: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    from_fingers: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8,
    to_fingers: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8,
};

pub const LmtRankedKeyboardFingering = extern struct {
    hand: u8,
    note_count: u8,
    reserved0: u8,
    reserved1: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    fingers: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8,
};

pub const LmtMetricPosition = extern struct {
    beat_in_bar: u8,
    beats_per_bar: u8,
    subdivision: u8,
    reserved: u8,
};

pub const LmtVoice = extern struct {
    id: u8,
    midi: u8,
    octave: i8,
    pitch_class: u8,
    sustained: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
};

pub const LmtVoicedState = extern struct {
    set_value: u16,
    voice_count: u8,
    tonic: u8,
    mode_type: u8,
    key_quality: u8,
    metric: LmtMetricPosition,
    cadence_state: u8,
    state_index: u8,
    next_voice_id: u8,
    reserved: u8,
    voices: [counterpoint.MAX_VOICES]LmtVoice,
};

pub const LmtVoicedHistory = extern struct {
    len: u8,
    next_voice_id: u8,
    reserved0: u8,
    reserved1: u8,
    states: [counterpoint.HISTORY_CAPACITY]LmtVoicedState,
};

pub const LmtVoiceMotion = extern struct {
    voice_id: u8,
    from_midi: u8,
    to_midi: u8,
    delta: i8,
    abs_delta: u8,
    motion_class: u8,
    retained: u8,
    reserved: u8,
};

pub const LmtMotionSummary = extern struct {
    voice_motion_count: u8,
    common_tone_count: u8,
    step_count: u8,
    leap_count: u8,
    contrary_count: u8,
    similar_count: u8,
    parallel_count: u8,
    oblique_count: u8,
    crossing_count: u8,
    overlap_count: u8,
    total_motion: u16,
    outer_interval_before: i8,
    outer_interval_after: i8,
    outer_motion: u8,
    previous_cadence_state: u8,
    current_cadence_state: u8,
    voice_motions: [counterpoint.MAX_VOICES]LmtVoiceMotion,
};

pub const LmtMotionEvaluation = extern struct {
    score: i32,
    preferred_score: i16,
    penalty_score: i16,
    cadence_score: i16,
    spacing_penalty: i16,
    leap_penalty: i16,
    disallowed_count: u8,
    disallowed: u8,
};

pub const LmtVoicePairViolation = extern struct {
    kind: u8,
    lower_voice_id: u8,
    upper_voice_id: u8,
    previous_interval_semitones: i8,
    current_interval_semitones: i8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
};

pub const LmtMotionIndependenceSummary = extern struct {
    collapsed: u8,
    direction: i8,
    moving_voice_count: u8,
    stationary_voice_count: u8,
    ascending_count: u8,
    descending_count: u8,
    retained_voice_count: u8,
    reserved0: u8,
};

pub const LmtSatbRegisterViolation = extern struct {
    voice_id: u8,
    satb_voice: u8,
    midi: u8,
    direction: i8,
    low: u8,
    high: u8,
    reserved0: u8,
    reserved1: u8,
};

pub const LmtNextStepSuggestion = extern struct {
    score: i32,
    reason_mask: u32,
    warning_mask: u32,
    cadence_effect: u8,
    tension_delta: i8,
    note_count: u8,
    reserved0: u8,
    reserved1: u8,
    set_value: u16,
    notes: [counterpoint.MAX_VOICES]u8,
    motion: LmtMotionSummary,
    evaluation: LmtMotionEvaluation,
};

pub const LmtRankedKeyboardContextSuggestion = extern struct {
    candidate: LmtContextSuggestion,
    transition: LmtKeyboardTransitionAssessment,
    realized_note: u8,
    candidate_index: u8,
    hand: u8,
    policy: u8,
    accepted: u8,
    reserved0: u8,
};

pub const LmtRankedKeyboardNextStep = extern struct {
    candidate: LmtNextStepSuggestion,
    transition: LmtKeyboardTransitionAssessment,
    candidate_index: u8,
    hand: u8,
    policy: u8,
    accepted: u8,
};

pub const LmtCadenceDestinationScore = extern struct {
    score: i32,
    destination: u8,
    candidate_count: u8,
    warning_count: u8,
    current_match: u8,
    tension_bias: i8,
    reserved0: u8,
    reserved1: u8,
};

pub const LmtSuspensionMachineSummary = extern struct {
    state: u8,
    tracked_voice_id: u8,
    held_midi: u8,
    expected_resolution_midi: u8,
    resolution_direction: i8,
    obligation_count: u8,
    warning_count: u8,
    retained_count: u8,
    current_tension: i16,
    previous_tension: i16,
    candidate_resolution_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
};

pub const LmtOrbifoldTriadNode = extern struct {
    set_value: u16,
    root: u8,
    quality: u8,
    x: f32,
    y: f32,
};

pub const LmtOrbifoldTriadEdge = extern struct {
    from_index: u8,
    to_index: u8,
    reserved0: u8,
    reserved1: u8,
};

const SCALE_DIATONIC: u8 = 0;
const SCALE_ACOUSTIC: u8 = 1;
const SCALE_DIMINISHED: u8 = 2;
const SCALE_WHOLE_TONE: u8 = 3;
const SCALE_HARMONIC_MINOR: u8 = 4;
const SCALE_HARMONIC_MAJOR: u8 = 5;
const SCALE_DOUBLE_AUGMENTED_HEXATONIC: u8 = 6;

const CHORD_MAJOR: u8 = 0;
const CHORD_MINOR: u8 = 1;
const CHORD_DIMINISHED: u8 = 2;
const CHORD_AUGMENTED: u8 = 3;

const KEY_MAJOR: u8 = 0;
const KEY_MINOR: u8 = 1;
const COUNTERPOINT_RULE_PROFILE_NAMES = [_][]const u8{
    "species",
    "tonal-chorale",
    "modal-polyphony",
    "jazz-close-leading",
    "free-contemporary",
};

const MAJOR_TRIAD = pcs.C_MAJOR_TRIAD;
const MINOR_TRIAD = pcs.C_MINOR_TRIAD;
const DIMINISHED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 });
const AUGMENTED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });
const MAJOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 });
const DOMINANT_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 10 });
const MINOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7, 10 });
const HALF_DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 10 });
const DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 9 });

var c_string_slots: [8][64]u8 = [_][64]u8{[_]u8{0} ** 64} ** 8;
var c_string_slot_index: usize = 0;
var compat_svg_buf: [4 * 1024 * 1024]u8 = undefined;
var wasm_client_scratch: [8 * 1024 * 1024]u8 = undefined;
const MAX_PARAMETRIC_FRET_STRINGS: usize = 64;
const MAX_KEYBOARD_RENDER_NOTES: usize = 128;
const MAX_C_API_GENERIC_VOICINGS: usize = MAX_PARAMETRIC_FRET_STRINGS * MAX_PARAMETRIC_FRET_STRINGS;
var generic_voicing_meta_buf: [MAX_C_API_GENERIC_VOICINGS]guitar.GenericVoicing = undefined;
var generic_voicing_fret_buf: [MAX_C_API_GENERIC_VOICINGS * MAX_PARAMETRIC_FRET_STRINGS]i8 = undefined;

fn maskPitchClassSet(raw: u16) pcs.PitchClassSet {
    return @as(pcs.PitchClassSet, @intCast(raw & 0x0fff));
}

fn toCSet(set: pcs.PitchClassSet) u16 {
    return @as(u16, set);
}

fn decodeKeyContext(ctx: LmtKeyContext) key.Key {
    const tonic = @as(pitch.PitchClass, @intCast(ctx.tonic % 12));
    const quality: key.KeyQuality = if (ctx.quality == KEY_MINOR) .minor else .major;
    return key.Key.init(tonic, quality);
}

fn buildKeyStaffNotes(tonic: pitch.PitchClass, quality: key.KeyQuality, out: *[8]pitch.MidiNote) []const pitch.MidiNote {
    const base_root: u8 = @as(u8, tonic);
    const root_midi: u8 = if (base_root <= 5) 60 + base_root else 48 + base_root;
    const intervals = switch (quality) {
        .major => [_]u8{ 0, 2, 4, 5, 7, 9, 11, 12 },
        .minor => [_]u8{ 0, 2, 3, 5, 7, 8, 10, 12 },
    };

    for (intervals, 0..) |interval, index| {
        out[index] = @as(pitch.MidiNote, @intCast(root_midi + interval));
    }
    return out[0..intervals.len];
}

fn decodeScaleType(scale_type: u8) ?scale.ScaleType {
    return switch (scale_type) {
        SCALE_DIATONIC => .diatonic,
        SCALE_ACOUSTIC => .acoustic,
        SCALE_DIMINISHED => .diminished,
        SCALE_WHOLE_TONE => .whole_tone,
        SCALE_HARMONIC_MINOR => .harmonic_minor,
        SCALE_HARMONIC_MAJOR => .harmonic_major,
        SCALE_DOUBLE_AUGMENTED_HEXATONIC => .double_augmented_hexatonic,
        else => null,
    };
}

fn decodeModeType(mode_type: u8) ?mode.ModeType {
    return mode.fromInt(mode_type);
}

fn decodeSnapTiePolicy(raw: u8) ordered_scale.SnapTiePolicy {
    return if (raw == 1) .higher else .lower;
}

fn decodeOrderedScalePattern(index: u32) ?ordered_scale.PatternId {
    if (index > std.math.maxInt(u8)) return null;
    return ordered_scale.fromInt(@as(u8, @intCast(index)));
}

fn modeSet(mode_type: mode.ModeType) pcs.PitchClassSet {
    return mode.info(mode_type).pcs;
}

fn chordTemplate(chord_kind: u8) pcs.PitchClassSet {
    return switch (chord_kind) {
        CHORD_MINOR => chord_type.MINOR.pcs,
        CHORD_DIMINISHED => chord_type.DIMINISHED.pcs,
        CHORD_AUGMENTED => chord_type.AUGMENTED.pcs,
        else => chord_type.MAJOR.pcs,
    };
}

fn firstPitchClass(set: pcs.PitchClassSet) pitch.PitchClass {
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if ((set & (@as(pcs.PitchClassSet, 1) << pc)) != 0) {
            return @as(pitch.PitchClass, @intCast(pc));
        }
    }
    return 0;
}

fn classifyChordQuality(root_pc: pitch.PitchClass, chord_set: pcs.PitchClassSet) harmony.ChordQuality {
    const normalized = pcs.transposeDown(chord_set, root_pc);

    if (normalized == MAJOR_TRIAD) return .major;
    if (normalized == MINOR_TRIAD) return .minor;
    if (normalized == DIMINISHED_TRIAD) return .diminished;
    if (normalized == AUGMENTED_TRIAD) return .augmented;

    if (normalized == MAJOR_SEVENTH) return .major;
    if (normalized == DOMINANT_SEVENTH) return .dominant;
    if (normalized == MINOR_SEVENTH) return .minor;
    if (normalized == HALF_DIMINISHED_SEVENTH) return .half_diminished;
    if (normalized == DIMINISHED_SEVENTH) return .diminished_seventh;

    return .unknown;
}

fn decodeTuning(ptr: [*c]const u8) guitar.Tuning {
    if (ptr == null) return guitar.tunings.STANDARD;

    var out: guitar.Tuning = undefined;
    var i: usize = 0;
    while (i < guitar.NUM_STRINGS) : (i += 1) {
        const raw = ptr[i];
        out[i] = @as(pitch.MidiNote, @intCast(@min(raw, @as(u8, 127))));
    }
    return out;
}

fn decodeTuningGeneric(ptr: [*c]const u8, tuning_count: u32, out: *[MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote) []const pitch.MidiNote {
    const len = @min(@as(usize, @intCast(tuning_count)), out.len);
    if (ptr == null or len == 0) return out[0..0];

    var i: usize = 0;
    while (i < len) : (i += 1) {
        const raw = ptr[i];
        out[i] = @as(pitch.MidiNote, @intCast(@min(raw, @as(u8, 127))));
    }
    return out[0..len];
}

fn decodeMidiNotes(ptr: [*c]const u8, note_count: u32, out: *[MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote) []const pitch.MidiNote {
    const len = @min(@as(usize, @intCast(note_count)), out.len);
    if (ptr == null or len == 0) return out[0..0];

    var i: usize = 0;
    while (i < len) : (i += 1) {
        out[i] = @as(pitch.MidiNote, @intCast(@min(ptr[i], @as(u8, 127))));
    }
    return out[0..len];
}

fn decodeHandProfile(raw: LmtHandProfile) playability.types.HandProfile {
    return playability.types.HandProfile.init(
        raw.finger_count,
        raw.comfort_span_steps,
        raw.limit_span_steps,
        raw.comfort_shift_steps,
        raw.limit_shift_steps,
        raw.prefers_low_tension != 0,
    );
}

fn decodeFretTechniqueProfile(raw: u32) ?playability.fret_assessment.TechniqueProfile {
    if (raw > std.math.maxInt(u8)) return null;
    return playability.fret_assessment.fromInt(@as(u8, @intCast(raw)));
}

fn decodeKeyboardHand(raw: u32) ?playability.keyboard_assessment.HandRole {
    if (raw > std.math.maxInt(u8)) return null;
    return playability.keyboard_assessment.fromInt(@as(u8, @intCast(raw)));
}

fn decodePlayabilityPolicy(raw: u32) ?playability.ranking.PlayabilityPolicy {
    if (raw > std.math.maxInt(u8)) return null;
    return playability.ranking.fromInt(@as(u8, @intCast(raw)));
}

fn decodePlayabilityProfilePreset(raw: u32) ?playability.profile.ProfilePreset {
    if (raw > std.math.maxInt(u8)) return null;
    return playability.profile.fromInt(@as(u8, @intCast(raw)));
}

fn decodePhraseIssueScope(raw: u8) ?playability.phrase.IssueScope {
    return std.meta.intToEnum(playability.phrase.IssueScope, raw) catch null;
}

fn decodePhraseIssueSeverity(raw: u8) ?playability.phrase.IssueSeverity {
    return std.meta.intToEnum(playability.phrase.IssueSeverity, raw) catch null;
}

fn decodePhraseFamilyDomain(raw: u8) ?playability.phrase.FamilyDomain {
    return std.meta.intToEnum(playability.phrase.FamilyDomain, raw) catch null;
}

fn writeHandProfile(out: *LmtHandProfile, profile: playability.types.HandProfile) void {
    out.* = .{
        .finger_count = profile.finger_count,
        .comfort_span_steps = profile.comfort_span_steps,
        .limit_span_steps = profile.limit_span_steps,
        .comfort_shift_steps = profile.comfort_shift_steps,
        .limit_shift_steps = profile.limit_shift_steps,
        .prefers_low_tension = if (profile.prefers_low_tension) 1 else 0,
        .reserved0 = 0,
        .reserved1 = 0,
    };
}

fn writePlayabilityDifficultySummary(
    out: *LmtPlayabilityDifficultySummary,
    summary: playability.profile.DifficultySummary,
) void {
    out.* = .{
        .accepted = if (summary.accepted) 1 else 0,
        .blocker_count = summary.blocker_count,
        .warning_count = summary.warning_count,
        .reason_count = summary.reason_count,
        .bottleneck_cost = summary.bottleneck_cost,
        .cumulative_cost = summary.cumulative_cost,
        .span_steps = summary.span_steps,
        .shift_steps = summary.shift_steps,
        .load_event_count = summary.load_event_count,
        .peak_recent_span_steps = summary.peak_recent_span_steps,
        .peak_recent_shift_steps = summary.peak_recent_shift_steps,
        .reserved0 = 0,
        .comfort_span_margin = summary.comfort_span_margin,
        .limit_span_margin = summary.limit_span_margin,
        .comfort_shift_margin = summary.comfort_shift_margin,
        .limit_shift_margin = summary.limit_shift_margin,
    };
}

fn decodePhraseIssue(raw: LmtPlayabilityPhraseIssue) ?playability.phrase.PhraseIssue {
    return .{
        .scope = decodePhraseIssueScope(raw.scope) orelse return null,
        .severity = decodePhraseIssueSeverity(raw.severity) orelse return null,
        .family_domain = decodePhraseFamilyDomain(raw.family_domain) orelse return null,
        .family_index = raw.family_index,
        .event_index = raw.event_index,
        .related_event_index = raw.related_event_index,
        .magnitude = raw.magnitude,
        .reserved0 = raw.reserved0,
    };
}

fn decodeKeyboardPhraseEvent(raw: LmtKeyboardPhraseEvent) ?playability.phrase.KeyboardPhraseEvent {
    const hand = decodeKeyboardHand(raw.hand) orelse return null;
    const count = @min(@as(usize, raw.note_count), playability.keyboard_assessment.MAX_FINGERING_NOTES);

    var out = playability.phrase.KeyboardPhraseEvent{
        .note_count = @as(u8, @intCast(count)),
        .hand = hand,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = [_]pitch.MidiNote{0} ** playability.keyboard_assessment.MAX_FINGERING_NOTES,
    };

    var index: usize = 0;
    while (index < count) : (index += 1) {
        out.notes[index] = @as(pitch.MidiNote, @intCast(@min(raw.notes[index], @as(u8, 127))));
    }
    return out;
}

fn decodeFretPhraseEvent(raw: LmtFretPhraseEvent) playability.phrase.FretPhraseEvent {
    return .{
        .fret_count = @as(u8, @intCast(@min(@as(usize, raw.fret_count), guitar.MAX_GENERIC_STRINGS))),
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = raw.frets,
    };
}

fn decodeKeyboardCommittedPhraseMemory(raw: LmtKeyboardCommittedPhraseMemory) ?playability.phrase.KeyboardCommittedPhraseMemory {
    var out = playability.phrase.KeyboardCommittedPhraseMemory.init();
    const count = @min(@as(usize, raw.event_count), playability.phrase.MAX_PHRASE_EVENTS);
    var index: usize = 0;
    while (index < count) : (index += 1) {
        out.events[index] = decodeKeyboardPhraseEvent(raw.events[index]) orelse return null;
    }
    out.event_count = @as(u8, @intCast(count));
    return out;
}

fn decodeFretCommittedPhraseMemory(raw: LmtFretCommittedPhraseMemory) playability.phrase.FretCommittedPhraseMemory {
    var out = playability.phrase.FretCommittedPhraseMemory.init();
    const count = @min(@as(usize, raw.event_count), playability.phrase.MAX_PHRASE_EVENTS);
    var index: usize = 0;
    while (index < count) : (index += 1) {
        out.events[index] = decodeFretPhraseEvent(raw.events[index]);
    }
    out.event_count = @as(u8, @intCast(count));
    return out;
}

fn writeKeyboardPhraseEvent(out: *LmtKeyboardPhraseEvent, event: playability.phrase.KeyboardPhraseEvent) void {
    var notes: [playability.keyboard_assessment.MAX_FINGERING_NOTES]u8 = [_]u8{0} ** playability.keyboard_assessment.MAX_FINGERING_NOTES;
    for (event.notes, 0..) |note, index| {
        notes[index] = note;
    }
    out.* = .{
        .note_count = event.note_count,
        .hand = @intFromEnum(event.hand),
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = notes,
    };
}

fn writeFretPhraseEvent(out: *LmtFretPhraseEvent, event: playability.phrase.FretPhraseEvent) void {
    out.* = .{
        .fret_count = event.fret_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = event.frets,
    };
}

fn writeKeyboardCommittedPhraseMemory(
    out: *LmtKeyboardCommittedPhraseMemory,
    memory: playability.phrase.KeyboardCommittedPhraseMemory,
) void {
    out.* = .{
        .event_count = memory.event_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .events = undefined,
    };
    var index: usize = 0;
    while (index < playability.phrase.MAX_PHRASE_EVENTS) : (index += 1) {
        writeKeyboardPhraseEvent(&out.events[index], memory.events[index]);
    }
}

fn writeFretCommittedPhraseMemory(
    out: *LmtFretCommittedPhraseMemory,
    memory: playability.phrase.FretCommittedPhraseMemory,
) void {
    out.* = .{
        .event_count = memory.event_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .events = undefined,
    };
    var index: usize = 0;
    while (index < playability.phrase.MAX_PHRASE_EVENTS) : (index += 1) {
        writeFretPhraseEvent(&out.events[index], memory.events[index]);
    }
}

fn writePhraseIssue(
    out: *LmtPlayabilityPhraseIssue,
    issue: playability.phrase.PhraseIssue,
) void {
    out.* = .{
        .scope = @intFromEnum(issue.scope),
        .severity = @intFromEnum(issue.severity),
        .family_domain = @intFromEnum(issue.family_domain),
        .family_index = issue.family_index,
        .event_index = issue.event_index,
        .related_event_index = issue.related_event_index,
        .magnitude = issue.magnitude,
        .reserved0 = 0,
    };
}

fn writePhraseSummary(
    out: *LmtPlayabilityPhraseSummary,
    summary: playability.phrase.PhraseSummary,
) void {
    out.* = .{
        .event_count = summary.event_count,
        .issue_count = summary.issue_count,
        .first_blocked_event_index = summary.first_blocked_event_index,
        .first_blocked_transition_from_index = summary.first_blocked_transition_from_index,
        .first_blocked_transition_to_index = summary.first_blocked_transition_to_index,
        .bottleneck_issue_index = summary.bottleneck_issue_index,
        .bottleneck_magnitude = summary.bottleneck_magnitude,
        .bottleneck_severity = @intFromEnum(summary.bottleneck_severity),
        .bottleneck_domain = @intFromEnum(summary.bottleneck_domain),
        .bottleneck_family_index = summary.bottleneck_family_index,
        .strain_bucket = @intFromEnum(summary.strain_bucket),
        .dominant_reason_family = summary.dominant_reason_family,
        .dominant_warning_family = summary.dominant_warning_family,
        .reserved0 = 0,
        .severity_counts = summary.severity_counts,
        .reason_family_counts = summary.reason_family_counts,
        .warning_family_counts = summary.warning_family_counts,
        .recovery_deficit_start_index = summary.recovery_deficit_start_index,
        .recovery_deficit_end_index = summary.recovery_deficit_end_index,
        .longest_recovery_deficit_run = summary.longest_recovery_deficit_run,
    };
}

fn decodeTemporalLoadState(raw: LmtTemporalLoadState) playability.types.TemporalLoadState {
    return .{
        .event_count = raw.event_count,
        .last_anchor_step = raw.last_anchor_step,
        .last_span_steps = raw.last_span_steps,
        .last_shift_steps = raw.last_shift_steps,
        .peak_span_steps = raw.peak_span_steps,
        .peak_shift_steps = raw.peak_shift_steps,
        .cumulative_span_steps = raw.cumulative_span_steps,
        .cumulative_shift_steps = raw.cumulative_shift_steps,
    };
}

fn writeTemporalLoadState(out: *LmtTemporalLoadState, state: playability.types.TemporalLoadState) void {
    out.* = .{
        .event_count = state.event_count,
        .last_anchor_step = state.last_anchor_step,
        .last_span_steps = state.last_span_steps,
        .last_shift_steps = state.last_shift_steps,
        .peak_span_steps = state.peak_span_steps,
        .peak_shift_steps = state.peak_shift_steps,
        .cumulative_span_steps = state.cumulative_span_steps,
        .cumulative_shift_steps = state.cumulative_shift_steps,
    };
}

const KeyboardRange = struct {
    low: pitch.MidiNote,
    high: pitch.MidiNote,
};

fn sanitizeKeyboardRange(low_raw: u8, high_raw: u8) KeyboardRange {
    const clamped_low = @as(pitch.MidiNote, @intCast(@min(low_raw, @as(u8, 127))));
    const clamped_high = @as(pitch.MidiNote, @intCast(@min(high_raw, @as(u8, 127))));
    return if (clamped_low <= clamped_high)
        .{ .low = clamped_low, .high = clamped_high }
    else
        .{ .low = clamped_high, .high = clamped_low };
}

fn decodeCadenceState(raw: u8) ?counterpoint.CadenceState {
    return std.meta.intToEnum(counterpoint.CadenceState, raw) catch null;
}

fn decodeCounterpointRuleProfile(raw: u8) ?counterpoint.CounterpointRuleProfile {
    return std.meta.intToEnum(counterpoint.CounterpointRuleProfile, raw) catch null;
}

fn decodeMetricPosition(beat_in_bar: u8, beats_per_bar: u8, subdivision: u8) counterpoint.MetricPosition {
    return counterpoint.MetricPosition.normalized(beat_in_bar, beats_per_bar, subdivision);
}

fn decodeVoicedState(raw: LmtVoicedState) counterpoint.VoicedState {
    var state = counterpoint.VoicedState.initEmpty(
        @as(pitch.PitchClass, @intCast(raw.tonic % 12)),
        decodeModeType(raw.mode_type) orelse .ionian,
        decodeMetricPosition(raw.metric.beat_in_bar, raw.metric.beats_per_bar, raw.metric.subdivision),
    );
    state.set_value = maskPitchClassSet(raw.set_value);
    state.voice_count = @as(u8, @intCast(@min(raw.voice_count, counterpoint.MAX_VOICES)));
    state.key_quality = if (raw.key_quality == KEY_MINOR) .minor else .major;
    state.cadence_state = decodeCadenceState(raw.cadence_state) orelse .none;
    state.state_index = raw.state_index;
    state.next_voice_id = raw.next_voice_id;

    var index: usize = 0;
    while (index < state.voice_count) : (index += 1) {
        const voice = raw.voices[index];
        state.voices[index] = .{
            .id = voice.id,
            .midi = @as(pitch.MidiNote, @intCast(@min(voice.midi, @as(u8, 127)))),
            .pitch_class = @as(pitch.PitchClass, @intCast(voice.pitch_class % 12)),
            .octave = voice.octave,
            .sustained = voice.sustained == 1,
        };
    }
    while (index < counterpoint.MAX_VOICES) : (index += 1) {
        state.voices[index] = .{ .id = 0, .midi = 0, .pitch_class = 0, .octave = -1, .sustained = false };
    }
    return state;
}

fn writeVoicedState(out: *LmtVoicedState, state: counterpoint.VoicedState) void {
    out.* = .{
        .set_value = toCSet(state.set_value),
        .voice_count = state.voice_count,
        .tonic = state.tonic,
        .mode_type = @intFromEnum(state.mode_type),
        .key_quality = switch (state.key_quality) {
            .minor => KEY_MINOR,
            .major => KEY_MAJOR,
        },
        .metric = .{
            .beat_in_bar = state.metric.beat_in_bar,
            .beats_per_bar = state.metric.beats_per_bar,
            .subdivision = state.metric.subdivision,
            .reserved = 0,
        },
        .cadence_state = @intFromEnum(state.cadence_state),
        .state_index = state.state_index,
        .next_voice_id = state.next_voice_id,
        .reserved = 0,
        .voices = [_]LmtVoice{.{
            .id = 0,
            .midi = 0,
            .octave = -1,
            .pitch_class = 0,
            .sustained = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
        }} ** counterpoint.MAX_VOICES,
    };

    for (state.slice(), 0..) |voice, index| {
        out.voices[index] = .{
            .id = voice.id,
            .midi = voice.midi,
            .octave = voice.octave,
            .pitch_class = voice.pitch_class,
            .sustained = if (voice.sustained) 1 else 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
        };
    }
}

fn decodeVoicedHistory(raw: LmtVoicedHistory) counterpoint.VoicedHistoryWindow {
    var history = counterpoint.VoicedHistoryWindow.init();
    history.len = @as(u8, @intCast(@min(raw.len, counterpoint.HISTORY_CAPACITY)));
    history.next_voice_id = raw.next_voice_id;
    var index: usize = 0;
    while (index < history.len) : (index += 1) {
        history.states[index] = decodeVoicedState(raw.states[index]);
    }
    return history;
}

fn writeVoicedHistory(out: *LmtVoicedHistory, history: counterpoint.VoicedHistoryWindow) void {
    out.* = .{
        .len = history.len,
        .next_voice_id = history.next_voice_id,
        .reserved0 = 0,
        .reserved1 = 0,
        .states = [_]LmtVoicedState{undefined} ** counterpoint.HISTORY_CAPACITY,
    };
    var index: usize = 0;
    while (index < counterpoint.HISTORY_CAPACITY) : (index += 1) {
        writeVoicedState(&out.states[index], history.states[index]);
    }
}

fn writeMotionSummary(out: *LmtMotionSummary, summary: counterpoint.MotionSummary) void {
    out.* = .{
        .voice_motion_count = summary.voice_motion_count,
        .common_tone_count = summary.common_tone_count,
        .step_count = summary.step_count,
        .leap_count = summary.leap_count,
        .contrary_count = summary.contrary_count,
        .similar_count = summary.similar_count,
        .parallel_count = summary.parallel_count,
        .oblique_count = summary.oblique_count,
        .crossing_count = summary.crossing_count,
        .overlap_count = summary.overlap_count,
        .total_motion = summary.total_motion,
        .outer_interval_before = summary.outer_interval_before,
        .outer_interval_after = summary.outer_interval_after,
        .outer_motion = @intFromEnum(summary.outer_motion),
        .previous_cadence_state = @intFromEnum(summary.previous_cadence_state),
        .current_cadence_state = @intFromEnum(summary.current_cadence_state),
        .voice_motions = [_]LmtVoiceMotion{undefined} ** counterpoint.MAX_VOICES,
    };

    for (summary.voice_motions, 0..) |motion, index| {
        out.voice_motions[index] = .{
            .voice_id = motion.voice_id,
            .from_midi = motion.from_midi,
            .to_midi = motion.to_midi,
            .delta = motion.delta,
            .abs_delta = motion.abs_delta,
            .motion_class = @intFromEnum(motion.motion_class),
            .retained = if (motion.retained) 1 else 0,
            .reserved = 0,
        };
    }
}

fn decodeMotionSummary(raw: LmtMotionSummary) counterpoint.MotionSummary {
    var summary = counterpoint.MotionSummary.init();
    summary.voice_motion_count = @min(raw.voice_motion_count, counterpoint.MAX_VOICES);
    summary.common_tone_count = raw.common_tone_count;
    summary.step_count = raw.step_count;
    summary.leap_count = raw.leap_count;
    summary.contrary_count = raw.contrary_count;
    summary.similar_count = raw.similar_count;
    summary.parallel_count = raw.parallel_count;
    summary.oblique_count = raw.oblique_count;
    summary.crossing_count = raw.crossing_count;
    summary.overlap_count = raw.overlap_count;
    summary.total_motion = raw.total_motion;
    summary.outer_interval_before = raw.outer_interval_before;
    summary.outer_interval_after = raw.outer_interval_after;
    summary.outer_motion = std.meta.intToEnum(counterpoint.PairMotionClass, raw.outer_motion) catch .none;
    summary.previous_cadence_state = decodeCadenceState(raw.previous_cadence_state) orelse .none;
    summary.current_cadence_state = decodeCadenceState(raw.current_cadence_state) orelse .none;
    for (0..summary.voice_motion_count) |index| {
        const motion = raw.voice_motions[index];
        summary.voice_motions[index] = .{
            .voice_id = motion.voice_id,
            .from_midi = @as(pitch.MidiNote, @intCast(@min(motion.from_midi, @as(u8, 127)))),
            .to_midi = @as(pitch.MidiNote, @intCast(@min(motion.to_midi, @as(u8, 127)))),
            .delta = motion.delta,
            .abs_delta = motion.abs_delta,
            .motion_class = std.meta.intToEnum(counterpoint.VoiceMotionClass, motion.motion_class) catch .stationary,
            .retained = motion.retained != 0,
        };
    }
    return summary;
}

fn writeMotionEvaluation(out: *LmtMotionEvaluation, evaluation: counterpoint.MotionEvaluation) void {
    out.* = .{
        .score = evaluation.score,
        .preferred_score = evaluation.preferred_score,
        .penalty_score = evaluation.penalty_score,
        .cadence_score = evaluation.cadence_score,
        .spacing_penalty = evaluation.spacing_penalty,
        .leap_penalty = evaluation.leap_penalty,
        .disallowed_count = evaluation.disallowed_count,
        .disallowed = if (evaluation.disallowed) 1 else 0,
    };
}

fn writeVoicePairViolation(out: *LmtVoicePairViolation, violation: voice_leading_rules.VoicePairViolation) void {
    out.* = .{
        .kind = @intFromEnum(violation.kind),
        .lower_voice_id = violation.lower_voice_id,
        .upper_voice_id = violation.upper_voice_id,
        .previous_interval_semitones = violation.previous_interval_semitones,
        .current_interval_semitones = violation.current_interval_semitones,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
    };
}

fn writeMotionIndependenceSummary(out: *LmtMotionIndependenceSummary, summary: voice_leading_rules.MotionIndependenceSummary) void {
    out.* = .{
        .collapsed = if (summary.collapsed) 1 else 0,
        .direction = summary.direction,
        .moving_voice_count = summary.moving_voice_count,
        .stationary_voice_count = summary.stationary_voice_count,
        .ascending_count = summary.ascending_count,
        .descending_count = summary.descending_count,
        .retained_voice_count = summary.retained_voice_count,
        .reserved0 = 0,
    };
}

fn writeSatbRegisterViolation(out: *LmtSatbRegisterViolation, violation: choir.RegisterViolation) void {
    out.* = .{
        .voice_id = violation.voice_id,
        .satb_voice = @intFromEnum(violation.satb_voice),
        .midi = violation.midi,
        .direction = violation.direction,
        .low = violation.low,
        .high = violation.high,
        .reserved0 = 0,
        .reserved1 = 0,
    };
}

fn writeNextStepSuggestion(out: *LmtNextStepSuggestion, suggestion: counterpoint.NextStepSuggestion) void {
    out.* = .{
        .score = suggestion.score,
        .reason_mask = suggestion.reason_mask,
        .warning_mask = suggestion.warning_mask,
        .cadence_effect = @intFromEnum(suggestion.cadence_effect),
        .tension_delta = suggestion.tension_delta,
        .note_count = suggestion.note_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .set_value = toCSet(suggestion.set_value),
        .notes = [_]u8{0} ** counterpoint.MAX_VOICES,
        .motion = undefined,
        .evaluation = undefined,
    };
    for (suggestion.notes, 0..) |note, index| out.notes[index] = note;
    writeMotionSummary(&out.motion, suggestion.motion);
    writeMotionEvaluation(&out.evaluation, suggestion.evaluation);
}

fn writeContextSuggestion(out: *LmtContextSuggestion, row: keyboard_logic.ContextSuggestion) void {
    out.* = .{
        .score = row.score,
        .expanded_set = toCSet(row.expanded_set),
        .pitch_class = row.pitch_class,
        .overlap = row.overlap,
        .outside_count = row.outside_count,
        .in_context = if (row.in_context) 1 else 0,
        .cluster_free = if (row.cluster_free) 1 else 0,
        .reads_as_named_chord = if (row.reads_as_named_chord) 1 else 0,
    };
}

fn writeCadenceDestinationScore(out: *LmtCadenceDestinationScore, score: counterpoint.CadenceDestinationScore) void {
    out.* = .{
        .score = score.score,
        .destination = @intFromEnum(score.destination),
        .candidate_count = score.candidate_count,
        .warning_count = score.warning_count,
        .current_match = if (score.current_match) 1 else 0,
        .tension_bias = score.tension_bias,
        .reserved0 = 0,
        .reserved1 = 0,
    };
}

fn writeSuspensionMachineSummary(out: *LmtSuspensionMachineSummary, summary: counterpoint.SuspensionMachineSummary) void {
    out.* = .{
        .state = @intFromEnum(summary.state),
        .tracked_voice_id = summary.tracked_voice_id,
        .held_midi = summary.held_midi,
        .expected_resolution_midi = summary.expected_resolution_midi,
        .resolution_direction = summary.resolution_direction,
        .obligation_count = summary.obligation_count,
        .warning_count = summary.warning_count,
        .retained_count = summary.retained_count,
        .current_tension = summary.current_tension,
        .previous_tension = summary.previous_tension,
        .candidate_resolution_count = summary.candidate_resolution_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
    };
}

fn writeOrbifoldTriadNode(out: *LmtOrbifoldTriadNode, node: svg_orbifold.Node) void {
    out.* = .{
        .set_value = toCSet(node.set),
        .root = node.root,
        .quality = switch (node.quality) {
            .major => CHORD_MAJOR,
            .minor => CHORD_MINOR,
            .diminished => CHORD_DIMINISHED,
            .augmented => CHORD_AUGMENTED,
        },
        .x = node.x,
        .y = node.y,
    };
}

fn writeOrbifoldTriadEdge(out: *LmtOrbifoldTriadEdge, edge: svg_orbifold.Edge) void {
    out.* = .{
        .from_index = edge.from_idx,
        .to_index = edge.to_idx,
        .reserved0 = 0,
        .reserved1 = 0,
    };
}

fn writeFretCandidateLocation(out: *LmtFretCandidateLocation, location: playability.fret_topology.WindowedLocation) void {
    out.* = .{
        .position = .{
            .string = @as(u8, @intCast(location.position.string)),
            .fret = location.position.fret,
        },
        .in_window = if (location.in_window) 1 else 0,
        .shift_steps = location.shift_steps,
    };
}

fn writeFretPlayState(out: *LmtFretPlayState, state: playability.fret_topology.PlayState) void {
    out.* = .{
        .anchor_fret = state.anchor_fret,
        .window_start = state.window_start,
        .window_end = state.window_end,
        .lowest_string = state.lowest_string,
        .highest_string = state.highest_string,
        .active_string_count = state.active_string_count,
        .fretted_note_count = state.fretted_note_count,
        .open_string_count = state.open_string_count,
        .span_steps = state.span_steps,
        .comfort_fit = if (state.comfort_fit) 1 else 0,
        .limit_fit = if (state.limit_fit) 1 else 0,
        .reserved0 = 0,
        .load = undefined,
    };
    writeTemporalLoadState(&out.load, state.load);
}

fn writeKeybedKeyCoord(out: *LmtKeybedKeyCoord, coord: playability.keyboard_topology.KeyCoord) void {
    out.* = .{
        .midi = coord.midi,
        .is_black = if (coord.is_black) 1 else 0,
        .octave = coord.octave,
        .degree_in_octave = coord.degree_in_octave,
        .x = coord.x,
        .y = coord.y,
    };
}

fn writeFretRealizationAssessment(
    out: *LmtFretRealizationAssessment,
    assessment: playability.fret_assessment.RealizationAssessment,
) void {
    out.* = .{
        .state = undefined,
        .string_span_steps = assessment.string_span_steps,
        .profile = @intFromEnum(assessment.profile),
        .bottleneck_cost = assessment.bottleneck_cost,
        .cumulative_cost = assessment.cumulative_cost,
        .blocker_bits = assessment.blocker_bits,
        .warning_bits = assessment.warning_bits,
        .reason_bits = assessment.reason_bits,
        .recommended_fingers = assessment.recommended_fingers,
    };
    writeFretPlayState(&out.state, assessment.state);
}

fn writeFretTransitionAssessment(
    out: *LmtFretTransitionAssessment,
    assessment: playability.fret_assessment.TransitionAssessment,
) void {
    out.* = .{
        .from_state = undefined,
        .to_state = undefined,
        .anchor_delta_steps = assessment.anchor_delta_steps,
        .changed_string_count = assessment.changed_string_count,
        .profile = @intFromEnum(assessment.profile),
        .reserved0 = 0,
        .bottleneck_cost = assessment.bottleneck_cost,
        .cumulative_cost = assessment.cumulative_cost,
        .blocker_bits = assessment.blocker_bits,
        .warning_bits = assessment.warning_bits,
        .reason_bits = assessment.reason_bits,
        .recommended_fingers = assessment.recommended_fingers,
    };
    writeFretPlayState(&out.from_state, assessment.from_state);
    writeFretPlayState(&out.to_state, assessment.to_state);
}

fn writeRankedFretRealization(
    out: *LmtRankedFretRealization,
    assessment: playability.fret_assessment.RankedLocation,
) void {
    out.* = .{
        .location = undefined,
        .bottleneck_cost = assessment.bottleneck_cost,
        .cumulative_cost = assessment.cumulative_cost,
        .blocker_bits = assessment.blocker_bits,
        .warning_bits = assessment.warning_bits,
        .reason_bits = assessment.reason_bits,
        .recommended_finger = assessment.recommended_finger,
        .profile = @intFromEnum(assessment.profile),
        .reserved0 = 0,
        .reserved1 = 0,
    };
    writeFretCandidateLocation(&out.location, assessment.location);
}

fn writeKeyboardPlayState(out: *LmtKeyboardPlayState, state: playability.keyboard_topology.PlayState) void {
    out.* = .{
        .anchor_midi = state.anchor_midi,
        .low_midi = state.low_midi,
        .high_midi = state.high_midi,
        .active_note_count = state.active_note_count,
        .black_key_count = state.black_key_count,
        .white_key_count = state.white_key_count,
        .span_semitones = state.span_semitones,
        .comfort_fit = if (state.comfort_fit) 1 else 0,
        .limit_fit = if (state.limit_fit) 1 else 0,
        .reserved0 = 0,
        .load = undefined,
    };
    writeTemporalLoadState(&out.load, state.load);
}

fn writeKeyboardRealizationAssessment(
    out: *LmtKeyboardRealizationAssessment,
    assessment: playability.keyboard_assessment.RealizationAssessment,
) void {
    out.* = .{
        .state = undefined,
        .hand = @intFromEnum(assessment.hand),
        .note_count = assessment.note_count,
        .outer_black_count = assessment.outer_black_count,
        .reserved0 = 0,
        .bottleneck_cost = assessment.bottleneck_cost,
        .cumulative_cost = assessment.cumulative_cost,
        .blocker_bits = assessment.blocker_bits,
        .warning_bits = assessment.warning_bits,
        .reason_bits = assessment.reason_bits,
        .recommended_fingers = assessment.recommended_fingers,
    };
    writeKeyboardPlayState(&out.state, assessment.state);
}

fn writeKeyboardTransitionAssessment(
    out: *LmtKeyboardTransitionAssessment,
    assessment: playability.keyboard_assessment.TransitionAssessment,
) void {
    out.* = .{
        .from_state = undefined,
        .to_state = undefined,
        .hand = @intFromEnum(assessment.hand),
        .note_count = assessment.note_count,
        .anchor_delta_semitones = assessment.anchor_delta_semitones,
        .reserved0 = 0,
        .bottleneck_cost = assessment.bottleneck_cost,
        .cumulative_cost = assessment.cumulative_cost,
        .blocker_bits = assessment.blocker_bits,
        .warning_bits = assessment.warning_bits,
        .reason_bits = assessment.reason_bits,
        .from_fingers = assessment.from_fingers,
        .to_fingers = assessment.to_fingers,
    };
    writeKeyboardPlayState(&out.from_state, assessment.from_state);
    writeKeyboardPlayState(&out.to_state, assessment.to_state);
}

fn writeRankedKeyboardFingering(
    out: *LmtRankedKeyboardFingering,
    row: playability.keyboard_assessment.RankedFingering,
) void {
    out.* = .{
        .hand = @intFromEnum(row.hand),
        .note_count = row.note_count,
        .reserved0 = 0,
        .reserved1 = 0,
        .bottleneck_cost = row.bottleneck_cost,
        .cumulative_cost = row.cumulative_cost,
        .blocker_bits = row.blocker_bits,
        .warning_bits = row.warning_bits,
        .reason_bits = row.reason_bits,
        .fingers = row.fingers,
    };
}

fn writeRankedKeyboardContextSuggestion(
    out: *LmtRankedKeyboardContextSuggestion,
    row: playability.ranking.RankedKeyboardContextSuggestion,
) void {
    out.* = .{
        .candidate = undefined,
        .transition = undefined,
        .realized_note = row.realized_note,
        .candidate_index = row.candidate_index,
        .hand = @intFromEnum(row.hand),
        .policy = @intFromEnum(row.policy),
        .accepted = if (row.accepted) 1 else 0,
        .reserved0 = 0,
    };
    writeContextSuggestion(&out.candidate, row.candidate);
    writeKeyboardTransitionAssessment(&out.transition, row.transition);
}

fn writeRankedKeyboardNextStep(
    out: *LmtRankedKeyboardNextStep,
    row: playability.ranking.RankedKeyboardNextStep,
) void {
    out.* = .{
        .candidate = undefined,
        .transition = undefined,
        .candidate_index = row.candidate_index,
        .hand = @intFromEnum(row.hand),
        .policy = @intFromEnum(row.policy),
        .accepted = if (row.accepted) 1 else 0,
    };
    writeNextStepSuggestion(&out.candidate, row.candidate);
    writeKeyboardTransitionAssessment(&out.transition, row.transition);
}

fn isSelectedGuidePosition(selected_ptr: [*c]const LmtFretPos, selected_count: usize, string: usize, fret: u8) bool {
    if (selected_ptr == null) return false;

    var i: usize = 0;
    while (i < selected_count) : (i += 1) {
        const pos = selected_ptr[i];
        if (pos.string == @as(u8, @intCast(@min(string, @as(usize, 255)))) and pos.fret == fret) {
            return true;
        }
    }

    return false;
}

fn selectedGuidePitchClasses(selected_ptr: [*c]const LmtFretPos, selected_count: usize, tuning: []const pitch.MidiNote) pcs.PitchClassSet {
    if (selected_ptr == null or selected_count == 0 or tuning.len == 0) return 0;

    var out: pcs.PitchClassSet = 0;
    var i: usize = 0;
    while (i < selected_count) : (i += 1) {
        const pos = selected_ptr[i];
        const midi = guitar.fretToMidiGeneric(pos.string, pos.fret, tuning) orelse continue;
        const pc = @as(pitch.PitchClass, @intCast(midi % 12));
        out |= @as(pcs.PitchClassSet, 1) << pc;
    }

    return out;
}

fn parseUrlFretToken(raw_token: []const u8) ?i8 {
    const token = std.mem.trim(u8, raw_token, " \t\r\n");
    if (token.len == 0) return null;

    const parsed = std.fmt.parseInt(i16, token, 10) catch return null;
    if (parsed < -1 or parsed > std.math.maxInt(i8)) return null;
    return @as(i8, @intCast(parsed));
}

fn writeCString(text: []const u8) [*c]const u8 {
    const slot = &c_string_slots[c_string_slot_index % c_string_slots.len];
    c_string_slot_index += 1;

    const n = @min(text.len, slot.len - 1);
    std.mem.copyForwards(u8, slot[0..n], text[0..n]);
    slot[n] = 0;

    return &slot[0];
}

fn copySvgOut(svg: []const u8, buf: [*c]u8, buf_size: u32) u32 {
    const total = @as(u32, @intCast(svg.len));
    if (buf == null or buf_size == 0) return total;

    const cap = @as(usize, @intCast(buf_size));
    const copy_len = @min(svg.len, cap - 1);
    if (copy_len > 0) {
        std.mem.copyForwards(u8, buf[0..copy_len], svg[0..copy_len]);
    }
    buf[copy_len] = 0;

    return total;
}

fn requiredRgbaBytes(width: u32, height: u32) ?u32 {
    const required: u64 = @as(u64, width) * @as(u64, height) * 4;
    if (width == 0 or height == 0 or required == 0 or required > std.math.maxInt(u32)) return null;
    return @as(u32, @intCast(required));
}

fn renderPublicSvgBitmap(svg: []const u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;

    const required = requiredRgbaBytes(width, height) orelse return 0;
    if (required > out_rgba_size) return 0;

    const out = out_rgba[0..@as(usize, required)];
    const written = bitmap_compat.renderSvgMarkupRgba(width, height, svg, out) catch return 0;
    return @as(u32, @intCast(written));
}

pub export fn lmt_wasm_scratch_ptr() callconv(.c) [*c]u8 {
    return &wasm_client_scratch[0];
}

pub export fn lmt_wasm_scratch_size() callconv(.c) u32 {
    return @as(u32, @intCast(wasm_client_scratch.len));
}

pub export fn lmt_pcs_from_list(pcs_ptr: [*c]const u8, count: u8) callconv(.c) u16 {
    if (pcs_ptr == null or count == 0) return 0;

    var list_buf: [12]pitch.PitchClass = undefined;
    const len = @min(@as(usize, count), list_buf.len);

    var i: usize = 0;
    while (i < len) : (i += 1) {
        list_buf[i] = @as(pitch.PitchClass, @intCast(pcs_ptr[i] % 12));
    }

    return toCSet(pcs.fromList(list_buf[0..len]));
}

pub export fn lmt_pcs_to_list(set: u16, out: [*c]u8) callconv(.c) u8 {
    var tmp: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(maskPitchClassSet(set), &tmp);

    if (out != null) {
        for (list, 0..) |pc, i| {
            out[i] = @as(u8, pc);
        }
    }

    return @as(u8, @intCast(list.len));
}

pub export fn lmt_pcs_cardinality(set: u16) callconv(.c) u8 {
    return @as(u8, pcs.cardinality(maskPitchClassSet(set)));
}

pub export fn lmt_pcs_transpose(set: u16, semitones: u8) callconv(.c) u16 {
    const value = pcs.transpose(maskPitchClassSet(set), @as(u4, @intCast(semitones % 12)));
    return toCSet(value);
}

pub export fn lmt_pcs_invert(set: u16) callconv(.c) u16 {
    return toCSet(pcs.invert(maskPitchClassSet(set)));
}

pub export fn lmt_pcs_complement(set: u16) callconv(.c) u16 {
    return toCSet(pcs.complement(maskPitchClassSet(set)));
}

pub export fn lmt_pcs_is_subset(small: u16, big: u16) callconv(.c) bool {
    return pcs.isSubsetOf(maskPitchClassSet(small), maskPitchClassSet(big));
}

pub export fn lmt_prime_form(set: u16) callconv(.c) u16 {
    return toCSet(set_class.primeForm(maskPitchClassSet(set)));
}

pub export fn lmt_forte_prime(set: u16) callconv(.c) u16 {
    return toCSet(set_class.fortePrime(maskPitchClassSet(set)));
}

pub export fn lmt_is_cluster_free(set: u16) callconv(.c) bool {
    return !cluster.hasCluster(maskPitchClassSet(set));
}

pub export fn lmt_evenness_distance(set: u16) callconv(.c) f32 {
    return evenness.evennessDistance(maskPitchClassSet(set));
}

pub export fn lmt_scale(scale_type: u8, tonic: u8) callconv(.c) u16 {
    const st = decodeScaleType(scale_type) orelse return 0;
    const root = @as(pitch.PitchClass, @intCast(tonic % 12));
    return toCSet(pcs.transpose(scale.pcsForType(st), root));
}

pub export fn lmt_mode(mode_type: u8, root: u8) callconv(.c) u16 {
    const mt = decodeModeType(mode_type) orelse return 0;
    const base = modeSet(mt);
    const tonic = @as(pitch.PitchClass, @intCast(root % 12));
    return toCSet(pcs.transpose(base, tonic));
}

pub export fn lmt_mode_type_count() callconv(.c) u32 {
    return @as(u32, @intCast(mode.count()));
}

pub export fn lmt_mode_type_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= mode.count()) return null;
    return writeCString(mode.name(@enumFromInt(@as(u8, @intCast(index)))));
}

pub export fn lmt_ordered_scale_pattern_count() callconv(.c) u32 {
    return @as(u32, @intCast(ordered_scale.count()));
}

pub export fn lmt_ordered_scale_pattern_name(index: u32) callconv(.c) [*c]const u8 {
    const pattern_id = decodeOrderedScalePattern(index) orelse return null;
    return writeCString(ordered_scale.info(pattern_id).name);
}

pub export fn lmt_ordered_scale_degree_count(index: u32) callconv(.c) u8 {
    const pattern_id = decodeOrderedScalePattern(index) orelse return 0;
    return ordered_scale.info(pattern_id).degree_count;
}

pub export fn lmt_ordered_scale_pitch_class_set(index: u32, tonic: u8) callconv(.c) u16 {
    const pattern_id = decodeOrderedScalePattern(index) orelse return 0;
    return toCSet(ordered_scale.rootedPitchClassSet(pattern_id, @as(pitch.PitchClass, @intCast(tonic % 12))));
}

pub export fn lmt_barry_harris_parity(index: u32, tonic: u8, note: u8, out_degree: [*c]u8) callconv(.c) u8 {
    if (note > 127) return 0;
    const pattern_id = decodeOrderedScalePattern(index) orelse return 0;
    const parity = ordered_scale.barryHarrisParity(
        pattern_id,
        @as(pitch.PitchClass, @intCast(tonic % 12)),
        @as(pitch.MidiNote, @intCast(note)),
    ) orelse return 0;
    if (out_degree != null) out_degree[0] = parity.degree;
    return switch (parity.kind) {
        .chord_tone => 1,
        .passing_tone => 2,
    };
}

pub export fn lmt_playability_reason_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.types.REASON_NAMES.len));
}

pub export fn lmt_playability_reason_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.types.REASON_NAMES.len) return null;
    return writeCString(playability.types.REASON_NAMES[idx]);
}

pub export fn lmt_playability_warning_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.types.WARNING_NAMES.len));
}

pub export fn lmt_playability_warning_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.types.WARNING_NAMES.len) return null;
    return writeCString(playability.types.WARNING_NAMES[idx]);
}

pub export fn lmt_fret_playability_blocker_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.fret_assessment.BLOCKER_NAMES.len));
}

pub export fn lmt_fret_playability_blocker_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.fret_assessment.BLOCKER_NAMES.len) return null;
    return writeCString(playability.fret_assessment.BLOCKER_NAMES[idx]);
}

pub export fn lmt_fret_technique_profile_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.fret_assessment.PROFILE_NAMES.len));
}

pub export fn lmt_fret_technique_profile_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.fret_assessment.PROFILE_NAMES.len) return null;
    return writeCString(playability.fret_assessment.PROFILE_NAMES[idx]);
}

pub export fn lmt_keyboard_hand_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.keyboard_assessment.HAND_ROLE_NAMES.len));
}

pub export fn lmt_keyboard_hand_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.keyboard_assessment.HAND_ROLE_NAMES.len) return null;
    return writeCString(playability.keyboard_assessment.HAND_ROLE_NAMES[idx]);
}

pub export fn lmt_keyboard_playability_blocker_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.keyboard_assessment.BLOCKER_NAMES.len));
}

pub export fn lmt_keyboard_playability_blocker_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.keyboard_assessment.BLOCKER_NAMES.len) return null;
    return writeCString(playability.keyboard_assessment.BLOCKER_NAMES[idx]);
}

pub export fn lmt_playability_policy_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.ranking.POLICY_NAMES.len));
}

pub export fn lmt_playability_policy_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.ranking.POLICY_NAMES.len) return null;
    return writeCString(playability.ranking.POLICY_NAMES[idx]);
}

pub export fn lmt_playability_profile_preset_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.profile.PRESET_NAMES.len));
}

pub export fn lmt_playability_profile_preset_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.profile.PRESET_NAMES.len) return null;
    return writeCString(playability.profile.PRESET_NAMES[idx]);
}

pub export fn lmt_playability_profile_from_preset(
    preset_raw: u32,
    base_profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtHandProfile,
) callconv(.c) u32 {
    if (base_profile_ptr == null or out == null) return 0;
    const preset = decodePlayabilityProfilePreset(preset_raw) orelse return 0;
    const resolved = playability.profile.applyPreset(decodeHandProfile(base_profile_ptr[0]), preset);
    writeHandProfile(@ptrCast(out), resolved);
    return 1;
}

pub export fn lmt_playability_phrase_issue_scope_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.phrase.ISSUE_SCOPE_NAMES.len));
}

pub export fn lmt_playability_phrase_issue_scope_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.phrase.ISSUE_SCOPE_NAMES.len) return null;
    return writeCString(playability.phrase.ISSUE_SCOPE_NAMES[idx]);
}

pub export fn lmt_playability_phrase_issue_severity_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.phrase.ISSUE_SEVERITY_NAMES.len));
}

pub export fn lmt_playability_phrase_issue_severity_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.phrase.ISSUE_SEVERITY_NAMES.len) return null;
    return writeCString(playability.phrase.ISSUE_SEVERITY_NAMES[idx]);
}

pub export fn lmt_playability_phrase_family_domain_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.phrase.FAMILY_DOMAIN_NAMES.len));
}

pub export fn lmt_playability_phrase_family_domain_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.phrase.FAMILY_DOMAIN_NAMES.len) return null;
    return writeCString(playability.phrase.FAMILY_DOMAIN_NAMES[idx]);
}

pub export fn lmt_playability_phrase_strain_bucket_count() callconv(.c) u32 {
    return @as(u32, @intCast(playability.phrase.STRAIN_BUCKET_NAMES.len));
}

pub export fn lmt_playability_phrase_strain_bucket_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= playability.phrase.STRAIN_BUCKET_NAMES.len) return null;
    return writeCString(playability.phrase.STRAIN_BUCKET_NAMES[idx]);
}

pub export fn lmt_scale_degree(tonic: u8, mode_type: u8, note: u8) callconv(.c) u8 {
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const midi_note = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const degree = mode.degreeOfNote(tonic_pc, mt, midi_note) orelse return 0;
    return degree + 1;
}

pub export fn lmt_transpose_diatonic(tonic: u8, mode_type: u8, note: u8, degrees: i8, out: [*c]u8) callconv(.c) u32 {
    if (out == null) return 0;
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const midi_note = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const transposed = mode.transposeDiatonic(tonic_pc, mt, midi_note, degrees) orelse return 0;
    out[0] = transposed;
    return 1;
}

pub export fn lmt_nearest_scale_tones(tonic: u8, mode_type: u8, note: u8, out: [*c]LmtScaleSnapCandidates) callconv(.c) u32 {
    if (out == null) return 0;
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const midi_note = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const neighbors = mode.nearestScaleNeighbors(tonic_pc, mt, midi_note);
    out[0] = .{
        .in_scale = @intFromBool(neighbors.in_scale),
        .has_lower = @intFromBool(neighbors.has_lower),
        .has_upper = @intFromBool(neighbors.has_upper),
        .reserved0 = 0,
        .lower = neighbors.lower,
        .upper = neighbors.upper,
        .lower_distance = neighbors.lower_distance,
        .upper_distance = neighbors.upper_distance,
    };
    return 1;
}

pub export fn lmt_snap_to_scale(tonic: u8, mode_type: u8, note: u8, policy: u8, out: [*c]u8) callconv(.c) u32 {
    if (out == null) return 0;
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const midi_note = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const snapped = mode.snapToScale(tonic_pc, mt, midi_note, decodeSnapTiePolicy(policy)) orelse return 0;
    out[0] = snapped;
    return 1;
}

pub export fn lmt_find_containing_modes(
    note_pc: u8,
    tonic: u8,
    modes_ptr: [*c]const u8,
    mode_count: u8,
    out: [*c]LmtContainingModeMatch,
    out_len: u8,
) callconv(.c) u8 {
    if (mode_count > 0 and modes_ptr == null) return 0;
    if (out_len > 0 and out == null) return 0;

    var mode_buf: [modal_interchange.MAX_MATCHES]mode.ModeType = undefined;
    const requested = mode_buf[0..mode_count];
    for (requested, 0..) |*slot, index| {
        slot.* = decodeModeType(modes_ptr[index]) orelse return 0;
    }

    var matches_buf: [modal_interchange.MAX_MATCHES]modal_interchange.ContainingModeMatch = undefined;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const total = modal_interchange.findContainingModes(@as(pitch.PitchClass, @intCast(note_pc % 12)), tonic_pc, requested, matches_buf[0..]);
    const write_count = @min(@as(usize, total), @as(usize, out_len));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        out[index] = .{
            .mode = @intFromEnum(matches_buf[index].mode),
            .degree = matches_buf[index].degree,
            .reserved0 = 0,
            .reserved1 = 0,
        };
    }
    return total;
}

pub export fn lmt_chord_pattern_count() callconv(.c) u32 {
    return @as(u32, @intCast(chord_detection.count()));
}

pub export fn lmt_chord_pattern_name(index: u32) callconv(.c) [*c]const u8 {
    const pattern_id = chord_detection.fromInt(@as(u8, @intCast(index))) orelse return null;
    return writeCString(chord_detection.pattern(pattern_id).name);
}

pub export fn lmt_chord_pattern_formula(index: u32) callconv(.c) [*c]const u8 {
    const pattern_id = chord_detection.fromInt(@as(u8, @intCast(index))) orelse return null;
    return writeCString(chord_detection.pattern(pattern_id).formula);
}

pub export fn lmt_detect_chord_matches(
    set: u16,
    bass: u8,
    bass_known: bool,
    out: [*c]LmtChordMatch,
    out_len: u8,
) callconv(.c) u16 {
    if (out_len > 0 and out == null) return 0;
    const chord_set = maskPitchClassSet(set);
    if (chord_set == 0) return 0;

    var matches_buf: [chord_detection.MAX_MATCHES]chord_detection.Match = undefined;
    const total = chord_detection.detectMatches(
        chord_set,
        bass_known,
        @as(pitch.PitchClass, @intCast(bass % 12)),
        matches_buf[0..],
    );
    const write_count = @min(@as(usize, total), @as(usize, out_len));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        out[index] = .{
            .root = matches_buf[index].root,
            .bass = matches_buf[index].bass,
            .pattern = @intFromEnum(matches_buf[index].pattern),
            .interval_count = matches_buf[index].interval_count,
            .bass_known = @intFromBool(matches_buf[index].bass_known),
            .root_is_bass = @intFromBool(matches_buf[index].root_is_bass),
            .bass_degree = matches_buf[index].bass_degree,
            .reserved0 = 0,
        };
    }
    return total;
}

pub export fn lmt_counterpoint_max_voices() callconv(.c) u32 {
    return @as(u32, counterpoint.MAX_VOICES);
}

pub export fn lmt_counterpoint_history_capacity() callconv(.c) u32 {
    return @as(u32, counterpoint.HISTORY_CAPACITY);
}

pub export fn lmt_counterpoint_rule_profile_count() callconv(.c) u32 {
    return @as(u32, @intCast(COUNTERPOINT_RULE_PROFILE_NAMES.len));
}

pub export fn lmt_counterpoint_rule_profile_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= COUNTERPOINT_RULE_PROFILE_NAMES.len) return null;
    return writeCString(COUNTERPOINT_RULE_PROFILE_NAMES[idx]);
}

pub export fn lmt_voice_leading_violation_kind_count() callconv(.c) u32 {
    return @as(u32, @intCast(voice_leading_rules.VIOLATION_KIND_NAMES.len));
}

pub export fn lmt_voice_leading_violation_kind_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= voice_leading_rules.VIOLATION_KIND_NAMES.len) return null;
    return writeCString(voice_leading_rules.VIOLATION_KIND_NAMES[idx]);
}

pub export fn lmt_satb_voice_count() callconv(.c) u32 {
    return @as(u32, @intCast(choir.SATB_VOICE_NAMES.len));
}

pub export fn lmt_satb_voice_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= choir.SATB_VOICE_NAMES.len) return null;
    return writeCString(choir.SATB_VOICE_NAMES[idx]);
}

pub export fn lmt_sizeof_hand_profile() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtHandProfile)));
}

pub export fn lmt_sizeof_temporal_load_state() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtTemporalLoadState)));
}

pub export fn lmt_sizeof_fret_candidate_location() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretCandidateLocation)));
}

pub export fn lmt_sizeof_fret_play_state() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretPlayState)));
}

pub export fn lmt_sizeof_fret_realization_assessment() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretRealizationAssessment)));
}

pub export fn lmt_sizeof_fret_transition_assessment() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretTransitionAssessment)));
}

pub export fn lmt_sizeof_ranked_fret_realization() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtRankedFretRealization)));
}

pub export fn lmt_sizeof_keybed_key_coord() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeybedKeyCoord)));
}

pub export fn lmt_sizeof_keyboard_play_state() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeyboardPlayState)));
}

pub export fn lmt_sizeof_keyboard_realization_assessment() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeyboardRealizationAssessment)));
}

pub export fn lmt_sizeof_keyboard_transition_assessment() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeyboardTransitionAssessment)));
}

pub export fn lmt_sizeof_ranked_keyboard_fingering() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtRankedKeyboardFingering)));
}

pub export fn lmt_sizeof_ranked_keyboard_context_suggestion() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtRankedKeyboardContextSuggestion)));
}

pub export fn lmt_sizeof_ranked_keyboard_next_step() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtRankedKeyboardNextStep)));
}

pub export fn lmt_sizeof_playability_difficulty_summary() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtPlayabilityDifficultySummary)));
}

pub export fn lmt_sizeof_keyboard_phrase_event() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeyboardPhraseEvent)));
}

pub export fn lmt_sizeof_fret_phrase_event() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretPhraseEvent)));
}

pub export fn lmt_sizeof_keyboard_committed_phrase_memory() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtKeyboardCommittedPhraseMemory)));
}

pub export fn lmt_sizeof_fret_committed_phrase_memory() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtFretCommittedPhraseMemory)));
}

pub export fn lmt_sizeof_playability_phrase_issue() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtPlayabilityPhraseIssue)));
}

pub export fn lmt_sizeof_playability_phrase_summary() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtPlayabilityPhraseSummary)));
}

pub export fn lmt_sizeof_voiced_state() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtVoicedState)));
}

pub export fn lmt_sizeof_voiced_history() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtVoicedHistory)));
}

pub export fn lmt_sizeof_next_step_suggestion() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtNextStepSuggestion)));
}

pub export fn lmt_sizeof_voice_pair_violation() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtVoicePairViolation)));
}

pub export fn lmt_sizeof_motion_independence_summary() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtMotionIndependenceSummary)));
}

pub export fn lmt_sizeof_satb_register_violation() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtSatbRegisterViolation)));
}

pub export fn lmt_cadence_destination_count() callconv(.c) u32 {
    return @as(u32, @intCast(counterpoint.CADENCE_DESTINATION_NAMES.len));
}

pub export fn lmt_cadence_destination_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= counterpoint.CADENCE_DESTINATION_NAMES.len) return null;
    return writeCString(counterpoint.CADENCE_DESTINATION_NAMES[idx]);
}

pub export fn lmt_suspension_state_count() callconv(.c) u32 {
    return @as(u32, @intCast(counterpoint.SUSPENSION_STATE_NAMES.len));
}

pub export fn lmt_suspension_state_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= counterpoint.SUSPENSION_STATE_NAMES.len) return null;
    return writeCString(counterpoint.SUSPENSION_STATE_NAMES[idx]);
}

pub export fn lmt_sizeof_cadence_destination_score() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtCadenceDestinationScore)));
}

pub export fn lmt_sizeof_suspension_machine_summary() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtSuspensionMachineSummary)));
}

pub export fn lmt_orbifold_triad_node_count() callconv(.c) u32 {
    return @as(u32, @intCast(svg_orbifold.NODE_COUNT));
}

pub export fn lmt_sizeof_orbifold_triad_node() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtOrbifoldTriadNode)));
}

pub export fn lmt_orbifold_triad_node_at(index: u32, out: [*c]LmtOrbifoldTriadNode) callconv(.c) u32 {
    if (out == null or index >= svg_orbifold.NODE_COUNT) return 0;

    var nodes_buf: [svg_orbifold.NODE_COUNT]svg_orbifold.Node = undefined;
    const nodes = svg_orbifold.enumerateTriadNodes(&nodes_buf);
    const out_node: *LmtOrbifoldTriadNode = @ptrCast(out);
    writeOrbifoldTriadNode(out_node, nodes[index]);
    return 1;
}

pub export fn lmt_find_orbifold_triad_node(set: u16) callconv(.c) u32 {
    const safe_set = maskPitchClassSet(set);
    var nodes_buf: [svg_orbifold.NODE_COUNT]svg_orbifold.Node = undefined;
    const nodes = svg_orbifold.enumerateTriadNodes(&nodes_buf);
    if (safe_set == 0) return @as(u32, @intCast(svg_orbifold.NODE_COUNT));
    for (nodes, 0..) |node, index| {
        if (node.set == safe_set) return @as(u32, @intCast(index));
    }

    var best_index: usize = svg_orbifold.NODE_COUNT;
    var best_score: i32 = std.math.minInt(i32);
    for (nodes, 0..) |node, index| {
        const overlap = pcs.cardinality(node.set & safe_set);
        if (overlap < 2) continue;

        const outside = pcs.cardinality(safe_set & ~node.set);
        var score: i32 = @as(i32, overlap) * 32 - @as(i32, outside) * 10;
        if (pcs.isSubsetOf(node.set, safe_set)) score += 24;
        if ((safe_set & (@as(u16, 1) << @as(u4, @intCast(node.root)))) != 0) score += 4;
        score += switch (node.quality) {
            .major, .minor => 2,
            .diminished, .augmented => 1,
        };
        if (score > best_score) {
            best_score = score;
            best_index = index;
        }
    }

    return @as(u32, @intCast(best_index));
}

pub export fn lmt_orbifold_triad_edge_count() callconv(.c) u32 {
    var nodes_buf: [svg_orbifold.NODE_COUNT]svg_orbifold.Node = undefined;
    const nodes = svg_orbifold.enumerateTriadNodes(&nodes_buf);
    var edges_buf: [svg_orbifold.MAX_EDGES]svg_orbifold.Edge = undefined;
    const edges = svg_orbifold.buildTriadEdges(nodes, &edges_buf);
    return @as(u32, @intCast(edges.len));
}

pub export fn lmt_sizeof_orbifold_triad_edge() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtOrbifoldTriadEdge)));
}

pub export fn lmt_default_fret_hand_profile(out: [*c]LmtHandProfile) callconv(.c) u32 {
    if (out == null) return 0;
    const out_profile: *LmtHandProfile = @ptrCast(out);
    writeHandProfile(out_profile, playability.fret_topology.defaultHandProfile());
    return 1;
}

pub export fn lmt_default_fret_hand_profile_for_technique(profile_raw: u32, out: [*c]LmtHandProfile) callconv(.c) u32 {
    if (out == null) return 0;
    const profile = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const out_profile: *LmtHandProfile = @ptrCast(out);
    writeHandProfile(out_profile, playability.fret_assessment.defaultHandProfile(profile));
    return 1;
}

pub export fn lmt_default_keyboard_hand_profile(out: [*c]LmtHandProfile) callconv(.c) u32 {
    if (out == null) return 0;
    const out_profile: *LmtHandProfile = @ptrCast(out);
    writeHandProfile(out_profile, playability.keyboard_topology.defaultHandProfile());
    return 1;
}

pub export fn lmt_summarize_playability_phrase_issues(
    event_count: u32,
    issues_ptr: [*c]const LmtPlayabilityPhraseIssue,
    issue_count: u32,
    out: [*c]LmtPlayabilityPhraseSummary,
) callconv(.c) u32 {
    if (out == null) return 0;
    if (event_count > playability.phrase.MAX_PHRASE_EVENTS) return 0;

    var accumulator = playability.phrase.SummaryAccumulator.init(event_count);
    if (issues_ptr != null) {
        const len = @as(usize, @intCast(issue_count));
        var index: usize = 0;
        while (index < len) : (index += 1) {
            const issue = decodePhraseIssue(issues_ptr[index]) orelse continue;
            accumulator.observeIssue(issue, index);
        }
    }

    writePhraseSummary(@ptrCast(out), accumulator.finish());
    return 1;
}

pub export fn lmt_keyboard_committed_phrase_reset(memory_ptr: [*c]LmtKeyboardCommittedPhraseMemory) callconv(.c) void {
    if (memory_ptr == null) return;
    writeKeyboardCommittedPhraseMemory(@ptrCast(memory_ptr), playability.phrase.KeyboardCommittedPhraseMemory.init());
}

pub export fn lmt_keyboard_committed_phrase_push(
    memory_ptr: [*c]LmtKeyboardCommittedPhraseMemory,
    event_ptr: [*c]const LmtKeyboardPhraseEvent,
) callconv(.c) u32 {
    if (memory_ptr == null or event_ptr == null) return 0;

    var memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;
    const event = decodeKeyboardPhraseEvent((@as(*const LmtKeyboardPhraseEvent, @ptrCast(event_ptr))).*) orelse return 0;
    if (!memory.push(event)) return 0;
    writeKeyboardCommittedPhraseMemory(@ptrCast(memory_ptr), memory);
    return @as(u32, memory.event_count);
}

pub export fn lmt_keyboard_committed_phrase_len(memory_ptr: [*c]const LmtKeyboardCommittedPhraseMemory) callconv(.c) u32 {
    if (memory_ptr == null) return 0;
    const memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;
    return @as(u32, memory.event_count);
}

pub export fn lmt_fret_committed_phrase_reset(memory_ptr: [*c]LmtFretCommittedPhraseMemory) callconv(.c) void {
    if (memory_ptr == null) return;
    writeFretCommittedPhraseMemory(@ptrCast(memory_ptr), playability.phrase.FretCommittedPhraseMemory.init());
}

pub export fn lmt_fret_committed_phrase_push(
    memory_ptr: [*c]LmtFretCommittedPhraseMemory,
    event_ptr: [*c]const LmtFretPhraseEvent,
) callconv(.c) u32 {
    if (memory_ptr == null or event_ptr == null) return 0;

    var memory = decodeFretCommittedPhraseMemory((@as(*const LmtFretCommittedPhraseMemory, @ptrCast(memory_ptr))).*);
    const event = decodeFretPhraseEvent((@as(*const LmtFretPhraseEvent, @ptrCast(event_ptr))).*);
    if (!memory.push(event)) return 0;
    writeFretCommittedPhraseMemory(@ptrCast(memory_ptr), memory);
    return @as(u32, memory.event_count);
}

pub export fn lmt_fret_committed_phrase_len(memory_ptr: [*c]const LmtFretCommittedPhraseMemory) callconv(.c) u32 {
    if (memory_ptr == null) return 0;
    const memory = decodeFretCommittedPhraseMemory((@as(*const LmtFretCommittedPhraseMemory, @ptrCast(memory_ptr))).*);
    return @as(u32, memory.event_count);
}

pub export fn lmt_audit_fret_phrase_n(
    events_ptr: [*c]const LmtFretPhraseEvent,
    event_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    issues_out: [*c]LmtPlayabilityPhraseIssue,
    issues_cap: u32,
    summary_out: [*c]LmtPlayabilityPhraseSummary,
) callconv(.c) u32 {
    if (event_count > playability.phrase.MAX_PHRASE_EVENTS) return 0;
    if (event_count > 0 and events_ptr == null) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0) return 0;

    const technique = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;

    const bounded_event_count = @as(usize, @intCast(event_count));
    var events_buf: [playability.phrase.MAX_PHRASE_EVENTS]playability.phrase.FretPhraseEvent = undefined;
    for (0..bounded_event_count) |index| {
        events_buf[index] = decodeFretPhraseEvent(events_ptr[index]);
        if (events_buf[index].fret_count > tuning.len) return 0;
    }

    var issues_buf: [playability.phrase.MAX_PHRASE_AUDIT_ISSUES]playability.phrase.PhraseIssue = undefined;
    const out_cap = if (issues_out != null)
        @min(@as(usize, @intCast(issues_cap)), issues_buf.len)
    else
        0;
    const result = playability.phrase.auditFretPhrase(
        events_buf[0..bounded_event_count],
        tuning,
        technique,
        hand_profile,
        issues_buf[0..out_cap],
    );

    if (issues_out != null) {
        const write_len = @min(result.written_issue_count, @as(usize, @intCast(issues_cap)));
        for (issues_buf[0..write_len], 0..) |issue, index| {
            writePhraseIssue(@ptrCast(&issues_out[index]), issue);
        }
    }
    if (summary_out != null) {
        writePhraseSummary(@ptrCast(summary_out), result.summary);
    }
    return @as(u32, @intCast(result.logical_issue_count));
}

pub export fn lmt_audit_committed_fret_phrase_n(
    memory_ptr: [*c]const LmtFretCommittedPhraseMemory,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    issues_out: [*c]LmtPlayabilityPhraseIssue,
    issues_cap: u32,
    summary_out: [*c]LmtPlayabilityPhraseSummary,
) callconv(.c) u32 {
    if (memory_ptr == null) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0) return 0;

    const technique = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;
    const memory = decodeFretCommittedPhraseMemory((@as(*const LmtFretCommittedPhraseMemory, @ptrCast(memory_ptr))).*);

    var issues_buf: [playability.phrase.MAX_PHRASE_AUDIT_ISSUES]playability.phrase.PhraseIssue = undefined;
    const out_cap = if (issues_out != null)
        @min(@as(usize, @intCast(issues_cap)), issues_buf.len)
    else
        0;
    const result = playability.phrase.auditCommittedFretPhrase(
        &memory,
        tuning,
        technique,
        hand_profile,
        issues_buf[0..out_cap],
    );

    if (issues_out != null) {
        const write_len = @min(result.written_issue_count, @as(usize, @intCast(issues_cap)));
        for (issues_buf[0..write_len], 0..) |issue, index| {
            writePhraseIssue(@ptrCast(&issues_out[index]), issue);
        }
    }
    if (summary_out != null) {
        writePhraseSummary(@ptrCast(summary_out), result.summary);
    }
    return @as(u32, @intCast(result.logical_issue_count));
}

pub export fn lmt_audit_keyboard_phrase_n(
    events_ptr: [*c]const LmtKeyboardPhraseEvent,
    event_count: u32,
    profile_ptr: [*c]const LmtHandProfile,
    issues_out: [*c]LmtPlayabilityPhraseIssue,
    issues_cap: u32,
    summary_out: [*c]LmtPlayabilityPhraseSummary,
) callconv(.c) u32 {
    if (event_count > playability.phrase.MAX_PHRASE_EVENTS) return 0;
    if (event_count > 0 and events_ptr == null) return 0;

    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();

    const bounded_event_count = @as(usize, @intCast(event_count));
    var events_buf: [playability.phrase.MAX_PHRASE_EVENTS]playability.phrase.KeyboardPhraseEvent = undefined;
    for (0..bounded_event_count) |index| {
        events_buf[index] = decodeKeyboardPhraseEvent(events_ptr[index]) orelse return 0;
    }

    var issues_buf: [playability.phrase.MAX_PHRASE_AUDIT_ISSUES]playability.phrase.PhraseIssue = undefined;
    const out_cap = if (issues_out != null)
        @min(@as(usize, @intCast(issues_cap)), issues_buf.len)
    else
        0;
    const result = playability.phrase.auditKeyboardPhrase(
        events_buf[0..bounded_event_count],
        profile,
        issues_buf[0..out_cap],
    );

    if (issues_out != null) {
        const write_len = @min(result.written_issue_count, @as(usize, @intCast(issues_cap)));
        for (issues_buf[0..write_len], 0..) |issue, index| {
            writePhraseIssue(@ptrCast(&issues_out[index]), issue);
        }
    }
    if (summary_out != null) {
        writePhraseSummary(@ptrCast(summary_out), result.summary);
    }
    return @as(u32, @intCast(result.logical_issue_count));
}

pub export fn lmt_audit_committed_keyboard_phrase_n(
    memory_ptr: [*c]const LmtKeyboardCommittedPhraseMemory,
    profile_ptr: [*c]const LmtHandProfile,
    issues_out: [*c]LmtPlayabilityPhraseIssue,
    issues_cap: u32,
    summary_out: [*c]LmtPlayabilityPhraseSummary,
) callconv(.c) u32 {
    if (memory_ptr == null) return 0;

    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;

    var issues_buf: [playability.phrase.MAX_PHRASE_AUDIT_ISSUES]playability.phrase.PhraseIssue = undefined;
    const out_cap = if (issues_out != null)
        @min(@as(usize, @intCast(issues_cap)), issues_buf.len)
    else
        0;
    const result = playability.phrase.auditCommittedKeyboardPhrase(&memory, profile, issues_buf[0..out_cap]);

    if (issues_out != null) {
        const write_len = @min(result.written_issue_count, @as(usize, @intCast(issues_cap)));
        for (issues_buf[0..write_len], 0..) |issue, index| {
            writePhraseIssue(@ptrCast(&issues_out[index]), issue);
        }
    }
    if (summary_out != null) {
        writePhraseSummary(@ptrCast(summary_out), result.summary);
    }
    return @as(u32, @intCast(result.logical_issue_count));
}

pub export fn lmt_orbifold_triad_edge_at(index: u32, out: [*c]LmtOrbifoldTriadEdge) callconv(.c) u32 {
    if (out == null) return 0;

    var nodes_buf: [svg_orbifold.NODE_COUNT]svg_orbifold.Node = undefined;
    const nodes = svg_orbifold.enumerateTriadNodes(&nodes_buf);
    var edges_buf: [svg_orbifold.MAX_EDGES]svg_orbifold.Edge = undefined;
    const edges = svg_orbifold.buildTriadEdges(nodes, &edges_buf);
    if (index >= edges.len) return 0;

    const out_edge: *LmtOrbifoldTriadEdge = @ptrCast(out);
    writeOrbifoldTriadEdge(out_edge, edges[index]);
    return 1;
}

pub export fn lmt_voiced_history_reset(history: [*c]LmtVoicedHistory) callconv(.c) void {
    if (history == null) return;
    const out_history: *LmtVoicedHistory = @ptrCast(history);
    writeVoicedHistory(out_history, counterpoint.VoicedHistoryWindow.init());
}

pub export fn lmt_build_voiced_state(
    notes_ptr: [*c]const u8,
    note_count: u32,
    sustained_ptr: [*c]const u8,
    sustained_count: u32,
    tonic: u8,
    mode_type: u8,
    beat_in_bar: u8,
    beats_per_bar: u8,
    subdivision: u8,
    cadence_hint: u8,
    previous: [*c]const LmtVoicedState,
    out: [*c]LmtVoicedState,
) callconv(.c) u32 {
    if (out == null) return 0;
    const out_state: *LmtVoicedState = @ptrCast(out);
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    var sustained_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const sustained_notes = decodeMidiNotes(sustained_ptr, sustained_count, &sustained_buf);
    var previous_state_storage: counterpoint.VoicedState = undefined;
    const previous_state: ?*const counterpoint.VoicedState = if (previous != null) blk: {
        previous_state_storage = decodeVoicedState(previous[0]);
        break :blk &previous_state_storage;
    } else null;
    const built = counterpoint.buildVoicedState(
        notes,
        sustained_notes,
        tonic_pc,
        mt,
        decodeMetricPosition(beat_in_bar, beats_per_bar, subdivision),
        decodeCadenceState(cadence_hint),
        previous_state,
        if (previous != null) previous[0].next_voice_id else 0,
    );
    writeVoicedState(out_state, built);
    return built.voice_count;
}

pub export fn lmt_voiced_history_push(
    history_ptr: [*c]LmtVoicedHistory,
    notes_ptr: [*c]const u8,
    note_count: u32,
    sustained_ptr: [*c]const u8,
    sustained_count: u32,
    tonic: u8,
    mode_type: u8,
    beat_in_bar: u8,
    beats_per_bar: u8,
    subdivision: u8,
    cadence_hint: u8,
    out: [*c]LmtVoicedState,
) callconv(.c) u32 {
    if (history_ptr == null) return 0;
    const out_history: *LmtVoicedHistory = @ptrCast(history_ptr);
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    var sustained_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const sustained_notes = decodeMidiNotes(sustained_ptr, sustained_count, &sustained_buf);
    var history = decodeVoicedHistory(out_history.*);
    const built = history.push(
        notes,
        sustained_notes,
        tonic_pc,
        mt,
        decodeMetricPosition(beat_in_bar, beats_per_bar, subdivision),
        decodeCadenceState(cadence_hint),
    );
    writeVoicedHistory(out_history, history);
    if (out != null) {
        const out_state: *LmtVoicedState = @ptrCast(out);
        writeVoicedState(out_state, built);
    }
    return built.voice_count;
}

pub export fn lmt_classify_motion(previous: [*c]const LmtVoicedState, current: [*c]const LmtVoicedState, out: [*c]LmtMotionSummary) callconv(.c) u32 {
    if (previous == null or current == null or out == null) return 0;

    const previous_state: *const LmtVoicedState = @ptrCast(previous);
    const current_state: *const LmtVoicedState = @ptrCast(current);
    const out_summary: *LmtMotionSummary = @ptrCast(out);

    const previous_value = decodeVoicedState(previous_state.*);
    const current_value = decodeVoicedState(current_state.*);
    const summary = counterpoint.classifyMotion(&previous_value, &current_value);
    writeMotionSummary(out_summary, summary);
    return 1;
}

pub export fn lmt_evaluate_motion_profile(profile: u8, summary: [*c]const LmtMotionSummary, out: [*c]LmtMotionEvaluation) callconv(.c) u32 {
    if (summary == null or out == null) return 0;

    const profile_value = decodeCounterpointRuleProfile(profile) orelse return 0;
    const raw_summary: *const LmtMotionSummary = @ptrCast(summary);
    const out_evaluation: *LmtMotionEvaluation = @ptrCast(out);

    const evaluation = counterpoint.evaluateMotionProfile(decodeMotionSummary(raw_summary.*), profile_value);
    writeMotionEvaluation(out_evaluation, evaluation);
    return 1;
}

pub export fn lmt_check_parallel_perfects(
    previous: [*c]const LmtVoicedState,
    current: [*c]const LmtVoicedState,
    out: [*c]LmtVoicePairViolation,
    out_cap: u32,
) callconv(.c) u32 {
    if (previous == null or current == null) return 0;
    if (out_cap > 0 and out == null) return 0;

    const previous_state: *const LmtVoicedState = @ptrCast(previous);
    const current_state: *const LmtVoicedState = @ptrCast(current);
    const previous_value = decodeVoicedState(previous_state.*);
    const current_value = decodeVoicedState(current_state.*);

    var violations: [voice_leading_rules.MAX_VOICE_PAIR_VIOLATIONS]voice_leading_rules.VoicePairViolation = undefined;
    const total = voice_leading_rules.detectParallelPerfects(&previous_value, &current_value, violations[0..]);
    const write_count = @min(@as(usize, total), @as(usize, @intCast(out_cap)));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        const out_violation: *LmtVoicePairViolation = @ptrCast(&out[index]);
        writeVoicePairViolation(out_violation, violations[index]);
    }
    return total;
}

pub export fn lmt_check_voice_crossing(
    previous: [*c]const LmtVoicedState,
    current: [*c]const LmtVoicedState,
    out: [*c]LmtVoicePairViolation,
    out_cap: u32,
) callconv(.c) u32 {
    if (previous == null or current == null) return 0;
    if (out_cap > 0 and out == null) return 0;

    const previous_state: *const LmtVoicedState = @ptrCast(previous);
    const current_state: *const LmtVoicedState = @ptrCast(current);
    const previous_value = decodeVoicedState(previous_state.*);
    const current_value = decodeVoicedState(current_state.*);

    var violations: [voice_leading_rules.MAX_VOICE_PAIR_VIOLATIONS]voice_leading_rules.VoicePairViolation = undefined;
    const total = voice_leading_rules.detectVoiceCrossings(&previous_value, &current_value, violations[0..]);
    const write_count = @min(@as(usize, total), @as(usize, @intCast(out_cap)));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        const out_violation: *LmtVoicePairViolation = @ptrCast(&out[index]);
        writeVoicePairViolation(out_violation, violations[index]);
    }
    return total;
}

pub export fn lmt_check_spacing(
    current: [*c]const LmtVoicedState,
    out: [*c]LmtVoicePairViolation,
    out_cap: u32,
) callconv(.c) u32 {
    if (current == null) return 0;
    if (out_cap > 0 and out == null) return 0;

    const current_state: *const LmtVoicedState = @ptrCast(current);
    const current_value = decodeVoicedState(current_state.*);

    var violations: [voice_leading_rules.MAX_VOICE_PAIR_VIOLATIONS]voice_leading_rules.VoicePairViolation = undefined;
    const total = voice_leading_rules.detectSpacingViolations(&current_value, violations[0..]);
    const write_count = @min(@as(usize, total), @as(usize, @intCast(out_cap)));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        const out_violation: *LmtVoicePairViolation = @ptrCast(&out[index]);
        writeVoicePairViolation(out_violation, violations[index]);
    }
    return total;
}

pub export fn lmt_check_motion_independence(
    previous: [*c]const LmtVoicedState,
    current: [*c]const LmtVoicedState,
    out: [*c]LmtMotionIndependenceSummary,
) callconv(.c) u32 {
    if (previous == null or current == null or out == null) return 0;

    const previous_state: *const LmtVoicedState = @ptrCast(previous);
    const current_state: *const LmtVoicedState = @ptrCast(current);
    const out_summary: *LmtMotionIndependenceSummary = @ptrCast(out);
    const previous_value = decodeVoicedState(previous_state.*);
    const current_value = decodeVoicedState(current_state.*);
    const summary = voice_leading_rules.detectMotionIndependence(&previous_value, &current_value);
    writeMotionIndependenceSummary(out_summary, summary);
    return 1;
}

fn decodeSatbVoice(raw: u8) ?choir.SatbVoice {
    return switch (raw) {
        0 => .soprano,
        1 => .alto,
        2 => .tenor,
        3 => .bass,
        else => null,
    };
}

pub export fn lmt_satb_range_low(voice: u8) callconv(.c) u8 {
    const satb_voice = decodeSatbVoice(voice) orelse return 0;
    return choir.rangeLow(satb_voice);
}

pub export fn lmt_satb_range_high(voice: u8) callconv(.c) u8 {
    const satb_voice = decodeSatbVoice(voice) orelse return 0;
    return choir.rangeHigh(satb_voice);
}

pub export fn lmt_satb_range_contains(voice: u8, midi: u8) callconv(.c) bool {
    const satb_voice = decodeSatbVoice(voice) orelse return false;
    if (midi > 127) return false;
    return choir.rangeContains(satb_voice, @as(pitch.MidiNote, @intCast(midi)));
}

pub export fn lmt_check_satb_registers(
    current: [*c]const LmtVoicedState,
    out: [*c]LmtSatbRegisterViolation,
    out_cap: u32,
) callconv(.c) u32 {
    if (current == null) return 0;
    if (out_cap > 0 and out == null) return 0;

    const current_state: *const LmtVoicedState = @ptrCast(current);
    const current_value = decodeVoicedState(current_state.*);

    var violations: [choir.MAX_REGISTER_VIOLATIONS]choir.RegisterViolation = undefined;
    const total = choir.checkRegisters(&current_value, violations[0..]);
    const write_count = @min(@as(usize, total), @as(usize, @intCast(out_cap)));
    var index: usize = 0;
    while (index < write_count) : (index += 1) {
        const out_violation: *LmtSatbRegisterViolation = @ptrCast(&out[index]);
        writeSatbRegisterViolation(out_violation, violations[index]);
    }
    return total;
}

pub export fn lmt_rank_next_steps(history: [*c]const LmtVoicedHistory, profile: u8, out: [*c]LmtNextStepSuggestion, out_cap: u32) callconv(.c) u32 {
    if (history == null or out == null or out_cap == 0) return 0;

    const profile_value = decodeCounterpointRuleProfile(profile) orelse return 0;
    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    const decoded_history = decodeVoicedHistory(raw_history.*);
    const write_cap = @min(@as(usize, @intCast(out_cap)), counterpoint.MAX_NEXT_STEP_SUGGESTIONS);

    var suggestions_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const ranked = counterpoint.rankNextSteps(&decoded_history, profile_value, suggestions_buf[0..write_cap]);

    for (ranked, 0..) |suggestion, index| {
        const out_suggestion: *LmtNextStepSuggestion = @ptrCast(&out[index]);
        writeNextStepSuggestion(out_suggestion, suggestion);
    }
    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_filter_next_steps_by_playability(
    history: [*c]const LmtVoicedHistory,
    profile_raw: u32,
    hand_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtNextStepSuggestion,
    out_cap: u32,
) callconv(.c) u32 {
    if (history == null) return 0;
    if (profile_raw > std.math.maxInt(u8)) return 0;

    const profile_value = decodeCounterpointRuleProfile(@as(u8, @intCast(profile_raw))) orelse return 0;
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    var decoded_history = decodeVoicedHistory(raw_history.*);
    var filtered_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const filtered = playability.ranking.filterNextStepsByPlayability(
        &decoded_history,
        profile_value,
        hand,
        hand_profile,
        policy,
        filtered_buf[0..],
    );

    if (out != null) {
        const write_len = @min(filtered.len, @as(usize, @intCast(out_cap)));
        for (filtered[0..write_len], 0..) |row, index| {
            const out_row: *LmtNextStepSuggestion = @ptrCast(&out[index]);
            writeNextStepSuggestion(out_row, row);
        }
    }

    return @as(u32, @intCast(filtered.len));
}

pub export fn lmt_rank_keyboard_next_steps_by_playability(
    history: [*c]const LmtVoicedHistory,
    profile_raw: u32,
    hand_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardNextStep,
    out_cap: u32,
) callconv(.c) u32 {
    if (history == null) return 0;
    if (profile_raw > std.math.maxInt(u8)) return 0;

    const profile_value = decodeCounterpointRuleProfile(@as(u8, @intCast(profile_raw))) orelse return 0;
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    var decoded_history = decodeVoicedHistory(raw_history.*);
    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]playability.ranking.RankedKeyboardNextStep = undefined;
    const ranked = playability.ranking.rankKeyboardNextSteps(
        &decoded_history,
        profile_value,
        hand,
        hand_profile,
        policy,
        ranked_buf[0..],
    );

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedKeyboardNextStep = @ptrCast(&out[index]);
            writeRankedKeyboardNextStep(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_rank_keyboard_next_steps_by_committed_phrase(
    memory_ptr: [*c]const LmtKeyboardCommittedPhraseMemory,
    history: [*c]const LmtVoicedHistory,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardNextStep,
    out_cap: u32,
) callconv(.c) u32 {
    if (memory_ptr == null or history == null) return 0;
    if (profile_raw > std.math.maxInt(u8)) return 0;

    const memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;
    const profile_value = decodeCounterpointRuleProfile(@as(u8, @intCast(profile_raw))) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    var decoded_history = decodeVoicedHistory(raw_history.*);
    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]playability.ranking.RankedKeyboardNextStep = undefined;
    const ranked = playability.ranking.rankKeyboardNextStepsFromCommittedPhrase(
        &memory,
        &decoded_history,
        profile_value,
        hand_profile,
        policy,
        ranked_buf[0..],
    );

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedKeyboardNextStep = @ptrCast(&out[index]);
            writeRankedKeyboardNextStep(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_suggest_safer_keyboard_next_step_by_playability(
    history: [*c]const LmtVoicedHistory,
    profile_raw: u32,
    hand_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardNextStep,
) callconv(.c) u32 {
    if (history == null or out == null) return 0;
    if (profile_raw > std.math.maxInt(u8)) return 0;

    const profile_value = decodeCounterpointRuleProfile(@as(u8, @intCast(profile_raw))) orelse return 0;
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    var decoded_history = decodeVoicedHistory((@as(*const LmtVoicedHistory, @ptrCast(history))).*);
    const ranked = playability.profile.suggestSaferKeyboardNextStep(
        &decoded_history,
        profile_value,
        hand,
        hand_profile,
        policy,
    ) orelse return 0;
    writeRankedKeyboardNextStep(@ptrCast(out), ranked);
    return 1;
}

pub export fn lmt_suggest_safer_keyboard_next_step_by_committed_phrase(
    memory_ptr: [*c]const LmtKeyboardCommittedPhraseMemory,
    history: [*c]const LmtVoicedHistory,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardNextStep,
) callconv(.c) u32 {
    if (memory_ptr == null or history == null or out == null) return 0;
    if (profile_raw > std.math.maxInt(u8)) return 0;

    const memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;
    const profile_value = decodeCounterpointRuleProfile(@as(u8, @intCast(profile_raw))) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    var decoded_history = decodeVoicedHistory((@as(*const LmtVoicedHistory, @ptrCast(history))).*);
    const ranked = playability.profile.suggestSaferKeyboardNextStepFromCommittedPhrase(
        &memory,
        &decoded_history,
        profile_value,
        hand_profile,
        policy,
    ) orelse return 0;
    writeRankedKeyboardNextStep(@ptrCast(out), ranked);
    return 1;
}

pub export fn lmt_rank_cadence_destinations(
    history: [*c]const LmtVoicedHistory,
    profile: u8,
    out: [*c]LmtCadenceDestinationScore,
    out_cap: u32,
) callconv(.c) u32 {
    if (history == null or out == null or out_cap == 0) return 0;

    const profile_value = decodeCounterpointRuleProfile(profile) orelse return 0;
    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    const decoded_history = decodeVoicedHistory(raw_history.*);
    const write_cap = @min(@as(usize, @intCast(out_cap)), counterpoint.MAX_CADENCE_DESTINATIONS);

    var destination_buf: [counterpoint.MAX_CADENCE_DESTINATIONS]counterpoint.CadenceDestinationScore = undefined;
    const ranked = counterpoint.rankCadenceDestinations(&decoded_history, profile_value, destination_buf[0..write_cap]);

    for (ranked, 0..) |destination, index| {
        const out_destination: *LmtCadenceDestinationScore = @ptrCast(&out[index]);
        writeCadenceDestinationScore(out_destination, destination);
    }
    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_analyze_suspension_machine(
    history: [*c]const LmtVoicedHistory,
    profile: u8,
    out: [*c]LmtSuspensionMachineSummary,
) callconv(.c) u32 {
    if (history == null or out == null) return 0;

    const profile_value = decodeCounterpointRuleProfile(profile) orelse return 0;
    const raw_history: *const LmtVoicedHistory = @ptrCast(history);
    const decoded_history = decodeVoicedHistory(raw_history.*);
    const summary = counterpoint.analyzeSuspensionMachine(&decoded_history, profile_value);
    const out_summary: *LmtSuspensionMachineSummary = @ptrCast(out);
    writeSuspensionMachineSummary(out_summary, summary);
    return 1;
}

pub export fn lmt_next_step_reason_count() callconv(.c) u32 {
    return @as(u32, @intCast(counterpoint.NEXT_STEP_REASON_NAMES.len));
}

pub export fn lmt_next_step_reason_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= counterpoint.NEXT_STEP_REASON_NAMES.len) return null;
    return writeCString(counterpoint.NEXT_STEP_REASON_NAMES[idx]);
}

pub export fn lmt_next_step_warning_count() callconv(.c) u32 {
    return @as(u32, @intCast(counterpoint.NEXT_STEP_WARNING_NAMES.len));
}

pub export fn lmt_next_step_warning_name(index: u32) callconv(.c) [*c]const u8 {
    const idx = @as(usize, @intCast(index));
    if (idx >= counterpoint.NEXT_STEP_WARNING_NAMES.len) return null;
    return writeCString(counterpoint.NEXT_STEP_WARNING_NAMES[idx]);
}

pub export fn lmt_mode_spelling_quality(tonic: u8, mode_type: u8) callconv(.c) u8 {
    const mt = decodeModeType(mode_type) orelse return KEY_MAJOR;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    return switch (keyboard_logic.modeSpellingQuality(tonic_pc, mt)) {
        .minor => KEY_MINOR,
        .major => KEY_MAJOR,
    };
}

pub export fn lmt_spell_note(pc: u8, key_ctx: LmtKeyContext) callconv(.c) [*c]const u8 {
    var note_buf: [4]u8 = undefined;
    const k = decodeKeyContext(key_ctx);
    const note = note_spelling.spellNote(@as(pitch.PitchClass, @intCast(pc % 12)), k);
    const text = note.format(&note_buf);
    return writeCString(text);
}

// WASM-friendly helper to avoid JS struct-by-value ABI marshalling.
pub export fn lmt_spell_note_parts(pc: u8, tonic: u8, quality: u8) callconv(.c) [*c]const u8 {
    return lmt_spell_note(pc, .{ .tonic = tonic, .quality = quality });
}

pub export fn lmt_chord(chord_kind: u8, root: u8) callconv(.c) u16 {
    const root_pc = @as(pitch.PitchClass, @intCast(root % 12));
    return toCSet(pcs.transpose(chordTemplate(chord_kind), root_pc));
}

pub export fn lmt_chord_name(set: u16) callconv(.c) [*c]const u8 {
    const name = chord.pcsToChordName(maskPitchClassSet(set)) orelse "Unknown";
    return writeCString(name);
}

pub export fn lmt_roman_numeral(chord_set: u16, key_ctx: LmtKeyContext) callconv(.c) [*c]const u8 {
    var buf: [16]u8 = undefined;

    const set = maskPitchClassSet(chord_set);
    const root_pc = firstPitchClass(set);
    const chord_instance = harmony.ChordInstance{
        .root = root_pc,
        .pcs = set,
        .quality = classifyChordQuality(root_pc, set),
        .degree = 0,
    };

    const numeral = harmony.romanNumeral(chord_instance, decodeKeyContext(key_ctx));
    const text = numeral.format(&buf);
    return writeCString(text);
}

// WASM-friendly helper to avoid JS struct-by-value ABI marshalling.
pub export fn lmt_roman_numeral_parts(chord_set: u16, tonic: u8, quality: u8) callconv(.c) [*c]const u8 {
    return lmt_roman_numeral(chord_set, .{ .tonic = tonic, .quality = quality });
}

pub export fn lmt_fret_to_midi(string: u8, fret: u8, tuning_ptr: [*c]const u8) callconv(.c) u8 {
    if (string >= guitar.NUM_STRINGS) return 0;

    const tuning = decodeTuning(tuning_ptr);
    const clamped_fret: u5 = @intCast(@min(fret, @as(u8, guitar.MAX_FRET)));
    const midi = guitar.fretToMidi(@as(u3, @intCast(string)), clamped_fret, tuning);
    return @as(u8, midi);
}

pub export fn lmt_fret_to_midi_n(string: u32, fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32) callconv(.c) u8 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    const midi = guitar.fretToMidiGeneric(@as(usize, @intCast(string)), fret, tuning) orelse return 0;
    return @as(u8, midi);
}

pub export fn lmt_midi_to_fret_positions(note: u8, tuning_ptr: [*c]const u8, out: [*c]LmtFretPos) callconv(.c) u8 {
    var tmp: [guitar.NUM_STRINGS]guitar.FretPosition = undefined;
    const tuning = decodeTuning(tuning_ptr);

    const midi = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const positions = guitar.midiToFretPositions(midi, tuning, &tmp);

    if (out != null) {
        for (positions, 0..) |pos, i| {
            out[i] = .{
                .string = @as(u8, pos.string),
                .fret = @as(u8, pos.fret),
            };
        }
    }

    return @as(u8, @intCast(positions.len));
}

pub export fn lmt_midi_to_fret_positions_n(note: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtFretPos, out_cap: u32) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    var tmp: [MAX_PARAMETRIC_FRET_STRINGS]guitar.GenericFretPosition = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);

    const midi = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const positions = guitar.midiToFretPositionsGeneric(midi, tuning, tmp[0..tuning.len]);

    if (out != null) {
        const write_len = @min(positions.len, @as(usize, @intCast(out_cap)));
        for (positions[0..write_len], 0..) |pos, i| {
            out[i] = .{
                .string = @as(u8, @intCast(@min(pos.string, @as(usize, 255)))),
                .fret = pos.fret,
            };
        }
    }

    return @as(u32, @intCast(positions.len));
}

pub export fn lmt_generate_voicings_n(chord_set: u16, tuning_ptr: [*c]const u8, tuning_count: u32, max_fret: u8, max_span: u8, out_frets: [*c]i8, out_voicing_cap: u32) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or out_frets == null or out_voicing_cap == 0) return 0;

    const row_cap = @as(usize, @intCast(out_voicing_cap));
    if (row_cap > MAX_C_API_GENERIC_VOICINGS) return 0;

    const generated = guitar.generateVoicingsGeneric(
        maskPitchClassSet(chord_set),
        tuning,
        max_fret,
        max_span,
        generic_voicing_meta_buf[0..row_cap],
        generic_voicing_fret_buf[0 .. row_cap * tuning.len],
    );

    for (generated, 0..) |voicing, row| {
        const row_start = row * tuning.len;
        @memcpy(out_frets[row_start .. row_start + tuning.len], voicing.frets);
    }

    return @as(u32, @intCast(generated.len));
}

pub export fn lmt_preferred_voicing_n(chord_set: u16, tuning_ptr: [*c]const u8, tuning_count: u32, max_fret: u8, max_span: u8, preferred_bass_pc: u8, out_frets: [*c]i8, out_fret_cap: u32) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or out_frets == null) return 0;

    const write_cap = @as(usize, @intCast(out_fret_cap));
    if (write_cap < tuning.len) return 0;

    const preferred_pc: ?pitch.PitchClass = if (preferred_bass_pc < 12)
        @as(pitch.PitchClass, @intCast(preferred_bass_pc))
    else
        null;

    const preferred = guitar.preferredVoicingGeneric(
        maskPitchClassSet(chord_set),
        tuning,
        max_fret,
        max_span,
        preferred_pc,
        generic_voicing_meta_buf[0..MAX_C_API_GENERIC_VOICINGS],
        generic_voicing_fret_buf[0 .. MAX_C_API_GENERIC_VOICINGS * tuning.len],
    ) orelse return 0;

    @memcpy(out_frets[0..tuning.len], preferred.voicing.frets);
    return @as(u32, @intCast(preferred.row_count));
}

pub export fn lmt_rank_context_suggestions(set: u16, midi_notes_ptr: [*c]const u8, note_count: u32, tonic: u8, mode_type: u8, out: [*c]LmtContextSuggestion, out_cap: u32) callconv(.c) u32 {
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(midi_notes_ptr, note_count, &notes_buf);

    var ranked_buf: [keyboard_logic.MAX_CONTEXT_SUGGESTIONS]keyboard_logic.ContextSuggestion = undefined;
    const ranked = keyboard_logic.rankContextSuggestions(maskPitchClassSet(set), notes, tonic_pc, mt, &ranked_buf);

    const total = ranked.len;
    const write_len = @min(total, @as(usize, @intCast(out_cap)));
    if (out != null) {
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtContextSuggestion = @ptrCast(&out[index]);
            writeContextSuggestion(out_row, row);
        }
    }

    return @as(u32, @intCast(total));
}

pub export fn lmt_rank_keyboard_context_suggestions_by_playability(
    set: u16,
    midi_notes_ptr: [*c]const u8,
    note_count: u32,
    tonic: u8,
    mode_type: u8,
    hand_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardContextSuggestion,
    out_cap: u32,
) callconv(.c) u32 {
    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(midi_notes_ptr, note_count, &notes_buf);

    var ranked_buf: [keyboard_logic.MAX_CONTEXT_SUGGESTIONS]playability.ranking.RankedKeyboardContextSuggestion = undefined;
    const ranked = playability.ranking.rankKeyboardContextSuggestions(
        maskPitchClassSet(set),
        notes,
        tonic_pc,
        mt,
        hand,
        hand_profile,
        previous_load,
        policy,
        ranked_buf[0..],
    );

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedKeyboardContextSuggestion = @ptrCast(&out[index]);
            writeRankedKeyboardContextSuggestion(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_rank_keyboard_context_suggestions_by_committed_phrase(
    memory_ptr: [*c]const LmtKeyboardCommittedPhraseMemory,
    set: u16,
    tonic: u8,
    mode_type: u8,
    hand_profile_ptr: [*c]const LmtHandProfile,
    policy_raw: u32,
    out: [*c]LmtRankedKeyboardContextSuggestion,
    out_cap: u32,
) callconv(.c) u32 {
    if (memory_ptr == null) return 0;

    const mt = decodeModeType(mode_type) orelse return 0;
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const memory = decodeKeyboardCommittedPhraseMemory((@as(*const LmtKeyboardCommittedPhraseMemory, @ptrCast(memory_ptr))).*) orelse return 0;
    const hand_profile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const policy = decodePlayabilityPolicy(policy_raw) orelse return 0;

    var ranked_buf: [keyboard_logic.MAX_CONTEXT_SUGGESTIONS]playability.ranking.RankedKeyboardContextSuggestion = undefined;
    const ranked = playability.ranking.rankKeyboardContextSuggestionsFromCommittedPhrase(
        &memory,
        maskPitchClassSet(set),
        tonic_pc,
        mt,
        hand_profile,
        policy,
        ranked_buf[0..],
    );

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedKeyboardContextSuggestion = @ptrCast(&out[index]);
            writeRankedKeyboardContextSuggestion(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_pitch_class_guide_n(selected_ptr: [*c]const LmtFretPos, selected_count: u32, min_fret: u8, max_fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtGuideDot, out_cap: u32) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or max_fret < min_fret) return 0;

    const selected_len = @as(usize, @intCast(selected_count));
    const selected_pcs = selectedGuidePitchClasses(selected_ptr, selected_len, tuning);
    if (selected_pcs == 0) return 0;

    const write_cap = @as(usize, @intCast(out_cap));
    var total: usize = 0;

    for (tuning, 0..) |_, string| {
        var fret = min_fret;
        while (true) : (fret += 1) {
            if (isSelectedGuidePosition(selected_ptr, selected_len, string, fret)) {
                if (fret == max_fret or fret == std.math.maxInt(u8)) break;
                continue;
            }

            const midi = guitar.fretToMidiGeneric(string, fret, tuning) orelse {
                if (fret == max_fret or fret == std.math.maxInt(u8)) break;
                continue;
            };
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((selected_pcs & bit) != 0) {
                if (out != null and total < write_cap) {
                    out[total] = .{
                        .position = .{
                            .string = @as(u8, @intCast(@min(string, @as(usize, 255)))),
                            .fret = fret,
                        },
                        .pitch_class = pc,
                        .opacity = guitar.GUIDE_OPACITY,
                    };
                }
                total += 1;
            }

            if (fret == max_fret or fret == std.math.maxInt(u8)) break;
        }
    }

    return @as(u32, @intCast(total));
}

pub export fn lmt_frets_to_url_n(frets_ptr: [*c]const i8, fret_count: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    if (buf == null or buf_size == 0) return 0;

    const out = buf[0..@as(usize, @intCast(buf_size))];
    var stream = std.io.fixedBufferStream(out);
    const writer = stream.writer();
    const count = @as(usize, @intCast(fret_count));

    if (count > 0 and frets_ptr == null) return 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (i > 0) writer.writeByte(',') catch return 0;

        const fret = frets_ptr[i];
        if (fret < -1) return 0;
        if (fret == -1) {
            writer.writeAll("-1") catch return 0;
        } else {
            writer.print("{d}", .{fret}) catch return 0;
        }
    }

    if (stream.pos >= out.len) return 0;
    out[stream.pos] = 0;
    return @as(u32, @intCast(stream.pos));
}

pub export fn lmt_url_to_frets_n(url_ptr: [*c]const u8, out: [*c]i8, out_cap: u32) callconv(.c) u32 {
    if (url_ptr == null) return 0;

    const url = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(url_ptr)), 0);
    const write_cap = @as(usize, @intCast(out_cap));
    var count: usize = 0;

    var it = std.mem.splitScalar(u8, url, ',');
    while (it.next()) |raw_token| {
        const fret = parseUrlFretToken(raw_token) orelse return 0;
        if (out != null and count < write_cap) {
            out[count] = fret;
        }
        count += 1;
    }

    return @as(u32, @intCast(count));
}

pub export fn lmt_describe_fret_play_state(
    frets_ptr: [*c]const i8,
    fret_count: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtFretPlayState,
) callconv(.c) u32 {
    if (out == null) return 0;

    const count = @as(usize, @intCast(fret_count));
    if (count > 0 and frets_ptr == null) return 0;
    if (count > guitar.MAX_GENERIC_STRINGS) return 0;

    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.fret_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const frets = if (count == 0) &[_]i8{} else frets_ptr[0..count];
    const state = playability.fret_topology.describeState(frets, profile, previous_load);
    const out_state: *LmtFretPlayState = @ptrCast(out);
    writeFretPlayState(out_state, state);
    return 1;
}

pub export fn lmt_windowed_fret_positions_n(
    note: u8,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    anchor_fret: u8,
    profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtFretCandidateLocation,
    out_cap: u32,
) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0) return 0;

    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.fret_topology.defaultHandProfile();

    var locations_buf: [playability.fret_topology.MAX_WINDOWED_LOCATIONS]playability.fret_topology.WindowedLocation = undefined;
    const locations = playability.fret_topology.windowedLocationsForMidi(
        @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127)))),
        tuning,
        anchor_fret,
        profile,
        locations_buf[0..],
    );

    if (out != null) {
        const write_len = @min(locations.len, @as(usize, @intCast(out_cap)));
        for (locations[0..write_len], 0..) |location, index| {
            const out_location: *LmtFretCandidateLocation = @ptrCast(&out[index]);
            writeFretCandidateLocation(out_location, location);
        }
    }

    return @as(u32, @intCast(locations.len));
}

pub export fn lmt_assess_fret_realization_n(
    frets_ptr: [*c]const i8,
    fret_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtFretRealizationAssessment,
) callconv(.c) u32 {
    if (out == null) return 0;

    const count = @as(usize, @intCast(fret_count));
    if (count > 0 and frets_ptr == null) return 0;
    if (count > guitar.MAX_GENERIC_STRINGS) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or count > tuning.len) return 0;

    const profile = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;
    const frets = if (count == 0) &[_]i8{} else frets_ptr[0..count];
    const assessment = playability.fret_assessment.assessRealization(
        frets,
        tuning,
        profile,
        hand_profile,
        previous_load,
    );
    const out_assessment: *LmtFretRealizationAssessment = @ptrCast(out);
    writeFretRealizationAssessment(out_assessment, assessment);
    return 1;
}

pub export fn lmt_assess_fret_transition_n(
    from_frets_ptr: [*c]const i8,
    to_frets_ptr: [*c]const i8,
    fret_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtFretTransitionAssessment,
) callconv(.c) u32 {
    if (out == null) return 0;

    const count = @as(usize, @intCast(fret_count));
    if (count > 0 and (from_frets_ptr == null or to_frets_ptr == null)) return 0;
    if (count > guitar.MAX_GENERIC_STRINGS) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or count > tuning.len) return 0;

    const profile = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;
    const from_frets = if (count == 0) &[_]i8{} else from_frets_ptr[0..count];
    const to_frets = if (count == 0) &[_]i8{} else to_frets_ptr[0..count];
    const assessment = playability.fret_assessment.assessTransition(
        from_frets,
        to_frets,
        tuning,
        profile,
        hand_profile,
    );
    const out_assessment: *LmtFretTransitionAssessment = @ptrCast(out);
    writeFretTransitionAssessment(out_assessment, assessment);
    return 1;
}

pub export fn lmt_summarize_fret_realization_difficulty_n(
    frets_ptr: [*c]const i8,
    fret_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtPlayabilityDifficultySummary,
) callconv(.c) u32 {
    if (out == null) return 0;

    const count = @as(usize, @intCast(fret_count));
    if (count > 0 and frets_ptr == null) return 0;
    if (count > guitar.MAX_GENERIC_STRINGS) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or count > tuning.len) return 0;

    const technique = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;
    const resolved_hand = hand_profile orelse playability.fret_assessment.defaultHandProfile(technique);
    const frets = if (count == 0) &[_]i8{} else frets_ptr[0..count];
    const assessment = playability.fret_assessment.assessRealization(
        frets,
        tuning,
        technique,
        hand_profile,
        previous_load,
    );
    writePlayabilityDifficultySummary(@ptrCast(out), playability.profile.summarizeFretRealization(assessment, resolved_hand));
    return 1;
}

pub export fn lmt_summarize_fret_transition_difficulty_n(
    from_frets_ptr: [*c]const i8,
    to_frets_ptr: [*c]const i8,
    fret_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtPlayabilityDifficultySummary,
) callconv(.c) u32 {
    if (out == null) return 0;

    const count = @as(usize, @intCast(fret_count));
    if (count > 0 and (from_frets_ptr == null or to_frets_ptr == null)) return 0;
    if (count > guitar.MAX_GENERIC_STRINGS) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or count > tuning.len) return 0;

    const technique = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;
    const resolved_hand = hand_profile orelse playability.fret_assessment.defaultHandProfile(technique);
    const from_frets = if (count == 0) &[_]i8{} else from_frets_ptr[0..count];
    const to_frets = if (count == 0) &[_]i8{} else to_frets_ptr[0..count];
    const assessment = playability.fret_assessment.assessTransition(
        from_frets,
        to_frets,
        tuning,
        technique,
        hand_profile,
    );
    writePlayabilityDifficultySummary(@ptrCast(out), playability.profile.summarizeFretTransition(assessment, resolved_hand));
    return 1;
}

pub export fn lmt_rank_fret_realizations_n(
    note: u8,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    anchor_fret: u8,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtRankedFretRealization,
    out_cap: u32,
) callconv(.c) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0) return 0;

    const profile = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;

    var ranked_buf: [playability.fret_assessment.MAX_RANKED_LOCATIONS]playability.fret_assessment.RankedLocation = undefined;
    const ranked = playability.fret_assessment.rankLocationsForMidi(
        @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127)))),
        tuning,
        anchor_fret,
        profile,
        hand_profile,
        ranked_buf[0..],
    );

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedFretRealization = @ptrCast(&out[index]);
            writeRankedFretRealization(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_suggest_easier_fret_realization_n(
    note: u8,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    anchor_fret: u8,
    profile_raw: u32,
    hand_profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtRankedFretRealization,
) callconv(.c) u32 {
    if (out == null) return 0;

    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0) return 0;

    const technique = decodeFretTechniqueProfile(profile_raw) orelse return 0;
    const hand_profile: ?playability.types.HandProfile = if (hand_profile_ptr != null)
        decodeHandProfile(hand_profile_ptr[0])
    else
        null;

    const ranked = playability.profile.suggestEasierFretRealization(
        @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127)))),
        tuning,
        anchor_fret,
        technique,
        hand_profile,
    ) orelse return 0;

    writeRankedFretRealization(@ptrCast(out), ranked);
    return 1;
}

pub export fn lmt_keyboard_key_coord(note: u8, out: [*c]LmtKeybedKeyCoord) callconv(.c) u32 {
    if (out == null) return 0;
    const coord = playability.keyboard_topology.keyCoord(@as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127)))));
    const out_coord: *LmtKeybedKeyCoord = @ptrCast(out);
    writeKeybedKeyCoord(out_coord, coord);
    return 1;
}

pub export fn lmt_describe_keyboard_play_state(
    notes_ptr: [*c]const u8,
    note_count: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtKeyboardPlayState,
) callconv(.c) u32 {
    if (out == null) return 0;

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);

    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const state = playability.keyboard_topology.describeState(notes, profile, previous_load);
    const out_state: *LmtKeyboardPlayState = @ptrCast(out);
    writeKeyboardPlayState(out_state, state);
    return 1;
}

pub export fn lmt_assess_keyboard_realization_n(
    notes_ptr: [*c]const u8,
    note_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtKeyboardRealizationAssessment,
) callconv(.c) u32 {
    if (out == null) return 0;

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const assessment = playability.keyboard_assessment.assessRealization(notes, hand, profile, previous_load);
    const out_assessment: *LmtKeyboardRealizationAssessment = @ptrCast(out);
    writeKeyboardRealizationAssessment(out_assessment, assessment);
    return 1;
}

pub export fn lmt_assess_keyboard_transition_n(
    from_notes_ptr: [*c]const u8,
    from_count: u32,
    to_notes_ptr: [*c]const u8,
    to_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtKeyboardTransitionAssessment,
) callconv(.c) u32 {
    if (out == null) return 0;

    var from_notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    var to_notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const from_notes = decodeMidiNotes(from_notes_ptr, from_count, &from_notes_buf);
    const to_notes = decodeMidiNotes(to_notes_ptr, to_count, &to_notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const assessment = playability.keyboard_assessment.assessTransition(from_notes, to_notes, hand, profile, previous_load);
    const out_assessment: *LmtKeyboardTransitionAssessment = @ptrCast(out);
    writeKeyboardTransitionAssessment(out_assessment, assessment);
    return 1;
}

pub export fn lmt_summarize_keyboard_realization_difficulty_n(
    notes_ptr: [*c]const u8,
    note_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtPlayabilityDifficultySummary,
) callconv(.c) u32 {
    if (out == null) return 0;

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const assessment = playability.keyboard_assessment.assessRealization(notes, hand, profile, previous_load);
    writePlayabilityDifficultySummary(@ptrCast(out), playability.profile.summarizeKeyboardRealization(assessment, profile));
    return 1;
}

pub export fn lmt_summarize_keyboard_transition_difficulty_n(
    from_notes_ptr: [*c]const u8,
    from_count: u32,
    to_notes_ptr: [*c]const u8,
    to_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    previous_load_ptr: [*c]const LmtTemporalLoadState,
    out: [*c]LmtPlayabilityDifficultySummary,
) callconv(.c) u32 {
    if (out == null) return 0;

    var from_notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    var to_notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const from_notes = decodeMidiNotes(from_notes_ptr, from_count, &from_notes_buf);
    const to_notes = decodeMidiNotes(to_notes_ptr, to_count, &to_notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();
    const previous_load: ?playability.types.TemporalLoadState = if (previous_load_ptr != null)
        decodeTemporalLoadState(previous_load_ptr[0])
    else
        null;

    const assessment = playability.keyboard_assessment.assessTransition(from_notes, to_notes, hand, profile, previous_load);
    writePlayabilityDifficultySummary(@ptrCast(out), playability.profile.summarizeKeyboardTransition(assessment, profile));
    return 1;
}

pub export fn lmt_rank_keyboard_fingerings_n(
    notes_ptr: [*c]const u8,
    note_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtRankedKeyboardFingering,
    out_cap: u32,
) callconv(.c) u32 {
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();

    var ranked_buf: [playability.keyboard_assessment.MAX_RANKED_FINGERINGS]playability.keyboard_assessment.RankedFingering = undefined;
    const ranked = playability.keyboard_assessment.rankFingerings(notes, hand, profile, ranked_buf[0..]);

    if (out != null) {
        const write_len = @min(ranked.len, @as(usize, @intCast(out_cap)));
        for (ranked[0..write_len], 0..) |row, index| {
            const out_row: *LmtRankedKeyboardFingering = @ptrCast(&out[index]);
            writeRankedKeyboardFingering(out_row, row);
        }
    }

    return @as(u32, @intCast(ranked.len));
}

pub export fn lmt_suggest_easier_keyboard_fingering_n(
    notes_ptr: [*c]const u8,
    note_count: u32,
    hand_raw: u32,
    profile_ptr: [*c]const LmtHandProfile,
    out: [*c]LmtRankedKeyboardFingering,
) callconv(.c) u32 {
    if (out == null) return 0;

    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const hand = decodeKeyboardHand(hand_raw) orelse return 0;
    const profile = if (profile_ptr != null)
        decodeHandProfile(profile_ptr[0])
    else
        playability.keyboard_topology.defaultHandProfile();

    const ranked = playability.profile.suggestEasierKeyboardFingering(notes, hand, profile) orelse return 0;
    writeRankedKeyboardFingering(@ptrCast(out), ranked);
    return 1;
}

pub export fn lmt_svg_clock_optc(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var svg_buf: [16384]u8 = undefined;
    var label_buf: [12]u8 = undefined;

    const safe_set = maskPitchClassSet(set);
    const label = pcs.format(safe_set, &label_buf);
    const svg = svg_clock.renderOPTC(safe_set, label, &svg_buf);

    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_optic_k_group(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var svg_buf: [128 * 1024]u8 = undefined;
    const safe_set = maskPitchClassSet(set);
    const svg = svg_clock.renderOpticKGroup(safe_set, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_evenness_chart(buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var svg_buf: [128 * 1024]u8 = undefined;
    const svg = svg_evenness_chart.renderEvennessChart(&svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_evenness_field(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var svg_buf: [128 * 1024]u8 = undefined;
    const safe_set = maskPitchClassSet(set);
    const svg = svg_evenness_chart.renderEvennessField(safe_set, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_fret(frets_ptr: [*c]const i8, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var frets: [guitar.NUM_STRINGS]i8 = [_]i8{-1} ** guitar.NUM_STRINGS;
    if (frets_ptr != null) {
        var i: usize = 0;
        while (i < guitar.NUM_STRINGS) : (i += 1) {
            const raw = frets_ptr[i];
            frets[i] = if (raw < -1) -1 else if (raw > guitar.MAX_FRET) @as(i8, @intCast(guitar.MAX_FRET)) else raw;
        }
    }

    const voicing = guitar.GuitarVoicing{
        .frets = frets,
        .tuning = guitar.tunings.STANDARD,
    };

    var svg_buf: [4096]u8 = undefined;
    const svg = svg_fret.renderFretDiagram(voicing, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_fret_n(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    if (frets_ptr == null or string_count == 0) {
        var empty_svg_buf: [256]u8 = undefined;
        const svg = svg_fret.renderDiagram(.{ .frets = &[_]i8{} }, &empty_svg_buf);
        return copySvgOut(svg, buf, buf_size);
    }

    const count = @as(usize, @intCast(string_count));
    const raw_frets = frets_ptr[0..count];

    var svg_buf: [8192]u8 = undefined;
    const svg = svg_fret.renderDiagram(.{
        .frets = raw_frets,
        .window_start = if (window_start == 0 and visible_frets == 0) null else window_start,
        .visible_frets = visible_frets,
    }, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_fret_tuned_n(
    frets_ptr: [*c]const i8,
    string_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    window_start: u32,
    visible_frets: u32,
    buf: [*c]u8,
    buf_size: u32,
) callconv(.c) u32 {
    if (frets_ptr == null or string_count == 0) {
        var empty_svg_buf: [256]u8 = undefined;
        const svg = svg_fret.renderDiagram(.{ .frets = &[_]i8{} }, &empty_svg_buf);
        return copySvgOut(svg, buf, buf_size);
    }

    const count = @as(usize, @intCast(string_count));
    const raw_frets = frets_ptr[0..count];
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);

    var svg_buf: [8192]u8 = undefined;
    const svg = svg_fret.renderDiagram(.{
        .frets = raw_frets,
        .window_start = if (window_start == 0 and visible_frets == 0) null else window_start,
        .visible_frets = visible_frets,
        .tuning = tuning,
    }, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_chord_staff(chord_kind: u8, root: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    const root_pc = @as(pitch.PitchClass, @intCast(root % 12));
    const root_midi: pitch.MidiNote = @as(pitch.MidiNote, @intCast(60 + @as(u8, root_pc)));

    var notes: [4]pitch.MidiNote = undefined;
    const count: usize = switch (chord_kind) {
        CHORD_MINOR => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 3));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 7));
            break :blk 3;
        },
        CHORD_DIMINISHED => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 3));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 6));
            break :blk 3;
        },
        CHORD_AUGMENTED => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 4));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 8));
            break :blk 3;
        },
        else => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 4));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 7));
            break :blk 3;
        },
    };

    const k = key.Key.init(root_pc, .major);

    var svg_buf: [16384]u8 = undefined;
    const svg = svg_staff.renderChordStaff(notes[0..count], k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_key_staff(tonic: u8, quality_raw: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const quality: key.KeyQuality = if (quality_raw == KEY_MINOR) .minor else .major;
    const k = key.Key.init(tonic_pc, quality);

    var notes: [8]pitch.MidiNote = undefined;
    const key_notes = buildKeyStaffNotes(tonic_pc, quality, &notes);

    var svg_buf: [24576]u8 = undefined;
    const svg = svg_staff.renderKeyStaff(key_notes, k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_keyboard(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const range = sanitizeKeyboardRange(range_low, range_high);

    var svg_buf: [128 * 1024]u8 = undefined;
    const svg = svg_keyboard.renderKeyboard(notes, range.low, range.high, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_svg_piano_staff(notes_ptr: [*c]const u8, note_count: u32, tonic: u8, quality_raw: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const quality: key.KeyQuality = if (quality_raw == KEY_MINOR) .minor else .major;
    const k = key.Key.init(tonic_pc, quality);

    var svg_buf: [32 * 1024]u8 = undefined;
    const svg = svg_staff.renderPianoStaff(notes, k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

pub export fn lmt_raster_is_enabled() callconv(.c) u32 {
    return if (build_options.enable_raster_backend) 1 else 0;
}

pub export fn lmt_raster_demo_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null or width == 0 or height == 0) return 0;

    const required: u64 = @as(u64, width) * @as(u64, height) * 4;
    if (required == 0 or required > std.math.maxInt(u32)) return 0;
    if (required > @as(u64, out_rgba_size)) return 0;

    const expected_stride = width * 4;
    const out_slice = out_rgba[0..@as(usize, @intCast(required))];
    var surface = raster.Surface{
        .pixels = out_slice,
        .width = width,
        .height = height,
        .stride = expected_stride,
    };
    raster.renderDemoScene(&surface);
    return @as(u32, @intCast(required));
}

pub export fn lmt_bitmap_clock_optc_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_clock_optc(set, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_clock_optc(set, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_optic_k_group_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_optic_k_group(set, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_optic_k_group(set, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_evenness_chart_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_evenness_chart(null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_evenness_chart(@ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_evenness_field_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_evenness_field(set, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_evenness_field(set, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_fret_rgba(frets_ptr: [*c]const i8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (frets_ptr == null or out_rgba == null or width == 0 or height == 0) return 0;
    const required: u64 = @as(u64, width) * @as(u64, height) * 4;
    if (required == 0 or required > @as(u64, out_rgba_size)) return 0;
    const out = out_rgba[0..@as(usize, @intCast(required))];
    const rendered = bitmap_compat.renderPublicStandardFretDiagramRgba(width, height, frets_ptr[0..guitar.tunings.STANDARD.len], out) catch return 0;
    return @as(u32, @intCast(rendered));
}

pub export fn lmt_bitmap_fret_n_rgba(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_fret_n(frets_ptr, string_count, window_start, visible_frets, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_fret_n(frets_ptr, string_count, window_start, visible_frets, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_fret_tuned_n_rgba(
    frets_ptr: [*c]const i8,
    string_count: u32,
    tuning_ptr: [*c]const u8,
    tuning_count: u32,
    window_start: u32,
    visible_frets: u32,
    width: u32,
    height: u32,
    out_rgba: [*c]u8,
    out_rgba_size: u32,
) callconv(.c) u32 {
    const total = lmt_svg_fret_tuned_n(frets_ptr, string_count, tuning_ptr, tuning_count, window_start, visible_frets, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_fret_tuned_n(frets_ptr, string_count, tuning_ptr, tuning_count, window_start, visible_frets, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_chord_staff_rgba(chord_kind: u8, root: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_chord_staff(chord_kind, root, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_chord_staff(chord_kind, root, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_key_staff_rgba(tonic: u8, quality_raw: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_key_staff(tonic, quality_raw, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_key_staff(tonic, quality_raw, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_keyboard_rgba(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_keyboard(notes_ptr, note_count, range_low, range_high, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_keyboard(notes_ptr, note_count, range_low, range_high, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_piano_staff_rgba(notes_ptr: [*c]const u8, note_count: u32, tonic: u8, quality_raw: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    const total = lmt_svg_piano_staff(notes_ptr, note_count, tonic, quality_raw, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_piano_staff(notes_ptr, note_count, tonic, quality_raw, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

pub export fn lmt_bitmap_proof_scale_numerator() callconv(.c) u32 {
    return bitmap_compat.SCALE_NUMERATOR;
}

pub export fn lmt_bitmap_proof_scale_denominator() callconv(.c) u32 {
    return bitmap_compat.SCALE_DENOMINATOR;
}

pub export fn lmt_bitmap_compat_kind_supported(kind_index: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return if (bitmap_compat.kindSupported(@as(usize, kind_index))) 1 else 0;
}

pub export fn lmt_bitmap_compat_candidate_backend_name(kind_index: u32) callconv(.c) [*:0]const u8 {
    if (!build_options.enable_raster_backend) return "".ptr;
    return (bitmap_compat.candidateBackendName(@as(usize, kind_index)) orelse "").ptr;
}

pub export fn lmt_bitmap_compat_target_width_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetWidthScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

pub export fn lmt_bitmap_compat_target_width(kind_index: u32, image_index: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetWidth(@as(usize, kind_index), @as(usize, image_index));
}

pub export fn lmt_bitmap_compat_target_height_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetHeightScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

pub export fn lmt_bitmap_compat_target_height(kind_index: u32, image_index: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetHeight(@as(usize, kind_index), @as(usize, image_index));
}

pub export fn lmt_bitmap_compat_required_rgba_bytes_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.requiredRgbaBytesScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

pub export fn lmt_bitmap_compat_required_rgba_bytes(kind_index: u32, image_index: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.requiredRgbaBytes(@as(usize, kind_index), @as(usize, image_index));
}

pub export fn lmt_bitmap_compat_render_candidate_rgba_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderCandidateRgbaScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator, out) catch return 0;
    return @as(u32, @intCast(len));
}

pub export fn lmt_bitmap_compat_render_candidate_rgba(kind_index: u32, image_index: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderCandidateRgba(@as(usize, kind_index), @as(usize, image_index), out) catch return 0;
    return @as(u32, @intCast(len));
}

pub export fn lmt_bitmap_compat_render_reference_svg_rgba_scaled(kind_index: u32, scale_numerator: u32, scale_denominator: u32, svg_ptr: [*c]const u8, svg_len: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (svg_ptr == null or out_rgba == null or svg_len == 0) return 0;
    const svg = svg_ptr[0..@as(usize, svg_len)];
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderReferenceSvgRgbaScaled(@as(usize, kind_index), svg, scale_numerator, scale_denominator, out) catch return 0;
    return @as(u32, @intCast(len));
}

pub export fn lmt_bitmap_compat_render_reference_svg_rgba(kind_index: u32, svg_ptr: [*c]const u8, svg_len: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (svg_ptr == null or out_rgba == null or svg_len == 0) return 0;
    const svg = svg_ptr[0..@as(usize, svg_len)];
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderReferenceSvgRgba(@as(usize, kind_index), svg, out) catch return 0;
    return @as(u32, @intCast(len));
}

pub export fn lmt_svg_compat_kind_count() callconv(.c) u32 {
    return @as(u32, @intCast(svg_compat.kindCount()));
}

pub export fn lmt_svg_compat_kind_name(kind_index: u32) callconv(.c) [*c]const u8 {
    const name = svg_compat.kindName(@as(usize, kind_index)) orelse return writeCString("");
    return writeCString(name);
}

pub export fn lmt_svg_compat_kind_directory(kind_index: u32) callconv(.c) [*c]const u8 {
    const directory = svg_compat.kindDirectory(@as(usize, kind_index)) orelse return writeCString("");
    return writeCString(directory);
}

pub export fn lmt_svg_compat_image_count(kind_index: u32) callconv(.c) u32 {
    return @as(u32, @intCast(svg_compat.imageCount(@as(usize, kind_index))));
}

pub export fn lmt_svg_compat_image_name(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    const name = svg_compat.imageName(@as(usize, kind_index), @as(usize, image_index)) orelse return 0;
    return copySvgOut(name, buf, buf_size);
}

pub export fn lmt_svg_compat_generate(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32 {
    const svg = svg_compat.generateByIndex(@as(usize, kind_index), @as(usize, image_index), &compat_svg_buf);
    if (svg.len == 0) return 0;
    return copySvgOut(svg, buf, buf_size);
}
