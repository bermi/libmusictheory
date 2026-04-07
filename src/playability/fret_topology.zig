const std = @import("std");
const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const types = @import("types.zig");

pub const MAX_WINDOWED_LOCATIONS: usize = guitar.MAX_GENERIC_STRINGS;

pub const WindowedLocation = struct {
    position: guitar.GenericFretPosition,
    in_window: bool,
    shift_steps: u8,
};

pub const PlayState = struct {
    anchor_fret: u8,
    window_start: u8,
    window_end: u8,
    lowest_string: u8,
    highest_string: u8,
    active_string_count: u8,
    fretted_note_count: u8,
    open_string_count: u8,
    span_steps: u8,
    comfort_fit: bool,
    limit_fit: bool,
    load: types.TemporalLoadState,
};

pub fn defaultHandProfile() types.HandProfile {
    return types.HandProfile.init(4, 4, 5, 4, 7, true);
}

pub fn currentWindowStart(anchor_fret: u8) u8 {
    return if (anchor_fret == 0) 0 else anchor_fret;
}

pub fn currentWindowEnd(anchor_fret: u8, profile: types.HandProfile) u8 {
    const end = @as(u16, currentWindowStart(anchor_fret)) + profile.comfort_span_steps;
    return @as(u8, @intCast(@min(end, guitar.MAX_FRET)));
}

pub fn isFretInWindow(fret: u8, anchor_fret: u8, profile: types.HandProfile) bool {
    if (fret == 0) return true;
    const window_start = currentWindowStart(anchor_fret);
    const window_end = currentWindowEnd(anchor_fret, profile);
    return fret >= window_start and fret <= window_end;
}

pub fn shiftStepsForFret(fret: u8, anchor_fret: u8, profile: types.HandProfile) u8 {
    if (fret == 0) return 0;
    const window_start = currentWindowStart(anchor_fret);
    const window_end = currentWindowEnd(anchor_fret, profile);
    if (fret < window_start) return window_start - fret;
    if (fret > window_end) return fret - window_end;
    return 0;
}

pub fn describeState(frets: []const i8, profile: types.HandProfile, previous_load: ?types.TemporalLoadState) PlayState {
    var anchor_fret: u8 = 0;
    var min_positive: u8 = std.math.maxInt(u8);
    var max_positive: u8 = 0;
    var lowest_string: u8 = std.math.maxInt(u8);
    var highest_string: u8 = 0;
    var active_string_count: u8 = 0;
    var fretted_note_count: u8 = 0;
    var open_string_count: u8 = 0;

    for (frets, 0..) |fret, string_index| {
        if (fret < 0) continue;
        active_string_count += 1;
        const string_u8 = @as(u8, @intCast(string_index));
        if (string_u8 < lowest_string) lowest_string = string_u8;
        if (string_u8 > highest_string) highest_string = string_u8;
        if (fret == 0) {
            open_string_count += 1;
            continue;
        }
        fretted_note_count += 1;
        const fret_u8 = @as(u8, @intCast(fret));
        if (fret_u8 < min_positive) min_positive = fret_u8;
        if (fret_u8 > max_positive) max_positive = fret_u8;
    }

    if (fretted_note_count > 0) anchor_fret = min_positive;
    const span_steps: u8 = if (fretted_note_count == 0) 0 else max_positive - min_positive;
    var load = previous_load orelse types.TemporalLoadState.init();
    load.observe(anchor_fret, span_steps);

    return .{
        .anchor_fret = anchor_fret,
        .window_start = currentWindowStart(anchor_fret),
        .window_end = currentWindowEnd(anchor_fret, profile),
        .lowest_string = if (active_string_count == 0) 0 else lowest_string,
        .highest_string = if (active_string_count == 0) 0 else highest_string,
        .active_string_count = active_string_count,
        .fretted_note_count = fretted_note_count,
        .open_string_count = open_string_count,
        .span_steps = span_steps,
        .comfort_fit = span_steps <= profile.comfort_span_steps,
        .limit_fit = span_steps <= profile.limit_span_steps,
        .load = load,
    };
}

pub fn windowedLocationsForMidi(note: pitch.MidiNote, tuning: []const pitch.MidiNote, anchor_fret: u8, profile: types.HandProfile, out: []WindowedLocation) []WindowedLocation {
    var raw_positions: [MAX_WINDOWED_LOCATIONS]guitar.GenericFretPosition = undefined;
    const positions = guitar.midiToFretPositionsGeneric(note, tuning, raw_positions[0..]);
    const write_count = @min(out.len, positions.len);
    for (positions[0..write_count], 0..) |pos, index| {
        out[index] = .{
            .position = pos,
            .in_window = isFretInWindow(pos.fret, anchor_fret, profile),
            .shift_steps = shiftStepsForFret(pos.fret, anchor_fret, profile),
        };
    }
    return out[0..write_count];
}

test "describe state derives anchor and span from fretted notes" {
    const profile = defaultHandProfile();
    const state = describeState(&[_]i8{ -1, 3, 2, 0, 1, 0 }, profile, null);
    try std.testing.expectEqual(@as(u8, 1), state.anchor_fret);
    try std.testing.expectEqual(@as(u8, 1), state.window_start);
    try std.testing.expectEqual(@as(u8, 5), state.window_end);
    try std.testing.expectEqual(@as(u8, 5), state.active_string_count);
    try std.testing.expectEqual(@as(u8, 3), state.fretted_note_count);
    try std.testing.expectEqual(@as(u8, 2), state.open_string_count);
    try std.testing.expectEqual(@as(u8, 2), state.span_steps);
    try std.testing.expect(state.comfort_fit);
    try std.testing.expect(state.limit_fit);
}

test "windowed locations annotate in-window and shift steps" {
    const profile = defaultHandProfile();
    var out: [MAX_WINDOWED_LOCATIONS]WindowedLocation = undefined;
    const positions = windowedLocationsForMidi(60, guitar.tunings.STANDARD[0..], 7, profile, out[0..]);
    try std.testing.expect(positions.len > 0);
    try std.testing.expectEqual(@as(usize, 5), positions.len);
    try std.testing.expectEqual(@as(usize, 1), positions[1].position.string);
    try std.testing.expectEqual(@as(u8, 15), positions[1].position.fret);
    try std.testing.expect(!positions[1].in_window);
    try std.testing.expectEqual(@as(u8, 4), positions[1].shift_steps);
    try std.testing.expectEqual(@as(usize, 2), positions[2].position.string);
    try std.testing.expectEqual(@as(u8, 10), positions[2].position.fret);
    try std.testing.expect(positions[2].in_window);
    try std.testing.expectEqual(@as(u8, 0), positions[2].shift_steps);
}
