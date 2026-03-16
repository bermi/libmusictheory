const std = @import("std");
const svg_quality = @import("quality.zig");

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

    svg_quality.writeSvgPrelude(w, "500", "220", "0 0 500 220",
        \\.chart-grid,.n-tet-bar{vector-effect:non-scaling-stroke}
        \\.chart-grid{stroke:#d6dae2;stroke-width:1}
        \\.chart-title{font-size:16px;fill:black}
        \\.chart-label{font-size:12px;fill:black}
        \\.chart-value{font-size:11px;fill:#333}
        \\.n-tet-bar{fill:#2c7;rx:4;ry:4}
        \\
    ) catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"500\" height=\"220\" fill=\"white\" />\n") catch unreachable;
    w.writeAll("<text class=\"label-sans chart-title\" x=\"20\" y=\"26\">N-TET Error vs. Just Intonation</text>\n") catch unreachable;

    var grid: usize = 0;
    while (grid < 5) : (grid += 1) {
        const x = 110 + @as(i32, @intCast(grid + 1)) * 70;
        w.print("<line class=\"chart-grid\" x1=\"{d}\" y1=\"44\" x2=\"{d}\" y2=\"205\" />\n", .{ x, x }) catch unreachable;
    }

    var i: usize = 0;
    while (i < TUNINGS.len) : (i += 1) {
        const t = TUNINGS[i];
        const y = 55 + @as(i32, @intCast(i)) * 32;
        const width = 18.0 * t.avg_error_cents;

        w.print("<text class=\"label-sans chart-label\" x=\"20\" y=\"{d}\">{s}</text>\n", .{ y + 12, t.name }) catch unreachable;
        w.print("<rect class=\"n-tet-bar\" x=\"110\" y=\"{d}\" width=\"{d:.2}\" height=\"18\" rx=\"4\" ry=\"4\" />\n", .{ y, width }) catch unreachable;
        w.print("<text class=\"label-mono chart-value\" x=\"{d:.2}\" y=\"{d}\">{d:.2}c</text>\n", .{ 118.0 + width, y + 13, t.avg_error_cents }) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}
