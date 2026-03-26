const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const keyboard = @import("../keyboard.zig");

test "toggle and pitch class set extraction" {
    var state = keyboard.KeyboardState.init();

    state.toggle(60); // C4
    state.toggle(64); // E4
    state.toggle(67); // G4

    try testing.expectEqual(pcs.C_MAJOR_TRIAD, state.pitchClassSet());

    state.toggle(64);
    try testing.expectEqual(pcs.fromList(&[_]pitch.PitchClass{ pitch.pc.C, pitch.pc.G }), state.pitchClassSet());
}

test "visual state marks selected and octave equivalents" {
    var state = keyboard.KeyboardState.init();
    state.toggle(60); // C4

    const visuals = keyboard.updateKeyVisuals(state);

    const key_c3 = visuals[48 - keyboard.DEFAULT_RANGE_LOW];
    const key_c4 = visuals[60 - keyboard.DEFAULT_RANGE_LOW];
    const key_c5 = visuals[72 - keyboard.DEFAULT_RANGE_LOW];
    const key_cs4 = visuals[61 - keyboard.DEFAULT_RANGE_LOW];

    try testing.expectApproxEqAbs(@as(f32, 0.5), key_c3.opacity, 0.0001);
    try testing.expectApproxEqAbs(@as(f32, 1.0), key_c4.opacity, 0.0001);
    try testing.expectApproxEqAbs(@as(f32, 0.5), key_c5.opacity, 0.0001);
    try testing.expectApproxEqAbs(@as(f32, 0.0), key_cs4.opacity, 0.0001);
}

test "url round trip" {
    const notes = [_]pitch.MidiNote{ 60, 64, 67 };

    var buf: [64]u8 = undefined;
    const url = keyboard.notesToUrl(&notes, .sharps, &buf);

    var out: [48]pitch.MidiNote = undefined;
    const parsed = keyboard.urlToNotes(url, &out);

    try testing.expectEqual(@as(usize, 3), parsed.len);
    try testing.expectEqual(notes[0], parsed[0]);
    try testing.expectEqual(notes[1], parsed[1]);
    try testing.expectEqual(notes[2], parsed[2]);
}

test "playback style" {
    const triad = pcs.C_MAJOR_TRIAD;
    try testing.expectEqual(keyboard.PlaybackMode.simultaneous, keyboard.playbackStyle(triad));

    const diatonic = pcs.DIATONIC;
    try testing.expectEqual(keyboard.PlaybackMode.sequential, keyboard.playbackStyle(diatonic));
}

test "mode spelling quality follows modal third" {
    try testing.expectEqual(@import("../key.zig").KeyQuality.major, keyboard.modeSpellingQuality(0, .ionian));
    try testing.expectEqual(@import("../key.zig").KeyQuality.minor, keyboard.modeSpellingQuality(2, .dorian));
}

test "context suggestions stay inside selected mode first" {
    const midi_notes = [_]pitch.MidiNote{ 60, 64, 67 };
    var suggestions: [keyboard.MAX_CONTEXT_SUGGESTIONS]keyboard.ContextSuggestion = undefined;
    const ranked = keyboard.rankContextSuggestions(pcs.C_MAJOR_TRIAD, &midi_notes, pitch.pc.C, .ionian, &suggestions);

    try testing.expect(ranked.len >= 4);
    try testing.expect(ranked[0].in_context);
    try testing.expect(ranked[1].in_context);
    try testing.expect(ranked[2].in_context);
    try testing.expect(ranked[3].in_context);

    var pcs_found = [_]bool{false} ** 12;
    for (ranked[0..4]) |row| pcs_found[row.pitch_class] = true;
    try testing.expect(pcs_found[pitch.pc.D]);
    try testing.expect(pcs_found[pitch.pc.F]);
    try testing.expect(pcs_found[pitch.pc.A]);
    try testing.expect(pcs_found[pitch.pc.B]);
}
