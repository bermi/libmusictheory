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
}

test "dot positions and open muted markers" {
    const voicing = guitar.GuitarVoicing{ .frets = .{ -1, 3, 2, 0, 1, 0 }, .tuning = guitar.tunings.STANDARD };

    var buf: [8192]u8 = undefined;
    const svg = fret.renderFretDiagram(voicing, &buf);

    const dot = "<circle class=\"dot\" cx=\"32.00\" cy=\"57.50\" r=\"4\" fill=\"black\" />";
    try testing.expect(std.mem.indexOf(u8, svg, dot) != null);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"open\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"muted\"") != null);
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
