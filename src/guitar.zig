const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");

pub const NUM_STRINGS: usize = 6;
pub const MAX_FRET: u5 = 24;
pub const GUIDE_OPACITY: f32 = 0.35;
pub const MAX_GENERIC_STRINGS: usize = 16;
const MAX_OPTIONS_PER_STRING: usize = 10;

pub const Tuning = [NUM_STRINGS]pitch.MidiNote;

pub const tunings = struct {
    pub const STANDARD: Tuning = .{ 40, 45, 50, 55, 59, 64 };
    pub const DROP_D: Tuning = .{ 38, 45, 50, 55, 59, 64 };
    pub const DADGAD: Tuning = .{ 38, 45, 50, 55, 57, 62 };
    pub const OPEN_G: Tuning = .{ 38, 43, 50, 55, 59, 62 };
    pub const OPEN_D: Tuning = .{ 38, 45, 50, 54, 57, 62 };
};

pub const FretPosition = struct {
    string: u3,
    fret: u5,

    pub fn toMidi(self: FretPosition, tuning: Tuning) pitch.MidiNote {
        return fretToMidi(self.string, self.fret, tuning);
    }

    pub fn toPitchClass(self: FretPosition, tuning: Tuning) pitch.PitchClass {
        return @as(pitch.PitchClass, @intCast(self.toMidi(tuning) % 12));
    }
};

pub const GenericFretPosition = struct {
    string: usize,
    fret: u8,

    pub fn toMidi(self: GenericFretPosition, tuning: []const pitch.MidiNote) ?pitch.MidiNote {
        return fretToMidiGeneric(self.string, self.fret, tuning);
    }

    pub fn toPitchClass(self: GenericFretPosition, tuning: []const pitch.MidiNote) ?pitch.PitchClass {
        const midi = self.toMidi(tuning) orelse return null;
        return @as(pitch.PitchClass, @intCast(midi % 12));
    }
};

pub const GuitarVoicing = struct {
    frets: [NUM_STRINGS]i8,
    tuning: Tuning,

    pub fn toPitchClassSet(self: GuitarVoicing) pcs.PitchClassSet {
        var out: pcs.PitchClassSet = 0;
        for (self.frets, 0..) |fret, string| {
            if (fret < 0) continue;
            const midi = self.tuning[string] + @as(pitch.MidiNote, @intCast(fret));
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            out |= @as(pcs.PitchClassSet, 1) << pc;
        }
        return out;
    }

    pub fn handSpan(self: GuitarVoicing) u5 {
        var has_fretted = false;
        var min_fret: u5 = MAX_FRET;
        var max_fret: u5 = 0;

        for (self.frets) |fret| {
            if (fret <= 0) continue;
            has_fretted = true;
            const uf = @as(u5, @intCast(fret));
            if (uf < min_fret) min_fret = uf;
            if (uf > max_fret) max_fret = uf;
        }

        if (!has_fretted) return 0;
        return max_fret - min_fret;
    }
};

pub const GenericVoicing = struct {
    frets: []const i8,
    tuning: []const pitch.MidiNote,

    pub fn toPitchClassSet(self: GenericVoicing) pcs.PitchClassSet {
        var out: pcs.PitchClassSet = 0;
        for (self.frets, 0..) |fret, string| {
            if (fret < 0 or string >= self.tuning.len) continue;
            const midi = fretToMidiGeneric(string, @as(u8, @intCast(fret)), self.tuning) orelse continue;
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            out |= @as(pcs.PitchClassSet, 1) << pc;
        }
        return out;
    }

    pub fn handSpan(self: GenericVoicing) u8 {
        var has_fretted = false;
        var min_fret: u8 = std.math.maxInt(u8);
        var max_fret: u8 = 0;

        for (self.frets) |fret| {
            if (fret <= 0) continue;
            has_fretted = true;
            const uf = @as(u8, @intCast(fret));
            if (uf < min_fret) min_fret = uf;
            if (uf > max_fret) max_fret = uf;
        }

        if (!has_fretted) return 0;
        return max_fret - min_fret;
    }
};

pub const CAGEDShape = enum(u3) {
    C,
    A,
    G,
    E,
    D,
};

pub const CAGEDQuality = enum {
    major,
};

pub const CAGEDPosition = struct {
    shape: CAGEDShape,
    frets: [NUM_STRINGS]i8,
    position: u5,
    root_string: u3,
};

pub const GuideDot = struct {
    position: FretPosition,
    pitch_class: pitch.PitchClass,
    opacity: f32,
};

pub const GenericGuideDot = struct {
    position: GenericFretPosition,
    pitch_class: pitch.PitchClass,
    opacity: f32,
};

const ShapeTemplate = struct {
    shape: CAGEDShape,
    frets: [NUM_STRINGS]i8,
    root_string: u3,
    root_fret: u5,
};

const CAGED_MAJOR_SHAPES = [_]ShapeTemplate{
    .{ .shape = .C, .frets = .{ -1, 3, 2, 0, 1, 0 }, .root_string = 1, .root_fret = 3 },
    .{ .shape = .A, .frets = .{ -1, 0, 2, 2, 2, 0 }, .root_string = 1, .root_fret = 0 },
    .{ .shape = .G, .frets = .{ 3, 2, 0, 0, 0, 3 }, .root_string = 0, .root_fret = 3 },
    .{ .shape = .E, .frets = .{ 0, 2, 2, 1, 0, 0 }, .root_string = 0, .root_fret = 0 },
    .{ .shape = .D, .frets = .{ -1, -1, 0, 2, 3, 2 }, .root_string = 2, .root_fret = 0 },
};

pub fn fretToMidi(string: u3, fret: u5, tuning: Tuning) pitch.MidiNote {
    return fretToMidiGeneric(string, fret, tuning[0..]).?;
}

pub fn fretToMidiGeneric(string: usize, fret: u8, tuning: []const pitch.MidiNote) ?pitch.MidiNote {
    if (string >= tuning.len) return null;
    const midi = @as(u16, tuning[string]) + fret;
    if (midi > 127) return null;
    return @as(pitch.MidiNote, @intCast(midi));
}

pub fn midiToFretPositions(note: pitch.MidiNote, tuning: Tuning, out: *[NUM_STRINGS]FretPosition) []FretPosition {
    var generic_out: [NUM_STRINGS]GenericFretPosition = undefined;
    const generic_positions = midiToFretPositionsGeneric(note, tuning[0..], &generic_out);

    for (generic_positions, 0..) |pos, i| {
        out[i] = .{
            .string = @as(u3, @intCast(pos.string)),
            .fret = @as(u5, @intCast(pos.fret)),
        };
    }

    return out[0..generic_positions.len];
}

pub fn midiToFretPositionsGeneric(note: pitch.MidiNote, tuning: []const pitch.MidiNote, out: []GenericFretPosition) []GenericFretPosition {
    var count: usize = 0;
    for (tuning, 0..) |open_note, string| {
        if (note < open_note) continue;
        const fret = note - open_note;
        if (fret > MAX_FRET) continue;
        if (count >= out.len) return out[0..count];

        out[count] = .{
            .string = string,
            .fret = @as(u8, @intCast(fret)),
        };
        count += 1;
    }
    return out[0..count];
}

pub fn pcToFretPositions(pc: pitch.PitchClass, min_fret: u5, max_fret: u5, tuning: Tuning, out: []FretPosition) []FretPosition {
    var count: usize = 0;
    const hi = @min(max_fret, MAX_FRET);

    for (tuning, 0..) |open_note, string| {
        const open_pc = @as(pitch.PitchClass, @intCast(open_note % 12));
        var fret = @as(u5, @intCast((@as(u8, pc) + 12 - @as(u8, open_pc)) % 12));

        while (fret <= hi) : (fret += 12) {
            if (fret < min_fret) continue;
            if (count >= out.len) return out[0..count];

            out[count] = .{
                .string = @as(u3, @intCast(string)),
                .fret = fret,
            };
            count += 1;
        }
    }

    return out[0..count];
}

pub fn generateVoicingsGeneric(chord_pcs: pcs.PitchClassSet, tuning: []const pitch.MidiNote, max_fret: u8, max_span: u8, out: []GenericVoicing, out_fret_storage: []i8) []GenericVoicing {
    if (tuning.len == 0 or tuning.len > MAX_GENERIC_STRINGS) return out[0..0];
    if (out.len == 0) return out[0..0];
    const per_voicing = tuning.len;
    if (per_voicing == 0) return out[0..0];
    const storage_cap = out_fret_storage.len / per_voicing;
    if (storage_cap == 0) return out[0..0];

    var count: usize = 0;
    const out_cap = @min(out.len, storage_cap);

    var base_fret: u8 = 0;
    while (base_fret <= max_fret) : (base_fret += 1) {
        var options: [MAX_GENERIC_STRINGS][MAX_OPTIONS_PER_STRING]i8 = [_][MAX_OPTIONS_PER_STRING]i8{[_]i8{-1} ** MAX_OPTIONS_PER_STRING} ** MAX_GENERIC_STRINGS;
        var option_counts: [MAX_GENERIC_STRINGS]u8 = [_]u8{0} ** MAX_GENERIC_STRINGS;

        buildStringOptionsGeneric(chord_pcs, tuning, max_fret, base_fret, max_span, &options, &option_counts);

        var frets: [MAX_GENERIC_STRINGS]i8 = [_]i8{-1} ** MAX_GENERIC_STRINGS;
        searchVoicingsGeneric(0, chord_pcs, tuning, max_span, &options, &option_counts, &frets, out, out_fret_storage, out_cap, &count);
        if (count == out_cap or base_fret == max_fret) break;
    }

    return out[0..count];
}

pub fn generateVoicings(chord_pcs: pcs.PitchClassSet, tuning: Tuning, max_span: u5, out: []GuitarVoicing) []GuitarVoicing {
    var count: usize = 0;

    var base_fret: u5 = 0;
    while (base_fret <= MAX_FRET) : (base_fret += 1) {
        var options: [NUM_STRINGS][10]i8 = [_][10]i8{[_]i8{-1} ** 10} ** NUM_STRINGS;
        var option_counts: [NUM_STRINGS]u4 = [_]u4{0} ** NUM_STRINGS;

        buildStringOptions(chord_pcs, tuning, base_fret, max_span, &options, &option_counts);

        var frets: [NUM_STRINGS]i8 = [_]i8{-1} ** NUM_STRINGS;
        searchVoicings(0, chord_pcs, tuning, max_span, &options, &option_counts, &frets, out, &count);
        if (count == out.len) break;
    }

    return out[0..count];
}

pub fn cagedPositions(root_pc: pitch.PitchClass, quality: CAGEDQuality) [5]CAGEDPosition {
    _ = quality;

    var out: [5]CAGEDPosition = undefined;

    for (CAGED_MAJOR_SHAPES, 0..) |shape, i| {
        const shape_root_midi = tunings.STANDARD[shape.root_string] + shape.root_fret;
        const shape_root_pc = @as(pitch.PitchClass, @intCast(shape_root_midi % 12));
        const offset = @as(u5, @intCast((@as(u8, root_pc) + 12 - @as(u8, shape_root_pc)) % 12));

        var shifted: [NUM_STRINGS]i8 = undefined;
        for (shape.frets, 0..) |fret, string| {
            if (fret < 0) {
                shifted[string] = -1;
            } else if (fret == 0 and offset > 0) {
                shifted[string] = @as(i8, @intCast(offset));
            } else {
                shifted[string] = fret + @as(i8, @intCast(offset));
            }
        }

        out[i] = .{
            .shape = shape.shape,
            .frets = shifted,
            .position = offset,
            .root_string = shape.root_string,
        };
    }

    return out;
}

pub fn pitchClassGuideGeneric(selected_positions: []const GenericFretPosition, min_fret: u8, max_fret: u8, tuning: []const pitch.MidiNote, out: []GenericGuideDot) []GenericGuideDot {
    var selected_pcs: pcs.PitchClassSet = 0;
    for (selected_positions) |pos| {
        const pc = pos.toPitchClass(tuning) orelse continue;
        selected_pcs |= @as(pcs.PitchClassSet, 1) << pc;
    }

    var count: usize = 0;

    for (tuning, 0..) |_, string| {
        var fret: u8 = min_fret;
        while (fret <= max_fret) : (fret += 1) {
            if (isSelectedGeneric(selected_positions, string, fret)) continue;

            const midi = fretToMidiGeneric(string, fret, tuning) orelse continue;
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((selected_pcs & bit) == 0) continue;

            if (count >= out.len) return out[0..count];
            out[count] = .{
                .position = .{ .string = string, .fret = fret },
                .pitch_class = pc,
                .opacity = GUIDE_OPACITY,
            };
            count += 1;
        }
    }

    return out[0..count];
}

pub fn pitchClassGuide(selected_positions: []const FretPosition, min_fret: u5, max_fret: u5, tuning: Tuning, out: []GuideDot) []GuideDot {
    var selected_pcs: pcs.PitchClassSet = 0;
    for (selected_positions) |pos| {
        const pc = pos.toPitchClass(tuning);
        selected_pcs |= @as(pcs.PitchClassSet, 1) << pc;
    }

    var count: usize = 0;
    const hi = @min(max_fret, MAX_FRET);

    var string: u3 = 0;
    while (string < NUM_STRINGS) : (string += 1) {
        var fret: u5 = min_fret;
        while (fret <= hi) : (fret += 1) {
            if (isSelected(selected_positions, string, fret)) continue;

            const midi = fretToMidi(string, fret, tuning);
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((selected_pcs & bit) == 0) continue;

            if (count >= out.len) return out[0..count];
            out[count] = .{
                .position = .{ .string = string, .fret = fret },
                .pitch_class = pc,
                .opacity = GUIDE_OPACITY,
            };
            count += 1;
        }
    }

    return out[0..count];
}

pub fn fretsToUrlGeneric(frets: []const i8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();

    for (frets, 0..) |fret, i| {
        if (i > 0) writer.writeByte(',') catch unreachable;

        if (fret < 0) {
            writer.writeAll("-1") catch unreachable;
        } else {
            writer.print("{d}", .{fret}) catch unreachable;
        }
    }

    return buf[0..stream.pos];
}

pub fn fretsToUrl(voicing: GuitarVoicing, buf: *[64]u8) []u8 {
    return fretsToUrlGeneric(voicing.frets[0..], buf);
}

pub fn urlToFretsGeneric(url: []const u8, out: []i8) ?[]const i8 {
    var count: usize = 0;

    var it = std.mem.splitScalar(u8, url, ',');
    while (it.next()) |raw_token| {
        if (count >= out.len) return null;
        out[count] = parseFretToken(raw_token, std.math.maxInt(u8)) orelse return null;
        count += 1;
    }

    return out[0..count];
}

pub fn urlToFrets(url: []const u8, tuning: Tuning) ?GuitarVoicing {
    var frets: [NUM_STRINGS]i8 = undefined;
    const parsed = urlToFretsGeneric(url, &frets) orelse return null;
    if (parsed.len != NUM_STRINGS) return null;

    return .{
        .frets = frets,
        .tuning = tuning,
    };
}

fn buildStringOptions(chord_pcs: pcs.PitchClassSet, tuning: Tuning, base_fret: u5, max_span: u5, options: *[NUM_STRINGS][10]i8, option_counts: *[NUM_STRINGS]u4) void {
    const lo = if (base_fret > 0) base_fret else 0;
    const hi = @min(MAX_FRET, base_fret + max_span);

    var string: usize = 0;
    while (string < NUM_STRINGS) : (string += 1) {
        options[string][0] = -1;
        option_counts[string] = 1;

        var fret: u5 = lo;
        while (fret <= hi) : (fret += 1) {
            const midi = tuning[string] + fret;
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((chord_pcs & bit) == 0) continue;

            appendOption(options, option_counts, string, @as(i8, @intCast(fret)));
        }

        if (base_fret > 0) {
            const open_pc = @as(pitch.PitchClass, @intCast(tuning[string] % 12));
            const bit = @as(pcs.PitchClassSet, 1) << open_pc;
            if ((chord_pcs & bit) != 0) {
                appendOption(options, option_counts, string, 0);
            }
        }
    }
}

fn buildStringOptionsGeneric(chord_pcs: pcs.PitchClassSet, tuning: []const pitch.MidiNote, max_fret: u8, base_fret: u8, max_span: u8, options: *[MAX_GENERIC_STRINGS][MAX_OPTIONS_PER_STRING]i8, option_counts: *[MAX_GENERIC_STRINGS]u8) void {
    const lo: u8 = if (base_fret > 0) base_fret else 0;
    const hi: u8 = @min(max_fret, base_fret + max_span);

    var string: usize = 0;
    while (string < tuning.len) : (string += 1) {
        options[string][0] = -1;
        option_counts[string] = 1;

        var fret: u8 = lo;
        while (fret <= hi) : (fret += 1) {
            const midi = fretToMidiGeneric(string, fret, tuning) orelse continue;
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((chord_pcs & bit) == 0) continue;

            appendOptionGeneric(options, option_counts, string, @as(i8, @intCast(fret)));
            if (fret == hi) break;
        }

        if (base_fret > 0) {
            const open_pc = @as(pitch.PitchClass, @intCast(tuning[string] % 12));
            const bit = @as(pcs.PitchClassSet, 1) << open_pc;
            if ((chord_pcs & bit) != 0) {
                appendOptionGeneric(options, option_counts, string, 0);
            }
        }
    }
}

fn appendOption(options: *[NUM_STRINGS][10]i8, option_counts: *[NUM_STRINGS]u4, string: usize, fret: i8) void {
    var i: usize = 0;
    while (i < option_counts[string]) : (i += 1) {
        if (options[string][i] == fret) return;
    }

    const count = option_counts[string];
    if (count >= 10) return;

    options[string][count] = fret;
    option_counts[string] += 1;
}

fn appendOptionGeneric(options: *[MAX_GENERIC_STRINGS][MAX_OPTIONS_PER_STRING]i8, option_counts: *[MAX_GENERIC_STRINGS]u8, string: usize, fret: i8) void {
    var i: usize = 0;
    while (i < option_counts[string]) : (i += 1) {
        if (options[string][i] == fret) return;
    }

    const count = option_counts[string];
    if (count >= MAX_OPTIONS_PER_STRING) return;

    options[string][count] = fret;
    option_counts[string] += 1;
}

fn searchVoicings(string_index: usize, chord_pcs: pcs.PitchClassSet, tuning: Tuning, max_span: u5, options: *const [NUM_STRINGS][10]i8, option_counts: *const [NUM_STRINGS]u4, frets: *[NUM_STRINGS]i8, out: []GuitarVoicing, out_count: *usize) void {
    if (out_count.* >= out.len) return;

    if (string_index == NUM_STRINGS) {
        const voicing = GuitarVoicing{ .frets = frets.*, .tuning = tuning };
        if (!isPlayable(voicing, chord_pcs, max_span)) return;
        if (containsVoicing(out[0..out_count.*], voicing.frets)) return;

        out[out_count.*] = voicing;
        out_count.* += 1;
        return;
    }

    var i: usize = 0;
    while (i < option_counts[string_index]) : (i += 1) {
        frets[string_index] = options[string_index][i];
        searchVoicings(string_index + 1, chord_pcs, tuning, max_span, options, option_counts, frets, out, out_count);
        if (out_count.* >= out.len) return;
    }
}

fn searchVoicingsGeneric(string_index: usize, chord_pcs: pcs.PitchClassSet, tuning: []const pitch.MidiNote, max_span: u8, options: *const [MAX_GENERIC_STRINGS][MAX_OPTIONS_PER_STRING]i8, option_counts: *const [MAX_GENERIC_STRINGS]u8, frets: *[MAX_GENERIC_STRINGS]i8, out: []GenericVoicing, out_fret_storage: []i8, out_cap: usize, out_count: *usize) void {
    if (out_count.* >= out_cap) return;

    if (string_index == tuning.len) {
        const fret_slice = frets[0..tuning.len];
        const voicing = GenericVoicing{ .frets = fret_slice, .tuning = tuning };
        if (!isPlayableGeneric(voicing, chord_pcs, max_span)) return;
        if (containsVoicingGeneric(out[0..out_count.*], fret_slice)) return;

        const storage_offset = out_count.* * tuning.len;
        const target = out_fret_storage[storage_offset .. storage_offset + tuning.len];
        std.mem.copyForwards(i8, target, fret_slice);
        out[out_count.*] = .{
            .frets = target,
            .tuning = tuning,
        };
        out_count.* += 1;
        return;
    }

    var i: usize = 0;
    while (i < option_counts[string_index]) : (i += 1) {
        frets[string_index] = options[string_index][i];
        searchVoicingsGeneric(string_index + 1, chord_pcs, tuning, max_span, options, option_counts, frets, out, out_fret_storage, out_cap, out_count);
        if (out_count.* >= out_cap) return;
    }
}

fn isPlayable(voicing: GuitarVoicing, chord_pcs: pcs.PitchClassSet, max_span: u5) bool {
    var sounding: u4 = 0;
    var voiced_pcs: pcs.PitchClassSet = 0;

    for (voicing.frets, 0..) |fret, string| {
        if (fret < 0) continue;
        sounding += 1;

        const midi = voicing.tuning[string] + @as(pitch.MidiNote, @intCast(fret));
        const pc = @as(pitch.PitchClass, @intCast(midi % 12));
        voiced_pcs |= @as(pcs.PitchClassSet, 1) << pc;
    }

    if (sounding < 3) return false;
    if (!pcs.isSubsetOf(chord_pcs, voiced_pcs)) return false;
    if (voicing.handSpan() > max_span) return false;

    return true;
}

fn isPlayableGeneric(voicing: GenericVoicing, chord_pcs: pcs.PitchClassSet, max_span: u8) bool {
    var sounding: usize = 0;
    var voiced_pcs: pcs.PitchClassSet = 0;

    for (voicing.frets, 0..) |fret, string| {
        if (fret < 0) continue;
        sounding += 1;

        const midi = fretToMidiGeneric(string, @as(u8, @intCast(fret)), voicing.tuning) orelse continue;
        const pc = @as(pitch.PitchClass, @intCast(midi % 12));
        voiced_pcs |= @as(pcs.PitchClassSet, 1) << pc;
    }

    const required_sounding = @min(voicing.tuning.len, pcs.cardinality(chord_pcs));
    if (sounding < required_sounding) return false;
    if (!pcs.isSubsetOf(chord_pcs, voiced_pcs)) return false;
    if (voicing.handSpan() > max_span) return false;

    return true;
}

fn containsVoicing(existing: []const GuitarVoicing, frets: [NUM_STRINGS]i8) bool {
    for (existing) |one| {
        if (std.mem.eql(i8, &one.frets, &frets)) return true;
    }
    return false;
}

fn containsVoicingGeneric(existing: []const GenericVoicing, frets: []const i8) bool {
    for (existing) |one| {
        if (one.frets.len != frets.len) continue;
        if (std.mem.eql(i8, one.frets, frets)) return true;
    }
    return false;
}

fn isSelected(selected_positions: []const FretPosition, string: u3, fret: u5) bool {
    for (selected_positions) |one| {
        if (one.string == string and one.fret == fret) return true;
    }
    return false;
}

fn isSelectedGeneric(selected_positions: []const GenericFretPosition, string: usize, fret: u8) bool {
    for (selected_positions) |one| {
        if (one.string == string and one.fret == fret) return true;
    }
    return false;
}

fn parseFretToken(raw_token: []const u8, max_fret: u8) ?i8 {
    const token = std.mem.trim(u8, raw_token, " \t\n\r");
    if (token.len == 0) return null;

    var split = std.mem.splitScalar(u8, token, '_');
    const first = split.first();

    if (std.mem.eql(u8, first, "x") or std.mem.eql(u8, first, "X") or std.mem.eql(u8, first, "-1")) {
        return -1;
    }

    const fret = std.fmt.parseInt(i8, first, 10) catch return null;
    if (fret < 0 or fret > max_fret) return null;
    return fret;
}
