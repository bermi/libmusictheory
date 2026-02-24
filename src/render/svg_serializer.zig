const std = @import("std");
const ir = @import("ir.zig");

pub const Mode = enum {
    strict,
    pretty,
};

pub fn write(scene: ir.Scene, writer: anytype, mode: Mode) !void {
    _ = mode;
    for (scene.ops) |op| {
        switch (op) {
            .raw => |text| try writer.writeAll(text),
            .path => |p| try writePath(writer, p),
            .rect => |r| try writeRect(writer, r),
            .circle => |c| try writeCircle(writer, c),
            .ellipse => |e| try writeEllipse(writer, e),
            .line => |l| try writeLine(writer, l),
            .polyline => |p| try writePolyline(writer, p),
            .polygon => |p| try writePolygon(writer, p),
            .group_start => |g| try writeGroupStart(writer, g),
            .group_end => |newline| {
                try writer.writeAll("</g>");
                if (newline) try writer.writeByte('\n');
            },
            .link_start => |l| try writeLinkStart(writer, l),
            .link_end => |newline| {
                try writer.writeAll("</a>");
                if (newline) try writer.writeByte('\n');
            },
        }
    }
}

fn writeAttr(writer: anytype, key: []const u8, value: []const u8) !void {
    try writer.print(" {s}=\"{s}\"", .{ key, value });
}

fn writeStyleAttr(writer: anytype, key: []const u8, value: ?[]const u8) !void {
    if (value) |v| try writeAttr(writer, key, v);
}

fn writePath(writer: anytype, path: ir.Path) !void {
    try writer.writeAll("<path");
    try writeStyleAttr(writer, "stroke", path.stroke);
    try writeStyleAttr(writer, "stroke-width", path.stroke_width);
    try writeStyleAttr(writer, "fill", path.fill);
    try writeStyleAttr(writer, "stroke-dasharray", path.stroke_dasharray);

    var i: u8 = 0;
    while (i < path.spaces_before_d) : (i += 1) {
        try writer.writeByte(' ');
    }
    try writer.print("d=\"{s}\"/>", .{path.d});
    if (path.newline) try writer.writeByte('\n');
}

fn writeRect(writer: anytype, rect: ir.Rect) !void {
    try writer.writeAll("<rect");
    try writeAttr(writer, "x", rect.x);
    try writeAttr(writer, "y", rect.y);
    try writeAttr(writer, "width", rect.width);
    try writeAttr(writer, "height", rect.height);
    try writeStyleAttr(writer, "stroke", rect.stroke);
    try writeStyleAttr(writer, "stroke-width", rect.stroke_width);
    try writeStyleAttr(writer, "fill", rect.fill);
    try writer.writeAll(" />");
    if (rect.newline) try writer.writeByte('\n');
}

fn writeCircle(writer: anytype, circle: ir.Circle) !void {
    try writer.writeAll("<circle");
    try writeAttr(writer, "cx", circle.cx);
    try writeAttr(writer, "cy", circle.cy);
    try writeAttr(writer, "r", circle.r);
    try writeStyleAttr(writer, "stroke", circle.stroke);
    try writeStyleAttr(writer, "stroke-width", circle.stroke_width);
    try writeStyleAttr(writer, "fill", circle.fill);
    try writer.writeAll(" />");
    if (circle.newline) try writer.writeByte('\n');
}

fn writeEllipse(writer: anytype, ellipse: ir.Ellipse) !void {
    try writer.writeAll("<ellipse");
    try writeAttr(writer, "cx", ellipse.cx);
    try writeAttr(writer, "cy", ellipse.cy);
    try writeAttr(writer, "rx", ellipse.rx);
    try writeAttr(writer, "ry", ellipse.ry);
    try writeStyleAttr(writer, "stroke", ellipse.stroke);
    try writeStyleAttr(writer, "stroke-width", ellipse.stroke_width);
    try writeStyleAttr(writer, "fill", ellipse.fill);
    try writer.writeAll(" />");
    if (ellipse.newline) try writer.writeByte('\n');
}

fn writeLine(writer: anytype, line: ir.Line) !void {
    try writer.writeAll("<line");
    try writeAttr(writer, "x1", line.x1);
    try writeAttr(writer, "y1", line.y1);
    try writeAttr(writer, "x2", line.x2);
    try writeAttr(writer, "y2", line.y2);
    try writeStyleAttr(writer, "stroke", line.stroke);
    try writeStyleAttr(writer, "stroke-width", line.stroke_width);
    try writeStyleAttr(writer, "fill", line.fill);
    try writeStyleAttr(writer, "stroke-dasharray", line.stroke_dasharray);
    try writer.writeAll(" />");
    if (line.newline) try writer.writeByte('\n');
}

fn writePolyline(writer: anytype, polyline: ir.Polyline) !void {
    try writer.writeAll("<polyline");
    try writeAttr(writer, "points", polyline.points);
    try writeStyleAttr(writer, "stroke", polyline.stroke);
    try writeStyleAttr(writer, "stroke-width", polyline.stroke_width);
    try writeStyleAttr(writer, "fill", polyline.fill);
    try writeStyleAttr(writer, "stroke-dasharray", polyline.stroke_dasharray);
    try writer.writeAll(" />");
    if (polyline.newline) try writer.writeByte('\n');
}

fn writePolygon(writer: anytype, polygon: ir.Polygon) !void {
    try writer.writeAll("<polygon");
    try writeAttr(writer, "points", polygon.points);
    try writeStyleAttr(writer, "stroke", polygon.stroke);
    try writeStyleAttr(writer, "stroke-width", polygon.stroke_width);
    try writeStyleAttr(writer, "fill", polygon.fill);
    try writeStyleAttr(writer, "stroke-dasharray", polygon.stroke_dasharray);
    try writer.writeAll(" />");
    if (polygon.newline) try writer.writeByte('\n');
}

fn writeGroupStart(writer: anytype, group: ir.GroupStart) !void {
    try writer.writeAll("<g");
    for (group.attrs) |attr| {
        try writeAttr(writer, attr.key, attr.value);
    }
    try writer.writeAll(">");
    if (group.newline) try writer.writeByte('\n');
}

fn writeLinkStart(writer: anytype, link: ir.LinkStart) !void {
    try writer.writeAll("<a");
    try writeAttr(writer, "xlink:href", link.href);
    for (link.attrs) |attr| {
        try writeAttr(writer, attr.key, attr.value);
    }
    try writer.writeAll(">");
    if (link.newline) try writer.writeByte('\n');
}

test "serializer deterministic for identical scene" {
    var ops: [4]ir.Op = undefined;
    var builder = ir.Builder.init(&ops);
    try builder.raw("<svg>\n");
    try builder.circle(.{
        .cx = "10",
        .cy = "10",
        .r = "5",
        .stroke = "black",
        .stroke_width = "2",
        .fill = "white",
    });
    try builder.path(.{
        .stroke = "black",
        .stroke_width = "1",
        .fill = "transparent",
        .d = "M0,0L10,10",
    });
    try builder.raw("</svg>\n");

    var a_buf: [512]u8 = undefined;
    var b_buf: [512]u8 = undefined;

    var a_stream = std.io.fixedBufferStream(&a_buf);
    var b_stream = std.io.fixedBufferStream(&b_buf);

    try write(builder.scene(), a_stream.writer(), .strict);
    try write(builder.scene(), b_stream.writer(), .strict);

    const a = a_buf[0..a_stream.pos];
    const b = b_buf[0..b_stream.pos];
    try std.testing.expectEqualStrings(a, b);
}
