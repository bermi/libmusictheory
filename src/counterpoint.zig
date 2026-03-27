const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const mode = @import("mode.zig");
const key = @import("key.zig");
const keyboard = @import("keyboard.zig");

pub const MAX_VOICES: usize = 8;
pub const HISTORY_CAPACITY: usize = 4;
const ASSIGNMENT_COST_SCALE: i16 = 4;
const INSERT_DELETE_COST: i16 = 24;

pub const MetricPosition = struct {
    beat_in_bar: u8 = 0,
    beats_per_bar: u8 = 4,
    subdivision: u8 = 0,

    pub fn normalized(beat_in_bar: u8, beats_per_bar: u8, subdivision: u8) MetricPosition {
        const bar_beats = if (beats_per_bar == 0) 4 else beats_per_bar;
        return .{
            .beat_in_bar = beat_in_bar % bar_beats,
            .beats_per_bar = bar_beats,
            .subdivision = subdivision,
        };
    }
};

pub const CadenceState = enum(u8) {
    none,
    stable,
    pre_dominant,
    dominant,
    cadential_six_four,
    authentic_arrival,
    half_arrival,
    deceptive_pull,
};

pub const Voice = struct {
    id: u8,
    midi: pitch.MidiNote,
    pitch_class: pitch.PitchClass,
    octave: i8,
    sustained: bool,
};

pub const VoicedState = struct {
    set_value: pcs.PitchClassSet,
    voice_count: u8,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    key_quality: key.KeyQuality,
    metric: MetricPosition,
    cadence_state: CadenceState,
    state_index: u8,
    next_voice_id: u8,
    voices: [MAX_VOICES]Voice,

    pub fn initEmpty(tonic: pitch.PitchClass, mode_type: mode.ModeType, metric: MetricPosition) VoicedState {
        return .{
            .set_value = 0,
            .voice_count = 0,
            .tonic = tonic,
            .mode_type = mode_type,
            .key_quality = keyboard.modeSpellingQuality(tonic, mode_type),
            .metric = metric,
            .cadence_state = .none,
            .state_index = 0,
            .next_voice_id = 0,
            .voices = [_]Voice{emptyVoice()} ** MAX_VOICES,
        };
    }

    pub fn slice(self: *const VoicedState) []const Voice {
        return self.voices[0..self.voice_count];
    }
};

pub const VoicedHistoryWindow = struct {
    states: [HISTORY_CAPACITY]VoicedState,
    len: u8,
    next_voice_id: u8,

    pub fn init() VoicedHistoryWindow {
        return .{
            .states = [_]VoicedState{VoicedState.initEmpty(0, .ionian, MetricPosition.normalized(0, 4, 0))} ** HISTORY_CAPACITY,
            .len = 0,
            .next_voice_id = 0,
        };
    }

    pub fn reset(self: *VoicedHistoryWindow) void {
        self.* = init();
    }

    pub fn current(self: *const VoicedHistoryWindow) ?*const VoicedState {
        if (self.len == 0) return null;
        return &self.states[self.len - 1];
    }

    pub fn previous(self: *const VoicedHistoryWindow) ?*const VoicedState {
        if (self.len < 2) return null;
        return &self.states[self.len - 2];
    }

    pub fn push(
        self: *VoicedHistoryWindow,
        notes: []const pitch.MidiNote,
        sustained_notes: []const pitch.MidiNote,
        tonic: pitch.PitchClass,
        mode_type: mode.ModeType,
        metric: MetricPosition,
        cadence_hint: ?CadenceState,
    ) VoicedState {
        const prior = self.current();
        const next = buildVoicedState(notes, sustained_notes, tonic, mode_type, metric, cadence_hint, prior, self.next_voice_id);
        if (self.len < HISTORY_CAPACITY) {
            self.states[self.len] = next;
            self.len += 1;
        } else {
            var index: usize = 1;
            while (index < HISTORY_CAPACITY) : (index += 1) {
                self.states[index - 1] = self.states[index];
            }
            self.states[HISTORY_CAPACITY - 1] = next;
        }
        self.next_voice_id = next.next_voice_id;
        return next;
    }
};

pub fn buildVoicedState(
    notes: []const pitch.MidiNote,
    sustained_notes: []const pitch.MidiNote,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    metric: MetricPosition,
    cadence_hint: ?CadenceState,
    previous: ?*const VoicedState,
    next_voice_id_seed: u8,
) VoicedState {
    var normalized_notes: [MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_VOICES;
    var sustained_flags: [MAX_VOICES]bool = [_]bool{false} ** MAX_VOICES;
    const note_count = normalizeNotes(notes, sustained_notes, &normalized_notes, &sustained_flags);

    var state = VoicedState.initEmpty(tonic, mode_type, metric);
    state.key_quality = keyboard.modeSpellingQuality(tonic, mode_type);
    state.state_index = if (previous) |prev| prev.state_index + 1 else 0;
    state.set_value = keyboard.notesPitchClassSet(normalized_notes[0..note_count]);

    var assigned_ids: [MAX_VOICES]u8 = [_]u8{0} ** MAX_VOICES;
    state.next_voice_id = assignVoiceIds(normalized_notes[0..note_count], previous, next_voice_id_seed, &assigned_ids);
    state.voice_count = @as(u8, @intCast(note_count));

    var index: usize = 0;
    while (index < note_count) : (index += 1) {
        const midi = normalized_notes[index];
        state.voices[index] = .{
            .id = assigned_ids[index],
            .midi = midi,
            .pitch_class = pitch.midiToPC(midi),
            .octave = pitch.midiToOctave(midi),
            .sustained = sustained_flags[index],
        };
    }
    while (index < MAX_VOICES) : (index += 1) {
        state.voices[index] = emptyVoice();
    }

    state.cadence_state = cadence_hint orelse inferCadenceState(state.set_value, tonic, state.key_quality, metric);
    return state;
}

pub fn inferCadenceState(
    set_value: pcs.PitchClassSet,
    tonic: pitch.PitchClass,
    quality: key.KeyQuality,
    metric: MetricPosition,
) CadenceState {
    _ = quality;
    if (set_value == 0) return .none;

    const normalized = pcs.transposeDown(set_value, tonic);
    const has_root = containsPc(normalized, 0);
    const has_third = containsPc(normalized, 3) or containsPc(normalized, 4);
    const has_fourth = containsPc(normalized, 5);
    const has_second = containsPc(normalized, 2);
    const has_fifth = containsPc(normalized, 7);
    const has_leading = containsPc(normalized, 11);
    const on_strong_arrival = metric.beats_per_bar > 0 and metric.beat_in_bar + 1 == metric.beats_per_bar;

    if (has_fifth and has_fourth and containsPc(normalized, 0)) return .cadential_six_four;
    if (has_root and has_third and on_strong_arrival) return .authentic_arrival;
    if (has_fifth and has_leading) return .dominant;
    if (has_second and has_fourth) return .pre_dominant;
    if (has_fifth and on_strong_arrival) return .half_arrival;
    if (has_root and has_third) return .stable;
    return .none;
}

fn emptyVoice() Voice {
    return .{
        .id = 0,
        .midi = 0,
        .pitch_class = 0,
        .octave = -1,
        .sustained = false,
    };
}

fn normalizeNotes(
    notes: []const pitch.MidiNote,
    sustained_notes: []const pitch.MidiNote,
    out_notes: *[MAX_VOICES]pitch.MidiNote,
    out_sustained: *[MAX_VOICES]bool,
) usize {
    var sorted: [MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_VOICES;
    var count: usize = 0;
    for (notes) |note| {
        if (count >= MAX_VOICES) break;
        if (containsMidi(sorted[0..count], note)) continue;
        sorted[count] = note;
        count += 1;
    }

    std.sort.heap(pitch.MidiNote, sorted[0..count], {}, lessThanMidi);

    for (sorted[0..count], 0..) |note, index| {
        out_notes[index] = note;
        out_sustained[index] = containsMidi(sustained_notes, note);
    }
    return count;
}

fn assignVoiceIds(
    current_notes: []const pitch.MidiNote,
    previous: ?*const VoicedState,
    next_voice_id_seed: u8,
    out_ids: *[MAX_VOICES]u8,
) u8 {
    if (current_notes.len == 0) return next_voice_id_seed;
    if (previous == null or previous.?.voice_count == 0) {
        var next_id = next_voice_id_seed;
        for (current_notes, 0..) |_, index| {
            out_ids[index] = next_id;
            next_id +%= 1;
        }
        return next_id;
    }

    const prev = previous.?;
    const m = @as(usize, prev.voice_count);
    const n = current_notes.len;
    const size = @max(m, n);

    var cost: [MAX_VOICES][MAX_VOICES]i16 = [_][MAX_VOICES]i16{[_]i16{0} ** MAX_VOICES} ** MAX_VOICES;
    var row: usize = 0;
    while (row < size) : (row += 1) {
        var col: usize = 0;
        while (col < size) : (col += 1) {
            const real_row = row < m;
            const real_col = col < n;
            cost[row][col] = switch (@as(u2, @intFromBool(real_row)) << 1 | @as(u2, @intFromBool(real_col))) {
                0b11 => @as(i16, @intCast(@abs(@as(i16, prev.voices[row].midi) - @as(i16, current_notes[col])) * ASSIGNMENT_COST_SCALE)),
                0b10 => INSERT_DELETE_COST,
                0b01 => INSERT_DELETE_COST,
                else => 0,
            };
        }
    }

    var assignment: [MAX_VOICES]usize = [_]usize{0} ** MAX_VOICES;
    hungarianAssign(size, &cost, &assignment);

    var matched_ids: [MAX_VOICES]?u8 = [_]?u8{null} ** MAX_VOICES;
    row = 0;
    while (row < m) : (row += 1) {
        const col = assignment[row];
        if (col < n) matched_ids[col] = prev.voices[row].id;
    }

    var next_id = next_voice_id_seed;
    for (current_notes, 0..) |_, index| {
        if (matched_ids[index]) |id| {
            out_ids[index] = id;
        } else {
            out_ids[index] = next_id;
            next_id +%= 1;
        }
    }
    return next_id;
}

fn hungarianAssign(size: usize, cost: *const [MAX_VOICES][MAX_VOICES]i16, assignment: *[MAX_VOICES]usize) void {
    if (size == 0) return;

    var u: [MAX_VOICES + 1]i16 = [_]i16{0} ** (MAX_VOICES + 1);
    var v: [MAX_VOICES + 1]i16 = [_]i16{0} ** (MAX_VOICES + 1);
    var p: [MAX_VOICES + 1]usize = [_]usize{0} ** (MAX_VOICES + 1);
    var way: [MAX_VOICES + 1]usize = [_]usize{0} ** (MAX_VOICES + 1);

    var row: usize = 1;
    while (row <= size) : (row += 1) {
        p[0] = row;
        var minv: [MAX_VOICES + 1]i16 = [_]i16{std.math.maxInt(i16)} ** (MAX_VOICES + 1);
        var used: [MAX_VOICES + 1]bool = [_]bool{false} ** (MAX_VOICES + 1);
        var col0: usize = 0;

        while (true) {
            used[col0] = true;
            const row0 = p[col0];
            var delta: i16 = std.math.maxInt(i16);
            var col1: usize = 0;

            var col: usize = 1;
            while (col <= size) : (col += 1) {
                if (used[col]) continue;
                const cur = cost[row0 - 1][col - 1] - u[row0] - v[col];
                if (cur < minv[col]) {
                    minv[col] = cur;
                    way[col] = col0;
                }
                if (minv[col] < delta) {
                    delta = minv[col];
                    col1 = col;
                }
            }

            var col_adjust: usize = 0;
            while (col_adjust <= size) : (col_adjust += 1) {
                if (used[col_adjust]) {
                    u[p[col_adjust]] += delta;
                    v[col_adjust] -= delta;
                } else {
                    minv[col_adjust] -= delta;
                }
            }

            col0 = col1;
            if (p[col0] == 0) break;
        }

        while (true) {
            const col1 = way[col0];
            p[col0] = p[col1];
            col0 = col1;
            if (col0 == 0) break;
        }
    }

    var col: usize = 1;
    while (col <= size) : (col += 1) {
        if (p[col] != 0) assignment[p[col] - 1] = col - 1;
    }
}

fn containsPc(set_value: pcs.PitchClassSet, pc: u4) bool {
    return (set_value & (@as(pcs.PitchClassSet, 1) << pc)) != 0;
}

fn containsMidi(notes: []const pitch.MidiNote, midi: pitch.MidiNote) bool {
    for (notes) |note| {
        if (note == midi) return true;
    }
    return false;
}

fn lessThanMidi(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
}
