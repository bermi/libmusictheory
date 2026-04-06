const counterpoint = @import("counterpoint.zig");
const pitch = @import("pitch.zig");

pub const MAX_REGISTER_VIOLATIONS: usize = 4;

pub const SatbVoice = enum(u8) {
    soprano,
    alto,
    tenor,
    bass,
};

pub const SATB_VOICE_NAMES = [_][]const u8{
    "soprano",
    "alto",
    "tenor",
    "bass",
};

pub const RegisterRange = struct {
    low: pitch.MidiNote,
    high: pitch.MidiNote,
};

pub const RegisterViolation = struct {
    voice_id: u8,
    satb_voice: SatbVoice,
    midi: pitch.MidiNote,
    direction: i8,
    low: pitch.MidiNote,
    high: pitch.MidiNote,
};

pub fn range(voice: SatbVoice) RegisterRange {
    return switch (voice) {
        .soprano => .{ .low = 60, .high = 81 },
        .alto => .{ .low = 55, .high = 76 },
        .tenor => .{ .low = 48, .high = 69 },
        .bass => .{ .low = 40, .high = 64 },
    };
}

pub fn rangeLow(voice: SatbVoice) pitch.MidiNote {
    return range(voice).low;
}

pub fn rangeHigh(voice: SatbVoice) pitch.MidiNote {
    return range(voice).high;
}

pub fn rangeContains(voice: SatbVoice, midi: pitch.MidiNote) bool {
    const bounds = range(voice);
    return midi >= bounds.low and midi <= bounds.high;
}

pub fn checkRegisters(state: *const counterpoint.VoicedState, out: []RegisterViolation) u8 {
    const voices = state.slice();
    if (voices.len != 4) return 0;

    const satb_order = [_]SatbVoice{ .bass, .tenor, .alto, .soprano };
    var total: u8 = 0;
    var written: usize = 0;

    for (voices, satb_order) |voice, satb_voice| {
        const bounds = range(satb_voice);
        const direction: i8 = if (voice.midi < bounds.low)
            -1
        else if (voice.midi > bounds.high)
            1
        else
            0;
        if (direction == 0) continue;

        total +%= 1;
        if (written >= out.len) continue;
        out[written] = .{
            .voice_id = voice.id,
            .satb_voice = satb_voice,
            .midi = voice.midi,
            .direction = direction,
            .low = bounds.low,
            .high = bounds.high,
        };
        written += 1;
    }

    return total;
}
