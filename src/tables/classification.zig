const cluster = @import("../cluster.zig");
const evenness = @import("../evenness.zig");
const set_class = @import("../set_class.zig");
const set_tables = @import("set_classes.zig");

pub const CLUSTER_INFO = cluster.CLUSTER_INFO_TABLE;
pub const EVENNESS_INFO = evenness.EVENNESS_INFO_TABLE;
pub const CLASSIFICATION_FLAGS = buildClassificationFlags();
pub const CLUSTER_FREE_INDICES = buildClusterFreeIndices();

fn buildClassificationFlags() [set_tables.SET_CLASSES.len]set_class.ClassificationFlags {
    @setEvalBranchQuota(2_000_000);

    var out: [set_tables.SET_CLASSES.len]set_class.ClassificationFlags = undefined;

    for (set_tables.SET_CLASSES, 0..) |sc, i| {
        out[i] = .{
            .cluster_free = !CLUSTER_INFO[i].has_cluster,
            .symmetric = sc.flags.symmetric,
            .limited_transposition = sc.flags.limited_transposition,
        };
    }

    return out;
}

fn buildClusterFreeIndices() [124]u16 {
    @setEvalBranchQuota(2_000_000);

    var out: [124]u16 = undefined;
    var count: usize = 0;

    for (CLUSTER_INFO, 0..) |info, i| {
        if (info.has_cluster) continue;
        out[count] = @as(u16, @intCast(i));
        count += 1;
    }

    if (count != out.len) {
        @compileError("Expected exactly 124 cluster-free set classes");
    }

    return out;
}
