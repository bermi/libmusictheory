const std = @import("std");
const primitives = @import("../generated/harmonious_text_primitives.zig");
const svg_quality = @import("quality.zig");

const PairDeltaStep = struct {
    dx: i32,
    dy: i32,
};

fn findSymbol(ch: u8) ?primitives.SymbolDef {
    for (primitives.SYMBOLS) |sym| {
        if (sym.ch == ch) return sym;
    }
    return null;
}

fn findPairDelta(model: primitives.OrientationModel, prev: u8, next: u8) ?PairDeltaStep {
    for (model.pair_deltas) |entry| {
        if (entry.prev == prev and entry.next == next) {
            return .{ .dx = entry.dx, .dy = entry.dy };
        }
    }
    return null;
}

fn findEdgeBias(model: primitives.OrientationModel, first: u8, last: u8) ?i32 {
    for (model.edge_biases) |entry| {
        if (entry.first == first and entry.last == last) return entry.bias2;
    }
    return null;
}

fn findFirstY(model: primitives.OrientationModel, first: u8) ?i32 {
    for (model.first_y) |entry| {
        if (entry.first == first) return entry.y;
    }
    return null;
}

fn writeScaledCoord(writer: anytype, value: i32) !void {
    if (value == 0) {
        try writer.writeAll("0");
        return;
    }

    var magnitude: i64 = value;
    if (magnitude < 0) {
        try writer.writeByte('-');
        magnitude = -magnitude;
    }

    const whole: i64 = @divFloor(magnitude, 10_000);
    const frac: i64 = @mod(magnitude, 10_000);
    try writer.print("{d}", .{whole});
    if (frac == 0) return;

    var frac_digits: [4]u8 = undefined;
    var n: u16 = @intCast(frac);
    var i: usize = 4;
    while (i > 0) {
        i -= 1;
        frac_digits[i] = @as(u8, @intCast('0' + (n % 10)));
        n /= 10;
    }

    var end: usize = frac_digits.len;
    while (end > 0 and frac_digits[end - 1] == '0') : (end -= 1) {}
    if (end == 0) return;

    try writer.writeByte('.');
    try writer.writeAll(frac_digits[0..end]);
}

fn buildVerticalPath(text: []const u8, bottom_to_top: bool, buf: []u8) ?[]const u8 {
    if (text.len == 0) return null;
    if (text.len > 64) return null;

    const model = if (bottom_to_top)
        primitives.VERT_TEXT_B2T_BLACK_MODEL
    else
        primitives.VERT_TEXT_BLACK_MODEL;

    var pair_deltas: [64]PairDeltaStep = undefined;
    var total_dx: i64 = 0;
    if (text.len > 1) {
        var i: usize = 0;
        while (i + 1 < text.len) : (i += 1) {
            const delta = findPairDelta(model, text[i], text[i + 1]) orelse return null;
            pair_deltas[i] = delta;
            total_dx += delta.dx;
        }
    }

    const edge_bias = findEdgeBias(model, text[0], text[text.len - 1]) orelse return null;
    const x0_num: i64 = @as(i64, edge_bias) - total_dx;
    if (@mod(x0_num, 2) != 0) return null;
    var symbol_x: i32 = @intCast(@divFloor(x0_num, 2));
    var symbol_y: i32 = findFirstY(model, text[0]) orelse return null;

    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const symbol = findSymbol(text[i]) orelse return null;
        for (symbol.parts) |part| {
            if (part.primitive_index >= primitives.PRIMITIVES.len) return null;
            const primitive = primitives.PRIMITIVES[part.primitive_index];

            const x = symbol_x + part.dx;
            const y = symbol_y + part.dy;

            writer.writeByte('M') catch return null;
            writeScaledCoord(writer, x) catch return null;
            if (model.use_comma) writer.writeByte(',') catch return null;
            writeScaledCoord(writer, y) catch return null;
            writer.writeAll(primitive.body) catch return null;
        }

        if (i + 1 < text.len) {
            symbol_x += pair_deltas[i].dx;
            symbol_y += pair_deltas[i].dy;
        }
    }

    return buf[0..stream.pos];
}

fn findCenterTemplate(stem: []const u8) ?[]const u8 {
    for (primitives.CENTER_SQUARE_TEXT) |entry| {
        if (std.mem.eql(u8, entry.stem, stem)) return entry.path_d;
    }
    return null;
}

pub fn verticalPathData(text: []const u8, bottom_to_top: bool, buf: []u8) ?[]const u8 {
    return buildVerticalPath(text, bottom_to_top, buf);
}

pub const HorizontalPath = struct {
    d: []const u8,
    width: f32,
};

const HorizontalBounds = struct {
    min_x: i32,
    max_x: i32,
    min_y: i32,
    max_y: i32,

    fn width(self: HorizontalBounds) i32 {
        return self.max_x - self.min_x;
    }
};

fn includeBoundsPoint(bounds: *HorizontalBounds, x: i32, y: i32) void {
    bounds.min_x = @min(bounds.min_x, x);
    bounds.max_x = @max(bounds.max_x, x);
    bounds.min_y = @min(bounds.min_y, y);
    bounds.max_y = @max(bounds.max_y, y);
}

fn skipPathSeparators(text: []const u8, index: *usize) void {
    while (index.* < text.len) : (index.* += 1) {
        switch (text[index.*]) {
            ' ', '\t', '\r', '\n', ',' => {},
            else => return,
        }
    }
}

fn isPathNumberStart(ch: u8) bool {
    return (ch >= '0' and ch <= '9') or ch == '-' or ch == '+' or ch == '.';
}

fn parseScaledNumber(text: []const u8, index: *usize) ?i32 {
    skipPathSeparators(text, index);
    if (index.* >= text.len or !isPathNumberStart(text[index.*])) return null;

    var sign: i64 = 1;
    if (text[index.*] == '-') {
        sign = -1;
        index.* += 1;
    } else if (text[index.*] == '+') {
        index.* += 1;
    }

    var whole: i64 = 0;
    var saw_digit = false;
    while (index.* < text.len and text[index.*] >= '0' and text[index.*] <= '9') : (index.* += 1) {
        saw_digit = true;
        whole = whole * 10 + @as(i64, text[index.*] - '0');
    }

    var frac: i64 = 0;
    var frac_scale: i64 = 1;
    if (index.* < text.len and text[index.*] == '.') {
        index.* += 1;
        while (index.* < text.len and text[index.*] >= '0' and text[index.*] <= '9') : (index.* += 1) {
            if (frac_scale < 10_000) {
                frac = frac * 10 + @as(i64, text[index.*] - '0');
                frac_scale *= 10;
            }
        }
    }

    if (!saw_digit and frac_scale == 1) return null;
    while (frac_scale < 10_000) : (frac_scale *= 10) frac *= 10;
    const scaled = sign * (whole * 10_000 + frac);
    return @intCast(scaled);
}

fn measurePrimitive(body: []const u8) ?HorizontalBounds {
    var bounds = HorizontalBounds{ .min_x = 0, .max_x = 0, .min_y = 0, .max_y = 0 };
    var index: usize = 0;
    var cmd: u8 = 0;
    var current_x: i32 = 0;
    var current_y: i32 = 0;
    var start_x: i32 = 0;
    var start_y: i32 = 0;

    while (index < body.len) {
        skipPathSeparators(body, &index);
        if (index >= body.len) break;

        const ch = body[index];
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z')) {
            cmd = ch;
            index += 1;
        } else if (cmd == 0) {
            return null;
        }

        switch (cmd) {
            'm', 'M' => {
                const dx = parseScaledNumber(body, &index) orelse return null;
                const dy = parseScaledNumber(body, &index) orelse return null;
                if (cmd == 'm') {
                    current_x += dx;
                    current_y += dy;
                } else {
                    current_x = dx;
                    current_y = dy;
                }
                start_x = current_x;
                start_y = current_y;
                includeBoundsPoint(&bounds, current_x, current_y);
                cmd = if (cmd == 'm') 'l' else 'L';
            },
            'l', 'L' => while (true) {
                const vx = parseScaledNumber(body, &index) orelse break;
                const vy = parseScaledNumber(body, &index) orelse return null;
                if (cmd == 'l') {
                    current_x += vx;
                    current_y += vy;
                } else {
                    current_x = vx;
                    current_y = vy;
                }
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            'h', 'H' => while (true) {
                const vx = parseScaledNumber(body, &index) orelse break;
                if (cmd == 'h') current_x += vx else current_x = vx;
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            'v', 'V' => while (true) {
                const vy = parseScaledNumber(body, &index) orelse break;
                if (cmd == 'v') current_y += vy else current_y = vy;
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            'c', 'C' => while (true) {
                const x1 = parseScaledNumber(body, &index) orelse break;
                const y1 = parseScaledNumber(body, &index) orelse return null;
                const x2 = parseScaledNumber(body, &index) orelse return null;
                const y2 = parseScaledNumber(body, &index) orelse return null;
                const x = parseScaledNumber(body, &index) orelse return null;
                const y = parseScaledNumber(body, &index) orelse return null;
                if (cmd == 'c') {
                    includeBoundsPoint(&bounds, current_x + x1, current_y + y1);
                    includeBoundsPoint(&bounds, current_x + x2, current_y + y2);
                    current_x += x;
                    current_y += y;
                } else {
                    includeBoundsPoint(&bounds, x1, y1);
                    includeBoundsPoint(&bounds, x2, y2);
                    current_x = x;
                    current_y = y;
                }
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            's', 'S' => while (true) {
                const x2 = parseScaledNumber(body, &index) orelse break;
                const y2 = parseScaledNumber(body, &index) orelse return null;
                const x = parseScaledNumber(body, &index) orelse return null;
                const y = parseScaledNumber(body, &index) orelse return null;
                if (cmd == 's') {
                    includeBoundsPoint(&bounds, current_x + x2, current_y + y2);
                    current_x += x;
                    current_y += y;
                } else {
                    includeBoundsPoint(&bounds, x2, y2);
                    current_x = x;
                    current_y = y;
                }
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            'z', 'Z' => {
                current_x = start_x;
                current_y = start_y;
                includeBoundsPoint(&bounds, current_x, current_y);
            },
            else => return null,
        }
    }

    return bounds;
}

fn measureSymbolBounds(symbol: primitives.SymbolDef) ?HorizontalBounds {
    var first = true;
    var bounds = HorizontalBounds{ .min_x = 0, .max_x = 0, .min_y = 0, .max_y = 0 };
    for (symbol.parts) |part| {
        if (part.primitive_index >= primitives.PRIMITIVES.len) return null;
        const primitive = primitives.PRIMITIVES[part.primitive_index];
        const primitive_bounds = measurePrimitive(primitive.body) orelse return null;
        const min_x = primitive_bounds.min_x + part.dx;
        const max_x = primitive_bounds.max_x + part.dx;
        const min_y = primitive_bounds.min_y + part.dy;
        const max_y = primitive_bounds.max_y + part.dy;
        if (first) {
            bounds = .{ .min_x = min_x, .max_x = max_x, .min_y = min_y, .max_y = max_y };
            first = false;
        } else {
            includeBoundsPoint(&bounds, min_x, min_y);
            includeBoundsPoint(&bounds, max_x, max_y);
        }
    }
    return if (first) null else bounds;
}

pub fn horizontalPathData(text: []const u8, buf: []u8) ?HorizontalPath {
    if (text.len == 0 or text.len > 64) return null;

    const gap: i32 = 12_000;
    var symbol_bounds: [64]HorizontalBounds = undefined;
    var baseline_max_y: i32 = std.math.minInt(i32);
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const symbol = findSymbol(text[i]) orelse return null;
        const bounds = measureSymbolBounds(symbol) orelse return null;
        symbol_bounds[i] = bounds;
        baseline_max_y = @max(baseline_max_y, bounds.max_y);
    }

    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();
    var cursor_x: i32 = 0;
    i = 0;
    while (i < text.len) : (i += 1) {
        const symbol = findSymbol(text[i]) orelse return null;
        const bounds = symbol_bounds[i];
        const origin_x = cursor_x - bounds.min_x;
        const origin_y = baseline_max_y - bounds.max_y;
        for (symbol.parts) |part| {
            if (part.primitive_index >= primitives.PRIMITIVES.len) return null;
            const primitive = primitives.PRIMITIVES[part.primitive_index];
            const x = origin_x + part.dx;
            const y = origin_y + part.dy;

            writer.writeByte('M') catch return null;
            writeScaledCoord(writer, x) catch return null;
            writer.writeByte(',') catch return null;
            writeScaledCoord(writer, y) catch return null;
            writer.writeAll(primitive.body) catch return null;
        }
        cursor_x += bounds.width();
        if (i + 1 < text.len) cursor_x += gap;
    }

    return .{
        .d = buf[0..stream.pos],
        .width = @as(f32, @floatFromInt(cursor_x)) / 10_000.0,
    };
}

pub const BlockTextAnchor = enum {
    left,
    center,
    right,
};

const BlockGlyph = struct {
    ch: u8,
    width: u8,
    rows: [7]u8,
};

const BLOCK_GLYPHS = [_]BlockGlyph{
    .{ .ch = ' ', .width = 3, .rows = .{ 0, 0, 0, 0, 0, 0, 0 } },
    .{ .ch = '-', .width = 3, .rows = .{ 0, 0, 0b111, 0, 0, 0, 0 } },
    .{ .ch = '/', .width = 5, .rows = .{ 0b00001, 0b00010, 0b00100, 0b00100, 0b01000, 0b10000, 0 } },
    .{ .ch = '[', .width = 3, .rows = .{ 0b111, 0b100, 0b100, 0b100, 0b100, 0b100, 0b111 } },
    .{ .ch = ']', .width = 3, .rows = .{ 0b111, 0b001, 0b001, 0b001, 0b001, 0b001, 0b111 } },
    .{ .ch = '.', .width = 1, .rows = .{ 0, 0, 0, 0, 0, 0, 0b1 } },
    .{ .ch = '0', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110 } },
    .{ .ch = '1', .width = 5, .rows = .{ 0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110 } },
    .{ .ch = '2', .width = 5, .rows = .{ 0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111 } },
    .{ .ch = '3', .width = 5, .rows = .{ 0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110 } },
    .{ .ch = '4', .width = 5, .rows = .{ 0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010 } },
    .{ .ch = '5', .width = 5, .rows = .{ 0b11111, 0b10000, 0b10000, 0b11110, 0b00001, 0b00001, 0b11110 } },
    .{ .ch = '6', .width = 5, .rows = .{ 0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = '7', .width = 5, .rows = .{ 0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000 } },
    .{ .ch = '8', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = '9', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110 } },
    .{ .ch = 'A', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001 } },
    .{ .ch = 'B', .width = 5, .rows = .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110 } },
    .{ .ch = 'C', .width = 5, .rows = .{ 0b01111, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b01111 } },
    .{ .ch = 'D', .width = 5, .rows = .{ 0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110 } },
    .{ .ch = 'E', .width = 5, .rows = .{ 0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111 } },
    .{ .ch = 'F', .width = 5, .rows = .{ 0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000 } },
    .{ .ch = 'G', .width = 5, .rows = .{ 0b01111, 0b10000, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = 'H', .width = 5, .rows = .{ 0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001 } },
    .{ .ch = 'I', .width = 5, .rows = .{ 0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b11111 } },
    .{ .ch = 'J', .width = 5, .rows = .{ 0b00001, 0b00001, 0b00001, 0b00001, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = 'K', .width = 5, .rows = .{ 0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001 } },
    .{ .ch = 'L', .width = 5, .rows = .{ 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111 } },
    .{ .ch = 'M', .width = 5, .rows = .{ 0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001 } },
    .{ .ch = 'N', .width = 5, .rows = .{ 0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001 } },
    .{ .ch = 'O', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = 'P', .width = 5, .rows = .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000 } },
    .{ .ch = 'Q', .width = 5, .rows = .{ 0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101 } },
    .{ .ch = 'R', .width = 5, .rows = .{ 0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001 } },
    .{ .ch = 'S', .width = 5, .rows = .{ 0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110 } },
    .{ .ch = 'T', .width = 5, .rows = .{ 0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100 } },
    .{ .ch = 'U', .width = 5, .rows = .{ 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110 } },
    .{ .ch = 'V', .width = 5, .rows = .{ 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100 } },
    .{ .ch = 'W', .width = 5, .rows = .{ 0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010 } },
    .{ .ch = 'X', .width = 5, .rows = .{ 0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001 } },
    .{ .ch = 'Y', .width = 5, .rows = .{ 0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100 } },
    .{ .ch = 'Z', .width = 5, .rows = .{ 0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111 } },
};

fn findBlockGlyph(ch: u8) BlockGlyph {
    for (BLOCK_GLYPHS) |glyph| {
        if (glyph.ch == ch) return glyph;
    }
    return BLOCK_GLYPHS[0];
}

pub fn blockTextWidth(text: []const u8, cell: f64, tracking: f64) f64 {
    if (text.len == 0) return 0.0;

    var width: f64 = 0.0;
    for (text, 0..) |raw_ch, index| {
        const glyph = findBlockGlyph(std.ascii.toUpper(raw_ch));
        width += @as(f64, @floatFromInt(glyph.width)) * cell;
        if (index + 1 < text.len) width += tracking;
    }
    return width;
}

pub fn writeBlockText(
    writer: anytype,
    text: []const u8,
    x: f64,
    y: f64,
    cell: f64,
    tracking: f64,
    fill: []const u8,
    anchor: BlockTextAnchor,
    class_name: ?[]const u8,
) !void {
    if (text.len == 0) return;

    const total_width = blockTextWidth(text, cell, tracking);
    var start_x = x;
    switch (anchor) {
        .left => {},
        .center => start_x -= total_width / 2.0,
        .right => start_x -= total_width,
    }

    if (class_name) |class| {
        try writer.print("<g class=\"{s}\" data-text=\"{s}\">\n", .{ class, text });
    } else {
        try writer.print("<g data-text=\"{s}\">\n", .{text});
    }

    var cursor_x = start_x;
    for (text, 0..) |raw_ch, index| {
        const glyph = findBlockGlyph(std.ascii.toUpper(raw_ch));
        var row: usize = 0;
        while (row < glyph.rows.len) : (row += 1) {
            const bits = glyph.rows[row];
            var col: u8 = 0;
            while (col < glyph.width) : (col += 1) {
                const shift = glyph.width - 1 - col;
                if ((bits & (@as(u8, 1) << @as(u3, @intCast(shift)))) == 0) continue;
                try writer.print(
                    "<rect x=\"{d:.3}\" y=\"{d:.3}\" width=\"{d:.3}\" height=\"{d:.3}\" fill=\"{s}\" />\n",
                    .{
                        cursor_x + @as(f64, @floatFromInt(col)) * cell,
                        y + @as(f64, @floatFromInt(row)) * cell,
                        cell,
                        cell,
                        fill,
                    },
                );
            }
        }
        cursor_x += @as(f64, @floatFromInt(glyph.width)) * cell;
        if (index + 1 < text.len) cursor_x += tracking;
    }
    try writer.writeAll("</g>\n");
}

pub fn centerSquarePathData(glyph: []const u8) ?[]const u8 {
    return findCenterTemplate(glyph);
}

pub fn renderVerticalLabel(text: []const u8, bottom_to_top: bool, buf: []u8) []u8 {
    var path_buf: [16 * 1024]u8 = undefined;
    const path_d = buildVerticalPath(text, bottom_to_top, &path_buf) orelse return renderVerticalFallback(text, bottom_to_top, buf);

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    const transform = if (bottom_to_top) "rotate(-90),translate(-45,0)" else "rotate(90),translate(45,0)";

    svg_quality.writeSvgPrelude(w, "36", "90", "0 0 36 90",
        \\.vert-label{fill:black}
        \\
    ) catch unreachable;
    w.print("<g transform=\"{s}\">\n", .{transform}) catch unreachable;
    w.print("<path class=\"vert-label\" d=\"{s}\" />\n", .{path_d}) catch unreachable;
    w.writeAll("</g>\n</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn renderVerticalFallback(text: []const u8, bottom_to_top: bool, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const rotate = if (bottom_to_top) "-90" else "90";
    const tx = if (bottom_to_top) "-45" else "45";

    svg_quality.writeSvgPrelude(w, "36", "90", "0 0 36 90",
        \\.vert-fallback{font-size:18px;fill:black}
        \\
    ) catch unreachable;
    w.print("<g transform=\"rotate({s}),translate({s},0)\">\n", .{ rotate, tx }) catch unreachable;
    w.print("<text class=\"label-sans vert-fallback\" x=\"-10\" y=\"20\">{s}</text>\n", .{text}) catch unreachable;
    w.writeAll("</g>\n</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderCenterSquareGlyph(glyph: []const u8, buf: []u8) []u8 {
    if (findCenterTemplate(glyph)) |d| {
        var stream = std.io.fixedBufferStream(buf);
        const w = stream.writer();

        svg_quality.writeSvgPrelude(w, "36", "36", "0 0 36 36",
            \\.center-square{fill:gray}
            \\
        ) catch unreachable;
        w.writeAll("<g transform=\"translate(18,0)\">\n") catch unreachable;
        w.print("<path class=\"center-square\" d=\"{s}\" />\n", .{d}) catch unreachable;
        w.writeAll("</g>\n</svg>\n") catch unreachable;
        return buf[0..stream.pos];
    }

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    svg_quality.writeSvgPrelude(w, "36", "36", "0 0 36 36",
        \\.center-glyph{font-size:20px;fill:gray}
        \\
    ) catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"36\" height=\"36\" fill=\"white\" />\n") catch unreachable;
    w.print("<text class=\"label-sans center-glyph\" x=\"18\" y=\"22\" text-anchor=\"middle\">{s}</text>\n", .{glyph}) catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}
