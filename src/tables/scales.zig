const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const scale = @import("../scale.zig");
const mode = @import("../mode.zig");
const key = @import("../key.zig");
const note_name = @import("../note_name.zig");
const note_spelling = @import("../note_spelling.zig");

pub const SCALE_TYPE_PCS = [_]pcs.PitchClassSet{
    scale.pcsForType(.diatonic),
    scale.pcsForType(.acoustic),
    scale.pcsForType(.diminished),
    scale.pcsForType(.whole_tone),
    scale.pcsForType(.harmonic_minor),
    scale.pcsForType(.harmonic_major),
    scale.pcsForType(.double_augmented_hexatonic),
};

pub const MODE_TYPES = buildModeTypes();

pub const KeySpellingMap = struct {
    tonic: pitch.PitchClass,
    quality: key.KeyQuality,
    names: [12]note_name.NoteName,
};

pub const KEY_SPELLING_MAPS = buildKeySpellingMaps();

fn buildModeTypes() [mode.ALL_MODES.len]mode.ModeType {
    @setEvalBranchQuota(2_000_000);

    var out: [mode.ALL_MODES.len]mode.ModeType = undefined;
    for (mode.ALL_MODES, 0..) |m, i| {
        out[i] = m.id;
    }
    return out;
}

fn buildKeySpellingMaps() [24]KeySpellingMap {
    @setEvalBranchQuota(2_000_000);

    var out: [24]KeySpellingMap = undefined;
    var i: usize = 0;

    var tonic: u4 = 0;
    while (tonic < 12) : (tonic += 1) {
        out[i] = buildOneMap(@as(pitch.PitchClass, @intCast(tonic)), .major);
        i += 1;
        out[i] = buildOneMap(@as(pitch.PitchClass, @intCast(tonic)), .minor);
        i += 1;
    }

    return out;
}

fn buildOneMap(tonic: pitch.PitchClass, quality: key.KeyQuality) KeySpellingMap {
    var names: [12]note_name.NoteName = undefined;
    const k = key.Key.init(tonic, quality);

    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        names[pc] = note_spelling.spellNote(@as(pitch.PitchClass, @intCast(pc)), k);
    }

    return .{
        .tonic = tonic,
        .quality = quality,
        .names = names,
    };
}
