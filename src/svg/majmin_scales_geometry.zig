const std = @import("std");

pub const SCALE_GEOMETRY_PATH_COUNT: usize = 76;
pub const SCALE_GEOMETRY_CLUSTER_COUNT: usize = 19;
pub const SCALE_GEOMETRY_SHAPES_PER_CLUSTER: usize = 4;

const ClusterX = struct { xm: u8, x0: u8, cx: u8, x1: u8, x2: u8, x3: u8 };
const ClusterY = struct { y2: u8, y0: u8, cy: u8, y1: u8 };

const X_TOKENS = [_][]const u8{
    "217.8",
    "245",
    "272.2",
    "299.4",
    "326.6",
    "353.8",
    "326.59999999999997",
    "353.79999999999995",
    "381",
    "408.2",
    "435.4",
    "-54.19999999999999",
    "-26.99999999999999",
    "0.20000000000000995",
    "27.400000000000006",
    "54.60000000000001",
    "81.80000000000001",
    "109",
    "136.2",
    "163.4",
    "190.6",
    "217.79999999999998",
    "-81.39999999999998",
    "-54.199999999999974",
    "-26.99999999999998",
    "0.20000000000001705",
    "27.40000000000002",
    "54.60000000000002",
    "0.20000000000000284",
    "27.400000000000002",
    "54.6",
    "81.8",
    "163.39999999999998",
    "190.59999999999997",
    "244.99999999999997",
    "-108.6",
    "-81.39999999999999",
    "-54.199999999999996",
    "-27",
    "0.1999999999999993",
    "27.4",
    "54.599999999999994",
    "-135.79999999999998",
    "-108.59999999999998",
    "-26.999999999999986",
};

const Y_TOKENS = [_][]const u8{
    "-126.33534589762039",
    "-79.22356393174692",
    "-32.11178196587346",
    "15",
    "62.11178196587346",
    "109.22356393174692",
    "156.33534589762039",
    "203.44712786349385",
    "250.5589098293673",
    "297.67069179524077",
    "344.78247376111426",
    "391.8942557269877",
    "297.6706917952408",
    "439.0060376928612",
    "439.0060376928611",
    "486.1178196587346",
    "297.6706917952407",
    "344.7824737611142",
};

const CLUSTERS_X = [_]ClusterX{
    .{ .xm = 0, .x0 = 1, .cx = 2, .x1 = 3, .x2 = 4, .x3 = 5 },
    .{ .xm = 3, .x0 = 6, .cx = 7, .x1 = 8, .x2 = 9, .x3 = 10 },
    .{ .xm = 11, .x0 = 12, .cx = 13, .x1 = 14, .x2 = 15, .x3 = 16 },
    .{ .xm = 14, .x0 = 15, .cx = 16, .x1 = 17, .x2 = 18, .x3 = 19 },
    .{ .xm = 17, .x0 = 18, .cx = 19, .x1 = 20, .x2 = 0, .x3 = 1 },
    .{ .xm = 20, .x0 = 21, .cx = 1, .x1 = 2, .x2 = 3, .x3 = 4 },
    .{ .xm = 2, .x0 = 3, .cx = 6, .x1 = 7, .x2 = 8, .x3 = 9 },
    .{ .xm = 22, .x0 = 23, .cx = 24, .x1 = 25, .x2 = 26, .x3 = 27 },
    .{ .xm = 28, .x0 = 29, .cx = 30, .x1 = 31, .x2 = 17, .x3 = 18 },
    .{ .xm = 31, .x0 = 17, .cx = 18, .x1 = 32, .x2 = 20, .x3 = 0 },
    .{ .xm = 32, .x0 = 33, .cx = 21, .x1 = 34, .x2 = 2, .x3 = 3 },
    .{ .xm = 1, .x0 = 2, .cx = 3, .x1 = 4, .x2 = 5, .x3 = 8 },
    .{ .xm = 35, .x0 = 36, .cx = 37, .x1 = 38, .x2 = 28, .x3 = 14 },
    .{ .xm = 38, .x0 = 39, .cx = 40, .x1 = 41, .x2 = 31, .x3 = 17 },
    .{ .xm = 30, .x0 = 31, .cx = 17, .x1 = 18, .x2 = 19, .x3 = 20 },
    .{ .xm = 18, .x0 = 32, .cx = 20, .x1 = 21, .x2 = 1, .x3 = 2 },
    .{ .xm = 21, .x0 = 34, .cx = 2, .x1 = 3, .x2 = 6, .x3 = 7 },
    .{ .xm = 42, .x0 = 43, .cx = 22, .x1 = 11, .x2 = 44, .x3 = 25 },
    .{ .xm = 11, .x0 = 12, .cx = 13, .x1 = 14, .x2 = 15, .x3 = 16 },
};

const CLUSTERS_Y = [_]ClusterY{
    .{ .y2 = 0, .y0 = 1, .cy = 2, .y1 = 3 },
    .{ .y2 = 1, .y0 = 2, .cy = 3, .y1 = 4 },
    .{ .y2 = 0, .y0 = 1, .cy = 2, .y1 = 3 },
    .{ .y2 = 1, .y0 = 2, .cy = 3, .y1 = 4 },
    .{ .y2 = 2, .y0 = 3, .cy = 4, .y1 = 5 },
    .{ .y2 = 3, .y0 = 4, .cy = 5, .y1 = 6 },
    .{ .y2 = 4, .y0 = 5, .cy = 6, .y1 = 7 },
    .{ .y2 = 3, .y0 = 4, .cy = 5, .y1 = 6 },
    .{ .y2 = 4, .y0 = 5, .cy = 6, .y1 = 7 },
    .{ .y2 = 5, .y0 = 6, .cy = 7, .y1 = 8 },
    .{ .y2 = 6, .y0 = 7, .cy = 8, .y1 = 9 },
    .{ .y2 = 7, .y0 = 8, .cy = 9, .y1 = 10 },
    .{ .y2 = 6, .y0 = 7, .cy = 8, .y1 = 9 },
    .{ .y2 = 7, .y0 = 8, .cy = 9, .y1 = 10 },
    .{ .y2 = 8, .y0 = 9, .cy = 10, .y1 = 11 },
    .{ .y2 = 12, .y0 = 10, .cy = 11, .y1 = 13 },
    .{ .y2 = 10, .y0 = 11, .cy = 14, .y1 = 15 },
    .{ .y2 = 16, .y0 = 17, .cy = 11, .y1 = 14 },
    .{ .y2 = 10, .y0 = 11, .cy = 14, .y1 = 15 },
};

pub fn writePathForSlot(writer: anytype, slot: usize) !void {
    if (slot >= SCALE_GEOMETRY_PATH_COUNT) return error.InvalidSlot;
    const cluster_idx = slot / SCALE_GEOMETRY_SHAPES_PER_CLUSTER;
    const shape_idx = slot % SCALE_GEOMETRY_SHAPES_PER_CLUSTER;
    const x = CLUSTERS_X[cluster_idx];
    const y = CLUSTERS_Y[cluster_idx];

    const xm = X_TOKENS[@as(usize, x.xm)];
    const x0 = X_TOKENS[@as(usize, x.x0)];
    const cx = X_TOKENS[@as(usize, x.cx)];
    const x1 = X_TOKENS[@as(usize, x.x1)];
    const x2 = X_TOKENS[@as(usize, x.x2)];
    const x3 = X_TOKENS[@as(usize, x.x3)];

    const y2 = Y_TOKENS[@as(usize, y.y2)];
    const y0 = Y_TOKENS[@as(usize, y.y0)];
    const cy = Y_TOKENS[@as(usize, y.cy)];
    const y1 = Y_TOKENS[@as(usize, y.y1)];

    switch (shape_idx) {
        0 => try writer.print("M{s},{s} L{s},{s} L{s},{s} L{s},{s} L{s},{s} L{s},{s}  z", .{ x0, y0, x1, y0, x2, cy, x1, y1, x0, y1, xm, cy }),
        1 => try writer.print("M{s},{s} L{s},{s} L{s},{s} L{s},{s}  z", .{ x1, y0, x2, y2, x3, y0, x2, cy }),
        2 => try writer.print("M{s},{s} L{s},{s} L{s},{s}  z", .{ x0, y0, x1, y0, cx, y2 }),
        3 => try writer.print("M{s},{s} L{s},{s} L{s},{s}  z", .{ x1, y0, cx, y2, x2, y2 }),
        else => unreachable,
    }
}

pub fn pathForSlot(slot: usize, buf: []u8) ?[]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    writePathForSlot(w, slot) catch return null;
    return buf[0..stream.pos];
}
