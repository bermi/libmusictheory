const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const note_name = @import("note_name.zig");
const scale = @import("scale.zig");
const mode = @import("mode.zig");
const key = @import("key.zig");
const evenness = @import("evenness.zig");
const cluster = @import("cluster.zig");
const chord = @import("chord_construction.zig");

pub const DEFAULT_RANGE_LOW: pitch.MidiNote = 36;
pub const DEFAULT_RANGE_HIGH: pitch.MidiNote = 83;
pub const NUM_KEYS: usize = DEFAULT_RANGE_HIGH - DEFAULT_RANGE_LOW + 1;
pub const MAX_SELECTED_NOTES: usize = NUM_KEYS;
pub const MAX_CONTEXT_SUGGESTIONS: usize = 12;

pub const AccidentalPreference = note_name.AccidentalPreference;

pub const KeyboardState = struct {
    selected_notes: [MAX_SELECTED_NOTES]pitch.MidiNote,
    selected_len: usize,
    accidental_preference: AccidentalPreference,
    range_low: pitch.MidiNote,
    range_high: pitch.MidiNote,

    pub fn init() KeyboardState {
        return .{
            .selected_notes = [_]pitch.MidiNote{0} ** MAX_SELECTED_NOTES,
            .selected_len = 0,
            .accidental_preference = .sharps,
            .range_low = DEFAULT_RANGE_LOW,
            .range_high = DEFAULT_RANGE_HIGH,
        };
    }

    pub fn selected(self: *const KeyboardState) []const pitch.MidiNote {
        return self.selected_notes[0..self.selected_len];
    }

    pub fn toggle(self: *KeyboardState, note: pitch.MidiNote) void {
        if (note < self.range_low or note > self.range_high) return;

        if (indexOf(self.selected(), note)) |idx| {
            var i = idx;
            while (i + 1 < self.selected_len) : (i += 1) {
                self.selected_notes[i] = self.selected_notes[i + 1];
            }
            self.selected_len -= 1;
            return;
        }

        if (self.selected_len >= MAX_SELECTED_NOTES) return;

        var insert_at: usize = self.selected_len;
        var i: usize = 0;
        while (i < self.selected_len) : (i += 1) {
            if (self.selected_notes[i] > note) {
                insert_at = i;
                break;
            }
        }

        var j: usize = self.selected_len;
        while (j > insert_at) : (j -= 1) {
            self.selected_notes[j] = self.selected_notes[j - 1];
        }

        self.selected_notes[insert_at] = note;
        self.selected_len += 1;
    }

    pub fn pitchClassSet(self: *const KeyboardState) pcs.PitchClassSet {
        var out: pcs.PitchClassSet = 0;
        for (self.selected()) |note| {
            const pc = @as(pitch.PitchClass, @intCast(note % 12));
            out |= @as(pcs.PitchClassSet, 1) << pc;
        }
        return out;
    }
};

pub const KeyVisual = struct {
    midi: pitch.MidiNote,
    opacity: f32,

    pub const FULL_OPACITY: f32 = 1.0;
    pub const HALF_OPACITY: f32 = 0.5;
    pub const NORMAL_OPACITY: f32 = 0.0;
};

pub const PlaybackMode = enum {
    solo,
    sequential,
    simultaneous,
};

pub const ContextSuggestion = struct {
    pitch_class: pitch.PitchClass,
    expanded_set: pcs.PitchClassSet,
    score: i32,
    in_context: bool,
    overlap: u4,
    outside_count: u4,
    cluster_free: bool,
    reads_as_named_chord: bool,
};

pub fn notesPitchClassSet(notes: []const pitch.MidiNote) pcs.PitchClassSet {
    var out: pcs.PitchClassSet = 0;
    for (notes) |note| {
        const pc = @as(pitch.PitchClass, @intCast(note % 12));
        out |= @as(pcs.PitchClassSet, 1) << pc;
    }
    return out;
}

pub fn visualOpacityForMidi(selected: []const pitch.MidiNote, selected_pcs: pcs.PitchClassSet, midi: pitch.MidiNote) f32 {
    return if (contains(selected, midi))
        KeyVisual.FULL_OPACITY
    else if ((selected_pcs & (@as(pcs.PitchClassSet, 1) << @as(pitch.PitchClass, @intCast(midi % 12)))) != 0)
        KeyVisual.HALF_OPACITY
    else
        KeyVisual.NORMAL_OPACITY;
}

pub fn updateKeyVisuals(state: KeyboardState) [NUM_KEYS]KeyVisual {
    var out: [NUM_KEYS]KeyVisual = undefined;
    const selected_pcs = state.pitchClassSet();

    var i: usize = 0;
    while (i < NUM_KEYS) : (i += 1) {
        const midi = @as(pitch.MidiNote, @intCast(@as(u8, state.range_low) + i));
        out[i] = .{
            .midi = midi,
            .opacity = visualOpacityForMidi(state.selected(), selected_pcs, midi),
        };
    }

    return out;
}

pub fn notesToUrl(notes: []const pitch.MidiNote, pref: AccidentalPreference, buf: []u8) []u8 {
    var sorted: [MAX_SELECTED_NOTES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_SELECTED_NOTES;
    std.debug.assert(notes.len <= sorted.len);

    std.mem.copyForwards(pitch.MidiNote, sorted[0..notes.len], notes);
    std.sort.heap(pitch.MidiNote, sorted[0..notes.len], {}, midiLessThan);

    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();

    for (sorted[0..notes.len], 0..) |note, i| {
        if (i > 0) writer.writeByte('-') catch unreachable;
        writeNoteToken(writer, note, pref);
    }

    return buf[0..stream.pos];
}

pub fn urlToNotes(url: []const u8, out: []pitch.MidiNote) []pitch.MidiNote {
    if (url.len == 0) return out[0..0];

    var count: usize = 0;

    if (std.mem.indexOfScalar(u8, url, ',')) |_| {
        var it = std.mem.splitScalar(u8, url, ',');
        while (it.next()) |token| {
            if (count >= out.len) break;
            const note = parseNoteToken(token) orelse continue;
            out[count] = note;
            count += 1;
        }
    } else {
        var it = std.mem.splitScalar(u8, url, '-');
        while (it.next()) |token| {
            if (count >= out.len) break;
            const note = parseNoteToken(token) orelse continue;
            out[count] = note;
            count += 1;
        }
    }

    std.sort.heap(pitch.MidiNote, out[0..count], {}, midiLessThan);
    return out[0..count];
}

pub fn playbackStyle(set: pcs.PitchClassSet) PlaybackMode {
    const card = pcs.cardinality(set);
    if (card <= 1) return .solo;
    if (scale.isScaley(set)) return .sequential;
    return .simultaneous;
}

pub fn modeSet(tonic: pitch.PitchClass, mode_type: mode.ModeType) pcs.PitchClassSet {
    const rooted = mode.ALL_MODES[@intFromEnum(mode_type)].pcs;
    return pcs.transpose(rooted, tonic);
}

pub fn modeSpellingQuality(tonic: pitch.PitchClass, mode_type: mode.ModeType) key.KeyQuality {
    const mode_set = modeSet(tonic, mode_type);
    const minor_third = (mode_set & (@as(pcs.PitchClassSet, 1) << @as(u4, @intCast((@as(u8, tonic) + 3) % 12)))) != 0;
    const major_third = (mode_set & (@as(pcs.PitchClassSet, 1) << @as(u4, @intCast((@as(u8, tonic) + 4) % 12)))) != 0;
    if (minor_third and !major_third) return .minor;
    return .major;
}

pub fn rankContextSuggestions(
    set_value: pcs.PitchClassSet,
    midi_notes: []const pitch.MidiNote,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    out: []ContextSuggestion,
) []ContextSuggestion {
    if (set_value == 0 or out.len == 0) return out[0..0];

    const context_set = modeSet(tonic, mode_type);
    const current_overlap = pcs.cardinality(set_value & context_set);
    const last_pc: ?pitch.PitchClass = if (midi_notes.len > 0)
        @as(pitch.PitchClass, @intCast(midi_notes[midi_notes.len - 1] % 12))
    else
        null;

    var suggestions: [MAX_CONTEXT_SUGGESTIONS]ContextSuggestion = undefined;
    var count: usize = 0;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        if ((set_value & bit) != 0) continue;

        const expanded = set_value | bit;
        const in_context = (context_set & bit) != 0;
        const overlap = pcs.cardinality(expanded & context_set);
        const outside_count = pcs.cardinality(expanded) - overlap;
        const overlap_gain = @as(i32, @intCast(overlap)) - @as(i32, @intCast(current_overlap));
        const cluster_free = !cluster.hasCluster(expanded);
        const named_chord = chord.pcsToChordName(expanded) != null;
        const evenness_penalty = @as(i32, @intFromFloat(@round(evenness.evennessDistance(expanded) * 12.0)));
        const step_distance = if (last_pc) |lp|
            circularDistance(pc, lp)
        else
            0;
        const root_distance = circularDistance(pc, tonic);

        var score: i32 = if (in_context) 1600 else -800;
        score += overlap_gain * 800;
        score -= @as(i32, @intCast(outside_count)) * 400;
        score += if (cluster_free) 300 else -400;
        if (named_chord) score += 500;
        score -= evenness_penalty;
        score -= @as(i32, @intCast(step_distance)) * 40;
        score -= @as(i32, @intCast(root_distance)) * 15;
        if ((expanded & context_set) == expanded) score += 500;
        if (midi_notes.len <= 2 and named_chord) score += 300;

        suggestions[count] = .{
            .pitch_class = @as(pitch.PitchClass, @intCast(pc)),
            .expanded_set = expanded,
            .score = score,
            .in_context = in_context,
            .overlap = overlap,
            .outside_count = outside_count,
            .cluster_free = cluster_free,
            .reads_as_named_chord = named_chord,
        };
        count += 1;
    }

    var i: usize = 1;
    while (i < count) : (i += 1) {
        const value = suggestions[i];
        var j = i;
        while (j > 0 and contextSuggestionLessThan(value, suggestions[j - 1])) : (j -= 1) {
            suggestions[j] = suggestions[j - 1];
        }
        suggestions[j] = value;
    }

    const write_len = @min(count, out.len);
    @memcpy(out[0..write_len], suggestions[0..write_len]);
    return out[0..write_len];
}

fn midiLessThan(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
}

fn contextSuggestionLessThan(a: ContextSuggestion, b: ContextSuggestion) bool {
    if (a.score != b.score) return a.score > b.score;
    return a.pitch_class < b.pitch_class;
}

fn circularDistance(a: pitch.PitchClass, b: pitch.PitchClass) u4 {
    const forward = (@as(u8, a) + 12 - @as(u8, b)) % 12;
    const backward = (@as(u8, b) + 12 - @as(u8, a)) % 12;
    return @as(u4, @intCast(@min(forward, backward)));
}

fn contains(haystack: []const pitch.MidiNote, needle: pitch.MidiNote) bool {
    return indexOf(haystack, needle) != null;
}

fn indexOf(haystack: []const pitch.MidiNote, needle: pitch.MidiNote) ?usize {
    for (haystack, 0..) |item, i| {
        if (item == needle) return i;
    }
    return null;
}

fn writeNoteToken(writer: anytype, midi: pitch.MidiNote, pref: AccidentalPreference) void {
    const pc = @as(pitch.PitchClass, @intCast(midi % 12));
    const name = note_name.chooseName(pc, pref);
    var name_buf: [4]u8 = undefined;
    const note_str = name.format(&name_buf);

    writer.writeAll(note_str) catch unreachable;
    writer.print("{d}", .{pitch.midiToOctave(midi)}) catch unreachable;
}

fn parseNoteToken(raw: []const u8) ?pitch.MidiNote {
    const token = std.mem.trim(u8, raw, " \t\n\r");
    if (token.len < 2) return null;

    const letter_pc = switch (token[0]) {
        'C' => @as(i16, 0),
        'D' => 2,
        'E' => 4,
        'F' => 5,
        'G' => 7,
        'A' => 9,
        'B' => 11,
        else => return null,
    };

    var i: usize = 1;
    var accidental: i16 = 0;

    if (i < token.len and (token[i] == '#' or token[i] == 's')) {
        accidental = 1;
        i += 1;
    } else if (i < token.len and token[i] == 'b') {
        accidental = -1;
        i += 1;
    }

    if (i < token.len and (token[i] == '_' or token[i] == '/' or token[i] == '-')) {
        i += 1;
    }

    if (i >= token.len) return null;
    const octave = std.fmt.parseInt(i8, token[i..], 10) catch return null;

    const pc = pitch.wrapPitchClass(letter_pc + accidental);
    return pitch.pcToMidi(pc, octave);
}
