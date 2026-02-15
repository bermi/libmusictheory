const testing = @import("std").testing;
const std = @import("std");

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const guitar = @import("../guitar.zig");

test "standard tuning fret-to-midi and inverse midi map" {
    const tuning = guitar.tunings.STANDARD;

    try testing.expectEqual(@as(pitch.MidiNote, 40), guitar.fretToMidi(0, 0, tuning));

    var out: [6]guitar.FretPosition = undefined;
    const positions = guitar.midiToFretPositions(60, tuning, &out);

    try testing.expectEqual(@as(usize, 5), positions.len);
    try testing.expectEqual(@as(u3, 0), positions[0].string);
    try testing.expectEqual(@as(u5, 20), positions[0].fret);
    try testing.expectEqual(@as(u3, 1), positions[1].string);
    try testing.expectEqual(@as(u5, 15), positions[1].fret);
    try testing.expectEqual(@as(u3, 2), positions[2].string);
    try testing.expectEqual(@as(u5, 10), positions[2].fret);
    try testing.expectEqual(@as(u3, 3), positions[3].string);
    try testing.expectEqual(@as(u5, 5), positions[3].fret);
    try testing.expectEqual(@as(u3, 4), positions[4].string);
    try testing.expectEqual(@as(u5, 1), positions[4].fret);
}

test "pitch class positions and caged positions" {
    const tuning = guitar.tunings.STANDARD;

    var pos_out: [24]guitar.FretPosition = undefined;
    const c_positions = guitar.pcToFretPositions(pitch.pc.C, 0, 12, tuning, &pos_out);
    try testing.expect(c_positions.len > 0);

    const caged = guitar.cagedPositions(pitch.pc.C, .major);
    try testing.expectEqual(@as(usize, 5), caged.len);
    try testing.expectEqualSlices(i8, &[_]i8{ -1, 3, 2, 0, 1, 0 }, &caged[0].frets);
}

test "generate voicings includes open C major" {
    const tuning = guitar.tunings.STANDARD;

    var out: [512]guitar.GuitarVoicing = undefined;
    const voicings = guitar.generateVoicings(pcs.C_MAJOR_TRIAD, tuning, 4, &out);
    try testing.expect(voicings.len > 0);

    var found_open_c = false;
    for (voicings) |v| {
        if (std.mem.eql(i8, &v.frets, &[_]i8{ -1, 3, 2, 0, 1, 0 })) {
            found_open_c = true;
            break;
        }
    }
    try testing.expect(found_open_c);
}

test "guide overlay and url round trip" {
    const tuning = guitar.tunings.STANDARD;

    const selected = [_]guitar.FretPosition{
        .{ .string = 0, .fret = 0 }, // E
    };

    var guide_out: [128]guitar.GuideDot = undefined;
    const guide = guitar.pitchClassGuide(&selected, 0, 12, tuning, &guide_out);
    try testing.expect(guide.len > 0);

    var has_a_string_e = false;
    for (guide) |dot| {
        if (dot.position.string == 1 and dot.position.fret == 7) {
            has_a_string_e = true;
            break;
        }
    }
    try testing.expect(has_a_string_e);

    const voicing = guitar.GuitarVoicing{ .frets = .{ -1, 3, 2, 0, 1, 0 }, .tuning = tuning };
    var url_buf: [64]u8 = undefined;
    const url = guitar.fretsToUrl(voicing, &url_buf);
    try testing.expectEqualStrings("-1,3,2,0,1,0", url);

    const parsed = guitar.urlToFrets(url, tuning).?;
    try testing.expectEqualSlices(i8, &voicing.frets, &parsed.frets);
}
