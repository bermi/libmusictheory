const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const voice_leading = @import("../voice_leading.zig");

pub const NODE_COUNT: usize = 40;
pub const MAX_EDGES: usize = 512;
const ROOT_NAMES = [_][]const u8{ "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B" };

pub const TriadQuality = enum {
    major,
    minor,
    diminished,
    augmented,
};

pub const Node = struct {
    root: pitch.PitchClass,
    quality: TriadQuality,
    set: pcs.PitchClassSet,
    x: f32,
    y: f32,
};

pub const Edge = struct {
    from_idx: u8,
    to_idx: u8,
};

pub fn enumerateTriadNodes(out: *[NODE_COUNT]Node) []Node {
    var idx: usize = 0;

    var root: u4 = 0;
    while (root < 12) : (root += 1) {
        out[idx] = makeNode(.major, @as(pitch.PitchClass, @intCast(root)));
        idx += 1;
    }

    root = 0;
    while (root < 12) : (root += 1) {
        out[idx] = makeNode(.minor, @as(pitch.PitchClass, @intCast(root)));
        idx += 1;
    }

    root = 0;
    while (root < 12) : (root += 1) {
        out[idx] = makeNode(.diminished, @as(pitch.PitchClass, @intCast(root)));
        idx += 1;
    }

    root = 0;
    while (root < 4) : (root += 1) {
        out[idx] = makeNode(.augmented, @as(pitch.PitchClass, @intCast(root)));
        idx += 1;
    }

    std.debug.assert(idx == NODE_COUNT);
    return out[0..idx];
}

pub fn buildTriadEdges(nodes: []const Node, out: *[MAX_EDGES]Edge) []Edge {
    var edge_count: usize = 0;

    var i: usize = 0;
    while (i < nodes.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < nodes.len) : (j += 1) {
            const dist = voice_leading.vlDistance(nodes[i].set, nodes[j].set);
            if (dist != 1) continue;

            std.debug.assert(edge_count < out.len);
            out[edge_count] = .{
                .from_idx = @as(u8, @intCast(i)),
                .to_idx = @as(u8, @intCast(j)),
            };
            edge_count += 1;
        }
    }

    return out[0..edge_count];
}

pub fn renderTriadOrbifold(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    var nodes_buf: [NODE_COUNT]Node = undefined;
    const nodes = enumerateTriadNodes(&nodes_buf);

    var edges_buf: [MAX_EDGES]Edge = undefined;
    const edges = buildTriadEdges(nodes, &edges_buf);

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 540 540\" width=\"100%\" height=\"100%\">\n") catch unreachable;
    w.writeAll("<ellipse cx=\"270\" cy=\"270\" rx=\"156.25\" ry=\"247.5\" style=\"fill:none;stroke:#bbb;stroke-width:2px;\" />\n") catch unreachable;

    for (edges) |edge| {
        const from = nodes[edge.from_idx];
        const to = nodes[edge.to_idx];
        w.print("<line class=\"orbifold-edge\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#bbb\" stroke-width=\"1\" />\n", .{ from.x, from.y, to.x, to.y }) catch unreachable;
    }

    for (nodes) |node| {
        const style = nodeStyle(node.quality);
        w.print("<circle class=\"orbifold-node\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"8\" fill=\"{s}\" stroke=\"{s}\" stroke-width=\"1\" />\n", .{ node.x, node.y, style.fill, style.stroke }) catch unreachable;
        w.print("<text x=\"{d:.2}\" y=\"{d:.2}\" text-anchor=\"middle\" font-size=\"6\" fill=\"white\">{s}{s}</text>\n", .{ node.x, node.y + 2.2, rootName(node.root), qualitySuffix(node.quality) }) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn makeNode(quality: TriadQuality, root: pitch.PitchClass) Node {
    const center_x: f32 = 270.0;
    const center_y: f32 = 270.0;

    var angle: f32 = 0.0;
    var radius: f32 = 0.0;

    switch (quality) {
        .major => {
            angle = std.math.tau * (@as(f32, @floatFromInt(root)) / 12.0);
            radius = 155.0;
        },
        .minor => {
            angle = std.math.tau * (@as(f32, @floatFromInt(root)) / 12.0) + @as(f32, @floatCast(std.math.pi / 12.0));
            radius = 195.0;
        },
        .diminished => {
            angle = std.math.tau * (@as(f32, @floatFromInt(root)) / 12.0) + @as(f32, @floatCast(std.math.pi / 24.0));
            radius = 235.0;
        },
        .augmented => {
            angle = std.math.tau * (@as(f32, @floatFromInt(root)) / 4.0);
            radius = 55.0;
        },
    }

    const x = center_x + radius * @as(f32, @floatCast(std.math.cos(angle)));
    const y = center_y + radius * @as(f32, @floatCast(std.math.sin(angle)));

    return .{
        .root = root,
        .quality = quality,
        .set = triadSet(quality, root),
        .x = x,
        .y = y,
    };
}

fn triadSet(quality: TriadQuality, root: pitch.PitchClass) pcs.PitchClassSet {
    const base = switch (quality) {
        .major => pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 }),
        .minor => pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7 }),
        .diminished => pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 }),
        .augmented => pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 }),
    };
    return pcs.transpose(base, root);
}

fn nodeStyle(quality: TriadQuality) struct { fill: []const u8, stroke: []const u8 } {
    return switch (quality) {
        .major => .{ .fill = "#02fe02", .stroke = "#000" },
        .minor => .{ .fill = "#0b007e", .stroke = "#fff" },
        .diminished => .{ .fill = "#004700", .stroke = "#fff" },
        .augmented => .{ .fill = "#a16", .stroke = "#fff" },
    };
}

fn rootName(pc: pitch.PitchClass) []const u8 {
    return ROOT_NAMES[pc];
}

fn qualitySuffix(quality: TriadQuality) []const u8 {
    return switch (quality) {
        .major => "",
        .minor => "m",
        .diminished => "o",
        .augmented => "+",
    };
}
