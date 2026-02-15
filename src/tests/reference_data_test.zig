const testing = @import("std").testing;

const pcs = @import("../pitch_class_set.zig");
const forte = @import("../forte.zig");
const set_class = @import("../set_class.zig");
const interval_vector = @import("../interval_vector.zig");
const chord = @import("../chord_construction.zig");
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
    try testing.expectEqual(@as(u16, 455), stats.mode_subset_count);
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
