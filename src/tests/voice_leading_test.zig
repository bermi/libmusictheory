const testing = @import("std").testing;

const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const key = @import("../key.zig");
const evenness = @import("../evenness.zig");
const voice_leading = @import("../voice_leading.zig");

test "single voice distance wraps on chromatic circle" {
    try testing.expectEqual(@as(u4, 0), voice_leading.voiceDistance(pitch.pc.C, pitch.pc.C));
    try testing.expectEqual(@as(u4, 1), voice_leading.voiceDistance(pitch.pc.C, pitch.pc.B));
    try testing.expectEqual(@as(u4, 6), voice_leading.voiceDistance(pitch.pc.C, pitch.pc.Fs));
    try testing.expectEqual(@as(u4, 2), voice_leading.voiceDistance(pitch.pc.D, pitch.pc.C));
}

test "vl distance, uncrossed assignments, and cadence size" {
    const g7 = pcs.fromList(&[_]pitch.PitchClass{ 7, 11, 2, 5 });
    const cmaj7 = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 });
    const cadence_distance = voice_leading.vlDistance(g7, cmaj7);
    try testing.expect(cadence_distance >= 2 and cadence_distance <= 3);

    const c_major = pcs.C_MAJOR_TRIAD;
    const g_major = pcs.fromList(&[_]pitch.PitchClass{ 7, 11, 2 });

    var out: [voice_leading.MAX_CARDINALITY]voice_leading.VoiceAssignment = undefined;
    const leadings = voice_leading.uncrossedVoiceLeadings(c_major, g_major, &out);
    try testing.expectEqual(@as(usize, 3), leadings.len);

    var i: usize = 1;
    while (i < leadings.len) : (i += 1) {
        try testing.expect(leadings[i - 1].distance <= leadings[i].distance);
    }
}

test "average vl distance and orbifold radius" {
    const augmented = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });
    const major = pcs.C_MAJOR_TRIAD;

    const avg_aug = voice_leading.avgVLDistance(augmented);
    const avg_maj = voice_leading.avgVLDistance(major);

    try testing.expect(avg_aug < avg_maj);

    const orbifold = voice_leading.orbifoldRadius(major);
    const even = evenness.evennessDistance(major);
    try testing.expectApproxEqAbs(even, orbifold, 0.0001);
}

test "voice-leading graph edges and connectivity" {
    const nodes = [_]pcs.PitchClassSet{
        pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 }),
        pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7 }),
        pcs.fromList(&[_]pitch.PitchClass{ 0, 5, 7 }),
    };

    var edges: [16]voice_leading.VLEdge = undefined;
    const graph = voice_leading.vlGraph(&nodes, &edges);

    try testing.expectEqual(@as(usize, 2), graph.edges.len);
    try testing.expect(voice_leading.graphIsConnected(graph));
}

test "diatonic circuits follow expected degree order" {
    const c_major = key.Key.init(pitch.pc.C, .major);

    const fifths = voice_leading.diatonicFifthsCircuit(c_major);
    const expected_fifths_roots = [_]pitch.PitchClass{
        pitch.pc.B,
        pitch.pc.E,
        pitch.pc.A,
        pitch.pc.D,
        pitch.pc.G,
        pitch.pc.C,
        pitch.pc.F,
    };

    const thirds = voice_leading.diatonicThirdsCircuit(c_major);
    const expected_thirds_roots = [_]pitch.PitchClass{
        pitch.pc.C,
        pitch.pc.A,
        pitch.pc.F,
        pitch.pc.D,
        pitch.pc.B,
        pitch.pc.G,
        pitch.pc.E,
    };

    for (fifths, expected_fifths_roots) |chord, root| {
        try testing.expectEqual(root, chord.root);
    }

    for (thirds, expected_thirds_roots) |chord, root| {
        try testing.expectEqual(root, chord.root);
    }
}
