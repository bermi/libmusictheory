const testing = @import("std").testing;

const pcs = @import("../pitch_class_set.zig");
const forte = @import("../forte.zig");
const set_class = @import("../set_class.zig");
const interval_vector = @import("../interval_vector.zig");
const chord = @import("../chord_construction.zig");
const chord_detection = @import("../chord_detection.zig");
const mode = @import("../mode.zig");
const tables = @import("../tables.zig");

test "music21 spot check: major/minor triad set class and interval vector" {
    const triad_prime = set_class.fortePrime(pcs.C_MAJOR_TRIAD);
    const triad_forte = forte.lookup(triad_prime) orelse unreachable;

    try testing.expectEqual(@as(u4, 3), triad_forte.cardinality);
    try testing.expectEqual(@as(u8, 11), triad_forte.ordinal);
    try testing.expectEqual(@as([6]u8, .{ 0, 0, 1, 1, 1, 0 }), interval_vector.compute(triad_prime));
}

test "harmoniousapp spot check: cluster-free class count" {
    try testing.expectEqual(@as(usize, 124), tables.classification.CLUSTER_FREE_INDICES.len);
}

test "the game spot check: otc and subset counts" {
    const stats = chord.computeGameStats();
    try testing.expectEqual(@as(u16, 2048), stats.otc_count);
    try testing.expectEqual(@as(u16, 560), stats.cluster_free_count);
    try testing.expectEqual(@as(u16, 545), stats.mode_subset_count);
}

test "set class cardinality bounds match published domain" {
    for (set_class.SET_CLASSES) |sc| {
        try testing.expect(sc.cardinality >= 3);
        try testing.expect(sc.cardinality <= 9);
    }

    // Common reference anchor: C major set class is present.
    const c_major_prime = set_class.primeForm(pcs.C_MAJOR_TRIAD);
    var found = false;
    for (set_class.SET_CLASSES) |sc| {
        if (sc.pcs == c_major_prime) {
            found = true;
            break;
        }
    }
    try testing.expect(found);
}

test "tonal-ts spot check: expanded mode inventory matches textbook interval facts" {
    try testing.expectEqual(pcs.fromList(&[_]u4{ 0, 2, 3, 5, 7, 8, 11 }), mode.info(.harmonic_minor).pcs);
    try testing.expectEqual(pcs.fromList(&[_]u4{ 0, 1, 4, 5, 7, 8, 10 }), mode.info(.phrygian_dominant).pcs);
    try testing.expectEqual(pcs.fromList(&[_]u4{ 0, 1, 4, 5, 7, 8, 11 }), mode.info(.double_harmonic).pcs);
    try testing.expectEqual(pcs.fromList(&[_]u4{ 0, 2, 3, 6, 7, 8, 11 }), mode.info(.hungarian_minor).pcs);
    try testing.expectEqual(pcs.fromList(&[_]u4{ 0, 1, 4, 6, 8, 10, 11 }), mode.info(.enigmatic).pcs);
}

test "tonal-ts spot check: structured chord patterns match published interval facts" {
    try testing.expectEqual(chord.formulaToPCS("1 3 5 7"), chord_detection.pattern(.maj7).pcs);
    try testing.expectEqual(chord.formulaToPCS("1 3 5 b7 9 13"), chord_detection.pattern(.dominant13).pcs);
    try testing.expectEqual(chord.formulaToPCS("1 b3 b5 b7"), chord_detection.pattern(.min7_flat5).pcs);
    try testing.expectEqual(chord.formulaToPCS("1 4 5"), chord_detection.pattern(.sus4).pcs);
}
