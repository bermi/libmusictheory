const std = @import("std");
const testing = std.testing;
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const keyboard = @import("../keyboard.zig");
const counterpoint = @import("../counterpoint.zig");
const playability = @import("../playability.zig");

fn emptyMotion() counterpoint.MotionSummary {
    return counterpoint.MotionSummary.init();
}

fn emptyEvaluation() counterpoint.MotionEvaluation {
    return .{
        .score = 0,
        .preferred_score = 0,
        .penalty_score = 0,
        .cadence_score = 0,
        .spacing_penalty = 0,
        .leap_penalty = 0,
        .disallowed_count = 0,
        .disallowed = false,
    };
}

fn makeNextStep(score: i32, note: pitch.MidiNote) counterpoint.NextStepSuggestion {
    var notes = [_]pitch.MidiNote{0} ** counterpoint.MAX_VOICES;
    notes[0] = note;
    return .{
        .score = score,
        .reason_mask = 0,
        .warning_mask = 0,
        .cadence_effect = .none,
        .tension_delta = 0,
        .note_count = 1,
        .set_value = pcs.fromList(&[_]pitch.PitchClass{@intCast(note % 12)}),
        .notes = notes,
        .motion = emptyMotion(),
        .evaluation = emptyEvaluation(),
    };
}

fn makeContextSuggestion(score: i32, pc: pitch.PitchClass) keyboard.ContextSuggestion {
    return .{
        .pitch_class = pc,
        .expanded_set = pcs.fromList(&[_]pitch.PitchClass{pc}),
        .score = score,
        .in_context = true,
        .overlap = 1,
        .outside_count = 0,
        .cluster_free = true,
        .reads_as_named_chord = false,
    };
}

test "keyboard next-step ranking keeps accepted candidates ahead of blocked ones" {
    const profile = playability.types.HandProfile.init(5, 12, 14, 1, 1, true);
    const current_notes = [_]pitch.MidiNote{60};
    const candidates = [_]counterpoint.NextStepSuggestion{
        makeNextStep(400, 62),
        makeNextStep(100, 61),
        makeNextStep(300, 58),
    };

    var ranked_buf: [3]playability.ranking.RankedKeyboardNextStep = undefined;
    const ranked = playability.ranking.rankKeyboardNextStepCandidates(
        &current_notes,
        null,
        &candidates,
        .right,
        profile,
        .balanced,
        ranked_buf[0..],
    );

    try testing.expectEqual(@as(usize, 3), ranked.len);
    try testing.expect(ranked[0].accepted);
    try testing.expectEqual(@as(u8, 1), ranked[0].candidate_index);
    try testing.expect(!ranked[1].accepted);
    try testing.expect(!ranked[2].accepted);
}

test "keyboard next-step policies change ordering among accepted candidates" {
    const profile = playability.keyboard_topology.defaultHandProfile();
    const current_notes = [_]pitch.MidiNote{60};
    const candidates = [_]counterpoint.NextStepSuggestion{
        makeNextStep(500, 64),
        makeNextStep(100, 61),
    };

    var balanced_buf: [2]playability.ranking.RankedKeyboardNextStep = undefined;
    const balanced = playability.ranking.rankKeyboardNextStepCandidates(
        &current_notes,
        null,
        &candidates,
        .right,
        profile,
        .balanced,
        balanced_buf[0..],
    );
    try testing.expectEqual(@as(u8, 0), balanced[0].candidate_index);

    var minimax_buf: [2]playability.ranking.RankedKeyboardNextStep = undefined;
    const minimax = playability.ranking.rankKeyboardNextStepCandidates(
        &current_notes,
        null,
        &candidates,
        .right,
        profile,
        .minimax_bottleneck,
        minimax_buf[0..],
    );
    try testing.expectEqual(@as(u8, 1), minimax[0].candidate_index);
}

test "keyboard context candidate ranking resolves register ties by hand" {
    const profile = playability.keyboard_topology.defaultHandProfile();
    const current_notes = [_]pitch.MidiNote{60};
    const candidates = [_]keyboard.ContextSuggestion{makeContextSuggestion(200, 6)};

    var right_buf: [1]playability.ranking.RankedKeyboardContextSuggestion = undefined;
    const right_ranked = playability.ranking.rankKeyboardContextCandidates(
        &current_notes,
        null,
        &candidates,
        .right,
        profile,
        .balanced,
        right_buf[0..],
    );
    try testing.expectEqual(@as(usize, 1), right_ranked.len);
    try testing.expectEqual(@as(u8, 66), right_ranked[0].realized_note);

    var left_buf: [1]playability.ranking.RankedKeyboardContextSuggestion = undefined;
    const left_ranked = playability.ranking.rankKeyboardContextCandidates(
        &current_notes,
        null,
        &candidates,
        .left,
        profile,
        .balanced,
        left_buf[0..],
    );
    try testing.expectEqual(@as(usize, 1), left_ranked.len);
    try testing.expectEqual(@as(u8, 54), left_ranked[0].realized_note);
}

test "keyboard next-step filtering returns only accepted candidates" {
    var history = counterpoint.VoicedHistoryWindow.init();
    _ = history.push(&[_]pitch.MidiNote{60}, &[_]pitch.MidiNote{}, 0, .ionian, counterpoint.MetricPosition.normalized(0, 4, 0), .stable);

    const strict_profile = playability.types.HandProfile.init(5, 12, 14, 1, 1, true);
    var filtered_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const filtered = playability.ranking.filterNextStepsByPlayability(
        &history,
        .species,
        .right,
        strict_profile,
        .balanced,
        filtered_buf[0..],
    );

    try testing.expectEqual(@as(usize, 2), filtered.len);
    try testing.expectEqual(@as(u8, 1), filtered[0].note_count);
    try testing.expectEqual(@as(u8, 59), filtered[0].notes[0]);
    try testing.expectEqual(@as(u8, 61), filtered[1].notes[0]);
}
