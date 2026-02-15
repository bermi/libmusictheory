const std = @import("std");
const guitar = @import("../guitar.zig");

const GRID_LEFT: f32 = 20.0;
const GRID_TOP: f32 = 20.0;
const STRING_SPACING: f32 = 12.0;
const FRET_SPACING: f32 = 15.0;

pub const Barre = struct {
    fret: u5,
    low_string: u3,
    high_string: u3,
};

pub const FretWindow = struct {
    start: u5,
    end: u5,
};

pub fn renderFretDiagram(voicing: guitar.GuitarVoicing, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const window = fretWindow(voicing);

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 100 100\">\n") catch unreachable;

    drawGrid(w, window);

    for (voicing.frets, 0..) |fret, string| {
        const x = stringX(@as(u3, @intCast(string)));

        if (fret < 0) {
            w.print("<text class=\"muted\" x=\"{d:.2}\" y=\"12\" text-anchor=\"middle\" font-size=\"10\">X</text>\n", .{x}) catch unreachable;
        } else if (fret == 0) {
            w.print("<text class=\"open\" x=\"{d:.2}\" y=\"12\" text-anchor=\"middle\" font-size=\"10\">O</text>\n", .{x}) catch unreachable;
        } else {
            const ufret = @as(u5, @intCast(fret));
            if (ufret <= window.start or ufret > window.end) continue;
            const y = dotY(ufret, window);
            w.print("<circle class=\"dot\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"4\" fill=\"black\" />\n", .{ x, y }) catch unreachable;
        }
    }

    if (detectBarre(voicing)) |barre| {
        if (barre.fret > window.start and barre.fret <= window.end) {
            const y = dotY(barre.fret, window);
            const x0 = stringX(barre.low_string) - 4.0;
            const x1 = stringX(barre.high_string) + 4.0;
            const width = x1 - x0;
            w.print("<rect class=\"barre\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"8\" rx=\"4\" fill=\"black\" />\n", .{ x0, y - 4.0, width }) catch unreachable;
        }
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn detectBarre(voicing: guitar.GuitarVoicing) ?Barre {
    var fret: u5 = 1;
    while (fret <= guitar.MAX_FRET) : (fret += 1) {
        var min_string: i8 = -1;
        var max_string: i8 = -1;
        var count: u3 = 0;

        var string: u3 = 0;
        while (string < guitar.NUM_STRINGS) : (string += 1) {
            const sfret = voicing.frets[string];
            if (sfret < 0) continue;
            if (@as(u5, @intCast(sfret)) < fret) continue;

            if (min_string == -1) min_string = @as(i8, @intCast(string));
            max_string = @as(i8, @intCast(string));
            count += 1;
        }

        if (count < 2) continue;
        if ((max_string - min_string) != @as(i8, @intCast(count - 1))) continue;

        return .{
            .fret = fret,
            .low_string = @as(u3, @intCast(min_string)),
            .high_string = @as(u3, @intCast(max_string)),
        };
    }

    return null;
}

fn fretWindow(voicing: guitar.GuitarVoicing) FretWindow {
    var min_fret: u5 = guitar.MAX_FRET;
    var max_fret: u5 = 0;
    var has_fretted = false;

    for (voicing.frets) |fret| {
        if (fret <= 0) continue;
        has_fretted = true;
        const ufret = @as(u5, @intCast(fret));
        if (ufret < min_fret) min_fret = ufret;
        if (ufret > max_fret) max_fret = ufret;
    }

    if (!has_fretted) {
        return .{ .start = 0, .end = 4 };
    }

    const start: u5 = if (min_fret <= 1) 0 else min_fret - 1;
    var end: u5 = start + 4;
    if (max_fret + 1 > end) end = max_fret + 1;

    return .{ .start = start, .end = end };
}

fn drawGrid(writer: anytype, window: FretWindow) void {
    var string: u3 = 0;
    while (string < guitar.NUM_STRINGS) : (string += 1) {
        const x = stringX(string);
        writer.print("<line x1=\"{d:.2}\" y1=\"20\" x2=\"{d:.2}\" y2=\"80\" stroke=\"black\" stroke-width=\"1\" />\n", .{ x, x }) catch unreachable;
    }

    var i: u3 = 0;
    while (i < 5) : (i += 1) {
        const y = GRID_TOP + @as(f32, @floatFromInt(i)) * FRET_SPACING;
        const width: u3 = if (window.start == 0 and i == 0) 3 else 1;
        writer.print("<line x1=\"20\" y1=\"{d:.2}\" x2=\"80\" y2=\"{d:.2}\" stroke=\"black\" stroke-width=\"{d}\" />\n", .{ y, y, width }) catch unreachable;
    }

    if (window.start > 0) {
        const pos = window.start + 1;
        writer.print("<text class=\"position\" x=\"8\" y=\"30\" font-size=\"10\">{d}</text>\n", .{pos}) catch unreachable;
    }
}

fn stringX(string: u3) f32 {
    return GRID_LEFT + @as(f32, @floatFromInt(string)) * STRING_SPACING;
}

fn dotY(fret: u5, window: FretWindow) f32 {
    return GRID_TOP + (@as(f32, @floatFromInt(fret - window.start)) - 0.5) * FRET_SPACING;
}
