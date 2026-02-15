const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const key_signature = @import("../key_signature.zig");
const key = @import("../key.zig");
const note_spelling = @import("../note_spelling.zig");

test "major key signatures count and accidental counts" {
    try testing.expectEqual(@as(usize, 15), key_signature.MAJOR_SIGNATURES.len);

    try testing.expectEqual(@as(u4, 0), key_signature.fromTonic(pitch.pc.C, .major).count);
    try testing.expectEqual(@as(u4, 1), key_signature.fromTonic(pitch.pc.G, .major).count);
    try testing.expectEqual(@as(u4, 2), key_signature.fromTonic(pitch.pc.D, .major).count);
    try testing.expectEqual(@as(u4, 1), key_signature.fromTonic(pitch.pc.F, .major).count);
    try testing.expectEqual(@as(u4, 3), key_signature.fromTonic(pitch.pc.Ds, .major).count); // Eb
}

test "relative and parallel keys" {
    const c_major = key.Key.init(pitch.pc.C, .major);
    const a_minor = c_major.relativeMinor();
    try testing.expectEqual(pitch.pc.A, a_minor.tonic);
    try testing.expectEqual(key.KeyQuality.minor, a_minor.quality);

    const g_major = key.Key.init(pitch.pc.G, .major);
    const e_minor = g_major.relativeMinor();
    try testing.expectEqual(pitch.pc.E, e_minor.tonic);

    const c_minor = c_major.parallelKey();
    try testing.expectEqual(pitch.pc.C, c_minor.tonic);
    try testing.expectEqual(key.KeyQuality.minor, c_minor.quality);
}

test "circle of fifths cycle" {
    var k = key.Key.init(pitch.pc.C, .major);
    const expected = [_]pitch.PitchClass{ pitch.pc.G, pitch.pc.D, pitch.pc.A, pitch.pc.E, pitch.pc.B, pitch.pc.Fs, pitch.pc.Cs, pitch.pc.Gs, pitch.pc.Ds, pitch.pc.As, pitch.pc.F, pitch.pc.C };

    for (expected) |pc| {
        k = k.nextKeySharp();
        try testing.expectEqual(pc, k.tonic);
    }
}

test "note spelling in key context" {
    const g_major = key.Key.init(pitch.pc.G, .major);
    const db_major = key.Key.init(pitch.pc.Cs, .major);

    var g_buf: [4]u8 = undefined;
    const g_name = note_spelling.spellNote(pitch.pc.Fs, g_major).format(&g_buf);
    try testing.expectEqualStrings("F#", g_name);

    var db_buf: [4]u8 = undefined;
    const db_name = note_spelling.spellNote(pitch.pc.Fs, db_major).format(&db_buf);
    try testing.expectEqualStrings("Gb", db_name);
}

test "auto spell basic triad" {
    const notes = [_]pitch.PitchClass{ 0, 4, 7 };
    var spelled: [3]note_spelling.SpellingResult = undefined;
    const result = note_spelling.autoSpell(&notes, .sharps, &spelled);

    try testing.expectEqual(pitch.pc.C, result.key_tonic);

    var b0: [4]u8 = undefined;
    var b1: [4]u8 = undefined;
    var b2: [4]u8 = undefined;
    try testing.expectEqualStrings("C", result.names[0].format(&b0));
    try testing.expectEqualStrings("E", result.names[1].format(&b1));
    try testing.expectEqualStrings("G", result.names[2].format(&b2));
}
