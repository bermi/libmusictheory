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

fn makeKeyboardBranchOne(note: pitch.MidiNote, hand: playability.keyboard_assessment.HandRole) playability.phrase.KeyboardPhraseBranch {
    var branch = playability.phrase.KeyboardPhraseBranch.init();
    _ = branch.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{note}, hand));
    return branch;
}

fn makeFretBranchOne(fret: i8) playability.phrase.FretPhraseBranch {
    var branch = playability.phrase.FretPhraseBranch.init();
    _ = branch.push(playability.phrase.FretPhraseEvent.init(&[_]i8{ fret, -1, -1, -1 }));
    return branch;
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

test "committed phrase memory biases later keyboard next-step ranking" {
    var committed = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(committed.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{60}, .right)));

    const profile = playability.keyboard_topology.defaultHandProfile();
    const candidates = [_]counterpoint.NextStepSuggestion{
        makeNextStep(100, 61),
        makeNextStep(100, 73),
    };

    var before_buf: [2]playability.ranking.RankedKeyboardNextStep = undefined;
    const before = playability.ranking.rankKeyboardNextStepCandidatesFromCommittedPhrase(
        &committed,
        &candidates,
        profile,
        .cumulative_strain,
        before_buf[0..],
    );
    try testing.expectEqual(@as(u8, 0), before[0].candidate_index);

    const preview = playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right);
    _ = preview;

    var preview_buf: [2]playability.ranking.RankedKeyboardNextStep = undefined;
    const preview_ranked = playability.ranking.rankKeyboardNextStepCandidatesFromCommittedPhrase(
        &committed,
        &candidates,
        profile,
        .cumulative_strain,
        preview_buf[0..],
    );
    try testing.expectEqual(@as(u8, 0), preview_ranked[0].candidate_index);
    try testing.expectEqual(before[0].transition.cumulative_cost, preview_ranked[0].transition.cumulative_cost);

    try testing.expect(committed.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));

    var after_buf: [2]playability.ranking.RankedKeyboardNextStep = undefined;
    const after = playability.ranking.rankKeyboardNextStepCandidatesFromCommittedPhrase(
        &committed,
        &candidates,
        profile,
        .cumulative_strain,
        after_buf[0..],
    );
    try testing.expectEqual(@as(u8, 1), after[0].candidate_index);
    try testing.expectEqual(@as(u8, 0), after[1].candidate_index);
    try testing.expect(after[1].transition.cumulative_cost > before[0].transition.cumulative_cost);
    try testing.expect(after[1].transition.bottleneck_cost > before[0].transition.bottleneck_cost);
}

test "committed phrase memory resolves keyboard context suggestions from accepted anchor" {
    var committed = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(committed.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));

    var ranked_buf: [keyboard.MAX_CONTEXT_SUGGESTIONS]playability.ranking.RankedKeyboardContextSuggestion = undefined;
    const ranked = playability.ranking.rankKeyboardContextSuggestionsFromCommittedPhrase(
        &committed,
        pcs.fromList(&[_]pitch.PitchClass{0}),
        0,
        .ionian,
        playability.keyboard_topology.defaultHandProfile(),
        .balanced,
        ranked_buf[0..],
    );

    try testing.expect(ranked.len > 0);
    try testing.expect(ranked[0].realized_note >= 69);
    try testing.expect(ranked[0].realized_note <= 79);
}

test "seeded keyboard branch summary reflects committed shift pressure" {
    var committed = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(committed.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));

    const profile = playability.types.HandProfile.init(5, 12, 14, 1, 1, true);
    const branch = makeKeyboardBranchOne(48, .right);

    const standalone = playability.phrase.summarizeKeyboardBranch(&branch, profile);
    const biased = playability.phrase.summarizeKeyboardBranchAgainstCommittedPhrase(&committed, &branch, profile);
    const bias = playability.ranking.summarizeKeyboardBranchBiasFromCommittedPhrase(&committed, &branch, profile);

    try testing.expectEqual(playability.ranking.PhraseBranchClassification.playable_recovery_neutral, playability.ranking.classifyBranchSummary(standalone));
    try testing.expectEqual(playability.ranking.PhraseBranchClassification.blocked, playability.ranking.classifyBranchSummary(biased));
    try testing.expect((bias.bias_reason_bits & (@as(u32, 1) << @intFromEnum(playability.ranking.PhraseBranchBiasReason.blocked_by_committed_history))) != 0);
    try testing.expect(bias.peak_strain_delta > 0);
}

test "diagnostic reranking keeps blocked branches visible while hard filter removes them" {
    var committed = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(committed.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));

    const profile = playability.types.HandProfile.init(5, 12, 14, 1, 1, true);
    const branches = [_]playability.phrase.KeyboardPhraseBranch{
        makeKeyboardBranchOne(48, .right),
        makeKeyboardBranchOne(73, .right),
        makeKeyboardBranchOne(48, .left),
    };

    var ranked_buf: [3]playability.ranking.RankedKeyboardPhraseBranch = undefined;
    const ranked = playability.ranking.rankKeyboardPhraseBranchesFromCommittedPhrase(
        &committed,
        &branches,
        profile,
        .balanced,
        .diagnostics_keep_blocked,
        ranked_buf[0..],
    );
    try testing.expectEqual(@as(usize, 3), ranked.len);
    try testing.expectEqual(playability.ranking.PhraseBranchClassification.playable_recovery_improving, ranked[0].classification);
    try testing.expectEqual(@as(u32, 2), ranked[0].candidate_index);
    try testing.expect((ranked[0].bias.bias_reason_bits & (@as(u32, 1) << @intFromEnum(playability.ranking.PhraseBranchBiasReason.continuity_reset_from_hand_switch))) != 0);
    try testing.expectEqual(playability.ranking.PhraseBranchClassification.playable_recovery_deficit, ranked[1].classification);
    try testing.expectEqual(@as(u32, 1), ranked[1].candidate_index);
    try testing.expectEqual(playability.ranking.PhraseBranchClassification.blocked, ranked[2].classification);

    var filtered_buf: [3]playability.phrase.KeyboardPhraseBranch = undefined;
    const filtered = playability.ranking.filterBlockedKeyboardPhraseBranchesFromCommittedPhrase(
        &committed,
        &branches,
        profile,
        filtered_buf[0..],
    );
    try testing.expectEqual(@as(usize, 2), filtered.len);
    try testing.expectEqual(@as(pitch.MidiNote, 73), filtered[0].steps[0].notes[0]);
    try testing.expectEqual(playability.keyboard_assessment.HandRole.left, filtered[1].steps[0].hand);
}

test "committed phrase memory compounds fret branch strain without hard filtering until asked" {
    var committed = playability.phrase.FretCommittedPhraseMemory.init();
    try testing.expect(committed.push(playability.phrase.FretPhraseEvent.init(&[_]i8{ 3, -1, -1, -1 })));
    try testing.expect(committed.push(playability.phrase.FretPhraseEvent.init(&[_]i8{ 10, -1, -1, -1 })));

    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const hand = playability.types.HandProfile.init(4, 4, 5, 1, 3, true);
    const branches = [_]playability.phrase.FretPhraseBranch{
        makeFretBranchOne(12),
        makeFretBranchOne(2),
    };

    var ranked_buf: [2]playability.ranking.RankedFretPhraseBranch = undefined;
    const ranked = playability.ranking.rankFretPhraseBranchesFromCommittedPhrase(
        &committed,
        &branches,
        &tuning,
        .generic_guitar,
        hand,
        .cumulative_strain,
        .diagnostics_keep_blocked,
        ranked_buf[0..],
    );
    try testing.expectEqual(@as(usize, 2), ranked.len);
    try testing.expect(ranked[0].summary.deficit_window_count <= ranked[1].summary.deficit_window_count);

    var filtered_buf: [2]playability.phrase.FretPhraseBranch = undefined;
    const filtered = playability.ranking.filterBlockedFretPhraseBranchesFromCommittedPhrase(
        &committed,
        &branches,
        &tuning,
        .generic_guitar,
        hand,
        filtered_buf[0..],
    );
    try testing.expectEqual(@as(usize, 1), filtered.len);
}
