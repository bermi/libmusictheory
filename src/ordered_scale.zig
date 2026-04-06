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
