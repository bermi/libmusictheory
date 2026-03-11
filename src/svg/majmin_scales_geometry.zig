const std = @import("std");

pub const SCALE_GEOMETRY_PATH_COUNT: usize = 76;
pub const SCALE_GEOMETRY_CLUSTER_COUNT: usize = 19;
pub const SCALE_GEOMETRY_SHAPES_PER_CLUSTER: usize = 4;
pub const SCALE_GEOMETRY_STEP_X: f64 = 27.2;
pub const SCALE_GEOMETRY_STEP_Y: f64 = 47.11178196587346;

const XSeed = enum(u8) {
    x_217_8,
    x_272_2,
    x_neg_54_2_long,
    x_27_4_long,
    x_245,
    x_408_2,
    x_neg_81_4_long,
    x_0_20000000000000284,
    x_81_8,
    x_299_4,
    x_neg_108_6,
    x_neg_27,
    x_109,
    x_neg_135_8_long,
};

const YSeed = enum(u8) {
    y_neg_126_33534589762039,
    y_neg_79_22356393174692,
    y_neg_32_11178196587346,
    y_15,
    y_344_78247376111426,
    y_439_0060376928611,
};

const ClusterContext = struct {
    x_seed: XSeed,
    x_n: i8,
    y_seed: YSeed,
    y_n: i8,
};

const SCALE_GEOMETRY_CONTEXTS = [_]ClusterContext{
    .{ .x_seed = .x_217_8, .x_n = 0, .y_seed = .y_neg_126_33534589762039, .y_n = 0 },
    .{ .x_seed = .x_272_2, .x_n = 1, .y_seed = .y_neg_126_33534589762039, .y_n = 1 },
    .{ .x_seed = .x_neg_54_2_long, .x_n = 0, .y_seed = .y_neg_126_33534589762039, .y_n = 0 },
    .{ .x_seed = .x_27_4_long, .x_n = 0, .y_seed = .y_neg_126_33534589762039, .y_n = 1 },
    .{ .x_seed = .x_245, .x_n = -5, .y_seed = .y_neg_126_33534589762039, .y_n = 2 },
    .{ .x_seed = .x_408_2, .x_n = -8, .y_seed = .y_neg_126_33534589762039, .y_n = 3 },
    .{ .x_seed = .x_272_2, .x_n = 0, .y_seed = .y_neg_79_22356393174692, .y_n = 3 },
    .{ .x_seed = .x_neg_81_4_long, .x_n = 0, .y_seed = .y_neg_126_33534589762039, .y_n = 3 },
    .{ .x_seed = .x_0_20000000000000284, .x_n = 0, .y_seed = .y_neg_79_22356393174692, .y_n = 3 },
    .{ .x_seed = .x_81_8, .x_n = 0, .y_seed = .y_neg_32_11178196587346, .y_n = 3 },
    .{ .x_seed = .x_299_4, .x_n = -5, .y_seed = .y_15, .y_n = 3 },
    .{ .x_seed = .x_217_8, .x_n = 1, .y_seed = .y_15, .y_n = 4 },
    .{ .x_seed = .x_neg_108_6, .x_n = 0, .y_seed = .y_15, .y_n = 3 },
    .{ .x_seed = .x_neg_27, .x_n = 0, .y_seed = .y_15, .y_n = 4 },
    .{ .x_seed = .x_109, .x_n = -2, .y_seed = .y_15, .y_n = 5 },
    .{ .x_seed = .x_272_2, .x_n = -5, .y_seed = .y_344_78247376111426, .y_n = -1 },
    .{ .x_seed = .x_299_4, .x_n = -3, .y_seed = .y_15, .y_n = 7 },
    .{ .x_seed = .x_neg_135_8_long, .x_n = 0, .y_seed = .y_439_0060376928611, .y_n = -3 },
    .{ .x_seed = .x_neg_54_2_long, .x_n = 0, .y_seed = .y_15, .y_n = 7 },
};

comptime {
    if (SCALE_GEOMETRY_CONTEXTS.len != SCALE_GEOMETRY_CLUSTER_COUNT) {
        @compileError("SCALE_GEOMETRY_CONTEXTS must match SCALE_GEOMETRY_CLUSTER_COUNT");
    }
}

fn xSeedValue(seed: XSeed) f64 {
    return switch (seed) {
        .x_217_8 => 217.8,
        .x_272_2 => 272.2,
        .x_neg_54_2_long => -54.19999999999999,
        .x_27_4_long => 27.400000000000006,
        .x_245 => 245.0,
        .x_408_2 => 408.2,
        .x_neg_81_4_long => -81.39999999999998,
        .x_0_20000000000000284 => 0.20000000000000284,
        .x_81_8 => 81.8,
        .x_299_4 => 299.4,
        .x_neg_108_6 => -108.6,
        .x_neg_27 => -27.0,
        .x_109 => 109.0,
        .x_neg_135_8_long => -135.79999999999998,
    };
}

fn ySeedValue(seed: YSeed) f64 {
    return switch (seed) {
        .y_neg_126_33534589762039 => -126.33534589762039,
        .y_neg_79_22356393174692 => -79.22356393174692,
        .y_neg_32_11178196587346 => -32.11178196587346,
        .y_15 => 15.0,
        .y_344_78247376111426 => 344.78247376111426,
        .y_439_0060376928611 => 439.0060376928611,
    };
}

fn coordFromSeed(seed_value: f64, start_n: i8, offset: i8, step: f64) f64 {
    const n: i16 = @as(i16, start_n) + @as(i16, offset);
    return seed_value + @as(f64, @floatFromInt(n)) * step;
}

fn xCoordFor(context: ClusterContext, offset: i8) f64 {
    return coordFromSeed(xSeedValue(context.x_seed), context.x_n, offset, SCALE_GEOMETRY_STEP_X);
}

fn yCoordFor(context: ClusterContext, offset: i8) f64 {
    return coordFromSeed(ySeedValue(context.y_seed), context.y_n, offset, SCALE_GEOMETRY_STEP_Y);
}

pub fn writePathForSlot(writer: anytype, slot: usize) !void {
    if (slot >= SCALE_GEOMETRY_PATH_COUNT) return error.InvalidSlot;
    const cluster_idx = slot / SCALE_GEOMETRY_SHAPES_PER_CLUSTER;
    const shape_idx = slot % SCALE_GEOMETRY_SHAPES_PER_CLUSTER;
    const context = SCALE_GEOMETRY_CONTEXTS[cluster_idx];

    const xm = xCoordFor(context, 0);
    const x0 = xCoordFor(context, 1);
    const cx = xCoordFor(context, 2);
    const x1 = xCoordFor(context, 3);
    const x2 = xCoordFor(context, 4);
    const x3 = xCoordFor(context, 5);

    const y2 = yCoordFor(context, 0);
    const y0 = yCoordFor(context, 1);
    const cy = yCoordFor(context, 2);
    const y1 = yCoordFor(context, 3);

    switch (shape_idx) {
        0 => try writer.print("M{d},{d} L{d},{d} L{d},{d} L{d},{d} L{d},{d} L{d},{d}  z", .{ x0, y0, x1, y0, x2, cy, x1, y1, x0, y1, xm, cy }),
        1 => try writer.print("M{d},{d} L{d},{d} L{d},{d} L{d},{d}  z", .{ x1, y0, x2, y2, x3, y0, x2, cy }),
        2 => try writer.print("M{d},{d} L{d},{d} L{d},{d}  z", .{ x0, y0, x1, y0, cx, y2 }),
        3 => try writer.print("M{d},{d} L{d},{d} L{d},{d}  z", .{ x1, y0, cx, y2, x2, y2 }),
        else => unreachable,
    }
}

pub fn pathForSlot(slot: usize, buf: []u8) ?[]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    writePathForSlot(w, slot) catch return null;
    return buf[0..stream.pos];
}
