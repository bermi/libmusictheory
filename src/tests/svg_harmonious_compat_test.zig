const std = @import("std");
const testing = std.testing;

const compat = @import("../harmonious_svg_compat.zig");

fn looksLikeSvg(svg: []const u8) bool {
    return std.mem.startsWith(u8, svg, "<svg") or
        std.mem.startsWith(u8, svg, "<?xml") or
        std.mem.startsWith(u8, svg, "\n<svg");
}

fn findKindIndex(name: []const u8) ?usize {
    var kind_index: usize = 0;
    while (kind_index < compat.kindCount()) : (kind_index += 1) {
        const got = compat.kindName(kind_index) orelse continue;
        if (std.mem.eql(u8, got, name)) return kind_index;
    }
    return null;
}

test "harmonious compatibility kinds are available" {
    try testing.expectEqual(@as(usize, 15), compat.kindCount());

    const expected = [_][]const u8{
        "vert-text-black",
        "even",
        "scale",
        "opc",
        "oc",
        "optc",
        "eadgbe",
        "center-square-text",
        "wide-chord",
        "chord-clipped",
        "grand-chord",
        "majmin/modes",
        "majmin/scales",
        "chord",
        "vert-text-b2t-black",
    };

    for (expected, 0..) |name, i| {
        const got = compat.kindName(i).?;
        try testing.expectEqualStrings(name, got);
        try testing.expect(compat.imageCount(i) > 0);
    }
}

test "compat generation smoke by kind" {
    var buf: [4 * 1024 * 1024]u8 = undefined;

    var kind_index: usize = 0;
    while (kind_index < compat.kindCount()) : (kind_index += 1) {
        const count = compat.imageCount(kind_index);
        try testing.expect(count > 0);

        const svg = compat.generateByIndex(kind_index, 0, &buf);
        try testing.expect(svg.len > 0);
        try testing.expect(looksLikeSvg(svg));
    }
}

test "compat optc parses metadata arguments into spoke overlays" {
    const optc_kind = findKindIndex("optc") orelse return error.SkipZigTest;
    var buf: [4 * 1024 * 1024]u8 = undefined;

    const svg = compat.generateByName(optc_kind, "013568A,0,2708,2708.svg", &buf);
    try testing.expect(svg.len > 0);
    try testing.expect(std.mem.startsWith(u8, svg, "<?xml version=\"1.0\" encoding=\"utf-8\"?>"));
    try testing.expect(std.mem.indexOf(u8, svg, "stroke-dasharray=\"1.6,0.8\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg, "stroke=\"white\" stroke-width=\"5\" fill=\"transparent\"") != null);
}

test "compat exact match (strict opt-in)" {
    const strict = std.process.getEnvVarOwned(testing.allocator, "LMT_HARMONIOUS_COMPAT_STRICT") catch {
        return error.SkipZigTest;
    };
    defer testing.allocator.free(strict);

    if (!std.mem.eql(u8, strict, "1")) return error.SkipZigTest;

    std.fs.cwd().access("tmp/harmoniousapp.net", .{}) catch return error.SkipZigTest;

    var svg_buf: [4 * 1024 * 1024]u8 = undefined;
    var path_buf: [512]u8 = undefined;

    var kind_index: usize = 0;
    while (kind_index < compat.kindCount()) : (kind_index += 1) {
        const dir = compat.kindDirectory(kind_index).?;
        const count = compat.imageCount(kind_index);

        var image_index: usize = 0;
        while (image_index < count) : (image_index += 1) {
            const image_name = compat.imageName(kind_index, image_index).?;
            const generated = compat.generateByIndex(kind_index, image_index, &svg_buf);

            const path = std.fmt.bufPrint(&path_buf, "tmp/harmoniousapp.net/{s}/{s}", .{ dir, image_name }) catch {
                continue;
            };

            const expected = std.fs.cwd().readFileAlloc(testing.allocator, path, 4 * 1024 * 1024) catch {
                return error.SkipZigTest;
            };
            defer testing.allocator.free(expected);

            if (!std.mem.eql(u8, expected, generated)) {
                const kind_name = compat.kindName(kind_index) orelse "unknown";
                std.debug.print("compat mismatch kind={s} image={s}\n", .{ kind_name, image_name });
                return error.TestExpectedEqual;
            }
        }
    }
}
