const std = @import("std");
const testing = std.testing;

const slider = @import("../slider.zig");

test "easing endpoints and midpoint" {
    try testing.expectApproxEqAbs(@as(f32, 0.0), slider.ease(0.0), 0.0001);
    try testing.expectApproxEqAbs(@as(f32, 0.5), slider.ease(0.5), 0.0001);
    try testing.expectApproxEqAbs(@as(f32, 1.0), slider.ease(1.0), 0.0001);
}

test "blend color linear interpolation" {
    const a = slider.Color{ .r = 255, .g = 0, .b = 0 };
    const b = slider.Color{ .r = 0, .g = 0, .b = 255 };
    const c = slider.blend(a, b, 0.5);

    try testing.expectEqual(@as(u8, 127), c.r);
    try testing.expectEqual(@as(u8, 0), c.g);
    try testing.expectEqual(@as(u8, 127), c.b);
}

test "url quad roundtrip" {
    const quad = slider.KeyQuad{ .key_index = -3, .down_triangle = true, .row = 2, .column = 4 };
    var buf: [64]u8 = undefined;
    const path = slider.quadToUrlPath(quad, &buf);
    const parsed = slider.urlPathToQuad(path).?;

    try testing.expectEqualDeep(quad, parsed);
}

test "snap to grid under low velocity detente" {
    var state = slider.SliderState{
        .position = 755.0,
        .velocity = 2.0,
        .current_key = 0,
        .canvas = .{ .width = 1400.0, .height = 694.0 },
        .touching = false,
    };

    const stride = slider.strideForHeight(state.canvas.height);
    var i: usize = 0;
    while (i < 80) : (i += 1) {
        state = slider.updateScroll(state, stride);
    }

    const snapped = @round(state.position / stride) * stride;
    try testing.expectApproxEqAbs(snapped, state.position, 0.35);
    try testing.expect(@abs(state.velocity) < 0.5);
}

test "tap detection returns expected whitelisted coordinate" {
    const dims = slider.CanvasDims{ .width = 1400.0, .height = 694.0 };
    const wanted = slider.GridCoord{ .row = 1, .column = 3, .is_down_triangle = true };

    const center = slider.triangleCenter(wanted, dims, 0.0);
    const got = slider.handleTap(center.x, center.y, dims, 0.0).?;

    try testing.expectEqualDeep(wanted, got);
}

test "color index matches slider js order" {
    const expected = [_]u4{ 2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9 };
    try testing.expectEqualSlices(u4, &expected, &slider.COLOR_INDEX);
}
