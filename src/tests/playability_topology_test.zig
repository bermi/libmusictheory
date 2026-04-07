const std = @import("std");
const testing = std.testing;
const pitch = @import("../pitch.zig");
const fret_topology = @import("../playability/fret_topology.zig");
const keyboard_topology = @import("../playability/keyboard_topology.zig");
const guitar = @import("../guitar.zig");

test "fret topology open strings remain in window" {
    const profile = fret_topology.defaultHandProfile();
    try testing.expect(fret_topology.isFretInWindow(0, 7, profile));
    try testing.expectEqual(@as(u8, 0), fret_topology.shiftStepsForFret(0, 7, profile));
}

test "fret topology describes open C shape" {
    const profile = fret_topology.defaultHandProfile();
    const state = fret_topology.describeState(&[_]i8{ -1, 3, 2, 0, 1, 0 }, profile, null);
    try testing.expectEqual(@as(u8, 1), state.lowest_string);
    try testing.expectEqual(@as(u8, 5), state.highest_string);
    try testing.expectEqual(@as(u8, 1), state.load.last_anchor_step);
}

test "fret topology windowed positions use current anchor" {
    const profile = fret_topology.defaultHandProfile();
    var out: [fret_topology.MAX_WINDOWED_LOCATIONS]fret_topology.WindowedLocation = undefined;
    const positions = fret_topology.windowedLocationsForMidi(60, guitar.tunings.STANDARD[0..], 7, profile, out[0..]);
    try testing.expectEqual(@as(usize, 5), positions.len);
    try testing.expect(positions[2].in_window);
}

test "keyboard topology counts black and white keys" {
    const profile = keyboard_topology.defaultHandProfile();
    const state = keyboard_topology.describeState(&[_]pitch.MidiNote{ 61, 64, 68 }, profile, null);
    try testing.expectEqual(@as(u8, 2), state.black_key_count);
    try testing.expectEqual(@as(u8, 1), state.white_key_count);
    try testing.expectEqual(@as(u8, 7), state.span_semitones);
}
