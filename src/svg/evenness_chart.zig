const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const evenness = @import("../evenness.zig");
const cluster = @import("../cluster.zig");
const svg_quality = @import("quality.zig");

pub const MAX_DOTS: usize = set_class.SET_CLASSES.len;

pub const Dot = struct {
    x: f32,
    y: f32,
    cardinality: u4,
    cluster_free: bool,
    evenness_distance: f32,
};

const Bounds = struct {
    min_x: f32,
    min_y: f32,
    width: f32,
    height: f32,
};

pub fn computeDots(out: *[MAX_DOTS]Dot) []Dot {
    var card_counts: [13]u16 = [_]u16{0} ** 13;
    var max_evenness: [13]f32 = [_]f32{0.0} ** 13;

    for (set_class.SET_CLASSES) |sc| {
        const card = @as(usize, sc.cardinality);
        card_counts[card] += 1;

        const dist = evenness.evennessDistance(sc.pcs);
        if (dist > max_evenness[card]) max_evenness[card] = dist;
    }

    var index_within_card: [13]u16 = [_]u16{0} ** 13;

    for (set_class.SET_CLASSES, 0..) |sc, i| {
        const card = @as(usize, sc.cardinality);
        const in_card_idx = index_within_card[card];
        index_within_card[card] += 1;

        const count = @as(f32, @floatFromInt(card_counts[card]));
        const angle = std.math.tau * (@as(f32, @floatFromInt(in_card_idx)) / count);

        const base_radius = 290.0 + @as(f32, @floatFromInt(card - 3)) * 290.0;
        const dist = evenness.evennessDistance(sc.pcs);
        const normalized = if (max_evenness[card] <= 0.0001) 0.0 else dist / max_evenness[card];
        const radius = base_radius + normalized * 210.0;

        out[i] = .{
            .x = radius * @as(f32, @floatCast(std.math.cos(angle))),
            .y = radius * @as(f32, @floatCast(std.math.sin(angle))),
            .cardinality = sc.cardinality,
            .cluster_free = !cluster.hasCluster(sc.pcs),
            .evenness_distance = dist,
        };
    }

    return out[0..set_class.SET_CLASSES.len];
}

fn chartBounds(dots: []const Dot) Bounds {
    var min_x: f32 = -1453.4442;
    var max_x: f32 = 1453.4442;
    var min_y: f32 = -1453.4442;
    var max_y: f32 = 1453.4442;

    for (dots) |dot| {
        min_x = @min(min_x, dot.x - 14.0);
        max_x = @max(max_x, dot.x + 14.0);
        min_y = @min(min_y, dot.y - 14.0);
        max_y = @max(max_y, dot.y + 14.0);
    }

    const pad_x = @max(24.0, (max_x - min_x) * 0.04);
    const pad_y = @max(24.0, (max_y - min_y) * 0.04);
    return .{
        .min_x = min_x - pad_x,
        .min_y = min_y - pad_y,
        .width = (max_x - min_x) + pad_x * 2.0,
        .height = (max_y - min_y) + pad_y * 2.0,
    };
}

pub fn renderEvennessChart(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    var dots_buf: [MAX_DOTS]Dot = undefined;
    const dots = computeDots(&dots_buf);
    const bounds = chartBounds(dots);
    const target_width: f32 = 500.0;
    const target_height: f32 = 650.0;
    const pad_x: f32 = 34.0;
    const pad_y: f32 = 38.0;
    const scale = @min(
        (target_width - pad_x * 2.0) / bounds.width,
        (target_height - pad_y * 2.0) / bounds.height,
    );
    const center_x = bounds.min_x + bounds.width / 2.0;
    const center_y = bounds.min_y + bounds.height / 2.0;

    svg_quality.writeSvgPrelude(w, "500", "650", "0 0 500 650",
        \\.ring,.dot{vector-effect:non-scaling-stroke}
        \\.ring{fill:none;stroke:#8f949d;stroke-width:2;stroke-linecap:round}
        \\.dot{stroke:white;stroke-width:1.25}
        \\
    ) catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"500\" height=\"650\" fill=\"white\" />\n") catch unreachable;

    var ring: u4 = 1;
    while (ring <= 5) : (ring += 1) {
        const r = 290.68884 * @as(f32, @floatFromInt(ring)) * scale;
        w.print("<circle class=\"ring\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"{d:.2}\" />\n", .{
            target_width / 2.0,
            target_height / 2.0,
            r,
        }) catch unreachable;
    }

    for (dots) |dot| {
        const fill = if (dot.cluster_free) "#099" else "#999";
        w.print(
            "<circle class=\"dot\" data-cardinality=\"{d}\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"9\" fill=\"{s}\" />\n",
            .{
                dot.cardinality,
                target_width / 2.0 + (dot.x - center_x) * scale,
                target_height / 2.0 + (dot.y - center_y) * scale,
                fill,
            },
        ) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn forteLabel(sc: set_class.SetClass, out: *[16]u8) []u8 {
    if (sc.forte_number.ordinal == 0) {
        return std.fmt.bufPrint(out, "{d}", .{sc.pcs}) catch unreachable;
    }

    if (sc.forte_number.is_z) {
        return std.fmt.bufPrint(out, "{d}-Z{d}", .{ sc.forte_number.cardinality, sc.forte_number.ordinal }) catch unreachable;
    }

    return std.fmt.bufPrint(out, "{d}-{d}", .{ sc.forte_number.cardinality, sc.forte_number.ordinal }) catch unreachable;
}

pub fn setClassCenter(sc: set_class.SetClass) pitch.PitchClass {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(sc.pcs, &list_buf);
    return if (list.len == 0) 0 else list[list.len / 2];
}
