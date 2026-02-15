const std = @import("std");

pub const CanvasDims = struct {
    width: f32,
    height: f32,
};

pub const Point = struct {
    x: f32,
    y: f32,
};

pub const SliderState = struct {
    position: f32,
    velocity: f32,
    current_key: i8,
    canvas: CanvasDims,
    touching: bool,
};

pub const GridCoord = struct {
    row: u4,
    column: u4,
    is_down_triangle: bool,
};

pub const KeyQuad = struct {
    key_index: i8,
    down_triangle: bool,
    row: u4,
    column: u4,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const COLOR_INDEX = [_]u4{ 2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9 };

const PC_COLORS = [_]Color{
    .{ .r = 0x00, .g = 0x00, .b = 0xCC },
    .{ .r = 0xAA, .g = 0x44, .b = 0xFF },
    .{ .r = 0xFF, .g = 0x00, .b = 0xFF },
    .{ .r = 0xAA, .g = 0x11, .b = 0x66 },
    .{ .r = 0xEE, .g = 0x00, .b = 0x22 },
    .{ .r = 0xFF, .g = 0x99, .b = 0x11 },
    .{ .r = 0xCC, .g = 0x88, .b = 0x11 },
    .{ .r = 0x00, .g = 0x99, .b = 0x44 },
    .{ .r = 0x11, .g = 0x66, .b = 0x11 },
    .{ .r = 0x00, .g = 0x77, .b = 0x77 },
    .{ .r = 0x00, .g = 0xBB, .b = 0xBB },
    .{ .r = 0x22, .g = 0x88, .b = 0xFF },
};

const MXIX: f32 = 22.0;

const WhitelistCoord = struct {
    row: u4,
    column: u4,
    down: bool,
    color_index: u4,
};

const WHITELIST_COORDS = [_]WhitelistCoord{
    .{ .row = 0, .column = 1, .down = true, .color_index = 3 },
    .{ .row = 0, .column = 2, .down = false, .color_index = 11 },
    .{ .row = 0, .column = 2, .down = true, .color_index = 8 },
    .{ .row = 0, .column = 3, .down = false, .color_index = 4 },
    .{ .row = 0, .column = 3, .down = true, .color_index = 1 },
    .{ .row = 0, .column = 4, .down = false, .color_index = 9 },
    .{ .row = 0, .column = 4, .down = true, .color_index = 6 },
    .{ .row = 1, .column = 1, .down = false, .color_index = 2 },
    .{ .row = 1, .column = 2, .down = true, .color_index = 11 },
    .{ .row = 1, .column = 2, .down = false, .color_index = 7 },
    .{ .row = 1, .column = 3, .down = true, .color_index = 4 },
    .{ .row = 1, .column = 3, .down = false, .color_index = 0 },
    .{ .row = 1, .column = 4, .down = true, .color_index = 9 },
    .{ .row = 1, .column = 4, .down = false, .color_index = 5 },
    .{ .row = 1, .column = 5, .down = true, .color_index = 2 },
    .{ .row = 2, .column = 1, .down = true, .color_index = 2 },
    .{ .row = 2, .column = 2, .down = false, .color_index = 10 },
    .{ .row = 2, .column = 2, .down = true, .color_index = 7 },
    .{ .row = 2, .column = 3, .down = false, .color_index = 3 },
    .{ .row = 2, .column = 3, .down = true, .color_index = 0 },
    .{ .row = 2, .column = 4, .down = false, .color_index = 8 },
    .{ .row = 2, .column = 4, .down = true, .color_index = 5 },
    .{ .row = 2, .column = 5, .down = false, .color_index = 1 },
    .{ .row = 3, .column = 3, .down = true, .color_index = 3 },
    .{ .row = 3, .column = 4, .down = true, .color_index = 8 },
};

const KnownQuadPath = struct {
    path: []const u8,
    quad: KeyQuad,
};

const URL_PATH_TO_QUAD = [_]KnownQuadPath{
    .{ .path = "/p/fb/C-Major", .quad = .{ .key_index = 0, .down_triangle = false, .row = 1, .column = 3 } },
    .{ .path = "/p/ab/F-Major", .quad = .{ .key_index = 1, .down_triangle = false, .row = 1, .column = 3 } },
    .{ .path = "/p/d2/G-Major", .quad = .{ .key_index = -1, .down_triangle = false, .row = 1, .column = 3 } },
    .{ .path = "/p/f1/A-Minor", .quad = .{ .key_index = -3, .down_triangle = true, .row = 2, .column = 3 } },
    .{ .path = "/p/62/D-Minor", .quad = .{ .key_index = -2, .down_triangle = true, .row = 2, .column = 3 } },
};

pub fn strideForHeight(height: f32) f32 {
    return 138.0 * height / 480.0;
}

pub fn ease(t: f32) f32 {
    return -@as(f32, @floatCast(std.math.cos(@as(f64, @floatCast(t)) * std.math.pi))) * 0.5 + 0.5;
}

pub fn blend(a: Color, b: Color, t: f32) Color {
    const clamped = std.math.clamp(t, 0.0, 1.0);
    const omt = 1.0 - clamped;

    return .{
        .r = @as(u8, @intFromFloat(omt * @as(f32, @floatFromInt(a.r)) + clamped * @as(f32, @floatFromInt(b.r)))),
        .g = @as(u8, @intFromFloat(omt * @as(f32, @floatFromInt(a.g)) + clamped * @as(f32, @floatFromInt(b.g)))),
        .b = @as(u8, @intFromFloat(omt * @as(f32, @floatFromInt(a.b)) + clamped * @as(f32, @floatFromInt(b.b)))),
    };
}

pub fn updateScroll(state: SliderState, stride: f32) SliderState {
    var target = state.position + state.velocity;
    var velocity = state.velocity;

    const left = (3.0 + 0.51) * stride;
    const right = (MXIX - 0.51 - 3.0) * stride;

    if (target < left) {
        target = left;
        velocity *= 0.2;
    }
    if (target > right) {
        target = right;
        velocity *= 0.2;
    }

    const target3 = @round(target / stride) * stride;

    if (!state.touching and @abs(velocity) < 15.0) {
        const dt = 2.0 * (target3 - target) / stride;
        target += stride * dt * 0.15;
    }

    const position = target;

    if (state.touching) {
        velocity *= 0.5;
    } else {
        velocity *= 0.96;
    }

    var ix2 = @as(i16, @intFromFloat(@round(position / stride)));
    if (ix2 < 0) ix2 = 0;
    if (ix2 > 22) ix2 = 22;

    return .{
        .position = position,
        .velocity = velocity,
        .current_key = @as(i8, @intCast(ix2 - 11)),
        .canvas = state.canvas,
        .touching = state.touching,
    };
}

pub fn handleTap(x: f32, y: f32, canvas: CanvasDims, scroll_offset: f32) ?GridCoord {
    const hhh = canvas.height;
    const cw = canvas.width;
    const stride = strideForHeight(hhh);

    const y_float = 8.0 * y / hhh;
    const x_float = 9.0 * (x + 0.5 * stride + scroll_offset) / cw;

    const row = @as(i32, @intFromFloat(@floor(y_float)));
    if (row < 0) return null;

    const column0 = @as(i32, @intFromFloat(@floor(x_float)));
    const column1 = @as(i32, @intFromFloat(@floor(x_float + 0.5)));

    var inn = 0.5 * ((x_float - @floor(x_float)) - 0.5 * (y_float - @as(f32, @floatFromInt(row))));
    var inn2 = 0.5 * ((x_float + 0.5 - @floor(x_float + 0.5)) - 0.5 * (y_float - @as(f32, @floatFromInt(row))));

    var yes = inn > 0;
    if (@mod(row, 2) != 0) {
        yes = inn2 > 0;
    }

    inn = 0.5 * ((-x_float - @floor(-x_float)) - 0.5 * (y_float - @as(f32, @floatFromInt(row))));
    inn2 = 0.5 * ((-(x_float + 0.5) - @floor(-(x_float + 0.5))) - 0.5 * (y_float - @as(f32, @floatFromInt(row))));

    var yes2 = inn > 0;
    if (@mod(row, 2) != 0) {
        yes2 = inn2 > 0;
    }

    const down_triangle = yes and yes2;
    const column = if (down_triangle)
        (if (@mod(row, 2) != 0) column1 else column0)
    else
        (if (@mod(row, 2) != 0) column0 else column1);

    if (column < 0 or row > 15) return null;

    const coord = GridCoord{
        .row = @as(u4, @intCast(row)),
        .column = @as(u4, @intCast(column)),
        .is_down_triangle = down_triangle,
    };

    if (!isWhitelisted(coord)) return null;
    return coord;
}

pub fn triangleVertices(coord: GridCoord, canvas: CanvasDims, scroll_offset: f32) [3]Point {
    const stride = strideForHeight(canvas.height);
    const metric_x = stride;
    const metric_y = metric_x * 0.5 * 1.732;

    const aspect_ratio = canvas.width / canvas.height;
    const min_aspect: f32 = 1.299;
    const k = 0.25 * (1.0 + 7.0 * (min_aspect - aspect_ratio));
    const ox = -stride * k - scroll_offset;

    if (!coord.is_down_triangle) {
        var col = @as(f32, @floatFromInt(coord.column));
        if (((coord.row + 1) % 2) != 0) col -= 0.5;

        return .{
            .{ .x = ox + col * metric_x, .y = @as(f32, @floatFromInt(coord.row)) * metric_y },
            .{ .x = ox + (0.5 + col) * metric_x, .y = @as(f32, @floatFromInt(coord.row + 1)) * metric_y },
            .{ .x = ox + (-0.5 + col) * metric_x, .y = @as(f32, @floatFromInt(coord.row + 1)) * metric_y },
        };
    }

    var col = @as(f32, @floatFromInt(coord.column));
    if ((coord.row % 2) != 0) col -= 0.5;
    col -= 0.5;

    return .{
        .{ .x = ox + col * metric_x, .y = @as(f32, @floatFromInt(coord.row)) * metric_y },
        .{ .x = ox + (0.5 + col) * metric_x, .y = @as(f32, @floatFromInt(coord.row + 1)) * metric_y },
        .{ .x = ox + (1.0 + col) * metric_x, .y = @as(f32, @floatFromInt(coord.row)) * metric_y },
    };
}

pub fn triangleCenter(coord: GridCoord, canvas: CanvasDims, scroll_offset: f32) Point {
    // Find an interior point in tap-space for this whitelist coordinate.
    var y_step: u16 = 0;
    while (y_step <= 48) : (y_step += 1) {
        const y_float = (@as(f32, @floatFromInt(coord.row)) + 0.1) + 0.8 * (@as(f32, @floatFromInt(y_step)) / 48.0);
        const y = y_float * canvas.height / 8.0;

        var x_step: u16 = 0;
        while (x_step <= 500) : (x_step += 1) {
            const x = (@as(f32, @floatFromInt(x_step)) / 500.0) * canvas.width;
            if (handleTap(x, y, canvas, scroll_offset)) |found| {
                if (found.row == coord.row and found.column == coord.column and found.is_down_triangle == coord.is_down_triangle) {
                    return .{ .x = x, .y = y };
                }
            }
        }
    }

    // Fallback geometric centroid for rendering workflows.
    const tri = triangleVertices(coord, canvas, scroll_offset);
    return .{
        .x = (tri[0].x + tri[1].x + tri[2].x) / 3.0,
        .y = (tri[0].y + tri[1].y + tri[2].y) / 3.0,
    };
}

pub fn getRelativeColorIndex(coord: GridCoord) u4 {
    for (WHITELIST_COORDS) |entry| {
        if (entry.row == coord.row and entry.column == coord.column and entry.down == coord.is_down_triangle) {
            return entry.color_index;
        }
    }
    return 0;
}

pub fn triangleColor(coord: GridCoord, key_index: i8, scroll_fraction: f32) Color {
    const rel = getRelativeColorIndex(coord);

    const idx0 = wrap12(@as(i16, key_index) + 24 + 3);
    const idx1 = wrap12(@as(i16, key_index) + 25 + 3);

    const pc0 = @as(usize, @intCast((COLOR_INDEX[idx0] + rel) % 12));
    const pc1 = @as(usize, @intCast((COLOR_INDEX[idx1] + rel) % 12));

    return blend(PC_COLORS[pc0], PC_COLORS[pc1], scroll_fraction);
}

pub fn quadToUrlPath(quad: KeyQuad, out: *[64]u8) []u8 {
    const down: u8 = if (quad.down_triangle) 1 else 0;
    return std.fmt.bufPrint(out, "/slider/{d},{d},{d},{d}", .{
        quad.key_index,
        down,
        quad.row,
        quad.column,
    }) catch unreachable;
}

pub fn urlPathToQuad(path: []const u8) ?KeyQuad {
    if (std.mem.startsWith(u8, path, "/slider/")) {
        var it = std.mem.splitScalar(u8, path[8..], ',');
        const k_s = it.next() orelse return null;
        const d_s = it.next() orelse return null;
        const r_s = it.next() orelse return null;
        const c_s = it.next() orelse return null;

        const key_index = std.fmt.parseInt(i8, k_s, 10) catch return null;
        const down_i = std.fmt.parseInt(u8, d_s, 10) catch return null;
        const row = std.fmt.parseInt(u4, r_s, 10) catch return null;
        const column = std.fmt.parseInt(u4, c_s, 10) catch return null;

        return .{
            .key_index = key_index,
            .down_triangle = down_i != 0,
            .row = row,
            .column = column,
        };
    }

    for (URL_PATH_TO_QUAD) |entry| {
        if (std.mem.eql(u8, path, entry.path)) {
            return entry.quad;
        }
    }

    return null;
}

fn isWhitelisted(coord: GridCoord) bool {
    for (WHITELIST_COORDS) |entry| {
        if (entry.row == coord.row and entry.column == coord.column and entry.down == coord.is_down_triangle) {
            return true;
        }
    }
    return false;
}

fn wrap12(value: i16) usize {
    var out = @mod(value, 12);
    if (out < 0) out += 12;
    return @as(usize, @intCast(out));
}
