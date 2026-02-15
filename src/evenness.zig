const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const interval_vector = @import("interval_vector.zig");

pub const EvennessInfo = struct {
    distance: f32,
    perfectly_even: bool,
    maximally_even: bool,
    consonance: f32,
};

pub const EVENNESS_INFO_TABLE = buildEvennessInfoTable();

pub fn evennessDistance(set: pcs.PitchClassSet) f32 {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    if (list.len < 2) return 0;

    const ideal = 12.0 / @as(f32, @floatFromInt(list.len));
    var sum_sq: f32 = 0;

    var i: usize = 0;
    while (i < list.len) : (i += 1) {
        const a = list[i];
        const b = list[(i + 1) % list.len];
        const gap = if (b > a) @as(f32, @floatFromInt(b - a)) else @as(f32, @floatFromInt((12 - a) + b));
        const d = gap - ideal;
        sum_sq += d * d;
    }

    return @as(f32, @floatCast(std.math.sqrt(sum_sq)));
}

pub fn isPerfectlyEven(set: pcs.PitchClassSet) bool {
    return evennessDistance(set) <= 0.00001;
}

pub fn isMaximallyEven(set: pcs.PitchClassSet) bool {
    const card = pcs.cardinality(set);
    if (card < 2) return true;

    const d = evennessDistance(set);
    const min_d = minDistanceForCard(card);
    return @abs(d - min_d) <= 0.0001;
}

pub fn consonanceScore(set: pcs.PitchClassSet) f32 {
    const card = pcs.cardinality(set);
    if (card < 2) return 0;

    const iv = interval_vector.compute(set);
    const consonant_pairs = @as(f32, @floatFromInt(iv[2] + iv[3] + iv[4]));
    const total_pairs = @as(f32, @floatFromInt((@as(u16, card) * @as(u16, card - 1)) / 2));

    const interval_score = consonant_pairs / total_pairs;
    const even_score = 1.0 / (1.0 + evennessDistance(set));

    return interval_score * 0.5 + even_score * 0.5;
}

fn minDistanceForCard(card: u4) f32 {
    var min_d: f32 = std.math.floatMax(f32);

    var dec: u16 = 0;
    while (dec < 4096) : (dec += 1) {
        const set = @as(pcs.PitchClassSet, @intCast(dec));
        if (pcs.cardinality(set) != card) continue;

        const d = evennessDistance(set);
        if (d < min_d) min_d = d;
    }

    return min_d;
}

fn buildEvennessInfoTable() [set_class.SET_CLASSES.len]EvennessInfo {
    @setEvalBranchQuota(2_000_000);

    var out: [set_class.SET_CLASSES.len]EvennessInfo = undefined;
    for (set_class.SET_CLASSES, 0..) |sc, i| {
        const dist = evennessDistance(sc.pcs);
        out[i] = .{
            .distance = dist,
            .perfectly_even = dist <= 0.00001,
            .maximally_even = dist <= 0.00001,
            .consonance = consonanceScore(sc.pcs),
        };
    }
    return out;
}
