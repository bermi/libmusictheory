const std = @import("std");
const testing = std.testing;

const ir = @import("../render/ir.zig");
const raster = @import("../render/raster.zig");

extern fn lmt_raster_is_enabled() callconv(.c) u32;
extern fn lmt_raster_demo_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;

fn countPartialAlphaPixels(pixels: []const u8) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index + 3 < pixels.len) : (index += 4) {
        const alpha = pixels[index + 3];
        if (alpha > 0 and alpha < 255) count += 1;
    }
    return count;
}

test "raster demo deterministic hash" {
    var pixels: [100 * 100 * 4]u8 = undefined;
    var surface = raster.Surface{
        .pixels = &pixels,
        .width = 100,
        .height = 100,
        .stride = 100 * 4,
    };

    raster.renderDemoScene(&surface);
    const hash_a = raster.hashSurface(surface);
    raster.renderDemoScene(&surface);
    const hash_b = raster.hashSurface(surface);

    try testing.expectEqual(hash_a, hash_b);
    try testing.expect(hash_a != 0);
}

test "c abi raster demo surface" {
    const enabled = lmt_raster_is_enabled();
    try testing.expect(enabled == 0 or enabled == 1);
    if (enabled == 0) return error.SkipZigTest;

    var pixels: [64 * 64 * 4]u8 = [_]u8{0} ** (64 * 64 * 4);
    const written = lmt_raster_demo_rgba(64, 64, @ptrCast(&pixels), @intCast(pixels.len));
    try testing.expectEqual(@as(u32, 64 * 64 * 4), written);

    var all_zero = true;
    for (pixels) |v| {
        if (v != 0) {
            all_zero = false;
            break;
        }
    }
    try testing.expect(!all_zero);
}

test "raster demo anti aliases curved and diagonal edges" {
    var pixels: [64 * 64 * 4]u8 = [_]u8{0} ** (64 * 64 * 4);
    var surface = raster.Surface{
        .pixels = &pixels,
        .width = 64,
        .height = 64,
        .stride = 64 * 4,
    };

    raster.clear(&surface, .{ 0, 0, 0, 0 });

    var ops: [2]ir.Op = undefined;
    var builder = ir.Builder.init(&ops);
    try builder.circle(.{
        .cx = "20",
        .cy = "20",
        .r = "9",
        .fill = "#16b",
        .stroke = "black",
        .stroke_width = "2",
    });
    try builder.line(.{
        .x1 = "8",
        .y1 = "56",
        .x2 = "56",
        .y2 = "12",
        .stroke = "black",
        .stroke_width = "3",
    });

    raster.renderScene(builder.scene(), &surface);
    try testing.expect(countPartialAlphaPixels(&pixels) > 0);
}
