const std = @import("std");
const pitch = @import("../pitch.zig");

const PC_COLORS = [_][]const u8{
    "#00C", "#a4f", "#f0f", "#a16", "#e02", "#f91",
    "#c81", "#1e0", "#094", "#0bb", "#16b", "#28f",
};

const DIATONIC_OFFSETS = [_]u4{ 0, 2, 4, 5, 7, 9, 11 };
const ACOUSTIC_OFFSETS = [_]u4{ 0, 2, 3, 5, 7, 9, 10 };
const DIMINISHED_OFFSETS = [_]u4{ 0, 1, 3, 4, 6, 7, 9, 10 };
const WHOLE_TONE_OFFSETS = [_]u4{ 0, 2, 4, 6, 8, 10 };

const DIATONIC_ROMAN = [_][]const u8{ "I", "ii", "iii", "IV", "V", "vi", "vii°" };
const ACOUSTIC_ROMAN = [_][]const u8{ "i", "ii", "III", "IV", "V", "vi°", "VII" };
const DIMINISHED_ROMAN = [_][]const u8{ "i", "ii", "III", "IV", "V", "vi", "vii", "x7" };
const WHOLE_TONE_ROMAN = [_][]const u8{ "I", "II", "III", "IV", "V", "VI" };

pub const ModeFamily = enum {
    diatonic,
    acoustic,
    diminished,
    whole_tone,
};

pub const ModeIconSpec = struct {
    family: ModeFamily,
    transposition: i8,
    degree: u4,
};

pub fn renderModeIcon(spec: ModeIconSpec, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const root_pc = modeRootPitchClass(spec);
    const color = PC_COLORS[root_pc];
    const roman = degreeRoman(spec);

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"70\" height=\"70\" viewBox=\"-7 -7 114 114\">\n") catch unreachable;
    w.print("<rect x=\"8\" y=\"8\" width=\"86\" height=\"86\" stroke=\"black\" stroke-width=\"4\" fill=\"{s}\" />\n", .{color}) catch unreachable;
    w.print("<text x=\"51\" y=\"58\" text-anchor=\"middle\" font-size=\"30\" fill=\"white\" font-family=\"serif\">{s}</text>\n", .{roman}) catch unreachable;
    w.writeAll("</svg>\n") catch unreachable;

    return buf[0..stream.pos];
}

pub fn modeRootPitchClass(spec: ModeIconSpec) pitch.PitchClass {
    const degree_count = degreeCount(spec.family);
    const degree_idx = @as(usize, @intCast((spec.degree - 1) % degree_count));

    const base_offset = switch (spec.family) {
        .diatonic => DIATONIC_OFFSETS[degree_idx],
        .acoustic => ACOUSTIC_OFFSETS[degree_idx],
        .diminished => DIMINISHED_OFFSETS[degree_idx],
        .whole_tone => WHOLE_TONE_OFFSETS[degree_idx],
    };

    const t = @as(i16, spec.transposition);
    const wrapped = @mod(t, 12);
    const tonic = @as(u8, @intCast(wrapped));
    const sum = tonic + @as(u8, base_offset);

    return @as(pitch.PitchClass, @intCast(sum % 12));
}

pub fn degreeRoman(spec: ModeIconSpec) []const u8 {
    const count = degreeCount(spec.family);
    const idx = @as(usize, @intCast((spec.degree - 1) % count));

    return switch (spec.family) {
        .diatonic => DIATONIC_ROMAN[idx],
        .acoustic => ACOUSTIC_ROMAN[idx],
        .diminished => DIMINISHED_ROMAN[idx],
        .whole_tone => WHOLE_TONE_ROMAN[idx],
    };
}

pub fn degreeCount(family: ModeFamily) u4 {
    return switch (family) {
        .diatonic => 7,
        .acoustic => 7,
        .diminished => 8,
        .whole_tone => 6,
    };
}

pub fn fileName(spec: ModeIconSpec, out: *[32]u8) []u8 {
    const family_abbrev = switch (spec.family) {
        .diatonic => "d",
        .acoustic => "aco",
        .diminished => "o",
        .whole_tone => "w",
    };
    return std.fmt.bufPrint(out, "{s},{d},{s}.svg", .{ family_abbrev, spec.transposition, degreeRoman(spec) }) catch unreachable;
}
