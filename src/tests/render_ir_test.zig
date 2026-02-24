const std = @import("std");
const testing = std.testing;

const ir = @import("../render/ir.zig");
const svg_serializer = @import("../render/svg_serializer.zig");
const clock = @import("../svg/clock.zig");
const pcs = @import("../pitch_class_set.zig");

test "render ir serializer preserves path spacing semantics" {
    var ops: [3]ir.Op = undefined;
    var builder = ir.Builder.init(&ops);

    try builder.path(.{
        .stroke = "black",
        .stroke_width = "9",
        .fill = "transparent",
        .d = "M1,2L3,4",
        .spaces_before_d = 2,
        .newline = false,
    });
    try builder.raw("\n");
    try builder.circle(.{
        .cx = "1",
        .cy = "2",
        .r = "3",
        .stroke = "black",
        .stroke_width = "1",
        .fill = "white",
    });

    var buf: [512]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try svg_serializer.write(builder.scene(), stream.writer(), .strict);

    const got = buf[0..stream.pos];
    const expected =
        "<path stroke=\"black\" stroke-width=\"9\" fill=\"transparent\"  d=\"M1,2L3,4\"/>\n" ++
        "<circle cx=\"1\" cy=\"2\" r=\"3\" stroke=\"black\" stroke-width=\"1\" fill=\"white\" />\n";
    try testing.expectEqualStrings(expected, got);
}

test "optc harmonious compat rendering remains deterministic" {
    var a_buf: [128 * 1024]u8 = undefined;
    var b_buf: [128 * 1024]u8 = undefined;

    const set: pcs.PitchClassSet = 0b000101001001;
    const svg_a = clock.renderOPTCHarmoniousCompat(
        set,
        "013568A",
        .{
            .cluster_mask = 0,
            .dash_mask = 2708,
            .black_mask = 2708,
        },
        &a_buf,
    );
    const svg_b = clock.renderOPTCHarmoniousCompat(
        set,
        "013568A",
        .{
            .cluster_mask = 0,
            .dash_mask = 2708,
            .black_mask = 2708,
        },
        &b_buf,
    );

    try testing.expect(svg_a.len > 0);
    try testing.expectEqualStrings(svg_a, svg_b);
    try testing.expect(std.mem.startsWith(u8, svg_a, "<?xml version=\"1.0\" encoding=\"utf-8\"?>"));
}
