const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const key = @import("../key.zig");
const harmony = @import("../harmony.zig");

fn expectRoman(expected: []const u8, rn: harmony.RomanNumeral) !void {
    var buf: [16]u8 = undefined;
    const s = rn.format(&buf);
    try testing.expectEqualStrings(expected, s);
}

test "diatonic triads and sevenths in C major" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    const expected_triads = [_]pcs.PitchClassSet{
        pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 }),
        pcs.fromList(&[_]pitch.PitchClass{ 2, 5, 9 }),
        pcs.fromList(&[_]pitch.PitchClass{ 4, 7, 11 }),
        pcs.fromList(&[_]pitch.PitchClass{ 5, 9, 0 }),
        pcs.fromList(&[_]pitch.PitchClass{ 7, 11, 2 }),
        pcs.fromList(&[_]pitch.PitchClass{ 9, 0, 4 }),
        pcs.fromList(&[_]pitch.PitchClass{ 11, 2, 5 }),
    };

    const expected_sevenths = [_]pcs.PitchClassSet{
        pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 }),
        pcs.fromList(&[_]pitch.PitchClass{ 2, 5, 9, 0 }),
        pcs.fromList(&[_]pitch.PitchClass{ 4, 7, 11, 2 }),
        pcs.fromList(&[_]pitch.PitchClass{ 5, 9, 0, 4 }),
        pcs.fromList(&[_]pitch.PitchClass{ 7, 11, 2, 5 }),
        pcs.fromList(&[_]pitch.PitchClass{ 9, 0, 4, 7 }),
        pcs.fromList(&[_]pitch.PitchClass{ 11, 2, 5, 9 }),
    };

    var degree: u4 = 1;
    while (degree <= 7) : (degree += 1) {
        const triad = harmony.diatonicTriad(c_major, degree);
        const seventh = harmony.diatonicSeventh(c_major, degree);

        try testing.expectEqual(expected_triads[degree - 1], triad.pcs);
        try testing.expectEqual(expected_sevenths[degree - 1], seventh.pcs);
    }

    const all = harmony.DiatonicHarmony.init(c_major);
    try testing.expectEqual(expected_triads[0], all.triads[0].pcs);
    try testing.expectEqual(expected_triads[6], all.triads[6].pcs);
    try testing.expectEqual(expected_sevenths[0], all.sevenths[0].pcs);
    try testing.expectEqual(expected_sevenths[6], all.sevenths[6].pcs);
}

test "roman numerals for major and minor keys" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    try expectRoman("I", harmony.romanNumeral(harmony.diatonicTriad(c_major, 1), c_major));
    try expectRoman("ii", harmony.romanNumeral(harmony.diatonicTriad(c_major, 2), c_major));
    try expectRoman("iii", harmony.romanNumeral(harmony.diatonicTriad(c_major, 3), c_major));
    try expectRoman("IV", harmony.romanNumeral(harmony.diatonicTriad(c_major, 4), c_major));
    try expectRoman("V", harmony.romanNumeral(harmony.diatonicTriad(c_major, 5), c_major));
    try expectRoman("vi", harmony.romanNumeral(harmony.diatonicTriad(c_major, 6), c_major));
    try expectRoman("vii°", harmony.romanNumeral(harmony.diatonicTriad(c_major, 7), c_major));

    try expectRoman("Imaj7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 1), c_major));
    try expectRoman("ii7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 2), c_major));
    try expectRoman("iii7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 3), c_major));
    try expectRoman("IVmaj7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 4), c_major));
    try expectRoman("V7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 5), c_major));
    try expectRoman("vi7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 6), c_major));
    try expectRoman("viiø7", harmony.romanNumeral(harmony.diatonicSeventh(c_major, 7), c_major));

    const a_minor = key.Key.init(pitch.pc.A, .minor);
    try expectRoman("i", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 1), a_minor));
    try expectRoman("ii°", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 2), a_minor));
    try expectRoman("III", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 3), a_minor));
    try expectRoman("iv", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 4), a_minor));
    try expectRoman("v", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 5), a_minor));
    try expectRoman("VI", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 6), a_minor));
    try expectRoman("VII", harmony.romanNumeral(harmony.diatonicTriad(a_minor, 7), a_minor));
}

test "chord-scale compatibility and avoid notes" {
    const c_major = key.Key.init(pitch.pc.C, .major);
    const scale = harmony.keyScaleSet(c_major);

    const d_m7 = harmony.diatonicSeventh(c_major, 2);
    const d_dorian = harmony.ModeContext{ .root = pitch.pc.D, .pcs = scale };
    const dorian_match = harmony.chordScaleCompatibility(d_m7, d_dorian);
    try testing.expect(dorian_match.compatible);

    const c_maj7 = harmony.diatonicSeventh(c_major, 1);
    const c_ionian = harmony.ModeContext{ .root = pitch.pc.C, .pcs = scale };
    const ionian_match = harmony.chordScaleCompatibility(c_maj7, c_ionian);
    try testing.expect(ionian_match.compatible);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{pitch.pc.F}), ionian_match.avoid_notes);

    const g7 = harmony.diatonicSeventh(c_major, 5);
    const g_mixolydian = harmony.ModeContext{ .root = pitch.pc.G, .pcs = scale };
    const mixolydian_match = harmony.chordScaleCompatibility(g7, g_mixolydian);
    try testing.expect(mixolydian_match.compatible);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{pitch.pc.C}), mixolydian_match.avoid_notes);

    const f_maj7 = harmony.diatonicSeventh(c_major, 4);
    const f_lydian = harmony.ModeContext{ .root = pitch.pc.F, .pcs = scale };
    const lydian_match = harmony.chordScaleCompatibility(f_maj7, f_lydian);
    try testing.expect(lydian_match.compatible);
    try testing.expectEqual(@as(pcs.PitchClassSet, 0), lydian_match.avoid_notes);
}

test "tritone substitution and diatonic circuits" {
    const c_major = key.Key.init(pitch.pc.C, .major);
    const g7 = harmony.diatonicSeventh(c_major, 5);
    const sub = harmony.tritoneSub(g7);

    try testing.expectEqual(pitch.pc.Cs, sub.root); // Db7
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 1, 5, 8, 11 }), sub.pcs);

    try testing.expectEqualSlices(u4, &[_]u4{ 7, 3, 6, 2, 5, 1, 4 }, &harmony.CIRCLE_OF_FIFTHS_DEGREES);
    try testing.expectEqualSlices(u4, &[_]u4{ 1, 6, 4, 2, 7, 5, 3 }, &harmony.CIRCLE_OF_THIRDS_DEGREES);
}
