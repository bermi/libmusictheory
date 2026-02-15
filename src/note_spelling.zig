const pitch = @import("pitch.zig");
const note_name = @import("note_name.zig");
const key = @import("key.zig");

pub const SpellingResult = note_name.NoteName;

pub const AutoSpellResult = struct {
    key_tonic: pitch.PitchClass,
    names: []const note_name.NoteName,
};

pub fn spellWithPreference(pc: pitch.PitchClass, pref: note_name.AccidentalPreference) note_name.NoteName {
    return note_name.chooseName(pc, pref);
}

pub fn spellNote(pc: pitch.PitchClass, k: key.Key) note_name.NoteName {
    if (k.signature.kind == .flats) {
        return note_name.chooseName(pc, .flats);
    }
    return note_name.chooseName(pc, .sharps);
}

pub fn autoSpell(
    pcs_list: []const pitch.PitchClass,
    pref: note_name.AccidentalPreference,
    out: []note_name.NoteName,
) AutoSpellResult {
    for (pcs_list, 0..) |pc, i| {
        out[i] = spellWithPreference(pc, pref);
    }

    const tonic = if (pcs_list.len > 0) pcs_list[0] else pitch.pc.C;
    return .{
        .key_tonic = tonic,
        .names = out[0..pcs_list.len],
    };
}
