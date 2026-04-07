const std = @import("std");
const pitch = @import("../pitch.zig");
const types = @import("types.zig");

pub const KeyCoord = struct {
    midi: pitch.MidiNote,
    is_black: bool,
    octave: u8,
    degree_in_octave: u8,
    x: f32,
    y: f32,
};

pub const PlayState = struct {
    anchor_midi: pitch.MidiNote,
    low_midi: pitch.MidiNote,
    high_midi: pitch.MidiNote,
    active_note_count: u8,
    black_key_count: u8,
    white_key_count: u8,
    span_semitones: u8,
    comfort_fit: bool,
    limit_fit: bool,
    load: types.TemporalLoadState,
};

const KEY_X_OFFSETS = [12]f32{ 0.0, 0.65, 1.0, 1.65, 2.0, 3.0, 3.65, 4.0, 4.65, 5.0, 5.65, 6.0 };

pub fn defaultHandProfile() types.HandProfile {
    return types.HandProfile.init(5, 12, 14, 7, 12, true);
}

pub fn isBlackKey(pc: pitch.PitchClass) bool {
    return switch (pc) {
        1, 3, 6, 8, 10 => true,
        else => false,
    };
}

pub fn keyCoord(note: pitch.MidiNote) KeyCoord {
    const pc: pitch.PitchClass = @intCast(note % 12);
    const octave: u8 = @intCast(note / 12);
    return .{
        .midi = note,
        .is_black = isBlackKey(pc),
        .octave = octave,
        .degree_in_octave = pc,
        .x = @as(f32, @floatFromInt(octave)) * 7.0 + KEY_X_OFFSETS[pc],
        .y = if (isBlackKey(pc)) 1.0 else 0.0,
    };
}

pub fn describeState(notes: []const pitch.MidiNote, profile: types.HandProfile, previous_load: ?types.TemporalLoadState) PlayState {
    if (notes.len == 0) {
        return .{
            .anchor_midi = 0,
            .low_midi = 0,
            .high_midi = 0,
            .active_note_count = 0,
            .black_key_count = 0,
            .white_key_count = 0,
            .span_semitones = 0,
            .comfort_fit = true,
            .limit_fit = true,
            .load = previous_load orelse types.TemporalLoadState.init(),
        };
    }

    var low = notes[0];
    var high = notes[0];
    var black_key_count: u8 = 0;
    var white_key_count: u8 = 0;
    for (notes) |note| {
        if (note < low) low = note;
        if (note > high) high = note;
        if (isBlackKey(@intCast(note % 12)))
            black_key_count += 1
        else
            white_key_count += 1;
    }

    const span = high - low;
    const anchor_midi: pitch.MidiNote = @intCast((@as(u16, low) + @as(u16, high)) / 2);
    var load = previous_load orelse types.TemporalLoadState.init();
    load.observe(anchor_midi, span);

    return .{
        .anchor_midi = anchor_midi,
        .low_midi = low,
        .high_midi = high,
        .active_note_count = @as(u8, @intCast(notes.len)),
        .black_key_count = black_key_count,
        .white_key_count = white_key_count,
        .span_semitones = span,
        .comfort_fit = span <= profile.comfort_span_steps,
        .limit_fit = span <= profile.limit_span_steps,
        .load = load,
    };
}

test "key coordinates mark black keys and linear x positions" {
    const c4 = keyCoord(60);
    const cs4 = keyCoord(61);
    try std.testing.expectEqual(@as(f32, 35.0), c4.x);
    try std.testing.expectEqual(@as(f32, 35.65), cs4.x);
    try std.testing.expect(!c4.is_black);
    try std.testing.expect(cs4.is_black);
    try std.testing.expectEqual(@as(f32, 0.0), c4.y);
    try std.testing.expectEqual(@as(f32, 1.0), cs4.y);
}

test "keyboard play state derives span and black key exposure" {
    const profile = defaultHandProfile();
    const state = describeState(&[_]pitch.MidiNote{ 60, 64, 67 }, profile, null);
    try std.testing.expectEqual(@as(u8, 63), state.anchor_midi);
    try std.testing.expectEqual(@as(u8, 60), state.low_midi);
    try std.testing.expectEqual(@as(u8, 67), state.high_midi);
    try std.testing.expectEqual(@as(u8, 7), state.span_semitones);
    try std.testing.expectEqual(@as(u8, 0), state.black_key_count);
    try std.testing.expectEqual(@as(u8, 3), state.white_key_count);
    try std.testing.expect(state.comfort_fit);
    try std.testing.expect(state.limit_fit);
}
