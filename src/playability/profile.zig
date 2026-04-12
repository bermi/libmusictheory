const std = @import("std");
const pitch = @import("../pitch.zig");
const counterpoint = @import("../counterpoint.zig");
const fret_assessment = @import("fret_assessment.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");
const phrase = @import("phrase.zig");
const repair = @import("repair.zig");
const ranking = @import("ranking.zig");
const types = @import("types.zig");

pub const ProfilePreset = enum(u8) {
    compact_beginner = 0,
    balanced_standard = 1,
    span_tolerant = 2,
    shift_tolerant = 3,
};

pub const PRESET_NAMES = [_][]const u8{
    "compact-beginner",
    "balanced-standard",
    "span-tolerant",
    "shift-tolerant",
};

const PresetAdjustments = struct {
    comfort_span_delta: i8,
    limit_span_delta: i8,
    comfort_shift_delta: i8,
    limit_shift_delta: i8,
    prefers_low_tension: ?bool,
};

const PRESET_ADJUSTMENTS = [_]PresetAdjustments{
    .{
        .comfort_span_delta = -2,
        .limit_span_delta = -1,
        .comfort_shift_delta = -1,
        .limit_shift_delta = -1,
        .prefers_low_tension = true,
    },
    .{
        .comfort_span_delta = 0,
        .limit_span_delta = 0,
        .comfort_shift_delta = 0,
        .limit_shift_delta = 0,
        .prefers_low_tension = null,
    },
    .{
        .comfort_span_delta = 1,
        .limit_span_delta = 2,
        .comfort_shift_delta = 0,
        .limit_shift_delta = 0,
        .prefers_low_tension = false,
    },
    .{
        .comfort_span_delta = 0,
        .limit_span_delta = 0,
        .comfort_shift_delta = 1,
        .limit_shift_delta = 2,
        .prefers_low_tension = false,
    },
};

pub const DifficultySummary = struct {
    accepted: bool,
    blocker_count: u8,
    warning_count: u8,
    reason_count: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    span_steps: u8,
    shift_steps: u8,
    load_event_count: u8,
    peak_recent_span_steps: u8,
    peak_recent_shift_steps: u8,
    comfort_span_margin: i16,
    limit_span_margin: i16,
    comfort_shift_margin: i16,
    limit_shift_margin: i16,
};

pub fn fromInt(raw: u8) ?ProfilePreset {
    return switch (raw) {
        0 => .compact_beginner,
        1 => .balanced_standard,
        2 => .span_tolerant,
        3 => .shift_tolerant,
        else => null,
    };
}

pub fn applyPreset(base: types.HandProfile, preset: ProfilePreset) types.HandProfile {
    const spec = PRESET_ADJUSTMENTS[@intFromEnum(preset)];

    const comfort_span_steps = adjustBounded(base.comfort_span_steps, spec.comfort_span_delta, 1);
    const limit_span_steps = @max(
        comfort_span_steps,
        adjustBounded(base.limit_span_steps, spec.limit_span_delta, comfort_span_steps),
    );
    const comfort_shift_steps = adjustBounded(base.comfort_shift_steps, spec.comfort_shift_delta, 0);
    const limit_shift_steps = @max(
        comfort_shift_steps,
        adjustBounded(base.limit_shift_steps, spec.limit_shift_delta, comfort_shift_steps),
    );

    return .{
        .finger_count = base.finger_count,
        .comfort_span_steps = comfort_span_steps,
        .limit_span_steps = limit_span_steps,
        .comfort_shift_steps = comfort_shift_steps,
        .limit_shift_steps = limit_shift_steps,
        .prefers_low_tension = spec.prefers_low_tension orelse base.prefers_low_tension,
        .reserved0 = 0,
        .reserved1 = 0,
    };
}

pub fn summarizeFretRealization(
    assessment: fret_assessment.RealizationAssessment,
    hand: types.HandProfile,
) DifficultySummary {
    return buildSummary(
        assessment.blocker_bits,
        assessment.warning_bits,
        assessment.reason_bits,
        assessment.bottleneck_cost,
        assessment.cumulative_cost,
        assessment.state.span_steps,
        assessment.state.load.last_shift_steps,
        assessment.state.load,
        hand,
    );
}

pub fn summarizeFretTransition(
    assessment: fret_assessment.TransitionAssessment,
    hand: types.HandProfile,
) DifficultySummary {
    return buildSummary(
        assessment.blocker_bits,
        assessment.warning_bits,
        assessment.reason_bits,
        assessment.bottleneck_cost,
        assessment.cumulative_cost,
        assessment.to_state.span_steps,
        assessment.anchor_delta_steps,
        assessment.to_state.load,
        hand,
    );
}

pub fn summarizeKeyboardRealization(
    assessment: keyboard_assessment.RealizationAssessment,
    hand: types.HandProfile,
) DifficultySummary {
    return buildSummary(
        assessment.blocker_bits,
        assessment.warning_bits,
        assessment.reason_bits,
        assessment.bottleneck_cost,
        assessment.cumulative_cost,
        assessment.state.span_semitones,
        assessment.state.load.last_shift_steps,
        assessment.state.load,
        hand,
    );
}

pub fn summarizeKeyboardTransition(
    assessment: keyboard_assessment.TransitionAssessment,
    hand: types.HandProfile,
) DifficultySummary {
    return buildSummary(
        assessment.blocker_bits,
        assessment.warning_bits,
        assessment.reason_bits,
        assessment.bottleneck_cost,
        assessment.cumulative_cost,
        assessment.to_state.span_semitones,
        assessment.anchor_delta_semitones,
        assessment.to_state.load,
        hand,
    );
}

pub fn suggestEasierFretRealization(
    note: pitch.MidiNote,
    tuning: []const pitch.MidiNote,
    anchor_fret: u8,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
) ?fret_assessment.RankedLocation {
    var ranked_buf: [fret_assessment.MAX_RANKED_LOCATIONS]fret_assessment.RankedLocation = undefined;
    const ranked = fret_assessment.rankLocationsForMidi(
        note,
        tuning,
        anchor_fret,
        technique,
        hand_override,
        ranked_buf[0..],
    );
    return if (ranked.len == 0) null else ranked[0];
}

pub fn suggestEasierKeyboardFingering(
    notes: []const pitch.MidiNote,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
) ?keyboard_assessment.RankedFingering {
    var ranked_buf: [keyboard_assessment.MAX_RANKED_FINGERINGS]keyboard_assessment.RankedFingering = undefined;
    const ranked = keyboard_assessment.rankFingerings(notes, hand, hand_profile, ranked_buf[0..]);
    return if (ranked.len == 0) null else ranked[0];
}

pub fn suggestSaferKeyboardNextStep(
    history: *const counterpoint.VoicedHistoryWindow,
    profile: counterpoint.CounterpointRuleProfile,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: ranking.PlayabilityPolicy,
) ?ranking.RankedKeyboardNextStep {
    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]ranking.RankedKeyboardNextStep = undefined;
    const ranked_rows = ranking.rankKeyboardNextSteps(
        history,
        profile,
        hand,
        hand_profile,
        policy,
        ranked_buf[0..],
    );
    return firstAcceptedOrFallback(ranked_rows);
}

pub fn suggestSaferKeyboardNextStepFromCommittedPhrase(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    history: *const counterpoint.VoicedHistoryWindow,
    profile: counterpoint.CounterpointRuleProfile,
    hand_profile: types.HandProfile,
    policy: ranking.PlayabilityPolicy,
) ?ranking.RankedKeyboardNextStep {
    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]ranking.RankedKeyboardNextStep = undefined;
    const ranked_rows = ranking.rankKeyboardNextStepsFromCommittedPhrase(
        committed,
        history,
        profile,
        hand_profile,
        policy,
        ranked_buf[0..],
    );
    return firstAcceptedOrFallback(ranked_rows);
}

pub fn suggestBestKeyboardPhraseRepair(
    committed: *const phrase.KeyboardCommittedPhraseMemory,
    hand_profile: types.HandProfile,
    policy: repair.RepairPolicy,
) ?repair.RankedKeyboardPhraseRepair {
    var ranked_buf: [repair.MAX_PHRASE_REPAIRS]repair.RankedKeyboardPhraseRepair = undefined;
    const ranked_rows = repair.rankKeyboardPhraseRepairs(
        committed,
        hand_profile,
        policy,
        ranked_buf[0..],
    );
    return if (ranked_rows.len == 0) null else ranked_rows[0];
}

pub fn suggestBestFretPhraseRepair(
    committed: *const phrase.FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    policy: repair.RepairPolicy,
) ?repair.RankedFretPhraseRepair {
    var ranked_buf: [repair.MAX_PHRASE_REPAIRS]repair.RankedFretPhraseRepair = undefined;
    const ranked_rows = repair.rankFretPhraseRepairs(
        committed,
        tuning,
        technique,
        hand_override,
        policy,
        ranked_buf[0..],
    );
    return if (ranked_rows.len == 0) null else ranked_rows[0];
}

pub fn suggestSaferKeyboardNextStepCandidates(
    current_notes: []const pitch.MidiNote,
    previous_load: ?types.TemporalLoadState,
    candidates: []const counterpoint.NextStepSuggestion,
    hand: keyboard_assessment.HandRole,
    hand_profile: types.HandProfile,
    policy: ranking.PlayabilityPolicy,
) ?ranking.RankedKeyboardNextStep {
    var ranked_buf: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]ranking.RankedKeyboardNextStep = undefined;
    const ranked_rows = ranking.rankKeyboardNextStepCandidates(
        current_notes,
        previous_load,
        candidates,
        hand,
        hand_profile,
        policy,
        ranked_buf[0..],
    );
    return firstAcceptedOrFallback(ranked_rows);
}

fn firstAcceptedOrFallback(rows: []const ranking.RankedKeyboardNextStep) ?ranking.RankedKeyboardNextStep {
    if (rows.len == 0) return null;
    for (rows) |row| {
        if (row.accepted) return row;
    }
    return rows[0];
}

fn buildSummary(
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    span_steps: u8,
    shift_steps: u8,
    load: types.TemporalLoadState,
    hand: types.HandProfile,
) DifficultySummary {
    return .{
        .accepted = blocker_bits == 0,
        .blocker_count = countBits(blocker_bits),
        .warning_count = countBits(warning_bits),
        .reason_count = countBits(reason_bits),
        .bottleneck_cost = bottleneck_cost,
        .cumulative_cost = cumulative_cost,
        .span_steps = span_steps,
        .shift_steps = shift_steps,
        .load_event_count = load.event_count,
        .peak_recent_span_steps = load.peak_span_steps,
        .peak_recent_shift_steps = load.peak_shift_steps,
        .comfort_span_margin = margin(hand.comfort_span_steps, span_steps),
        .limit_span_margin = margin(hand.limit_span_steps, span_steps),
        .comfort_shift_margin = margin(hand.comfort_shift_steps, shift_steps),
        .limit_shift_margin = margin(hand.limit_shift_steps, shift_steps),
    };
}

fn countBits(bits: u32) u8 {
    return @as(u8, @intCast(@min(@popCount(bits), std.math.maxInt(u8))));
}

fn margin(limit: u8, actual: u8) i16 {
    return @as(i16, limit) - @as(i16, actual);
}

fn adjustBounded(base: u8, delta: i8, floor: u8) u8 {
    const widened = @as(i16, base) + @as(i16, delta);
    return @as(u8, @intCast(@max(@as(i16, floor), widened)));
}

test "profile preset metadata stays stable" {
    try std.testing.expectEqual(@as(?ProfilePreset, .compact_beginner), fromInt(0));
    try std.testing.expectEqual(@as(?ProfilePreset, .balanced_standard), fromInt(1));
    try std.testing.expectEqual(@as(?ProfilePreset, .span_tolerant), fromInt(2));
    try std.testing.expectEqual(@as(?ProfilePreset, .shift_tolerant), fromInt(3));
    try std.testing.expectEqual(@as(?ProfilePreset, null), fromInt(9));
    try std.testing.expectEqualStrings("compact-beginner", PRESET_NAMES[@intFromEnum(ProfilePreset.compact_beginner)]);
}
