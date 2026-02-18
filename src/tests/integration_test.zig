const std = @import("std");
const testing = std.testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const key = @import("../key.zig");
const harmony = @import("../harmony.zig");
const mode = @import("../mode.zig");
const guitar = @import("../guitar.zig");
const svg_clock = @import("../svg/clock.zig");
const svg_staff = @import("../svg/staff.zig");

const EXPECTED_MAJOR_TRIAD_UPPERCASE = [_]bool{ true, false, false, true, true, false, false };

test "roman numeral integration for all major degrees" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    var degree: u4 = 1;
    while (degree <= 7) : (degree += 1) {
        const triad = harmony.diatonicTriad(c_major, degree);
        const numeral = harmony.romanNumeral(triad, c_major);

        try testing.expectEqual(degree, numeral.degree);
        try testing.expectEqual(EXPECTED_MAJOR_TRIAD_UPPERCASE[degree - 1], numeral.uppercase);
    }
}

test "mode triads are compatible with their parent mode" {
    for (mode.ALL_MODES) |m| {
        var list_buf: [12]pitch.PitchClass = undefined;
        const list = pcs.toList(m.pcs, &list_buf);
        if (list.len < 5) continue;

        const chord_set = pcs.fromList(&[_]pitch.PitchClass{ list[0], list[2], list[4] });
        const chord = harmony.ChordInstance{ .root = list[0], .pcs = chord_set, .quality = .unknown, .degree = 0 };
        const mode_ctx = harmony.ModeContext{ .root = list[0], .pcs = m.pcs };

        const match = harmony.chordScaleCompatibility(chord, mode_ctx);
        try testing.expect(match.compatible);
    }
}

test "caged positions cover all 12 roots with valid shape metadata" {
    var root: u4 = 0;
    while (root < 12) : (root += 1) {
        const positions = guitar.cagedPositions(@as(pitch.PitchClass, @intCast(root)), .major);
        try testing.expectEqual(@as(usize, 5), positions.len);

        for (positions) |pos| {
            try testing.expect(pos.root_string < guitar.NUM_STRINGS);
            try testing.expect(pos.position <= guitar.MAX_FRET);
        }
    }
}

test "svg integration emits valid wrappers" {
    var buf: [8192]u8 = undefined;

    const clock_svg = svg_clock.renderOPC(pcs.C_MAJOR_TRIAD, &buf);
    try testing.expect(std.mem.startsWith(u8, clock_svg, "<svg"));
    try testing.expect(std.mem.endsWith(u8, clock_svg, "</svg>"));

    const notes = [_]pitch.MidiNote{ 60, 64, 67 };
    const staff_svg = svg_staff.renderChordStaff(&notes, key.Key.init(0, .major), &buf);
    try testing.expect(std.mem.startsWith(u8, staff_svg, "<svg"));
    try testing.expect(std.mem.endsWith(u8, staff_svg, "</svg>\n"));
}
