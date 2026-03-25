const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const cluster = @import("../cluster.zig");
const set_class = @import("../set_class.zig");
const forte = @import("../forte.zig");
const svg_quality = @import("quality.zig");
const text_misc = @import("text_misc.zig");

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
        \\.optc-bg{fill:white}
        \\.optc-ring{fill:none;stroke:black;stroke-width:2}
        \\.optc-node{stroke-width:3}
        \\
    ) catch unreachable;
    w.writeAll("<rect class=\"optc-bg\" x=\"-7\" y=\"-7\" width=\"114\" height=\"114\" fill=\"white\" />\n") catch unreachable;
    w.writeAll("<circle class=\"optc-ring\" cx=\"50.00\" cy=\"50.00\" r=\"20\" fill=\"none\" stroke=\"black\" stroke-width=\"2\" />\n") catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const p = circlePosition(@as(pitch.PitchClass, @intCast(pc)), 50.0, 42.0);
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const present = (set & bit) != 0;
        const in_cluster = (cluster_info.cluster_mask & bit) != 0;

        const stroke = OPC_STROKE_COLORS[pc];
        const fill = if (!present)
            "white"
        else if (in_cluster)
            OPC_STROKE_COLORS[pc]
        else
            OPC_FILL_COLORS[pc];

        w.print(
            "<circle class=\"optc-node\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"10\" stroke=\"{s}\" stroke-width=\"3\" fill=\"{s}\" />\n",
            .{ p.x, p.y, stroke, fill },
        ) catch unreachable;
    }

    var label_path_buf: [8 * 1024]u8 = undefined;
    const label_path = text_misc.horizontalPathData(prime_label, &label_path_buf);
    if (label_path) |horizontal| {
        const scale = @min(0.52, 22.0 / @max(horizontal.width, 1.0));
        const label_x = 50.0 - @as(f64, horizontal.width) * scale / 2.0;
        const label_y = 46.4;
        w.print(
            "<g transform=\"translate({d:.3},{d:.3}) scale({d:.3})\"><path fill=\"#111\" d=\"{s}\" /></g>\n",
            .{ label_x, label_y, scale, horizontal.d },
        ) catch unreachable;
    } else {
        text_misc.writeBlockText(w, prime_label, 50.0, 43.0, 1.7, 0.45, "#111", .center, "optc-fallback-label") catch unreachable;
    }
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}

pub fn renderOpticKGroup(set: pcs.PitchClassSet, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const safe_set = set & 0x0fff;
    const left_set = set_class.fortePrime(safe_set);
    const right_set = set_class.fortePrime(pcs.complement(safe_set));
    const left_forte = forte.lookup(left_set) orelse forte.ForteNumber{
        .cardinality = pcs.cardinality(left_set),
        .ordinal = 0,
        .is_z = false,
    };
    const right_forte = forte.lookup(right_set) orelse forte.ForteNumber{
        .cardinality = pcs.cardinality(right_set),
        .ordinal = 0,
        .is_z = false,
    };

    var left_set_label_buf: [12]u8 = undefined;
    var right_set_label_buf: [12]u8 = undefined;
    var left_forte_label_buf: [16]u8 = undefined;
    var right_forte_label_buf: [16]u8 = undefined;

    const left_set_label = pcs.format(left_set, &left_set_label_buf);
    const right_set_label = pcs.format(right_set, &right_set_label_buf);
    const left_forte_label = forteLabel(left_forte, &left_forte_label_buf);
    const right_forte_label = forteLabel(right_forte, &right_forte_label_buf);
    const group_state = if (left_set == right_set) "self-complementary" else "complement-paired";

    svg_quality.writeSvgPrelude(w, "280", "140", "0 0 280 140",
        \\.optic-k-bg{fill:white}
        \\.optic-k-card{fill:rgba(255,255,255,0.94);stroke:rgba(17,24,39,0.08);stroke-width:1.2}
        \\.optic-k-link{fill:none;stroke:#8d7f74;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
        \\.optic-k-ring{fill:none;stroke:#111;stroke-width:1.75}
        \\.optic-k-node{stroke-width:2.8}
        \\
    ) catch unreachable;
    w.writeAll("<rect class=\"optic-k-bg\" x=\"0\" y=\"0\" width=\"280\" height=\"140\" fill=\"white\" />\n") catch unreachable;
    w.writeAll("<rect class=\"optic-k-card\" x=\"8\" y=\"8\" width=\"120\" height=\"124\" rx=\"18\" fill=\"rgba(255,255,255,0.94)\" stroke=\"rgba(17,24,39,0.08)\" stroke-width=\"1.2\" />\n") catch unreachable;
    w.writeAll("<rect class=\"optic-k-card\" x=\"152\" y=\"8\" width=\"120\" height=\"124\" rx=\"18\" fill=\"rgba(255,255,255,0.94)\" stroke=\"rgba(17,24,39,0.08)\" stroke-width=\"1.2\" />\n") catch unreachable;
    w.writeAll("<path class=\"optic-k-link\" d=\"M118 57 C138 46, 142 46, 162 57 M118 83 C138 94, 142 94, 162 83\" fill=\"none\" stroke=\"#8d7f74\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />\n") catch unreachable;
    text_misc.writeBlockText(w, "OPTIC/K", 140.0, 12.0, 1.55, 0.55, "#24323d", .center, "optic-k-title") catch unreachable;
    text_misc.writeBlockText(w, upperOpticKState(group_state), 140.0, 64.0, 0.95, 0.45, "#6b5f55", .center, "optic-k-chip") catch unreachable;

    writeOpticKWheel(w, left_set, 68.0, 70.0, 28.0, 7.0, 13.0);
    writeOpticKWheel(w, right_set, 212.0, 70.0, 28.0, 7.0, 13.0);

    text_misc.writeBlockText(w, left_forte_label, 68.0, 100.0, 1.25, 0.42, "#111", .center, "optic-k-label") catch unreachable;
    var left_set_display_buf: [18]u8 = undefined;
    const left_set_display = std.fmt.bufPrint(&left_set_display_buf, "[{s}]", .{left_set_label}) catch unreachable;
    text_misc.writeBlockText(w, left_set_display, 68.0, 114.0, 0.95, 0.36, "#475569", .center, "optic-k-set") catch unreachable;
    text_misc.writeBlockText(w, right_forte_label, 212.0, 100.0, 1.25, 0.42, "#111", .center, "optic-k-label") catch unreachable;
    var right_set_display_buf: [18]u8 = undefined;
    const right_set_display = std.fmt.bufPrint(&right_set_display_buf, "[{s}]", .{right_set_label}) catch unreachable;
    text_misc.writeBlockText(w, right_set_display, 212.0, 114.0, 0.95, 0.36, "#475569", .center, "optic-k-set") catch unreachable;
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

fn writeOpticKWheel(w: anytype, set: pcs.PitchClassSet, center_x: f64, center_y: f64, radius: f64, node_radius: f64, ring_radius: f64) void {
    const cluster_info = cluster.getClusters(set);
    w.print(
        "<circle class=\"optic-k-ring\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"{d:.2}\" fill=\"none\" stroke=\"#111\" stroke-width=\"1.75\" />\n",
        .{ center_x, center_y, ring_radius },
    ) catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const p = circlePositionScaled(@as(pitch.PitchClass, @intCast(pc)), center_x, center_y, radius);
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const present = (set & bit) != 0;
        const in_cluster = (cluster_info.cluster_mask & bit) != 0;
        const stroke = OPC_STROKE_COLORS[pc];
        const fill = if (!present)
            "white"
        else if (in_cluster)
            OPC_STROKE_COLORS[pc]
        else
            OPC_FILL_COLORS[pc];

        w.print(
            "<circle class=\"optic-k-node\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"{d:.2}\" stroke=\"{s}\" stroke-width=\"2.8\" fill=\"{s}\" />\n",
            .{ p.x, p.y, node_radius, stroke, fill },
        ) catch unreachable;
    }
}

fn circlePositionScaled(pc: pitch.PitchClass, center_x: f64, center_y: f64, radius: f64) Point {
    const angle = TAU * (@as(f64, @floatFromInt(pc)) / 12.0);
    return .{
        .x = center_x + radius * std.math.sin(angle),
        .y = center_y - radius * std.math.cos(angle),
    };
}

fn forteLabel(number: forte.ForteNumber, out: *[16]u8) []u8 {
    if (number.ordinal == 0) {
        return std.fmt.bufPrint(out, "{d}?", .{number.cardinality}) catch unreachable;
    }
    if (number.is_z) {
        return std.fmt.bufPrint(out, "{d}-Z{d}", .{ number.cardinality, number.ordinal }) catch unreachable;
    }
    return std.fmt.bufPrint(out, "{d}-{d}", .{ number.cardinality, number.ordinal }) catch unreachable;
}

fn upperOpticKState(group_state: []const u8) []const u8 {
    if (std.mem.eql(u8, group_state, "self-complementary")) return "SELF-COMPLEMENTARY";
    return "COMPLEMENT-PAIRED";
}
