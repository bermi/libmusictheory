const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const note_name = @import("note_name.zig");
const scale = @import("scale.zig");

pub const DEFAULT_RANGE_LOW: pitch.MidiNote = 36;
pub const DEFAULT_RANGE_HIGH: pitch.MidiNote = 83;
pub const NUM_KEYS: usize = DEFAULT_RANGE_HIGH - DEFAULT_RANGE_LOW + 1;
pub const MAX_SELECTED_NOTES: usize = NUM_KEYS;

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

pub fn updateKeyVisuals(state: KeyboardState) [NUM_KEYS]KeyVisual {
    var out: [NUM_KEYS]KeyVisual = undefined;
    const selected_pcs = state.pitchClassSet();

    var i: usize = 0;
    while (i < NUM_KEYS) : (i += 1) {
        const midi = @as(pitch.MidiNote, @intCast(@as(u8, state.range_low) + i));
        const pc = @as(pitch.PitchClass, @intCast(midi % 12));

        const opacity: f32 = if (contains(state.selected(), midi))
            KeyVisual.FULL_OPACITY
        else if ((selected_pcs & (@as(pcs.PitchClassSet, 1) << pc)) != 0)
            KeyVisual.HALF_OPACITY
        else
            KeyVisual.NORMAL_OPACITY;

        out[i] = .{ .midi = midi, .opacity = opacity };
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

fn midiLessThan(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
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
