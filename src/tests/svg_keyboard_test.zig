const testing = @import("std").testing;
const std = @import("std");

const pitch = @import("../pitch.zig");
const keyboard_svg = @import("../svg/keyboard_svg.zig");

test "keyboard svg renders selected and echoed keys with palette classes" {
    var buf: [64 * 1024]u8 = undefined;
    const notes = [_]pitch.MidiNote{ 60, 64, 67 };
    const svg = keyboard_svg.renderKeyboard(notes[0..], 48, 72, &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key white-key is-selected\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key white-key is-echo\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key black-key black-key-base\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "data-midi=\"60\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "shape-rendering=\"geometricPrecision\"") != null);
}

test "keyboard svg underpaints black echo keys before tint overlays" {
    var buf: [64 * 1024]u8 = undefined;
    const notes = [_]pitch.MidiNote{ 61, 63, 64, 66, 68, 69, 71, 73 };
    const svg = keyboard_svg.renderKeyboard(notes[0..], 48, 84, &buf);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key black-key black-key-base\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key black-key black-key-overlay is-selected\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"keyboard-key black-key black-key-overlay is-echo\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "stroke=\"none\"") != null);
}
