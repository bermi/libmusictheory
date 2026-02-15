const pcs = @import("pitch_class_set.zig");
const pitch = @import("pitch.zig");

pub const ChordType = struct {
    name: []const u8,
    abbreviation: []const u8,
    formula: []const u8,
    pcs: pcs.PitchClassSet,
};

pub const MAJOR = ChordType{ .name = "Major", .abbreviation = "", .formula = "1 3 5", .pcs = pcs.C_MAJOR_TRIAD };
pub const MINOR = ChordType{ .name = "Minor", .abbreviation = "m", .formula = "1 b3 5", .pcs = pcs.C_MINOR_TRIAD };
pub const DIMINISHED = ChordType{ .name = "Diminished", .abbreviation = "dim", .formula = "1 b3 b5", .pcs = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 }) };
pub const AUGMENTED = ChordType{ .name = "Augmented", .abbreviation = "aug", .formula = "1 3 #5", .pcs = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 }) };

pub const ALL = [_]ChordType{
    MAJOR,
    MINOR,
    DIMINISHED,
    AUGMENTED,
};
