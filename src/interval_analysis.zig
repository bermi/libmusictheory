const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const interval_vector = @import("interval_vector.zig");
const fc_components = @import("fc_components.zig");

pub const INTERVAL_VECTOR_TABLE = buildIntervalVectorTable();
pub const FC_COMPONENT_TABLE = buildFCComponentTable();

pub fn m5Transform(set: pcs.PitchClassSet) pcs.PitchClassSet {
    return multiplyTransform(set, 5);
}

pub fn m7Transform(set: pcs.PitchClassSet) pcs.PitchClassSet {
    return multiplyTransform(set, 7);
}

pub fn isZRelated(a: pcs.PitchClassSet, b: pcs.PitchClassSet) bool {
    if (pcs.cardinality(a) != pcs.cardinality(b)) return false;

    const iv_a = interval_vector.compute(a);
    const iv_b = interval_vector.compute(b);
    if (!std.mem.eql(u8, iv_a[0..], iv_b[0..])) return false;

    return set_class.fortePrime(a) != set_class.fortePrime(b);
}

pub fn isMRelated(a: pcs.PitchClassSet, b: pcs.PitchClassSet) bool {
    if (pcs.cardinality(a) != pcs.cardinality(b)) return false;

    const b_prime = set_class.primeForm(b);
    const a_m5_prime = set_class.primeForm(m5Transform(a));
    const a_m7_prime = set_class.primeForm(m7Transform(a));

    return b_prime == a_m5_prime or b_prime == a_m7_prime;
}

fn multiplyTransform(set: pcs.PitchClassSet, multiplier: u4) pcs.PitchClassSet {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    var out_list: [12]pitch.PitchClass = undefined;
    var i: usize = 0;
    for (list) |pc| {
        const product = @as(u8, pc) * @as(u8, multiplier);
        out_list[i] = @as(pitch.PitchClass, @intCast(product % 12));
        i += 1;
    }

    return pcs.fromList(out_list[0..i]);
}

fn buildIntervalVectorTable() [set_class.SET_CLASSES.len]interval_vector.IntervalVector {
    @setEvalBranchQuota(2_000_000);

    var out: [set_class.SET_CLASSES.len]interval_vector.IntervalVector = undefined;
    for (set_class.SET_CLASSES, 0..) |sc, i| {
        out[i] = interval_vector.compute(sc.pcs);
    }
    return out;
}

fn buildFCComponentTable() [set_class.SET_CLASSES.len]fc_components.FCComponents {
    @setEvalBranchQuota(2_000_000);

    var out: [set_class.SET_CLASSES.len]fc_components.FCComponents = undefined;
    for (set_class.SET_CLASSES, 0..) |sc, i| {
        out[i] = fc_components.compute(sc.pcs);
    }
    return out;
}
