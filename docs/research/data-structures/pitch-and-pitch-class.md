# Pitch and Pitch Class Data Structures

> References: [Pitch and Intervals](../pitch-and-intervals.md), [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Used by: All algorithms

## Core Types

### PitchClass

The fundamental unit — a note identity ignoring octave (mod 12).

```zig
pub const PitchClass = u4; // 0-11, but only values 0-11 are valid

pub const pc = struct {
    pub const C = 0;
    pub const Cs = 1; // C# / Db
    pub const D = 2;
    pub const Ds = 3; // D# / Eb
    pub const E = 4;
    pub const F = 5;
    pub const Fs = 6; // F# / Gb
    pub const G = 7;
    pub const Gs = 8; // G# / Ab
    pub const A = 9;
    pub const As = 10; // A# / Bb
    pub const B = 11;
};
```

### MidiNote

A specific pitch with octave information.

```zig
pub const MidiNote = u7; // 0-127 standard MIDI range

pub fn midiToPC(note: MidiNote) PitchClass {
    return @intCast(note % 12);
}

pub fn midiToOctave(note: MidiNote) i4 {
    return @intCast(@as(i8, note / 12) - 1);
}

pub fn pcToMidi(pc_val: PitchClass, octave: i4) MidiNote {
    return @intCast(@as(u8, 12) + @as(u8, @intCast(@as(i8, octave) + 1)) * 12 + pc_val);
}
```

### NoteName

A spelled note name (letter + accidental), essential for correct music notation.

```zig
pub const Letter = enum(u3) {
    A = 0, B = 1, C = 2, D = 3, E = 4, F = 5, G = 6,
};

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

    /// Convert to pitch class (0-11)
    pub fn toPitchClass(self: NoteName) PitchClass {
        const letter_to_pc = [7]u4{ 9, 11, 0, 2, 4, 5, 7 }; // A B C D E F G
        const base = letter_to_pc[@intFromEnum(self.letter)];
        return @intCast(@mod(@as(i8, base) + @intFromEnum(self.accidental), 12));
    }
};

pub const SpelledNote = struct {
    name: NoteName,
    octave: i4,

    pub fn toMidi(self: SpelledNote) MidiNote {
        return pcToMidi(self.name.toPitchClass(), self.octave);
    }
};
```

### AccidentalPreference

Controls how pitch classes are displayed as note names.

```zig
pub const AccidentalPreference = enum {
    sharp,  // C C# D D# E F F# G G# A A# B
    flat,   // C Db D Eb E F Gb G Ab A Bb B
    auto,   // Choose based on key context
};
```

## Constants

```zig
pub const MIDDLE_C: MidiNote = 60;
pub const CONCERT_A: MidiNote = 69; // A4 = 440 Hz
pub const PIANO_LOW: MidiNote = 21;  // A0
pub const PIANO_HIGH: MidiNote = 108; // C8
pub const KEYBOARD_LOW: MidiNote = 36;  // C2 (site's interactive keyboard)
pub const KEYBOARD_HIGH: MidiNote = 83; // B5
```

## Conversion Tables

```zig
/// 35 note name spellings → 12 pitch classes (compile-time map)
pub const NOTE_SPELLINGS: [35]struct { name: []const u8, pc: PitchClass } = .{
    .{ .name = "C", .pc = 0 },   .{ .name = "B#", .pc = 0 },  .{ .name = "Dbb", .pc = 0 },
    .{ .name = "C#", .pc = 1 },  .{ .name = "Db", .pc = 1 },
    .{ .name = "D", .pc = 2 },   .{ .name = "C##", .pc = 2 }, .{ .name = "Ebb", .pc = 2 },
    // ... (all 35)
};

/// Sharp and flat default spellings
pub const SHARP_NAMES = [12][]const u8{ "C","C#","D","D#","E","F","F#","G","G#","A","A#","B" };
pub const FLAT_NAMES = [12][]const u8{ "C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B" };
```

## Relationships to Other Types

- `PitchClass` → used in `PitchClassSet`, `IntervalClass`, `Chord`, `Scale`, `Key`
- `MidiNote` → used in `GuitarVoicing`, `KeyboardState`, playback
- `NoteName` → used in `KeySignature`, `NoteSpellingMap`, staff notation
- `SpelledNote` → used in SVG generation (staff notation, keyboard labels)
