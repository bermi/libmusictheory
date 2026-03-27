const testing = @import("std").testing;

const counterpoint = @import("../counterpoint.zig");
const pitch = @import("../pitch.zig");

test "voiced state assigns deterministic ids across insertion and deletion" {
    var history = counterpoint.VoicedHistoryWindow.init();

    const first = history.push(&[_]pitch.MidiNote{ 60, 64, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), null);
    try testing.expectEqual(@as(u8, 3), first.voice_count);
    try testing.expectEqual(@as(u8, 0), first.voices[0].id);
    try testing.expectEqual(@as(u8, 1), first.voices[1].id);
    try testing.expectEqual(@as(u8, 2), first.voices[2].id);

    const second = history.push(&[_]pitch.MidiNote{ 59, 60, 64, 67 }, &[_]pitch.MidiNote{59}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), null);
    try testing.expectEqual(@as(u8, 4), second.voice_count);
    try testing.expectEqual(@as(u8, 3), second.voices[0].id);
    try testing.expectEqual(@as(u8, 0), second.voices[1].id);
    try testing.expectEqual(@as(u8, 1), second.voices[2].id);
    try testing.expectEqual(@as(u8, 2), second.voices[3].id);
    try testing.expect(second.voices[0].sustained);

    const third = history.push(&[_]pitch.MidiNote{ 60, 65, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(2, 4, 0), null);
    try testing.expectEqual(@as(u8, 3), third.voice_count);
    try testing.expectEqual(@as(u8, 0), third.voices[0].id);
    try testing.expectEqual(@as(u8, 1), third.voices[1].id);
    try testing.expectEqual(@as(u8, 2), third.voices[2].id);
}

test "history keeps the last four voiced states" {
    var history = counterpoint.VoicedHistoryWindow.init();

    _ = history.push(&[_]pitch.MidiNote{60}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), null);
    _ = history.push(&[_]pitch.MidiNote{62}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), null);
    _ = history.push(&[_]pitch.MidiNote{64}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(2, 4, 0), null);
    _ = history.push(&[_]pitch.MidiNote{65}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(3, 4, 0), null);
    const fifth = history.push(&[_]pitch.MidiNote{67}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), null);

    try testing.expectEqual(@as(u8, counterpoint.HISTORY_CAPACITY), history.len);
    try testing.expectEqual(@as(pitch.MidiNote, 62), history.states[0].voices[0].midi);
    try testing.expectEqual(@as(pitch.MidiNote, 67), fifth.voices[0].midi);
    try testing.expectEqual(@as(u8, 4), fifth.state_index);
}

test "cadence inference reflects dominant and arrival states" {
    const dominant = counterpoint.buildVoicedState(&[_]pitch.MidiNote{ 55, 59, 62, 65 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(2, 4, 0), null, null, 0);
    try testing.expectEqual(counterpoint.CadenceState.dominant, dominant.cadence_state);

    const arrival = counterpoint.buildVoicedState(&[_]pitch.MidiNote{ 60, 64, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(3, 4, 0), null, null, 0);
    try testing.expectEqual(counterpoint.CadenceState.authentic_arrival, arrival.cadence_state);
}
