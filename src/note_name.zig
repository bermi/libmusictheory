const pitch = @import("pitch.zig");

pub const Letter = enum(u3) { A, B, C, D, E, F, G };
pub const Accidental = enum(i3) {
    double_flat = -2,
    flat = -1,
    natural = 0,
    sharp = 1,
    double_sharp = 2,
};

pub const NoteName = struct {
    letter: Letter,
    accidental: Accidental,

    pub fn toPitchClass(self: NoteName) pitch.PitchClass {
        const base: i16 = switch (self.letter) {
            .A => 9,
            .B => 11,
            .C => 0,
            .D => 2,
            .E => 4,
            .F => 5,
            .G => 7,
        };
        const offset: i16 = @intFromEnum(self.accidental);
        return pitch.wrapPitchClass(base + offset);
    }

    pub fn format(self: NoteName, buffer: *[4]u8) []const u8 {
        buffer[0] = switch (self.letter) {
            .A => 'A',
            .B => 'B',
            .C => 'C',
            .D => 'D',
            .E => 'E',
            .F => 'F',
            .G => 'G',
        };

        return switch (self.accidental) {
            .double_flat => blk: {
                buffer[1] = 'b';
                buffer[2] = 'b';
                break :blk buffer[0..3];
            },
            .flat => blk: {
                buffer[1] = 'b';
                break :blk buffer[0..2];
            },
            .natural => buffer[0..1],
            .sharp => blk: {
                buffer[1] = '#';
                break :blk buffer[0..2];
            },
            .double_sharp => blk: {
                buffer[1] = '#';
                buffer[2] = '#';
                break :blk buffer[0..3];
            },
        };
    }
};

pub const SpelledNote = struct {
    name: NoteName,
    octave: i4,

    pub fn toMidi(self: SpelledNote) pitch.MidiNote {
        return pitch.pcToMidi(self.name.toPitchClass(), self.octave);
    }
};

pub const AccidentalPreference = enum {
    sharps,
    flats,
};

pub const SHARP_NAMES = [12]NoteName{
    .{ .letter = .C, .accidental = .natural },
    .{ .letter = .C, .accidental = .sharp },
    .{ .letter = .D, .accidental = .natural },
    .{ .letter = .D, .accidental = .sharp },
    .{ .letter = .E, .accidental = .natural },
    .{ .letter = .F, .accidental = .natural },
    .{ .letter = .F, .accidental = .sharp },
    .{ .letter = .G, .accidental = .natural },
    .{ .letter = .G, .accidental = .sharp },
    .{ .letter = .A, .accidental = .natural },
    .{ .letter = .A, .accidental = .sharp },
    .{ .letter = .B, .accidental = .natural },
};

pub const FLAT_NAMES = [12]NoteName{
    .{ .letter = .C, .accidental = .natural },
    .{ .letter = .D, .accidental = .flat },
    .{ .letter = .D, .accidental = .natural },
    .{ .letter = .E, .accidental = .flat },
    .{ .letter = .E, .accidental = .natural },
    .{ .letter = .F, .accidental = .natural },
    .{ .letter = .G, .accidental = .flat },
    .{ .letter = .G, .accidental = .natural },
    .{ .letter = .A, .accidental = .flat },
    .{ .letter = .A, .accidental = .natural },
    .{ .letter = .B, .accidental = .flat },
    .{ .letter = .B, .accidental = .natural },
};

pub fn chooseName(class: pitch.PitchClass, pref: AccidentalPreference) NoteName {
    return switch (pref) {
        .sharps => SHARP_NAMES[class],
        .flats => FLAT_NAMES[class],
    };
}

pub const ALL_SPELLINGS = buildAllSpellings();

fn buildAllSpellings() [35]NoteName {
    const letters = [_]Letter{ .A, .B, .C, .D, .E, .F, .G };
    const accidental_order = [_]Accidental{ .double_flat, .flat, .natural, .sharp, .double_sharp };

    var out: [35]NoteName = undefined;
    var i: usize = 0;
    for (letters) |letter| {
        for (accidental_order) |accidental| {
            out[i] = .{ .letter = letter, .accidental = accidental };
            i += 1;
        }
    }
    return out;
}
