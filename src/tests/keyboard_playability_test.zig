const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const keyboard_assessment = @import("../playability/keyboard_assessment.zig");
const keyboard_topology = @import("../playability/keyboard_topology.zig");
const types = @import("../playability/types.zig");

fn hasWarning(bits: u32, warning: types.WarningKind) bool {
    return (bits & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(warning))))) != 0;
}

fn hasBlocker(bits: u32, blocker: keyboard_assessment.BlockerKind) bool {
    return (bits & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(blocker))))) != 0;
}

test "right hand triad prefers spread fingering without blockers" {
    const profile = keyboard_topology.defaultHandProfile();
    const assessment = keyboard_assessment.assessRealization(&[_]pitch.MidiNote{ 60, 64, 67 }, .right, profile, null);

    try testing.expectEqual(@as(u8, 3), assessment.note_count);
    try testing.expectEqual(@as(u8, 0), assessment.outer_black_count);
    try testing.expectEqual(@as(u32, 0), assessment.blocker_bits);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 3, 5, 0, 0 }, &assessment.recommended_fingers);
    try testing.expect(!hasWarning(assessment.warning_bits, .hard_limit_exceeded));
}

test "wide right hand chord hits span hard limit" {
    const profile = keyboard_topology.defaultHandProfile();
    const assessment = keyboard_assessment.assessRealization(&[_]pitch.MidiNote{ 60, 67, 76 }, .right, profile, null);

    try testing.expect(hasBlocker(assessment.blocker_bits, .span_hard_limit));
    try testing.expect(hasWarning(assessment.warning_bits, .hard_limit_exceeded));
}

test "singleton black key prefers non-thumb fingering" {
    const profile = keyboard_topology.defaultHandProfile();
    var ranked: [keyboard_assessment.MAX_RANKED_FINGERINGS]keyboard_assessment.RankedFingering = undefined;
    const results = keyboard_assessment.rankFingerings(&[_]pitch.MidiNote{61}, .right, profile, &ranked);

    try testing.expect(results.len >= 5);
    try testing.expectEqual(@as(u8, 2), results[0].fingers[0]);
}

test "monophonic transition tracks shift limit and recent-motion fluency" {
    const profile = keyboard_topology.defaultHandProfile();
    const previous_load = types.TemporalLoadState{
        .event_count = 1,
        .last_anchor_step = 48,
        .last_span_steps = 0,
        .last_shift_steps = 0,
        .peak_span_steps = 0,
        .peak_shift_steps = 0,
        .cumulative_span_steps = 0,
        .cumulative_shift_steps = 0,
    };
    const transition = keyboard_assessment.assessTransition(&[_]pitch.MidiNote{60}, &[_]pitch.MidiNote{73}, .right, profile, previous_load);

    try testing.expectEqual(@as(u8, 13), transition.anchor_delta_semitones);
    try testing.expect(hasBlocker(transition.blocker_bits, .shift_hard_limit));
    try testing.expect(hasWarning(transition.warning_bits, .shift_required));
    try testing.expect(hasWarning(transition.warning_bits, .excessive_longitudinal_shift));
    try testing.expect(hasWarning(transition.warning_bits, .fluency_degradation_from_recent_motion));
}
