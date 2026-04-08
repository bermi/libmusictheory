const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const mode = @import("../mode.zig");
const counterpoint = @import("../counterpoint.zig");
const keyboard = @import("../keyboard.zig");
const types = @import("types.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");
const keyboard_topology = @import("keyboard_topology.zig");

pub const PlayabilityPolicy = enum(u8) {
    balanced = 0,
    minimax_bottleneck = 1,
    cumulative_strain = 2,
};

pub const POLICY_NAMES = [_][]const u8{
    "balanced",
    "minimax-bottleneck",
    "cumulative-strain",
};

pub fn fromInt(raw: u8) ?PlayabilityPolicy {
    return switch (raw) {
        0 => .balanced,
        1 => .minimax_bottleneck,
        2 => .cumulative_strain,
        else => null,
    };
}

pub const RankedKeyboardNextStep = struct {
    candidate: counterpoint.NextStepSuggestion,
    transition: keyboard_assessment.TransitionAssessment,
    candidate_index: u8,
    hand: keyboard_assessment.HandRole,
    policy: PlayabilityPolicy,
    accepted: bool,
};

pub const RankedKeyboardContextSuggestion = struct {
    candidate: keyboard.ContextSuggestion,
    transition: keyboard_assessment.TransitionAssessment,
    realized_note: pitch.MidiNote,
    candidate_index: u8,
    hand: keyboard_assessment.HandRole,
    policy: PlayabilityPolicy,
    accepted: bool,
};

const MAX_CONTEXT_CANDIDATE_NOTES: usize = 129;

pub fn rankKeyboardNextSteps(
    history: *const counterpoint.VoicedHistoryWindow,
    profile: counterpoint.CounterpointRuleProfile,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardNextStep,
) []RankedKeyboardNextStep {
    if (out.len == 0) return out[0..0];
    const current = history.current() orelse return out[0..0];

    var theory_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const theory = counterpoint.rankNextSteps(history, profile, theory_buf[0..]);

    var current_notes_buf: [counterpoint.MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** counterpoint.MAX_VOICES;
    const current_notes = voicedStateNotes(current, &current_notes_buf);
    const previous_load = keyboardLoadBeforeCurrent(history, hand_profile);
    return rankKeyboardNextStepCandidates(current_notes, previous_load, theory, hand, hand_profile, policy, out);
}

pub fn rankKeyboardNextStepCandidates(
    current_notes: []const pitch.MidiNote,
    previous_load: ?types.TemporalLoadState,
    candidates: []const counterpoint.NextStepSuggestion,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardNextStep,
) []RankedKeyboardNextStep {
    if (out.len == 0 or candidates.len == 0) return out[0..0];

    const write_len = @min(candidates.len, out.len);
    for (candidates[0..write_len], 0..) |candidate, index| {
        const to_notes = candidate.notes[0..candidate.note_count];
        const transition = keyboard_assessment.assessTransition(current_notes, to_notes, hand, hand_profile, previous_load);
        out[index] = .{
            .candidate = candidate,
            .transition = transition,
            .candidate_index = @as(u8, @intCast(index)),
            .hand = hand,
            .policy = policy,
            .accepted = transition.blocker_bits == 0,
        };
    }

    std.sort.insertion(RankedKeyboardNextStep, out[0..write_len], policy, nextStepLessThan);
    return out[0..write_len];
}

pub fn filterNextStepsByPlayability(
    history: *const counterpoint.VoicedHistoryWindow,
    profile: counterpoint.CounterpointRuleProfile,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []counterpoint.NextStepSuggestion,
) []counterpoint.NextStepSuggestion {
    if (out.len == 0) return out[0..0];

    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]RankedKeyboardNextStep = undefined;
    const ranked = rankKeyboardNextSteps(history, profile, hand, hand_profile, policy, ranked_buf[0..]);

    var write_len: usize = 0;
    for (ranked) |row| {
        if (!row.accepted) continue;
        if (write_len >= out.len) break;
        out[write_len] = row.candidate;
        write_len += 1;
    }
    return out[0..write_len];
}

pub fn rankKeyboardContextSuggestions(
    set_value: pcs.PitchClassSet,
    midi_notes: []const pitch.MidiNote,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    previous_load: ?types.TemporalLoadState,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardContextSuggestion,
) []RankedKeyboardContextSuggestion {
    if (out.len == 0) return out[0..0];

    var theory_buf: [keyboard.MAX_CONTEXT_SUGGESTIONS]keyboard.ContextSuggestion = undefined;
    const theory = keyboard.rankContextSuggestions(set_value, midi_notes, tonic, mode_type, theory_buf[0..]);
    return rankKeyboardContextCandidates(midi_notes, previous_load, theory, hand, hand_profile, policy, out);
}

pub fn rankKeyboardContextCandidates(
    current_notes: []const pitch.MidiNote,
    previous_load: ?types.TemporalLoadState,
    candidates: []const keyboard.ContextSuggestion,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardContextSuggestion,
) []RankedKeyboardContextSuggestion {
    if (out.len == 0 or candidates.len == 0) return out[0..0];

    const anchor = currentAnchorMidi(current_notes, hand_profile, previous_load, hand);
    const write_len = @min(candidates.len, out.len);

    for (candidates[0..write_len], 0..) |candidate, index| {
        const realized_note = nearestMidiForPitchClass(candidate.pitch_class, anchor, hand);
        var to_notes_buf: [MAX_CONTEXT_CANDIDATE_NOTES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_CONTEXT_CANDIDATE_NOTES;
        const to_notes = appendRealizedNote(current_notes, realized_note, &to_notes_buf);
        const transition = keyboard_assessment.assessTransition(current_notes, to_notes, hand, hand_profile, previous_load);
        out[index] = .{
            .candidate = candidate,
            .transition = transition,
            .realized_note = realized_note,
            .candidate_index = @as(u8, @intCast(index)),
            .hand = hand,
            .policy = policy,
            .accepted = transition.blocker_bits == 0,
        };
    }

    std.sort.insertion(RankedKeyboardContextSuggestion, out[0..write_len], policy, contextSuggestionLessThan);
    return out[0..write_len];
}

fn currentAnchorMidi(
    current_notes: []const pitch.MidiNote,
    hand_profile: types.HandProfile,
    previous_load: ?types.TemporalLoadState,
    hand: keyboard_assessment.HandRole,
) pitch.MidiNote {
    if (current_notes.len == 0) return defaultAnchorForHand(hand);
    const state = keyboard_topology.describeState(current_notes, hand_profile, previous_load);
    return state.anchor_midi;
}

fn defaultAnchorForHand(hand: keyboard_assessment.HandRole) pitch.MidiNote {
    return switch (hand) {
        .left => 48,
        .right => 60,
    };
}

fn nearestMidiForPitchClass(target_pc: pitch.PitchClass, anchor: pitch.MidiNote, hand: keyboard_assessment.HandRole) pitch.MidiNote {
    const anchor_pc: pitch.PitchClass = @intCast(anchor % 12);
    const upward_delta: u8 = @intCast((@as(u8, target_pc) + 12 - @as(u8, anchor_pc)) % 12);
    const downward_delta: u8 = @intCast((@as(u8, anchor_pc) + 12 - @as(u8, target_pc)) % 12);

    const anchor_wide = @as(i16, anchor);
    const upward_note = anchor_wide + upward_delta;
    const downward_note = anchor_wide - downward_delta;
    const upward_valid = upward_note <= 127;
    const downward_valid = downward_note >= 0;

    if (!downward_valid) return @as(pitch.MidiNote, @intCast(upward_note));
    if (!upward_valid) return @as(pitch.MidiNote, @intCast(downward_note));

    if (upward_delta < downward_delta) return @as(pitch.MidiNote, @intCast(upward_note));
    if (downward_delta < upward_delta) return @as(pitch.MidiNote, @intCast(downward_note));

    return switch (hand) {
        .right => @as(pitch.MidiNote, @intCast(upward_note)),
        .left => @as(pitch.MidiNote, @intCast(downward_note)),
    };
}

fn appendRealizedNote(current_notes: []const pitch.MidiNote, realized_note: pitch.MidiNote, out: *[MAX_CONTEXT_CANDIDATE_NOTES]pitch.MidiNote) []const pitch.MidiNote {
    const copy_len = @min(current_notes.len, out.len - 1);
    @memcpy(out[0..copy_len], current_notes[0..copy_len]);

    var index: usize = 0;
    while (index < copy_len) : (index += 1) {
        if (out[index] == realized_note) return out[0..copy_len];
    }

    out[copy_len] = realized_note;
    return out[0 .. copy_len + 1];
}

fn voicedStateNotes(state: *const counterpoint.VoicedState, out: *[counterpoint.MAX_VOICES]pitch.MidiNote) []const pitch.MidiNote {
    for (state.slice(), 0..) |voice, index| {
        out[index] = voice.midi;
    }
    return out[0..state.voice_count];
}

fn keyboardLoadBeforeCurrent(history: *const counterpoint.VoicedHistoryWindow, hand_profile: types.HandProfile) ?types.TemporalLoadState {
    if (history.len < 2) return null;

    const current_index: usize = history.len - 1;
    const start_index: usize = if (current_index > 3) current_index - 3 else 0;

    var maybe_load: ?types.TemporalLoadState = null;
    var notes_buf: [counterpoint.MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** counterpoint.MAX_VOICES;
    var index: usize = start_index;
    while (index < current_index) : (index += 1) {
        const notes = voicedStateNotes(&history.states[index], &notes_buf);
        const state = keyboard_topology.describeState(notes, hand_profile, maybe_load);
        maybe_load = state.load;
    }
    return maybe_load;
}

fn warningCount(bits: u32) u32 {
    return @as(u32, @intCast(@popCount(bits)));
}

fn nextStepLessThan(policy: PlayabilityPolicy, a: RankedKeyboardNextStep, b: RankedKeyboardNextStep) bool {
    if (a.accepted != b.accepted) return a.accepted;

    switch (policy) {
        .balanced => {
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
        },
        .minimax_bottleneck => {
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
        },
        .cumulative_strain => {
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
        },
    }

    return a.candidate_index < b.candidate_index;
}

fn contextSuggestionLessThan(policy: PlayabilityPolicy, a: RankedKeyboardContextSuggestion, b: RankedKeyboardContextSuggestion) bool {
    if (a.accepted != b.accepted) return a.accepted;

    switch (policy) {
        .balanced => {
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
        },
        .minimax_bottleneck => {
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
        },
        .cumulative_strain => {
            if (a.transition.cumulative_cost != b.transition.cumulative_cost) return a.transition.cumulative_cost < b.transition.cumulative_cost;
            if (a.candidate.score != b.candidate.score) return a.candidate.score > b.candidate.score;
            if (warningCount(a.transition.warning_bits) != warningCount(b.transition.warning_bits)) {
                return warningCount(a.transition.warning_bits) < warningCount(b.transition.warning_bits);
            }
            if (a.transition.bottleneck_cost != b.transition.bottleneck_cost) return a.transition.bottleneck_cost < b.transition.bottleneck_cost;
        },
    }

    return a.candidate_index < b.candidate_index;
}

test "playability policy metadata is stable" {
    try std.testing.expectEqual(@as(?PlayabilityPolicy, .balanced), fromInt(0));
    try std.testing.expectEqual(@as(?PlayabilityPolicy, .minimax_bottleneck), fromInt(1));
    try std.testing.expectEqual(@as(?PlayabilityPolicy, .cumulative_strain), fromInt(2));
    try std.testing.expectEqual(@as(?PlayabilityPolicy, null), fromInt(9));
    try std.testing.expectEqualStrings("balanced", POLICY_NAMES[@intFromEnum(PlayabilityPolicy.balanced)]);
    try std.testing.expectEqualStrings("minimax-bottleneck", POLICY_NAMES[@intFromEnum(PlayabilityPolicy.minimax_bottleneck)]);
}
