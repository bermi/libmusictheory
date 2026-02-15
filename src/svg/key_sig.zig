const std = @import("std");
const key_signature = @import("../key_signature.zig");

const STAFF_Y = [_]u8{ 39, 49, 59, 69, 79 };
const SHARP_Y = [_]u8{ 54, 44, 64, 49, 69, 59, 74 };
const FLAT_Y = [_]u8{ 59, 74, 54, 69, 49, 64, 44 };

pub fn renderKeySignature(sig: key_signature.KeySignature, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"133\" height=\"100\" viewBox=\"0 0 133 100\">\n") catch unreachable;
    w.writeAll("<g transform=\"translate(0,-14)\">\n") catch unreachable;

    for (STAFF_Y) |y| {
        w.print("<rect x=\"10\" y=\"{d}\" width=\"112.5\" height=\"1.5\" fill=\"#999\" stroke=\"#999\" stroke-width=\"0.3\" />\n", .{y}) catch unreachable;
    }
    w.writeAll("<rect x=\"10\" y=\"39\" width=\"0.5\" height=\"41.5\" fill=\"black\" />\n") catch unreachable;
    w.writeAll("<rect x=\"123\" y=\"39\" width=\"0.5\" height=\"41.5\" fill=\"black\" />\n") catch unreachable;
    w.writeAll("<text x=\"16\" y=\"68\" font-size=\"28\" fill=\"black\">G</text>\n") catch unreachable;

    const count = @as(usize, sig.count);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const x = 49 + @as(i32, @intCast(i)) * 10;
        switch (sig.kind) {
            .natural => {},
            .sharps => {
                const y = SHARP_Y[i];
                w.print("<text class=\"accidental sharp\" x=\"{d}\" y=\"{d}\" font-size=\"18\" fill=\"black\">#</text>\n", .{ x, y }) catch unreachable;
            },
            .flats => {
                const y = FLAT_Y[i];
                w.print("<text class=\"accidental flat\" x=\"{d}\" y=\"{d}\" font-size=\"18\" fill=\"black\">b</text>\n", .{ x, y }) catch unreachable;
            },
        }
    }

    w.writeAll("</g>\n") catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}
