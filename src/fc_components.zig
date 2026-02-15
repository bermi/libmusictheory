const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");

pub const FCComponents = [6]f32;

pub fn compute(set: pcs.PitchClassSet) FCComponents {
    var out: FCComponents = .{ 0, 0, 0, 0, 0, 0 };

    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    var k: u8 = 1;
    while (k <= 6) : (k += 1) {
        var sum_x: f64 = 0.0;
        var sum_y: f64 = 0.0;

        for (list) |pc| {
            const angle = @as(f64, @floatFromInt(pc)) * @as(f64, @floatFromInt(k)) * (std.math.pi / 6.0);
            sum_x += std.math.cos(angle);
            sum_y += std.math.sin(angle);
        }

        out[k - 1] = @as(f32, @floatCast(std.math.sqrt(sum_x * sum_x + sum_y * sum_y)));
    }

    return out;
}
