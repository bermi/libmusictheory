const std = @import("std");

pub fn renderVerticalLabel(text: []const u8, bottom_to_top: bool, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const rotate = if (bottom_to_top) "-90" else "90";
    const tx = if (bottom_to_top) "-45" else "45";

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 90\">\n") catch unreachable;
    w.print("<g transform=\"rotate({s}),translate({s},0)\">\n", .{ rotate, tx }) catch unreachable;
    w.print("<text x=\"-10\" y=\"20\" font-size=\"18\" fill=\"black\" font-family=\"sans-serif\">{s}</text>\n", .{text}) catch unreachable;
    w.writeAll("</g>\n") catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}

pub fn renderCenterSquareGlyph(glyph: []const u8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 36\">\n") catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"36\" height=\"36\" fill=\"white\" />\n") catch unreachable;
    w.print("<text x=\"18\" y=\"22\" text-anchor=\"middle\" font-size=\"20\" fill=\"gray\" font-family=\"sans-serif\">{s}</text>\n", .{glyph}) catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}
