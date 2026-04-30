const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const mode = @import("../mode.zig");
const counterpoint = @import("../counterpoint.zig");
const keyboard = @import("../keyboard.zig");
const types = @import("types.zig");
const phrase = @import("phrase.zig");
const fret_assessment = @import("fret_assessment.zig");
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

pub const PhraseBranchClassification = enum(u8) {
    blocked = 0,
    playable_recovery_deficit = 1,
    playable_recovery_neutral = 2,
    playable_recovery_improving = 3,
};

pub const PHRASE_BRANCH_CLASSIFICATION_NAMES = [_][]const u8{
    "blocked",
    "playable-recovery-deficit",
    "playable-recovery-neutral",
    "playable-recovery-improving",
};

pub fn phraseBranchClassificationFromInt(raw: u8) ?PhraseBranchClassification {
    return switch (raw) {
        0 => .blocked,
        1 => .playable_recovery_deficit,
        2 => .playable_recovery_neutral,
        3 => .playable_recovery_improving,
        else => null,
    };
}

pub const PhraseBranchVisibility = enum(u8) {
    diagnostics_keep_blocked = 0,
    hard_filter_blocked = 1,
};

pub const PHRASE_BRANCH_VISIBILITY_NAMES = [_][]const u8{
    "diagnostics-keep-blocked",
    "hard-filter-blocked",
};

pub fn phraseBranchVisibilityFromInt(raw: u8) ?PhraseBranchVisibility {
    return switch (raw) {
        0 => .diagnostics_keep_blocked,
        1 => .hard_filter_blocked,
        else => null,
    };
}

pub const PhraseBranchBiasReason = enum(u8) {
    blocked_by_committed_history = 0,
    deficit_windows_compounded = 1,
    dominant_warning_compounded = 2,
    dominant_reason_reinforced = 3,
    peak_strain_increased = 4,
    continuity_reset_from_hand_switch = 5,
};

pub const PHRASE_BRANCH_BIAS_REASON_NAMES = [_][]const u8{
    "blocked by committed history",
    "deficit windows compounded",
    "dominant warning compounded",
    "dominant reason reinforced",
    "peak strain increased",
    "continuity reset from hand switch",
};

pub const PhraseBranchBiasSummary = struct {
    bias_reason_bits: u32,
    deficit_window_delta: i16,
    improving_window_delta: i16,
    peak_strain_delta: i16,
    standalone_classification: PhraseBranchClassification,
    biased_classification: PhraseBranchClassification,
    committed_strain_bucket: phrase.StrainBucket,
    committed_warning_family: u8,
    committed_reason_family: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,

    pub fn empty() PhraseBranchBiasSummary {
        return .{
            .bias_reason_bits = 0,
            .deficit_window_delta = 0,
            .improving_window_delta = 0,
            .peak_strain_delta = 0,
            .standalone_classification = .playable_recovery_neutral,
            .biased_classification = .playable_recovery_neutral,
            .committed_strain_bucket = .neutral,
            .committed_warning_family = phrase.NONE_FAMILY_INDEX,
            .committed_reason_family = phrase.NONE_FAMILY_INDEX,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
        };
    }
};

pub const RankedKeyboardPhraseBranch = struct {
    branch: phrase.KeyboardPhraseBranch,
    summary: phrase.PhraseBranchSummary,
    standalone_summary: phrase.PhraseBranchSummary,
    bias: PhraseBranchBiasSummary,
    candidate_index: u32,
    policy: PlayabilityPolicy,
    visibility: PhraseBranchVisibility,
    classification: PhraseBranchClassification,
    accepted: bool,
};

pub const RankedFretPhraseBranch = struct {
    branch: phrase.FretPhraseBranch,
    summary: phrase.PhraseBranchSummary,
    standalone_summary: phrase.PhraseBranchSummary,
    bias: PhraseBranchBiasSummary,
    candidate_index: u32,
    policy: PlayabilityPolicy,
    visibility: PhraseBranchVisibility,
    classification: PhraseBranchClassification,
    accepted: bool,
};

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

pub fn rankKeyboardNextStepsFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    history: *const counterpoint.VoicedHistoryWindow,
    profile: counterpoint.CounterpointRuleProfile,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardNextStep,
) []RankedKeyboardNextStep {
    if (out.len == 0) return out[0..0];

    var theory_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]counterpoint.NextStepSuggestion = undefined;
    const theory = counterpoint.rankNextSteps(history, profile, theory_buf[0..]);
    return rankKeyboardNextStepCandidatesFromCommittedPhrase(committed, theory, hand_profile, policy, out);
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

pub fn rankKeyboardNextStepCandidatesFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    candidates: []const counterpoint.NextStepSuggestion,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardNextStep,
) []RankedKeyboardNextStep {
    const current = committed.current() orelse return out[0..0];
    return rankKeyboardNextStepCandidates(
        phrase.keyboardPhraseNotes(current),
        committed.loadBeforeCurrent(hand_profile),
        candidates,
        current.hand,
        hand_profile,
        policy,
        out,
    );
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

pub fn rankKeyboardContextSuggestionsFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    set_value: pcs.PitchClassSet,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    hand_profile: types.HandProfile,
    policy: PlayabilityPolicy,
    out: []RankedKeyboardContextSuggestion,
) []RankedKeyboardContextSuggestion {
    const current = committed.current() orelse return out[0..0];
    return rankKeyboardContextSuggestions(
        set_value,
        phrase.keyboardPhraseNotes(current),
        tonic,
        mode_type,
        current.hand,
        hand_profile,
        committed.loadBeforeCurrent(hand_profile),
        policy,
        out,
    );
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

pub fn classifyBranchSummary(summary: phrase.PhraseBranchSummary) PhraseBranchClassification {
    if (branchSummaryBlocked(summary)) return .blocked;
    if (summary.improving_window_count > summary.deficit_window_count) return .playable_recovery_improving;
    if (summary.deficit_window_count > summary.improving_window_count) return .playable_recovery_deficit;
    return .playable_recovery_neutral;
}

pub fn summarizeKeyboardBranchBiasFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    branch: *const phrase.KeyboardPhraseBranch,
    profile: types.HandProfile,
) PhraseBranchBiasSummary {
    const standalone = phrase.summarizeKeyboardBranch(branch, profile);
    const biased = phrase.summarizeKeyboardBranchAgainstCommittedPhrase(committed, branch, profile);
    return describeKeyboardBranchBias(committed, branch, profile, standalone, biased);
}

pub fn summarizeFretBranchBiasFromCommittedPhrase(
    committed: *const phrase.FretCommittedPhraseMemory,
    branch: *const phrase.FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
) PhraseBranchBiasSummary {
    const standalone = phrase.summarizeFretBranch(branch, tuning, technique, hand_override);
    const biased = phrase.summarizeFretBranchAgainstCommittedPhrase(committed, branch, tuning, technique, hand_override);
    return describeFretBranchBias(committed, tuning, technique, hand_override, standalone, biased);
}

pub fn rankKeyboardPhraseBranchesFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    branches: []const phrase.KeyboardPhraseBranch,
    profile: types.HandProfile,
    policy: PlayabilityPolicy,
    visibility: PhraseBranchVisibility,
    out: []RankedKeyboardPhraseBranch,
) []RankedKeyboardPhraseBranch {
    if (branches.len == 0 or out.len == 0) return out[0..0];

    var write_len: usize = 0;
    for (branches, 0..) |branch, index| {
        if (write_len >= out.len) break;

        const standalone = phrase.summarizeKeyboardBranch(&branch, profile);
        const biased = phrase.summarizeKeyboardBranchAgainstCommittedPhrase(committed, &branch, profile);
        const classification = classifyBranchSummary(biased);
        if (visibility == .hard_filter_blocked and classification == .blocked) continue;

        out[write_len] = .{
            .branch = branch,
            .summary = biased,
            .standalone_summary = standalone,
            .bias = describeKeyboardBranchBias(committed, &branch, profile, standalone, biased),
            .candidate_index = @as(u32, @intCast(index)),
            .policy = policy,
            .visibility = visibility,
            .classification = classification,
            .accepted = classification != .blocked,
        };
        write_len += 1;
    }

    std.sort.insertion(RankedKeyboardPhraseBranch, out[0..write_len], policy, keyboardPhraseBranchLessThan);
    return out[0..write_len];
}

pub fn rankFretPhraseBranchesFromCommittedPhrase(
    committed: *const phrase.FretCommittedPhraseMemory,
    branches: []const phrase.FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    policy: PlayabilityPolicy,
    visibility: PhraseBranchVisibility,
    out: []RankedFretPhraseBranch,
) []RankedFretPhraseBranch {
    if (branches.len == 0 or out.len == 0) return out[0..0];

    var write_len: usize = 0;
    for (branches, 0..) |branch, index| {
        if (write_len >= out.len) break;

        const standalone = phrase.summarizeFretBranch(&branch, tuning, technique, hand_override);
        const biased = phrase.summarizeFretBranchAgainstCommittedPhrase(committed, &branch, tuning, technique, hand_override);
        const classification = classifyBranchSummary(biased);
        if (visibility == .hard_filter_blocked and classification == .blocked) continue;

        out[write_len] = .{
            .branch = branch,
            .summary = biased,
            .standalone_summary = standalone,
            .bias = describeFretBranchBias(committed, tuning, technique, hand_override, standalone, biased),
            .candidate_index = @as(u32, @intCast(index)),
            .policy = policy,
            .visibility = visibility,
            .classification = classification,
            .accepted = classification != .blocked,
        };
        write_len += 1;
    }

    std.sort.insertion(RankedFretPhraseBranch, out[0..write_len], policy, fretPhraseBranchLessThan);
    return out[0..write_len];
}

pub fn filterBlockedKeyboardPhraseBranchesFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    branches: []const phrase.KeyboardPhraseBranch,
    profile: types.HandProfile,
    out: []phrase.KeyboardPhraseBranch,
) []phrase.KeyboardPhraseBranch {
    if (branches.len == 0 or out.len == 0) return out[0..0];

    var write_len: usize = 0;
    for (branches) |branch| {
        if (write_len >= out.len) break;
        const biased = phrase.summarizeKeyboardBranchAgainstCommittedPhrase(committed, &branch, profile);
        if (classifyBranchSummary(biased) == .blocked) continue;
        out[write_len] = branch;
        write_len += 1;
    }
    return out[0..write_len];
}

pub fn filterBlockedFretPhraseBranchesFromCommittedPhrase(
    committed: *const phrase.FretCommittedPhraseMemory,
    branches: []const phrase.FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    out: []phrase.FretPhraseBranch,
) []phrase.FretPhraseBranch {
    if (branches.len == 0 or out.len == 0) return out[0..0];

    var write_len: usize = 0;
    for (branches) |branch| {
        if (write_len >= out.len) break;
        const biased = phrase.summarizeFretBranchAgainstCommittedPhrase(committed, &branch, tuning, technique, hand_override);
        if (classifyBranchSummary(biased) == .blocked) continue;
        out[write_len] = branch;
        write_len += 1;
    }
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
    for (current_notes[0..copy_len], 0..) |note, index| {
        out[index] = note;
    }

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

fn describeKeyboardBranchBias(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    branch: *const phrase.KeyboardPhraseBranch,
    profile: types.HandProfile,
    standalone: phrase.PhraseBranchSummary,
    biased: phrase.PhraseBranchSummary,
) PhraseBranchBiasSummary {
    const committed_summary = committedKeyboardSummary(committed, profile);
    var out = PhraseBranchBiasSummary.empty();
    out.standalone_classification = classifyBranchSummary(standalone);
    out.biased_classification = classifyBranchSummary(biased);
    out.committed_strain_bucket = committed_summary.strain_bucket;
    out.committed_warning_family = committed_summary.dominant_warning_family;
    out.committed_reason_family = committed_summary.dominant_reason_family;
    out.deficit_window_delta = deltaU16(biased.deficit_window_count, standalone.deficit_window_count);
    out.improving_window_delta = deltaU16(biased.improving_window_count, standalone.improving_window_count);
    out.peak_strain_delta = deltaU16(biased.peak_strain_magnitude, standalone.peak_strain_magnitude);

    if (out.biased_classification == .blocked and out.standalone_classification != .blocked) {
        out.bias_reason_bits |= branchBiasBit(.blocked_by_committed_history);
    }
    if (biased.deficit_window_count > standalone.deficit_window_count) {
        out.bias_reason_bits |= branchBiasBit(.deficit_windows_compounded);
    }
    if (committed_summary.dominant_warning_family != phrase.NONE_FAMILY_INDEX and
        biased.dominant_warning_family == committed_summary.dominant_warning_family)
    {
        out.bias_reason_bits |= branchBiasBit(.dominant_warning_compounded);
    }
    if (committed_summary.dominant_reason_family != phrase.NONE_FAMILY_INDEX and
        biased.dominant_reason_family == committed_summary.dominant_reason_family)
    {
        out.bias_reason_bits |= branchBiasBit(.dominant_reason_reinforced);
    }
    if (biased.peak_strain_magnitude > standalone.peak_strain_magnitude) {
        out.bias_reason_bits |= branchBiasBit(.peak_strain_increased);
    }
    if (committed.current()) |prior| {
        if (branch.len() > 0 and branch.steps[0].hand != prior.hand) {
            out.bias_reason_bits |= branchBiasBit(.continuity_reset_from_hand_switch);
        }
    }
    return out;
}

fn describeFretBranchBias(
    committed: *const phrase.FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    standalone: phrase.PhraseBranchSummary,
    biased: phrase.PhraseBranchSummary,
) PhraseBranchBiasSummary {
    const committed_summary = committedFretSummary(committed, tuning, technique, hand_override);
    var out = PhraseBranchBiasSummary.empty();
    out.standalone_classification = classifyBranchSummary(standalone);
    out.biased_classification = classifyBranchSummary(biased);
    out.committed_strain_bucket = committed_summary.strain_bucket;
    out.committed_warning_family = committed_summary.dominant_warning_family;
    out.committed_reason_family = committed_summary.dominant_reason_family;
    out.deficit_window_delta = deltaU16(biased.deficit_window_count, standalone.deficit_window_count);
    out.improving_window_delta = deltaU16(biased.improving_window_count, standalone.improving_window_count);
    out.peak_strain_delta = deltaU16(biased.peak_strain_magnitude, standalone.peak_strain_magnitude);

    if (out.biased_classification == .blocked and out.standalone_classification != .blocked) {
        out.bias_reason_bits |= branchBiasBit(.blocked_by_committed_history);
    }
    if (biased.deficit_window_count > standalone.deficit_window_count) {
        out.bias_reason_bits |= branchBiasBit(.deficit_windows_compounded);
    }
    if (committed_summary.dominant_warning_family != phrase.NONE_FAMILY_INDEX and
        biased.dominant_warning_family == committed_summary.dominant_warning_family)
    {
        out.bias_reason_bits |= branchBiasBit(.dominant_warning_compounded);
    }
    if (committed_summary.dominant_reason_family != phrase.NONE_FAMILY_INDEX and
        biased.dominant_reason_family == committed_summary.dominant_reason_family)
    {
        out.bias_reason_bits |= branchBiasBit(.dominant_reason_reinforced);
    }
    if (biased.peak_strain_magnitude > standalone.peak_strain_magnitude) {
        out.bias_reason_bits |= branchBiasBit(.peak_strain_increased);
    }
    return out;
}

fn committedKeyboardSummary(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    profile: types.HandProfile,
) phrase.PhraseSummary {
    var issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    return phrase.auditCommittedKeyboardPhrase(committed, profile, issues[0..]).summary;
}

fn committedFretSummary(
    committed: *const phrase.FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
) phrase.PhraseSummary {
    var issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    return phrase.auditCommittedFretPhrase(committed, tuning, technique, hand_override, issues[0..]).summary;
}

fn deltaU16(after: u16, before: u16) i16 {
    const after_i: i32 = @intCast(after);
    const before_i: i32 = @intCast(before);
    return @as(i16, @intCast(after_i - before_i));
}

fn branchBiasBit(kind: PhraseBranchBiasReason) u32 {
    return @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn branchSummaryBlocked(summary: phrase.PhraseBranchSummary) bool {
    return summary.first_blocked_step_index != phrase.NONE_EVENT_INDEX or
        summary.first_blocked_transition_from_index != phrase.NONE_EVENT_INDEX or
        summary.strain_bucket == .blocked;
}

fn classRank(classification: PhraseBranchClassification) u8 {
    return switch (classification) {
        .playable_recovery_improving => 0,
        .playable_recovery_neutral => 1,
        .playable_recovery_deficit => 2,
        .blocked => 3,
    };
}

fn earliestBlockedStep(summary: phrase.PhraseBranchSummary) u16 {
    if (summary.first_blocked_step_index != phrase.NONE_EVENT_INDEX) return summary.first_blocked_step_index;
    return summary.first_blocked_transition_to_index;
}

fn keyboardPhraseBranchLessThan(policy: PlayabilityPolicy, a: RankedKeyboardPhraseBranch, b: RankedKeyboardPhraseBranch) bool {
    if (a.classification != b.classification) return classRank(a.classification) < classRank(b.classification);

    switch (policy) {
        .balanced => {
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
        },
        .minimax_bottleneck => {
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
            if (a.classification == .blocked and b.classification == .blocked and earliestBlockedStep(a.summary) != earliestBlockedStep(b.summary)) {
                return earliestBlockedStep(a.summary) > earliestBlockedStep(b.summary);
            }
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
        },
        .cumulative_strain => {
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
        },
    }

    return a.candidate_index < b.candidate_index;
}

fn fretPhraseBranchLessThan(policy: PlayabilityPolicy, a: RankedFretPhraseBranch, b: RankedFretPhraseBranch) bool {
    if (a.classification != b.classification) return classRank(a.classification) < classRank(b.classification);

    switch (policy) {
        .balanced => {
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
        },
        .minimax_bottleneck => {
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
            if (a.classification == .blocked and b.classification == .blocked and earliestBlockedStep(a.summary) != earliestBlockedStep(b.summary)) {
                return earliestBlockedStep(a.summary) > earliestBlockedStep(b.summary);
            }
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
        },
        .cumulative_strain => {
            if (a.summary.deficit_window_count != b.summary.deficit_window_count) return a.summary.deficit_window_count < b.summary.deficit_window_count;
            if (a.summary.improving_window_count != b.summary.improving_window_count) return a.summary.improving_window_count > b.summary.improving_window_count;
            if (a.summary.peak_strain_magnitude != b.summary.peak_strain_magnitude) return a.summary.peak_strain_magnitude < b.summary.peak_strain_magnitude;
        },
    }

    return a.candidate_index < b.candidate_index;
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
