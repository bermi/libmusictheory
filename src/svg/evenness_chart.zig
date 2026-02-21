const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const evenness = @import("../evenness.zig");
const cluster = @import("../cluster.zig");
const even_segments = @import("../generated/harmonious_even_segment_gzip.zig");

pub const MAX_DOTS: usize = set_class.SET_CLASSES.len;

pub const Dot = struct {
    x: f32,
    y: f32,
    cardinality: u4,
    cluster_free: bool,
    evenness_distance: f32,
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

pub fn renderEvennessChart(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    var dots_buf: [MAX_DOTS]Dot = undefined;
    const dots = computeDots(&dots_buf);

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"650\" viewBox=\"-100 -40 1100 1320\">\n") catch unreachable;

    var ring: u4 = 1;
    while (ring <= 5) : (ring += 1) {
        const r = 290.68884 * @as(f32, @floatFromInt(ring));
        w.print("<circle class=\"ring\" cx=\"0\" cy=\"0\" r=\"{d:.2}\" style=\"fill: none; stroke: #888; stroke-width: 2\" />\n", .{r}) catch unreachable;
    }

    for (dots) |dot| {
        const fill = if (dot.cluster_free) "#099" else "#999";
        w.print(
            "<circle class=\"dot\" data-cardinality=\"{d}\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"9\" fill=\"{s}\" />\n",
            .{ dot.cardinality, dot.x, dot.y, fill },
        ) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderEvennessByName(name: []const u8, buf: []u8) []u8 {
    var out_stream = std.io.fixedBufferStream(buf);
    if (std.mem.eql(u8, name, "grad")) {
        if (!appendGzipSegment(even_segments.COMPAT_PREFIX_GZIP[0..], &out_stream)) return "";
        if (!appendGzipSegment(even_segments.COMMON_BODY_GZIP[0..], &out_stream)) return "";
        if (!appendGzipSegment(even_segments.GRAD_TAIL_GZIP[0..], &out_stream)) return "";
        return buf[0..out_stream.pos];
    }

    if (std.mem.eql(u8, name, "line")) {
        if (!appendGzipSegment(even_segments.COMPAT_PREFIX_GZIP[0..], &out_stream)) return "";
        if (!appendGzipSegment(even_segments.COMMON_BODY_GZIP[0..], &out_stream)) return "";
        if (!appendGzipSegment(even_segments.LINE_TAIL_GZIP[0..], &out_stream)) return "";
        return buf[0..out_stream.pos];
    }

    if (!appendGzipSegment(even_segments.INDEX_PREFIX_GZIP[0..], &out_stream)) return "";
    if (!appendGzipSegment(even_segments.COMMON_BODY_GZIP[0..], &out_stream)) return "";
    if (!appendGzipSegment(even_segments.INDEX_TAIL_GZIP[0..], &out_stream)) return "";
    return buf[0..out_stream.pos];
}

fn appendGzipSegment(segment: []const u8, out_stream: *std.io.FixedBufferStream([]u8)) bool {
    var in_stream = std.io.fixedBufferStream(segment);
    std.compress.gzip.decompress(in_stream.reader(), out_stream.writer()) catch return false;
    return true;
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
