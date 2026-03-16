const std = @import("std");
const guitar = @import("../guitar.zig");

const GRID_LEFT: f32 = 20.0;
const GRID_TOP: f32 = 20.0;
const GRID_WIDTH: f32 = 60.0;
const FRET_SPACING: f32 = 15.0;
pub const DEFAULT_VISIBLE_FRETS: u32 = 4;
const MAX_DIAGRAM_FRET: u32 = std.math.maxInt(u8);
const MARKER_Y: f32 = 10.0;

pub const Barre = struct {
    fret: u5,
    low_string: u3,
    high_string: u3,
};

pub const GenericBarre = struct {
    fret: u32,
    low_string: usize,
    high_string: usize,
};

pub const FretWindow = struct {
    start: u5,
    end: u5,
};

pub const GenericFretWindow = struct {
    start: u32,
    end: u32,
};

pub const DiagramSpec = struct {
    frets: []const i8,
    window_start: ?u32 = null,
    visible_frets: u32 = DEFAULT_VISIBLE_FRETS,
};

pub fn renderFretDiagram(voicing: guitar.GuitarVoicing, buf: []u8) []u8 {
    return renderDiagram(.{ .frets = voicing.frets[0..] }, buf);
}

pub fn renderDiagram(spec: DiagramSpec, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    if (spec.frets.len == 0) {
        w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 100 100\" shape-rendering=\"geometricPrecision\" text-rendering=\"geometricPrecision\">\n</svg>\n") catch unreachable;
        return buf[0..stream.pos];
    }

    const window = genericFretWindow(spec.frets, spec.window_start, spec.visible_frets);

    w.writeAll(
        \\<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100" shape-rendering="geometricPrecision" text-rendering="geometricPrecision">
        \\<style>
        \\.string,.fret,.marker-open,.marker-muted,.position{vector-effect:non-scaling-stroke}
        \\.string{stroke:#171717;stroke-width:1.1;stroke-linecap:round}
        \\.fret{stroke:#171717;stroke-width:1.35;stroke-linecap:round}
        \\.nut{stroke:#101010;stroke-width:3.6;stroke-linecap:round}
        \\.dot{fill:#111}
        \\.barre{fill:#111}
        \\.marker-open{fill:#fff;stroke:#111;stroke-width:1.7}
        \\.marker-muted{stroke:#111;stroke-width:1.9;stroke-linecap:round}
        \\.position{fill:#4b4338;font-size:10px;font-weight:600;font-family:ui-sans-serif,-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif}
        \\</style>
        \\
    ) catch unreachable;

    drawGrid(w, spec.frets.len, window);

    for (spec.frets, 0..) |fret, string| {
        const x = stringX(string, spec.frets.len);

        if (fret < 0) {
            drawMutedMarker(w, x);
        } else if (fret == 0) {
            drawOpenMarker(w, x);
        } else {
            const ufret = @as(u32, @intCast(fret));
            if (ufret <= window.start or ufret > window.end) continue;
            const y = dotY(ufret, window);
            w.print("<circle class=\"dot\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"4.35\" />\n", .{ x, y }) catch unreachable;
        }
    }

    if (detectBarreForFrets(spec.frets)) |barre| {
        if (barre.fret > window.start and barre.fret <= window.end) {
            const y = dotY(barre.fret, window);
            const x0 = stringX(barre.low_string, spec.frets.len) - 4.0;
            const x1 = stringX(barre.high_string, spec.frets.len) + 4.0;
            const width = x1 - x0;
            w.print("<rect class=\"barre\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"8.7\" rx=\"4.35\" />\n", .{ x0, y - 4.35, width }) catch unreachable;
        }
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn detectBarre(voicing: guitar.GuitarVoicing) ?Barre {
    const generic = detectBarreForFrets(voicing.frets[0..]) orelse return null;
    return .{
        .fret = @as(u5, @intCast(@min(generic.fret, @as(u32, guitar.MAX_FRET)))),
        .low_string = @as(u3, @intCast(generic.low_string)),
        .high_string = @as(u3, @intCast(generic.high_string)),
    };
}

pub fn detectBarreForFrets(frets: []const i8) ?GenericBarre {
    var max_fret: u32 = 0;
    for (frets) |sfret| {
        if (sfret > 0) max_fret = @max(max_fret, @as(u32, @intCast(sfret)));
    }
    if (max_fret == 0) return null;

    var fret: u32 = 1;
    while (fret <= max_fret) : (fret += 1) {
        var min_string: ?usize = null;
        var max_string: usize = 0;
        var count: usize = 0;

        for (frets, 0..) |sfret, string| {
            if (sfret < 0) continue;
            if (@as(u32, @intCast(sfret)) < fret) continue;

            if (min_string == null) min_string = string;
            max_string = string;
            count += 1;
        }

        if (count < 2) continue;
        const low_string = min_string orelse continue;
        if ((max_string - low_string) != count - 1) continue;

        return .{
            .fret = fret,
            .low_string = low_string,
            .high_string = max_string,
        };
    }

    return null;
}

fn fretWindow(voicing: guitar.GuitarVoicing) FretWindow {
    const window = genericFretWindow(voicing.frets[0..], null, DEFAULT_VISIBLE_FRETS);
    return .{
        .start = @as(u5, @intCast(@min(window.start, @as(u32, guitar.MAX_FRET)))),
        .end = @as(u5, @intCast(@min(window.end, @as(u32, guitar.MAX_FRET)))),
    };
}

fn genericFretWindow(frets: []const i8, explicit_start: ?u32, explicit_visible_frets: u32) GenericFretWindow {
    const visible_frets = normalizeVisibleFrets(explicit_visible_frets);
    if (explicit_start) |start| {
        return .{ .start = start, .end = start + visible_frets };
    }

    var min_fret: u32 = MAX_DIAGRAM_FRET;
    var max_fret: u32 = 0;
    var has_fretted = false;

    for (frets) |fret| {
        if (fret <= 0) continue;
        has_fretted = true;
        const ufret = @as(u32, @intCast(fret));
        if (ufret < min_fret) min_fret = ufret;
        if (ufret > max_fret) max_fret = ufret;
    }

    if (!has_fretted) {
        return .{ .start = 0, .end = visible_frets };
    }

    const start: u32 = if (min_fret <= 1) 0 else min_fret - 1;
    var end: u32 = start + visible_frets;
    if (max_fret + 1 > end) end = max_fret + 1;

    return .{ .start = start, .end = end };
}

fn drawGrid(writer: anytype, string_count: usize, window: GenericFretWindow) void {
    var string: usize = 0;
    while (string < string_count) : (string += 1) {
        const x = stringX(string, string_count);
        writer.print("<line class=\"string\" x1=\"{d:.2}\" y1=\"20\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x, x, gridBottom(window) }) catch unreachable;
    }

    const line_count = window.end - window.start;
    var i: u32 = 0;
    while (i <= line_count) : (i += 1) {
        const y = GRID_TOP + @as(f32, @floatFromInt(i)) * FRET_SPACING;
        const klass = if (window.start == 0 and i == 0) "nut" else "fret";
        writer.print("<line class=\"{s}\" x1=\"20\" y1=\"{d:.2}\" x2=\"80\" y2=\"{d:.2}\" />\n", .{ klass, y, y }) catch unreachable;
    }

    if (window.start > 0) {
        const pos = window.start + 1;
        writer.print("<text class=\"position\" x=\"8\" y=\"30\">{d}</text>\n", .{pos}) catch unreachable;
    }
}

fn drawOpenMarker(writer: anytype, x: f32) void {
    writer.print("<circle class=\"marker-open\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"4.3\" />\n", .{ x, MARKER_Y }) catch unreachable;
}

fn drawMutedMarker(writer: anytype, x: f32) void {
    writer.print("<line class=\"marker-muted\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 3.6, MARKER_Y - 3.6, x + 3.6, MARKER_Y + 3.6 }) catch unreachable;
    writer.print("<line class=\"marker-muted\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 3.6, MARKER_Y + 3.6, x + 3.6, MARKER_Y - 3.6 }) catch unreachable;
}

fn stringX(string: usize, string_count: usize) f32 {
    if (string_count <= 1) return GRID_LEFT + (GRID_WIDTH / 2.0);
    const spacing = GRID_WIDTH / @as(f32, @floatFromInt(string_count - 1));
    return GRID_LEFT + @as(f32, @floatFromInt(string)) * spacing;
}

fn dotY(fret: u32, window: GenericFretWindow) f32 {
    return GRID_TOP + (@as(f32, @floatFromInt(fret - window.start)) - 0.5) * FRET_SPACING;
}

fn gridBottom(window: GenericFretWindow) f32 {
    return GRID_TOP + @as(f32, @floatFromInt(window.end - window.start)) * FRET_SPACING;
}

fn normalizeVisibleFrets(explicit_visible_frets: u32) u32 {
    return if (explicit_visible_frets == 0) DEFAULT_VISIBLE_FRETS else explicit_visible_frets;
}
