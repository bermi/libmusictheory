const std = @import("std");
const testing = std.testing;

const pitch = @import("../pitch.zig");
const mode = @import("../mode.zig");
const modal_interchange = @import("../modal_interchange.zig");

test "modal interchange returns every containing mode in caller order" {
    const requested = [_]mode.ModeType{ .ionian, .mixolydian, .dorian, .aeolian };
    var out: [modal_interchange.MAX_MATCHES]modal_interchange.ContainingModeMatch = undefined;
    const total = modal_interchange.findContainingModes(pitch.pc.As, pitch.pc.C, &requested, out[0..]);

    try testing.expectEqual(@as(u8, 3), total);
    try testing.expectEqual(mode.ModeType.mixolydian, out[0].mode);
    try testing.expectEqual(@as(u8, 7), out[0].degree);
    try testing.expectEqual(mode.ModeType.dorian, out[1].mode);
    try testing.expectEqual(@as(u8, 7), out[1].degree);
    try testing.expectEqual(mode.ModeType.aeolian, out[2].mode);
    try testing.expectEqual(@as(u8, 7), out[2].degree);
}

test "modal interchange exposes raised fourth facts without hidden borrowing priority" {
    const requested = [_]mode.ModeType{ .ionian, .lydian, .mixolydian };
    var out: [modal_interchange.MAX_MATCHES]modal_interchange.ContainingModeMatch = undefined;
    const total = modal_interchange.findContainingModes(pitch.pc.Fs, pitch.pc.C, &requested, out[0..]);

    try testing.expectEqual(@as(u8, 1), total);
    try testing.expectEqual(mode.ModeType.lydian, out[0].mode);
    try testing.expectEqual(@as(u8, 4), out[0].degree);
}
