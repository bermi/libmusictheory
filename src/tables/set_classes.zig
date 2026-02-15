const pcs = @import("../pitch_class_set.zig");
const forte = @import("../forte.zig");
const set_class = @import("../set_class.zig");

pub const SET_CLASSES = set_class.SET_CLASSES;
pub const FORTE_MAP = buildForteMap();
pub const COMPLEMENT_MAP = buildComplementMap();
pub const INVOLUTION_MAP = buildInvolutionMap();

fn buildForteMap() [SET_CLASSES.len]forte.ForteNumber {
    @setEvalBranchQuota(2_000_000);

    var out: [SET_CLASSES.len]forte.ForteNumber = undefined;
    for (SET_CLASSES, 0..) |sc, i| {
        out[i] = sc.forte_number;
    }
    return out;
}

fn buildComplementMap() [SET_CLASSES.len]u16 {
    @setEvalBranchQuota(2_000_000);

    var out: [SET_CLASSES.len]u16 = undefined;
    for (SET_CLASSES, 0..) |sc, i| {
        const comp_prime = set_class.fortePrime(pcs.complement(sc.pcs));
        out[i] = findSetClassIndex(comp_prime);
    }
    return out;
}

fn buildInvolutionMap() [SET_CLASSES.len]u16 {
    @setEvalBranchQuota(2_000_000);

    var out: [SET_CLASSES.len]u16 = undefined;
    for (SET_CLASSES, 0..) |sc, i| {
        const inv_prime = set_class.fortePrime(pcs.invert(sc.pcs));
        out[i] = findSetClassIndex(inv_prime);
    }
    return out;
}

fn findSetClassIndex(target: pcs.PitchClassSet) u16 {
    for (SET_CLASSES, 0..) |sc, i| {
        if (sc.pcs == target) return @as(u16, @intCast(i));
    }
    unreachable;
}
