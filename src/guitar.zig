const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");

pub const NUM_STRINGS: usize = 6;
pub const MAX_FRET: u5 = 24;
pub const GUIDE_OPACITY: f32 = 0.35;

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
    std.debug.assert(string < NUM_STRINGS);
    return tuning[string] + fret;
}

pub fn midiToFretPositions(note: pitch.MidiNote, tuning: Tuning, out: *[NUM_STRINGS]FretPosition) []FretPosition {
    var count: usize = 0;
    for (tuning, 0..) |open_note, string| {
        if (note < open_note) continue;
        const fret = note - open_note;
        if (fret > MAX_FRET) continue;

        out[count] = .{
            .string = @as(u3, @intCast(string)),
            .fret = @as(u5, @intCast(fret)),
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

pub fn fretsToUrl(voicing: GuitarVoicing, buf: *[64]u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();

    for (voicing.frets, 0..) |fret, i| {
        if (i > 0) writer.writeByte(',') catch unreachable;

        if (fret < 0) {
            writer.writeAll("-1") catch unreachable;
        } else {
            writer.print("{d}", .{fret}) catch unreachable;
        }
    }

    return buf[0..stream.pos];
}

pub fn urlToFrets(url: []const u8, tuning: Tuning) ?GuitarVoicing {
    var frets: [NUM_STRINGS]i8 = undefined;
    var count: usize = 0;

    var it = std.mem.splitScalar(u8, url, ',');
    while (it.next()) |raw_token| {
        if (count >= NUM_STRINGS) return null;
        frets[count] = parseFretToken(raw_token) orelse return null;
        count += 1;
    }

    if (count != NUM_STRINGS) return null;

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

fn containsVoicing(existing: []const GuitarVoicing, frets: [NUM_STRINGS]i8) bool {
    for (existing) |one| {
        if (std.mem.eql(i8, &one.frets, &frets)) return true;
    }
    return false;
}

fn isSelected(selected_positions: []const FretPosition, string: u3, fret: u5) bool {
    for (selected_positions) |one| {
        if (one.string == string and one.fret == fret) return true;
    }
    return false;
}

fn parseFretToken(raw_token: []const u8) ?i8 {
    const token = std.mem.trim(u8, raw_token, " \t\n\r");
    if (token.len == 0) return null;

    var split = std.mem.splitScalar(u8, token, '_');
    const first = split.first();

    if (std.mem.eql(u8, first, "x") or std.mem.eql(u8, first, "X") or std.mem.eql(u8, first, "-1")) {
        return -1;
    }

    const fret = std.fmt.parseInt(i8, first, 10) catch return null;
    if (fret < 0 or fret > MAX_FRET) return null;
    return fret;
}
