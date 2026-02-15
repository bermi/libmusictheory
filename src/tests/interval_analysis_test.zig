const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const interval_vector = @import("../interval_vector.zig");
const fc_components = @import("../fc_components.zig");
const interval_analysis = @import("../interval_analysis.zig");
const interval_ref = @import("../interval_vector_reference.zig");

test "known interval vectors" {
    const major_iv = interval_vector.compute(pcs.C_MAJOR_TRIAD);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 1, 1, 1, 0 }, &major_iv);

    const diatonic_like = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 3, 5, 6, 8, 10 });
    const diatonic_iv = interval_vector.compute(diatonic_like);
    try testing.expectEqualSlices(u8, &[_]u8{ 2, 5, 4, 3, 6, 1 }, &diatonic_iv);
}

test "interval vectors match music21 for all 336 set classes" {
    for (set_class.SET_CLASSES) |sc| {
        const expected = interval_ref.lookup(sc.forte_number.cardinality, sc.forte_number.ordinal) orelse {
            return error.TestExpectedEqual;
        };
        const actual = interval_vector.compute(sc.pcs);
        try testing.expectEqualSlices(u8, expected[0..], actual[0..]);
    }
}

test "fc complement invariance" {
    const set = pcs.DIATONIC;
    const comp = pcs.complement(set);

    const lhs = fc_components.compute(set);
    const rhs = fc_components.compute(comp);

    for (lhs, rhs) |a, b| {
        try testing.expectApproxEqAbs(a, b, 0.00001);
    }
}

test "fc m-relation swaps fc1 and fc5" {
    const set = pcs.C_MAJOR_TRIAD;
    const m5 = interval_analysis.m5Transform(set);
    const lhs = fc_components.compute(set);
    const rhs = fc_components.compute(m5);

    try testing.expectApproxEqAbs(lhs[0], rhs[4], 0.00001);
    try testing.expectApproxEqAbs(lhs[4], rhs[0], 0.00001);
    try testing.expectApproxEqAbs(lhs[1], rhs[1], 0.00001);
    try testing.expectApproxEqAbs(lhs[2], rhs[2], 0.00001);
    try testing.expectApproxEqAbs(lhs[3], rhs[3], 0.00001);
    try testing.expectApproxEqAbs(lhs[5], rhs[5], 0.00001);
}

test "z-related pairs" {
    const z_4_15 = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 4, 6 });
    const z_4_29 = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 3, 7 });

    try testing.expect(interval_analysis.isZRelated(z_4_15, z_4_29));
    try testing.expect(!interval_analysis.isZRelated(pcs.C_MAJOR_TRIAD, pcs.C_MINOR_TRIAD));
}

test "m transforms and m relation" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 7, 9 });

    const m5_once = interval_analysis.m5Transform(set);
    const m5_twice = interval_analysis.m5Transform(m5_once);
    try testing.expectEqual(set, m5_twice);

    const m7_once = interval_analysis.m7Transform(set);
    const m7_twice = interval_analysis.m7Transform(m7_once);
    try testing.expectEqual(set, m7_twice);

    try testing.expect(interval_analysis.isMRelated(set, m5_once));
    try testing.expect(interval_analysis.isMRelated(set, m7_once));
    try testing.expect(!interval_analysis.isMRelated(set, pcs.C_MAJOR_TRIAD));
}
