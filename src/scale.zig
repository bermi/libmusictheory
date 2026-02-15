const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");

pub const ScaleType = enum {
    diatonic,
    acoustic,
    diminished,
    whole_tone,
    harmonic_minor,
    harmonic_major,
    double_augmented_hexatonic,
};

pub const DIATONIC: pcs.PitchClassSet = 0b101010110101;
pub const ACOUSTIC: pcs.PitchClassSet = 0b101010110011;
pub const DIMINISHED: pcs.PitchClassSet = 0b011011011011;
pub const WHOLE_TONE: pcs.PitchClassSet = 0b010101010101;
pub const HARMONIC_MINOR: pcs.PitchClassSet = 0b100110110011;
pub const HARMONIC_MAJOR: pcs.PitchClassSet = 0b101010110011;
pub const DOUBLE_AUGMENTED_HEXATONIC: pcs.PitchClassSet = 0b000100110011;

pub const Scale = struct {
    scale_type: ScaleType,
    root: pitch.PitchClass,
    pcs: pcs.PitchClassSet,

    pub fn init(scale_type: ScaleType, root: pitch.PitchClass) Scale {
        return .{
            .scale_type = scale_type,
            .root = root,
            .pcs = pcs.transpose(pcsForType(scale_type), root),
        };
    }

    pub const Mode = struct {
        degree: u4,
        pcs: pcs.PitchClassSet,
    };

    pub fn mode(self: Scale, degree: u4) Mode {
        var list_buf: [12]pitch.PitchClass = undefined;
        const list = pcs.toList(self.pcs, &list_buf);

        std.debug.assert(degree < list.len);
        const root_pc = list[degree];

        return .{
            .degree = degree,
            .pcs = pcs.transposeDown(self.pcs, root_pc),
        };
    }
};

pub fn pcsForType(scale_type: ScaleType) pcs.PitchClassSet {
    return switch (scale_type) {
        .diatonic => DIATONIC,
        .acoustic => ACOUSTIC,
        .diminished => DIMINISHED,
        .whole_tone => WHOLE_TONE,
        .harmonic_minor => HARMONIC_MINOR,
        .harmonic_major => HARMONIC_MAJOR,
        .double_augmented_hexatonic => DOUBLE_AUGMENTED_HEXATONIC,
    };
}

pub fn identifyScaleType(set: pcs.PitchClassSet) ?ScaleType {
    const target = set_class.fortePrime(set);

    inline for ([_]ScaleType{ .diatonic, .acoustic, .diminished, .whole_tone, .harmonic_minor, .harmonic_major, .double_augmented_hexatonic }) |scale_type| {
        if (target == set_class.fortePrime(pcsForType(scale_type))) {
            return scale_type;
        }
    }

    return null;
}

pub fn isScaley(set: pcs.PitchClassSet) bool {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);
    if (list.len < 5) return false;

    var one_lte2 = false;
    var none_gt3 = true;
    var lte2_count: u8 = 0;
    var gte3_count: u8 = 0;

    var i: usize = 0;
    while (i < list.len) : (i += 1) {
        const a = list[i];
        const b = if (i + 1 < list.len) list[i + 1] else @as(pitch.PitchClass, @intCast(list[0] + 12));
        const diff = b - a;

        if (diff <= 2) {
            one_lte2 = true;
            lte2_count += 1;
        }
        if (diff > 3) {
            none_gt3 = false;
        }
        if (diff >= 3) {
            gte3_count += 1;
        }
    }

    return one_lte2 and none_gt3 and gte3_count < lte2_count;
}
