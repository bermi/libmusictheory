const std = @import("std");
const ir = @import("ir.zig");

pub const Surface = struct {
    pixels: []u8,
    width: u32,
    height: u32,
    stride: u32,
};

fn parseNumber(text: []const u8, fallback: f64) f64 {
    return std.fmt.parseFloat(f64, text) catch fallback;
}

fn parseHexNibble(ch: u8) ?u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => null,
    };
}

fn parseColor(text_opt: ?[]const u8) [4]u8 {
    const text = text_opt orelse return .{ 0, 0, 0, 0 };

    if (std.mem.eql(u8, text, "transparent")) return .{ 0, 0, 0, 0 };
    if (std.mem.eql(u8, text, "black")) return .{ 0, 0, 0, 255 };
    if (std.mem.eql(u8, text, "white")) return .{ 255, 255, 255, 255 };
    if (std.mem.eql(u8, text, "gray")) return .{ 128, 128, 128, 255 };

    if (text.len == 4 and text[0] == '#') {
        const r = parseHexNibble(text[1]) orelse return .{ 0, 0, 0, 255 };
        const g = parseHexNibble(text[2]) orelse return .{ 0, 0, 0, 255 };
        const b = parseHexNibble(text[3]) orelse return .{ 0, 0, 0, 255 };
        return .{ r * 17, g * 17, b * 17, 255 };
    }

    if (text.len == 7 and text[0] == '#') {
        const r_hi = parseHexNibble(text[1]) orelse return .{ 0, 0, 0, 255 };
        const r_lo = parseHexNibble(text[2]) orelse return .{ 0, 0, 0, 255 };
        const g_hi = parseHexNibble(text[3]) orelse return .{ 0, 0, 0, 255 };
        const g_lo = parseHexNibble(text[4]) orelse return .{ 0, 0, 0, 255 };
        const b_hi = parseHexNibble(text[5]) orelse return .{ 0, 0, 0, 255 };
        const b_lo = parseHexNibble(text[6]) orelse return .{ 0, 0, 0, 255 };
        return .{ (r_hi << 4) | r_lo, (g_hi << 4) | g_lo, (b_hi << 4) | b_lo, 255 };
    }

    return .{ 0, 0, 0, 255 };
}

fn blendPixel(dst: *[4]u8, src: [4]u8) void {
    const src_a: u32 = src[3];
    if (src_a == 0) return;

    const dst_a: u32 = dst[3];
    const out_a: u32 = src_a + ((dst_a * (255 - src_a) + 127) / 255);

    if (out_a == 0) {
        dst.* = .{ 0, 0, 0, 0 };
        return;
    }

    var channel: usize = 0;
    while (channel < 3) : (channel += 1) {
        const src_c: u32 = src[channel];
        const dst_c: u32 = dst[channel];
        const numer = src_c * src_a * 255 + dst_c * dst_a * (255 - src_a);
        const denom = out_a * 255;
        const value = if (denom == 0) 0 else (numer + (denom / 2)) / denom;
        dst[channel] = @as(u8, @intCast(@min(value, 255)));
    }

    dst[3] = @as(u8, @intCast(@min(out_a, 255)));
}

fn clamp01(value: f64) f64 {
    return std.math.clamp(value, 0.0, 1.0);
}

fn intervalCoverage(start: f64, end: f64, pixel_index: i32) f64 {
    if (end <= start) return 0.0;
    const pixel_start = @as(f64, @floatFromInt(pixel_index));
    const pixel_end = pixel_start + 1.0;
    return clamp01(@min(end, pixel_end) - @max(start, pixel_start));
}

fn rectCoverage(x0: f64, y0: f64, x1: f64, y1: f64, px: i32, py: i32) f64 {
    return intervalCoverage(x0, x1, px) * intervalCoverage(y0, y1, py);
}

fn fillCoverageForDistance(dist: f64, radius: f64) f64 {
    return clamp01(radius + 0.5 - dist);
}

fn annulusCoverageForDistance(dist: f64, inner_radius: f64, outer_radius: f64) f64 {
    const outer = fillCoverageForDistance(dist, outer_radius);
    const inner = if (inner_radius <= 0.0) 0.0 else fillCoverageForDistance(dist, inner_radius);
    return clamp01(outer - inner);
}

fn scaledAlpha(alpha: u8, coverage: f64) u8 {
    const scaled = @as(f64, @floatFromInt(alpha)) * clamp01(coverage);
    return @as(u8, @intFromFloat(std.math.clamp(@floor(scaled + 0.5), 0.0, 255.0)));
}

fn blendCoverage(dst: *[4]u8, src: [4]u8, coverage: f64) void {
    if (src[3] == 0 or coverage <= 0.0) return;
    if (coverage >= 0.999999) {
        blendPixel(dst, src);
        return;
    }
    var adjusted = src;
    adjusted[3] = scaledAlpha(src[3], coverage);
    if (adjusted[3] == 0) return;
    blendPixel(dst, adjusted);
}

fn pixelPtr(surface: *Surface, x: i32, y: i32) ?*[4]u8 {
    if (x < 0 or y < 0) return null;
    if (x >= @as(i32, @intCast(surface.width)) or y >= @as(i32, @intCast(surface.height))) return null;
    const offset = @as(usize, @intCast(y)) * @as(usize, @intCast(surface.stride)) + @as(usize, @intCast(x)) * 4;
    return @ptrCast(surface.pixels[offset .. offset + 4]);
}

fn drawRect(surface: *Surface, rect: ir.Rect) void {
    const x = @as(i32, @intFromFloat(@floor(parseNumber(rect.x, 0.0))));
    const y = @as(i32, @intFromFloat(@floor(parseNumber(rect.y, 0.0))));
    const w = @as(i32, @intFromFloat(@floor(parseNumber(rect.width, 0.0))));
    const h = @as(i32, @intFromFloat(@floor(parseNumber(rect.height, 0.0))));
    if (w <= 0 or h <= 0) return;

    const fill = parseColor(rect.fill);
    const stroke = parseColor(rect.stroke);
    const stroke_width = @max(1.0, parseNumber(rect.stroke_width orelse "1", 1.0));
    const half_stroke = stroke_width / 2.0;

    var py: i32 = y;
    while (py < y + h) : (py += 1) {
        var px: i32 = x;
        while (px < x + w) : (px += 1) {
            if (pixelPtr(surface, px, py)) |dst| {
                const fill_coverage = if (fill[3] > 0)
                    rectCoverage(@floatFromInt(x), @floatFromInt(y), @floatFromInt(x + w), @floatFromInt(y + h), px, py)
                else
                    0.0;
                const outer_coverage = if (stroke[3] > 0 and stroke_width > 0.0)
                    rectCoverage(@as(f64, @floatFromInt(x)) - half_stroke, @as(f64, @floatFromInt(y)) - half_stroke, @as(f64, @floatFromInt(x + w)) + half_stroke, @as(f64, @floatFromInt(y + h)) + half_stroke, px, py)
                else
                    0.0;
                const inner_coverage = if (stroke[3] > 0 and stroke_width > 0.0 and w > 0 and h > 0 and @as(f64, @floatFromInt(w)) > stroke_width and @as(f64, @floatFromInt(h)) > stroke_width)
                    rectCoverage(@as(f64, @floatFromInt(x)) + half_stroke, @as(f64, @floatFromInt(y)) + half_stroke, @as(f64, @floatFromInt(x + w)) - half_stroke, @as(f64, @floatFromInt(y + h)) - half_stroke, px, py)
                else
                    0.0;
                if (fill_coverage > 0.0) blendCoverage(dst, fill, fill_coverage);
                const stroke_coverage = clamp01(outer_coverage - inner_coverage);
                if (stroke_coverage > 0.0) blendCoverage(dst, stroke, stroke_coverage);
            }
        }
    }
}

fn drawCircle(surface: *Surface, circle: ir.Circle) void {
    const cx = parseNumber(circle.cx, 0.0);
    const cy = parseNumber(circle.cy, 0.0);
    const r = parseNumber(circle.r, 0.0);
    if (r <= 0.0) return;

    const fill = parseColor(circle.fill);
    const stroke = parseColor(circle.stroke);
    const stroke_width = parseNumber(circle.stroke_width orelse "1", 1.0);
    const half_stroke = stroke_width / 2.0;

    const min_x = @as(i32, @intFromFloat(@floor(cx - r - half_stroke - 1.0)));
    const max_x = @as(i32, @intFromFloat(@ceil(cx + r + half_stroke + 1.0)));
    const min_y = @as(i32, @intFromFloat(@floor(cy - r - half_stroke - 1.0)));
    const max_y = @as(i32, @intFromFloat(@ceil(cy + r + half_stroke + 1.0)));

    var py = min_y;
    while (py <= max_y) : (py += 1) {
        var px = min_x;
        while (px <= max_x) : (px += 1) {
            const dx = (@as(f64, @floatFromInt(px)) + 0.5) - cx;
            const dy = (@as(f64, @floatFromInt(py)) + 0.5) - cy;
            const dist = @sqrt(dx * dx + dy * dy);

            if (pixelPtr(surface, px, py)) |dst| {
                const fill_coverage = if (fill[3] > 0) fillCoverageForDistance(dist, r) else 0.0;
                const stroke_coverage = if (stroke[3] > 0 and stroke_width > 0.0)
                    annulusCoverageForDistance(dist, @max(0.0, r - half_stroke), r + half_stroke)
                else
                    0.0;
                if (fill_coverage > 0.0) blendCoverage(dst, fill, fill_coverage);
                if (stroke_coverage > 0.0) blendCoverage(dst, stroke, stroke_coverage);
            }
        }
    }
}

fn drawLine(surface: *Surface, line: ir.Line) void {
    const x1 = parseNumber(line.x1, 0.0);
    const y1 = parseNumber(line.y1, 0.0);
    const x2 = parseNumber(line.x2, 0.0);
    const y2 = parseNumber(line.y2, 0.0);
    const color = parseColor(line.stroke);
    if (color[3] == 0) return;

    const thickness = @max(1.0, parseNumber(line.stroke_width orelse "1", 1.0));
    const radius = thickness / 2.0;

    const min_x = @as(i32, @intFromFloat(@floor(@min(x1, x2) - radius - 1.0)));
    const max_x = @as(i32, @intFromFloat(@ceil(@max(x1, x2) + radius + 1.0)));
    const min_y = @as(i32, @intFromFloat(@floor(@min(y1, y2) - radius - 1.0)));
    const max_y = @as(i32, @intFromFloat(@ceil(@max(y1, y2) + radius + 1.0)));

    const vx = x2 - x1;
    const vy = y2 - y1;
    const vv = vx * vx + vy * vy;

    var py = min_y;
    while (py <= max_y) : (py += 1) {
        var px = min_x;
        while (px <= max_x) : (px += 1) {
            const fx = @as(f64, @floatFromInt(px)) + 0.5;
            const fy = @as(f64, @floatFromInt(py)) + 0.5;

            var t: f64 = 0.0;
            if (vv > 0.0) {
                t = ((fx - x1) * vx + (fy - y1) * vy) / vv;
                t = @max(0.0, @min(1.0, t));
            }

            const cx = x1 + t * vx;
            const cy = y1 + t * vy;
            const dx = fx - cx;
            const dy = fy - cy;
            const dist = @sqrt(dx * dx + dy * dy);

            if (pixelPtr(surface, px, py)) |dst| {
                const coverage = fillCoverageForDistance(dist, radius);
                if (coverage > 0.0) blendCoverage(dst, color, coverage);
            }
        }
    }
}

pub fn clear(surface: *Surface, rgba: [4]u8) void {
    var y: u32 = 0;
    while (y < surface.height) : (y += 1) {
        var x: u32 = 0;
        while (x < surface.width) : (x += 1) {
            const offset = @as(usize, @intCast(y)) * @as(usize, @intCast(surface.stride)) + @as(usize, @intCast(x)) * 4;
            surface.pixels[offset + 0] = rgba[0];
            surface.pixels[offset + 1] = rgba[1];
            surface.pixels[offset + 2] = rgba[2];
            surface.pixels[offset + 3] = rgba[3];
        }
    }
}

pub fn renderScene(scene: ir.Scene, surface: *Surface) void {
    for (scene.ops) |op| {
        switch (op) {
            .rect => |rect| drawRect(surface, rect),
            .circle => |circle| drawCircle(surface, circle),
            .line => |line| drawLine(surface, line),
            else => {},
        }
    }
}

pub fn renderDemoScene(surface: *Surface) void {
    clear(surface, .{ 245, 245, 245, 255 });

    var ops: [6]ir.Op = undefined;
    var builder = ir.Builder.init(&ops);
    builder.rect(.{
        .x = "4",
        .y = "4",
        .width = "92",
        .height = "92",
        .fill = "white",
        .stroke = "#333",
        .stroke_width = "2",
    }) catch unreachable;
    builder.circle(.{
        .cx = "50",
        .cy = "50",
        .r = "22",
        .fill = "#16b",
        .stroke = "black",
        .stroke_width = "2",
    }) catch unreachable;
    builder.line(.{
        .x1 = "18",
        .y1 = "80",
        .x2 = "82",
        .y2 = "20",
        .stroke = "black",
        .stroke_width = "3",
    }) catch unreachable;

    renderScene(builder.scene(), surface);
}

pub fn hashSurface(surface: Surface) u64 {
    var hasher = std.hash.Fnv1a_64.init();
    hasher.update(surface.pixels);
    return hasher.final();
}

test "raster demo scene is deterministic" {
    var a_pixels: [100 * 100 * 4]u8 = undefined;
    var b_pixels: [100 * 100 * 4]u8 = undefined;

    var a = Surface{
        .pixels = &a_pixels,
        .width = 100,
        .height = 100,
        .stride = 100 * 4,
    };
    var b = Surface{
        .pixels = &b_pixels,
        .width = 100,
        .height = 100,
        .stride = 100 * 4,
    };

    renderDemoScene(&a);
    renderDemoScene(&b);

    try std.testing.expectEqual(hashSurface(a), hashSurface(b));
}
