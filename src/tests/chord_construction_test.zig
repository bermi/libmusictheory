const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const chord_type = @import("../chord_type.zig");
const chord = @import("../chord_construction.zig");

test "triad chord types" {
    try testing.expectEqual(pcs.C_MAJOR_TRIAD, chord_type.MAJOR.pcs);
    try testing.expectEqual(pcs.C_MINOR_TRIAD, chord_type.MINOR.pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 }), chord_type.DIMINISHED.pcs);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 }), chord_type.AUGMENTED.pcs);
}

test "formula parsing and naming" {
    const from_formula = chord.formulaToPCS("1 3 5");
    try testing.expectEqual(pcs.C_MAJOR_TRIAD, from_formula);

    const from_minor = chord.formulaToPCS("1 b3 5");
    try testing.expectEqual(pcs.C_MINOR_TRIAD, from_minor);

    try testing.expectEqualStrings("Major", chord.pcsToChordName(pcs.C_MAJOR_TRIAD).?);
    try testing.expectEqualStrings("Minor", chord.pcsToChordName(pcs.C_MINOR_TRIAD).?);
}

test "shell chords and inversions" {
    const cmaj7 = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 });
    const shell = chord.shellChord(cmaj7, 0);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 11 }), shell);

    try testing.expectEqual(chord.Inversion.root_position, chord.detectInversion(0, pcs.C_MAJOR_TRIAD));
    try testing.expectEqual(chord.Inversion.first, chord.detectInversion(4, pcs.C_MAJOR_TRIAD));
    try testing.expectEqual(chord.Inversion.second, chord.detectInversion(7, pcs.C_MAJOR_TRIAD));
}

test "leave one out" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 });
    var out: [12]pcs.PitchClassSet = undefined;
    const subsets = chord.leaveOneOut(set, &out);
    try testing.expectEqual(@as(usize, 3), subsets.len);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 4, 7 }), subsets[0]);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 7 }), subsets[1]);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ 0, 4 }), subsets[2]);
}

test "the game counts" {
    const stats = chord.computeGameStats();
    try testing.expectEqual(@as(u16, 2048), stats.otc_count);
    try testing.expectEqual(@as(u16, 1969), stats.card_3_to_9_count);
    try testing.expectEqual(@as(u16, 560), stats.cluster_free_count);
    try testing.expectEqual(@as(u16, 455), stats.mode_subset_count);
}
