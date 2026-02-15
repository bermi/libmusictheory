const std = @import("std");
const pitch = @import("pitch.zig");

pub const PitchClassSet = u12;

pub const EMPTY: PitchClassSet = 0;
pub const CHROMATIC: PitchClassSet = 0b111111111111;

pub const C_MAJOR_TRIAD: PitchClassSet = fromList(&[_]pitch.PitchClass{ 0, 4, 7 });
pub const C_MINOR_TRIAD: PitchClassSet = fromList(&[_]pitch.PitchClass{ 0, 3, 7 });
pub const DIATONIC: PitchClassSet = fromList(&[_]pitch.PitchClass{ 0, 2, 4, 5, 7, 9, 11 });
pub const C_MAJOR_PENTATONIC: PitchClassSet = fromList(&[_]pitch.PitchClass{ 0, 2, 4, 7, 9 });
pub const PENTATONIC: PitchClassSet = complement(DIATONIC);

pub fn fromList(list: []const pitch.PitchClass) PitchClassSet {
    var out: PitchClassSet = EMPTY;
    for (list) |pc| {
        out |= @as(PitchClassSet, @intCast(@as(u13, 1) << @as(u4, @intCast(pc % 12))));
    }
    return out;
}

pub fn toList(set: PitchClassSet, out: *[12]pitch.PitchClass) []pitch.PitchClass {
    var i: usize = 0;
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if (set & (@as(PitchClassSet, 1) << pc) != 0) {
            out[i] = @as(pitch.PitchClass, @intCast(pc));
            i += 1;
        }
    }
    return out[0..i];
}

pub fn cardinality(set: PitchClassSet) u4 {
    return @as(u4, @intCast(@popCount(set)));
}

pub fn transpose(set: PitchClassSet, semitones: u4) PitchClassSet {
    const shift = @as(u4, @intCast(semitones % 12));
    if (shift == 0) return set;

    const left = @as(PitchClassSet, @truncate(set << shift));
    const wrapped = set >> @as(u4, @intCast(12 - shift));
    return (left | wrapped) & CHROMATIC;
}

pub fn transposeDown(set: PitchClassSet, semitones: u4) PitchClassSet {
    const shift = @as(u4, @intCast(semitones % 12));
    if (shift == 0) return set;

    const right = set >> shift;
    const wrapped = @as(PitchClassSet, @truncate(set << @as(u4, @intCast(12 - shift))));
    return (right | wrapped) & CHROMATIC;
}

pub fn invert(set: PitchClassSet) PitchClassSet {
    var out: PitchClassSet = EMPTY;
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if (set & (@as(PitchClassSet, 1) << pc) != 0) {
            const inv: u4 = if (pc == 0) 0 else @as(u4, @intCast(12 - pc));
            out |= @as(PitchClassSet, 1) << inv;
        }
    }
    return out;
}

pub fn complement(set: PitchClassSet) PitchClassSet {
    return CHROMATIC ^ set;
}

pub fn isSubsetOf(small: PitchClassSet, big: PitchClassSet) bool {
    return (small & big) == small;
}

pub fn union_(a: PitchClassSet, b: PitchClassSet) PitchClassSet {
    return a | b;
}

pub fn intersection(a: PitchClassSet, b: PitchClassSet) PitchClassSet {
    return a & b;
}

pub fn hammingDistance(a: PitchClassSet, b: PitchClassSet) u4 {
    return @as(u4, @intCast(@popCount(a ^ b)));
}

pub fn format(set: PitchClassSet, buf: *[12]u8) []u8 {
    var i: usize = 0;
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if (set & (@as(PitchClassSet, 1) << pc) != 0) {
            buf[i] = switch (pc) {
                10 => 't',
                11 => 'e',
                else => '0' + @as(u8, @intCast(pc)),
            };
            i += 1;
        }
    }
    return buf[0..i];
}

pub fn hasSub(small: PitchClassSet, big: PitchClassSet) bool {
    const rots = allRotations(small);
    for (rots) |rot| {
        if (isSubsetOf(rot, big)) {
            return true;
        }
    }
    return false;
}

pub fn allRotations(set: PitchClassSet) [12]PitchClassSet {
    var out: [12]PitchClassSet = undefined;
    var r = set;
    var i: usize = 0;
    while (i < 12) : (i += 1) {
        out[i] = r;
        r = transposeDown(r, 1);
    }
    return out;
}

pub fn leastError(candidates: []const PitchClassSet, target: PitchClassSet) PitchClassSet {
    std.debug.assert(candidates.len > 0);

    var best = candidates[0];
    var best_error = hammingDistance(candidates[0], target);
    for (candidates[1..]) |candidate| {
        const err = hammingDistance(candidate, target);
        if (err < best_error) {
            best = candidate;
            best_error = err;
        }
    }
    return best;
}
