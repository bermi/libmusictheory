const std = @import("std");
const testing = std.testing;

const tessellation = @import("../svg/tessellation.zig");

fn countSubstring(haystack: []const u8, needle: []const u8) usize {
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, haystack, pos, needle)) |idx| {
        count += 1;
        pos = idx + needle.len;
    }
    return count;
}

test "tessellation adjacency neighbor counts by scale type" {
    var tile_buf: [tessellation.TILE_COUNT]tessellation.Tile = undefined;
    const tiles = tessellation.enumerateTiles(&tile_buf);

    var edge_buf: [tessellation.MAX_EDGES]tessellation.Edge = undefined;
    const edges = tessellation.buildAdjacency(tiles, &edge_buf);

    for (tiles, 0..) |tile, idx| {
        const neighbors = tessellation.neighborCount(idx, edges);
        switch (tile.scale_type) {
            .diatonic => try testing.expectEqual(@as(u8, 6), neighbors),
            .acoustic => try testing.expectEqual(@as(u8, 4), neighbors),
            .harmonic_minor => try testing.expectEqual(@as(u8, 3), neighbors),
            .harmonic_major => try testing.expectEqual(@as(u8, 3), neighbors),
        }
    }
}

test "tessellation shape assignment matches scale type" {
    var tile_buf: [tessellation.TILE_COUNT]tessellation.Tile = undefined;
    const tiles = tessellation.enumerateTiles(&tile_buf);

    for (tiles) |tile| {
        switch (tile.scale_type) {
            .diatonic => try testing.expectEqual(tessellation.TileShape.hexagon, tile.shape),
            .acoustic => try testing.expectEqual(tessellation.TileShape.square, tile.shape),
            .harmonic_minor => try testing.expectEqual(tessellation.TileShape.triangle, tile.shape),
            .harmonic_major => try testing.expectEqual(tessellation.TileShape.diamond, tile.shape),
        }
    }
}

test "tessellation svg validity and dimensions" {
    var buf: [65536]u8 = undefined;
    const svg = tessellation.renderScaleTessellation(&buf);

    try testing.expect(std.mem.startsWith(u8, svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg, "width=\"300\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "height=\"360\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "</svg>") != null);

    try testing.expect(countSubstring(svg, "class=\"tile diatonic hexagon\"") == 12);
    try testing.expect(countSubstring(svg, "class=\"tile acoustic square\"") == 12);
    try testing.expect(countSubstring(svg, "class=\"tile harmonic_minor triangle\"") == 12);
    try testing.expect(countSubstring(svg, "class=\"tile harmonic_major diamond\"") == 12);

    try testing.expect(std.mem.indexOf(u8, svg, "class=\"vl-edge\"") != null);
}
