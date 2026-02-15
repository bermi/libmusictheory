const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const scale = @import("../scale.zig");
const mode = @import("../mode.zig");

test "all 17 modes are defined and identifiable" {
    try testing.expectEqual(@as(usize, 17), mode.ALL_MODES.len);

    for (mode.ALL_MODES) |m| {
        const identified = mode.identifyMode(m.pcs);
        try testing.expect(identified != null);
        try testing.expectEqual(m.id, identified.?);
    }
}

test "mode identification round-trip from scale construction" {
    const diatonic_c = scale.Scale.init(.diatonic, pitch.pc.C);

    var found: usize = 0;
    var seen = [_]bool{false} ** @typeInfo(mode.ModeType).@"enum".fields.len;

    var degree: u4 = 0;
    while (degree < 7) : (degree += 1) {
        const built = diatonic_c.mode(degree);
        const identified = mode.identifyMode(built.pcs) orelse return error.TestExpectedEqual;
        seen[@intFromEnum(identified)] = true;
        found += 1;
    }

    try testing.expectEqual(@as(usize, 7), found);
    try testing.expect(seen[@intFromEnum(mode.ModeType.ionian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.dorian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.phrygian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.lydian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.mixolydian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.aeolian)]);
    try testing.expect(seen[@intFromEnum(mode.ModeType.locrian)]);
}

test "scale type identification" {
    try testing.expectEqual(scale.ScaleType.diatonic, scale.identifyScaleType(scale.DIATONIC).?);
    try testing.expectEqual(scale.ScaleType.acoustic, scale.identifyScaleType(scale.ACOUSTIC).?);
    try testing.expectEqual(scale.ScaleType.whole_tone, scale.identifyScaleType(scale.WHOLE_TONE).?);

    const unknown = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 6, 7 });
    try testing.expectEqual(@as(?scale.ScaleType, null), scale.identifyScaleType(unknown));
}

test "isScaley heuristic" {
    try testing.expect(scale.isScaley(scale.DIATONIC));
    try testing.expect(scale.isScaley(scale.WHOLE_TONE));
    try testing.expect(!scale.isScaley(pcs.C_MAJOR_TRIAD));
}
