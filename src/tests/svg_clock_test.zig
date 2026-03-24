const testing = @import("std").testing;
const std = @import("std");

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const clock = @import("../svg/clock.zig");
const clock_compat = @import("../svg/clock_compat.zig");

test "clock circle positions follow 30 degree steps" {
    const p0 = clock.circlePosition(0, 50.0, 42.0);
    try testing.expectApproxEqAbs(@as(f64, 50.0), p0.x, 0.0001);
    try testing.expectApproxEqAbs(@as(f64, 8.0), p0.y, 0.0001);

    const p3 = clock.circlePosition(3, 50.0, 42.0);
    try testing.expectApproxEqAbs(@as(f64, 92.0), p3.x, 0.0001);
    try testing.expectApproxEqAbs(@as(f64, 50.0), p3.y, 0.0001);
}

test "opc svg generation basic validity" {
    const set = pcs.C_MAJOR_TRIAD;
    var buf: [8192]u8 = undefined;
    const svg = clock.renderOPC(set, &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "</svg>") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"100\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"opc-node\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "shape-rendering=\"geometricPrecision\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "fill=\"white\"") != null);
}

test "optc cluster coloring and center label" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 2, 5 });
    var buf: [16384]u8 = undefined;
    const svg = clock.renderOPTC(set, "0125", &buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));

    const dark_blue_top = "<circle class=\"optc-node\" cx=\"50.00\" cy=\"8.00\" r=\"10\" stroke=\"#00c\" stroke-width=\"3\" fill=\"#00c\" />";
    try testing.expect(std.mem.indexOf(u8, svg, dark_blue_top) != null);

    const orange_pc5 = "<circle class=\"optc-node\" cx=\"71.00\" cy=\"86.37\" r=\"10\" stroke=\"#f91\" stroke-width=\"3\" fill=\"#f91\" />";
    try testing.expect(std.mem.indexOf(u8, svg, orange_pc5) != null);

    const hollow_pc3 = "<circle class=\"optc-node\" cx=\"92.00\" cy=\"50.00\" r=\"10\" stroke=\"#a16\" stroke-width=\"3\" fill=\"white\" />";
    try testing.expect(std.mem.indexOf(u8, svg, hollow_pc3) != null);

    try testing.expect(std.mem.indexOf(u8, svg, "<g transform=\"translate(") != null);
    try testing.expect(std.mem.indexOf(u8, svg, ") scale(") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "<path fill=\"#111\" d=\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "shape-rendering=\"geometricPrecision\"") != null);
}

test "optc harmonious compat emits xml prolog and variant glyph path" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 1 });
    var buf: [16384]u8 = undefined;
    const svg = clock_compat.renderOPTCHarmoniousCompat(
        set,
        "01",
        .{
            .cluster_mask = 0,
            .dash_mask = 0,
            .black_mask = 0,
        },
        &buf,
    );

    try testing.expect(std.mem.startsWith(u8, svg, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!DOCTYPE svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "translate(33, 29.5), scale(0.24)") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "fill=\"transparent\" />\n\n<circle cx=\"92.00\"") != null);
}

test "optc harmonious compat renders spoke metadata overlays" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 6 });
    var buf: [16384]u8 = undefined;
    const svg = clock_compat.renderOPTCHarmoniousCompat(
        set,
        "06",
        .{
            .cluster_mask = 0,
            .dash_mask = 65,
            .black_mask = 65,
        },
        &buf,
    );

    try testing.expect(std.mem.indexOf(u8, svg, "stroke-dasharray=\"1.6,0.8\" d=\"M50,18L50,30\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "stroke=\"black\" stroke-width=\"9\" fill=\"transparent\"  d=\"M50,82L50,70\"") != null);
}

test "optc harmonious compat adds white spokes for large A-label variants" {
    const set = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 3, 5, 6, 8, 10 });
    var buf: [16384]u8 = undefined;
    const svg = clock_compat.renderOPTCHarmoniousCompat(
        set,
        "013568A",
        .{
            .cluster_mask = 0,
            .dash_mask = 2708,
            .black_mask = 2708,
        },
        &buf,
    );

    try testing.expect(std.mem.indexOf(u8, svg, "stroke=\"white\" stroke-width=\"5\" fill=\"transparent\"") != null);
}
