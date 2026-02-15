const pcs = @import("pitch_class_set.zig");
const forte = @import("forte.zig");

pub const ClassificationFlags = packed struct(u16) {
    cluster_free: bool = false,
    symmetric: bool = false,
    limited_transposition: bool = false,
    _padding: u13 = 0,
};

pub const SetClass = struct {
    pcs: pcs.PitchClassSet,
    cardinality: u4,
    prime: pcs.PitchClassSet,
    forte_prime: pcs.PitchClassSet,
    forte_number: forte.ForteNumber,
    flags: ClassificationFlags,
};

pub fn primeForm(set: pcs.PitchClassSet) pcs.PitchClassSet {
    const rots = pcs.allRotations(set);
    var best = rots[0];
    for (rots[1..]) |r| {
        if (r < best) best = r;
    }
    return best;
}

pub fn fortePrime(set: pcs.PitchClassSet) pcs.PitchClassSet {
    const prime = primeForm(set);
    const inverted = primeForm(pcs.invert(set));
    return if (inverted < prime) inverted else prime;
}

pub fn numTranspositions(set: pcs.PitchClassSet) u4 {
    const rots = pcs.allRotations(set);
    var seen = [_]bool{false} ** 4096;
    var count: u4 = 0;
    for (rots) |r| {
        if (!seen[r]) {
            seen[r] = true;
            count += 1;
        }
    }
    return count;
}

pub fn isLimitedTransposition(set: pcs.PitchClassSet) bool {
    return numTranspositions(set) < 12;
}

pub fn isSymmetric(set: pcs.PitchClassSet) bool {
    return primeForm(set) == primeForm(pcs.invert(set));
}

pub const SET_CLASSES = enumerateSetClasses();

pub fn countOpticClasses() u16 {
    var seen = [_]bool{false} ** (10 * 81);
    var count: u16 = 0;

    for (SET_CLASSES) |sc| {
        const key = @as(usize, sc.forte_number.cardinality) * 81 + @as(usize, sc.forte_number.ordinal);
        if (!seen[key]) {
            seen[key] = true;
            count += 1;
        }
    }

    return count;
}

pub fn countOpticKGroups() u16 {
    var seen = [_]bool{false} ** 100000;
    var count: u16 = 0;

    for (SET_CLASSES) |sc| {
        const lhs = encodeForte(sc.forte_number);

        const comp_prime = fortePrime(pcs.complement(sc.pcs));
        const comp_forte = forte.lookup(comp_prime) orelse continue;
        const rhs = encodeForte(comp_forte);

        const min_key = if (lhs < rhs) lhs else rhs;
        const max_key = if (lhs > rhs) lhs else rhs;
        const pair_key = min_key * 100 + max_key;

        if (!seen[pair_key]) {
            seen[pair_key] = true;
            count += 1;
        }
    }

    return count;
}

fn encodeForte(number: forte.ForteNumber) usize {
    return @as(usize, number.cardinality) * 100 + @as(usize, number.ordinal);
}

fn enumerateSetClasses() [336]SetClass {
    @setEvalBranchQuota(2_000_000);

    var out: [336]SetClass = undefined;
    var i: usize = 0;

    var dec: u16 = 0;
    while (dec < 4096) : (dec += 1) {
        const set = @as(pcs.PitchClassSet, @intCast(dec));
        const card = pcs.cardinality(set);
        if (card < 3 or card > 9) continue;

        const prime = primeForm(set);
        if (prime != set) continue;

        const fprime = fortePrime(set);
        const fnum = forte.lookup(fprime) orelse forte.ForteNumber{
            .cardinality = card,
            .ordinal = 0,
            .is_z = false,
        };

        out[i] = .{
            .pcs = set,
            .cardinality = card,
            .prime = prime,
            .forte_prime = fprime,
            .forte_number = fnum,
            .flags = .{
                .symmetric = isSymmetric(set),
                .limited_transposition = isLimitedTransposition(set),
            },
        };
        i += 1;
    }

    if (i != 336) {
        @compileError("Expected 336 transposition set classes in cardinalities 3-9");
    }

    return out;
}
