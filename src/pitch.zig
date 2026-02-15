const std = @import("std");

pub const PitchClass = u4;
pub const MidiNote = u7;
pub const Interval = u7;
pub const IntervalClass = u3;

pub const pc = struct {
    pub const C: PitchClass = 0;
    pub const Cs: PitchClass = 1;
    pub const D: PitchClass = 2;
    pub const Ds: PitchClass = 3;
    pub const E: PitchClass = 4;
    pub const F: PitchClass = 5;
    pub const Fs: PitchClass = 6;
    pub const G: PitchClass = 7;
    pub const Gs: PitchClass = 8;
    pub const A: PitchClass = 9;
    pub const As: PitchClass = 10;
    pub const B: PitchClass = 11;
};

pub fn midiToPC(note: MidiNote) PitchClass {
    return @as(PitchClass, @intCast(note % 12));
}

pub fn midiToOctave(note: MidiNote) i8 {
    return @as(i8, @intCast(note / 12)) - 1;
}

pub fn pcToMidi(class: PitchClass, octave: i8) MidiNote {
    const note: i16 = (@as(i16, octave) + 1) * 12 + @as(i16, class);
    std.debug.assert(note >= 0 and note <= 127);
    return @as(MidiNote, @intCast(note));
}

pub fn midiToFrequency(note: MidiNote) f64 {
    const exp = (@as(f64, @floatFromInt(note)) - 69.0) / 12.0;
    return 440.0 * std.math.exp2(exp);
}

pub fn toIntervalClass(semitones: u4) IntervalClass {
    const reduced = @as(u4, @intCast(semitones % 12));
    const folded = if (reduced <= 6) reduced else @as(u4, @intCast(12 - reduced));
    return @as(IntervalClass, @intCast(folded));
}

pub fn wrapPitchClass(value: i16) PitchClass {
    var out = @mod(value, 12);
    if (out < 0) out += 12;
    return @as(PitchClass, @intCast(out));
}
