const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const evenness = @import("evenness.zig");
const forte = @import("forte.zig");
const cluster = @import("cluster.zig");

pub const DISPLAY_ENTRY_COUNT: usize = 194;

pub const BorderStyle = enum {
    single,
    pair,
};

pub const IndexMarkerFamily = enum {
    diatonic_hexagon,
    acoustic_square,
    whole_tone_star,
    diminished_octagon,
    neighboring_triangle,
    other_circle,
};

pub const Entry = struct {
    sc: set_class.SetClass,
    border: BorderStyle,
    marker_family: IndexMarkerFamily,
    cluster_free: bool,
    limited_transposition: bool,
    evenness_distance: f32,
};

pub fn isOpticRepresentative(sc: set_class.SetClass) bool {
    return sc.pcs == sc.forte_prime;
}

pub fn isSelfComplementary(sc: set_class.SetClass) bool {
    const comp_prime = set_class.fortePrime(pcs.complement(sc.pcs));
    const comp_forte = forte.lookup(comp_prime) orelse return false;
    return sc.forte_number.cardinality == comp_forte.cardinality and
        sc.forte_number.ordinal == comp_forte.ordinal and
        sc.forte_number.is_z == comp_forte.is_z;
}

pub fn isSelfComplementarySymmetricHexachord(sc: set_class.SetClass) bool {
    return sc.cardinality == 6 and sc.flags.symmetric and isSelfComplementary(sc);
}

pub fn includeInDisplayDomain(sc: set_class.SetClass) bool {
    if (!isOpticRepresentative(sc)) return false;
    if (sc.cardinality == 6 and sc.flags.symmetric and !isSelfComplementarySymmetricHexachord(sc)) return false;
    return true;
}

pub fn classifyIndexMarker(sc: set_class.SetClass) IndexMarkerFamily {
    const diatonic = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 9, 11 });
    const acoustic = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 3, 4, 6, 8, 10 });
    const whole_tone = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 6, 8, 10 });
    const diminished = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 3, 4, 6, 7, 9, 10 });
    const augmented_hex = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 4, 5, 8, 9 });
    const harmonic_major = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 8, 11 });
    const harmonic_minor = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 5, 7, 8, 11 });

    if (isSubsetClass(sc.pcs, diatonic)) return .diatonic_hexagon;
    if (isSubsetClass(sc.pcs, acoustic)) return .acoustic_square;
    if (isSubsetClass(sc.pcs, whole_tone)) return .whole_tone_star;
    if (isSubsetClass(sc.pcs, diminished)) return .diminished_octagon;
    if (isSubsetClass(sc.pcs, augmented_hex) or
        isSubsetClass(sc.pcs, harmonic_major) or
        isSubsetClass(sc.pcs, harmonic_minor)) return .neighboring_triangle;
    return .other_circle;
}

pub fn enumerateDisplayDomain(out: *[DISPLAY_ENTRY_COUNT]Entry) []Entry {
    var i: usize = 0;
    for (set_class.SET_CLASSES) |sc| {
        if (!includeInDisplayDomain(sc)) continue;
        out[i] = .{
            .sc = sc,
            .border = if (sc.flags.symmetric) .single else .pair,
            .marker_family = classifyIndexMarker(sc),
            .cluster_free = !cluster.hasCluster(sc.pcs),
            .limited_transposition = sc.flags.limited_transposition,
            .evenness_distance = evenness.evennessDistance(sc.pcs),
        };
        i += 1;
    }
    std.debug.assert(i == DISPLAY_ENTRY_COUNT);
    return out[0..i];
}

pub fn cardinalityHistogram(entries: []const Entry, out: *[13]u16) void {
    out.* = [_]u16{0} ** 13;
    for (entries) |entry| {
        out[@as(usize, entry.sc.cardinality)] += 1;
    }
}

pub fn countBorder(entries: []const Entry, border: BorderStyle) usize {
    var count: usize = 0;
    for (entries) |entry| {
        if (entry.border == border) count += 1;
    }
    return count;
}

fn isSubsetClass(small: pcs.PitchClassSet, big: pcs.PitchClassSet) bool {
    return pcs.hasSub(small, big) or pcs.hasSub(pcs.invert(small), big);
}
