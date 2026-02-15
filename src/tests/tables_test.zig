const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const interval_vector = @import("../interval_vector.zig");
const fc_components = @import("../fc_components.zig");
const cluster = @import("../cluster.zig");
const evenness = @import("../evenness.zig");
const scale = @import("../scale.zig");
const mode = @import("../mode.zig");
const key = @import("../key.zig");
const note_spelling = @import("../note_spelling.zig");
const chord_type = @import("../chord_type.zig");
const harmony = @import("../harmony.zig");
const slider = @import("../slider.zig");
const tables = @import("../tables.zig");

test "set class tables match runtime computation" {
    try testing.expectEqual(set_class.SET_CLASSES.len, tables.set_classes.SET_CLASSES.len);

    for (tables.set_classes.SET_CLASSES, 0..) |sc, i| {
        try testing.expectEqual(sc.pcs, set_class.SET_CLASSES[i].pcs);
        try testing.expectEqual(sc.forte_number, tables.set_classes.FORTE_MAP[i]);

        const comp_idx = tables.set_classes.COMPLEMENT_MAP[i];
        try testing.expect(comp_idx < tables.set_classes.SET_CLASSES.len);
        const complement_prime = set_class.fortePrime(pcs.complement(sc.pcs));
        try testing.expectEqual(complement_prime, tables.set_classes.SET_CLASSES[comp_idx].pcs);

        const inv_idx = tables.set_classes.INVOLUTION_MAP[i];
        try testing.expect(inv_idx < tables.set_classes.SET_CLASSES.len);
        const involution_prime = set_class.fortePrime(pcs.invert(sc.pcs));
        try testing.expectEqual(involution_prime, tables.set_classes.SET_CLASSES[inv_idx].pcs);
    }
}

test "interval and fc tables match runtime computation" {
    for (tables.set_classes.SET_CLASSES, 0..) |sc, i| {
        const iv = interval_vector.compute(sc.pcs);
        try testing.expectEqual(iv, tables.intervals.INTERVAL_VECTORS[i]);

        const fc = fc_components.compute(sc.pcs);
        const cached_fc = tables.intervals.FC_COMPONENTS[i];

        var k: usize = 0;
        while (k < fc.len) : (k += 1) {
            try testing.expectApproxEqAbs(fc[k], cached_fc[k], 0.0001);
        }
    }
}

test "classification tables and cluster-free index list are consistent" {
    try testing.expectEqual(@as(usize, tables.set_classes.SET_CLASSES.len), tables.classification.CLUSTER_INFO.len);
    try testing.expectEqual(@as(usize, tables.set_classes.SET_CLASSES.len), tables.classification.EVENNESS_INFO.len);
    try testing.expectEqual(@as(usize, tables.set_classes.SET_CLASSES.len), tables.classification.CLASSIFICATION_FLAGS.len);
    try testing.expectEqual(@as(usize, 124), tables.classification.CLUSTER_FREE_INDICES.len);

    for (tables.set_classes.SET_CLASSES, 0..) |sc, i| {
        const runtime_cluster = cluster.getClusters(sc.pcs);
        const table_cluster = tables.classification.CLUSTER_INFO[i];
        try testing.expectEqual(runtime_cluster.has_cluster, table_cluster.has_cluster);
        try testing.expectEqual(runtime_cluster.cluster_mask, table_cluster.cluster_mask);
        try testing.expectEqual(runtime_cluster.run_count, table_cluster.run_count);
        try testing.expectEqualSlices(
            u4,
            runtime_cluster.runs[0..runtime_cluster.run_count],
            table_cluster.runs[0..table_cluster.run_count],
        );
        const even = tables.classification.EVENNESS_INFO[i];
        try testing.expectApproxEqAbs(evenness.evennessDistance(sc.pcs), even.distance, 0.0001);

        const flags = tables.classification.CLASSIFICATION_FLAGS[i];
        try testing.expectEqual(!cluster.hasCluster(sc.pcs), flags.cluster_free);
        try testing.expectEqual(sc.flags.symmetric, flags.symmetric);
        try testing.expectEqual(sc.flags.limited_transposition, flags.limited_transposition);
    }

    for (tables.classification.CLUSTER_FREE_INDICES) |idx| {
        try testing.expect(!tables.classification.CLUSTER_INFO[idx].has_cluster);
    }
}

test "scale and mode tables expose stable constants" {
    try testing.expectEqual(@as(usize, 7), tables.scales.SCALE_TYPE_PCS.len);
    try testing.expectEqual(scale.pcsForType(.diatonic), tables.scales.SCALE_TYPE_PCS[0]);
    try testing.expectEqual(scale.pcsForType(.whole_tone), tables.scales.SCALE_TYPE_PCS[3]);

    try testing.expectEqual(@as(usize, mode.ALL_MODES.len), tables.scales.MODE_TYPES.len);
    for (mode.ALL_MODES, 0..) |m, i| {
        try testing.expectEqual(m.id, tables.scales.MODE_TYPES[i]);
    }

    try testing.expectEqual(@as(usize, 24), tables.scales.KEY_SPELLING_MAPS.len);

    const c_major_map = findKeyMap(0, .major);
    try testing.expectEqual(note_spelling.spellNote(1, key.Key.init(0, .major)), c_major_map.names[1]);

    const f_major_map = findKeyMap(5, .major);
    try testing.expectEqual(note_spelling.spellNote(10, key.Key.init(5, .major)), f_major_map.names[10]);
}

test "chord compatibility table dimensions and spot checks" {
    try testing.expectEqual(@as(usize, chord_type.ALL.len), tables.chords.CHORD_TYPES.len);

    const expected_count = chord_type.ALL.len * 12 * mode.ALL_MODES.len;
    try testing.expectEqual(@as(usize, expected_count), tables.chords.GAME_RESULTS.len);

    const c_ionian = findGameResult(0, 0, .ionian);
    try testing.expect(c_ionian.compatible);

    const c_locrian = findGameResult(0, 0, .locrian);
    const chord_instance = harmony.ChordInstance{ .root = 0, .pcs = pcs.fromList(&[_]u4{ 0, 4, 7 }), .quality = .unknown, .degree = 0 };
    const mode_ctx = harmony.ModeContext{ .root = 0, .pcs = pcs.fromList(&[_]u4{ 0, 1, 3, 5, 6, 8, 10 }) };
    const runtime_match = harmony.chordScaleCompatibility(chord_instance, mode_ctx);
    try testing.expectEqual(runtime_match.compatible, c_locrian.compatible);
}

test "color tables and memory budget" {
    try testing.expectEqual(@as(usize, 12), tables.colors.PC_COLORS.len);
    try testing.expectEqual(@as(usize, 6), tables.colors.IC_COLORS.len);
    try testing.expectEqualSlices(u4, &slider.COLOR_INDEX, &tables.colors.COLOR_INDEX);

    const total_table_bytes =
        @sizeOf(@TypeOf(tables.set_classes.SET_CLASSES)) +
        @sizeOf(@TypeOf(tables.set_classes.FORTE_MAP)) +
        @sizeOf(@TypeOf(tables.set_classes.COMPLEMENT_MAP)) +
        @sizeOf(@TypeOf(tables.set_classes.INVOLUTION_MAP)) +
        @sizeOf(@TypeOf(tables.intervals.INTERVAL_VECTORS)) +
        @sizeOf(@TypeOf(tables.intervals.FC_COMPONENTS)) +
        @sizeOf(@TypeOf(tables.classification.CLUSTER_INFO)) +
        @sizeOf(@TypeOf(tables.classification.EVENNESS_INFO)) +
        @sizeOf(@TypeOf(tables.classification.CLASSIFICATION_FLAGS)) +
        @sizeOf(@TypeOf(tables.classification.CLUSTER_FREE_INDICES)) +
        @sizeOf(@TypeOf(tables.scales.SCALE_TYPE_PCS)) +
        @sizeOf(@TypeOf(tables.scales.MODE_TYPES)) +
        @sizeOf(@TypeOf(tables.scales.KEY_SPELLING_MAPS)) +
        @sizeOf(@TypeOf(tables.chords.CHORD_TYPES)) +
        @sizeOf(@TypeOf(tables.chords.GAME_RESULTS)) +
        @sizeOf(@TypeOf(tables.colors.PC_COLORS)) +
        @sizeOf(@TypeOf(tables.colors.IC_COLORS)) +
        @sizeOf(@TypeOf(tables.colors.COLOR_INDEX));

    try testing.expect(total_table_bytes <= 50 * 1024);
}

fn findKeyMap(tonic: u4, quality: key.KeyQuality) tables.scales.KeySpellingMap {
    for (tables.scales.KEY_SPELLING_MAPS) |m| {
        if (m.tonic == tonic and m.quality == quality) return m;
    }
    unreachable;
}

fn findGameResult(chord_type_index: u8, root: u4, mode_type: mode.ModeType) tables.chords.GameResult {
    for (tables.chords.GAME_RESULTS) |result| {
        if (result.chord_type_index == chord_type_index and result.root == root and result.mode_type == mode_type) {
            return result;
        }
    }
    unreachable;
}
