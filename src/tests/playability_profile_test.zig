const std = @import("std");
const testing = std.testing;
const pitch = @import("../pitch.zig");
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
        .set_value = 0,
        .notes = notes,
        .motion = emptyMotion(),
        .evaluation = emptyEvaluation(),
    };
}

test "applyPreset preserves finger count and changes comfort windows explicitly" {
    const base = playability.keyboard_topology.defaultHandProfile();
    const compact = playability.profile.applyPreset(base, .compact_beginner);
    const span_tolerant = playability.profile.applyPreset(base, .span_tolerant);
    const shift_tolerant = playability.profile.applyPreset(base, .shift_tolerant);

    try testing.expectEqual(base.finger_count, compact.finger_count);
    try testing.expect(compact.prefers_low_tension);
    try testing.expect(compact.comfort_span_steps < base.comfort_span_steps);
    try testing.expect(span_tolerant.limit_span_steps > base.limit_span_steps);
    try testing.expect(shift_tolerant.limit_shift_steps > base.limit_shift_steps);
}

test "keyboard difficulty summary exposes headroom margins" {
    const base = playability.keyboard_topology.defaultHandProfile();
    const compact = playability.profile.applyPreset(base, .compact_beginner);
    const from_notes = [_]pitch.MidiNote{60};
    const to_notes = [_]pitch.MidiNote{72};
    const transition = playability.keyboard_assessment.assessTransition(&from_notes, &to_notes, .right, compact, null);
    const summary = playability.profile.summarizeKeyboardTransition(transition, compact);

    try testing.expect(!summary.accepted);
    try testing.expect(summary.blocker_count > 0);
    try testing.expect(summary.limit_shift_margin < 0);
    try testing.expectEqual(transition.anchor_delta_semitones, summary.shift_steps);
}

test "safer keyboard next-step helper returns first accepted candidate" {
    const profile = playability.profile.applyPreset(
        playability.keyboard_topology.defaultHandProfile(),
        .compact_beginner,
    );
    const current_notes = [_]pitch.MidiNote{60};
    const candidates = [_]counterpoint.NextStepSuggestion{
        makeNextStep(400, 62),
        makeNextStep(100, 61),
        makeNextStep(300, 58),
    };

    const suggestion = playability.profile.suggestSaferKeyboardNextStepCandidates(
        &current_notes,
        null,
        &candidates,
        .right,
        profile,
        .balanced,
    ) orelse return error.TestUnexpectedResult;

    try testing.expect(suggestion.accepted);
    try testing.expectEqual(@as(u8, 0), suggestion.candidate_index);
}
