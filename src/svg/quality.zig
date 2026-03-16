const std = @import("std");

pub const SANS_STACK = "\"Avenir Next\",\"Avenir\",\"SF Pro Display\",\"Segoe UI\",\"Helvetica Neue\",Arial,sans-serif";
pub const SERIF_STACK = "\"Iowan Old Style\",\"Palatino Linotype\",\"Book Antiqua\",Georgia,serif";
pub const MONO_STACK = "\"SFMono-Regular\",Menlo,Monaco,Consolas,\"Liberation Mono\",monospace";

pub fn writeSvgPrelude(writer: anytype, width: []const u8, height: []const u8, view_box: []const u8, extra_css: []const u8) !void {
    try writer.print(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{s}\" height=\"{s}\" viewBox=\"{s}\" shape-rendering=\"geometricPrecision\" text-rendering=\"geometricPrecision\">\n",
        .{ width, height, view_box },
    );
    try writer.writeAll("<style>\n");
    try writer.writeAll("text{font-kerning:normal;text-rendering:geometricPrecision}\n");
    try writer.print(".label-sans{{font-family:{s};font-weight:600;letter-spacing:0.012em}}\n", .{SANS_STACK});
    try writer.print(".label-serif{{font-family:{s};font-weight:600;letter-spacing:0.01em}}\n", .{SERIF_STACK});
    try writer.print(".label-mono{{font-family:{s};font-weight:600;letter-spacing:0.01em}}\n", .{MONO_STACK});
    try writer.writeAll(".label-outline{paint-order:stroke fill;stroke:white;stroke-width:2.2;stroke-linejoin:round}\n");
    try writer.writeAll(".inverse-outline{paint-order:stroke fill;stroke:rgba(0,0,0,0.42);stroke-width:1.8;stroke-linejoin:round}\n");
    try writer.writeAll(".vector-stroke{vector-effect:non-scaling-stroke;stroke-linecap:round;stroke-linejoin:round}\n");
    if (extra_css.len > 0) {
        try writer.writeAll(extra_css);
        if (extra_css[extra_css.len - 1] != '\n') try writer.writeByte('\n');
    }
    try writer.writeAll("</style>\n");
}
