# Chord and Harmony Data Structures

> References: [Chords and Voicings](../chords-and-voicings.md), [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Used by: chord-construction-and-naming, scale-mode-key

## Types

### ChordQuality

The fundamental quality categories of chords.

```zig
pub const ChordQuality = enum(u4) {
    major = 0,
    minor = 1,
    diminished = 2,
    augmented = 3,
    suspended2 = 4,
    suspended4 = 5,
    dominant = 6,        // major 3rd + minor 7th
    half_diminished = 7, // minor 3rd + diminished 5th + minor 7th
    minor_major = 8,     // minor 3rd + major 7th
    power = 9,           // root + 5th only
};
```

### ChordType

A named chord type defined by its interval formula. This is OTC-equivalent — the same intervals from any root.

```zig
pub const ChordType = struct {
    name: []const u8,           // e.g., "Major 7th", "Dominant 9th"
    abbreviation: []const u8,   // e.g., "maj7", "9"
    quality: ChordQuality,
    formula: []const FormulaToken,
    pitch_class_set: PitchClassSet,  // with root at pc 0
    cardinality: u4,

    pub fn toPCS(self: ChordType) PitchClassSet {
        return self.pitch_class_set;
    }
};

/// Comprehensive chord type catalog (~100 types)
pub const CHORD_TYPES = struct {
    // Triads (3 notes)
    pub const MAJOR = ChordType{ .name = "Major", .abbreviation = "", .quality = .major,
        .formula = &.{ .root, .nat3, .nat5 }, .pitch_class_set = 0b000010010001, .cardinality = 3 };
    pub const MINOR = ChordType{ .name = "Minor", .abbreviation = "m", .quality = .minor,
        .formula = &.{ .root, .flat3, .nat5 }, .pitch_class_set = 0b000010001001, .cardinality = 3 };
    pub const DIM = ChordType{ .name = "Diminished", .abbreviation = "dim", .quality = .diminished,
        .formula = &.{ .root, .flat3, .flat5 }, .pitch_class_set = 0b000001001001, .cardinality = 3 };
    pub const AUG = ChordType{ .name = "Augmented", .abbreviation = "aug", .quality = .augmented,
        .formula = &.{ .root, .nat3, .sharp5 }, .pitch_class_set = 0b000100010001, .cardinality = 3 };
    pub const SUS2 = ChordType{ .name = "Suspended 2nd", .abbreviation = "sus2", .quality = .suspended2,
        .formula = &.{ .root, .nat2, .nat5 }, .pitch_class_set = 0b000010000101, .cardinality = 3 };
    pub const SUS4 = ChordType{ .name = "Suspended 4th", .abbreviation = "sus4", .quality = .suspended4,
        .formula = &.{ .root, .nat4, .nat5 }, .pitch_class_set = 0b000010100001, .cardinality = 3 };

    // Seventh chords (4 notes)
    pub const MAJ7 = ChordType{ .name = "Major 7th", .abbreviation = "maj7", .quality = .major,
        .formula = &.{ .root, .nat3, .nat5, .nat7 }, .pitch_class_set = 0b100010010001, .cardinality = 4 };
    pub const DOM7 = ChordType{ .name = "Dominant 7th", .abbreviation = "7", .quality = .dominant,
        .formula = &.{ .root, .nat3, .nat5, .flat7 }, .pitch_class_set = 0b010010010001, .cardinality = 4 };
    pub const MIN7 = ChordType{ .name = "Minor 7th", .abbreviation = "m7", .quality = .minor,
        .formula = &.{ .root, .flat3, .nat5, .flat7 }, .pitch_class_set = 0b010010001001, .cardinality = 4 };
    pub const MINMAJ7 = ChordType{ .name = "Minor Major 7th", .abbreviation = "mMaj7", .quality = .minor_major,
        .formula = &.{ .root, .flat3, .nat5, .nat7 }, .pitch_class_set = 0b100010001001, .cardinality = 4 };
    pub const HALFDIM7 = ChordType{ .name = "Half-Diminished 7th", .abbreviation = "m7b5", .quality = .half_diminished,
        .formula = &.{ .root, .flat3, .flat5, .flat7 }, .pitch_class_set = 0b010001001001, .cardinality = 4 };
    pub const DIM7 = ChordType{ .name = "Diminished 7th", .abbreviation = "dim7", .quality = .diminished,
        .formula = &.{ .root, .flat3, .flat5, .double_flat7 }, .pitch_class_set = 0b001001001001, .cardinality = 4 };
    pub const AUGMAJ7 = ChordType{ .name = "Augmented Major 7th", .abbreviation = "augMaj7", .quality = .augmented,
        .formula = &.{ .root, .nat3, .sharp5, .nat7 }, .pitch_class_set = 0b100100010001, .cardinality = 4 };
    pub const SUS7 = ChordType{ .name = "Suspended 7th", .abbreviation = "7sus4", .quality = .suspended4,
        .formula = &.{ .root, .nat4, .nat5, .flat7 }, .pitch_class_set = 0b010010100001, .cardinality = 4 };

    // Extended chords (5+ notes)
    pub const DOM9 = ChordType{ .name = "Dominant 9th", .abbreviation = "9", .quality = .dominant,
        .formula = &.{ .root, .nat3, .nat5, .flat7, .nat9 }, .pitch_class_set = 0b010010010101, .cardinality = 5 };
    pub const MAJ9 = ChordType{ .name = "Major 9th", .abbreviation = "maj9", .quality = .major,
        .formula = &.{ .root, .nat3, .nat5, .nat7, .nat9 }, .pitch_class_set = 0b100010010101, .cardinality = 5 };
    pub const MIN9 = ChordType{ .name = "Minor 9th", .abbreviation = "m9", .quality = .minor,
        .formula = &.{ .root, .flat3, .nat5, .flat7, .nat9 }, .pitch_class_set = 0b010010001101, .cardinality = 5 };

    // Add chords (triad + extension, no 7th)
    pub const ADD9 = ChordType{ .name = "Add 9", .abbreviation = "add9", .quality = .major,
        .formula = &.{ .root, .nat3, .nat5, .nat9 }, .pitch_class_set = 0b000010010101, .cardinality = 4 };
    pub const ADD6 = ChordType{ .name = "Add 6", .abbreviation = "6", .quality = .major,
        .formula = &.{ .root, .nat3, .nat5, .nat6 }, .pitch_class_set = 0b001010010001, .cardinality = 4 };

    // Power chord
    pub const POWER = ChordType{ .name = "Power Chord", .abbreviation = "5", .quality = .power,
        .formula = &.{ .root, .nat5 }, .pitch_class_set = 0b000010000001, .cardinality = 2 };
};
```

### ChordInstance

A specific chord: root + chord type.

```zig
pub const ChordInstance = struct {
    root: PitchClass,
    chord_type: *const ChordType,

    pub fn pitchClassSet(self: ChordInstance) PitchClassSet {
        return pcs.transpose(self.chord_type.pitch_class_set, self.root);
    }

    pub fn name(self: ChordInstance, buf: *[32]u8) []u8 {
        // e.g., "C Major 7th", "F# Minor"
        const root_name = SHARP_NAMES[self.root];
        // ... format root + chord type name
    }
};
```

### Inversion

How a chord is voiced relative to its bass note.

```zig
pub const Inversion = enum(u3) {
    root_position = 0,    // root is lowest
    first = 1,            // 3rd is lowest
    second = 2,           // 5th is lowest
    third = 3,            // 7th is lowest (for 7th+ chords)
    slash = 4,            // bass note not in chord
};
```

### SlashChord

A chord with a specified bass note (which may or may not be a chord tone).

```zig
pub const SlashChord = struct {
    upper_structure: ChordInstance,
    bass_note: PitchClass,

    pub fn fullPCS(self: SlashChord) PitchClassSet {
        return self.upper_structure.pitchClassSet() | (@as(PitchClassSet, 1) << self.bass_note);
    }

    pub fn inversion(self: SlashChord) Inversion {
        // Determine if bass note is a chord tone and which inversion
        const chord_pcs = self.upper_structure.pitchClassSet();
        if (self.bass_note == self.upper_structure.root) return .root_position;
        // ... check against 3rd, 5th, 7th
        return .slash;
    }
};
```

### RomanNumeral

Transposition-invariant chord function within a key.

```zig
pub const RomanNumeral = struct {
    degree: u4,              // 1-7
    quality: ChordQuality,
    extensions: []const u8,  // "7", "9", "ø7", etc.
    is_uppercase: bool,      // major/augmented = uppercase

    pub fn format(self: RomanNumeral, buf: *[16]u8) []u8 {
        const numerals_upper = [7][]const u8{ "I", "II", "III", "IV", "V", "VI", "VII" };
        const numerals_lower = [7][]const u8{ "i", "ii", "iii", "iv", "v", "vi", "vii" };
        // ... format with quality suffix
    }
};
```

### DiatonicHarmony

Precomputed diatonic chord table for a key.

```zig
pub const DiatonicHarmony = struct {
    key: Key,
    triads: [7]ChordInstance,
    sevenths: [7]ChordInstance,
    roman_numerals_triad: [7]RomanNumeral,
    roman_numerals_seventh: [7]RomanNumeral,

    pub fn init(key: Key) DiatonicHarmony {
        // Construct all 7 diatonic triads and 7th chords by stacking thirds
    }
};
```

### ChordScaleMatch

Result of chord-scale compatibility analysis.

```zig
pub const ChordScaleMatch = struct {
    chord: ChordInstance,
    mode: Mode,
    is_compatible: bool,
    avoid_notes: PitchClassSet,       // scale tones 1 semitone above chord tones
    available_tensions: PitchClassSet, // scale tones available as extensions

    pub fn numAvoidNotes(self: ChordScaleMatch) u4 {
        return pcs.cardinality(self.avoid_notes);
    }
};
```

### GameResult

Output of the exhaustive chord-mode matching algorithm ("The Game").

```zig
pub const GameResult = struct {
    chord_pcs: PitchClassSet,         // OTC object (root at pc 0)
    mode_type: *const ModeType,
    formula: []const FormulaToken,    // chord formula in mode context
    chord_name: []const u8,           // derived chord name

    pub const ALL_RESULTS: []const GameResult = comptime blk: {
        // ~1,000 chord-mode combinations from 479 cluster-free OTC objects
    };
};
```

## Relationships

```
ChordType (OTC: ~100 named types)
  └── ChordInstance (type + root = specific chord)
        ├── SlashChord (chord + bass note)
        ├── Inversion (bass note position)
        └── RomanNumeral (function in key)

DiatonicHarmony (7 triads + 7 sevenths per key)
  └── ChordScaleMatch (chord + mode compatibility)

GameResult (~1,000 chord-mode combinations)
```
