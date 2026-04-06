const std = @import("std");
const testing = std.testing;

const counterpoint = @import("../counterpoint.zig");
const pitch = @import("../pitch.zig");
const rules = @import("../voice_leading_rules.zig");

test "parallel perfect detectors identify fifths and octaves" {
    const previous_fifth = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 67 },
    });
    const current_fifth = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 69 },
    });

    var violations: [rules.MAX_VOICE_PAIR_VIOLATIONS]rules.VoicePairViolation = undefined;
    const fifth_total = rules.detectParallelPerfects(&previous_fifth, &current_fifth, violations[0..]);
    try testing.expectEqual(@as(u8, 1), fifth_total);
    try testing.expectEqual(rules.ViolationKind.parallel_fifth, violations[0].kind);
    try testing.expectEqual(@as(i8, 7), violations[0].previous_interval_semitones);
    try testing.expectEqual(@as(i8, 7), violations[0].current_interval_semitones);

    const previous_octave = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 72 },
    });
    const current_octave = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 74 },
    });

    const octave_total = rules.detectParallelPerfects(&previous_octave, &current_octave, violations[0..]);
    try testing.expectEqual(@as(u8, 1), octave_total);
    try testing.expectEqual(rules.ViolationKind.parallel_octave_or_unison, violations[0].kind);
    try testing.expectEqual(@as(i8, 12), violations[0].previous_interval_semitones);
    try testing.expectEqual(@as(i8, 12), violations[0].current_interval_semitones);
}

test "voice crossing detector returns offending persistent pair" {
    const previous = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 64 },
    });
    const current = manualState(&[_]ManualVoice{
        .{ .id = 1, .midi = 62 },
        .{ .id = 0, .midi = 67 },
    });

    var violations: [rules.MAX_VOICE_PAIR_VIOLATIONS]rules.VoicePairViolation = undefined;
    const total = rules.detectVoiceCrossings(&previous, &current, violations[0..]);
    try testing.expectEqual(@as(u8, 1), total);
    try testing.expectEqual(rules.ViolationKind.voice_crossing, violations[0].kind);
    try testing.expectEqual(@as(u8, 0), violations[0].lower_voice_id);
    try testing.expectEqual(@as(u8, 1), violations[0].upper_voice_id);
    try testing.expect(violations[0].current_interval_semitones < 0);
}

test "spacing detector checks adjacent upper voices but exempts bass-tenor span" {
    const state = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 40 },
        .{ .id = 1, .midi = 57 },
        .{ .id = 2, .midi = 74 },
        .{ .id = 3, .midi = 88 },
    });

    var violations: [rules.MAX_VOICE_PAIR_VIOLATIONS]rules.VoicePairViolation = undefined;
    const total = rules.detectSpacingViolations(&state, violations[0..]);
    try testing.expectEqual(@as(u8, 2), total);
    try testing.expectEqual(rules.ViolationKind.upper_spacing, violations[0].kind);
    try testing.expectEqual(@as(u8, 1), violations[0].lower_voice_id);
    try testing.expectEqual(@as(u8, 2), violations[0].upper_voice_id);
    try testing.expectEqual(@as(i8, 17), violations[0].current_interval_semitones);
    try testing.expectEqual(@as(u8, 2), violations[1].lower_voice_id);
    try testing.expectEqual(@as(u8, 3), violations[1].upper_voice_id);
}

test "motion independence summary reports collapsed similar motion" {
    const previous = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 48 },
        .{ .id = 1, .midi = 55 },
        .{ .id = 2, .midi = 60 },
    });
    const collapsed = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 50 },
        .{ .id = 1, .midi = 57 },
        .{ .id = 2, .midi = 62 },
    });

    const summary = rules.detectMotionIndependence(&previous, &collapsed);
    try testing.expect(summary.collapsed);
    try testing.expectEqual(@as(i8, 1), summary.direction);
    try testing.expectEqual(@as(u8, 3), summary.moving_voice_count);
    try testing.expectEqual(@as(u8, 0), summary.stationary_voice_count);

    const mixed = manualState(&[_]ManualVoice{
        .{ .id = 0, .midi = 50 },
        .{ .id = 1, .midi = 54 },
        .{ .id = 2, .midi = 62 },
    });
    const mixed_summary = rules.detectMotionIndependence(&previous, &mixed);
    try testing.expect(!mixed_summary.collapsed);
    try testing.expectEqual(@as(i8, 0), mixed_summary.direction);
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
