const std = @import("std");
const testing = std.testing;
const types = @import("../playability/types.zig");

test "playability reason and warning names stay aligned with enums" {
    try testing.expectEqual(@as(usize, 9), types.REASON_NAMES.len);
    try testing.expectEqual(@as(usize, 12), types.WARNING_NAMES.len);
    try testing.expectEqualStrings("reachable in current window", types.REASON_NAMES[@intFromEnum(types.ReasonKind.reachable_in_current_window)]);
    try testing.expectEqualStrings("reduced bottleneck", types.REASON_NAMES[@intFromEnum(types.ReasonKind.bottleneck_reduced)]);
    try testing.expectEqualStrings("hand continuity reset", types.REASON_NAMES[@intFromEnum(types.ReasonKind.hand_continuity_reset)]);
    try testing.expectEqualStrings("hard limit exceeded", types.WARNING_NAMES[@intFromEnum(types.WarningKind.hard_limit_exceeded)]);
    try testing.expectEqualStrings("unsupported extension", types.WARNING_NAMES[@intFromEnum(types.WarningKind.unsupported_extension)]);
    try testing.expectEqualStrings("thumb on black under stretch", types.WARNING_NAMES[@intFromEnum(types.WarningKind.thumb_on_black_under_stretch)]);
    try testing.expectEqualStrings("fluency degradation from recent motion", types.WARNING_NAMES[@intFromEnum(types.WarningKind.fluency_degradation_from_recent_motion)]);
}

test "hand profile init preserves explicit parameters" {
    const profile = types.HandProfile.init(4, 4, 5, 4, 7, true);
    try testing.expectEqual(@as(u8, 4), profile.finger_count);
    try testing.expectEqual(@as(u8, 4), profile.comfort_span_steps);
    try testing.expectEqual(@as(u8, 5), profile.limit_span_steps);
    try testing.expect(profile.prefers_low_tension);
}
