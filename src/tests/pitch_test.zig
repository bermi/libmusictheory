const std = @import("std");
const testing = std.testing;

const pitch = @import("../pitch.zig");
const note_name = @import("../note_name.zig");
const interval = @import("../interval.zig");

test "pitch class constants" {
    try testing.expectEqual(@as(pitch.PitchClass, 0), pitch.pc.C);
    try testing.expectEqual(@as(pitch.PitchClass, 1), pitch.pc.Cs);
    try testing.expectEqual(@as(pitch.PitchClass, 2), pitch.pc.D);
    try testing.expectEqual(@as(pitch.PitchClass, 3), pitch.pc.Ds);
    try testing.expectEqual(@as(pitch.PitchClass, 4), pitch.pc.E);
    try testing.expectEqual(@as(pitch.PitchClass, 5), pitch.pc.F);
    try testing.expectEqual(@as(pitch.PitchClass, 6), pitch.pc.Fs);
    try testing.expectEqual(@as(pitch.PitchClass, 7), pitch.pc.G);
    try testing.expectEqual(@as(pitch.PitchClass, 8), pitch.pc.Gs);
    try testing.expectEqual(@as(pitch.PitchClass, 9), pitch.pc.A);
    try testing.expectEqual(@as(pitch.PitchClass, 10), pitch.pc.As);
    try testing.expectEqual(@as(pitch.PitchClass, 11), pitch.pc.B);
}

test "midi to pitch class round trip" {
    var midi: u8 = 0;
    while (midi <= 127) : (midi += 1) {
        const note = @as(pitch.MidiNote, @intCast(midi));
        const pc = pitch.midiToPC(note);
        const octave = pitch.midiToOctave(note);
        const rebuilt = pitch.pcToMidi(pc, octave);
        try testing.expectEqual(note, rebuilt);
    }
}

test "a4 is 440hz" {
    const hz = pitch.midiToFrequency(69);
    try testing.expectApproxEqAbs(@as(f64, 440.0), hz, 0.0000001);
}

test "all 35 note spellings map to pitch class" {
    try testing.expectEqual(@as(usize, 35), note_name.ALL_SPELLINGS.len);

    var seen = [_]bool{false} ** 35;
    for (note_name.ALL_SPELLINGS, 0..) |spelling, index| {
        seen[index] = true;
        _ = spelling.toPitchClass();
    }

    for (seen) |value| {
        try testing.expect(value);
    }

    const expected = [_]struct { name: []const u8, pc: pitch.PitchClass }{
        .{ .name = "A", .pc = 9 },
        .{ .name = "Bbb", .pc = 9 },
        .{ .name = "A#", .pc = 10 },
        .{ .name = "Bb", .pc = 10 },
        .{ .name = "B", .pc = 11 },
        .{ .name = "Cb", .pc = 11 },
        .{ .name = "B#", .pc = 0 },
        .{ .name = "C", .pc = 0 },
        .{ .name = "C#", .pc = 1 },
        .{ .name = "Db", .pc = 1 },
        .{ .name = "C##", .pc = 2 },
        .{ .name = "D", .pc = 2 },
        .{ .name = "Ebb", .pc = 2 },
        .{ .name = "D#", .pc = 3 },
        .{ .name = "Eb", .pc = 3 },
        .{ .name = "D##", .pc = 4 },
        .{ .name = "E", .pc = 4 },
        .{ .name = "Fb", .pc = 4 },
        .{ .name = "E#", .pc = 5 },
        .{ .name = "F", .pc = 5 },
        .{ .name = "F#", .pc = 6 },
        .{ .name = "Gb", .pc = 6 },
        .{ .name = "F##", .pc = 7 },
        .{ .name = "G", .pc = 7 },
        .{ .name = "Abb", .pc = 7 },
        .{ .name = "G#", .pc = 8 },
        .{ .name = "Ab", .pc = 8 },
        .{ .name = "G##", .pc = 9 },
    };

    for (expected) |entry| {
        var found = false;
        for (note_name.ALL_SPELLINGS) |spelling| {
            var buf: [4]u8 = undefined;
            const text = spelling.format(&buf);
            if (std.mem.eql(u8, text, entry.name)) {
                try testing.expectEqual(entry.pc, spelling.toPitchClass());
                found = true;
                break;
            }
        }
        try testing.expect(found);
    }
}

test "spelled note converts to midi" {
    const c4 = note_name.SpelledNote{
        .name = .{ .letter = .C, .accidental = .natural },
        .octave = 4,
    };
    const a4 = note_name.SpelledNote{
        .name = .{ .letter = .A, .accidental = .natural },
        .octave = 4,
    };

    try testing.expectEqual(@as(pitch.MidiNote, 60), c4.toMidi());
    try testing.expectEqual(@as(pitch.MidiNote, 69), a4.toMidi());
}

test "interval class inversion symmetry" {
    var semitones: u4 = 0;
    while (semitones < 12) : (semitones += 1) {
        const lhs = pitch.toIntervalClass(semitones);
        const rhs = pitch.toIntervalClass(@as(u4, @intCast((12 - semitones) % 12)));
        try testing.expectEqual(lhs, rhs);
        try testing.expect(lhs <= 6);
    }

    try testing.expectEqual(@as(pitch.IntervalClass, 1), pitch.toIntervalClass(1));
    try testing.expectEqual(@as(pitch.IntervalClass, 1), pitch.toIntervalClass(11));
    try testing.expectEqual(@as(pitch.IntervalClass, 2), pitch.toIntervalClass(2));
    try testing.expectEqual(@as(pitch.IntervalClass, 2), pitch.toIntervalClass(10));
    try testing.expectEqual(@as(pitch.IntervalClass, 6), pitch.toIntervalClass(6));
}

test "formula token to semitone values" {
    try testing.expectEqual(@as(u8, 0), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.root)]);
    try testing.expectEqual(@as(u8, 1), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.flat2)]);
    try testing.expectEqual(@as(u8, 2), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat2)]);
    try testing.expectEqual(@as(u8, 3), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.sharp2)]);
    try testing.expectEqual(@as(u8, 3), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.flat3)]);
    try testing.expectEqual(@as(u8, 4), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat3)]);
    try testing.expectEqual(@as(u8, 5), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.sharp3)]);
    try testing.expectEqual(@as(u8, 6), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.flat5)]);
    try testing.expectEqual(@as(u8, 7), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat5)]);
    try testing.expectEqual(@as(u8, 8), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.sharp5)]);
    try testing.expectEqual(@as(u8, 9), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat6)]);
    try testing.expectEqual(@as(u8, 11), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat7)]);
    try testing.expectEqual(@as(u8, 12), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.sharp7)]);
    try testing.expectEqual(@as(u8, 14), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat9)]);
    try testing.expectEqual(@as(u8, 17), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat11)]);
    try testing.expectEqual(@as(u8, 21), interval.FORMULA_SEMITONES[@intFromEnum(interval.FormulaToken.nat13)]);

    try testing.expectEqual(@as(i16, 0), interval.BASE_INTERVALS[1]);
    try testing.expectEqual(@as(i16, 2), interval.BASE_INTERVALS[2]);
    try testing.expectEqual(@as(i16, 4), interval.BASE_INTERVALS[3]);
    try testing.expectEqual(@as(i16, 5), interval.BASE_INTERVALS[4]);
    try testing.expectEqual(@as(i16, 7), interval.BASE_INTERVALS[5]);
    try testing.expectEqual(@as(i16, 9), interval.BASE_INTERVALS[6]);
    try testing.expectEqual(@as(i16, 11), interval.BASE_INTERVALS[7]);
    try testing.expectEqual(@as(i16, 14), interval.BASE_INTERVALS[9]);
    try testing.expectEqual(@as(i16, 17), interval.BASE_INTERVALS[11]);
    try testing.expectEqual(@as(i16, 21), interval.BASE_INTERVALS[13]);
}
