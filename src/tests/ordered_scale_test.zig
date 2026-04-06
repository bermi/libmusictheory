const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const ordered_scale = @import("../ordered_scale.zig");

fn expectOffsets(expected: []const pitch.PitchClass, actual: []const pitch.PitchClass) !void {
    try testing.expectEqual(expected.len, actual.len);
    try testing.expectEqualSlices(pitch.PitchClass, expected, actual);
}

test "ordered scale base patterns match rooted pitch-class facts" {
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 9, 11 }), ordered_scale.info(.diatonic).pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 9, 11 }), ordered_scale.info(.melodic_minor).pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 8, 11 }), ordered_scale.info(.harmonic_minor).pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 4, 5, 7, 8, 11 }), ordered_scale.info(.double_harmonic).pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 6, 7, 8, 11 }), ordered_scale.info(.hungarian_minor).pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 4, 6, 8, 10, 11 }), ordered_scale.info(.enigmatic).pcs);
}

test "ordered scale mode rotation derives harmonic minor family members" {
    var offsets_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;

    const phrygian_dominant_offsets = ordered_scale.modeOffsets(.harmonic_minor, 4, &offsets_buf);
    try expectOffsets(&[_]pitch.PitchClass{ 0, 1, 4, 5, 7, 8, 10 }, phrygian_dominant_offsets);
    try testing.expectEqual(pcs.fromList(phrygian_dominant_offsets), ordered_scale.modePitchClassSet(.harmonic_minor, 4));

    const lydian_sharp2_offsets = ordered_scale.modeOffsets(.harmonic_minor, 5, &offsets_buf);
    try expectOffsets(&[_]pitch.PitchClass{ 0, 3, 4, 6, 7, 9, 11 }, lydian_sharp2_offsets);
    try testing.expectEqual(pcs.fromList(lydian_sharp2_offsets), ordered_scale.modePitchClassSet(.harmonic_minor, 5));
}

test "ordered scale supports non-heptatonic parent patterns" {
    try testing.expectEqual(@as(u4, 8), ordered_scale.info(.diminished).degree_count);
    try testing.expectEqual(@as(u4, 6), ordered_scale.info(.whole_tone).degree_count);
    try testing.expectEqual(@as(u4, 8), ordered_scale.info(.barry_harris_major_sixth_diminished).degree_count);
    try testing.expectEqual(@as(u4, 8), ordered_scale.info(.barry_harris_minor_sixth_diminished).degree_count);
}
