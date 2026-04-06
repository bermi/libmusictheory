const std = @import("std");
const testing = std.testing;

const chord_detection = @import("../chord_detection.zig");
const pcs = @import("../pitch_class_set.zig");
const pitch = @import("../pitch.zig");

test "structured chord detection finds exact major seventh and slash-chord facts" {
    var out: [8]chord_detection.Match = undefined;
    const total = chord_detection.detectMatches(pcs.fromList(&[_]u4{ 0, 4, 7, 11 }), true, pitch.pc.E, out[0..]);

    try testing.expectEqual(@as(u16, 1), total);
    try testing.expectEqual(chord_detection.PatternId.maj7, out[0].pattern);
    try testing.expectEqual(pitch.pc.C, out[0].root);
    try testing.expectEqual(pitch.pc.E, out[0].bass);
    try testing.expectEqual(@as(u8, 2), out[0].bass_degree);
    try testing.expect(!out[0].root_is_bass);
}

test "structured chord detection preserves tied interpretations" {
    var out: [8]chord_detection.Match = undefined;
    const total = chord_detection.detectMatches(pcs.fromList(&[_]u4{ 0, 2, 7 }), true, pitch.pc.C, out[0..]);

    try testing.expectEqual(@as(u16, 2), total);
    try testing.expectEqual(chord_detection.PatternId.sus2, out[0].pattern);
    try testing.expectEqual(pitch.pc.C, out[0].root);
    try testing.expect(out[0].root_is_bass);
    try testing.expectEqual(chord_detection.PatternId.sus4, out[1].pattern);
    try testing.expectEqual(pitch.pc.G, out[1].root);
}

test "structured chord detection covers every shipped pattern at root C" {
    for (chord_detection.ALL_PATTERNS) |pattern| {
        var out: [8]chord_detection.Match = undefined;
        const total = chord_detection.detectMatches(pattern.pcs, true, pitch.pc.C, out[0..]);
        try testing.expect(total >= 1);

        var found = false;
        for (out[0..@min(@as(usize, total), out.len)]) |match| {
            if (match.root == pitch.pc.C and match.pattern == pattern.id) {
                found = true;
                break;
            }
        }
        try testing.expect(found);
    }
}
