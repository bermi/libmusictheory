const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");

pub const ClusterInfo = struct {
    has_cluster: bool,
    cluster_mask: pcs.PitchClassSet,
    run_count: u4,
    runs: [12]u4,
};

pub const CLUSTER_INFO_TABLE = buildClusterInfoTable();

pub fn hasCluster(set: pcs.PitchClassSet) bool {
    const base = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 2 });
    var t: u4 = 0;
    while (t < 12) : (t += 1) {
        if (pcs.isSubsetOf(pcs.transpose(base, t), set)) {
            return true;
        }
    }
    return false;
}

pub fn getClusters(set: pcs.PitchClassSet) ClusterInfo {
    var remaining = set;
    var mask: pcs.PitchClassSet = 0;

    while (true) {
        var found = false;
        for (CLUSTER_CANDIDATES) |candidate| {
            if (pcs.isSubsetOf(candidate, remaining)) {
                mask |= candidate;
                remaining ^= candidate;
                found = true;
                break;
            }
        }

        if (!found) break;
    }

    var runs: [12]u4 = undefined;
    const run_slice = clusterStats(mask, &runs);

    return .{
        .has_cluster = mask != 0,
        .cluster_mask = mask,
        .run_count = @as(u4, @intCast(run_slice.len)),
        .runs = runs,
    };
}

pub fn clusterStats(set: pcs.PitchClassSet, out: *[12]u4) []u4 {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(set, &list_buf);

    if (list.len == 0) return out[0..0];

    var count: usize = 0;
    var run_len: u4 = 1;

    var i: usize = 1;
    while (i < list.len) : (i += 1) {
        if (list[i] == list[i - 1] + 1) {
            run_len += 1;
        } else {
            if (run_len >= 3) {
                out[count] = run_len;
                count += 1;
            }
            run_len = 1;
        }
    }

    if (run_len >= 3) {
        out[count] = run_len;
        count += 1;
    }

    const wraps = list.len >= 2 and list[0] == 0 and list[list.len - 1] == 11;
    if (wraps and count >= 2) {
        const first = out[0];
        const last = out[count - 1];
        out[0] = first + last;
        count -= 1;
    }

    return out[0..count];
}

fn buildClusterInfoTable() [set_class.SET_CLASSES.len]ClusterInfo {
    @setEvalBranchQuota(2_000_000);

    var out: [set_class.SET_CLASSES.len]ClusterInfo = undefined;
    for (set_class.SET_CLASSES, 0..) |sc, i| {
        out[i] = getClusters(sc.pcs);
    }
    return out;
}

const CLUSTER_CANDIDATES = buildClusterCandidates();

fn buildClusterCandidates() [84]pcs.PitchClassSet {
    @setEvalBranchQuota(2_000_000);

    var out: [84]pcs.PitchClassSet = undefined;
    var idx: usize = 0;

    var length: u4 = 9;
    while (length >= 3) : (length -= 1) {
        var base_list: [9]pitch.PitchClass = undefined;
        var i: usize = 0;
        while (i < length) : (i += 1) {
            base_list[i] = @as(pitch.PitchClass, @intCast(i));
        }

        const base = pcs.fromList(base_list[0..length]);
        var t: u4 = 0;
        while (t < 12) : (t += 1) {
            out[idx] = pcs.transpose(base, t);
            idx += 1;
        }

        if (length == 3) break;
    }

    return out;
}
