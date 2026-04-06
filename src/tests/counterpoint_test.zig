const std = @import("std");
const testing = std.testing;

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

test "motion classifier distinguishes contrary parallel and oblique motion" {
    const previous = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 67 },
    }, .stable);

    const contrary = manualState(&[_]ManualVoice{
        .{ .id = 1, .midi = 65 },
        .{ .id = 0, .midi = 62 },
    }, .dominant);
    const contrary_summary = counterpoint.classifyMotion(&previous, &contrary);
    try testing.expectEqual(@as(u8, 1), contrary_summary.contrary_count);
    try testing.expectEqual(counterpoint.PairMotionClass.contrary, contrary_summary.outer_motion);
    try testing.expectEqual(@as(u8, 2), contrary_summary.step_count);

    const parallel = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 69 },
    }, .stable);
    const parallel_summary = counterpoint.classifyMotion(&previous, &parallel);
    try testing.expectEqual(@as(u8, 1), parallel_summary.parallel_count);
    try testing.expectEqual(counterpoint.PairMotionClass.parallel, parallel_summary.outer_motion);

    const oblique = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 69 },
    }, .stable);
    const oblique_summary = counterpoint.classifyMotion(&previous, &oblique);
    try testing.expectEqual(@as(u8, 1), oblique_summary.common_tone_count);
    try testing.expectEqual(@as(u8, 1), oblique_summary.oblique_count);
}

test "motion classifier detects crossing overlap and leaps" {
    const previous = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 64 },
    }, .stable);
    const crossing = manualState(&[_]ManualVoice{
        .{ .id = 1, .midi = 62 },
        .{ .id = 0, .midi = 67 },
    }, .dominant);

    const crossing_summary = counterpoint.classifyMotion(&previous, &crossing);
    try testing.expectEqual(@as(u8, 1), crossing_summary.crossing_count);
    try testing.expectEqual(@as(u8, 0), crossing_summary.overlap_count);
    try testing.expectEqual(@as(u8, 1), crossing_summary.step_count);
    try testing.expectEqual(@as(u8, 1), crossing_summary.leap_count);

    const overlap = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 65 },
        .{ .id = 1, .midi = 70 },
    }, .dominant);
    const overlap_summary = counterpoint.classifyMotion(&previous, &overlap);
    try testing.expectEqual(@as(u8, 0), overlap_summary.crossing_count);
    try testing.expectEqual(@as(u8, 1), overlap_summary.overlap_count);
}

test "counterpoint rule profiles alter evaluation outcomes" {
    const previous = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 67 },
    }, .dominant);
    const current = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 69 },
    }, .authentic_arrival);

    const summary = counterpoint.classifyMotion(&previous, &current);
    const species_eval = counterpoint.evaluateMotionProfile(summary, .species);
    const jazz_eval = counterpoint.evaluateMotionProfile(summary, .jazz_close_leading);

    try testing.expect(species_eval.disallowed);
    try testing.expect(species_eval.disallowed_count > 0);
    try testing.expect(jazz_eval.score > species_eval.score);
}

test "next step ranker changes candidate preference by profile" {
    var history = counterpoint.VoicedHistoryWindow.init();
    _ = history.push(&[_]pitch.MidiNote{ 60, 64 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);

    var species_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    var jazz_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const species = counterpoint.rankNextSteps(&history, .species, species_buf[0..]);
    const jazz = counterpoint.rankNextSteps(&history, .jazz_close_leading, jazz_buf[0..]);

    const contrary_species = findSuggestionByNotes(species, &[_]pitch.MidiNote{ 59, 65 }).?;
    const oblique_species = findSuggestionByNotes(species, &[_]pitch.MidiNote{ 60, 65 }).?;
    const contrary_jazz = findSuggestionByNotes(jazz, &[_]pitch.MidiNote{ 59, 65 }).?;
    const oblique_jazz = findSuggestionByNotes(jazz, &[_]pitch.MidiNote{ 60, 65 }).?;

    try testing.expect(contrary_species.score > oblique_species.score);
    try testing.expect(oblique_jazz.score >= contrary_jazz.score);
}

test "next step ranker uses temporal memory for leap compensation" {
    var full_history = counterpoint.VoicedHistoryWindow.init();
    _ = full_history.push(&[_]pitch.MidiNote{ 60, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);
    _ = full_history.push(&[_]pitch.MidiNote{ 64, 69 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), .dominant);

    var short_history = counterpoint.VoicedHistoryWindow.init();
    _ = short_history.push(&[_]pitch.MidiNote{ 64, 69 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), .dominant);

    var full_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    var short_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const ranked_full = counterpoint.rankNextSteps(&full_history, .species, full_buf[0..]);
    const ranked_short = counterpoint.rankNextSteps(&short_history, .species, short_buf[0..]);

    const with_memory = findSuggestionByNotes(ranked_full, &[_]pitch.MidiNote{ 62, 69 }).?;
    const without_memory = findSuggestionByNotes(ranked_short, &[_]pitch.MidiNote{ 62, 69 }).?;

    try testing.expect((with_memory.reason_mask & counterpoint.NEXT_STEP_REASON_LEAP_COMPENSATION) != 0);
    try testing.expect(with_memory.score > without_memory.score);
}

test "cadence destination ranking keeps current cadence pressure visible" {
    var history = counterpoint.VoicedHistoryWindow.init();
    _ = history.push(&[_]pitch.MidiNote{ 60, 64, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);
    _ = history.push(&[_]pitch.MidiNote{ 55, 59, 62, 65 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(2, 4, 0), .dominant);

    var buf: [counterpoint.MAX_CADENCE_DESTINATIONS]counterpoint.CadenceDestinationScore = undefined;
    const ranked = counterpoint.rankCadenceDestinations(&history, .species, buf[0..]);

    try testing.expect(ranked.len > 0);
    try testing.expectEqual(counterpoint.CadenceDestination.dominant_arrival, ranked[0].destination);
    try testing.expect(ranked[0].current_match);
    try testing.expect(ranked[0].score >= ranked[1].score);
}

test "suspension machine detects held and resolving voices across history" {
    var held_history = counterpoint.VoicedHistoryWindow.init();
    _ = held_history.push(&[_]pitch.MidiNote{ 60, 64, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);
    _ = held_history.push(&[_]pitch.MidiNote{ 60, 65, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), .dominant);

    const held = counterpoint.analyzeSuspensionMachine(&held_history, .species);
    try testing.expect(held.state != .none);
    try testing.expect(held.tracked_voice_id != 255);
    try testing.expectEqual(@as(u8, 1), held.obligation_count);
    try testing.expectEqual(@as(u8, 67), held.held_midi);
    try testing.expect(held.candidate_resolution_count > 0);

    var resolving_history = counterpoint.VoicedHistoryWindow.init();
    _ = resolving_history.push(&[_]pitch.MidiNote{ 60, 64, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);
    _ = resolving_history.push(&[_]pitch.MidiNote{ 60, 65, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(1, 4, 0), .dominant);
    _ = resolving_history.push(&[_]pitch.MidiNote{ 59, 65, 67 }, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(2, 4, 0), .stable);

    const resolved = counterpoint.analyzeSuspensionMachine(&resolving_history, .species);
    try testing.expectEqual(counterpoint.SuspensionState.resolution, resolved.state);
    try testing.expectEqual(@as(u8, 0), resolved.tracked_voice_id);
    try testing.expectEqual(@as(u8, 60), resolved.held_midi);
    try testing.expectEqual(@as(u8, 59), resolved.expected_resolution_midi);
    try testing.expectEqual(@as(i8, -1), resolved.resolution_direction);
}

const ManualVoice = struct {
    id: u8,
    midi: pitch.MidiNote,
};

fn manualState(voices: []const ManualVoice, cadence_state: counterpoint.CadenceState) counterpoint.VoicedState {
    var state = counterpoint.VoicedState.initEmpty(0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0));
    state.cadence_state = cadence_state;
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

fn findSuggestionByNotes(suggestions: []const counterpoint.NextStepSuggestion, expected: []const pitch.MidiNote) ?counterpoint.NextStepSuggestion {
    for (suggestions) |suggestion| {
        if (suggestion.note_count != expected.len) continue;
        if (std.mem.eql(pitch.MidiNote, suggestion.notes[0..expected.len], expected)) return suggestion;
    }
    return null;
}
