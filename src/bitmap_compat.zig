const std = @import("std");

const svg_compat = @import("harmonious_svg_compat.zig");
const pcs = @import("pitch_class_set.zig");
const svg_clock = @import("svg/clock.zig");

pub const SCALE_NUMERATOR: u32 = 55;
pub const SCALE_DENOMINATOR: u32 = 100;
pub const TARGET_SIZE_OPC: u32 = 55;

pub const Error = error{
    UnsupportedKind,
    InvalidImage,
    InvalidSvg,
    UnsupportedSvgFeature,
    OutputTooSmall,
};

const OPC_STROKE_COLORS = [_][4]u8{
    hexColor("#00c"), hexColor("#a4f"), hexColor("#f0f"), hexColor("#a16"), hexColor("#e02"), hexColor("#f91"),
    hexColor("#c81"), hexColor("#161"), hexColor("#094"), hexColor("#0bb"), hexColor("#16b"), hexColor("#28f"),
};

const OPC_FILL_COLORS = [_][4]u8{
    hexColor("#00C"), hexColor("#a4f"), hexColor("#f0f"), hexColor("#a16"), hexColor("#e02"), hexColor("#f91"),
    hexColor("#ff0"), hexColor("#1e0"), hexColor("#094"), hexColor("#0bb"), hexColor("#16b"), hexColor("#28f"),
};

pub const Surface = struct {
    pixels: []u8,
    width: u32,
    height: u32,
    stride: u32,
};

const Matrix = struct {
    a: f64 = 1.0,
    b: f64 = 0.0,
    c: f64 = 0.0,
    d: f64 = 1.0,
    e: f64 = 0.0,
    f: f64 = 0.0,

    fn multiply(lhs: Matrix, rhs: Matrix) Matrix {
        return .{
            .a = lhs.a * rhs.a + lhs.c * rhs.b,
            .b = lhs.b * rhs.a + lhs.d * rhs.b,
            .c = lhs.a * rhs.c + lhs.c * rhs.d,
            .d = lhs.b * rhs.c + lhs.d * rhs.d,
            .e = lhs.a * rhs.e + lhs.c * rhs.f + lhs.e,
            .f = lhs.b * rhs.e + lhs.d * rhs.f + lhs.f,
        };
    }

    fn apply(self: Matrix, x: f64, y: f64) struct { x: f64, y: f64 } {
        return .{
            .x = self.a * x + self.c * y + self.e,
            .y = self.b * x + self.d * y + self.f,
        };
    }

    fn approxUniformScale(self: Matrix) f64 {
        const sx = @sqrt(self.a * self.a + self.b * self.b);
        const sy = @sqrt(self.c * self.c + self.d * self.d);
        return (sx + sy) / 2.0;
    }
};

const Paint = struct {
    fill: [4]u8 = .{ 0, 0, 0, 0 },
    stroke: [4]u8 = .{ 0, 0, 0, 0 },
    stroke_width: f64 = 1.0,
};

pub fn kindSupported(kind_index: usize) bool {
    return switch (svg_compat.kindId(kind_index) orelse return false) {
        .opc => true,
        else => false,
    };
}

pub fn targetWidth(kind_index: usize, image_index: usize) u32 {
    _ = image_index;
    if (!kindSupported(kind_index)) return 0;
    return TARGET_SIZE_OPC;
}

pub fn targetHeight(kind_index: usize, image_index: usize) u32 {
    _ = image_index;
    if (!kindSupported(kind_index)) return 0;
    return TARGET_SIZE_OPC;
}

pub fn requiredRgbaBytes(kind_index: usize, image_index: usize) u32 {
    const width = targetWidth(kind_index, image_index);
    const height = targetHeight(kind_index, image_index);
    if (width == 0 or height == 0) return 0;
    return width * height * 4;
}

pub fn renderCandidateRgba(kind_index: usize, image_index: usize, out_rgba: []u8) Error!usize {
    if (!kindSupported(kind_index)) return error.UnsupportedKind;
    const required = requiredRgbaBytes(kind_index, image_index);
    if (required == 0) return error.UnsupportedKind;
    if (out_rgba.len < required) return error.OutputTooSmall;

    const image_name = svg_compat.imageName(kind_index, image_index) orelse return error.InvalidImage;
    const set_label = firstCsvField(trimSvgSuffix(image_name));
    const set = parseSetLabel(set_label) orelse return error.InvalidImage;

    var surface = Surface{
        .pixels = out_rgba[0..required],
        .width = TARGET_SIZE_OPC,
        .height = TARGET_SIZE_OPC,
        .stride = TARGET_SIZE_OPC * 4,
    };
    clear(&surface, .{ 255, 255, 255, 255 });
    drawRect(&surface, 0.0, 0.0, @floatFromInt(TARGET_SIZE_OPC), @floatFromInt(TARGET_SIZE_OPC), .{ 255, 255, 255, 255 }, .{ 0, 0, 0, 0 }, 0.0);

    const root = rootScaleMatrix();
    const circle_transform = parseTransformList("scale(0.877),translate(7,7)") catch return error.InvalidSvg;
    const transform = root.multiply(circle_transform);
    const radius = 9.5 * transform.approxUniformScale();
    const stroke_width = 3.0 * transform.approxUniformScale();

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const pos = svg_clock.circlePosition(@intCast(pc), 50.0, 42.0);
        const transformed = transform.apply(pos.x, pos.y);
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const fill = if ((set & bit) != 0) OPC_FILL_COLORS[pc] else .{ 255, 255, 255, 255 };
        drawCircle(&surface, transformed.x, transformed.y, radius, fill, OPC_STROKE_COLORS[pc], stroke_width);
    }

    return required;
}

pub fn renderReferenceSvgRgba(kind_index: usize, svg: []const u8, out_rgba: []u8) Error!usize {
    if (!kindSupported(kind_index)) return error.UnsupportedKind;
    const required = requiredRgbaBytes(kind_index, 0);
    if (out_rgba.len < required) return error.OutputTooSmall;

    var surface = Surface{
        .pixels = out_rgba[0..required],
        .width = TARGET_SIZE_OPC,
        .height = TARGET_SIZE_OPC,
        .stride = TARGET_SIZE_OPC * 4,
    };
    clear(&surface, .{ 255, 255, 255, 255 });

    const root = rootScaleMatrix();
    var cursor: usize = 0;
    while (findTag(svg, "rect", cursor)) |match| {
        cursor = match.end;
        const attrs = svg[match.start..match.end];
        try renderRectTag(attrs, root, &surface);
    }

    cursor = 0;
    while (findTag(svg, "circle", cursor)) |match| {
        cursor = match.end;
        const attrs = svg[match.start..match.end];
        try renderCircleTag(attrs, root, &surface);
    }

    return required;
}

fn findTag(svg: []const u8, tag_name: []const u8, from: usize) ?struct { start: usize, end: usize } {
    var cursor = from;
    while (cursor < svg.len) {
        const rel = std.mem.indexOfPos(u8, svg, cursor, "<") orelse return null;
        cursor = rel;
        if (cursor + tag_name.len + 1 >= svg.len) return null;
        if (svg[cursor + 1] == '/' or svg[cursor + 1] == '?' or svg[cursor + 1] == '!') {
            cursor += 1;
            continue;
        }
        if (!std.mem.startsWith(u8, svg[cursor + 1 ..], tag_name)) {
            cursor += 1;
            continue;
        }
        const end = std.mem.indexOfPos(u8, svg, cursor, ">") orelse return null;
        return .{ .start = cursor, .end = end + 1 };
    }
    return null;
}

fn renderRectTag(tag_text: []const u8, root: Matrix, surface: *Surface) Error!void {
    var paint = Paint{};
    applyPaintAttrs(tag_text, &paint);

    const x = parseAttrNumber(tag_text, "x") orelse return error.InvalidSvg;
    const y = parseAttrNumber(tag_text, "y") orelse return error.InvalidSvg;
    const width = parseAttrNumber(tag_text, "width") orelse return error.InvalidSvg;
    const height = parseAttrNumber(tag_text, "height") orelse return error.InvalidSvg;

    const transform = if (parseTransformAttr(tag_text)) |element_transform|
        root.multiply(element_transform)
    else
        root;

    if (!isAxisAligned(transform)) return error.UnsupportedSvgFeature;
    const p = transform.apply(x, y);
    const sx = @sqrt(transform.a * transform.a + transform.b * transform.b);
    const sy = @sqrt(transform.c * transform.c + transform.d * transform.d);

    drawRect(surface, p.x, p.y, width * sx, height * sy, paint.fill, paint.stroke, paint.stroke_width * @max(sx, sy));
}

fn renderCircleTag(tag_text: []const u8, root: Matrix, surface: *Surface) Error!void {
    var paint = Paint{};
    applyPaintAttrs(tag_text, &paint);

    const cx = parseAttrNumber(tag_text, "cx") orelse return error.InvalidSvg;
    const cy = parseAttrNumber(tag_text, "cy") orelse return error.InvalidSvg;
    const r = parseAttrNumber(tag_text, "r") orelse return error.InvalidSvg;

    const transform = if (parseTransformAttr(tag_text)) |element_transform|
        root.multiply(element_transform)
    else
        root;
    const center = transform.apply(cx, cy);
    const radius = r * transform.approxUniformScale();
    const stroke_width = paint.stroke_width * transform.approxUniformScale();
    drawCircle(surface, center.x, center.y, radius, paint.fill, paint.stroke, stroke_width);
}

fn rootScaleMatrix() Matrix {
    const scale = @as(f64, @floatFromInt(SCALE_NUMERATOR)) / @as(f64, @floatFromInt(SCALE_DENOMINATOR));
    return .{ .a = scale, .d = scale };
}

fn isAxisAligned(m: Matrix) bool {
    const eps = 0.0000001;
    return @abs(m.b) < eps and @abs(m.c) < eps;
}

fn applyPaintAttrs(tag_text: []const u8, paint: *Paint) void {
    if (parseAttr(tag_text, "fill")) |value| paint.fill = parseColor(value);
    if (parseAttr(tag_text, "stroke")) |value| paint.stroke = parseColor(value);
    if (parseAttrNumber(tag_text, "stroke-width")) |value| paint.stroke_width = value;

    if (parseAttr(tag_text, "style")) |style| {
        var parts = std.mem.splitScalar(u8, style, ';');
        while (parts.next()) |part| {
            const colon = std.mem.indexOfScalar(u8, part, ':') orelse continue;
            const key = std.mem.trim(u8, part[0..colon], " \t\r\n");
            const value = std.mem.trim(u8, part[colon + 1 ..], " \t\r\n");
            if (std.mem.eql(u8, key, "fill")) paint.fill = parseColor(value);
            if (std.mem.eql(u8, key, "stroke")) paint.stroke = parseColor(value);
            if (std.mem.eql(u8, key, "stroke-width")) paint.stroke_width = parseNumber(value, paint.stroke_width);
        }
    }
}

fn parseTransformAttr(tag_text: []const u8) ?Matrix {
    const value = parseAttr(tag_text, "transform") orelse return null;
    return parseTransformList(value) catch null;
}

fn parseTransformList(text: []const u8) !Matrix {
    var out = Matrix{};
    var cursor: usize = 0;
    while (cursor < text.len) {
        while (cursor < text.len and (text[cursor] == ' ' or text[cursor] == ',')) : (cursor += 1) {}
        if (cursor >= text.len) break;
        const open = std.mem.indexOfPos(u8, text, cursor, "(") orelse return error.InvalidSvg;
        const close = std.mem.indexOfPos(u8, text, open + 1, ")") orelse return error.InvalidSvg;
        const name = std.mem.trim(u8, text[cursor..open], " \t\r\n,");
        const args = std.mem.trim(u8, text[open + 1 .. close], " \t\r\n");
        const transform = if (std.mem.eql(u8, name, "scale"))
            parseScaleTransform(args)
        else if (std.mem.eql(u8, name, "translate"))
            parseTranslateTransform(args)
        else if (std.mem.eql(u8, name, "matrix"))
            try parseMatrixTransform(args)
        else
            return error.UnsupportedSvgFeature;
        out = out.multiply(transform);
        cursor = close + 1;
    }
    return out;
}

fn parseScaleTransform(args: []const u8) Matrix {
    var numbers = parseNumberList(args);
    const sx = numbers.next() orelse 1.0;
    const sy = numbers.next() orelse sx;
    return .{ .a = sx, .d = sy };
}

fn parseTranslateTransform(args: []const u8) Matrix {
    var numbers = parseNumberList(args);
    const tx = numbers.next() orelse 0.0;
    const ty = numbers.next() orelse 0.0;
    return .{ .e = tx, .f = ty };
}

fn parseMatrixTransform(args: []const u8) !Matrix {
    var numbers = parseNumberList(args);
    return .{
        .a = numbers.next() orelse return error.InvalidSvg,
        .b = numbers.next() orelse return error.InvalidSvg,
        .c = numbers.next() orelse return error.InvalidSvg,
        .d = numbers.next() orelse return error.InvalidSvg,
        .e = numbers.next() orelse return error.InvalidSvg,
        .f = numbers.next() orelse return error.InvalidSvg,
    };
}

fn parseNumberList(text: []const u8) NumberIterator {
    return .{ .text = text };
}

const NumberIterator = struct {
    text: []const u8,
    index: usize = 0,

    fn next(self: *NumberIterator) ?f64 {
        while (self.index < self.text.len and (self.text[self.index] == ' ' or self.text[self.index] == ',')) : (self.index += 1) {}
        if (self.index >= self.text.len) return null;

        const start = self.index;
        self.index += 1;
        while (self.index < self.text.len) : (self.index += 1) {
            const ch = self.text[self.index];
            if ((ch >= '0' and ch <= '9') or ch == '.' or ch == '-' or ch == '+' or ch == 'e' or ch == 'E') continue;
            break;
        }
        return parseNumber(self.text[start..self.index], 0.0);
    }
};

fn parseAttr(tag_text: []const u8, name: []const u8) ?[]const u8 {
    var cursor: usize = 0;
    while (cursor < tag_text.len) {
        const idx = std.mem.indexOfPos(u8, tag_text, cursor, name) orelse return null;
        if (idx > 0 and isAttrNameChar(tag_text[idx - 1])) {
            cursor = idx + name.len;
            continue;
        }
        var after = idx + name.len;
        while (after < tag_text.len and (tag_text[after] == ' ' or tag_text[after] == '\n' or tag_text[after] == '\t' or tag_text[after] == '\r')) : (after += 1) {}
        if (after >= tag_text.len or tag_text[after] != '=') {
            cursor = idx + name.len;
            continue;
        }
        after += 1;
        while (after < tag_text.len and (tag_text[after] == ' ' or tag_text[after] == '\n' or tag_text[after] == '\t' or tag_text[after] == '\r')) : (after += 1) {}
        if (after >= tag_text.len or tag_text[after] != '"') {
            cursor = idx + name.len;
            continue;
        }
        const end = std.mem.indexOfPos(u8, tag_text, after + 1, "\"") orelse return null;
        return tag_text[after + 1 .. end];
    }
    return null;
}

fn parseAttrNumber(tag_text: []const u8, name: []const u8) ?f64 {
    const value = parseAttr(tag_text, name) orelse return null;
    return parseNumber(value, 0.0);
}

fn isAttrNameChar(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '-' or ch == '_';
}

fn parseSetLabel(label: []const u8) ?pcs.PitchClassSet {
    if (label.len == 0) return null;
    var set: pcs.PitchClassSet = 0;
    for (label) |ch| {
        const pc_opt: ?u4 = switch (ch) {
            '0'...'9' => @as(u4, @intCast(ch - '0')),
            'a', 'A', 't', 'T' => 10,
            'b', 'B', 'e', 'E' => 11,
            else => null,
        };
        const pc = pc_opt orelse return null;
        set |= @as(pcs.PitchClassSet, 1) << pc;
    }
    return set;
}

fn trimSvgSuffix(name: []const u8) []const u8 {
    if (std.mem.endsWith(u8, name, ".svg")) return name[0 .. name.len - 4];
    return name;
}

fn firstCsvField(text: []const u8) []const u8 {
    const idx = std.mem.indexOfScalar(u8, text, ',') orelse return text;
    return text[0..idx];
}

fn parseNumber(text: []const u8, fallback: f64) f64 {
    return std.fmt.parseFloat(f64, text) catch fallback;
}

fn hexNibble(ch: u8) u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => 0,
    };
}

fn hexColor(comptime text: []const u8) [4]u8 {
    return parseColor(text);
}

fn parseColor(text: []const u8) [4]u8 {
    if (std.mem.eql(u8, text, "transparent") or std.mem.eql(u8, text, "none")) return .{ 0, 0, 0, 0 };
    if (std.mem.eql(u8, text, "black")) return .{ 0, 0, 0, 255 };
    if (std.mem.eql(u8, text, "white")) return .{ 255, 255, 255, 255 };
    if (text.len == 4 and text[0] == '#') {
        return .{
            hexNibble(text[1]) * 17,
            hexNibble(text[2]) * 17,
            hexNibble(text[3]) * 17,
            255,
        };
    }
    if (text.len == 7 and text[0] == '#') {
        return .{
            (hexNibble(text[1]) << 4) | hexNibble(text[2]),
            (hexNibble(text[3]) << 4) | hexNibble(text[4]),
            (hexNibble(text[5]) << 4) | hexNibble(text[6]),
            255,
        };
    }
    return .{ 0, 0, 0, 255 };
}

fn clear(surface: *Surface, rgba: [4]u8) void {
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

fn drawRect(surface: *Surface, x: f64, y: f64, width: f64, height: f64, fill: [4]u8, stroke: [4]u8, stroke_width: f64) void {
    const x0: i32 = @intFromFloat(@floor(x));
    const y0: i32 = @intFromFloat(@floor(y));
    const x1: i32 = @intFromFloat(@ceil(x + width));
    const y1: i32 = @intFromFloat(@ceil(y + height));
    const border = @max(1.0, stroke_width);

    var py = y0;
    while (py < y1) : (py += 1) {
        var px = x0;
        while (px < x1) : (px += 1) {
            if (pixelPtr(surface, px, py)) |dst| {
                const dx = (@as(f64, @floatFromInt(px)) + 0.5) - x;
                const dy = (@as(f64, @floatFromInt(py)) + 0.5) - y;
                const is_border = dx < border or dy < border or dx >= width - border or dy >= height - border;
                if (is_border and stroke[3] > 0) {
                    blend(dst, stroke);
                } else if (fill[3] > 0) {
                    blend(dst, fill);
                }
            }
        }
    }
}

fn drawCircle(surface: *Surface, cx: f64, cy: f64, r: f64, fill: [4]u8, stroke: [4]u8, stroke_width: f64) void {
    const half_stroke = stroke_width / 2.0;
    const min_x: i32 = @intFromFloat(@floor(cx - r - half_stroke - 1.0));
    const max_x: i32 = @intFromFloat(@ceil(cx + r + half_stroke + 1.0));
    const min_y: i32 = @intFromFloat(@floor(cy - r - half_stroke - 1.0));
    const max_y: i32 = @intFromFloat(@ceil(cy + r + half_stroke + 1.0));

    var py = min_y;
    while (py <= max_y) : (py += 1) {
        var px = min_x;
        while (px <= max_x) : (px += 1) {
            const dx = (@as(f64, @floatFromInt(px)) + 0.5) - cx;
            const dy = (@as(f64, @floatFromInt(py)) + 0.5) - cy;
            const dist = @sqrt(dx * dx + dy * dy);
            if (pixelPtr(surface, px, py)) |dst| {
                if (fill[3] > 0 and dist <= r) blend(dst, fill);
                if (stroke[3] > 0 and dist >= r - half_stroke and dist <= r + half_stroke) blend(dst, stroke);
            }
        }
    }
}

fn pixelPtr(surface: *Surface, x: i32, y: i32) ?*[4]u8 {
    if (x < 0 or y < 0) return null;
    if (x >= @as(i32, @intCast(surface.width)) or y >= @as(i32, @intCast(surface.height))) return null;
    const offset = @as(usize, @intCast(y)) * @as(usize, @intCast(surface.stride)) + @as(usize, @intCast(x)) * 4;
    return @ptrCast(surface.pixels[offset .. offset + 4]);
}

fn blend(dst: *[4]u8, src: [4]u8) void {
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
        dst[channel] = @intCast((numer + (denom / 2)) / denom);
    }
    dst[3] = @intCast(out_a);
}

test "opc candidate render is deterministic" {
    const kind_index = blk: {
        var i: usize = 0;
        while (i < svg_compat.kindCount()) : (i += 1) {
            if (svg_compat.kindId(i) == .opc) break :blk i;
        }
        unreachable;
    };

    const image_index: usize = 3;
    var a: [TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4]u8 = [_]u8{0} ** (TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4);
    var b: [TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4]u8 = [_]u8{0} ** (TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4);
    const len_a = try renderCandidateRgba(kind_index, image_index, &a);
    const len_b = try renderCandidateRgba(kind_index, image_index, &b);
    try std.testing.expectEqual(len_a, len_b);
    try std.testing.expectEqualSlices(u8, a[0..len_a], b[0..len_b]);
}

test "opc reference parser matches candidate bitmap for generated svg" {
    const kind_index = blk: {
        var i: usize = 0;
        while (i < svg_compat.kindCount()) : (i += 1) {
            if (svg_compat.kindId(i) == .opc) break :blk i;
        }
        unreachable;
    };

    const image_index: usize = 3;
    var svg_buf: [4096]u8 = undefined;
    const svg = svg_compat.generateByIndex(kind_index, image_index, &svg_buf);
    var candidate: [TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4]u8 = [_]u8{0} ** (TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4);
    var reference: [TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4]u8 = [_]u8{0} ** (TARGET_SIZE_OPC * TARGET_SIZE_OPC * 4);

    const candidate_len = try renderCandidateRgba(kind_index, image_index, &candidate);
    const reference_len = try renderReferenceSvgRgba(kind_index, svg, &reference);
    try std.testing.expectEqual(candidate_len, reference_len);
    try std.testing.expectEqualSlices(u8, candidate[0..candidate_len], reference[0..reference_len]);
}
