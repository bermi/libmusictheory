const std = @import("std");
const testing = std.testing;

const mode = @import("../mode.zig");
const ordered_scale = @import("../ordered_scale.zig");
const pitch = @import("../pitch.zig");

fn midi(pc: pitch.PitchClass, octave: i8) pitch.MidiNote {
    return pitch.pcToMidi(pc, octave);
}

test "degree lookup follows tonic-relative mode degrees" {
    try testing.expectEqual(@as(?u8, 2), mode.degreeOfNote(0, .ionian, midi(4, 4)));
    try testing.expectEqual(@as(?u8, null), mode.degreeOfNote(0, .ionian, midi(6, 4)));
    try testing.expectEqual(@as(?u8, 3), mode.degreeOfNote(0, .phrygian_dominant, midi(5, 4)));
}

test "diatonic transposition matches textbook thirds and sevenths" {
    try testing.expectEqual(@as(?pitch.MidiNote, midi(7, 4)), mode.transposeDiatonic(0, .ionian, midi(4, 4), 2));
    try testing.expectEqual(@as(?pitch.MidiNote, midi(0, 4)), mode.transposeDiatonic(0, .ionian, midi(4, 4), -2));
    try testing.expectEqual(@as(?pitch.MidiNote, midi(2, 5)), mode.transposeDiatonic(0, .ionian, midi(11, 4), 2));
}

test "nearest scale neighbors expose both sides of a chromatic note" {
    const neighbors = mode.nearestScaleNeighbors(0, .ionian, midi(6, 4));
    try testing.expect(!neighbors.in_scale);
    try testing.expect(neighbors.has_lower);
    try testing.expect(neighbors.has_upper);
    try testing.expectEqual(@as(pitch.MidiNote, midi(5, 4)), neighbors.lower);
    try testing.expectEqual(@as(pitch.MidiNote, midi(7, 4)), neighbors.upper);
    try testing.expectEqual(@as(u8, 1), neighbors.lower_distance);
    try testing.expectEqual(@as(u8, 1), neighbors.upper_distance);
}

test "snap tie policy is explicit when both scale neighbors are equally near" {
    try testing.expectEqual(@as(?pitch.MidiNote, midi(5, 4)), mode.snapToScale(0, .ionian, midi(6, 4), .lower));
    try testing.expectEqual(@as(?pitch.MidiNote, midi(7, 4)), mode.snapToScale(0, .ionian, midi(6, 4), .higher));
}

test "ordered scale helpers support non-heptatonic families" {
    var whole_tone_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;
    const whole_tone = ordered_scale.offsetsFor(.whole_tone);
    try testing.expectEqual(@as(usize, 6), whole_tone.len);
    try testing.expectEqual(@as(?u8, 3), ordered_scale.degreeIndexForOffsets(whole_tone, 0, midi(6, 4)));
    try testing.expectEqual(@as(?pitch.MidiNote, midi(10, 4)), ordered_scale.transposeMidiByDegrees(whole_tone, 0, midi(6, 4), 2));
    const rotated = ordered_scale.modeOffsets(.diminished, 1, &whole_tone_buf);
    try testing.expectEqual(@as(usize, 8), rotated.len);
}
