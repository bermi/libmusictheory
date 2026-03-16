const std = @import("std");

const svg_compat = @import("harmonious_svg_compat.zig");
const cluster = @import("cluster.zig");
const pcs = @import("pitch_class_set.zig");
const oc_templates = @import("generated/harmonious_oc_templates.zig");
const fret_compat = @import("svg/fret_compat.zig");
const chord_compat = @import("svg/chord_compat.zig");
const svg_clock = @import("svg/clock.zig");
const text_misc = @import("svg/text_misc.zig");

pub const SCALE_NUMERATOR: u32 = 55;
pub const SCALE_DENOMINATOR: u32 = 100;
pub const TARGET_SIZE_OPC: u32 = scaledDimDefault(100);
pub const TARGET_SIZE_OPTC: u32 = scaledDimDefault(70);
pub const TARGET_SIZE_OC: u32 = scaledDimDefault(70);
pub const TARGET_SIZE_EADGBE: u32 = scaledDimDefault(100);
pub const TARGET_SIZE_CENTER_SQUARE: u32 = scaledDimDefault(36);
pub const TARGET_WIDTH_VERTICAL_TEXT: u32 = scaledDimDefault(36);
pub const TARGET_HEIGHT_VERTICAL_TEXT: u32 = scaledDimDefault(90);
pub const MAX_TEST_TARGET_WIDTH: usize = 512;
pub const MAX_TEST_TARGET_HEIGHT: usize = 512;

const PATH_EDGE_LIMIT: usize = 4096;
const TAG_TRANSFORM_STACK_LIMIT: usize = 16;
const OC_TEMPLATE_BUFFER_LIMIT: usize = 8 * 1024;
const CHORD_COMPAT_SVG_BUFFER_LIMIT: usize = 64 * 1024;
const EADGBE_STRING_COUNT: usize = fret_compat.NumStrings;
const CHORD_CLIPPED_SOURCE_WIDTH: f64 = 170.0;
const CHORD_CLIPPED_SOURCE_HEIGHT: f64 = 82.05128205128206;
const CHORD_SOURCE_WIDTH: f64 = 170.0;
const CHORD_SOURCE_HEIGHT: f64 = 110.76923076923077;
const GRAND_CHORD_SOURCE_WIDTH: f64 = 170.0;
const GRAND_CHORD_SOURCE_HEIGHT: f64 = 216.0;
const WIDE_CHORD_SOURCE_WIDTH: f64 = 220.0;
const WIDE_CHORD_SOURCE_HEIGHT: f64 = 216.0;
const EADGBE_DOT_X = [_]f64{ -9.5, 2.5, 14.5, 26.5, 38.5, 50.5 };
const EADGBE_XMARK_X = [_]f64{ 0.0, 12.0, 24.0, 36.0, 48.0, 60.0 };
const EADGBE_DOT_Y = [_]f64{ -43.5, -31.5, -19.5, -7.5, 4.5 };
const EADGBE_DOT_CENTER_X: f64 = 16.114458;
const EADGBE_DOT_CENTER_Y: f64 = 67.921684;
const EADGBE_DOT_RADIUS: f64 = 4.3674698;
const EADGBE_BASE_GROUP = Matrix{ .e = 14.5, .f = 5.0 };
const EADGBE_X_ROTATE = Matrix{
    .a = 0.7071068,
    .b = -0.7071068,
    .c = 0.7071068,
    .d = 0.7071068,
    .e = -44.365971,
    .f = 15.412027,
};
const EADGBE_X_LINE_A = "M 42,24 L 42,36";
const EADGBE_X_LINE_B = "M 36,30 L 48,30";
const EADGBE_BARRE_CURVE = "M 4,0 C 0,0 0,12 4,12";
const EADGBE_MASK_3299_A: u8 = (1 << 1) | (1 << 2);
const EADGBE_MASK_3299_B: u8 = (1 << 3) | (1 << 4);
const EADGBE_MASK_3299_C: u8 = (1 << 4) | (1 << 5);
const EADGBE_MASK_3307_A: u8 = (1 << 1) | (1 << 2) | (1 << 3);
const EADGBE_MASK_3307_B: u8 = (1 << 2) | (1 << 3) | (1 << 4);
const EADGBE_MASK_3307_C: u8 = (1 << 3) | (1 << 4) | (1 << 5);
const EADGBE_MASK_3311_A: u8 = (1 << 0) | (1 << 2) | (1 << 3);
const EADGBE_MASK_3311_B: u8 = (1 << 1) | (1 << 3) | (1 << 4);
const EADGBE_MASK_3311_C: u8 = (1 << 2) | (1 << 4) | (1 << 5);

pub const Error = error{
    UnsupportedKind,
    InvalidImage,
    InvalidSvg,
    UnsupportedSvgFeature,
    OutputTooSmall,
    PathOverflow,
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

const Point = struct {
    x: f64,
    y: f64,
};

const ViewBox = struct {
    min_x: f64,
    min_y: f64,
    width: f64,
    height: f64,
};

const Edge = struct {
    a: Point,
    b: Point,
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

    fn apply(self: Matrix, x: f64, y: f64) Point {
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
    stroke_dash_on: f64 = 0.0,
    stroke_dash_off: f64 = 0.0,
};

const PathBuilder = struct {
    edges: [PATH_EDGE_LIMIT]Edge = undefined,
    edge_count: usize = 0,
    current: Point = .{ .x = 0.0, .y = 0.0 },
    subpath_start: Point = .{ .x = 0.0, .y = 0.0 },
    has_current: bool = false,
    last_cubic_ctrl: ?Point = null,
    prev_cmd: u8 = 0,

    fn moveTo(self: *PathBuilder, point: Point) void {
        self.current = point;
        self.subpath_start = point;
        self.has_current = true;
        self.last_cubic_ctrl = null;
    }

    fn lineTo(self: *PathBuilder, transform: Matrix, point: Point) Error!void {
        if (!self.has_current) {
            self.moveTo(point);
            return;
        }
        if (self.edge_count >= self.edges.len) return error.PathOverflow;
        self.edges[self.edge_count] = .{
            .a = transform.apply(self.current.x, self.current.y),
            .b = transform.apply(point.x, point.y),
        };
        self.edge_count += 1;
        self.current = point;
        self.last_cubic_ctrl = null;
    }

    fn cubicTo(self: *PathBuilder, transform: Matrix, ctrl1: Point, ctrl2: Point, point: Point) Error!void {
        const start = self.current;
        const steps = cubicStepCount(start, ctrl1, ctrl2, point);

        var i: u32 = 1;
        while (i <= steps) : (i += 1) {
            const t = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(steps));
            const next = cubicPoint(start, ctrl1, ctrl2, point, t);
            try self.lineTo(transform, next);
        }
        self.current = point;
        self.last_cubic_ctrl = ctrl2;
    }

    fn closePath(self: *PathBuilder, transform: Matrix) Error!void {
        if (!self.has_current) return;
        if (@abs(self.current.x - self.subpath_start.x) > 0.0000001 or @abs(self.current.y - self.subpath_start.y) > 0.0000001) {
            try self.lineTo(transform, self.subpath_start);
        }
        self.current = self.subpath_start;
        self.last_cubic_ctrl = null;
    }
};

const PathReader = struct {
    text: []const u8,
    index: usize = 0,

    fn skipSeparators(self: *PathReader) void {
        while (self.index < self.text.len) : (self.index += 1) {
            switch (self.text[self.index]) {
                ' ', '\t', '\r', '\n', ',' => {},
                else => break,
            }
        }
    }

    fn hasNumber(self: *PathReader) bool {
        self.skipSeparators();
        if (self.index >= self.text.len) return false;
        return isNumberStart(self.text[self.index]);
    }

    fn nextNumber(self: *PathReader) ?f64 {
        self.skipSeparators();
        if (self.index >= self.text.len or !isNumberStart(self.text[self.index])) return null;

        const start = self.index;
        self.index = scanNumberEnd(self.text, start);
        return parseNumber(self.text[start..self.index], 0.0);
    }
};

fn scaledDimDefault(comptime source: u32) u32 {
    return (source * SCALE_NUMERATOR + (SCALE_DENOMINATOR / 2)) / SCALE_DENOMINATOR;
}

fn scaledDim(source: u32, scale_numerator: u32, scale_denominator: u32) u32 {
    if (source == 0 or scale_numerator == 0 or scale_denominator == 0) return 0;
    const numerator = @as(u64, source) * @as(u64, scale_numerator) + @as(u64, scale_denominator / 2);
    const value = numerator / @as(u64, scale_denominator);
    if (value == 0 or value > std.math.maxInt(u32)) return 0;
    return @as(u32, @intCast(value));
}

fn scaledDimFloat(source: f64, scale_numerator: u32, scale_denominator: u32) u32 {
    if (source <= 0.0 or scale_numerator == 0 or scale_denominator == 0) return 0;
    const scaled = source * @as(f64, @floatFromInt(scale_numerator)) / @as(f64, @floatFromInt(scale_denominator));
    const rounded = @floor(scaled + 0.5);
    if (rounded < 1.0 or rounded > @as(f64, @floatFromInt(std.math.maxInt(u32)))) return 0;
    return @as(u32, @intFromFloat(rounded));
}

pub fn kindSupported(kind_index: usize) bool {
    return switch (svg_compat.kindId(kind_index) orelse return false) {
        .opc, .oc, .optc, .eadgbe, .wide_chord, .chord_clipped, .grand_chord, .chord, .center_square_text, .vert_text_black, .vert_text_b2t_black => true,
        else => false,
    };
}

pub fn targetWidth(kind_index: usize, image_index: usize) u32 {
    return targetWidthScaled(kind_index, image_index, SCALE_NUMERATOR, SCALE_DENOMINATOR);
}

pub fn targetWidthScaled(kind_index: usize, image_index: usize, scale_numerator: u32, scale_denominator: u32) u32 {
    _ = image_index;
    const kind_id = svg_compat.kindId(kind_index) orelse return 0;
    return switch (kind_id) {
        .opc => scaledDim(100, scale_numerator, scale_denominator),
        .eadgbe => scaledDim(100, scale_numerator, scale_denominator),
        .oc, .optc => scaledDim(70, scale_numerator, scale_denominator),
        .grand_chord => scaledDimFloat(GRAND_CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .chord => scaledDimFloat(CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .wide_chord => scaledDimFloat(WIDE_CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .chord_clipped => scaledDimFloat(CHORD_CLIPPED_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .center_square_text => scaledDim(36, scale_numerator, scale_denominator),
        .vert_text_black, .vert_text_b2t_black => scaledDim(36, scale_numerator, scale_denominator),
        else => 0,
    };
}

pub fn targetHeight(kind_index: usize, image_index: usize) u32 {
    return targetHeightScaled(kind_index, image_index, SCALE_NUMERATOR, SCALE_DENOMINATOR);
}

pub fn targetHeightScaled(kind_index: usize, image_index: usize, scale_numerator: u32, scale_denominator: u32) u32 {
    _ = image_index;
    const kind_id = svg_compat.kindId(kind_index) orelse return 0;
    return switch (kind_id) {
        .opc => scaledDim(100, scale_numerator, scale_denominator),
        .eadgbe => scaledDim(100, scale_numerator, scale_denominator),
        .oc, .optc => scaledDim(70, scale_numerator, scale_denominator),
        .grand_chord => scaledDimFloat(GRAND_CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .chord => scaledDimFloat(CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .wide_chord => scaledDimFloat(WIDE_CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .chord_clipped => scaledDimFloat(CHORD_CLIPPED_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .center_square_text => scaledDim(36, scale_numerator, scale_denominator),
        .vert_text_black, .vert_text_b2t_black => scaledDim(90, scale_numerator, scale_denominator),
        else => 0,
    };
}

pub fn requiredRgbaBytes(kind_index: usize, image_index: usize) u32 {
    return requiredRgbaBytesScaled(kind_index, image_index, SCALE_NUMERATOR, SCALE_DENOMINATOR);
}

pub fn requiredRgbaBytesScaled(kind_index: usize, image_index: usize, scale_numerator: u32, scale_denominator: u32) u32 {
    const width = targetWidthScaled(kind_index, image_index, scale_numerator, scale_denominator);
    const height = targetHeightScaled(kind_index, image_index, scale_numerator, scale_denominator);
    if (width == 0 or height == 0) return 0;
    const required = @as(u64, width) * @as(u64, height) * 4;
    if (required == 0 or required > std.math.maxInt(u32)) return 0;
    return @as(u32, @intCast(required));
}

pub fn renderCandidateRgba(kind_index: usize, image_index: usize, out_rgba: []u8) Error!usize {
    return renderCandidateRgbaScaled(kind_index, image_index, SCALE_NUMERATOR, SCALE_DENOMINATOR, out_rgba);
}

pub fn renderCandidateRgbaScaled(kind_index: usize, image_index: usize, scale_numerator: u32, scale_denominator: u32, out_rgba: []u8) Error!usize {
    const kind_id = svg_compat.kindId(kind_index) orelse return error.UnsupportedKind;
    if (!kindSupported(kind_index)) return error.UnsupportedKind;

    const required = requiredRgbaBytesScaled(kind_index, image_index, scale_numerator, scale_denominator);
    if (required == 0) return error.UnsupportedKind;
    if (out_rgba.len < required) return error.OutputTooSmall;

    const image_name = svg_compat.imageName(kind_index, image_index) orelse return error.InvalidImage;
    var surface = try initSurface(kind_id, required, out_rgba, scale_numerator, scale_denominator);

    switch (kind_id) {
        .opc => try renderOpcCandidate(&surface, image_name, scale_numerator, scale_denominator),
        .oc => try renderOcCandidate(&surface, image_name),
        .optc => try renderOptcCandidate(&surface, image_name),
        .eadgbe => try renderEadgbeCandidate(&surface, image_name, scale_numerator, scale_denominator),
        .grand_chord => try renderChordCompatCandidate(&surface, image_name, .grand_chord),
        .chord => try renderChordCompatCandidate(&surface, image_name, .chord),
        .wide_chord => try renderChordCompatCandidate(&surface, image_name, .wide_chord),
        .chord_clipped => try renderChordCompatCandidate(&surface, image_name, .chord_clipped),
        .center_square_text => try renderCenterSquareCandidate(&surface, image_name, scale_numerator, scale_denominator),
        .vert_text_black => try renderVerticalTextCandidate(&surface, image_name, false, scale_numerator, scale_denominator),
        .vert_text_b2t_black => try renderVerticalTextCandidate(&surface, image_name, true, scale_numerator, scale_denominator),
        else => return error.UnsupportedKind,
    }

    return required;
}

pub fn renderReferenceSvgRgba(kind_index: usize, svg: []const u8, out_rgba: []u8) Error!usize {
    return renderReferenceSvgRgbaScaled(kind_index, svg, SCALE_NUMERATOR, SCALE_DENOMINATOR, out_rgba);
}

pub fn renderReferenceSvgRgbaScaled(kind_index: usize, svg: []const u8, scale_numerator: u32, scale_denominator: u32, out_rgba: []u8) Error!usize {
    const kind_id = svg_compat.kindId(kind_index) orelse return error.UnsupportedKind;
    if (!kindSupported(kind_index)) return error.UnsupportedKind;

    const required = requiredRgbaBytesScaled(kind_index, 0, scale_numerator, scale_denominator);
    if (out_rgba.len < required) return error.OutputTooSmall;

    var surface = try initSurface(kind_id, required, out_rgba, scale_numerator, scale_denominator);
    switch (kind_id) {
        .opc => try renderOpcReference(&surface, svg, scale_numerator, scale_denominator),
        .oc => try renderOcReference(&surface, svg),
        .optc => try renderOptcReference(&surface, svg),
        .eadgbe => try renderEadgbeReference(&surface, svg, scale_numerator, scale_denominator),
        .wide_chord, .chord_clipped, .grand_chord, .chord => try renderChordCompatReference(&surface, svg),
        .center_square_text, .vert_text_black, .vert_text_b2t_black => try renderTextReference(&surface, svg, scale_numerator, scale_denominator),
        else => return error.UnsupportedKind,
    }

    return required;
}

fn initSurface(kind_id: svg_compat.KindId, required: usize, out_rgba: []u8, scale_numerator: u32, scale_denominator: u32) Error!Surface {
    const width = switch (kind_id) {
        .opc => scaledDim(100, scale_numerator, scale_denominator),
        .eadgbe => scaledDim(100, scale_numerator, scale_denominator),
        .oc, .optc => scaledDim(70, scale_numerator, scale_denominator),
        .grand_chord => scaledDimFloat(GRAND_CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .chord => scaledDimFloat(CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .wide_chord => scaledDimFloat(WIDE_CHORD_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .chord_clipped => scaledDimFloat(CHORD_CLIPPED_SOURCE_WIDTH, scale_numerator, scale_denominator),
        .center_square_text => scaledDim(36, scale_numerator, scale_denominator),
        .vert_text_black, .vert_text_b2t_black => scaledDim(36, scale_numerator, scale_denominator),
        else => return error.UnsupportedKind,
    };
    const height = switch (kind_id) {
        .opc => scaledDim(100, scale_numerator, scale_denominator),
        .eadgbe => scaledDim(100, scale_numerator, scale_denominator),
        .oc, .optc => scaledDim(70, scale_numerator, scale_denominator),
        .grand_chord => scaledDimFloat(GRAND_CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .chord => scaledDimFloat(CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .wide_chord => scaledDimFloat(WIDE_CHORD_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .chord_clipped => scaledDimFloat(CHORD_CLIPPED_SOURCE_HEIGHT, scale_numerator, scale_denominator),
        .center_square_text => scaledDim(36, scale_numerator, scale_denominator),
        .vert_text_black, .vert_text_b2t_black => scaledDim(90, scale_numerator, scale_denominator),
        else => return error.UnsupportedKind,
    };
    if (width == 0 or height == 0) return error.UnsupportedKind;
    return .{
        .pixels = out_rgba[0..required],
        .width = width,
        .height = height,
        .stride = width * 4,
    };
}

fn renderOpcCandidate(surface: *Surface, image_name: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    const set_label = firstCsvField(trimSvgSuffix(image_name));
    const set = parseSetLabel(set_label) orelse return error.InvalidImage;

    clear(surface, .{ 255, 255, 255, 255 });
    drawRect(surface, 0.0, 0.0, @floatFromInt(surface.width), @floatFromInt(surface.height), .{ 255, 255, 255, 255 }, .{ 0, 0, 0, 0 }, 0.0);

    const root = rootScaleMatrix(scale_numerator, scale_denominator);
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
        drawCircle(surface, transformed.x, transformed.y, radius, fill, OPC_STROKE_COLORS[pc], stroke_width);
    }
}

const OcImageArgs = struct {
    family: []const u8,
    transposition: i8,
    roman: []const u8,
};

fn renderOcCandidate(surface: *Surface, image_name: []const u8) Error!void {
    const args = parseOcImageArgs(trimSvgSuffix(image_name)) orelse return error.InvalidImage;
    const template = findOcTemplate(args.family, args.roman) orelse return error.InvalidImage;

    var body_buf: [OC_TEMPLATE_BUFFER_LIMIT]u8 = undefined;
    const body = try buildOcBody(template.body_template, ocTranspositionColorText(args.transposition), ocTranspositionTintText(args.transposition), &body_buf);

    clear(surface, .{ 0, 0, 0, 0 });
    try renderMarkup(surface, body, compat70ViewBoxMatrix(surface));
}

const OptcImageArgs = struct {
    label: []const u8,
    set: pcs.PitchClassSet,
    cluster_mask: pcs.PitchClassSet,
    dash_mask: pcs.PitchClassSet,
    black_mask: pcs.PitchClassSet,
};

fn renderOptcCandidate(surface: *Surface, image_name: []const u8) Error!void {
    const args = parseOptcImageArgs(trimSvgSuffix(image_name)) orelse return error.InvalidImage;
    const variant = svg_clock.optcCompatVariant(args.label);
    const root = compat70ViewBoxMatrix(surface);
    const center = root.apply(50.0, 50.0);
    const scale = root.approxUniformScale();
    const include_white_overlay = args.label.len >= 7;

    clear(surface, .{ 0, 0, 0, 0 });

    if (args.dash_mask != 0 and args.black_mask != 0) {
        try renderOptcSpokes(surface, root, args.dash_mask, hexColor("#777"), 9.0 * scale, .{ .on = 1.6 * scale, .off = 0.8 * scale });
        try renderOptcSpokes(surface, root, args.black_mask, hexColor("#000"), 9.0 * scale, .{});
        if (include_white_overlay) {
            try renderOptcSpokes(surface, root, args.black_mask, hexColor("#fff"), 5.0 * scale, .{});
        }
    }

    drawCircle(surface, center.x, center.y, 20.0 * scale, parseColor(variant.center_fill), hexColor("#000"), 2.0 * scale);

    for (svg_clock.OPTC_COMPAT_PC_ORDER) |pc| {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const present = (args.set & bit) != 0;
        const in_cluster = (args.cluster_mask & bit) != 0;
        const fill = if (!present)
            [4]u8{ 0, 0, 0, 0 }
        else if (in_cluster)
            parseColor("gray")
        else
            hexColor("#000");
        const pos = svg_clock.optcCompatCirclePosition(pc);
        const transformed = root.apply(pos.x, pos.y);
        drawCircle(surface, transformed.x, transformed.y, 10.0 * scale, fill, hexColor("#000"), 3.0 * scale);
    }

    const label_transform = root.multiply(parseTransformList(variant.transform) catch return error.InvalidSvg);
    try renderPathFill(surface, variant.text_path, label_transform, parseColor(variant.text_fill));
}

fn renderOptcReference(surface: *Surface, svg: []const u8) Error!void {
    clear(surface, .{ 0, 0, 0, 0 });

    const root = compat70ViewBoxMatrix(surface);
    var current_group_transform = Matrix{};
    var group_depth: usize = 0;
    var cursor: usize = 0;

    while (nextTag(svg, cursor)) |tag| {
        cursor = tag.end;
        const tag_text = svg[tag.start..tag.end];

        if (tag.close) {
            if (std.mem.eql(u8, tag.name, "g") and group_depth > 0) {
                group_depth -= 1;
                if (group_depth == 0) current_group_transform = Matrix{};
            }
            continue;
        }

        if (std.mem.eql(u8, tag.name, "g")) {
            if (group_depth == 0) {
                current_group_transform = parseTransformAttr(tag_text) orelse Matrix{};
            }
            group_depth += 1;
            continue;
        }

        if (std.mem.eql(u8, tag.name, "circle")) {
            try renderCircleTag(tag_text, root, surface);
            continue;
        }

        if (std.mem.eql(u8, tag.name, "path")) {
            try renderPathTag(tag_text, root.multiply(current_group_transform), surface);
        }
    }
}

fn renderOcReference(surface: *Surface, svg: []const u8) Error!void {
    clear(surface, .{ 0, 0, 0, 0 });
    try renderMarkup(surface, svg, compat70ViewBoxMatrix(surface));
}

const DashSpec = struct {
    on: f64 = 0.0,
    off: f64 = 0.0,
};

fn renderOptcSpokes(surface: *Surface, root: Matrix, mask: pcs.PitchClassSet, color: [4]u8, stroke_width: f64, dash: DashSpec) Error!void {
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        if ((mask & bit) == 0) continue;
        try renderPathStroke(surface, svg_clock.optcCompatSpokePath(pc), root, color, stroke_width, dash.on, dash.off);
    }
}

fn compat70ViewBoxMatrix(surface: *const Surface) Matrix {
    const sx = @as(f64, @floatFromInt(surface.width)) / 114.0;
    const sy = @as(f64, @floatFromInt(surface.height)) / 114.0;
    return .{
        .a = sx,
        .d = sy,
        .e = 7.0 * sx,
        .f = 7.0 * sy,
    };
}

fn renderMarkup(surface: *Surface, svg: []const u8, root: Matrix) Error!void {
    var transform_stack: [TAG_TRANSFORM_STACK_LIMIT]Matrix = undefined;
    var depth: usize = 1;
    transform_stack[0] = root;

    var cursor: usize = 0;
    while (nextTag(svg, cursor)) |tag| {
        cursor = tag.end;
        const tag_text = svg[tag.start..tag.end];

        if (tag.close) {
            if (std.mem.eql(u8, tag.name, "g") and depth > 1) depth -= 1;
            continue;
        }

        const current_transform = transform_stack[depth - 1];
        if (std.mem.eql(u8, tag.name, "g")) {
            if (tag.self_close) continue;
            if (depth >= transform_stack.len) return error.UnsupportedSvgFeature;
            transform_stack[depth] = if (parseTransformAttr(tag_text)) |group_transform|
                current_transform.multiply(group_transform)
            else
                current_transform;
            depth += 1;
            continue;
        }

        if (std.mem.eql(u8, tag.name, "rect")) {
            try renderRectTag(tag_text, current_transform, surface);
            continue;
        }

        if (std.mem.eql(u8, tag.name, "circle")) {
            try renderCircleTag(tag_text, current_transform, surface);
            continue;
        }

        if (std.mem.eql(u8, tag.name, "path")) {
            try renderPathTag(tag_text, current_transform, surface);
        }
    }
}

fn renderSvgDocument(surface: *Surface, svg: []const u8) Error!void {
    clear(surface, .{ 0, 0, 0, 0 });
    const root = try svgDocumentMatrix(surface, svg);
    try renderMarkup(surface, svg, root);
}

fn svgDocumentMatrix(surface: *const Surface, svg: []const u8) Error!Matrix {
    const view_box = try parseSvgViewBox(svg);
    const sx = @as(f64, @floatFromInt(surface.width)) / view_box.width;
    const sy = @as(f64, @floatFromInt(surface.height)) / view_box.height;
    return .{
        .a = sx,
        .d = sy,
        .e = -view_box.min_x * sx,
        .f = -view_box.min_y * sy,
    };
}

fn parseSvgViewBox(svg: []const u8) Error!ViewBox {
    var cursor: usize = 0;
    while (nextTag(svg, cursor)) |tag| {
        cursor = tag.end;
        if (tag.close or !std.mem.eql(u8, tag.name, "svg")) continue;
        const tag_text = svg[tag.start..tag.end];
        if (parseAttr(tag_text, "viewBox")) |raw| {
            var numbers = parseNumberList(raw);
            const min_x = numbers.next() orelse return error.InvalidSvg;
            const min_y = numbers.next() orelse return error.InvalidSvg;
            const width = numbers.next() orelse return error.InvalidSvg;
            const height = numbers.next() orelse return error.InvalidSvg;
            if (width <= 0.0 or height <= 0.0) return error.InvalidSvg;
            return .{ .min_x = min_x, .min_y = min_y, .width = width, .height = height };
        }

        const width = parseAttrNumber(tag_text, "width") orelse return error.InvalidSvg;
        const height = parseAttrNumber(tag_text, "height") orelse return error.InvalidSvg;
        if (width <= 0.0 or height <= 0.0) return error.InvalidSvg;
        return .{ .min_x = 0.0, .min_y = 0.0, .width = width, .height = height };
    }
    return error.InvalidSvg;
}

fn parseOptcImageArgs(stem: []const u8) ?OptcImageArgs {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const label = parts.next() orelse return null;
    const set = parseSetLabel(label) orelse return null;

    var cluster_mask: pcs.PitchClassSet = 0;
    var dash_mask: pcs.PitchClassSet = 0;
    var black_mask: pcs.PitchClassSet = 0;

    if (parts.next()) |cluster_mask_token| {
        cluster_mask = parseSetMaskToken(cluster_mask_token) orelse return null;
        const dash_mask_token = parts.next() orelse return null;
        const black_mask_token = parts.next() orelse return null;
        dash_mask = parseSetMaskToken(dash_mask_token) orelse return null;
        black_mask = parseSetMaskToken(black_mask_token) orelse return null;
        if (parts.next() != null) return null;
    } else {
        cluster_mask = cluster.getClusters(set).cluster_mask;
    }

    return .{
        .label = label,
        .set = set,
        .cluster_mask = cluster_mask,
        .dash_mask = dash_mask,
        .black_mask = black_mask,
    };
}

fn parseSetMaskToken(token: []const u8) ?pcs.PitchClassSet {
    if (token.len == 0) return null;
    const raw = std.fmt.parseInt(u16, token, 10) catch return null;
    if (raw > 0x0fff) return null;
    return @as(pcs.PitchClassSet, @intCast(raw));
}

fn renderCenterSquareCandidate(surface: *Surface, image_name: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    const stem = trimSvgSuffix(image_name);
    const path_d = text_misc.centerSquarePathData(stem) orelse return error.InvalidImage;
    clear(surface, .{ 0, 0, 0, 0 });

    const root = rootScaleMatrix(scale_numerator, scale_denominator);
    const group_transform = parseTransformList("translate(18,0)") catch return error.InvalidSvg;
    try renderPathFill(surface, path_d, root.multiply(group_transform), .{ 128, 128, 128, 255 });
}

fn renderVerticalTextCandidate(surface: *Surface, image_name: []const u8, bottom_to_top: bool, scale_numerator: u32, scale_denominator: u32) Error!void {
    const stem = trimSvgSuffix(image_name);
    var path_buf: [16 * 1024]u8 = undefined;
    const path_d = text_misc.verticalPathData(stem, bottom_to_top, &path_buf) orelse return error.InvalidImage;

    clear(surface, .{ 0, 0, 0, 0 });
    const root = rootScaleMatrix(scale_numerator, scale_denominator);
    const group_transform = parseTransformList(if (bottom_to_top) "rotate(-90),translate(-45,0)" else "rotate(90),translate(45,0)") catch return error.InvalidSvg;
    try renderPathFill(surface, path_d, root.multiply(group_transform), .{ 0, 0, 0, 255 });
}

fn renderOpcReference(surface: *Surface, svg: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    clear(surface, .{ 255, 255, 255, 255 });
    const root = rootScaleMatrix(scale_numerator, scale_denominator);

    var cursor: usize = 0;
    while (findTag(svg, "rect", cursor)) |match| {
        cursor = match.end;
        const attrs = svg[match.start..match.end];
        try renderRectTag(attrs, root, surface);
    }

    cursor = 0;
    while (findTag(svg, "circle", cursor)) |match| {
        cursor = match.end;
        const attrs = svg[match.start..match.end];
        try renderCircleTag(attrs, root, surface);
    }
}

fn renderTextReference(surface: *Surface, svg: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    clear(surface, .{ 0, 0, 0, 0 });
    const root = rootScaleMatrix(scale_numerator, scale_denominator);
    const group_transform = blk: {
        const tag = findTag(svg, "g", 0) orelse break :blk Matrix{};
        break :blk parseTransformAttr(svg[tag.start..tag.end]) orelse Matrix{};
    };
    const base_transform = root.multiply(group_transform);

    var cursor: usize = 0;
    while (findTag(svg, "path", cursor)) |match| {
        cursor = match.end;
        const attrs = svg[match.start..match.end];
        try renderPathTag(attrs, base_transform, surface);
    }
}

const EadgbeBarreStyle = enum {
    text3319,
    text3299,
    text3307,
    text3315,
    text3311,
};

const EadgbeBarreInfo = struct {
    style: EadgbeBarreStyle,
    target: i8,
};

const EadgbeLayout = struct {
    empty: bool,
    has_nut: bool,
    start_fret: i8,
    barres: [2]?EadgbeBarreInfo = .{ null, null },
};

fn renderEadgbeCandidate(surface: *Surface, image_name: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    const frets = parseEadgbeImageStem(trimSvgSuffix(image_name)) orelse return error.InvalidImage;
    try renderEadgbeFrets(surface, frets, scale_numerator, scale_denominator);
}

fn renderEadgbeReference(surface: *Surface, svg: []const u8, scale_numerator: u32, scale_denominator: u32) Error!void {
    const frets = try parseEadgbeFretsFromSvg(svg);
    try renderEadgbeFrets(surface, frets, scale_numerator, scale_denominator);
}

fn renderChordCompatCandidate(surface: *Surface, image_name: []const u8, kind: chord_compat.Kind) Error!void {
    const stem = trimSvgSuffix(image_name);
    var svg_buf: [CHORD_COMPAT_SVG_BUFFER_LIMIT]u8 = undefined;
    const svg = chord_compat.render(stem, kind, &svg_buf);
    if (svg.len == 0) return error.InvalidImage;
    try renderSvgDocument(surface, svg);
}

fn renderChordCompatReference(surface: *Surface, svg: []const u8) Error!void {
    try renderSvgDocument(surface, svg);
}

fn renderEadgbeFrets(surface: *Surface, frets: [EADGBE_STRING_COUNT]i8, scale_numerator: u32, scale_denominator: u32) Error!void {
    clear(surface, .{ 0, 0, 0, 0 });

    const root = rootScaleMatrix(scale_numerator, scale_denominator);
    const group = root.multiply(EADGBE_BASE_GROUP);
    const scale = root.approxUniformScale();
    renderEadgbeGrid(surface, group, scale);

    const layout = analyzeEadgbeLayout(frets);
    if (layout.empty) return;

    if (layout.has_nut) {
        drawLineSegment(surface, group.apply(6.0, 16.5), group.apply(67.0, 16.5), hexColor("#000"), 4.0 * scale);
    } else {
        renderEadgbePositionLabel(surface, group, layout.start_fret, scale);
    }

    for (layout.barres) |maybe_barre| {
        if (maybe_barre) |barre| try renderEadgbeBarre(surface, group, frets, layout.start_fret, barre, scale);
    }

    var rev: usize = 0;
    while (rev < EADGBE_STRING_COUNT) : (rev += 1) {
        const string_index = EADGBE_STRING_COUNT - 1 - rev;
        const fret = frets[string_index];
        if (fret < 0) {
            try renderEadgbeXMarker(surface, group, string_index, layout.has_nut, scale);
            continue;
        }
        if (fret == 0) {
            renderEadgbeOpenMarker(surface, group, string_index, scale);
            continue;
        }

        const y_idx_i = fret - layout.start_fret;
        if (y_idx_i < 0 or y_idx_i > 4) continue;
        renderEadgbeDotMarker(surface, group, string_index, @as(usize, @intCast(y_idx_i)), scale);
    }
}

fn renderEadgbeGrid(surface: *Surface, group: Matrix, scale: f64) void {
    const top_left = group.apply(6.5, 18.5);
    drawRect(surface, top_left.x, top_left.y, 60.0 * scale, 60.0 * scale, .{ 0, 0, 0, 0 }, hexColor("#000"), scale);

    for (&[_]f64{ 18.5, 30.5, 42.5, 54.5 }) |x| {
        drawLineSegment(surface, group.apply(x, 18.5), group.apply(x, 78.5), hexColor("#000"), scale);
    }
    for (&[_]f64{ 30.5, 42.5, 54.5, 66.5 }) |y| {
        drawLineSegment(surface, group.apply(6.5, y), group.apply(66.5, y), hexColor("#000"), scale);
    }
}

fn renderEadgbeDotMarker(surface: *Surface, group: Matrix, string_index: usize, y_idx: usize, scale: f64) void {
    const center = group.apply(EADGBE_DOT_CENTER_X + EADGBE_DOT_X[string_index], EADGBE_DOT_CENTER_Y + EADGBE_DOT_Y[y_idx]);
    drawCircle(surface, center.x, center.y, EADGBE_DOT_RADIUS * scale, hexColor("#000"), hexColor("#000"), scale);
}

fn renderEadgbeOpenMarker(surface: *Surface, group: Matrix, string_index: usize, scale: f64) void {
    const center = group.apply(EADGBE_DOT_CENTER_X + EADGBE_DOT_X[string_index], EADGBE_DOT_CENTER_Y - 61.25);
    drawCircle(surface, center.x, center.y, EADGBE_DOT_RADIUS * scale, .{ 0, 0, 0, 0 }, hexColor("#000"), scale);
}

fn renderEadgbeXMarker(surface: *Surface, group: Matrix, string_index: usize, has_nut: bool, scale: f64) Error!void {
    const outer = group.multiply(parseTranslateTransformArgs(EADGBE_XMARK_X[string_index], if (has_nut) 0.0 else 4.0)).multiply(EADGBE_X_ROTATE);
    try renderPathStroke(surface, EADGBE_X_LINE_A, outer, hexColor("#000"), scale, 0.0, 0.0);
    try renderPathStroke(surface, EADGBE_X_LINE_B, outer, hexColor("#000"), scale, 0.0, 0.0);
}

fn renderEadgbePositionLabel(surface: *Surface, group: Matrix, start_fret: i8, scale: f64) void {
    const value: u8 = @intCast(@max(start_fret, 0));
    var digits: [2]u8 = undefined;
    const digit_count: usize = if (value >= 10) 2 else 1;
    if (digit_count == 2) {
        digits[0] = '0' + @as(u8, @intCast(value / 10));
        digits[1] = '0' + @as(u8, @intCast(value % 10));
    } else {
        digits[0] = '0' + value;
    }

    const digit_width: f64 = 5.2;
    const digit_height: f64 = 9.2;
    const digit_gap: f64 = 1.6;
    const total_width = if (digit_count == 2) digit_width * 2.0 + digit_gap else digit_width;
    const base_x = 73.0 - total_width / 2.0;
    const base_y = 19.0;

    var i: usize = 0;
    while (i < digit_count) : (i += 1) {
        renderEadgbeDigit(surface, group, digits[i], base_x + @as(f64, @floatFromInt(i)) * (digit_width + digit_gap), base_y, digit_width, digit_height, 0.95 * scale);
    }
}

fn renderEadgbeDigit(surface: *Surface, group: Matrix, digit: u8, x: f64, y: f64, width: f64, height: f64, stroke_width: f64) void {
    const mask: u8 = switch (digit) {
        '0' => 0b0111111,
        '1' => 0b0000110,
        '2' => 0b1011011,
        '3' => 0b1001111,
        '4' => 0b1100110,
        '5' => 0b1101101,
        '6' => 0b1111101,
        '7' => 0b0000111,
        '8' => 0b1111111,
        '9' => 0b1101111,
        else => 0,
    };
    const half_h = height / 2.0;
    const color = hexColor("#000");

    if ((mask & (1 << 0)) != 0) drawLineSegment(surface, group.apply(x, y), group.apply(x + width, y), color, stroke_width);
    if ((mask & (1 << 1)) != 0) drawLineSegment(surface, group.apply(x + width, y), group.apply(x + width, y + half_h), color, stroke_width);
    if ((mask & (1 << 2)) != 0) drawLineSegment(surface, group.apply(x + width, y + half_h), group.apply(x + width, y + height), color, stroke_width);
    if ((mask & (1 << 3)) != 0) drawLineSegment(surface, group.apply(x, y + height), group.apply(x + width, y + height), color, stroke_width);
    if ((mask & (1 << 4)) != 0) drawLineSegment(surface, group.apply(x, y + half_h), group.apply(x, y + height), color, stroke_width);
    if ((mask & (1 << 5)) != 0) drawLineSegment(surface, group.apply(x, y), group.apply(x, y + half_h), color, stroke_width);
    if ((mask & (1 << 6)) != 0) drawLineSegment(surface, group.apply(x, y + half_h), group.apply(x + width, y + half_h), color, stroke_width);
}

fn renderEadgbeBarre(surface: *Surface, group: Matrix, frets: [EADGBE_STRING_COUNT]i8, start_fret: i8, barre: EadgbeBarreInfo, scale: f64) Error!void {
    const y_idx_i = barre.target - start_fret;
    if (y_idx_i < 0 or y_idx_i > 4) return;
    const y_idx: usize = @intCast(y_idx_i);
    const mask = eadgbeFretMask(frets, barre.target);
    const min_index = eadgbeMinIndex(mask) orelse return;
    const max_index = eadgbeMaxIndex(mask) orelse return;
    const span = max_index - min_index + 1;

    const Size = struct { width: f64, height: f64, x_offset: f64 };
    const size: Size = switch (barre.style) {
        .text3319 => .{ .width = 5.8, .height = 17.5, .x_offset = -8.6 },
        .text3315 => .{ .width = 5.5, .height = 16.0, .x_offset = -8.1 },
        .text3311 => .{ .width = 5.0, .height = 13.6, .x_offset = -7.8 },
        .text3299 => .{ .width = 4.8, .height = 12.4, .x_offset = -7.2 },
        .text3307 => .{ .width = 5.2, .height = 13.8, .x_offset = -7.6 },
    };
    const height = size.height + @as(f64, @floatFromInt(@max(span, 2) - 2)) * 0.5;
    const x = EADGBE_DOT_CENTER_X + EADGBE_DOT_X[min_index] + size.x_offset;
    const y = (EADGBE_DOT_CENTER_Y + EADGBE_DOT_Y[y_idx]) - height / 2.0;
    const transform = group.multiply(parseTranslateTransformArgs(x, y)).multiply(.{
        .a = size.width / 4.0,
        .d = height / 12.0,
    });
    try renderPathStroke(surface, EADGBE_BARRE_CURVE, transform, hexColor("#000"), 0.9 * scale, 0.0, 0.0);
}

fn parseEadgbeImageStem(stem: []const u8) ?[EADGBE_STRING_COUNT]i8 {
    var frets: [EADGBE_STRING_COUNT]i8 = [_]i8{-1} ** EADGBE_STRING_COUNT;
    if (std.mem.eql(u8, stem, "index")) return frets;

    var parts = std.mem.splitScalar(u8, stem, ',');
    var count: usize = 0;
    while (parts.next()) |token| {
        if (count >= EADGBE_STRING_COUNT) return null;
        frets[count] = std.fmt.parseInt(i8, token, 10) catch return null;
        count += 1;
    }
    if (count != EADGBE_STRING_COUNT) return null;
    return frets;
}

fn parseEadgbeFretsFromSvg(svg: []const u8) Error![EADGBE_STRING_COUNT]i8 {
    const unset = std.math.minInt(i8);
    var frets: [EADGBE_STRING_COUNT]i8 = [_]i8{unset} ** EADGBE_STRING_COUNT;
    const has_nut = std.mem.indexOf(u8, svg, "id=\"path3297\"") != null;
    const start_fret = if (has_nut) @as(i8, 1) else parseEadgbeStartFret(svg) orelse -1;

    var marker_count: usize = 0;
    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, svg, cursor, "<!-- x -->")) |comment_start| {
        const group_start = std.mem.indexOfPos(u8, svg, comment_start, "<g") orelse break;
        const group_end = std.mem.indexOfPos(u8, svg, group_start, ">") orelse break;
        const tag_text = svg[group_start .. group_end + 1];
        const transform = parseTransformAttr(tag_text) orelse return error.InvalidSvg;
        const string_index = matchNearestCandidate(transform.e, &EADGBE_XMARK_X) orelse return error.InvalidSvg;
        frets[string_index] = -1;
        marker_count += 1;
        cursor = group_end + 1;
    }

    cursor = 0;
    while (nextTag(svg, cursor)) |tag| {
        cursor = tag.end;
        if (tag.close or !std.mem.eql(u8, tag.name, "path")) continue;

        const tag_text = svg[tag.start..tag.end];
        const id = parseAttr(tag_text, "id") orelse continue;
        if (!std.mem.eql(u8, id, "path3261") and !std.mem.eql(u8, id, "path3287")) continue;

        const transform = parseTransformAttr(tag_text) orelse return error.InvalidSvg;
        const string_index = matchNearestCandidate(transform.e, &EADGBE_DOT_X) orelse return error.InvalidSvg;
        if (std.mem.eql(u8, id, "path3287")) {
            frets[string_index] = 0;
            marker_count += 1;
            continue;
        }

        if (start_fret < 0) return error.InvalidSvg;
        const y_idx = matchNearestCandidate(transform.f, &EADGBE_DOT_Y) orelse return error.InvalidSvg;
        frets[string_index] = start_fret + @as(i8, @intCast(y_idx));
        marker_count += 1;
    }

    if (marker_count == 0) return [_]i8{-1} ** EADGBE_STRING_COUNT;

    for (frets) |fret| {
        if (fret == unset) return error.InvalidSvg;
    }
    return frets;
}

fn parseEadgbeStartFret(svg: []const u8) ?i8 {
    const tspan = findTag(svg, "tspan", 0) orelse return null;
    const close = std.mem.indexOfPos(u8, svg, tspan.end, "</tspan>") orelse return null;
    const raw = std.mem.trim(u8, svg[tspan.end..close], " \t\r\n");
    if (raw.len == 0) return null;
    return std.fmt.parseInt(i8, raw, 10) catch null;
}

fn matchNearestCandidate(value: f64, candidates: []const f64) ?usize {
    var best: ?usize = null;
    var best_delta: f64 = 0.0;
    for (candidates, 0..) |candidate, index| {
        const delta = @abs(candidate - value);
        if (best == null or delta < best_delta) {
            best = index;
            best_delta = delta;
        }
    }
    if (best == null or best_delta > 0.25) return null;
    return best;
}

fn analyzeEadgbeLayout(frets: [EADGBE_STRING_COUNT]i8) EadgbeLayout {
    var min_fret: i8 = 127;
    var max_fret: i8 = -1;
    for (frets) |fret| {
        if (fret < 0) continue;
        if (fret < min_fret) min_fret = fret;
        if (fret > max_fret) max_fret = fret;
    }

    if (max_fret < 0) {
        return .{
            .empty = true,
            .has_nut = false,
            .start_fret = 1,
        };
    }

    var layout = EadgbeLayout{
        .empty = false,
        .has_nut = max_fret <= 5,
        .start_fret = if (max_fret <= 5) 1 else min_fret,
    };
    var barre_count: usize = 0;

    if (eadgbeCompute3319(frets)) |target| {
        layout.barres[0] = .{ .style = .text3319, .target = target };
    } else if (eadgbeCompute3315(frets)) |target| {
        layout.barres[0] = .{ .style = .text3315, .target = target };
    } else if (eadgbeCompute3311(frets)) |target| {
        layout.barres[0] = .{ .style = .text3311, .target = target };
    } else {
        if (eadgbeCompute3299(frets)) |target| {
            layout.barres[barre_count] = .{ .style = .text3299, .target = target };
            barre_count += 1;
        }
        if (eadgbeCompute3307(frets)) |target| {
            layout.barres[barre_count] = .{ .style = .text3307, .target = target };
        }
    }

    return layout;
}

fn eadgbeCompute3319(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    const target = frets[0];
    if (target <= 0) return null;
    if (frets[EADGBE_STRING_COUNT - 1] != target) return null;
    if (!eadgbeHasHigherFret(frets, target)) return null;
    if (!eadgbeHasLowerFret(frets, target)) return target;
    if (target == 2 and frets[1] == 0 and frets[2] == 0 and frets[3] == 2 and frets[4] == 3 and frets[5] == 2) return target;
    return null;
}

fn eadgbeCompute3315(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    const target = frets[1];
    if (frets[0] != -1) return null;
    if (target <= 0) return null;
    if (frets[5] != target) return null;
    if (eadgbeHasLowerFret(frets, target)) return null;
    if (!eadgbeHasHigherFret(frets, target)) return null;
    return target;
}

fn eadgbeCompute3311(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    if (frets[0] == -1 and frets[1] > 0 and frets[2] == frets[1] + 1 and frets[3] == frets[1] and frets[4] == frets[1] and frets[5] == 0) {
        return frets[1];
    }

    const target = eadgbeMinPositiveFret(frets) orelse return null;
    const mask = eadgbeFretMask(frets, target);
    if (mask != EADGBE_MASK_3311_A and mask != EADGBE_MASK_3311_B and mask != EADGBE_MASK_3311_C) return null;
    if (eadgbeHasLowerFret(frets, target)) return null;
    if (!eadgbeHasHigherFret(frets, target)) return null;
    return target;
}

fn eadgbeCompute3299(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    const target = eadgbeMinPositiveFret(frets) orelse return null;
    const mask = eadgbeFretMask(frets, target);

    if (mask == EADGBE_MASK_3299_A and frets[3] > target) return target;
    if (mask == EADGBE_MASK_3299_B and frets[2] > target and frets[5] < 0 and frets[0] >= 0 and frets[1] >= 0) return target;
    if (mask == EADGBE_MASK_3299_C and target == 1 and frets[0] > target and frets[1] > target and frets[2] > target and frets[3] == 0) return target;

    return null;
}

fn eadgbeCompute3307(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    const mp = eadgbeMinPositiveFret(frets) orelse return null;
    const mask = eadgbeFretMask(frets, mp);
    const above_mp = eadgbeHasHigherFret(frets, mp);

    if (mask == EADGBE_MASK_3307_B and above_mp) return mp;
    if (mask == EADGBE_MASK_3307_C and (mp >= 2 or above_mp)) return mp;

    if (mask == EADGBE_MASK_3307_A and frets[1] > 0 and frets[2] == frets[1] and frets[3] == frets[1] and frets[4] < 0 and frets[5] < 0 and frets[0] == frets[1] + 3) {
        return mp;
    }
    if (frets[0] == -1 and frets[2] > 0 and frets[4] == frets[2] and frets[1] == frets[2] + 2 and frets[3] == frets[5] and (frets[3] == frets[2] + 1 or frets[3] == frets[2] + 2)) {
        return frets[2];
    }
    if (frets[0] == -1 and frets[3] > 0 and frets[5] == frets[3] and frets[4] == frets[3] + 1 and frets[2] == frets[3] + 2 and (frets[1] == frets[3] + 2 or frets[1] == frets[3] + 3)) {
        return frets[3];
    }
    if (frets[0] == -1 and frets[3] > 0 and frets[4] == frets[3] and frets[5] == frets[3]) {
        if (frets[1] == -1 and (frets[2] == frets[3] - 1 or frets[2] == frets[3] - 2) and frets[2] >= 0 and !(frets[3] == 1 and frets[2] == 0)) {
            return frets[3];
        }
        if (frets[1] == frets[3] - 2 and frets[2] == frets[3] - 2 and frets[1] > 0) {
            return frets[3];
        }
    }
    return null;
}

fn eadgbeMinPositiveFret(frets: [EADGBE_STRING_COUNT]i8) ?i8 {
    var min: i8 = 127;
    for (frets) |fret| {
        if (fret <= 0) continue;
        if (fret < min) min = fret;
    }
    return if (min == 127) null else min;
}

fn eadgbeHasLowerFret(frets: [EADGBE_STRING_COUNT]i8, target: i8) bool {
    for (frets) |fret| {
        if (fret >= 0 and fret < target) return true;
    }
    return false;
}

fn eadgbeHasHigherFret(frets: [EADGBE_STRING_COUNT]i8, target: i8) bool {
    for (frets) |fret| {
        if (fret > target) return true;
    }
    return false;
}

fn eadgbeFretMask(frets: [EADGBE_STRING_COUNT]i8, fret: i8) u8 {
    var mask: u8 = 0;
    for (frets, 0..) |current, index| {
        if (current == fret) mask |= @as(u8, 1) << @as(u3, @intCast(index));
    }
    return mask;
}

fn eadgbeMinIndex(mask: u8) ?usize {
    var index: usize = 0;
    while (index < EADGBE_STRING_COUNT) : (index += 1) {
        if ((mask & (@as(u8, 1) << @as(u3, @intCast(index)))) != 0) return index;
    }
    return null;
}

fn eadgbeMaxIndex(mask: u8) ?usize {
    var index: usize = EADGBE_STRING_COUNT;
    while (index > 0) {
        index -= 1;
        if ((mask & (@as(u8, 1) << @as(u3, @intCast(index)))) != 0) return index;
    }
    return null;
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

const TagToken = struct {
    start: usize,
    end: usize,
    close: bool,
    self_close: bool,
    name: []const u8,
};

fn nextTag(svg: []const u8, from: usize) ?TagToken {
    var cursor = from;
    while (cursor < svg.len) {
        const start = std.mem.indexOfPos(u8, svg, cursor, "<") orelse return null;
        const end = std.mem.indexOfPos(u8, svg, start, ">") orelse return null;

        var name_start = start + 1;
        var close = false;
        if (name_start >= end) return null;
        if (svg[name_start] == '/' and name_start + 1 < end) {
            close = true;
            name_start += 1;
        }

        if (svg[name_start] == '!' or svg[name_start] == '?') {
            cursor = end + 1;
            continue;
        }

        var name_end = name_start;
        while (name_end < end and isAttrNameChar(svg[name_end])) : (name_end += 1) {}
        if (name_end == name_start) {
            cursor = end + 1;
            continue;
        }

        return .{
            .start = start,
            .end = end + 1,
            .close = close,
            .self_close = end > start and svg[end - 1] == '/',
            .name = svg[name_start..name_end],
        };
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

fn renderPathTag(tag_text: []const u8, parent_transform: Matrix, surface: *Surface) Error!void {
    var paint = Paint{};
    applyPaintAttrs(tag_text, &paint);
    const d = parseAttr(tag_text, "d") orelse return error.InvalidSvg;

    const transform = if (parseTransformAttr(tag_text)) |element_transform|
        parent_transform.multiply(element_transform)
    else
        parent_transform;
    if (paint.fill[3] > 0) {
        try renderPathFill(surface, d, transform, paint.fill);
    }
    if (paint.stroke[3] > 0 and paint.stroke_width > 0.0) {
        const scale = transform.approxUniformScale();
        try renderPathStroke(
            surface,
            d,
            transform,
            paint.stroke,
            paint.stroke_width * scale,
            paint.stroke_dash_on * scale,
            paint.stroke_dash_off * scale,
        );
    }
}

fn renderPathFill(surface: *Surface, d: []const u8, transform: Matrix, fill: [4]u8) Error!void {
    if (fill[3] == 0) return;

    var builder = PathBuilder{};
    try buildPathEdges(d, transform, &builder);
    fillEdges(surface, builder.edges[0..builder.edge_count], fill);
}

fn renderPathStroke(surface: *Surface, d: []const u8, transform: Matrix, stroke: [4]u8, stroke_width: f64, dash_on: f64, dash_off: f64) Error!void {
    if (stroke[3] == 0 or stroke_width <= 0.0) return;

    var builder = PathBuilder{};
    try buildPathEdges(d, transform, &builder);
    strokeEdges(surface, builder.edges[0..builder.edge_count], stroke, stroke_width, dash_on, dash_off);
}

fn buildPathEdges(d: []const u8, transform: Matrix, builder: *PathBuilder) Error!void {
    var reader = PathReader{ .text = d };
    var cmd: u8 = 0;

    while (true) {
        reader.skipSeparators();
        if (reader.index >= reader.text.len) break;

        if (isPathCommand(reader.text[reader.index])) {
            cmd = reader.text[reader.index];
            reader.index += 1;
        } else if (cmd == 0) {
            return error.InvalidSvg;
        }

        switch (cmd) {
            'M', 'm' => {
                const is_relative = cmd == 'm';
                const x = reader.nextNumber() orelse return error.InvalidSvg;
                const y = reader.nextNumber() orelse return error.InvalidSvg;
                const base = if (is_relative and builder.has_current) builder.current else Point{ .x = 0.0, .y = 0.0 };
                builder.moveTo(.{ .x = base.x + x, .y = base.y + y });
                cmd = if (is_relative) 'l' else 'L';
                while (reader.hasNumber()) {
                    const line_x = reader.nextNumber() orelse return error.InvalidSvg;
                    const line_y = reader.nextNumber() orelse return error.InvalidSvg;
                    const line_base = if (cmd == 'l') builder.current else Point{ .x = 0.0, .y = 0.0 };
                    try builder.lineTo(transform, .{ .x = line_base.x + line_x, .y = line_base.y + line_y });
                    builder.prev_cmd = cmd;
                }
                builder.prev_cmd = cmd;
            },
            'L', 'l' => {
                const is_relative = cmd == 'l';
                while (reader.hasNumber()) {
                    const x = reader.nextNumber() orelse return error.InvalidSvg;
                    const y = reader.nextNumber() orelse return error.InvalidSvg;
                    const base = if (is_relative) builder.current else Point{ .x = 0.0, .y = 0.0 };
                    try builder.lineTo(transform, .{ .x = base.x + x, .y = base.y + y });
                }
                builder.prev_cmd = cmd;
            },
            'C', 'c' => {
                const is_relative = cmd == 'c';
                while (reader.hasNumber()) {
                    const x1 = reader.nextNumber() orelse return error.InvalidSvg;
                    const y1 = reader.nextNumber() orelse return error.InvalidSvg;
                    const x2 = reader.nextNumber() orelse return error.InvalidSvg;
                    const y2 = reader.nextNumber() orelse return error.InvalidSvg;
                    const x = reader.nextNumber() orelse return error.InvalidSvg;
                    const y = reader.nextNumber() orelse return error.InvalidSvg;
                    const base = if (is_relative) builder.current else Point{ .x = 0.0, .y = 0.0 };
                    try builder.cubicTo(
                        transform,
                        .{ .x = base.x + x1, .y = base.y + y1 },
                        .{ .x = base.x + x2, .y = base.y + y2 },
                        .{ .x = base.x + x, .y = base.y + y },
                    );
                }
                builder.prev_cmd = cmd;
            },
            'S', 's' => {
                const is_relative = cmd == 's';
                while (reader.hasNumber()) {
                    const reflected = if (builder.prev_cmd == 'C' or builder.prev_cmd == 'c' or builder.prev_cmd == 'S' or builder.prev_cmd == 's') blk: {
                        const ctrl = builder.last_cubic_ctrl orelse builder.current;
                        break :blk Point{
                            .x = builder.current.x * 2.0 - ctrl.x,
                            .y = builder.current.y * 2.0 - ctrl.y,
                        };
                    } else builder.current;

                    const x2 = reader.nextNumber() orelse return error.InvalidSvg;
                    const y2 = reader.nextNumber() orelse return error.InvalidSvg;
                    const x = reader.nextNumber() orelse return error.InvalidSvg;
                    const y = reader.nextNumber() orelse return error.InvalidSvg;
                    const base = if (is_relative) builder.current else Point{ .x = 0.0, .y = 0.0 };
                    try builder.cubicTo(
                        transform,
                        reflected,
                        .{ .x = base.x + x2, .y = base.y + y2 },
                        .{ .x = base.x + x, .y = base.y + y },
                    );
                }
                builder.prev_cmd = cmd;
            },
            'Z', 'z' => {
                try builder.closePath(transform);
                builder.prev_cmd = cmd;
            },
            else => return error.UnsupportedSvgFeature,
        }
    }
}

fn fillEdges(surface: *Surface, edges: []const Edge, fill: [4]u8) void {
    if (edges.len == 0 or fill[3] == 0) return;

    var min_x = edges[0].a.x;
    var max_x = edges[0].a.x;
    var min_y = edges[0].a.y;
    var max_y = edges[0].a.y;
    for (edges) |edge| {
        min_x = @min(min_x, @min(edge.a.x, edge.b.x));
        max_x = @max(max_x, @max(edge.a.x, edge.b.x));
        min_y = @min(min_y, @min(edge.a.y, edge.b.y));
        max_y = @max(max_y, @max(edge.a.y, edge.b.y));
    }

    const x0: i32 = @as(i32, @intFromFloat(@floor(min_x))) - 1;
    const x1: i32 = @as(i32, @intFromFloat(@ceil(max_x))) + 1;
    const y0: i32 = @as(i32, @intFromFloat(@floor(min_y))) - 1;
    const y1: i32 = @as(i32, @intFromFloat(@ceil(max_y))) + 1;

    var py = y0;
    while (py <= y1) : (py += 1) {
        const y = @as(f64, @floatFromInt(py)) + 0.5;
        var px = x0;
        while (px <= x1) : (px += 1) {
            const x = @as(f64, @floatFromInt(px)) + 0.5;
            var winding: i32 = 0;

            for (edges) |edge| {
                if (edge.a.y <= y) {
                    if (edge.b.y > y and isLeft(edge.a, edge.b, .{ .x = x, .y = y }) > 0.0) winding += 1;
                } else {
                    if (edge.b.y <= y and isLeft(edge.a, edge.b, .{ .x = x, .y = y }) < 0.0) winding -= 1;
                }
            }

            if (winding != 0) {
                if (pixelPtr(surface, px, py)) |dst| blend(dst, fill);
            }
        }
    }
}

fn strokeEdges(surface: *Surface, edges: []const Edge, stroke: [4]u8, stroke_width: f64, dash_on: f64, dash_off: f64) void {
    if (edges.len == 0 or stroke[3] == 0 or stroke_width <= 0.0) return;
    for (edges) |edge| {
        strokeEdge(surface, edge, stroke, stroke_width, dash_on, dash_off);
    }
}

fn strokeEdge(surface: *Surface, edge: Edge, stroke: [4]u8, stroke_width: f64, dash_on: f64, dash_off: f64) void {
    const edge_length = distance(edge.a, edge.b);
    if (edge_length <= 0.0000001) {
        drawLineSegment(surface, edge.a, edge.b, stroke, stroke_width);
        return;
    }

    if (dash_on <= 0.0 or dash_off <= 0.0) {
        drawLineSegment(surface, edge.a, edge.b, stroke, stroke_width);
        return;
    }

    var cursor: f64 = 0.0;
    var draw = true;
    while (cursor < edge_length - 0.0000001) {
        const span = if (draw) dash_on else dash_off;
        if (span <= 0.0) break;
        const next = @min(edge_length, cursor + span);
        if (draw and next > cursor) {
            drawLineSegment(
                surface,
                lerpPoint(edge.a, edge.b, cursor / edge_length),
                lerpPoint(edge.a, edge.b, next / edge_length),
                stroke,
                stroke_width,
            );
        }
        cursor = next;
        draw = !draw;
    }
}

fn drawLineSegment(surface: *Surface, a: Point, b: Point, stroke: [4]u8, stroke_width: f64) void {
    if (stroke[3] == 0 or stroke_width <= 0.0) return;
    const half = stroke_width / 2.0;
    const min_x: i32 = @intFromFloat(@floor(@min(a.x, b.x) - half - 1.0));
    const max_x: i32 = @intFromFloat(@ceil(@max(a.x, b.x) + half + 1.0));
    const min_y: i32 = @intFromFloat(@floor(@min(a.y, b.y) - half - 1.0));
    const max_y: i32 = @intFromFloat(@ceil(@max(a.y, b.y) + half + 1.0));

    var py = min_y;
    while (py <= max_y) : (py += 1) {
        var px = min_x;
        while (px <= max_x) : (px += 1) {
            if (pixelPtr(surface, px, py)) |dst| {
                const p = Point{
                    .x = @as(f64, @floatFromInt(px)) + 0.5,
                    .y = @as(f64, @floatFromInt(py)) + 0.5,
                };
                if (distancePointToSegment(p, a, b) <= half) {
                    blend(dst, stroke);
                }
            }
        }
    }
}

fn distancePointToSegment(p: Point, a: Point, b: Point) f64 {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len_sq = dx * dx + dy * dy;
    if (len_sq <= 0.0000001) return distance(p, a);

    const t = std.math.clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / len_sq, 0.0, 1.0);
    const proj = Point{
        .x = a.x + dx * t,
        .y = a.y + dy * t,
    };
    return distance(p, proj);
}

fn lerpPoint(a: Point, b: Point, t: f64) Point {
    return .{
        .x = a.x + (b.x - a.x) * t,
        .y = a.y + (b.y - a.y) * t,
    };
}

fn isLeft(a: Point, b: Point, p: Point) f64 {
    return (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y);
}

fn cubicPoint(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) Point {
    const u = 1.0 - t;
    const tt = t * t;
    const uu = u * u;
    const uuu = uu * u;
    const ttt = tt * t;
    return .{
        .x = uuu * p0.x + 3.0 * uu * t * p1.x + 3.0 * u * tt * p2.x + ttt * p3.x,
        .y = uuu * p0.y + 3.0 * uu * t * p1.y + 3.0 * u * tt * p2.y + ttt * p3.y,
    };
}

fn cubicStepCount(p0: Point, p1: Point, p2: Point, p3: Point) u32 {
    const approx_len = distance(p0, p1) + distance(p1, p2) + distance(p2, p3);
    const steps = @as(u32, @intFromFloat(@ceil(approx_len / 3.0)));
    return @max(@as(u32, 8), @min(@as(u32, 48), steps));
}

fn distance(a: Point, b: Point) f64 {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    return @sqrt(dx * dx + dy * dy);
}

fn rootScaleMatrix(scale_numerator: u32, scale_denominator: u32) Matrix {
    const scale = @as(f64, @floatFromInt(scale_numerator)) / @as(f64, @floatFromInt(scale_denominator));
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
    if (parseAttr(tag_text, "stroke-dasharray")) |value| {
        const dash = parseDashArray(value);
        paint.stroke_dash_on = dash.on;
        paint.stroke_dash_off = dash.off;
    }

    if (parseAttr(tag_text, "style")) |style| {
        var parts = std.mem.splitScalar(u8, style, ';');
        while (parts.next()) |part| {
            const colon = std.mem.indexOfScalar(u8, part, ':') orelse continue;
            const key = std.mem.trim(u8, part[0..colon], " \t\r\n");
            const value = std.mem.trim(u8, part[colon + 1 ..], " \t\r\n");
            if (std.mem.eql(u8, key, "fill")) paint.fill = parseColor(value);
            if (std.mem.eql(u8, key, "stroke")) paint.stroke = parseColor(value);
            if (std.mem.eql(u8, key, "stroke-width")) paint.stroke_width = parseNumber(value, paint.stroke_width);
            if (std.mem.eql(u8, key, "stroke-dasharray")) {
                const dash = parseDashArray(value);
                paint.stroke_dash_on = dash.on;
                paint.stroke_dash_off = dash.off;
            }
        }
    }
}

fn parseDashArray(text: []const u8) DashSpec {
    var numbers = parseNumberList(text);
    const on = numbers.next() orelse 0.0;
    const off = numbers.next() orelse on;
    return .{ .on = on, .off = off };
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
        else if (std.mem.eql(u8, name, "rotate"))
            parseRotateTransform(args)
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

fn parseRotateTransform(args: []const u8) Matrix {
    var numbers = parseNumberList(args);
    const angle_degrees = numbers.next() orelse 0.0;
    const radians = angle_degrees * std.math.pi / 180.0;
    const cos_v = std.math.cos(radians);
    const sin_v = std.math.sin(radians);
    const rotate = Matrix{
        .a = cos_v,
        .b = sin_v,
        .c = -sin_v,
        .d = cos_v,
    };

    if (numbers.next()) |cx| {
        const cy = numbers.next() orelse 0.0;
        return parseTranslateTransformArgs(cx, cy).multiply(rotate).multiply(parseTranslateTransformArgs(-cx, -cy));
    }

    return rotate;
}

fn parseTranslateTransformArgs(tx: f64, ty: f64) Matrix {
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
        self.index = scanNumberEnd(self.text, start);
        return parseNumber(self.text[start..self.index], 0.0);
    }
};

fn scanNumberEnd(text: []const u8, start: usize) usize {
    var index = start;
    if (index < text.len and (text[index] == '-' or text[index] == '+')) index += 1;

    var seen_exp = false;
    while (index < text.len) {
        const ch = text[index];
        if ((ch >= '0' and ch <= '9') or ch == '.') {
            index += 1;
            continue;
        }
        if ((ch == 'e' or ch == 'E') and !seen_exp) {
            seen_exp = true;
            index += 1;
            if (index < text.len and (text[index] == '-' or text[index] == '+')) index += 1;
            continue;
        }
        break;
    }
    return index;
}

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

fn isPathCommand(ch: u8) bool {
    return switch (ch) {
        'M', 'm', 'L', 'l', 'C', 'c', 'S', 's', 'Z', 'z' => true,
        else => false,
    };
}

fn isNumberStart(ch: u8) bool {
    return (ch >= '0' and ch <= '9') or ch == '-' or ch == '+' or ch == '.';
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
    if (std.mem.eql(u8, text, "gray")) return .{ 128, 128, 128, 255 };
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

fn findKindIndex(kind_id: svg_compat.KindId) usize {
    var i: usize = 0;
    while (i < svg_compat.kindCount()) : (i += 1) {
        if (svg_compat.kindId(i) == kind_id) return i;
    }
    unreachable;
}

fn findImageIndexByName(kind_id: svg_compat.KindId, image_name: []const u8) usize {
    const kind_index = findKindIndex(kind_id);
    var image_index: usize = 0;
    while (image_index < svg_compat.imageCount(kind_index)) : (image_index += 1) {
        const current = svg_compat.imageName(kind_index, image_index) orelse continue;
        if (std.mem.eql(u8, current, image_name)) return image_index;
    }
    unreachable;
}

fn runScaledBitmapParity(kind_id: svg_compat.KindId, image_index: usize, scale_numerator: u32, scale_denominator: u32, svg_buf: []u8) !void {
    const kind_index = findKindIndex(kind_id);
    const svg = svg_compat.generateByIndex(kind_index, image_index, svg_buf);
    var candidate: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    var reference: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    const candidate_len = try renderCandidateRgbaScaled(kind_index, image_index, scale_numerator, scale_denominator, &candidate);
    const reference_len = try renderReferenceSvgRgbaScaled(kind_index, svg, scale_numerator, scale_denominator, &reference);
    try std.testing.expectEqual(candidate_len, reference_len);
    try std.testing.expectEqualSlices(u8, candidate[0..candidate_len], reference[0..reference_len]);
}

test "opc candidate render is deterministic at 55 and 200 percent" {
    const kind_index = findKindIndex(.opc);
    const image_index: usize = 3;
    var a: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    var b: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    const len_a = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &a);
    const len_b = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &b);
    try std.testing.expectEqual(len_a, len_b);
    try std.testing.expectEqualSlices(u8, a[0..len_a], b[0..len_b]);
}

test "opc reference parser matches candidate bitmap for generated svg at 55 and 200 percent" {
    var svg_buf: [4096]u8 = undefined;
    try runScaledBitmapParity(.opc, 3, 55, 100, &svg_buf);
    try runScaledBitmapParity(.opc, 3, 200, 100, &svg_buf);
}

test "center-square bitmap proof candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [4096]u8 = undefined;
    try runScaledBitmapParity(.center_square_text, 0, 55, 100, &svg_buf);
    try runScaledBitmapParity(.center_square_text, 0, 200, 100, &svg_buf);
}

test "vertical text bitmap proof candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [16 * 1024]u8 = undefined;
    try runScaledBitmapParity(.vert_text_black, 0, 55, 100, &svg_buf);
    try runScaledBitmapParity(.vert_text_black, 0, 200, 100, &svg_buf);
}

test "bottom-to-top vertical text bitmap proof candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [16 * 1024]u8 = undefined;
    try runScaledBitmapParity(.vert_text_b2t_black, 0, 55, 100, &svg_buf);
    try runScaledBitmapParity(.vert_text_b2t_black, 0, 200, 100, &svg_buf);
}

test "optc candidate render is deterministic at 55 and 200 percent" {
    const kind_index = findKindIndex(.optc);
    const image_index = findImageIndexByName(.optc, "01245689A,1911,2184,2184.svg");
    var a: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    var b: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;

    const len_a = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &a);
    const len_b = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &b);
    try std.testing.expectEqual(len_a, len_b);
    try std.testing.expectEqualSlices(u8, a[0..len_a], b[0..len_b]);
}

test "optc native RGBA candidate matches generated svg raster at 55 and 200 percent" {
    const image_index = findImageIndexByName(.optc, "01245689A,1911,2184,2184.svg");
    var svg_buf: [32 * 1024]u8 = undefined;
    try runScaledBitmapParity(.optc, image_index, 55, 100, &svg_buf);
    try runScaledBitmapParity(.optc, image_index, 200, 100, &svg_buf);
}

fn parseOcImageArgs(stem: []const u8) ?OcImageArgs {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const family = parts.next() orelse return null;
    const transposition_token = parts.next() orelse return null;
    const roman = parts.next() orelse return null;
    if (parts.next() != null) return null;

    const transposition = std.fmt.parseInt(i8, transposition_token, 10) catch return null;
    return .{
        .family = family,
        .transposition = transposition,
        .roman = roman,
    };
}

fn findOcTemplate(family: []const u8, roman: []const u8) ?oc_templates.OcTemplate {
    for (oc_templates.OC_TEMPLATES) |entry| {
        if (std.mem.eql(u8, entry.family, family) and std.mem.eql(u8, entry.roman, roman)) {
            return entry;
        }
    }
    return null;
}

fn buildOcBody(body_template: []const u8, color: []const u8, tint: []const u8, buf: []u8) Error![]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();
    var parts = std.mem.splitSequence(u8, body_template, "__COLOR__");
    var first = true;
    while (parts.next()) |part| {
        if (!first) writer.writeAll(color) catch return error.OutputTooSmall;
        first = false;
        var tint_parts = std.mem.splitSequence(u8, part, "#bbe");
        var tint_first = true;
        while (tint_parts.next()) |tint_part| {
            if (!tint_first) writer.writeAll(tint) catch return error.OutputTooSmall;
            tint_first = false;
            writer.writeAll(tint_part) catch return error.OutputTooSmall;
        }
    }
    return buf[0..stream.pos];
}

fn ocTranspositionColorText(transposition: i8) []const u8 {
    return switch (transposition) {
        -1 => "black",
        0 => "#00c",
        1 => "#a4f",
        2 => "#f0f",
        3 => "#a16",
        4 => "#e02",
        5 => "#f91",
        6 => "#c81",
        7 => "#094",
        8 => "#161",
        9 => "#077",
        10 => "#0bb",
        11 => "#28f",
        else => "black",
    };
}

fn ocTranspositionTintText(transposition: i8) []const u8 {
    return switch (transposition) {
        0 => "#bbe",
        1 => "#dcf",
        2 => "#fbf",
        3 => "#dbc",
        4 => "#ebb",
        5 => "#fdb",
        6 => "#ffb",
        7 => "#beb",
        8 => "#bdc",
        9 => "#bee",
        10 => "#bff",
        11 => "#bdf",
        else => "#bbe",
    };
}

test "oc candidate render is deterministic at 55 and 200 percent" {
    const kind_index = findKindIndex(.oc);
    const image_index = findImageIndexByName(.oc, "aco,0,x7.svg");
    var a: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    var b: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;

    const len_a = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &a);
    const len_b = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &b);
    try std.testing.expectEqual(len_a, len_b);
    try std.testing.expectEqualSlices(u8, a[0..len_a], b[0..len_b]);
}

test "oc native RGBA candidate matches generated svg raster for nested and plain templates at 55 and 200 percent" {
    var svg_buf: [32 * 1024]u8 = undefined;

    try runScaledBitmapParity(.oc, findImageIndexByName(.oc, "aco,0,x7.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.oc, findImageIndexByName(.oc, "aco,0,x7.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.oc, findImageIndexByName(.oc, "wt,0,I.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.oc, findImageIndexByName(.oc, "wt,0,I.svg"), 200, 100, &svg_buf);
}

test "eadgbe candidate render is deterministic at 55 and 200 percent" {
    const kind_index = findKindIndex(.eadgbe);
    const image_index = findImageIndexByName(.eadgbe, "-1,3,2,0,1,0.svg");
    var a: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;
    var b: [MAX_TEST_TARGET_WIDTH * MAX_TEST_TARGET_HEIGHT * 4]u8 = undefined;

    const len_a = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &a);
    const len_b = try renderCandidateRgbaScaled(kind_index, image_index, 200, 100, &b);
    try std.testing.expectEqual(len_a, len_b);
    try std.testing.expectEqualSlices(u8, a[0..len_a], b[0..len_b]);
}

test "eadgbe native RGBA candidate matches parsed reference bitmap at 55 and 200 percent" {
    var svg_buf: [32 * 1024]u8 = undefined;

    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "-1,3,2,0,1,0.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "-1,3,2,0,1,0.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "9,9,9,11,9,9.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "9,9,9,11,9,9.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "9,9,8,7,7,-1.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.eadgbe, findImageIndexByName(.eadgbe, "9,9,8,7,7,-1.svg"), 200, 100, &svg_buf);
}

test "wide chord native RGBA candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [CHORD_COMPAT_SVG_BUFFER_LIMIT]u8 = undefined;
    try runScaledBitmapParity(.wide_chord, findImageIndexByName(.wide_chord, "C_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.wide_chord, findImageIndexByName(.wide_chord, "C_3.svg"), 200, 100, &svg_buf);
}

test "chord clipped native RGBA candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [CHORD_COMPAT_SVG_BUFFER_LIMIT]u8 = undefined;
    try runScaledBitmapParity(.chord_clipped, findImageIndexByName(.chord_clipped, "C_3,E_3,G_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.chord_clipped, findImageIndexByName(.chord_clipped, "C_3,E_3,G_3.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.chord_clipped, findImageIndexByName(.chord_clipped, "C_3,E_3,G_3,B_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.chord_clipped, findImageIndexByName(.chord_clipped, "C_3,E_3,G_3,B_3.svg"), 200, 100, &svg_buf);
}

test "grand chord native RGBA candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [CHORD_COMPAT_SVG_BUFFER_LIMIT]u8 = undefined;
    try runScaledBitmapParity(.grand_chord, findImageIndexByName(.grand_chord, "C_3,Gb_3,Bb_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.grand_chord, findImageIndexByName(.grand_chord, "C_3,Gb_3,Bb_3.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.grand_chord, findImageIndexByName(.grand_chord, "C_2,G_2,Bb_2,Db_3,Gb_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.grand_chord, findImageIndexByName(.grand_chord, "C_2,G_2,Bb_2,Db_3,Gb_3.svg"), 200, 100, &svg_buf);
}

test "chord native RGBA candidate matches generated svg raster at 55 and 200 percent" {
    var svg_buf: [CHORD_COMPAT_SVG_BUFFER_LIMIT]u8 = undefined;
    try runScaledBitmapParity(.chord, findImageIndexByName(.chord, "D_3,F_3,Gs_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.chord, findImageIndexByName(.chord, "D_3,F_3,Gs_3.svg"), 200, 100, &svg_buf);
    try runScaledBitmapParity(.chord, findImageIndexByName(.chord, "E_2,Gs_2,Bs_2,Ds_3,Fs_3.svg"), 55, 100, &svg_buf);
    try runScaledBitmapParity(.chord, findImageIndexByName(.chord, "E_2,Gs_2,Bs_2,Ds_3,Fs_3.svg"), 200, 100, &svg_buf);
}
