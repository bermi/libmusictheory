const std = @import("std");
const testing = std.testing;

const raster = @import("../render/raster.zig");

extern fn lmt_raster_is_enabled() callconv(.c) u32;
extern fn lmt_raster_demo_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;

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
