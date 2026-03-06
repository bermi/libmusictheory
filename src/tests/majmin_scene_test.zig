const std = @import("std");
const testing = std.testing;

const scene = @import("../svg/majmin_scene.zig");

fn transpositionIndex(value: i8) usize {
    return @as(usize, @intCast(value + 1));
}

test "majmin scene parser accepts canonical image names" {
    var modes_count: usize = 0;
    var modes_legacy_count: usize = 0;
    var modes_transpositions: [13]u16 = [_]u16{0} ** 13;

    var index: usize = 0;
    while (index < scene.MODES_COUNT) : (index += 1) {
        const name = scene.imageName(.modes, index) orelse return error.TestUnexpectedResult;
        const parsed = scene.parseImageName(.modes, name) orelse return error.TestUnexpectedResult;
        try testing.expect(parsed.kind == .modes);
        try testing.expect(parsed.transposition >= -1 and parsed.transposition <= 11);
        try testing.expect(parsed.rotation >= -3 and parsed.rotation <= 11);
        modes_count += 1;
        modes_transpositions[transpositionIndex(parsed.transposition)] += 1;

        if (parsed.family == .legacy) {
            modes_legacy_count += 1;
            try testing.expectEqual(@as(i8, -1), parsed.transposition);
            try testing.expectEqual(@as(i8, -3), parsed.rotation);
            try testing.expect(parsed.variant != null);
        } else {
            try testing.expect(parsed.rotation >= 0);
            try testing.expectEqual(@as(?u8, null), parsed.variant);
        }

        var stem_buf: [64]u8 = undefined;
        const rebuilt = scene.formatStem(parsed, &stem_buf) orelse return error.TestUnexpectedResult;
        const expected_stem = name[0 .. name.len - 4];
        try testing.expectEqualStrings(expected_stem, rebuilt);
        try testing.expectEqual(index, scene.imageIndex(parsed).?);
    }

    var scales_count: usize = 0;
    var scales_legacy_count: usize = 0;
    var scales_transpositions: [13]u16 = [_]u16{0} ** 13;

    index = 0;
    while (index < scene.SCALES_COUNT) : (index += 1) {
        const name = scene.imageName(.scales, index) orelse return error.TestUnexpectedResult;
        const parsed = scene.parseImageName(.scales, name) orelse return error.TestUnexpectedResult;
        try testing.expect(parsed.kind == .scales);
        try testing.expect(parsed.transposition >= -1 and parsed.transposition <= 11);
        try testing.expect(parsed.rotation >= 0 and parsed.rotation <= 11);
        scales_count += 1;
        scales_transpositions[transpositionIndex(parsed.transposition)] += 1;

        if (parsed.family == .legacy) {
            scales_legacy_count += 1;
            try testing.expectEqual(@as(i8, -1), parsed.transposition);
            try testing.expectEqual(@as(i8, 0), parsed.rotation);
            try testing.expect(parsed.variant != null);
        } else {
            try testing.expectEqual(@as(?u8, null), parsed.variant);
        }

        var stem_buf: [64]u8 = undefined;
        const rebuilt = scene.formatStem(parsed, &stem_buf) orelse return error.TestUnexpectedResult;
        const expected_stem = name[0 .. name.len - 4];
        try testing.expectEqualStrings(expected_stem, rebuilt);
        try testing.expectEqual(index, scene.imageIndex(parsed).?);
    }

    try testing.expectEqual(@as(usize, 366), modes_count);
    try testing.expectEqual(@as(usize, 50), scales_count);
    try testing.expectEqual(@as(usize, 2), modes_legacy_count);
    try testing.expectEqual(@as(usize, 2), scales_legacy_count);
    try testing.expectEqual(@as(u16, 30), modes_transpositions[0]);
    try testing.expectEqual(@as(u16, 2), scales_transpositions[0]);
    try testing.expectEqual(@as(u16, 28), modes_transpositions[12]);
    try testing.expectEqual(@as(u16, 4), scales_transpositions[12]);
}

test "majmin scene enumerator matches canonical order" {
    var scenes: [scene.MODES_COUNT]scene.Scene = undefined;
    const enumerated_modes = scene.enumerate(.modes, &scenes) orelse return error.TestUnexpectedResult;
    try testing.expectEqual(scene.MODES_COUNT, enumerated_modes.len);

    var i: usize = 0;
    while (i < scene.MODES_COUNT) : (i += 1) {
        const name = scene.imageName(.modes, i) orelse return error.TestUnexpectedResult;
        var stem_buf: [64]u8 = undefined;
        const rebuilt = scene.formatStem(enumerated_modes[i], &stem_buf) orelse return error.TestUnexpectedResult;
        const expected_stem = name[0 .. name.len - 4];
        try testing.expectEqualStrings(expected_stem, rebuilt);
        try testing.expectEqual(i, scene.imageIndex(enumerated_modes[i]).?);
    }

    var scales: [scene.SCALES_COUNT]scene.Scene = undefined;
    const enumerated_scales = scene.enumerate(.scales, &scales) orelse return error.TestUnexpectedResult;
    try testing.expectEqual(scene.SCALES_COUNT, enumerated_scales.len);

    i = 0;
    while (i < scene.SCALES_COUNT) : (i += 1) {
        const name = scene.imageName(.scales, i) orelse return error.TestUnexpectedResult;
        var stem_buf: [64]u8 = undefined;
        const rebuilt = scene.formatStem(enumerated_scales[i], &stem_buf) orelse return error.TestUnexpectedResult;
        const expected_stem = name[0 .. name.len - 4];
        try testing.expectEqualStrings(expected_stem, rebuilt);
        try testing.expectEqual(i, scene.imageIndex(enumerated_scales[i]).?);
    }
}

test "majmin scene imageName matches sceneForIndex formatting" {
    var i: usize = 0;
    while (i < scene.MODES_COUNT) : (i += 1) {
        const name = scene.imageName(.modes, i) orelse return error.TestUnexpectedResult;
        const reconstructed = scene.sceneForIndex(.modes, i) orelse return error.TestUnexpectedResult;
        var stem_buf: [64]u8 = undefined;
        const stem = scene.formatStem(reconstructed, &stem_buf) orelse return error.TestUnexpectedResult;
        const expected = std.fmt.allocPrint(testing.allocator, "{s}.svg", .{stem}) catch return error.OutOfMemory;
        defer testing.allocator.free(expected);
        try testing.expectEqualStrings(expected, name);
    }

    i = 0;
    while (i < scene.SCALES_COUNT) : (i += 1) {
        const name = scene.imageName(.scales, i) orelse return error.TestUnexpectedResult;
        const reconstructed = scene.sceneForIndex(.scales, i) orelse return error.TestUnexpectedResult;
        var stem_buf: [64]u8 = undefined;
        const stem = scene.formatStem(reconstructed, &stem_buf) orelse return error.TestUnexpectedResult;
        const expected = std.fmt.allocPrint(testing.allocator, "{s}.svg", .{stem}) catch return error.OutOfMemory;
        defer testing.allocator.free(expected);
        try testing.expectEqualStrings(expected, name);
    }
}

test "majmin scene parser rejects invalid stems" {
    try testing.expect(scene.parseStem(.modes, "modes,-1,dntri,0,1") == null);
    try testing.expect(scene.parseStem(.modes, "modes,-1,,0,1") == null);
    try testing.expect(scene.parseStem(.modes, "modes,12,dntri,0") == null);
    try testing.expect(scene.parseStem(.modes, "modes,0,dntri,-1") == null);
    try testing.expect(scene.parseStem(.modes, "modes,0,dntri,2") == null);
    try testing.expect(scene.parseStem(.scales, "scales,-1,,1,1") == null);
    try testing.expect(scene.parseStem(.scales, "scales,-1,dntri,0") == null);
    try testing.expect(scene.parseStem(.scales, "scales,1,dntri,1") == null);
    try testing.expect(scene.parseStem(.scales, "modes,0,dntri,0") == null);
    try testing.expect(scene.parseStem(.scales, "scales,0,badshape,0") == null);
}
