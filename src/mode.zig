const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const ordered_scale = @import("ordered_scale.zig");

pub const ModeType = enum(u8) {
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
    harmonic_minor,
    locrian_nat6,
    ionian_aug,
    dorian_sharp4,
    phrygian_dominant,
    lydian_sharp2,
    super_locrian_dim,
    half_whole,
    whole_half,
    whole_tone,
    double_harmonic,
    hungarian_minor,
    enigmatic,
    neapolitan_minor,
    neapolitan_major,
};

pub const ModeInfo = struct {
    id: ModeType,
    name: []const u8,
    family: ordered_scale.Family,
    parent_pattern: ordered_scale.PatternId,
    degree: u4,
    pcs: pcs.PitchClassSet,
};

pub const ALL_MODES = [_]ModeInfo{
    makeMode(.ionian, "Ionian", .diatonic, 0),
    makeMode(.dorian, "Dorian", .diatonic, 1),
    makeMode(.phrygian, "Phrygian", .diatonic, 2),
    makeMode(.lydian, "Lydian", .diatonic, 3),
    makeMode(.mixolydian, "Mixolydian", .diatonic, 4),
    makeMode(.aeolian, "Aeolian", .diatonic, 5),
    makeMode(.locrian, "Locrian", .diatonic, 6),

    makeMode(.melodic_minor, "Melodic Minor", .melodic_minor, 0),
    makeMode(.dorian_b2, "Dorian b2", .melodic_minor, 1),
    makeMode(.lydian_aug, "Lydian Aug", .melodic_minor, 2),
    makeMode(.lydian_dom, "Lydian Dom", .melodic_minor, 3),
    makeMode(.mixolydian_b6, "Mixolydian b6", .melodic_minor, 4),
    makeMode(.locrian_nat2, "Locrian nat2", .melodic_minor, 5),
    makeMode(.super_locrian, "Super Locrian", .melodic_minor, 6),

    makeMode(.harmonic_minor, "Harmonic Minor", .harmonic_minor, 0),
    makeMode(.locrian_nat6, "Locrian nat6", .harmonic_minor, 1),
    makeMode(.ionian_aug, "Ionian Aug", .harmonic_minor, 2),
    makeMode(.dorian_sharp4, "Dorian #4", .harmonic_minor, 3),
    makeMode(.phrygian_dominant, "Phrygian Dominant", .harmonic_minor, 4),
    makeMode(.lydian_sharp2, "Lydian #2", .harmonic_minor, 5),
    makeMode(.super_locrian_dim, "Super Locrian Dim", .harmonic_minor, 6),

    makeMode(.half_whole, "Half-Whole", .diminished, 0),
    makeMode(.whole_half, "Whole-Half", .diminished, 1),
    makeMode(.whole_tone, "Whole-Tone", .whole_tone, 0),

    makeMode(.double_harmonic, "Double Harmonic", .double_harmonic, 0),
    makeMode(.hungarian_minor, "Hungarian Minor", .hungarian_minor, 0),
    makeMode(.enigmatic, "Enigmatic", .enigmatic, 0),
    makeMode(.neapolitan_minor, "Neapolitan Minor", .neapolitan_minor, 0),
    makeMode(.neapolitan_major, "Neapolitan Major", .neapolitan_major, 0),
};

pub fn identifyMode(rooted_set: pcs.PitchClassSet) ?ModeType {
    for (ALL_MODES) |m| {
        if (m.pcs == rooted_set) {
            return m.id;
        }
    }
    return null;
}

pub fn info(mode_type: ModeType) *const ModeInfo {
    return &ALL_MODES[@intFromEnum(mode_type)];
}

pub fn name(mode_type: ModeType) []const u8 {
    return info(mode_type).name;
}

pub fn count() usize {
    return ALL_MODES.len;
}

pub fn fromInt(raw: u8) ?ModeType {
    if (@as(usize, @intCast(raw)) >= ALL_MODES.len) return null;
    return @enumFromInt(raw);
}

pub fn offsets(mode_type: ModeType, out: *[ordered_scale.MAX_DEGREES]pitch.PitchClass) []pitch.PitchClass {
    const mode_info = info(mode_type);
    return ordered_scale.modeOffsets(mode_info.parent_pattern, mode_info.degree, out);
}

pub fn degreeOfNote(tonic: pitch.PitchClass, mode_type: ModeType, note: pitch.MidiNote) ?u8 {
    var offsets_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;
    return ordered_scale.degreeIndexForOffsets(offsets(mode_type, &offsets_buf), tonic, note);
}

pub fn transposeDiatonic(tonic: pitch.PitchClass, mode_type: ModeType, note: pitch.MidiNote, degrees: i8) ?pitch.MidiNote {
    var offsets_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;
    return ordered_scale.transposeMidiByDegrees(offsets(mode_type, &offsets_buf), tonic, note, degrees);
}

pub fn nearestScaleNeighbors(tonic: pitch.PitchClass, mode_type: ModeType, note: pitch.MidiNote) ordered_scale.ScaleNeighborTones {
    var offsets_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;
    return ordered_scale.nearestScaleNeighbors(offsets(mode_type, &offsets_buf), tonic, note);
}

pub fn snapToScale(tonic: pitch.PitchClass, mode_type: ModeType, note: pitch.MidiNote, policy: ordered_scale.SnapTiePolicy) ?pitch.MidiNote {
    var offsets_buf: [ordered_scale.MAX_DEGREES]pitch.PitchClass = undefined;
    return ordered_scale.snapToScale(offsets(mode_type, &offsets_buf), tonic, note, policy);
}

fn makeMode(id: ModeType, name_value: []const u8, parent_pattern: ordered_scale.PatternId, degree: u4) ModeInfo {
    const pattern = ordered_scale.info(parent_pattern);
    return .{
        .id = id,
        .name = name_value,
        .family = pattern.family,
        .parent_pattern = parent_pattern,
        .degree = degree,
        .pcs = ordered_scale.modePitchClassSet(parent_pattern, degree),
    };
}

comptime {
    for (ALL_MODES, 0..) |one, index| {
        if (@intFromEnum(one.id) != index) {
            @compileError("ModeType enum order must match ALL_MODES order");
        }
    }
}
