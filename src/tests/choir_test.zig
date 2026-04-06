const testing = @import("std").testing;

const choir = @import("../choir.zig");
const counterpoint = @import("../counterpoint.zig");
const pitch = @import("../pitch.zig");

test "satb ranges match standard textbook bounds" {
    try testing.expectEqual(@as(pitch.MidiNote, 60), choir.rangeLow(.soprano));
    try testing.expectEqual(@as(pitch.MidiNote, 81), choir.rangeHigh(.soprano));
    try testing.expectEqual(@as(pitch.MidiNote, 55), choir.rangeLow(.alto));
    try testing.expectEqual(@as(pitch.MidiNote, 76), choir.rangeHigh(.alto));
    try testing.expectEqual(@as(pitch.MidiNote, 48), choir.rangeLow(.tenor));
    try testing.expectEqual(@as(pitch.MidiNote, 69), choir.rangeHigh(.tenor));
    try testing.expectEqual(@as(pitch.MidiNote, 40), choir.rangeLow(.bass));
    try testing.expectEqual(@as(pitch.MidiNote, 64), choir.rangeHigh(.bass));
}

test "satb range membership is inclusive at boundaries" {
    try testing.expect(choir.rangeContains(.bass, 40));
    try testing.expect(choir.rangeContains(.bass, 64));
    try testing.expect(!choir.rangeContains(.bass, 39));
    try testing.expect(!choir.rangeContains(.bass, 65));
    try testing.expect(choir.rangeContains(.alto, 55));
    try testing.expect(choir.rangeContains(.alto, 76));
}

test "satb register checker flags out of range four-part voices" {
    const state = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 36 },
        .{ .id = 1, .midi = 50 },
        .{ .id = 2, .midi = 57 },
        .{ .id = 3, .midi = 84 },
    });

    var violations: [choir.MAX_REGISTER_VIOLATIONS]choir.RegisterViolation = undefined;
    const total = choir.checkRegisters(&state, violations[0..]);
    try testing.expectEqual(@as(u8, 2), total);
    try testing.expectEqual(choir.SatbVoice.bass, violations[0].satb_voice);
    try testing.expectEqual(@as(i8, -1), violations[0].direction);
    try testing.expectEqual(@as(pitch.MidiNote, 40), violations[0].low);
    try testing.expectEqual(choir.SatbVoice.soprano, violations[1].satb_voice);
    try testing.expectEqual(@as(i8, 1), violations[1].direction);
    try testing.expectEqual(@as(pitch.MidiNote, 81), violations[1].high);
}

test "satb register checker ignores non four-part states" {
    const triad = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 48 },
        .{ .id = 1, .midi = 55 },
        .{ .id = 2, .midi = 60 },
    });
    var violations: [choir.MAX_REGISTER_VIOLATIONS]choir.RegisterViolation = undefined;
    try testing.expectEqual(@as(u8, 0), choir.checkRegisters(&triad, violations[0..]));
}

const ManualVoice = struct {
    id: u8,
    midi: pitch.MidiNote,
};

fn manualState(voices: []const ManualVoice) counterpoint.VoicedState {
    var state = counterpoint.VoicedState.initEmpty(0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0));
    state.voice_count = @intCast(voices.len);
    var set_value: u12 = 0;
    for (voices, 0..) |voice, index| {
        state.voices[index] = .{
            .id = voice.id,
            .midi = voice.midi,
            .pitch_class = pitch.midiToPC(voice.midi),
            .octave = pitch.midiToOctave(voice.midi),
            .sustained = false,
        };
        set_value |= @as(u12, 1) << state.voices[index].pitch_class;
    }
    state.set_value = set_value;
    return state;
}
