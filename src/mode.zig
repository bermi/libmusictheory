const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const scale = @import("scale.zig");

pub const ModeType = enum {
    ionian,
    dorian,
    phrygian,
    lydian,
    mixolydian,
    aeolian,
    locrian,
    melodic_minor,
    dorian_b2,
    lydian_aug,
    lydian_dom,
    mixolydian_b6,
    locrian_nat2,
    super_locrian,
    half_whole,
    whole_half,
    whole_tone,
};

pub const ModeInfo = struct {
    id: ModeType,
    name: []const u8,
    parent_scale: scale.ScaleType,
    degree: u4,
    pcs: pcs.PitchClassSet,
};

pub const ALL_MODES = [_]ModeInfo{
    .{ .id = .ionian, .name = "Ionian", .parent_scale = .diatonic, .degree = 0, .pcs = rootedMode(scale.DIATONIC, 0) },
    .{ .id = .dorian, .name = "Dorian", .parent_scale = .diatonic, .degree = 1, .pcs = rootedMode(scale.DIATONIC, 1) },
    .{ .id = .phrygian, .name = "Phrygian", .parent_scale = .diatonic, .degree = 2, .pcs = rootedMode(scale.DIATONIC, 2) },
    .{ .id = .lydian, .name = "Lydian", .parent_scale = .diatonic, .degree = 3, .pcs = rootedMode(scale.DIATONIC, 3) },
    .{ .id = .mixolydian, .name = "Mixolydian", .parent_scale = .diatonic, .degree = 4, .pcs = rootedMode(scale.DIATONIC, 4) },
    .{ .id = .aeolian, .name = "Aeolian", .parent_scale = .diatonic, .degree = 5, .pcs = rootedMode(scale.DIATONIC, 5) },
    .{ .id = .locrian, .name = "Locrian", .parent_scale = .diatonic, .degree = 6, .pcs = rootedMode(scale.DIATONIC, 6) },

    .{ .id = .melodic_minor, .name = "Melodic Minor", .parent_scale = .acoustic, .degree = 0, .pcs = rootedMode(scale.ACOUSTIC, 0) },
    .{ .id = .dorian_b2, .name = "Dorian b2", .parent_scale = .acoustic, .degree = 1, .pcs = rootedMode(scale.ACOUSTIC, 1) },
    .{ .id = .lydian_aug, .name = "Lydian Aug", .parent_scale = .acoustic, .degree = 2, .pcs = rootedMode(scale.ACOUSTIC, 2) },
    .{ .id = .lydian_dom, .name = "Lydian Dom", .parent_scale = .acoustic, .degree = 3, .pcs = rootedMode(scale.ACOUSTIC, 3) },
    .{ .id = .mixolydian_b6, .name = "Mixolydian b6", .parent_scale = .acoustic, .degree = 4, .pcs = rootedMode(scale.ACOUSTIC, 4) },
    .{ .id = .locrian_nat2, .name = "Locrian nat2", .parent_scale = .acoustic, .degree = 5, .pcs = rootedMode(scale.ACOUSTIC, 5) },
    .{ .id = .super_locrian, .name = "Super Locrian", .parent_scale = .acoustic, .degree = 6, .pcs = rootedMode(scale.ACOUSTIC, 6) },

    .{ .id = .half_whole, .name = "Half-Whole", .parent_scale = .diminished, .degree = 0, .pcs = rootedMode(scale.DIMINISHED, 0) },
    .{ .id = .whole_half, .name = "Whole-Half", .parent_scale = .diminished, .degree = 1, .pcs = rootedMode(scale.DIMINISHED, 1) },

    .{ .id = .whole_tone, .name = "Whole-Tone", .parent_scale = .whole_tone, .degree = 0, .pcs = rootedMode(scale.WHOLE_TONE, 0) },
};

pub fn identifyMode(rooted_set: pcs.PitchClassSet) ?ModeType {
    for (ALL_MODES) |m| {
        if (m.pcs == rooted_set) {
            return m.id;
        }
    }
    return null;
}

fn rootedMode(parent: pcs.PitchClassSet, degree: u4) pcs.PitchClassSet {
    var list_buf: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(parent, &list_buf);
    const root_pc = list[degree];
    return pcs.transposeDown(parent, root_pc);
}
