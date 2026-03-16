const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const cluster = @import("../cluster.zig");
const set_class = @import("../set_class.zig");
const svg_quality = @import("quality.zig");

const TAU = std.math.pi * 2.0;

const OPC_STROKE_COLORS = [_][]const u8{
    "#00c", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#161", "#094", "#0bb", "#16b", "#28f",
};

const OPC_FILL_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#ff0", "#1e0", "#094", "#0bb", "#16b", "#28f",
};

pub const Point = struct {
    x: f64,
    y: f64,
};

pub fn circlePosition(pc: pitch.PitchClass, center: f64, radius: f64) Point {
    const angle = TAU * (@as(f64, @floatFromInt(pc)) / 12.0);
    return .{
        .x = center + radius * std.math.sin(angle),
        .y = center - radius * std.math.cos(angle),
    };
}

pub fn renderOPC(set: pcs.PitchClassSet, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    svg_quality.writeSvgPrelude(w, "100", "100", "0 0 100 100",
        \\.opc-bg{fill:white}
        \\.opc-node{vector-effect:non-scaling-stroke}
        \\
    ) catch unreachable;
    w.writeAll("<rect class=\"opc-bg\" x=\"0\" y=\"0\" width=\"100\" height=\"100\" />\n") catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const present = (set & (@as(pcs.PitchClassSet, 1) << pc)) != 0;
        const fill = if (present) OPC_FILL_COLORS[pc] else "white";

        w.print(
            "<circle class=\"opc-node\" transform=\"scale(0.877),translate(7,7)\" cx=\"{d:.12}\" cy=\"{d:.12}\" r=\"9.5\" stroke=\"{s}\" stroke-width=\"3\" fill=\"{s}\" />\n",
            .{ circlePosition(@intCast(pc), 50.0, 42.0).x, circlePosition(@intCast(pc), 50.0, 42.0).y, OPC_STROKE_COLORS[pc], fill },
        ) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderOPTC(set: pcs.PitchClassSet, prime_label: []const u8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const cluster_info = cluster.getClusters(set);

    svg_quality.writeSvgPrelude(w, "70", "70", "-7 -7 114 114",
        \\.optc-ring,.optc-node{vector-effect:non-scaling-stroke}
        \\.optc-ring{fill:none;stroke:black;stroke-width:2}
        \\.optc-node{stroke:black;stroke-width:3}
        \\.optc-center{font-size:16px;fill:black}
        \\
    ) catch unreachable;
    w.writeAll("<circle class=\"optc-ring\" cx=\"50.00\" cy=\"50.00\" r=\"20\" />\n") catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const p = circlePosition(@as(pitch.PitchClass, @intCast(pc)), 50.0, 42.0);
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const present = (set & bit) != 0;
        const in_cluster = (cluster_info.cluster_mask & bit) != 0;

        const fill = if (!present)
            "transparent"
        else if (in_cluster)
            "gray"
        else
            "black";

        w.print(
            "<circle class=\"optc-node\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"10\" fill=\"{s}\" />\n",
            .{ p.x, p.y, fill },
        ) catch unreachable;
    }

    w.print("<text class=\"label-serif inverse-outline optc-center\" x=\"50\" y=\"55\" text-anchor=\"middle\">{s}</text>\n", .{prime_label}) catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}

pub fn generateAllOPTCFiles(dir: std.fs.Dir) !void {
    var svg_buf: [8192]u8 = undefined;
    var label_buf: [12]u8 = undefined;
    var file_name_buf: [20]u8 = undefined;

    for (set_class.SET_CLASSES) |sc| {
        const label = pcs.format(sc.pcs, &label_buf);
        const svg = renderOPTC(sc.pcs, label, &svg_buf);

        const file_name = std.fmt.bufPrint(&file_name_buf, "{s}.svg", .{label}) catch continue;
        try dir.writeFile(.{ .sub_path = file_name, .data = svg });
    }
}
