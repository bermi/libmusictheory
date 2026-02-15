const std = @import("std");

const Tuning = struct {
    name: []const u8,
    tones: u8,
    avg_error_cents: f32,
};

const TUNINGS = [_]Tuning{
    .{ .name = "12-TET", .tones = 12, .avg_error_cents = 13.69 },
    .{ .name = "19-TET", .tones = 19, .avg_error_cents = 8.15 },
    .{ .name = "24-TET", .tones = 24, .avg_error_cents = 6.85 },
    .{ .name = "31-TET", .tones = 31, .avg_error_cents = 4.56 },
    .{ .name = "53-TET", .tones = 53, .avg_error_cents = 2.40 },
};

pub fn renderNTetChart(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"500\" height=\"220\" viewBox=\"0 0 500 220\">\n") catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"500\" height=\"220\" fill=\"white\" />\n") catch unreachable;
    w.writeAll("<text x=\"20\" y=\"26\" font-size=\"16\" fill=\"black\">N-TET Error vs. Just Intonation</text>\n") catch unreachable;

    var i: usize = 0;
    while (i < TUNINGS.len) : (i += 1) {
        const t = TUNINGS[i];
        const y = 55 + @as(i32, @intCast(i)) * 32;
        const width = 18.0 * t.avg_error_cents;

        w.print("<text x=\"20\" y=\"{d}\" font-size=\"12\" fill=\"black\">{s}</text>\n", .{ y + 12, t.name }) catch unreachable;
        w.print("<rect class=\"n-tet-bar\" x=\"110\" y=\"{d}\" width=\"{d:.2}\" height=\"18\" fill=\"#2c7\" />\n", .{ y, width }) catch unreachable;
        w.print("<text x=\"{d:.2}\" y=\"{d}\" font-size=\"11\" fill=\"#333\">{d:.2}c</text>\n", .{ 118.0 + width, y + 13, t.avg_error_cents }) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}
