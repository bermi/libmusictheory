const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");

pub const MAX_DEGREES: usize = 8;

pub const Family = enum {
    diatonic,
    melodic_minor,
    harmonic_minor,
    diminished,
    whole_tone,
    exotic,
};

pub const PatternId = enum {
    diatonic,
    melodic_minor,
    harmonic_minor,
    diminished,
    whole_tone,
    double_harmonic,
    hungarian_minor,
    enigmatic,
    neapolitan_minor,
    neapolitan_major,
};

pub const OrderedScaleInfo = struct {
    id: PatternId,
    name: []const u8,
    family: Family,
    degree_count: u4,
    offsets: [MAX_DEGREES]pitch.PitchClass,
    pcs: pcs.PitchClassSet,

    pub fn slice(self: *const OrderedScaleInfo) []const pitch.PitchClass {
        return self.offsets[0..self.degree_count];
    }
};

pub const SnapTiePolicy = enum(u8) {
    lower,
    higher,
};

pub const ScaleNeighborTones = struct {
    in_scale: bool = false,
    has_lower: bool = false,
    has_upper: bool = false,
    lower: pitch.MidiNote = 0,
    upper: pitch.MidiNote = 0,
    lower_distance: u8 = 0,
    upper_distance: u8 = 0,
};

pub const ALL_PATTERNS = [_]OrderedScaleInfo{
    makePattern(.diatonic, "Diatonic", .diatonic, &[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 9, 11 }),
    makePattern(.melodic_minor, "Melodic Minor", .melodic_minor, &[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 9, 11 }),
    makePattern(.harmonic_minor, "Harmonic Minor", .harmonic_minor, &[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 8, 11 }),
    makePattern(.diminished, "Diminished", .diminished, &[_]pitch.PitchClass{ 0, 1, 3, 4, 6, 7, 9, 10 }),
    makePattern(.whole_tone, "Whole-Tone", .whole_tone, &[_]pitch.PitchClass{ 0, 2, 4, 6, 8, 10 }),
    makePattern(.double_harmonic, "Double Harmonic", .exotic, &[_]pitch.PitchClass{ 0, 1, 4, 5, 7, 8, 11 }),
    makePattern(.hungarian_minor, "Hungarian Minor", .exotic, &[_]pitch.PitchClass{ 0, 2, 3, 6, 7, 8, 11 }),
    makePattern(.enigmatic, "Enigmatic", .exotic, &[_]pitch.PitchClass{ 0, 1, 4, 6, 8, 10, 11 }),
    makePattern(.neapolitan_minor, "Neapolitan Minor", .exotic, &[_]pitch.PitchClass{ 0, 1, 3, 5, 7, 8, 11 }),
    makePattern(.neapolitan_major, "Neapolitan Major", .exotic, &[_]pitch.PitchClass{ 0, 1, 3, 5, 7, 9, 11 }),
};

pub fn info(id: PatternId) *const OrderedScaleInfo {
    return &ALL_PATTERNS[@intFromEnum(id)];
}

pub fn offsetsFor(id: PatternId) []const pitch.PitchClass {
    return info(id).slice();
}

pub fn modePitchClassSet(id: PatternId, degree: u4) pcs.PitchClassSet {
    const pattern = info(id);
    std.debug.assert(degree < pattern.degree_count);
    return pcs.transposeDown(pattern.pcs, pattern.offsets[degree]);
}

pub fn modeOffsets(id: PatternId, degree: u4, out: *[MAX_DEGREES]pitch.PitchClass) []pitch.PitchClass {
    const pattern = info(id);
    const base = pattern.slice();
    std.debug.assert(degree < pattern.degree_count);

    const root_pc = base[degree];
    var index: usize = 0;
    while (index < base.len) : (index += 1) {
        const source = base[(index + degree) % base.len];
        out[index] = pitch.wrapPitchClass(@as(i16, @intCast(source)) - @as(i16, @intCast(root_pc)));
    }
    return out[0..base.len];
}

pub fn degreeIndexForOffsets(offsets: []const pitch.PitchClass, tonic: pitch.PitchClass, note: pitch.MidiNote) ?u8 {
    const relative = pitch.wrapPitchClass(@as(i16, @intCast(pitch.midiToPC(note))) - @as(i16, @intCast(tonic)));
    for (offsets, 0..) |offset, index| {
        if (offset == relative) return @as(u8, @intCast(index));
    }
    return null;
}

pub fn transposeMidiByDegrees(
    offsets: []const pitch.PitchClass,
    tonic: pitch.PitchClass,
    note: pitch.MidiNote,
    degrees: i8,
) ?pitch.MidiNote {
    const current_degree = degreeIndexForOffsets(offsets, tonic, note) orelse return null;
    const total_degrees = @as(i16, current_degree) + @as(i16, degrees);
    const len = @as(i16, @intCast(offsets.len));
    const octave_shift = @divFloor(total_degrees, len);
    const new_degree = @mod(total_degrees, len);

    const current_offset = @as(i16, @intCast(offsets[current_degree]));
    const new_offset = @as(i16, @intCast(offsets[@as(usize, @intCast(new_degree))]));
    const semitone_diff = (new_offset - current_offset) + (octave_shift * 12);
    const new_midi = @as(i16, note) + semitone_diff;
    if (new_midi < 0 or new_midi > 127) return null;
    return @as(pitch.MidiNote, @intCast(new_midi));
}

pub fn nearestScaleNeighbors(
    offsets: []const pitch.PitchClass,
    tonic: pitch.PitchClass,
    note: pitch.MidiNote,
) ScaleNeighborTones {
    if (degreeIndexForOffsets(offsets, tonic, note) != null) {
        return .{
            .in_scale = true,
            .has_lower = true,
            .has_upper = true,
            .lower = note,
            .upper = note,
            .lower_distance = 0,
            .upper_distance = 0,
        };
    }

    var out = ScaleNeighborTones{};
    var delta: u8 = 1;
    while (delta <= 12 and (!out.has_lower or !out.has_upper)) : (delta += 1) {
        if (!out.has_lower and note >= delta) {
            const lower = @as(pitch.MidiNote, @intCast(note - delta));
            if (degreeIndexForOffsets(offsets, tonic, lower) != null) {
                out.has_lower = true;
                out.lower = lower;
                out.lower_distance = delta;
            }
        }
        if (!out.has_upper and note <= 127 - delta) {
            const upper = @as(pitch.MidiNote, @intCast(note + delta));
            if (degreeIndexForOffsets(offsets, tonic, upper) != null) {
                out.has_upper = true;
                out.upper = upper;
                out.upper_distance = delta;
            }
        }
    }
    return out;
}

pub fn snapToScale(
    offsets: []const pitch.PitchClass,
    tonic: pitch.PitchClass,
    note: pitch.MidiNote,
    policy: SnapTiePolicy,
) ?pitch.MidiNote {
    const neighbors = nearestScaleNeighbors(offsets, tonic, note);
    if (neighbors.in_scale) return note;
    if (neighbors.has_lower and neighbors.has_upper) {
        if (neighbors.lower_distance < neighbors.upper_distance) return neighbors.lower;
        if (neighbors.upper_distance < neighbors.lower_distance) return neighbors.upper;
        return switch (policy) {
            .lower => neighbors.lower,
            .higher => neighbors.upper,
        };
    }
    if (neighbors.has_lower) return neighbors.lower;
    if (neighbors.has_upper) return neighbors.upper;
    return null;
}

fn makePattern(
    comptime id: PatternId,
    comptime name: []const u8,
    comptime family: Family,
    comptime source_offsets: []const pitch.PitchClass,
) OrderedScaleInfo {
    std.debug.assert(source_offsets.len <= MAX_DEGREES);
    var offsets = [_]pitch.PitchClass{0} ** MAX_DEGREES;
    for (source_offsets, 0..) |offset, index| {
        offsets[index] = offset;
    }
    return .{
        .id = id,
        .name = name,
        .family = family,
        .degree_count = @as(u4, @intCast(source_offsets.len)),
        .offsets = offsets,
        .pcs = pcs.fromList(source_offsets),
    };
}
