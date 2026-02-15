const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const key = @import("key.zig");

const MAJOR_SCALE_OFFSETS = [_]u4{ 0, 2, 4, 5, 7, 9, 11 };
const NATURAL_MINOR_SCALE_OFFSETS = [_]u4{ 0, 2, 3, 5, 7, 8, 10 };

const MAJOR_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 });
const MINOR_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7 });
const DIMINISHED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 });
const AUGMENTED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });

const MAJOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 });
const DOMINANT_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 10 });
const MINOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7, 10 });
const HALF_DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 10 });
const DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 9 });

pub const CIRCLE_OF_FIFTHS_DEGREES = [_]u4{ 7, 3, 6, 2, 5, 1, 4 };
pub const CIRCLE_OF_THIRDS_DEGREES = [_]u4{ 1, 6, 4, 2, 7, 5, 3 };

pub const ChordQuality = enum {
    major,
    minor,
    diminished,
    augmented,
    dominant,
    half_diminished,
    diminished_seventh,
    unknown,
};

pub const ChordInstance = struct {
    root: pitch.PitchClass,
    pcs: pcs.PitchClassSet,
    quality: ChordQuality,
    degree: u4,
};

pub const DiatonicHarmony = struct {
    key: key.Key,
    triads: [7]ChordInstance,
    sevenths: [7]ChordInstance,

    pub fn init(k: key.Key) DiatonicHarmony {
        var triads: [7]ChordInstance = undefined;
        var sevenths: [7]ChordInstance = undefined;

        var i: usize = 0;
        while (i < 7) : (i += 1) {
            const degree = @as(u4, @intCast(i + 1));
            triads[i] = diatonicTriad(k, degree);
            sevenths[i] = diatonicSeventh(k, degree);
        }

        return .{
            .key = k,
            .triads = triads,
            .sevenths = sevenths,
        };
    }
};

pub const RomanNumeral = struct {
    degree: u4,
    uppercase: bool,
    suffix: Suffix,
    extension: Extension,

    pub const Suffix = enum {
        none,
        diminished,
        augmented,
        half_diminished,
    };

    pub const Extension = enum {
        none,
        seven,
        maj7,
    };

    pub fn format(self: RomanNumeral, buf: *[16]u8) []u8 {
        if (self.degree < 1 or self.degree > 7) {
            buf[0] = '?';
            return buf[0..1];
        }

        const upper = [_][]const u8{ "I", "II", "III", "IV", "V", "VI", "VII" };
        const lower = [_][]const u8{ "i", "ii", "iii", "iv", "v", "vi", "vii" };

        var len: usize = 0;
        const base = if (self.uppercase) upper[self.degree - 1] else lower[self.degree - 1];
        std.mem.copyForwards(u8, buf[len .. len + base.len], base);
        len += base.len;

        switch (self.suffix) {
            .none => {},
            .diminished => {
                const sym = "°";
                std.mem.copyForwards(u8, buf[len .. len + sym.len], sym);
                len += sym.len;
            },
            .augmented => {
                buf[len] = '+';
                len += 1;
            },
            .half_diminished => {
                const sym = "ø";
                std.mem.copyForwards(u8, buf[len .. len + sym.len], sym);
                len += sym.len;
            },
        }

        switch (self.extension) {
            .none => {},
            .seven => {
                buf[len] = '7';
                len += 1;
            },
            .maj7 => {
                const s = "maj7";
                std.mem.copyForwards(u8, buf[len .. len + s.len], s);
                len += s.len;
            },
        }

        return buf[0..len];
    }
};

pub const ModeContext = struct {
    root: pitch.PitchClass,
    pcs: pcs.PitchClassSet,
};

pub const ChordScaleMatch = struct {
    compatible: bool,
    avoid_notes: pcs.PitchClassSet,
    available_tensions: pcs.PitchClassSet,
};

pub fn keyScaleSet(k: key.Key) pcs.PitchClassSet {
    var list: [7]pitch.PitchClass = undefined;

    var i: usize = 0;
    while (i < 7) : (i += 1) {
        list[i] = degreePitchClass(k, @as(u4, @intCast(i + 1)));
    }

    return pcs.fromList(&list);
}

pub fn diatonicTriad(k: key.Key, degree: u4) ChordInstance {
    validateDegree(degree);

    const root = degreePitchClass(k, degree);
    const third = degreePitchClass(k, wrapDegree(degree, 2));
    const fifth = degreePitchClass(k, wrapDegree(degree, 4));

    const set = pcs.fromList(&[_]pitch.PitchClass{ root, third, fifth });
    return .{
        .root = root,
        .pcs = set,
        .quality = classifyChord(root, set),
        .degree = degree,
    };
}

pub fn diatonicSeventh(k: key.Key, degree: u4) ChordInstance {
    validateDegree(degree);

    const root = degreePitchClass(k, degree);
    const third = degreePitchClass(k, wrapDegree(degree, 2));
    const fifth = degreePitchClass(k, wrapDegree(degree, 4));
    const seventh = degreePitchClass(k, wrapDegree(degree, 6));

    const set = pcs.fromList(&[_]pitch.PitchClass{ root, third, fifth, seventh });
    return .{
        .root = root,
        .pcs = set,
        .quality = classifyChord(root, set),
        .degree = degree,
    };
}

pub fn romanNumeral(ch: ChordInstance, k: key.Key) RomanNumeral {
    const degree = findDegreeForRoot(k, ch.root);

    const suffix: RomanNumeral.Suffix = switch (ch.quality) {
        .diminished, .diminished_seventh => .diminished,
        .augmented => .augmented,
        .half_diminished => .half_diminished,
        else => .none,
    };

    const uppercase = switch (ch.quality) {
        .minor, .diminished, .half_diminished, .diminished_seventh => false,
        else => true,
    };

    const extension: RomanNumeral.Extension = blk: {
        if (pcs.cardinality(ch.pcs) < 4) break :blk .none;
        if (ch.quality == .major) break :blk .maj7;
        break :blk .seven;
    };

    return .{
        .degree = degree,
        .uppercase = uppercase,
        .suffix = suffix,
        .extension = extension,
    };
}

pub fn chordScaleCompatibility(ch: ChordInstance, mode_ctx: ModeContext) ChordScaleMatch {
    if (!pcs.isSubsetOf(ch.pcs, mode_ctx.pcs)) {
        return .{
            .compatible = false,
            .avoid_notes = 0,
            .available_tensions = 0,
        };
    }

    var avoid: pcs.PitchClassSet = 0;
    var available: pcs.PitchClassSet = 0;

    var mode_list_buf: [12]pitch.PitchClass = undefined;
    const mode_list = pcs.toList(mode_ctx.pcs, &mode_list_buf);

    for (mode_list) |scale_pc| {
        const bit = @as(pcs.PitchClassSet, 1) << scale_pc;
        if ((ch.pcs & bit) != 0) continue;

        if (isAvoidTone(scale_pc, ch.pcs)) {
            avoid |= bit;
        } else {
            available |= bit;
        }
    }

    return .{
        .compatible = true,
        .avoid_notes = avoid,
        .available_tensions = available,
    };
}

pub fn tritoneSub(ch: ChordInstance) ChordInstance {
    const new_root = @as(pitch.PitchClass, @intCast((@as(u8, ch.root) + 6) % 12));
    const new_set = pcs.transpose(ch.pcs, 6);

    return .{
        .root = new_root,
        .pcs = new_set,
        .quality = classifyChord(new_root, new_set),
        .degree = 0,
    };
}

fn classifyChord(root: pitch.PitchClass, set: pcs.PitchClassSet) ChordQuality {
    const normalized = pcs.transposeDown(set, root);

    if (normalized == MAJOR_TRIAD) return .major;
    if (normalized == MINOR_TRIAD) return .minor;
    if (normalized == DIMINISHED_TRIAD) return .diminished;
    if (normalized == AUGMENTED_TRIAD) return .augmented;

    if (normalized == MAJOR_SEVENTH) return .major;
    if (normalized == DOMINANT_SEVENTH) return .dominant;
    if (normalized == MINOR_SEVENTH) return .minor;
    if (normalized == HALF_DIMINISHED_SEVENTH) return .half_diminished;
    if (normalized == DIMINISHED_SEVENTH) return .diminished_seventh;

    return .unknown;
}

fn validateDegree(degree: u4) void {
    std.debug.assert(degree >= 1 and degree <= 7);
}

fn wrapDegree(base_degree: u4, step: u4) u4 {
    const base = @as(u8, base_degree) - 1;
    return @as(u4, @intCast(((base + step) % 7) + 1));
}

fn degreePitchClass(k: key.Key, degree: u4) pitch.PitchClass {
    validateDegree(degree);
    const idx = @as(usize, degree - 1);

    const offset = switch (k.quality) {
        .major => MAJOR_SCALE_OFFSETS[idx],
        .minor => NATURAL_MINOR_SCALE_OFFSETS[idx],
    };

    return @as(pitch.PitchClass, @intCast((@as(u8, k.tonic) + offset) % 12));
}

fn findDegreeForRoot(k: key.Key, root: pitch.PitchClass) u4 {
    var degree: u4 = 1;
    while (degree <= 7) : (degree += 1) {
        if (degreePitchClass(k, degree) == root) {
            return degree;
        }
    }
    return 0;
}

fn isAvoidTone(scale_pc: pitch.PitchClass, chord_pcs: pcs.PitchClassSet) bool {
    const below = @as(pitch.PitchClass, @intCast((@as(u8, scale_pc) + 11) % 12));
    return (chord_pcs & (@as(pcs.PitchClassSet, 1) << below)) != 0;
}
