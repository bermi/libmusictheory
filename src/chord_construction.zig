const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const chord_type = @import("chord_type.zig");
const cluster = @import("cluster.zig");
const mode = @import("mode.zig");

pub const Inversion = enum {
    unknown,
    root_position,
    first,
    second,
    third,
};

pub const GameStats = struct {
    otc_count: u16,
    card_3_to_9_count: u16,
    cluster_free_count: u16,
    mode_subset_count: u16,
};

pub fn formulaToPCS(formula: []const u8) pcs.PitchClassSet {
    var out: pcs.PitchClassSet = 0;
    var it = std.mem.tokenizeAny(u8, formula, " \t\n");
    while (it.next()) |token| {
        const pc = tokenToPitchClass(token) orelse continue;
        out |= @as(pcs.PitchClassSet, 1) << pc;
    }
    return out;
}

pub fn pcsToChordName(set: pcs.PitchClassSet) ?[]const u8 {
    const prime = pcs.transposeDown(set, firstPitchClass(set) orelse 0);

    for (chord_type.ALL) |ct| {
        if (ct.pcs == prime) return ct.name;
    }
    return null;
}

pub fn detectInversion(bass_pc: pitch.PitchClass, chord_pcs: pcs.PitchClassSet) Inversion {
    if ((chord_pcs & (@as(pcs.PitchClassSet, 1) << bass_pc)) == 0) {
        return .unknown;
    }

    if (chord_pcs == pcs.C_MAJOR_TRIAD or chord_pcs == pcs.C_MINOR_TRIAD) {
        if (bass_pc == 0) return .root_position;
        if (bass_pc == 3 or bass_pc == 4) return .first;
        if (bass_pc == 7) return .second;
    }

    return .unknown;
}

pub fn shellChord(chord_pcs: pcs.PitchClassSet, root: pitch.PitchClass) pcs.PitchClassSet {
    var out: pcs.PitchClassSet = @as(pcs.PitchClassSet, 1) << root;

    const minor_third = @as(pitch.PitchClass, @intCast((@as(u8, root) + 3) % 12));
    const major_third = @as(pitch.PitchClass, @intCast((@as(u8, root) + 4) % 12));
    const minor_seventh = @as(pitch.PitchClass, @intCast((@as(u8, root) + 10) % 12));
    const major_seventh = @as(pitch.PitchClass, @intCast((@as(u8, root) + 11) % 12));

    if ((chord_pcs & (@as(pcs.PitchClassSet, 1) << major_third)) != 0) {
        out |= @as(pcs.PitchClassSet, 1) << major_third;
    } else if ((chord_pcs & (@as(pcs.PitchClassSet, 1) << minor_third)) != 0) {
        out |= @as(pcs.PitchClassSet, 1) << minor_third;
    }

    if ((chord_pcs & (@as(pcs.PitchClassSet, 1) << major_seventh)) != 0) {
        out |= @as(pcs.PitchClassSet, 1) << major_seventh;
    } else if ((chord_pcs & (@as(pcs.PitchClassSet, 1) << minor_seventh)) != 0) {
        out |= @as(pcs.PitchClassSet, 1) << minor_seventh;
    }

    return out;
}

pub fn leaveOneOut(set: pcs.PitchClassSet, out: *[12]pcs.PitchClassSet) []pcs.PitchClassSet {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    for (list, 0..) |pc, i| {
        out[i] = set ^ (@as(pcs.PitchClassSet, 1) << pc);
    }

    return out[0..list.len];
}

pub fn computeGameStats() GameStats {
    var stats = GameStats{
        .otc_count = 0,
        .card_3_to_9_count = 0,
        .cluster_free_count = 0,
        .mode_subset_count = 0,
    };

    var dec: u16 = 0;
    while (dec < 4096) : (dec += 1) {
        const set = @as(pcs.PitchClassSet, @intCast(dec));
        if ((set & 1) == 0) continue;
        stats.otc_count += 1;

        const card = pcs.cardinality(set);
        if (card < 3 or card > 9) continue;
        stats.card_3_to_9_count += 1;

        if (!cluster.hasCluster(set)) {
            stats.cluster_free_count += 1;
            if (isSubsetOfAnyMode(set)) {
                stats.mode_subset_count += 1;
            }
        }
    }

    return stats;
}

fn isSubsetOfAnyMode(set: pcs.PitchClassSet) bool {
    for (mode.ALL_MODES) |m| {
        if (pcs.hasSub(set, m.pcs)) return true;
    }
    return false;
}

fn tokenToPitchClass(token: []const u8) ?pitch.PitchClass {
    if (std.mem.eql(u8, token, "1")) return 0;
    if (std.mem.eql(u8, token, "b2")) return 1;
    if (std.mem.eql(u8, token, "2")) return 2;
    if (std.mem.eql(u8, token, "#2")) return 3;
    if (std.mem.eql(u8, token, "b3")) return 3;
    if (std.mem.eql(u8, token, "3")) return 4;
    if (std.mem.eql(u8, token, "#3")) return 5;
    if (std.mem.eql(u8, token, "4")) return 5;
    if (std.mem.eql(u8, token, "#4")) return 6;
    if (std.mem.eql(u8, token, "b5")) return 6;
    if (std.mem.eql(u8, token, "5")) return 7;
    if (std.mem.eql(u8, token, "#5")) return 8;
    if (std.mem.eql(u8, token, "b6")) return 8;
    if (std.mem.eql(u8, token, "6")) return 9;
    if (std.mem.eql(u8, token, "b7")) return 10;
    if (std.mem.eql(u8, token, "7")) return 11;
    if (std.mem.eql(u8, token, "9")) return 2;
    if (std.mem.eql(u8, token, "11")) return 5;
    if (std.mem.eql(u8, token, "13")) return 9;
    return null;
}

fn firstPitchClass(set: pcs.PitchClassSet) ?pitch.PitchClass {
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if ((set & (@as(pcs.PitchClassSet, 1) << pc)) != 0) {
            return @as(pitch.PitchClass, @intCast(pc));
        }
    }
    return null;
}
