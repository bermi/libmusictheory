const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");

test "enumeration counts" {
    try testing.expectEqual(@as(usize, 336), set_class.SET_CLASSES.len);
    try testing.expectEqual(@as(u16, 208), set_class.countOpticClasses());
    try testing.expectEqual(@as(u16, 114), set_class.countOpticKGroups());
}

test "known prime forms" {
    try testing.expectEqual(@as(pcs.PitchClassSet, 0b000010010001), set_class.primeForm(pcs.C_MAJOR_TRIAD));
    try testing.expectEqual(@as(pcs.PitchClassSet, 0b010101101011), set_class.primeForm(pcs.DIATONIC));
}

test "known forte numbers" {
    const triad = set_class.fortePrime(pcs.C_MAJOR_TRIAD);
    const triad_forte = @import("../forte.zig").lookup(triad) orelse unreachable;
    try testing.expectEqual(@as(u4, 3), triad_forte.cardinality);
    try testing.expectEqual(@as(u8, 11), triad_forte.ordinal);
    try testing.expectEqual(false, triad_forte.is_z);

    const diatonic_forte = @import("../forte.zig").lookup(set_class.fortePrime(pcs.DIATONIC)) orelse unreachable;
    try testing.expectEqual(@as(u4, 7), diatonic_forte.cardinality);
    try testing.expectEqual(@as(u8, 35), diatonic_forte.ordinal);
}

test "symmetry and limited transposition" {
    try testing.expect(set_class.isSymmetric(pcs.DIATONIC));

    const whole_tone = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 6, 8, 10 });
    const diminished_seventh = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 9 });
    const augmented = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });

    try testing.expectEqual(@as(u4, 2), set_class.numTranspositions(whole_tone));
    try testing.expectEqual(@as(u4, 3), set_class.numTranspositions(diminished_seventh));
    try testing.expectEqual(@as(u4, 4), set_class.numTranspositions(augmented));

    try testing.expect(set_class.isLimitedTransposition(whole_tone));
    try testing.expect(set_class.isLimitedTransposition(diminished_seventh));
    try testing.expect(set_class.isLimitedTransposition(augmented));
}

test "all set classes map to known forte numbers" {
    for (set_class.SET_CLASSES) |sc| {
        try testing.expect(sc.forte_number.ordinal != 0);
    }
}
