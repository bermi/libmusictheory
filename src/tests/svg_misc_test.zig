const std = @import("std");
const testing = std.testing;

const set_class = @import("../set_class.zig");
const pitch = @import("../pitch.zig");
const key_signature = @import("../key_signature.zig");

const mode_icon = @import("../svg/mode_icon.zig");
const evenness_chart = @import("../svg/evenness_chart.zig");
const orbifold = @import("../svg/orbifold.zig");
const circle_of_fifths = @import("../svg/circle_of_fifths.zig");
const key_sig = @import("../svg/key_sig.zig");
const text_misc = @import("../svg/text_misc.zig");
const n_tet_chart = @import("../svg/n_tet_chart.zig");

fn countSubstring(haystack: []const u8, needle: []const u8) usize {
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, haystack, pos, needle)) |idx| {
        count += 1;
        pos = idx + needle.len;
    }
    return count;
}

test "mode icon color mapping and svg validity" {
    const spec = mode_icon.ModeIconSpec{
        .family = .diatonic,
        .transposition = 0,
        .degree = 1,
    };

    var buf: [4096]u8 = undefined;
    const svg = mode_icon.renderModeIcon(spec, &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"70\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "height=\"70\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "fill=\"#00C\"") != null);
}

test "evenness chart ring counts match set class cardinality counts" {
    var dot_buf: [evenness_chart.MAX_DOTS]evenness_chart.Dot = undefined;
    const dots = evenness_chart.computeDots(&dot_buf);

    var expected: [13]u16 = [_]u16{0} ** 13;
    for (set_class.SET_CLASSES) |sc| {
        expected[sc.cardinality] += 1;
    }

    for (3..10) |card| {
        var got: u16 = 0;
        for (dots) |dot| {
            if (dot.cardinality == card) got += 1;
        }
        try testing.expectEqual(expected[card], got);
    }

    var svg_buf: [131072]u8 = undefined;
    const svg = evenness_chart.renderEvennessChart(&svg_buf);
    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"dot\"") != null);
}

test "circle of fifths order and svg validity" {
    const order = circle_of_fifths.fifthsOrder();
    const expected = [_]pitch.PitchClass{ 0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5 };
    try testing.expectEqualSlices(pitch.PitchClass, &expected, &order);

    var buf: [32768]u8 = undefined;
    const svg = circle_of_fifths.renderCircleOfFifths(&buf);
    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"100\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ">C<") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ">G<") != null);
}

test "orbifold graph svg validity" {
    var buf: [262144]u8 = undefined;
    const svg = orbifold.renderTriadOrbifold(&buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "viewBox=\"0 0 540 540\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"orbifold-node\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"orbifold-edge\"") != null);
}

test "key signature renders expected sharp count" {
    var buf: [65536]u8 = undefined;
    const sig = key_signature.fromTonic(pitch.pc.Fs, .major);
    const svg = key_sig.renderKeySignature(sig, &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"133\"") != null);
    try testing.expectEqual(@as(usize, 6), countSubstring(svg, "class=\"accidental sharp\""));
    try testing.expectEqual(@as(usize, 0), countSubstring(svg, "class=\"accidental flat\""));
}

test "vertical and center text svg validity" {
    var vertical_buf: [4096]u8 = undefined;
    const vertical = text_misc.renderVerticalLabel("6-1", false, &vertical_buf);
    try testing.expect(std.mem.startsWith(u8, vertical, "<svg"));
    try testing.expect(std.mem.indexOf(u8, vertical, "rotate(90)") != null);

    var center_buf: [4096]u8 = undefined;
    const center = text_misc.renderCenterSquareGlyph("A", &center_buf);
    try testing.expect(std.mem.startsWith(u8, center, "<svg"));
    try testing.expect(std.mem.indexOf(u8, center, ">A<") != null);
}

test "n tet chart svg validity" {
    var buf: [16384]u8 = undefined;
    const svg = n_tet_chart.renderNTetChart(&buf);
    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "N-TET Error") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"n-tet-bar\"") != null);
}
