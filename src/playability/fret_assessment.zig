const std = @import("std");
const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const fret_topology = @import("fret_topology.zig");
const types = @import("types.zig");

pub const MAX_FINGER_LABELS: usize = guitar.MAX_GENERIC_STRINGS;
pub const MAX_RANKED_LOCATIONS: usize = guitar.MAX_GENERIC_STRINGS;

pub const TechniqueProfile = enum(u8) {
    generic_guitar = 0,
    bass_simandl = 1,
    bass_ofpf = 2,
    extended_range_classical_thumb = 3,
};

pub const PROFILE_NAMES = [_][]const u8{
    "generic guitar",
    "bass simandl",
    "bass ofpf",
    "extended-range classical thumb",
};

pub const BlockerKind = enum(u8) {
    span_hard_limit = 0,
    shift_hard_limit = 1,
    string_span_hard_limit = 2,
    finger_overload = 3,
    unsupported_extension = 4,
};

pub const BLOCKER_NAMES = [_][]const u8{
    "span hard limit exceeded",
    "shift hard limit exceeded",
    "string-span hard limit exceeded",
    "finger overload",
    "unsupported extension",
};

const ProfileSpec = struct {
    hand: types.HandProfile,
    comfort_string_span: u8,
    limit_string_span: u8,
    low_position_warning_span: ?u8,
    low_position_blocker_span: ?u8,
    warn_on_fourth_finger_low_position: bool,
};

pub const RealizationAssessment = struct {
    state: fret_topology.PlayState,
    string_span_steps: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    profile: TechniqueProfile,
    recommended_fingers: [MAX_FINGER_LABELS]u8,
};

pub const TransitionAssessment = struct {
    from_state: fret_topology.PlayState,
    to_state: fret_topology.PlayState,
    anchor_delta_steps: u8,
    changed_string_count: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    profile: TechniqueProfile,
    recommended_fingers: [MAX_FINGER_LABELS]u8,
};

pub const RankedLocation = struct {
    location: fret_topology.WindowedLocation,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_finger: u8,
    profile: TechniqueProfile,
};

pub fn fromInt(raw: u8) ?TechniqueProfile {
    return switch (raw) {
        0 => .generic_guitar,
        1 => .bass_simandl,
        2 => .bass_ofpf,
        3 => .extended_range_classical_thumb,
        else => null,
    };
}

pub fn defaultHandProfile(profile: TechniqueProfile) types.HandProfile {
    return spec(profile).hand;
}

pub fn assessRealization(
    frets: []const i8,
    tuning: []const pitch.MidiNote,
    profile: TechniqueProfile,
    hand_override: ?types.HandProfile,
    previous_load: ?types.TemporalLoadState,
) RealizationAssessment {
    const hand = hand_override orelse defaultHandProfile(profile);
    const state = fret_topology.describeState(frets, hand, previous_load);
    return buildRealizationAssessment(frets, tuning, state, profile, hand, previous_load);
}

pub fn assessTransition(
    from_frets: []const i8,
    to_frets: []const i8,
    tuning: []const pitch.MidiNote,
    profile: TechniqueProfile,
    hand_override: ?types.HandProfile,
) TransitionAssessment {
    const hand = hand_override orelse defaultHandProfile(profile);
    const from_state = fret_topology.describeState(from_frets, hand, null);
    const to_state = fret_topology.describeState(to_frets, hand, from_state.load);
    const realization = buildRealizationAssessment(to_frets, tuning, to_state, profile, hand, from_state.load);

    var reason_bits = realization.reason_bits;
    var warning_bits = realization.warning_bits;
    var blocker_bits = realization.blocker_bits;

    const anchor_delta = to_state.load.last_shift_steps;
    const changed_string_count = countChangedStrings(from_frets, to_frets);

    if (anchor_delta > hand.comfort_shift_steps) {
        setWarningBit(&warning_bits, .excessive_longitudinal_shift);
    }
    if (from_state.span_steps >= hand.comfort_span_steps and to_state.span_steps >= hand.comfort_span_steps) {
        setWarningBit(&warning_bits, .repeated_maximal_stretch);
    }
    if (anchor_delta > hand.limit_shift_steps) {
        setBlockerBit(&blocker_bits, .shift_hard_limit);
        setWarningBit(&warning_bits, .hard_limit_exceeded);
    }

    const from_bottleneck = max3(@as(u16, from_state.span_steps), @as(u16, from_state.load.last_shift_steps), @as(u16, stringSpanSteps(from_frets)));
    const to_bottleneck = max3(realization.bottleneck_cost, @as(u16, anchor_delta), @as(u16, realization.string_span_steps));
    if (to_bottleneck < from_bottleneck) {
        setReasonBit(&reason_bits, .bottleneck_reduced);
    }
    if (to_state.open_string_count > from_state.open_string_count) {
        setReasonBit(&reason_bits, .open_string_relief);
    }

    return .{
        .from_state = from_state,
        .to_state = to_state,
        .anchor_delta_steps = anchor_delta,
        .changed_string_count = changed_string_count,
        .bottleneck_cost = to_bottleneck,
        .cumulative_cost = @as(u16, from_state.span_steps) + @as(u16, from_state.load.last_shift_steps) +
            @as(u16, stringSpanSteps(from_frets)) + realization.cumulative_cost,
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
        .profile = profile,
        .recommended_fingers = realization.recommended_fingers,
    };
}

pub fn rankLocationsForMidi(
    note: pitch.MidiNote,
    tuning: []const pitch.MidiNote,
    anchor_fret: u8,
    profile: TechniqueProfile,
    hand_override: ?types.HandProfile,
    out: []RankedLocation,
) []RankedLocation {
    const hand = hand_override orelse defaultHandProfile(profile);
    var locations_buf: [fret_topology.MAX_WINDOWED_LOCATIONS]fret_topology.WindowedLocation = undefined;
    const locations = fret_topology.windowedLocationsForMidi(note, tuning, anchor_fret, hand, locations_buf[0..]);
    const write_len = @min(out.len, locations.len);
    const multiple_locations = locations.len > 1;

    for (locations[0..write_len], 0..) |location, index| {
        var reason_bits: u32 = 0;
        var warning_bits: u32 = 0;
        var blocker_bits: u32 = 0;
        setReasonBit(&reason_bits, .reachable_location);
        if (location.in_window) {
            setReasonBit(&reason_bits, .reachable_in_current_window);
            if (location.position.fret != 0 and location.position.fret == anchor_fret) {
                setReasonBit(&reason_bits, .reuses_current_anchor);
            }
        } else {
            setReasonBit(&reason_bits, .expands_current_window);
            setWarningBit(&warning_bits, .shift_required);
        }
        if (multiple_locations) {
            setReasonBit(&reason_bits, .multiple_locations_available);
        }
        if (location.position.fret == 0) {
            setReasonBit(&reason_bits, .open_string_relief);
        }
        if (profile != .generic_guitar) {
            setReasonBit(&reason_bits, .technique_profile_applied);
        }

        if (location.shift_steps > hand.comfort_shift_steps) {
            setWarningBit(&warning_bits, .comfort_window_exceeded);
            setWarningBit(&warning_bits, .excessive_longitudinal_shift);
        }
        if (location.shift_steps > hand.limit_shift_steps) {
            setBlockerBit(&blocker_bits, .shift_hard_limit);
            setWarningBit(&warning_bits, .hard_limit_exceeded);
        }

        const recommended_finger = fingerForFret(location.position.fret, anchor_fret, profile);
        if (warnsOnLowPositionFourthFinger(profile) and anchor_fret > 0 and anchor_fret < 5 and recommended_finger == 4) {
            setWarningBit(&warning_bits, .weak_finger_stress);
        }

        out[index] = .{
            .location = location,
            .bottleneck_cost = location.shift_steps,
            .cumulative_cost = location.shift_steps,
            .blocker_bits = blocker_bits,
            .warning_bits = warning_bits,
            .reason_bits = reason_bits,
            .recommended_finger = recommended_finger,
            .profile = profile,
        };
    }

    insertionSortRanked(out[0..write_len], hand.prefers_low_tension);
    return out[0..write_len];
}

fn buildRealizationAssessment(
    frets: []const i8,
    tuning: []const pitch.MidiNote,
    state: fret_topology.PlayState,
    profile: TechniqueProfile,
    hand: types.HandProfile,
    previous_load: ?types.TemporalLoadState,
) RealizationAssessment {
    _ = tuning;
    const profile_spec = spec(profile);
    const string_span = stringSpanSteps(frets);
    const finger_overload = frettedFingerDemand(frets) > hand.finger_count;

    var recommended_fingers = [_]u8{255} ** MAX_FINGER_LABELS;
    writeFingerLabels(&recommended_fingers, frets, state.anchor_fret, profile);

    var reason_bits: u32 = 0;
    var warning_bits: u32 = 0;
    var blocker_bits: u32 = 0;

    setReasonBit(&reason_bits, .reachable_location);
    if (state.load.last_shift_steps == 0) {
        setReasonBit(&reason_bits, .reachable_in_current_window);
        if (previous_load != null and state.anchor_fret == previous_load.?.last_anchor_step) {
            setReasonBit(&reason_bits, .reuses_current_anchor);
        }
    } else {
        setReasonBit(&reason_bits, .expands_current_window);
    }
    if (state.open_string_count > 0) {
        setReasonBit(&reason_bits, .open_string_relief);
    }
    if (profile != .generic_guitar) {
        setReasonBit(&reason_bits, .technique_profile_applied);
    }

    if (state.load.last_shift_steps > 0) {
        setWarningBit(&warning_bits, .shift_required);
    }
    if (!state.comfort_fit or state.load.last_shift_steps > hand.comfort_shift_steps or string_span > profile_spec.comfort_string_span) {
        setWarningBit(&warning_bits, .comfort_window_exceeded);
    }
    if (state.load.last_shift_steps > hand.comfort_shift_steps) {
        setWarningBit(&warning_bits, .excessive_longitudinal_shift);
    }
    if (finger_overload) {
        setWarningBit(&warning_bits, .ambiguous_hand_assignment);
        setBlockerBit(&blocker_bits, .finger_overload);
    }
    if (previous_load != null and previous_load.?.last_span_steps >= hand.comfort_span_steps and state.span_steps >= hand.comfort_span_steps) {
        setWarningBit(&warning_bits, .repeated_maximal_stretch);
    }
    if (warnsOnLowPositionFourthFinger(profile) and state.anchor_fret > 0 and state.anchor_fret < 5 and anyFingerLabel(recommended_fingers, 4)) {
        setWarningBit(&warning_bits, .weak_finger_stress);
    }
    if (needsUnsupportedExtensionWarning(profile, state.anchor_fret, state.span_steps, string_span)) {
        setWarningBit(&warning_bits, .unsupported_extension);
    }

    if (!state.limit_fit) {
        setBlockerBit(&blocker_bits, .span_hard_limit);
    }
    if (state.load.last_shift_steps > hand.limit_shift_steps) {
        setBlockerBit(&blocker_bits, .shift_hard_limit);
    }
    if (string_span > profile_spec.limit_string_span) {
        setBlockerBit(&blocker_bits, .string_span_hard_limit);
    }
    if (needsUnsupportedExtensionBlocker(profile, state.anchor_fret, state.span_steps, string_span)) {
        setBlockerBit(&blocker_bits, .unsupported_extension);
    }
    if (blocker_bits != 0) {
        setWarningBit(&warning_bits, .hard_limit_exceeded);
    }

    const bottleneck_cost = max3(
        @as(u16, state.span_steps),
        @as(u16, state.load.last_shift_steps),
        @as(u16, string_span),
    );
    const cumulative_cost = @as(u16, state.span_steps) + @as(u16, state.load.last_shift_steps) + @as(u16, string_span);

    return .{
        .state = state,
        .string_span_steps = string_span,
        .bottleneck_cost = bottleneck_cost,
        .cumulative_cost = cumulative_cost,
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
        .profile = profile,
        .recommended_fingers = recommended_fingers,
    };
}

fn spec(profile: TechniqueProfile) ProfileSpec {
    return switch (profile) {
        .generic_guitar => .{
            .hand = types.HandProfile.init(4, 4, 5, 4, 7, true),
            .comfort_string_span = 4,
            .limit_string_span = 5,
            .low_position_warning_span = null,
            .low_position_blocker_span = null,
            .warn_on_fourth_finger_low_position = false,
        },
        .bass_simandl => .{
            .hand = types.HandProfile.init(3, 2, 3, 3, 6, true),
            .comfort_string_span = 3,
            .limit_string_span = 4,
            .low_position_warning_span = 2,
            .low_position_blocker_span = 3,
            .warn_on_fourth_finger_low_position = false,
        },
        .bass_ofpf => .{
            .hand = types.HandProfile.init(4, 3, 4, 3, 6, false),
            .comfort_string_span = 3,
            .limit_string_span = 4,
            .low_position_warning_span = null,
            .low_position_blocker_span = null,
            .warn_on_fourth_finger_low_position = true,
        },
        .extended_range_classical_thumb => .{
            .hand = types.HandProfile.init(4, 4, 5, 4, 7, true),
            .comfort_string_span = 3,
            .limit_string_span = 4,
            .low_position_warning_span = null,
            .low_position_blocker_span = null,
            .warn_on_fourth_finger_low_position = false,
        },
    };
}

fn stringSpanSteps(frets: []const i8) u8 {
    var has_active = false;
    var min_string: usize = std.math.maxInt(usize);
    var max_string: usize = 0;
    for (frets, 0..) |fret, string_index| {
        if (fret < 0) continue;
        has_active = true;
        if (string_index < min_string) min_string = string_index;
        if (string_index > max_string) max_string = string_index;
    }
    if (!has_active) return 0;
    return @as(u8, @intCast(max_string - min_string));
}

fn frettedFingerDemand(frets: []const i8) u8 {
    var count: u8 = 0;
    for (frets) |fret| {
        if (fret > 0) count += 1;
    }
    return count;
}

fn countChangedStrings(from_frets: []const i8, to_frets: []const i8) u8 {
    const count = @min(from_frets.len, to_frets.len);
    var changed: u8 = 0;
    for (0..count) |index| {
        if (from_frets[index] != to_frets[index]) changed += 1;
    }
    return changed;
}

fn writeFingerLabels(out: *[MAX_FINGER_LABELS]u8, frets: []const i8, anchor_fret: u8, profile: TechniqueProfile) void {
    @memset(out, 255);
    const count = @min(out.len, frets.len);
    for (frets[0..count], 0..) |fret, index| {
        out[index] = if (fret < 0)
            255
        else if (fret == 0)
            0
        else
            fingerForFret(@as(u8, @intCast(fret)), anchor_fret, profile);
    }
}

fn fingerForFret(fret: u8, anchor_fret: u8, profile: TechniqueProfile) u8 {
    if (fret == 0) return 0;
    const anchor = if (anchor_fret == 0) fret else anchor_fret;
    const relative = if (fret > anchor) fret - anchor else 0;
    return switch (profile) {
        .bass_simandl => switch (relative) {
            0 => 1,
            1 => 2,
            else => 4,
        },
        else => switch (relative) {
            0 => 1,
            1 => 2,
            2 => 3,
            else => 4,
        },
    };
}

fn warnsOnLowPositionFourthFinger(profile: TechniqueProfile) bool {
    return spec(profile).warn_on_fourth_finger_low_position;
}

fn anyFingerLabel(labels: [MAX_FINGER_LABELS]u8, target: u8) bool {
    for (labels) |label| {
        if (label == target) return true;
    }
    return false;
}

fn needsUnsupportedExtensionWarning(profile: TechniqueProfile, anchor_fret: u8, span_steps: u8, string_span: u8) bool {
    const profile_spec = spec(profile);
    if (profile == .extended_range_classical_thumb and string_span > profile_spec.comfort_string_span) return true;
    if (profile_spec.low_position_warning_span) |threshold| {
        if (anchor_fret > 0 and anchor_fret < 5 and span_steps > threshold) return true;
    }
    return false;
}

fn needsUnsupportedExtensionBlocker(profile: TechniqueProfile, anchor_fret: u8, span_steps: u8, string_span: u8) bool {
    const profile_spec = spec(profile);
    if (profile == .extended_range_classical_thumb and string_span > profile_spec.limit_string_span) return true;
    if (profile_spec.low_position_blocker_span) |threshold| {
        if (anchor_fret > 0 and anchor_fret < 5 and span_steps > threshold) return true;
    }
    return false;
}

fn max3(a: u16, b: u16, c: u16) u16 {
    return @max(a, @max(b, c));
}

fn setReasonBit(bits: *u32, kind: types.ReasonKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn setWarningBit(bits: *u32, kind: types.WarningKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn setBlockerBit(bits: *u32, kind: BlockerKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn insertionSortRanked(items: []RankedLocation, prefer_open_strings: bool) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and rankedBefore(items[j], items[j - 1], prefer_open_strings)) : (j -= 1) {
            const tmp = items[j - 1];
            items[j - 1] = items[j];
            items[j] = tmp;
        }
    }
}

fn rankedBefore(a: RankedLocation, b: RankedLocation, prefer_open_strings: bool) bool {
    const a_playable = a.blocker_bits == 0;
    const b_playable = b.blocker_bits == 0;
    if (a_playable != b_playable) return a_playable;
    if (a.location.in_window != b.location.in_window) return a.location.in_window;
    if (a.location.shift_steps != b.location.shift_steps) return a.location.shift_steps < b.location.shift_steps;
    if (prefer_open_strings and (a.location.position.fret == 0) != (b.location.position.fret == 0)) return a.location.position.fret == 0;
    if (a.location.position.fret != b.location.position.fret) return a.location.position.fret < b.location.position.fret;
    return a.location.position.string < b.location.position.string;
}
