const std = @import("std");
const geometry = @import("../svg/majmin_scales_geometry.zig");

test "majmin scales geometry slot table is complete and stable" {
    try std.testing.expectEqual(@as(usize, 76), geometry.SCALE_GEOMETRY_PATH_COUNT);
    try std.testing.expectEqual(@as(usize, 19), geometry.SCALE_GEOMETRY_CLUSTER_COUNT);
    try std.testing.expectEqual(@as(usize, 4), geometry.SCALE_GEOMETRY_SHAPES_PER_CLUSTER);
    try std.testing.expectEqual(@as(f64, 27.2), geometry.SCALE_GEOMETRY_STEP_X);
    try std.testing.expectEqual(@as(f64, 47.11178196587346), geometry.SCALE_GEOMETRY_STEP_Y);

    var buf: [512]u8 = undefined;
    var i: usize = 0;
    while (i < geometry.SCALE_GEOMETRY_PATH_COUNT) : (i += 1) {
        const path_d = geometry.pathForSlot(i, buf[0..]) orelse unreachable;
        try std.testing.expect(path_d.len > 0);
    }

    try std.testing.expect(geometry.pathForSlot(geometry.SCALE_GEOMETRY_PATH_COUNT, buf[0..]) == null);
    try std.testing.expectEqualStrings(
        "M245,-79.22356393174692 L299.4,-79.22356393174692 L326.6,-32.11178196587346 L299.4,15 L245,15 L217.8,-32.11178196587346  z",
        geometry.pathForSlot(0, buf[0..]).?,
    );
    try std.testing.expectEqualStrings(
        "M27.400000000000006,391.8942557269877 L0.20000000000000995,344.78247376111426 L54.60000000000001,344.78247376111426  z",
        geometry.pathForSlot(75, buf[0..]).?,
    );
}
