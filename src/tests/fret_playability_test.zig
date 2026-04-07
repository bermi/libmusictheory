const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const fret_assessment = @import("../playability/fret_assessment.zig");
const types = @import("../playability/types.zig");

fn hasReason(bits: u32, reason: types.ReasonKind) bool {
    return (bits & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(reason))))) != 0;
}

fn hasWarning(bits: u32, warning: types.WarningKind) bool {
    return (bits & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(warning))))) != 0;
}

fn hasBlocker(bits: u32, blocker: fret_assessment.BlockerKind) bool {
    return (bits & (@as(u32, 1) << @as(u5, @intCast(@intFromEnum(blocker))))) != 0;
}

test "ranked fret locations prefer in-window realizations before large shifts" {
    var ranked: [fret_assessment.MAX_RANKED_LOCATIONS]fret_assessment.RankedLocation = undefined;
    const results = fret_assessment.rankLocationsForMidi(
        60,
        guitar.tunings.STANDARD[0..],
        7,
        .generic_guitar,
        null,
        ranked[0..],
    );

    try testing.expectEqual(@as(usize, 5), results.len);
    try testing.expectEqual(@as(usize, 2), results[0].location.position.string);
    try testing.expectEqual(@as(u8, 10), results[0].location.position.fret);
    try testing.expect(results[0].location.in_window);
    try testing.expect(hasReason(results[0].reason_bits, .reachable_in_current_window));
    try testing.expect(hasReason(results[0].reason_bits, .multiple_locations_available));
}

test "generic guitar realization exposes open-string relief without blockers" {
    const assessment = fret_assessment.assessRealization(
        &[_]i8{ -1, 3, 2, 0, 1, 0 },
        guitar.tunings.STANDARD[0..],
        .generic_guitar,
        null,
        null,
    );

    try testing.expectEqual(@as(u32, 0), assessment.blocker_bits);
    try testing.expect(hasReason(assessment.reason_bits, .open_string_relief));
    try testing.expectEqual(@as(u8, 4), assessment.string_span_steps);
    try testing.expectEqual(@as(u8, 3), assessment.recommended_fingers[1]);
    try testing.expectEqual(@as(u8, 2), assessment.recommended_fingers[2]);
    try testing.expectEqual(@as(u8, 0), assessment.recommended_fingers[3]);
    try testing.expectEqual(@as(u8, 1), assessment.recommended_fingers[4]);
}

test "bass simandl flags unsupported extension while generic guitar does not" {
    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const frets = [_]i8{ 1, 4, -1, -1 };

    const simandl = fret_assessment.assessRealization(
        frets[0..],
        tuning[0..],
        .bass_simandl,
        null,
        null,
    );
    try testing.expect(hasWarning(simandl.warning_bits, .unsupported_extension));
    try testing.expect(!hasBlocker(simandl.blocker_bits, .unsupported_extension));

    const generic = fret_assessment.assessRealization(
        frets[0..],
        tuning[0..],
        .generic_guitar,
        null,
        null,
    );
    try testing.expect(!hasWarning(generic.warning_bits, .unsupported_extension));
}

test "fret transition reports shift pressure and repeated stretch" {
    const from = [_]i8{ -1, 3, 2, 0, 1, 0 };
    const to = [_]i8{ -1, 10, 9, 7, 8, 7 };
    const transition = fret_assessment.assessTransition(
        from[0..],
        to[0..],
        guitar.tunings.STANDARD[0..],
        .generic_guitar,
        null,
    );

    try testing.expectEqual(@as(u8, 6), transition.anchor_delta_steps);
    try testing.expect(hasWarning(transition.warning_bits, .shift_required));
    try testing.expect(hasWarning(transition.warning_bits, .excessive_longitudinal_shift));
    try testing.expect(!hasReason(transition.reason_bits, .technique_profile_applied));
    try testing.expect(transition.bottleneck_cost >= 6);
}
