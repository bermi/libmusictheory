const testing = @import("std").testing;
const std = @import("std");

const pitch = @import("../pitch.zig");
const key = @import("../key.zig");
const staff = @import("../svg/staff.zig");

test "staff positions and grand split" {
    const e4 = staff.midiToStaffPosition(64, .treble);
    const g4 = staff.midiToStaffPosition(67, .treble);
    try testing.expectApproxEqAbs(@as(f32, 82.0), e4.y, 0.01);
    try testing.expectApproxEqAbs(@as(f32, 74.5), g4.y, 0.01);
    try testing.expect(e4.y > g4.y);

    try testing.expectEqual(staff.Clef.bass, staff.clefForGrandStaff(59));
    try testing.expectEqual(staff.Clef.treble, staff.clefForGrandStaff(60));
    try testing.expectEqual(staff.StaffMode.bass, staff.pianoStaffMode(&[_]pitch.MidiNote{ 43, 47, 50 }));
    try testing.expectEqual(staff.StaffMode.treble, staff.pianoStaffMode(&[_]pitch.MidiNote{ 60, 64, 67 }));
    try testing.expectEqual(staff.StaffMode.grand, staff.pianoStaffMode(&[_]pitch.MidiNote{ 43, 52, 60, 64 }));
}

test "accidental detection respects key signature" {
    const g_major = key.Key.init(pitch.pc.G, .major);

    try testing.expect(!staff.needsAccidental(pitch.pc.Fs, g_major));
    try testing.expect(staff.needsAccidental(pitch.pc.F, g_major));
}

test "staff svg dimensions and notation structure" {
    const c_major = key.Key.init(pitch.pc.C, .major);
    const notes = [_]pitch.MidiNote{ 60, 64, 67 };

    var chord_buf: [12288]u8 = undefined;
    const chord_svg = staff.renderChordStaff(&notes, c_major, &chord_buf);
    try testing.expect(std.mem.startsWith(u8, chord_svg, "<svg"));
    try testing.expect(std.mem.indexOf(u8, chord_svg, "width=\"210\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "height=\"126\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "shape-rendering=\"geometricPrecision\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "class=\"clef clef-treble\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "class=\"clef-glyph\"") != null);
    try testing.expect(std.mem.indexOf(u8, chord_svg, "clef-stroke") == null);
    try testing.expectEqual(@as(usize, 3), std.mem.count(u8, chord_svg, "class=\"notehead chord-notehead\""));
    try testing.expectEqual(@as(usize, 1), std.mem.count(u8, chord_svg, "class=\"stem cluster-stem\""));

    var grand_buf: [16384]u8 = undefined;
    const grand_svg = staff.renderGrandChordStaff(&notes, c_major, &grand_buf);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "width=\"228\"") != null);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "height=\"236\"") != null);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "class=\"clef clef-treble\"") != null);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "class=\"clef clef-bass\"") != null);

    var scale_buf: [16384]u8 = undefined;
    const scale_svg = staff.renderScaleStaff(&[_]pitch.MidiNote{ 60, 62, 64, 65, 67, 69, 71 }, c_major, &scale_buf);
    try testing.expect(std.mem.indexOf(u8, scale_svg, "width=\"392\"") != null);
    try testing.expect(std.mem.indexOf(u8, scale_svg, "height=\"126\"") != null);
    try testing.expect(std.mem.indexOf(u8, scale_svg, "class=\"clef clef-treble\"") != null);

    var key_buf: [16384]u8 = undefined;
    const key_svg = staff.renderKeyStaff(&[_]pitch.MidiNote{ 60, 62, 64, 65, 67, 69, 71, 72 }, c_major, &key_buf);
    try testing.expect(std.mem.indexOf(u8, key_svg, "width=\"520\"") != null);
    try testing.expect(std.mem.count(u8, key_svg, "class=\"staff-barline\"") >= 2);
    try testing.expect(std.mem.count(u8, key_svg, "class=\"notehead key-notehead\"") >= 8);
}

test "key staff uses multiple bars" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    var buf: [16384]u8 = undefined;
    const svg = staff.renderKeyStaff(&[_]pitch.MidiNote{ 60, 62, 64, 65, 67, 69, 71, 72 }, c_major, &buf);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"staff-barline\" x1=\"240.00\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"staff-barline\" x1=\"406.00\"") != null);
}

test "piano staff switches between treble bass and grand layouts" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    var treble_buf: [16384]u8 = undefined;
    const treble_svg = staff.renderPianoStaff(&[_]pitch.MidiNote{ 60, 64, 67 }, c_major, &treble_buf);
    try testing.expect(std.mem.indexOf(u8, treble_svg, "class=\"staff-system staff-mode-treble\"") != null);
    try testing.expectEqual(@as(usize, 1), std.mem.count(u8, treble_svg, "class=\"clef "));
    try testing.expect(std.mem.indexOf(u8, treble_svg, "clef-bass") == null);

    var bass_buf: [16384]u8 = undefined;
    const bass_svg = staff.renderPianoStaff(&[_]pitch.MidiNote{ 36, 40, 43 }, c_major, &bass_buf);
    try testing.expect(std.mem.indexOf(u8, bass_svg, "class=\"staff-system staff-mode-bass\"") != null);
    try testing.expect(std.mem.indexOf(u8, bass_svg, "class=\"clef clef-bass\"") != null);
    try testing.expect(std.mem.indexOf(u8, bass_svg, "class=\"clef clef-treble\"") == null);

    var grand_buf: [24576]u8 = undefined;
    const grand_svg = staff.renderPianoStaff(&[_]pitch.MidiNote{ 43, 52, 60, 64 }, c_major, &grand_buf);
    try testing.expect(std.mem.indexOf(u8, grand_svg, "class=\"staff-system staff-mode-grand\"") != null);
    try testing.expectEqual(@as(usize, 2), std.mem.count(u8, grand_svg, "class=\"clef "));
    try testing.expect(std.mem.count(u8, grand_svg, "class=\"staff-barline\"") >= 2);
}

test "lower C ledger line stays on C and stem overlaps notehead edge" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    var buf: [12288]u8 = undefined;
    const svg = staff.renderChordStaff(&[_]pitch.MidiNote{ 60, 64, 67 }, c_major, &buf);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"ledger-line\" x1=\"115.20\" y1=\"92.00\" x2=\"132.80\" y2=\"92.00\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "y1=\"102.00\" x2=\"132.80\" y2=\"102.00\"") == null);
    try testing.expect(std.mem.indexOf(u8, svg, "class=\"stem cluster-stem\" x1=\"128.90\"") != null);
}

test "single staff chord notes stay simultaneous and seconds displace" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    var major_buf: [12288]u8 = undefined;
    const major_svg = staff.renderChordStaff(&[_]pitch.MidiNote{ 60, 64, 67 }, c_major, &major_buf);
    var major_xs: [8]f32 = undefined;
    const major_count = try extractChordNoteheadCxs(major_svg, &major_xs);
    try testing.expectEqual(@as(usize, 3), major_count);
    try testing.expectApproxEqAbs(major_xs[0], major_xs[1], 0.01);
    try testing.expectApproxEqAbs(major_xs[1], major_xs[2], 0.01);

    var cluster_buf: [12288]u8 = undefined;
    const cluster_svg = staff.renderChordStaff(&[_]pitch.MidiNote{ 60, 62, 67 }, c_major, &cluster_buf);
    var cluster_xs: [8]f32 = undefined;
    const cluster_count = try extractChordNoteheadCxs(cluster_svg, &cluster_xs);
    try testing.expectEqual(@as(usize, 3), cluster_count);
    const span = maxMinusMin(cluster_xs[0..cluster_count]);
    try testing.expect(span >= 7.5);
    try testing.expect(span <= 9.0);
}

test "accidental glyphs appear only when needed" {
    const g_major = key.Key.init(pitch.pc.G, .major);

    var in_key_buf: [12288]u8 = undefined;
    const in_key_svg = staff.renderChordStaff(&[_]pitch.MidiNote{66}, g_major, &in_key_buf); // F#
    try testing.expectEqual(@as(usize, 1), std.mem.count(u8, in_key_svg, "class=\"accidental "));
    try testing.expect(std.mem.indexOf(u8, in_key_svg, "accidental-natural") == null);

    var altered_buf: [12288]u8 = undefined;
    const altered_svg = staff.renderChordStaff(&[_]pitch.MidiNote{65}, g_major, &altered_buf); // F natural
    try testing.expectEqual(@as(usize, 2), std.mem.count(u8, altered_svg, "class=\"accidental "));
    try testing.expect(std.mem.indexOf(u8, altered_svg, "accidental-natural") != null);

    var sharp_buf: [12288]u8 = undefined;
    const sharp_svg = staff.renderChordStaff(&[_]pitch.MidiNote{61}, key.Key.init(pitch.pc.C, .major), &sharp_buf); // C#
    try testing.expectEqual(@as(usize, 1), std.mem.count(u8, sharp_svg, "class=\"accidental "));
    try testing.expect(std.mem.indexOf(u8, sharp_svg, "accidental-sharp") != null);

    var flat_key_buf: [12288]u8 = undefined;
    const flat_key_svg = staff.renderChordStaff(&[_]pitch.MidiNote{70}, key.Key.init(pitch.pc.F, .major), &flat_key_buf); // Bb in key
    try testing.expectEqual(@as(usize, 1), std.mem.count(u8, flat_key_svg, "class=\"accidental "));
    try testing.expect(std.mem.indexOf(u8, flat_key_svg, "accidental-natural") == null);
}

fn extractChordNoteheadCxs(svg: []const u8, out: []f32) !usize {
    const needle = "class=\"notehead chord-notehead\" cx=\"";
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, svg, pos, needle)) |match| {
        if (count >= out.len) return error.TestOverflow;
        const start = match + needle.len;
        const end = std.mem.indexOfScalarPos(u8, svg, start, '"') orelse return error.InvalidSvg;
        out[count] = try std.fmt.parseFloat(f32, svg[start..end]);
        count += 1;
        pos = end;
    }
    return count;
}

fn maxMinusMin(values: []const f32) f32 {
    var min = values[0];
    var max = values[0];
    for (values[1..]) |value| {
        min = @min(min, value);
        max = @max(max, value);
    }
    return max - min;
}
