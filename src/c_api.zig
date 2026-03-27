const std = @import("std");
const build_options = @import("build_options");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const cluster = @import("cluster.zig");
const evenness = @import("evenness.zig");
const scale = @import("scale.zig");
const mode = @import("mode.zig");
const key = @import("key.zig");
const note_spelling = @import("note_spelling.zig");
const chord_type = @import("chord_type.zig");
const chord = @import("chord_construction.zig");
const harmony = @import("harmony.zig");
const counterpoint = @import("counterpoint.zig");
const guitar = @import("guitar.zig");
const keyboard_logic = @import("keyboard.zig");
const svg_clock = @import("svg/clock.zig");
const svg_evenness_chart = @import("svg/evenness_chart.zig");
const svg_fret = @import("svg/fret.zig");
const svg_keyboard = @import("svg/keyboard_svg.zig");
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

const SCALE_DIATONIC: u8 = 0;
const SCALE_ACOUSTIC: u8 = 1;
const SCALE_DIMINISHED: u8 = 2;
const SCALE_WHOLE_TONE: u8 = 3;
const SCALE_HARMONIC_MINOR: u8 = 4;
const SCALE_HARMONIC_MAJOR: u8 = 5;
const SCALE_DOUBLE_AUGMENTED_HEXATONIC: u8 = 6;

const MODE_IONIAN: u8 = 0;
const MODE_DORIAN: u8 = 1;
const MODE_PHRYGIAN: u8 = 2;
const MODE_LYDIAN: u8 = 3;
const MODE_MIXOLYDIAN: u8 = 4;
const MODE_AEOLIAN: u8 = 5;
const MODE_LOCRIAN: u8 = 6;
const MODE_MELODIC_MINOR: u8 = 7;
const MODE_DORIAN_B2: u8 = 8;
const MODE_LYDIAN_AUG: u8 = 9;
const MODE_LYDIAN_DOM: u8 = 10;
const MODE_MIXOLYDIAN_B6: u8 = 11;
const MODE_LOCRIAN_NAT2: u8 = 12;
const MODE_SUPER_LOCRIAN: u8 = 13;
const MODE_HALF_WHOLE: u8 = 14;
const MODE_WHOLE_HALF: u8 = 15;
const MODE_WHOLE_TONE: u8 = 16;

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

var c_string_slots: [8][32]u8 = [_][32]u8{[_]u8{0} ** 32} ** 8;
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
    return switch (mode_type) {
        MODE_IONIAN => .ionian,
        MODE_DORIAN => .dorian,
        MODE_PHRYGIAN => .phrygian,
        MODE_LYDIAN => .lydian,
        MODE_MIXOLYDIAN => .mixolydian,
        MODE_AEOLIAN => .aeolian,
        MODE_LOCRIAN => .locrian,
        MODE_MELODIC_MINOR => .melodic_minor,
        MODE_DORIAN_B2 => .dorian_b2,
        MODE_LYDIAN_AUG => .lydian_aug,
        MODE_LYDIAN_DOM => .lydian_dom,
        MODE_MIXOLYDIAN_B6 => .mixolydian_b6,
        MODE_LOCRIAN_NAT2 => .locrian_nat2,
        MODE_SUPER_LOCRIAN => .super_locrian,
        MODE_HALF_WHOLE => .half_whole,
        MODE_WHOLE_HALF => .whole_half,
        MODE_WHOLE_TONE => .whole_tone,
        else => null,
    };
}

fn modeSet(mode_type: mode.ModeType) pcs.PitchClassSet {
    for (mode.ALL_MODES) |one| {
        if (one.id == mode_type) return one.pcs;
    }
    return mode.ALL_MODES[0].pcs;
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

pub export fn lmt_sizeof_voiced_state() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtVoicedState)));
}

pub export fn lmt_sizeof_voiced_history() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtVoicedHistory)));
}

pub export fn lmt_sizeof_next_step_suggestion() callconv(.c) u32 {
    return @as(u32, @intCast(@sizeOf(LmtNextStepSuggestion)));
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
            out[index] = .{
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
    }

    return @as(u32, @intCast(total));
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
