const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const evenness = @import("evenness.zig");
const key = @import("key.zig");
const harmony = @import("harmony.zig");

pub const MAX_CARDINALITY: usize = 9;
const MAX_GRAPH_NODES: usize = 256;

pub const VoiceAssignment = struct {
    from_pcs: [MAX_CARDINALITY]pitch.PitchClass,
    to_pcs: [MAX_CARDINALITY]pitch.PitchClass,
    cardinality: u4,
    distance: u8,
};

pub const VLEdge = struct {
    from_idx: u16,
    to_idx: u16,
    distance: u8,
};

pub const VLGraph = struct {
    nodes: []const pcs.PitchClassSet,
    edges: []VLEdge,
};

pub fn voiceDistance(a: pitch.PitchClass, b: pitch.PitchClass) u4 {
    const diff = if (a > b) a - b else b - a;
    const wrap = @as(u4, @intCast(12 - diff));
    return if (diff <= wrap) diff else wrap;
}

pub fn vlDistance(from: pcs.PitchClassSet, to: pcs.PitchClassSet) u8 {
    var from_buf: [12]pitch.PitchClass = undefined;
    var to_buf: [12]pitch.PitchClass = undefined;
    const from_list = pcs.toList(from, &from_buf);
    const to_list = pcs.toList(to, &to_buf);

    std.debug.assert(from_list.len == to_list.len);
    if (from_list.len == 0) return 0;
    std.debug.assert(from_list.len <= MAX_CARDINALITY);

    if (from_list.len <= 5) {
        return bruteForceDistance(from_list, to_list);
    }
    return hungarianDistance(from_list, to_list);
}

pub fn uncrossedVoiceLeadings(from: pcs.PitchClassSet, to: pcs.PitchClassSet, out: *[MAX_CARDINALITY]VoiceAssignment) []VoiceAssignment {
    var from_buf: [12]pitch.PitchClass = undefined;
    var to_buf: [12]pitch.PitchClass = undefined;
    const from_list = pcs.toList(from, &from_buf);
    const to_list = pcs.toList(to, &to_buf);

    std.debug.assert(from_list.len == to_list.len);
    std.debug.assert(from_list.len <= MAX_CARDINALITY);

    const n = from_list.len;
    var r: usize = 0;
    while (r < n) : (r += 1) {
        var assignment = VoiceAssignment{
            .from_pcs = [_]pitch.PitchClass{0} ** MAX_CARDINALITY,
            .to_pcs = [_]pitch.PitchClass{0} ** MAX_CARDINALITY,
            .cardinality = @as(u4, @intCast(n)),
            .distance = 0,
        };

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const from_pc = from_list[i];
            const to_pc = to_list[(i + r) % n];
            assignment.from_pcs[i] = from_pc;
            assignment.to_pcs[i] = to_pc;
            assignment.distance += voiceDistance(from_pc, to_pc);
        }

        out[r] = assignment;
    }

    sortAssignmentsByDistance(out[0..n]);
    return out[0..n];
}

pub fn avgVLDistance(set: pcs.PitchClassSet) f32 {
    if (pcs.cardinality(set) == 0) return 0;

    var total: f32 = 0;
    var semitones: u4 = 1;
    while (semitones < 12) : (semitones += 1) {
        const transposed = pcs.transpose(set, semitones);
        total += @as(f32, @floatFromInt(vlDistance(set, transposed)));
    }

    return total / 11.0;
}

pub fn vlGraph(nodes: []const pcs.PitchClassSet, edge_buf: []VLEdge) VLGraph {
    var edge_count: usize = 0;

    var i: usize = 0;
    while (i < nodes.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < nodes.len) : (j += 1) {
            if (pcs.cardinality(nodes[i]) != pcs.cardinality(nodes[j])) continue;

            const dist = vlDistance(nodes[i], nodes[j]);
            if (dist == 1) {
                std.debug.assert(edge_count < edge_buf.len);
                edge_buf[edge_count] = .{
                    .from_idx = @as(u16, @intCast(i)),
                    .to_idx = @as(u16, @intCast(j)),
                    .distance = dist,
                };
                edge_count += 1;
            }
        }
    }

    return .{
        .nodes = nodes,
        .edges = edge_buf[0..edge_count],
    };
}

pub fn graphIsConnected(graph: VLGraph) bool {
    if (graph.nodes.len <= 1) return true;
    if (graph.nodes.len > MAX_GRAPH_NODES) return false;

    var visited: [MAX_GRAPH_NODES]bool = [_]bool{false} ** MAX_GRAPH_NODES;
    var queue: [MAX_GRAPH_NODES]u16 = [_]u16{0} ** MAX_GRAPH_NODES;

    var head: usize = 0;
    var tail: usize = 0;

    visited[0] = true;
    queue[tail] = 0;
    tail += 1;

    while (head < tail) : (head += 1) {
        const node = queue[head];

        for (graph.edges) |edge| {
            var next: ?u16 = null;
            if (edge.from_idx == node) {
                next = edge.to_idx;
            } else if (edge.to_idx == node) {
                next = edge.from_idx;
            }

            if (next) |idx| {
                if (!visited[idx]) {
                    visited[idx] = true;
                    queue[tail] = idx;
                    tail += 1;
                }
            }
        }
    }

    var i: usize = 0;
    while (i < graph.nodes.len) : (i += 1) {
        if (!visited[i]) return false;
    }
    return true;
}

pub fn diatonicFifthsCircuit(k: key.Key) [7]harmony.ChordInstance {
    var out: [7]harmony.ChordInstance = undefined;
    for (harmony.CIRCLE_OF_FIFTHS_DEGREES, 0..) |degree, i| {
        out[i] = harmony.diatonicTriad(k, degree);
    }
    return out;
}

pub fn diatonicThirdsCircuit(k: key.Key) [7]harmony.ChordInstance {
    var out: [7]harmony.ChordInstance = undefined;
    for (harmony.CIRCLE_OF_THIRDS_DEGREES, 0..) |degree, i| {
        out[i] = harmony.diatonicTriad(k, degree);
    }
    return out;
}

pub fn orbifoldRadius(set: pcs.PitchClassSet) f32 {
    return evenness.evennessDistance(set);
}

fn bruteForceDistance(from_list: []const pitch.PitchClass, to_list: []const pitch.PitchClass) u8 {
    var used: [MAX_CARDINALITY]bool = [_]bool{false} ** MAX_CARDINALITY;
    var best: u8 = std.math.maxInt(u8);

    permuteDistance(from_list, to_list, &used, 0, 0, &best);
    return best;
}

fn permuteDistance(from_list: []const pitch.PitchClass, to_list: []const pitch.PitchClass, used: *[MAX_CARDINALITY]bool, index: usize, current_distance: u8, best: *u8) void {
    if (current_distance >= best.*) return;

    if (index == from_list.len) {
        if (current_distance < best.*) {
            best.* = current_distance;
        }
        return;
    }

    var j: usize = 0;
    while (j < to_list.len) : (j += 1) {
        if (used[j]) continue;

        used[j] = true;
        const step = voiceDistance(from_list[index], to_list[j]);
        permuteDistance(from_list, to_list, used, index + 1, current_distance + step, best);
        used[j] = false;
    }
}

fn hungarianDistance(from_list: []const pitch.PitchClass, to_list: []const pitch.PitchClass) u8 {
    const n = from_list.len;
    std.debug.assert(n == to_list.len);
    std.debug.assert(n <= MAX_CARDINALITY);

    var cost: [MAX_CARDINALITY][MAX_CARDINALITY]i16 = [_][MAX_CARDINALITY]i16{[_]i16{0} ** MAX_CARDINALITY} ** MAX_CARDINALITY;

    var i: usize = 0;
    while (i < n) : (i += 1) {
        var j: usize = 0;
        while (j < n) : (j += 1) {
            cost[i][j] = @as(i16, @intCast(voiceDistance(from_list[i], to_list[j])));
        }
    }

    var u: [MAX_CARDINALITY + 1]i16 = [_]i16{0} ** (MAX_CARDINALITY + 1);
    var v: [MAX_CARDINALITY + 1]i16 = [_]i16{0} ** (MAX_CARDINALITY + 1);
    var p: [MAX_CARDINALITY + 1]usize = [_]usize{0} ** (MAX_CARDINALITY + 1);
    var way: [MAX_CARDINALITY + 1]usize = [_]usize{0} ** (MAX_CARDINALITY + 1);

    var row: usize = 1;
    while (row <= n) : (row += 1) {
        p[0] = row;

        var minv: [MAX_CARDINALITY + 1]i16 = [_]i16{std.math.maxInt(i16)} ** (MAX_CARDINALITY + 1);
        var used: [MAX_CARDINALITY + 1]bool = [_]bool{false} ** (MAX_CARDINALITY + 1);

        var col0: usize = 0;
        while (true) {
            used[col0] = true;
            const row0 = p[col0];

            var delta: i16 = std.math.maxInt(i16);
            var col1: usize = 0;

            var col: usize = 1;
            while (col <= n) : (col += 1) {
                if (used[col]) continue;

                const cur = cost[row0 - 1][col - 1] - u[row0] - v[col];
                if (cur < minv[col]) {
                    minv[col] = cur;
                    way[col] = col0;
                }

                if (minv[col] < delta) {
                    delta = minv[col];
                    col1 = col;
                }
            }

            var k: usize = 0;
            while (k <= n) : (k += 1) {
                if (used[k]) {
                    u[p[k]] += delta;
                    v[k] -= delta;
                } else {
                    minv[k] -= delta;
                }
            }

            col0 = col1;
            if (p[col0] == 0) break;
        }

        while (true) {
            const col1 = way[col0];
            p[col0] = p[col1];
            col0 = col1;
            if (col0 == 0) break;
        }
    }

    var assignment: [MAX_CARDINALITY]usize = [_]usize{0} ** MAX_CARDINALITY;
    var col: usize = 1;
    while (col <= n) : (col += 1) {
        assignment[p[col] - 1] = col - 1;
    }

    var total: u8 = 0;
    var r: usize = 0;
    while (r < n) : (r += 1) {
        total += @as(u8, @intCast(cost[r][assignment[r]]));
    }

    return total;
}

fn sortAssignmentsByDistance(assignments: []VoiceAssignment) void {
    var i: usize = 0;
    while (i < assignments.len) : (i += 1) {
        var best_i = i;

        var j: usize = i + 1;
        while (j < assignments.len) : (j += 1) {
            if (assignments[j].distance < assignments[best_i].distance) {
                best_i = j;
            }
        }

        if (best_i != i) {
            const tmp = assignments[i];
            assignments[i] = assignments[best_i];
            assignments[best_i] = tmp;
        }
    }
}
