const std = @import("std");
const testing = std.testing;
const even_compat_model = @import("../even_compat_model.zig");
const set_class = @import("../set_class.zig");
const forte = @import("../forte.zig");

fn forteLabel(number: forte.ForteNumber, out: *[16]u8) []u8 {
    if (number.is_z) {
        return std.fmt.bufPrint(out, "{d}-Z{d}", .{ number.cardinality, number.ordinal }) catch unreachable;
    }
    return std.fmt.bufPrint(out, "{d}-{d}", .{ number.cardinality, number.ordinal }) catch unreachable;
}

fn findEntry(entries: []const even_compat_model.Entry, card: u8, ordinal: u8, is_z: bool) ?even_compat_model.Entry {
    for (entries) |entry| {
        const number = entry.sc.forte_number;
        if (number.cardinality == card and number.ordinal == ordinal and number.is_z == is_z) return entry;
    }
    return null;
}

test "even compat display domain counts match harmonious ray counts" {
    var buf: [even_compat_model.DISPLAY_ENTRY_COUNT]even_compat_model.Entry = undefined;
    const entries = even_compat_model.enumerateDisplayDomain(&buf);

    try testing.expectEqual(@as(usize, even_compat_model.DISPLAY_ENTRY_COUNT), entries.len);

    var hist: [13]u16 = undefined;
    even_compat_model.cardinalityHistogram(entries, &hist);

    const expected = [_]u16{ 12, 29, 38, 36, 38, 29, 12 };
    for (expected, 0..) |count, i| {
        try testing.expectEqual(count, hist[i + 3]);
    }
}

test "even compat display domain preserves optic pair and single counts" {
    var buf: [even_compat_model.DISPLAY_ENTRY_COUNT]even_compat_model.Entry = undefined;
    const entries = even_compat_model.enumerateDisplayDomain(&buf);

    try testing.expectEqual(@as(usize, 66), even_compat_model.countBorder(entries, .single));
    try testing.expectEqual(@as(usize, 128), even_compat_model.countBorder(entries, .pair));
}

test "even compat retains only the six self-complementary symmetric hexachords" {
    const expected = [_][]const u8{
        "6-1",
        "6-7",
        "6-8",
        "6-20",
        "6-32",
        "6-35",
    };
    var seen = [_]bool{false} ** expected.len;
    var retained_count: usize = 0;
    var omitted_count: usize = 0;

    for (set_class.SET_CLASSES) |sc| {
        if (!even_compat_model.isOpticRepresentative(sc) or sc.cardinality != 6 or !sc.flags.symmetric) continue;
        const included = even_compat_model.includeInDisplayDomain(sc);
        if (included) {
            try testing.expect(even_compat_model.isSelfComplementarySymmetricHexachord(sc));
            retained_count += 1;

            var buf: [16]u8 = undefined;
            const label = forteLabel(sc.forte_number, &buf);
            var matched = false;
            for (expected, 0..) |wanted, idx| {
                if (std.mem.eql(u8, label, wanted)) {
                    seen[idx] = true;
                    matched = true;
                }
            }
            try testing.expect(matched);
        } else {
            try testing.expect(!even_compat_model.isSelfComplementarySymmetricHexachord(sc));
            omitted_count += 1;
        }
    }

    try testing.expectEqual(@as(usize, 6), retained_count);
    try testing.expectEqual(@as(usize, 14), omitted_count);
    for (seen) |value| try testing.expect(value);
}

test "even compat index family classification matches canonical scale families" {
    var buf: [even_compat_model.DISPLAY_ENTRY_COUNT]even_compat_model.Entry = undefined;
    const entries = even_compat_model.enumerateDisplayDomain(&buf);

    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.diatonic_hexagon,
        findEntry(entries, 7, 35, false).?.marker_family,
    );
    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.acoustic_square,
        findEntry(entries, 7, 34, false).?.marker_family,
    );
    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.whole_tone_star,
        findEntry(entries, 6, 35, false).?.marker_family,
    );
    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.diminished_octagon,
        findEntry(entries, 8, 28, false).?.marker_family,
    );
    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.neighboring_triangle,
        findEntry(entries, 7, 32, false).?.marker_family,
    );
    try testing.expectEqual(
        even_compat_model.IndexMarkerFamily.other_circle,
        findEntry(entries, 3, 1, false).?.marker_family,
    );
}
