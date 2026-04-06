const testing = @import("std").testing;

const ordered_scale = @import("../ordered_scale.zig");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");

test "barry harris patterns stay ordered-scale-only 8-note inventories" {
    try testing.expectEqual(@as(usize, 12), ordered_scale.count());
    try testing.expect(ordered_scale.isBarryHarris(.barry_harris_major_sixth_diminished));
    try testing.expect(ordered_scale.isBarryHarris(.barry_harris_minor_sixth_diminished));
    try testing.expectEqual(
        pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 8, 9, 11 }),
        ordered_scale.rootedPitchClassSet(.barry_harris_major_sixth_diminished, 0),
    );
    try testing.expectEqual(
        pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 8, 9, 11 }),
        ordered_scale.rootedPitchClassSet(.barry_harris_minor_sixth_diminished, 0),
    );
}

test "barry harris parity alternates chord tones and passing tones" {
    const c = ordered_scale.barryHarrisParity(.barry_harris_major_sixth_diminished, 0, 60).?;
    try testing.expectEqual(@as(u8, 0), c.degree);
    try testing.expectEqual(ordered_scale.BarryHarrisParityKind.chord_tone, c.kind);

    const d = ordered_scale.barryHarrisParity(.barry_harris_major_sixth_diminished, 0, 62).?;
    try testing.expectEqual(@as(u8, 1), d.degree);
    try testing.expectEqual(ordered_scale.BarryHarrisParityKind.passing_tone, d.kind);

    const a_flat = ordered_scale.barryHarrisParity(.barry_harris_major_sixth_diminished, 0, 68).?;
    try testing.expectEqual(@as(u8, 5), a_flat.degree);
    try testing.expectEqual(ordered_scale.BarryHarrisParityKind.passing_tone, a_flat.kind);

    try testing.expect(ordered_scale.barryHarrisParity(.diatonic, 0, 60) == null);
    try testing.expect(ordered_scale.barryHarrisParity(.barry_harris_major_sixth_diminished, 0, 61) == null);
}
