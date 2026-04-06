const pitch = @import("pitch.zig");
const mode = @import("mode.zig");

pub const MAX_MATCHES: usize = mode.ALL_MODES.len;

pub const ContainingModeMatch = struct {
    mode: mode.ModeType,
    degree: u8,
};

pub fn findContainingModes(
    note_pc: pitch.PitchClass,
    tonic: pitch.PitchClass,
    modes: []const mode.ModeType,
    out: []ContainingModeMatch,
) u8 {
    var total: u8 = 0;
    var written: usize = 0;
    for (modes) |mode_type| {
        const degree_index = mode.degreeOfPitchClass(tonic, mode_type, note_pc) orelse continue;
        if (written < out.len) {
            out[written] = .{
                .mode = mode_type,
                .degree = degree_index + 1,
            };
            written += 1;
        }
        total += 1;
    }
    return total;
}
