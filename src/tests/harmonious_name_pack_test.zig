const std = @import("std");
const testing = std.testing;

const name_pack = @import("../harmonious_name_pack.zig");
const pack_data = @import("../generated/harmonious_name_pack_xz.zig");

test "harmonious name pack decodes and enumerates all names" {
    try testing.expectEqual(pack_data.KIND_COUNT, name_pack.kindCount());

    var total_names: usize = 0;
    var kind_index: usize = 0;
    while (kind_index < name_pack.kindCount()) : (kind_index += 1) {
        const count = name_pack.imageCount(kind_index);
        total_names += count;

        if (count == 0) {
            try testing.expect(name_pack.imageName(kind_index, 0) == null);
            continue;
        }

        const first = name_pack.imageName(kind_index, 0) orelse return error.TestUnexpectedResult;
        const last = name_pack.imageName(kind_index, count - 1) orelse return error.TestUnexpectedResult;
        try testing.expect(std.mem.endsWith(u8, first, ".svg"));
        try testing.expect(std.mem.endsWith(u8, last, ".svg"));
        try testing.expect(name_pack.imageName(kind_index, count) == null);
    }

    try testing.expectEqual(pack_data.TOTAL_NAME_COUNT, total_names);
}

test "harmonious name pack kind counts match generation metadata" {
    var i: usize = 0;
    while (i < pack_data.KIND_COUNT) : (i += 1) {
        try testing.expectEqual(
            @as(usize, @intCast(pack_data.KIND_IMAGE_COUNTS[i])),
            name_pack.imageCount(i),
        );
    }
}
