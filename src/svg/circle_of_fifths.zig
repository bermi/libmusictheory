const std = @import("std");
const pitch = @import("../pitch.zig");
const svg_quality = @import("quality.zig");

const PC_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#1e0", "#094", "#0bb", "#16b", "#28f",
};

const MAJOR_NAMES = [_][]const u8{ "C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B" };
const MINOR_NAMES = [_][]const u8{ "Am", "A#m", "Bm", "Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m" };

pub fn fifthsOrder() [12]pitch.PitchClass {
    return [_]pitch.PitchClass{ 0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5 };
}

pub fn renderCircleOfFifths(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const order = fifthsOrder();

    svg_quality.writeSvgPrelude(w, "100", "100", "0 0 100 100",
        \\.cof-ring,.major-key,.minor-key{vector-effect:non-scaling-stroke}
        \\.cof-ring{stroke:#aeb3bd;stroke-width:1.1;fill:none}
        \\.major-key{stroke:black;stroke-width:0.6}
        \\.minor-key{stroke:#666;stroke-width:0.6}
        \\.major-label{font-size:5.2px;fill:white}
        \\.minor-label{font-size:3.8px;fill:black}
        \\
    ) catch unreachable;
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"100\" height=\"100\" fill=\"white\"/>\n") catch unreachable;
    w.writeAll("<circle class=\"cof-ring\" cx=\"50\" cy=\"50\" r=\"45\" />\n") catch unreachable;

    for (order, 0..) |pc, i| {
        const angle = std.math.tau * (@as(f32, @floatFromInt(i)) / 12.0);
        const outer_x = 50.0 + 42.0 * @as(f32, @floatCast(std.math.sin(angle)));
        const outer_y = 50.0 - 42.0 * @as(f32, @floatCast(std.math.cos(angle)));
        const inner_x = 50.0 + 28.0 * @as(f32, @floatCast(std.math.sin(angle)));
        const inner_y = 50.0 - 28.0 * @as(f32, @floatCast(std.math.cos(angle)));

        const major_label = majorLabel(@as(u4, @intCast(i)), pc);
        const minor_label = minorLabel(pc);
        const fill = PC_COLORS[pc];

        w.print("<circle class=\"major-key\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"5.5\" fill=\"{s}\" />\n", .{ outer_x, outer_y, fill }) catch unreachable;
        w.print("<text class=\"label-sans inverse-outline major-label\" x=\"{d:.2}\" y=\"{d:.2}\" text-anchor=\"middle\" dominant-baseline=\"middle\">{s}</text>\n", .{ outer_x, outer_y + 0.2, major_label }) catch unreachable;

        w.print("<circle class=\"minor-key\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"3.8\" fill=\"white\" />\n", .{ inner_x, inner_y }) catch unreachable;
        w.print("<text class=\"label-sans label-outline minor-label\" x=\"{d:.2}\" y=\"{d:.2}\" text-anchor=\"middle\" dominant-baseline=\"middle\">{s}</text>\n", .{ inner_x, inner_y + 0.1, minor_label }) catch unreachable;
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn majorLabel(index: u4, pc: pitch.PitchClass) []const u8 {
    return switch (index) {
        5 => "B/Cb",
        6 => "F#/Gb",
        7 => "Db/C#",
        else => majorName(pc),
    };
}

fn majorName(pc: pitch.PitchClass) []const u8 {
    return MAJOR_NAMES[pc];
}

fn minorLabel(major_pc: pitch.PitchClass) []const u8 {
    const minor_pc = @as(pitch.PitchClass, @intCast((@as(u8, major_pc) + 9) % 12));
    return MINOR_NAMES[minor_pc];
}
