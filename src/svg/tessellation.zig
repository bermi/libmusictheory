const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");

pub const CANVAS_WIDTH: u16 = 300;
pub const CANVAS_HEIGHT: u16 = 360;

pub const TILE_COUNT: usize = 48;
pub const MAX_EDGES: usize = 128;

const DIATONIC: pcs.PitchClassSet = 0b101010110101;
const ACOUSTIC: pcs.PitchClassSet = 0b011011010101;
const HARMONIC_MINOR: pcs.PitchClassSet = 0b100110101101;
const HARMONIC_MAJOR: pcs.PitchClassSet = 0b100110110101;

const PC_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#1e0", "#094", "#0bb", "#16b", "#28f",
};

const PC_NAMES = [_][]const u8{
    "C",  "C#", "D",  "Eb", "E",  "F",
    "F#", "G",  "Ab", "A",  "Bb", "B",
};

pub const TileType = enum {
    diatonic,
    acoustic,
    harmonic_minor,
    harmonic_major,
};

pub const TileShape = enum {
    hexagon,
    square,
    triangle,
    diamond,
};

pub const Tile = struct {
    scale_type: TileType,
    root: pitch.PitchClass,
    pcs: pcs.PitchClassSet,
    shape: TileShape,
    cx: f32,
    cy: f32,
};

pub const Edge = struct {
    from_idx: u8,
    to_idx: u8,
};

pub fn enumerateTiles(out: *[TILE_COUNT]Tile) []Tile {
    var idx: usize = 0;

    inline for ([_]TileType{ .diatonic, .acoustic, .harmonic_minor, .harmonic_major }) |scale_type| {
        var root: u4 = 0;
        while (root < 12) : (root += 1) {
            const layout = tileLayout(scale_type, @as(pitch.PitchClass, @intCast(root)));
            out[idx] = .{
                .scale_type = scale_type,
                .root = @as(pitch.PitchClass, @intCast(root)),
                .pcs = pcs.transpose(baseSet(scale_type), root),
                .shape = tileShape(scale_type),
                .cx = layout.x,
                .cy = layout.y,
            };
            idx += 1;
        }
    }

    std.debug.assert(idx == TILE_COUNT);
    return out[0..idx];
}

pub fn buildAdjacency(tiles: []const Tile, edge_buf: *[MAX_EDGES]Edge) []Edge {
    var edge_count: usize = 0;

    var i: usize = 0;
    while (i < tiles.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < tiles.len) : (j += 1) {
            if (pcs.hammingDistance(tiles[i].pcs, tiles[j].pcs) != 2) continue;
            if (!includeEdge(tiles[i], tiles[j])) continue;

            std.debug.assert(edge_count < edge_buf.len);
            edge_buf[edge_count] = .{
                .from_idx = @as(u8, @intCast(i)),
                .to_idx = @as(u8, @intCast(j)),
            };
            edge_count += 1;
        }
    }

    return edge_buf[0..edge_count];
}

pub fn neighborCount(tile_idx: usize, edges: []const Edge) u8 {
    var count: u8 = 0;
    const idx = @as(u8, @intCast(tile_idx));

    for (edges) |edge| {
        if (edge.from_idx == idx or edge.to_idx == idx) {
            count += 1;
        }
    }

    return count;
}

pub fn renderScaleTessellation(buf: []u8) []u8 {
    var tiles_buf: [TILE_COUNT]Tile = undefined;
    const tiles = enumerateTiles(&tiles_buf);

    var edges_buf: [MAX_EDGES]Edge = undefined;
    const edges = buildAdjacency(tiles, &edges_buf);

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.print(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{d}\" viewBox=\"0 0 {d} {d}\">\n",
        .{ CANVAS_WIDTH, CANVAS_HEIGHT, CANVAS_WIDTH, CANVAS_HEIGHT },
    ) catch unreachable;

    w.print(
        "<rect x=\"0\" y=\"0\" width=\"{d}\" height=\"{d}\" fill=\"white\" />\n",
        .{ CANVAS_WIDTH, CANVAS_HEIGHT },
    ) catch unreachable;

    for (edges) |edge| {
        const from = tiles[edge.from_idx];
        const to = tiles[edge.to_idx];
        w.print(
            "<line class=\"vl-edge\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#222\" stroke-width=\"0.7\" opacity=\"0.5\" />\n",
            .{ from.cx, from.cy, to.cx, to.cy },
        ) catch unreachable;
    }

    for (tiles) |tile| {
        drawTile(w, tile);
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn includeEdge(a: Tile, b: Tile) bool {
    if (isHarmonicType(a.scale_type) and isHarmonicType(b.scale_type) and a.scale_type != b.scale_type) {
        return a.root == b.root;
    }
    return true;
}

fn isHarmonicType(scale_type: TileType) bool {
    return scale_type == .harmonic_minor or scale_type == .harmonic_major;
}

fn baseSet(scale_type: TileType) pcs.PitchClassSet {
    return switch (scale_type) {
        .diatonic => DIATONIC,
        .acoustic => ACOUSTIC,
        .harmonic_minor => HARMONIC_MINOR,
        .harmonic_major => HARMONIC_MAJOR,
    };
}

fn tileShape(scale_type: TileType) TileShape {
    return switch (scale_type) {
        .diatonic => .hexagon,
        .acoustic => .square,
        .harmonic_minor => .triangle,
        .harmonic_major => .diamond,
    };
}

const LayoutPoint = struct {
    x: f32,
    y: f32,
};

fn tileLayout(scale_type: TileType, root: pitch.PitchClass) LayoutPoint {
    const col = @as(f32, @floatFromInt(root % 6));
    const row = @as(f32, @floatFromInt(root / 6));

    return switch (scale_type) {
        .diatonic => .{
            .x = 34.0 + col * 44.0 + row * 22.0,
            .y = 66.0 + row * 52.0,
        },
        .acoustic => .{
            .x = 34.0 + col * 44.0 + row * 22.0,
            .y = 162.0 + row * 52.0,
        },
        .harmonic_minor => .{
            .x = 46.0 + col * 44.0 + row * 22.0,
            .y = 252.0 + row * 48.0,
        },
        .harmonic_major => .{
            .x = 22.0 + col * 44.0 + row * 22.0,
            .y = 306.0 + row * 48.0,
        },
    };
}

fn drawTile(writer: anytype, tile: Tile) void {
    const class_name = switch (tile.scale_type) {
        .diatonic => "diatonic",
        .acoustic => "acoustic",
        .harmonic_minor => "harmonic_minor",
        .harmonic_major => "harmonic_major",
    };

    const shape_name = switch (tile.shape) {
        .hexagon => "hexagon",
        .square => "square",
        .triangle => "triangle",
        .diamond => "diamond",
    };

    const fill = PC_COLORS[tile.root];

    switch (tile.shape) {
        .hexagon => drawPolygon(writer, class_name, shape_name, tile.cx, tile.cy, 14.5, 6, std.math.pi / 6.0, fill),
        .square => drawPolygon(writer, class_name, shape_name, tile.cx, tile.cy, 11.5, 4, std.math.pi / 4.0, fill),
        .triangle => drawPolygon(writer, class_name, shape_name, tile.cx, tile.cy, 12.5, 3, -std.math.pi / 2.0, fill),
        .diamond => drawPolygon(writer, class_name, shape_name, tile.cx, tile.cy, 12.0, 4, 0.0, fill),
    }

    const label = switch (tile.scale_type) {
        .diatonic => "D",
        .acoustic => "A",
        .harmonic_minor => "m",
        .harmonic_major => "M",
    };

    writer.print(
        "<text x=\"{d:.2}\" y=\"{d:.2}\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"8\" fill=\"white\" font-family=\"sans-serif\">{s}{s}</text>\n",
        .{ tile.cx, tile.cy + 0.5, PC_NAMES[tile.root], label },
    ) catch unreachable;
}

fn drawPolygon(writer: anytype, class_name: []const u8, shape_name: []const u8, cx: f32, cy: f32, radius: f32, sides: u8, rotation: f64, fill: []const u8) void {
    writer.print("<polygon class=\"tile {s} {s}\" points=\"", .{ class_name, shape_name }) catch unreachable;

    var i: u8 = 0;
    while (i < sides) : (i += 1) {
        const angle = rotation + (std.math.tau * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(sides)));
        const x = cx + radius * @as(f32, @floatCast(std.math.cos(angle)));
        const y = cy + radius * @as(f32, @floatCast(std.math.sin(angle)));
        writer.print("{d:.2},{d:.2} ", .{ x, y }) catch unreachable;
    }

    writer.print("\" fill=\"{s}\" stroke=\"black\" stroke-width=\"1\" />\n", .{fill}) catch unreachable;
}
