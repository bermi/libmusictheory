const testing = @import("std").testing;
const std = @import("std");

const guitar = @import("../guitar.zig");
const fret = @import("../svg/fret.zig");

test "fret diagram svg validity and dimensions" {
    const voicing = guitar.GuitarVoicing{ .frets = .{ -1, 3, 2, 0, 1, 0 }, .tuning = guitar.tunings.STANDARD };

    var buf: [8192]u8 = undefined;
    const svg = fret.renderFretDiagram(voicing, &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"100\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "height=\"100\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "shape-rendering=\"geometricPrecision\"") != null);
}

test "dot positions and open muted markers" {
    const voicing = guitar.GuitarVoicing{ .frets = .{ -1, 3, 2, 0, 1, 0 }, .tuning = guitar.tunings.STANDARD };

    var buf: [8192]u8 = undefined;
    const svg = fret.renderFretDiagram(voicing, &buf);

    const dot = "<circle class=\"dot\" cx=\"32.00\" cy=\"57.50\" r=\"4.35\" />";
    try testing.expect(std.mem.indexOf(u8, svg, dot) != null);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"marker-open\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"marker-muted\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ">X</text>") == null);
    try testing.expect(std.mem.indexOf(u8, svg, ">O</text>") == null);
}

test "barre detection" {
    const f_major_barre = guitar.GuitarVoicing{ .frets = .{ 1, 3, 3, 2, 1, 1 }, .tuning = guitar.tunings.STANDARD };
    const barre = fret.detectBarre(f_major_barre).?;

    try testing.expectEqual(@as(u5, 1), barre.fret);
    try testing.expectEqual(@as(u3, 0), barre.low_string);
    try testing.expectEqual(@as(u3, 5), barre.high_string);

    var buf: [8192]u8 = undefined;
    const svg = fret.renderFretDiagram(f_major_barre, &buf);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"barre\"") != null);
}

test "generic fret diagram supports four strings" {
    const frets = [_]i8{ 0, 0, 0, 3 };

    var buf: [8192]u8 = undefined;
    const svg = fret.renderDiagram(.{ .frets = frets[0..] }, &buf);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"position\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ">3</text>") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "cx=\"80.00\" cy=\"27.50\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"marker-open\"") != null);
}

test "generic fret diagram supports explicit fret windows" {
    const frets = [_]i8{ 7, 9, 9, 8, 7, 7, 7 };

    var buf: [8192]u8 = undefined;
    const svg = fret.renderDiagram(.{ .frets = frets[0..], .window_start = 5, .visible_frets = 5 }, &buf);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"position\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ">6</text>") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "y2=\"95.00\"") != null);
}

test "generic fret diagram detects barres on wider instruments" {
    const frets = [_]i8{ 1, 3, 3, 2, 1, 1, 1 };

    const barre = fret.detectBarreForFrets(frets[0..]).?;
    try testing.expectEqual(@as(u32, 1), barre.fret);
    try testing.expectEqual(@as(usize, 0), barre.low_string);
    try testing.expectEqual(@as(usize, 6), barre.high_string);
}
