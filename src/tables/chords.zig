const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const chord_type = @import("../chord_type.zig");
const mode = @import("../mode.zig");
const harmony = @import("../harmony.zig");

pub const CHORD_TYPES = chord_type.ALL;

pub const GameResult = struct {
    chord_type_index: u8,
    root: pitch.PitchClass,
    mode_type: mode.ModeType,
    compatible: bool,
    avoid_notes: pcs.PitchClassSet,
    available_tensions: pcs.PitchClassSet,
};

pub const GAME_RESULTS = buildGameResults();

fn buildGameResults() [CHORD_TYPES.len * 12 * mode.ALL_MODES.len]GameResult {
    @setEvalBranchQuota(20_000_000);

    var out: [CHORD_TYPES.len * 12 * mode.ALL_MODES.len]GameResult = undefined;
    var i: usize = 0;

    var ct_index: usize = 0;
    while (ct_index < CHORD_TYPES.len) : (ct_index += 1) {
        var root: u4 = 0;
        while (root < 12) : (root += 1) {
            const root_pc = @as(pitch.PitchClass, @intCast(root));
            const chord_set = pcs.transpose(CHORD_TYPES[ct_index].pcs, root_pc);
            const chord_instance = harmony.ChordInstance{
                .root = root_pc,
                .pcs = chord_set,
                .quality = .unknown,
                .degree = 0,
            };

            for (mode.ALL_MODES) |m| {
                const mode_set = pcs.transpose(m.pcs, root_pc);
                const mode_ctx = harmony.ModeContext{ .root = root_pc, .pcs = mode_set };
                const match = harmony.chordScaleCompatibility(chord_instance, mode_ctx);

                out[i] = .{
                    .chord_type_index = @as(u8, @intCast(ct_index)),
                    .root = root_pc,
                    .mode_type = m.id,
                    .compatible = match.compatible,
                    .avoid_notes = match.avoid_notes,
                    .available_tensions = match.available_tensions,
                };
                i += 1;
            }
        }
    }

    return out;
}
