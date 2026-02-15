const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const set_class = @import("../set_class.zig");
const cluster = @import("../cluster.zig");
const evenness = @import("../evenness.zig");

test "cluster-free set class count" {
    var count: u16 = 0;
    for (set_class.SET_CLASSES) |sc| {
        if (!cluster.hasCluster(sc.pcs)) {
            count += 1;
        }
    }

    try testing.expectEqual(@as(u16, 124), count);
}

test "known cluster free and containing sets" {
    try testing.expect(!cluster.hasCluster(pcs.C_MAJOR_TRIAD));
    try testing.expect(!cluster.hasCluster(pcs.C_MINOR_TRIAD));
    try testing.expect(!cluster.hasCluster(pcs.DIATONIC));
    try testing.expect(!cluster.hasCluster(pcs.C_MAJOR_PENTATONIC));

    const chromatic_cluster = pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 2 });
    try testing.expect(cluster.hasCluster(chromatic_cluster));
    try testing.expect(cluster.hasCluster(pcs.CHROMATIC));
}

test "perfectly even sets have zero distance" {
    const tritone = pcs.fromList(&[_]pitch.PitchClass{ 0, 6 });
    const augmented = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });
    const diminished_seventh = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 9 });
    const whole_tone = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 6, 8, 10 });

    try testing.expectApproxEqAbs(@as(f32, 0.0), evenness.evennessDistance(tritone), 0.00001);
    try testing.expectApproxEqAbs(@as(f32, 0.0), evenness.evennessDistance(augmented), 0.00001);
    try testing.expectApproxEqAbs(@as(f32, 0.0), evenness.evennessDistance(diminished_seventh), 0.00001);
    try testing.expectApproxEqAbs(@as(f32, 0.0), evenness.evennessDistance(whole_tone), 0.00001);

    try testing.expect(evenness.isPerfectlyEven(tritone));
    try testing.expect(evenness.isPerfectlyEven(augmented));
    try testing.expect(evenness.isPerfectlyEven(diminished_seventh));
    try testing.expect(evenness.isPerfectlyEven(whole_tone));
}

test "maximally even sets" {
    const pentatonic = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 4, 7, 9 });
    const diatonic = pcs.DIATONIC;
    const octatonic = pcs.fromList(&[_]pitch.PitchClass{ 0, 2, 3, 5, 6, 8, 9, 11 });

    try testing.expect(evenness.isMaximallyEven(pentatonic));
    try testing.expect(evenness.isMaximallyEven(diatonic));
    try testing.expect(evenness.isMaximallyEven(octatonic));
}

test "precomputed tables and consonance" {
    try testing.expectEqual(set_class.SET_CLASSES.len, cluster.CLUSTER_INFO_TABLE.len);
    try testing.expectEqual(set_class.SET_CLASSES.len, evenness.EVENNESS_INFO_TABLE.len);

    const triad_score = evenness.consonanceScore(pcs.C_MAJOR_TRIAD);
    const cluster_score = evenness.consonanceScore(pcs.fromList(&[_]pitch.PitchClass{ 0, 1, 2 }));
    try testing.expect(triad_score > cluster_score);
}
