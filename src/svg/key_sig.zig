const std = @import("std");
const key_signature = @import("../key_signature.zig");
const svg_quality = @import("quality.zig");

const STAFF_Y = [_]u8{ 39, 49, 59, 69, 79 };
const SHARP_Y = [_]u8{ 54, 44, 64, 49, 69, 59, 74 };
const FLAT_Y = [_]u8{ 59, 74, 54, 69, 49, 64, 44 };

pub fn renderKeySignature(sig: key_signature.KeySignature, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    svg_quality.writeSvgPrelude(w, "133", "100", "0 0 133 100",
        \\.staff-line,.barline{vector-effect:non-scaling-stroke}
        \\.staff-line{fill:#999;stroke:#999;stroke-width:0.3}
        \\.barline{fill:black}
        \\.key-root{font-size:28px;fill:black}
        \\.accidental{font-size:18px;fill:black}
        \\
    ) catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"133\" height=\"100\" fill=\"white\" />\n") catch unreachable;
    w.writeAll("<g transform=\"translate(0,-14)\">\n") catch unreachable;

    for (STAFF_Y) |y| {
        w.print("<rect class=\"staff-line\" x=\"10\" y=\"{d}\" width=\"112.5\" height=\"1.5\" />\n", .{y}) catch unreachable;
    }
    w.writeAll("<rect class=\"barline\" x=\"10\" y=\"39\" width=\"0.5\" height=\"41.5\" />\n") catch unreachable;
    w.writeAll("<rect class=\"barline\" x=\"123\" y=\"39\" width=\"0.5\" height=\"41.5\" />\n") catch unreachable;
    w.writeAll("<text class=\"label-serif label-outline key-root\" x=\"16\" y=\"68\">G</text>\n") catch unreachable;

    const count = @as(usize, sig.count);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const x = 49 + @as(i32, @intCast(i)) * 10;
        switch (sig.kind) {
            .natural => {},
            .sharps => {
                const y = SHARP_Y[i];
                w.print("<text class=\"accidental sharp\" x=\"{d}\" y=\"{d}\" font-family=\"Palatino Linotype,Book Antiqua,Georgia,serif\">#</text>\n", .{ x, y }) catch unreachable;
            },
            .flats => {
                const y = FLAT_Y[i];
                w.print("<text class=\"accidental flat\" x=\"{d}\" y=\"{d}\" font-family=\"Palatino Linotype,Book Antiqua,Georgia,serif\">b</text>\n", .{ x, y }) catch unreachable;
            },
        }
    }

    w.writeAll("</g>\n") catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}
