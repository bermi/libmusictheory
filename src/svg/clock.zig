const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const cluster = @import("../cluster.zig");
const set_class = @import("../set_class.zig");
const optc_templates = @import("../generated/harmonious_optc_templates.zig");

const TAU = std.math.pi * 2.0;

const OPC_STROKE_COLORS = [_][]const u8{
    "#00c", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#161", "#094", "#0bb", "#16b", "#28f",
};

const OPC_FILL_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#ff0", "#1e0", "#094", "#0bb", "#16b", "#28f",
};

const OPC_CX = [_][]const u8{
    "50",
    "71",
    "86.37306695894642",
    "92",
    "86.37306695894642",
    "71",
    "50",
    "29.000000000000014",
    "13.626933041053585",
    "8.000000000000002",
    "13.62693304105358",
    "28.999999999999982",
};

const OPC_CY = [_][]const u8{
    "8.000000000000002",
    "13.626933041053574",
    "28.999999999999993",
    "50",
    "71",
    "86.37306695894642",
    "92",
    "86.37306695894644",
    "71.00000000000001",
    "50.000000000000014",
    "28.999999999999993",
    "13.62693304105359",
};

const OPTC_COMPAT_PC_ORDER = [_]u4{ 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1, 2 };

const OPTC_COMPAT_CX = [_][]const u8{
    "50.00",
    "71.00",
    "86.37",
    "92.00",
    "86.37",
    "71.00",
    "50.00",
    "29.00",
    "13.63",
    "8.00",
    "13.63",
    "29.00",
};

const OPTC_COMPAT_CY = [_][]const u8{
    "8.00",
    "13.63",
    "29.00",
    "50.00",
    "71.00",
    "86.37",
    "92.00",
    "86.37",
    "71.00",
    "50.00",
    "29.00",
    "13.63",
};

const OPTC_COMPAT_SPOKE_PATHS = [_][]const u8{
    "M50,18L50,30",
    "M66,22.287187078897965L60,32.67949192431123",
    "M77.71281292110204,34L67.32050807568878,40",
    "M82,50L70,50",
    "M77.71281292110204,66L67.32050807568878,60",
    "M66,77.71281292110203L60,67.32050807568876",
    "M50,82L50,70",
    "M34.00000000000001,77.71281292110204L40,67.32050807568878",
    "M22.28718707889796,66L32.67949192431122,60",
    "M18,50.00000000000001L30,50",
    "M22.287187078897958,34.00000000000001L32.67949192431122,40.00000000000001",
    "M33.999999999999986,22.28718707889797L39.99999999999999,32.67949192431123",
};

const OPTC_PRE_G_BLANK_LINES = [_]u8{ 4, 8, 7, 6, 5 };
const OPTC_POST_G_BLANK_LINES = [_]u8{ 6, 2, 3, 4, 5 };

pub const OptcCompatMetadata = struct {
    cluster_mask: pcs.PitchClassSet,
    dash_mask: pcs.PitchClassSet,
    black_mask: pcs.PitchClassSet,
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

    w.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" width=\"100\" height=\"100\" xml:space=\"preserve\" viewBox=\"0 0 100 100\">\n") catch unreachable;
    w.writeAll("  <rect x=\"0\" y=\"0\" width=\"100\" height=\"100\" style=\"fill: white\"/>\n") catch unreachable;

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const present = (set & (@as(pcs.PitchClassSet, 1) << pc)) != 0;
        const fill = if (present) OPC_FILL_COLORS[pc] else "white";

        w.print(
            "  <circle transform=\"scale(0.877),translate(7,7)\" cx=\"{s}\" cy=\"{s}\" r=\"9.5\" stroke=\"{s}\" stroke-width=\"3\" fill=\"{s}\"/>\n",
            .{ OPC_CX[pc], OPC_CY[pc], OPC_STROKE_COLORS[pc], fill },
        ) catch unreachable;
    }

    w.writeAll("\n") catch unreachable;
    w.writeAll("</svg>") catch unreachable;
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

pub fn renderOPTCHarmoniousCompat(set: pcs.PitchClassSet, label: []const u8, metadata: OptcCompatMetadata, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const variant_index = findOptcVariantIndex(label);
    const variant = optc_templates.OPTC_VARIANTS[variant_index];
    const write_spokes = metadata.dash_mask != 0 and metadata.black_mask != 0;

    w.writeAll("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n") catch return "";
    w.writeAll("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n") catch return "";
    w.writeAll("<svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\"\n") catch return "";
    w.writeAll("  xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\"\n") catch return "";
    w.writeAll("        width=\"70px\" height=\"70px\" viewBox=\"-7 -7 114 114\"\n") catch return "";
    w.writeAll("        enable-background=\"new 0 0 70 70\" xml:space=\"preserve\">\n") catch return "";
    w.writeAll("\n") catch return "";
    w.writeAll("<!--rect x=\"-200\" y=\"-200\" width=\"400\" height=\"400\" style=\"fill:#eee\" / -->\n") catch return "";

    if (write_spokes) {
        w.writeAll("\n") catch return "";
        writeOptcSpokePaths(w, metadata.dash_mask, metadata.black_mask, label.len >= 7) catch return "";
        w.writeAll("\n\n") catch return "";
    } else {
        w.writeAll("\n\n\n") catch return "";
    }

    w.print("<circle cx=\"50.00\" cy=\"50.00\" r=\"20\" stroke=\"black\" stroke-width=\"2\" fill=\"{s}\" />\n", .{variant.center_fill}) catch return "";
    w.writeAll("\n") catch return "";

    for (OPTC_COMPAT_PC_ORDER) |pc| {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        const present = (set & bit) != 0;
        const in_cluster = (metadata.cluster_mask & bit) != 0;
        const fill = if (!present)
            "transparent"
        else if (in_cluster)
            "gray"
        else
            "black";

        w.print(
            "<circle cx=\"{s}\" cy=\"{s}\" r=\"10\" stroke=\"black\" stroke-width=\"3\" fill=\"{s}\" />\n",
            .{ OPTC_COMPAT_CX[pc], OPTC_COMPAT_CY[pc], fill },
        ) catch return "";
    }

    writeBlankLines(w, OPTC_PRE_G_BLANK_LINES[variant_index]) catch return "";
    w.print("<g transform=\"{s}\">\n", .{variant.transform}) catch return "";
    w.print("<path fill=\"{s}\" d=\"{s}\"/>\n", .{ variant.text_fill, variant.text_path }) catch return "";
    w.writeAll("</g>\n") catch return "";
    writeBlankLines(w, OPTC_POST_G_BLANK_LINES[variant_index]) catch return "";
    w.writeAll("</svg>\n") catch return "";

    return buf[0..stream.pos];
}

fn writeBlankLines(writer: anytype, count: usize) !void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        try writer.writeAll("\n");
    }
}

fn writeOptcSpokePaths(writer: anytype, dash_mask: pcs.PitchClassSet, black_mask: pcs.PitchClassSet, include_white_overlay: bool) !void {
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        if ((dash_mask & bit) != 0) {
            try writer.print(
                "<path stroke=\"#777\" stroke-width=\"9\" fill=\"transparent\" stroke-dasharray=\"1.6,0.8\" d=\"{s}\"/>",
                .{OPTC_COMPAT_SPOKE_PATHS[pc]},
            );
        }
    }

    pc = 0;
    while (pc < 12) : (pc += 1) {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        if ((black_mask & bit) != 0) {
            try writer.print(
                "<path stroke=\"black\" stroke-width=\"9\" fill=\"transparent\"  d=\"{s}\"/>",
                .{OPTC_COMPAT_SPOKE_PATHS[pc]},
            );
        }
    }

    if (!include_white_overlay) return;

    pc = 0;
    while (pc < 12) : (pc += 1) {
        const bit = @as(pcs.PitchClassSet, 1) << pc;
        if ((black_mask & bit) != 0) {
            try writer.print(
                "<path stroke=\"white\" stroke-width=\"5\" fill=\"transparent\"  d=\"{s}\"/>",
                .{OPTC_COMPAT_SPOKE_PATHS[pc]},
            );
        }
    }
}

fn findOptcVariantIndex(label: []const u8) usize {
    for (optc_templates.OPTC_SPECIAL_LABELS) |entry| {
        if (std.mem.eql(u8, entry.label, label)) return entry.variant_index;
    }

    var normalized_buf: [16]u8 = undefined;
    const normalized = normalizeLabelForOptcVariantLookup(label, &normalized_buf);
    if (!std.mem.eql(u8, label, normalized)) {
        for (optc_templates.OPTC_SPECIAL_LABELS) |entry| {
            if (std.mem.eql(u8, entry.label, normalized)) return entry.variant_index;
        }
    }

    return 0;
}

fn normalizeLabelForOptcVariantLookup(label: []const u8, out: []u8) []const u8 {
    if (label.len > out.len) return label;
    for (label, 0..) |ch, i| {
        out[i] = switch (ch) {
            'A' => 't',
            'B' => 'e',
            else => ch,
        };
    }
    return out[0..label.len];
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
