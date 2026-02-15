const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const cluster = @import("../cluster.zig");
const set_class = @import("../set_class.zig");

const TAU = std.math.pi * 2.0;

const OPC_STROKE_COLORS = [_][]const u8{
    "#00c", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#161", "#094", "#0bb", "#16b", "#28f",
};

const OPC_FILL_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#1e0", "#094", "#0bb", "#16b", "#28f",
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

    w.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 100 100\">\n") catch unreachable;
    w.writeAll("  <rect x=\"0\" y=\"0\" width=\"100\" height=\"100\" style=\"fill: white\"/>\n") catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const p = circlePosition(@as(pitch.PitchClass, @intCast(pc)), 50.0, 42.0);
        const present = (set & (@as(pcs.PitchClassSet, 1) << pc)) != 0;
        const fill = if (present) OPC_FILL_COLORS[pc] else "white";

        w.print(
            "  <circle cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"9.5\" stroke=\"{s}\" stroke-width=\"3\" fill=\"{s}\" />\n",
            .{ p.x, p.y, OPC_STROKE_COLORS[pc], fill },
        ) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderOPTC(set: pcs.PitchClassSet, prime_label: []const u8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const cluster_info = cluster.getClusters(set);

    w.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" width=\"70\" height=\"70\" viewBox=\"-7 -7 114 114\">\n") catch unreachable;
    w.writeAll("<circle cx=\"50.00\" cy=\"50.00\" r=\"20\" stroke=\"black\" stroke-width=\"2\" fill=\"transparent\" />\n") catch unreachable;

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
            "<circle cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"10\" stroke=\"black\" stroke-width=\"3\" fill=\"{s}\" />\n",
            .{ p.x, p.y, fill },
        ) catch unreachable;
    }

    w.print("<text x=\"50\" y=\"55\" text-anchor=\"middle\" font-size=\"16\" fill=\"black\">{s}</text>\n", .{prime_label}) catch unreachable;
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
