const std = @import("std");

pub const ReasonKind = enum(u8) {
    reachable_location = 0,
    reachable_in_current_window = 1,
    multiple_locations_available = 2,
    expands_current_window = 3,
    open_string_relief = 4,
    reuses_current_anchor = 5,
    bottleneck_reduced = 6,
    technique_profile_applied = 7,
};

pub const REASON_NAMES = [_][]const u8{
    "reachable location",
    "reachable in current window",
    "multiple locations available",
    "expands current window",
    "open-string relief",
    "reuses current anchor",
    "reduced bottleneck",
    "technique profile applied",
};

pub const WarningKind = enum(u8) {
    shift_required = 0,
    comfort_window_exceeded = 1,
    hard_limit_exceeded = 2,
    ambiguous_hand_assignment = 3,
    excessive_longitudinal_shift = 4,
    repeated_maximal_stretch = 5,
    weak_finger_stress = 6,
    unsupported_extension = 7,
};

pub const WARNING_NAMES = [_][]const u8{
    "shift required",
    "comfort window exceeded",
    "hard limit exceeded",
    "ambiguous hand assignment",
    "excessive longitudinal shift",
    "repeated maximal stretch",
    "weak finger stress",
    "unsupported extension",
};

pub const HandProfile = struct {
    finger_count: u8,
    comfort_span_steps: u8,
    limit_span_steps: u8,
    comfort_shift_steps: u8,
    limit_shift_steps: u8,
    prefers_low_tension: bool,
    reserved0: u8,
    reserved1: u8,

    pub fn init(
        finger_count: u8,
        comfort_span_steps: u8,
        limit_span_steps: u8,
        comfort_shift_steps: u8,
        limit_shift_steps: u8,
        prefers_low_tension: bool,
    ) HandProfile {
        return .{
            .finger_count = finger_count,
            .comfort_span_steps = comfort_span_steps,
            .limit_span_steps = limit_span_steps,
            .comfort_shift_steps = comfort_shift_steps,
            .limit_shift_steps = limit_shift_steps,
            .prefers_low_tension = prefers_low_tension,
            .reserved0 = 0,
            .reserved1 = 0,
        };
    }
};

pub const TemporalLoadState = struct {
    event_count: u8,
    last_anchor_step: u8,
    last_span_steps: u8,
    last_shift_steps: u8,
    peak_span_steps: u8,
    peak_shift_steps: u8,
    cumulative_span_steps: u16,
    cumulative_shift_steps: u16,

    pub fn init() TemporalLoadState {
        return .{
            .event_count = 0,
            .last_anchor_step = 0,
            .last_span_steps = 0,
            .last_shift_steps = 0,
            .peak_span_steps = 0,
            .peak_shift_steps = 0,
            .cumulative_span_steps = 0,
            .cumulative_shift_steps = 0,
        };
    }

    pub fn observe(self: *TemporalLoadState, anchor_step: u8, span_steps: u8) void {
        const shift_steps: u8 = if (self.event_count == 0)
            0
        else
            @as(u8, @intCast(@abs(@as(i16, anchor_step) - @as(i16, self.last_anchor_step))));

        self.event_count +|= 1;
        self.last_anchor_step = anchor_step;
        self.last_span_steps = span_steps;
        self.last_shift_steps = shift_steps;
        if (span_steps > self.peak_span_steps) self.peak_span_steps = span_steps;
        if (shift_steps > self.peak_shift_steps) self.peak_shift_steps = shift_steps;
        self.cumulative_span_steps +|= span_steps;
        self.cumulative_shift_steps +|= shift_steps;
    }
};

test "temporal load state accumulates anchor and span history" {
    var load = TemporalLoadState.init();
    load.observe(3, 4);
    try std.testing.expectEqual(@as(u8, 1), load.event_count);
    try std.testing.expectEqual(@as(u8, 3), load.last_anchor_step);
    try std.testing.expectEqual(@as(u8, 4), load.last_span_steps);
    try std.testing.expectEqual(@as(u8, 0), load.last_shift_steps);
    try std.testing.expectEqual(@as(u8, 4), load.peak_span_steps);
    try std.testing.expectEqual(@as(u16, 4), load.cumulative_span_steps);

    load.observe(6, 5);
    try std.testing.expectEqual(@as(u8, 2), load.event_count);
    try std.testing.expectEqual(@as(u8, 3), load.last_shift_steps);
    try std.testing.expectEqual(@as(u8, 5), load.peak_span_steps);
    try std.testing.expectEqual(@as(u8, 3), load.peak_shift_steps);
    try std.testing.expectEqual(@as(u16, 9), load.cumulative_span_steps);
    try std.testing.expectEqual(@as(u16, 3), load.cumulative_shift_steps);
}
