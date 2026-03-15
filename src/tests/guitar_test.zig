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

test "generic tuning fret helpers support non-six-string instruments" {
    const tuning = [_]pitch.MidiNote{ 55, 60, 64, 69 };

    try testing.expectEqual(@as(?pitch.MidiNote, 69), guitar.fretToMidiGeneric(3, 0, tuning[0..]));
    try testing.expectEqual(@as(?pitch.MidiNote, 69), guitar.fretToMidiGeneric(2, 5, tuning[0..]));

    var out: [4]guitar.GenericFretPosition = undefined;
    const positions = guitar.midiToFretPositionsGeneric(69, tuning[0..], &out);

    try testing.expectEqual(@as(usize, 4), positions.len);
    try testing.expectEqual(@as(usize, 0), positions[0].string);
    try testing.expectEqual(@as(u8, 14), positions[0].fret);
    try testing.expectEqual(@as(usize, 1), positions[1].string);
    try testing.expectEqual(@as(u8, 9), positions[1].fret);
    try testing.expectEqual(@as(usize, 2), positions[2].string);
    try testing.expectEqual(@as(u8, 5), positions[2].fret);
    try testing.expectEqual(@as(usize, 3), positions[3].string);
    try testing.expectEqual(@as(u8, 0), positions[3].fret);
}

test "generic voicing generation includes open major voicing on four strings" {
    const tuning = [_]pitch.MidiNote{ 48, 52, 55, 60 };
    var voicings: [64]guitar.GenericVoicing = undefined;
    var fret_storage: [64 * 4]i8 = undefined;

    const generated = guitar.generateVoicingsGeneric(pcs.C_MAJOR_TRIAD, tuning[0..], 12, 4, &voicings, &fret_storage);
    try testing.expect(generated.len > 0);

    var found_open = false;
    for (generated) |one| {
        if (std.mem.eql(i8, one.frets, &[_]i8{ 0, 0, 0, 0 })) {
            found_open = true;
            try testing.expectEqual(pcs.C_MAJOR_TRIAD, one.toPitchClassSet());
            break;
        }
    }
    try testing.expect(found_open);
}

test "generic pitch-class guide and url helpers support four strings" {
    const tuning = [_]pitch.MidiNote{ 55, 60, 64, 67 };
    const selected = [_]guitar.GenericFretPosition{
        .{ .string = 0, .fret = 0 },
    };

    var guide_out: [32]guitar.GenericGuideDot = undefined;
    const guide = guitar.pitchClassGuideGeneric(&selected, 0, 12, tuning[0..], &guide_out);
    try testing.expect(guide.len > 0);

    var has_open_g = false;
    var has_c_string_g = false;
    for (guide) |dot| {
        if (dot.position.string == 3 and dot.position.fret == 0) has_open_g = true;
        if (dot.position.string == 1 and dot.position.fret == 7) has_c_string_g = true;
    }
    try testing.expect(has_open_g);
    try testing.expect(has_c_string_g);

    const frets = [_]i8{ 0, 2, 3, 2 };
    var url_buf: [64]u8 = undefined;
    const url = guitar.fretsToUrlGeneric(frets[0..], &url_buf);
    try testing.expectEqualStrings("0,2,3,2", url);

    var parsed_out: [8]i8 = undefined;
    const parsed = guitar.urlToFretsGeneric(url, &parsed_out).?;
    try testing.expectEqual(@as(usize, 4), parsed.len);
    try testing.expectEqualSlices(i8, frets[0..], parsed);
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
