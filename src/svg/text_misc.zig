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

fn horizontalAdvance(ch: u8) i32 {
    return switch (ch) {
        '1' => 85_000,
        '-' => 95_000,
        'Z' => 118_000,
        else => 112_000,
    };
}

pub fn horizontalPathData(text: []const u8, buf: []u8) ?HorizontalPath {
    if (text.len == 0 or text.len > 64) return null;

    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();
    var cursor_x: i32 = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const symbol = findSymbol(text[i]) orelse return null;
        for (symbol.parts) |part| {
            if (part.primitive_index >= primitives.PRIMITIVES.len) return null;
            const primitive = primitives.PRIMITIVES[part.primitive_index];
            const x = cursor_x + part.dx;

            writer.writeByte('M') catch return null;
            writeScaledCoord(writer, x) catch return null;
            writer.writeByte(',') catch return null;
            writeScaledCoord(writer, part.dy) catch return null;
            writer.writeAll(primitive.body) catch return null;
        }
        cursor_x += horizontalAdvance(text[i]);
    }

    return .{
        .d = buf[0..stream.pos],
        .width = @as(f32, @floatFromInt(cursor_x)) / 10_000.0,
    };
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
