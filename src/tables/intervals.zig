const interval_vector = @import("../interval_vector.zig");
const fc_components = @import("../fc_components.zig");
const set_tables = @import("set_classes.zig");

pub const INTERVAL_VECTORS = buildIntervalVectors();
pub const FC_COMPONENTS = buildFCComponents();

fn buildIntervalVectors() [set_tables.SET_CLASSES.len]interval_vector.IntervalVector {
    @setEvalBranchQuota(2_000_000);

    var out: [set_tables.SET_CLASSES.len]interval_vector.IntervalVector = undefined;
    for (set_tables.SET_CLASSES, 0..) |sc, i| {
        out[i] = interval_vector.compute(sc.pcs);
    }
    return out;
}

fn buildFCComponents() [set_tables.SET_CLASSES.len]fc_components.FCComponents {
    @setEvalBranchQuota(2_000_000);

    var out: [set_tables.SET_CLASSES.len]fc_components.FCComponents = undefined;
    for (set_tables.SET_CLASSES, 0..) |sc, i| {
        out[i] = fc_components.compute(sc.pcs);
    }
    return out;
}
