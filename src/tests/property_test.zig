const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const interval_analysis = @import("../interval_analysis.zig");
const fc_components = @import("../fc_components.zig");

test "properties hold for all 4096 pitch-class sets" {
    var dec: u16 = 0;
    while (dec < 4096) : (dec += 1) {
        const set = @as(pcs.PitchClassSet, @intCast(dec));

        try testing.expectEqual(set, pcs.invert(pcs.invert(set)));
        try testing.expectEqual(set, interval_analysis.m5Transform(interval_analysis.m5Transform(set)));

        var cycled = set;
        var i: u4 = 0;
        while (i < 12) : (i += 1) {
            cycled = pcs.transpose(cycled, 1);
        }
        try testing.expectEqual(set, cycled);

        const prime = set_class.primeForm(set);
        try testing.expectEqual(prime, set_class.primeForm(prime));

        const card = pcs.cardinality(set);
        const comp_card = pcs.cardinality(pcs.complement(set));
        try testing.expectEqual(@as(u4, @intCast(12 - card)), comp_card);

        const fc = fc_components.compute(set);
        const comp_fc = fc_components.compute(pcs.complement(set));
        var k: usize = 0;
        while (k < 6) : (k += 1) {
            try testing.expectApproxEqAbs(fc[k], comp_fc[k], 0.0001);
        }
    }
}

test "fuzzed random inputs do not panic and preserve invariants" {
    var prng = std.Random.DefaultPrng.init(0x0022_0002);
    const random = prng.random();

    var i: usize = 0;
    while (i < 10_000) : (i += 1) {
        const raw = random.int(u16) & 0x0fff;
        const set = @as(pcs.PitchClassSet, @intCast(raw));

        var list_buf: [12]u4 = undefined;
        _ = pcs.toList(set, &list_buf);
        _ = set_class.fortePrime(set);
        _ = interval_analysis.isZRelated(set, pcs.transpose(set, @as(u4, @intCast(random.int(u8) % 12))));

        // Invariance sanity checks under random transposition/inversion chains.
        const t = @as(u4, @intCast(random.int(u8) % 12));
        const transformed = pcs.invert(pcs.transpose(set, t));
        try testing.expectEqual(pcs.cardinality(set), pcs.cardinality(transformed));
    }
}
