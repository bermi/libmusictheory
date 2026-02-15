const std = @import("std");
const testing = std.testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");

test "list round trip" {
    const input = [_]pitch.PitchClass{ 0, 2, 4, 7, 9 };
    const set = pcs.fromList(&input);

    var out_buf: [12]pitch.PitchClass = undefined;
    const out = pcs.toList(set, &out_buf);

    try testing.expectEqualSlices(pitch.PitchClass, &input, out);
}

test "cardinality matches list length" {
    const input = [_]pitch.PitchClass{ 0, 3, 7 };
    const set = pcs.fromList(&input);
    try testing.expectEqual(@as(u4, 3), pcs.cardinality(set));
}

test "transposition up and down" {
    const up7 = pcs.transpose(pcs.C_MAJOR_TRIAD, 7);
    const g_major = pcs.fromList(&[_]pitch.PitchClass{ 2, 7, 11 });
    try testing.expectEqual(g_major, up7);

    const back_down = pcs.transposeDown(up7, 7);
    try testing.expectEqual(pcs.C_MAJOR_TRIAD, back_down);
}

test "complement and subset relationships" {
    try testing.expectEqual(pcs.PENTATONIC, pcs.complement(pcs.DIATONIC));
    try testing.expect(pcs.isSubsetOf(pcs.C_MAJOR_TRIAD, pcs.DIATONIC));
}

test "union and intersection" {
    const major = pcs.C_MAJOR_TRIAD;
    const minor = pcs.C_MINOR_TRIAD;

    const i = pcs.intersection(major, minor);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 7 }), i);

    const u = pcs.union_(major, minor);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 4, 7 }), u);
}

test "hamming distance major minor" {
    try testing.expectEqual(@as(u4, 2), pcs.hammingDistance(pcs.C_MAJOR_TRIAD, pcs.C_MINOR_TRIAD));
}

test "inversion produces transposed minor triad class" {
    const inverted = pcs.invert(pcs.C_MAJOR_TRIAD);
    const rotations = pcs.allRotations(inverted);

    var found = false;
    for (rotations) |candidate| {
        if (candidate == pcs.C_MINOR_TRIAD) {
            found = true;
            break;
        }
    }

    try testing.expect(found);
}

test "all 12 diatonic rotations are distinct" {
    const rots = pcs.allRotations(pcs.DIATONIC);

    var seen = [_]bool{false} ** 4096;
    for (rots) |r| {
        try testing.expect(!seen[r]);
        seen[r] = true;
    }
}

test "hasSub and leastError" {
    try testing.expect(pcs.hasSub(pcs.C_MAJOR_TRIAD, pcs.DIATONIC));

    const candidates = [_]pcs.PitchClassSet{
        pcs.C_MINOR_TRIAD,
        pcs.C_MAJOR_TRIAD,
        pcs.C_MAJOR_PENTATONIC,
    };
    const best = pcs.leastError(&candidates, pcs.C_MAJOR_TRIAD);
    try testing.expectEqual(pcs.C_MAJOR_TRIAD, best);
}

test "format uses set-theory digits" {
    var buf: [12]u8 = undefined;
    const text = pcs.format(pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 10, 11 }), &buf);
    try testing.expectEqualStrings("02te", text);
}
