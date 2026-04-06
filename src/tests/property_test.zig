const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const interval_analysis = @import("../interval_analysis.zig");
const fc_components = @import("../fc_components.zig");
const pitch = @import("../pitch.zig");
const chord_detection = @import("../chord_detection.zig");
const mode = @import("../mode.zig");
const modal_interchange = @import("../modal_interchange.zig");

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

test "diatonic transposition round-trips across supported modes" {
    for (mode.ALL_MODES) |mode_info| {
        var offsets_buf: [8]u4 = undefined;
        const offsets = mode.offsets(mode_info.id, &offsets_buf);
        var tonic: u4 = 0;
        while (tonic < 12) : (tonic += 1) {
            for (offsets) |offset| {
                const note_pc = @as(u4, @intCast((@as(u8, tonic) + @as(u8, offset)) % 12));
                const note = pitch.pcToMidi(note_pc, 4);
                var degrees: i8 = -6;
                while (degrees <= 6) : (degrees += 1) {
                    const up = mode.transposeDiatonic(tonic, mode_info.id, note, degrees) orelse continue;
                    const back = mode.transposeDiatonic(tonic, mode_info.id, up, -degrees) orelse continue;
                    try testing.expectEqual(note, back);
                }
            }
        }
    }
}

test "nearest scale neighbors always stay inside the mode when present" {
    for (mode.ALL_MODES) |mode_info| {
        var tonic: u4 = 0;
        while (tonic < 12) : (tonic += 1) {
            var midi: u8 = 0;
            while (midi < 127) : (midi += 1) {
                const neighbors = mode.nearestScaleNeighbors(tonic, mode_info.id, @as(pitch.MidiNote, @intCast(midi)));
                if (neighbors.has_lower) {
                    try testing.expect(mode.degreeOfNote(tonic, mode_info.id, neighbors.lower) != null);
                }
                if (neighbors.has_upper) {
                    try testing.expect(mode.degreeOfNote(tonic, mode_info.id, neighbors.upper) != null);
                }
            }
        }
    }
}

test "modal interchange matches always contain the queried pitch class" {
    var mode_buf: [mode.ALL_MODES.len]mode.ModeType = undefined;
    for (mode.ALL_MODES, 0..) |mode_info, index| {
        mode_buf[index] = mode_info.id;
    }

    var out: [modal_interchange.MAX_MATCHES]modal_interchange.ContainingModeMatch = undefined;
    var tonic: u4 = 0;
    while (tonic < 12) : (tonic += 1) {
        var note_pc: u4 = 0;
        while (note_pc < 12) : (note_pc += 1) {
            const total = modal_interchange.findContainingModes(note_pc, tonic, mode_buf[0..], out[0..]);
            for (out[0..total]) |match| {
                try testing.expect(mode.degreeOfPitchClass(tonic, match.mode, note_pc) != null);
                try testing.expectEqual(match.degree, mode.degreeOfPitchClass(tonic, match.mode, note_pc).? + 1);
            }
        }
    }
}

test "detecting a shipped chord pattern preserves that pattern among exact matches" {
    for (chord_detection.ALL_PATTERNS) |pattern| {
        var out: [8]chord_detection.Match = undefined;
        const total = chord_detection.detectMatches(pattern.pcs, true, pitch.pc.C, out[0..]);
        try testing.expect(total >= 1);

        var found = false;
        for (out[0..@min(@as(usize, total), out.len)]) |match| {
            if (match.root == pitch.pc.C and match.pattern == pattern.id) {
                found = true;
                break;
            }
        }
        try testing.expect(found);
    }
}
