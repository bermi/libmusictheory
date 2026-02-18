const std = @import("std");
const templates = @import("../generated/harmonious_text_templates.zig");

fn findTemplate(list: []const templates.TextTemplate, stem: []const u8) ?[]const u8 {
    for (list) |entry| {
        if (std.mem.eql(u8, entry.stem, stem)) return entry.path_d;
    }
    return null;
}

pub fn renderVerticalLabel(text: []const u8, bottom_to_top: bool, buf: []u8) []u8 {
    const path_d = if (bottom_to_top)
        findTemplate(&templates.VERT_TEXT_B2T_BLACK, text)
    else
        findTemplate(&templates.VERT_TEXT_BLACK, text);

    if (path_d) |d| {
        var stream_exact = std.io.fixedBufferStream(buf);
        const exact = stream_exact.writer();

        const transform = if (bottom_to_top) "rotate(-90),translate(-45,0)" else "rotate(90),translate(45,0)";
        exact.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" enable-background=\"new 0 0 36 90\" xml:space=\"preserve\" viewBox=\"0 0 36 90\">\n") catch unreachable;
        exact.writeAll("  <!-- Loaded SVG font from path \"./svg-fonts/enhanced-firasanscondensed-book.svg\" -->\n") catch unreachable;
        exact.print("  <g transform=\"{s}\">\n", .{transform}) catch unreachable;
        exact.print("    <path style=\"fill: black\" d=\"{s}\"/>\n", .{d}) catch unreachable;
        exact.writeAll("  </g>\n") catch unreachable;
        exact.writeAll("</svg>") catch unreachable;
        return buf[0..stream_exact.pos];
    }

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
    if (findTemplate(&templates.CENTER_SQUARE_TEXT, glyph)) |d| {
        var stream_exact = std.io.fixedBufferStream(buf);
        const exact = stream_exact.writer();

        exact.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" enable-background=\"new 0 0 36 36\" xml:space=\"preserve\" viewBox=\"0 0 36 36\">\n") catch unreachable;
        exact.writeAll("  <!-- Loaded SVG font from path \"./svg-fonts/enhanced-firasanscondensed-book.svg\" -->\n") catch unreachable;
        exact.writeAll("  <g transform=\"translate(18,0)\">\n") catch unreachable;
        exact.print("    <path style=\"fill: gray\" d=\"{s}\"/>\n", .{d}) catch unreachable;
        exact.writeAll("  </g>\n") catch unreachable;
        exact.writeAll("</svg>") catch unreachable;
        return buf[0..stream_exact.pos];
    }

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 36\">\n") catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"36\" height=\"36\" fill=\"white\" />\n") catch unreachable;
    w.print("<text x=\"18\" y=\"22\" text-anchor=\"middle\" font-size=\"20\" fill=\"gray\" font-family=\"sans-serif\">{s}</text>\n", .{glyph}) catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}
