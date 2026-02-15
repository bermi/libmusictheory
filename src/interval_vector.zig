const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");

pub const IntervalVector = [6]u8;

pub fn compute(set: pcs.PitchClassSet) IntervalVector {
    var iv: IntervalVector = .{ 0, 0, 0, 0, 0, 0 };

    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    var i: usize = 0;
    while (i < list.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < list.len) : (j += 1) {
            const a = list[i];
            const b = list[j];
            const diff = if (b >= a) b - a else a - b;
            const ic = if (diff <= 6) diff else @as(u4, @intCast(12 - diff));
            if (ic > 0) {
                iv[ic - 1] += 1;
            }
        }
    }

    return iv;
}
