const testing = @import("std").testing;
const std = @import("std");

const pitch = @import("../pitch.zig");
const key = @import("../key.zig");
const staff = @import("../svg/staff.zig");

test "staff positions and grand split" {
    const e4 = staff.midiToStaffPosition(64, .treble);
    const g4 = staff.midiToStaffPosition(67, .treble);
    try testing.expect(e4.y > g4.y);

    try testing.expectEqual(staff.Clef.bass, staff.clefForGrandStaff(59));
    try testing.expectEqual(staff.Clef.treble, staff.clefForGrandStaff(60));
}

test "accidental detection respects key signature" {
    const g_major = key.Key.init(pitch.pc.G, .major);

    try testing.expect(!staff.needsAccidental(pitch.pc.Fs, g_major));
    try testing.expect(staff.needsAccidental(pitch.pc.F, g_major));
}

test "svg dimensions and xml validity" {
    const c_major = key.Key.init(pitch.pc.C, .major);
    const notes = [_]pitch.MidiNote{ 60, 64, 67 };

    var chord_buf: [8192]u8 = undefined;
    const chord_svg = staff.renderChordStaff(&notes, c_major, &chord_buf);
    try testing.expect(std.mem.startsWith(u8, chord_svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, chord_svg, "width=\"170\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "height=\"110.77\"") != null);

    var grand_buf: [8192]u8 = undefined;
    const grand_svg = staff.renderGrandChordStaff(&notes, c_major, &grand_buf);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "width=\"170\"") != null);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "height=\"216\"") != null);

    var scale_buf: [16384]u8 = undefined;
    const scale_svg = staff.renderScaleStaff(&[_]pitch.MidiNote{ 60, 62, 64, 65, 67, 69, 71 }, c_major, &scale_buf);
    try testing.expect(std.mem.indexOf(u8, scale_svg, "width=\"363\"") != null);
    try testing.expect(std.mem.indexOf(u8, scale_svg, "height=\"113\"") != null);
}

test "accidental glyphs appear only when needed" {
    const g_major = key.Key.init(pitch.pc.G, .major);

    var in_key_buf: [8192]u8 = undefined;
    const in_key_svg = staff.renderChordStaff(&[_]pitch.MidiNote{66}, g_major, &in_key_buf); // F#
    try testing.expect(std.mem.indexOf(u8, in_key_svg, "class=\"accidental\"") == null);

    var altered_buf: [8192]u8 = undefined;
    const altered_svg = staff.renderChordStaff(&[_]pitch.MidiNote{65}, g_major, &altered_buf); // F natural
    try testing.expect(std.mem.indexOf(u8, altered_svg, "class=\"accidental\"") != null);
}
