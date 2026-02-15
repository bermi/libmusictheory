# Scale, Mode, and Key Data Structures

> References: [Scales and Modes](../scales-and-modes.md), [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Used by: scale-mode-key, chord-construction-and-naming, note-spelling

## Types

### ScaleType

The 4 main (+3 neighboring) scale types.

```zig
pub const ScaleType = enum(u3) {
    diatonic = 0,          // 7-35, 7 notes, maximally even
    acoustic = 1,          // 7-34, 7 notes (melodic minor parent)
    diminished = 2,        // 8-28, 8 notes, limited transposition
    whole_tone = 3,        // 6-35, 6 notes, limited transposition
    harmonic_minor = 4,    // 7-32, 7 notes, has augmented 2nd
    harmonic_major = 5,    // 7-32 (involution of harmonic minor)
    double_aug_hex = 6,    // 6-20, 6 notes, limited transposition

    pub fn primeForm(self: ScaleType) PitchClassSet {
        return switch (self) {
            .diatonic => 0b101010110101,
            .acoustic => 0b101001110101,
            .diminished => 0b011011011011,
            .whole_tone => 0b010101010101,
            .harmonic_minor => 0b100110110011,
            .harmonic_major => 0b101010110011,
            .double_aug_hex => 0b100100110011,
        };
    }

    pub fn numModes(self: ScaleType) u4 {
        return switch (self) {
            .diatonic, .acoustic, .harmonic_minor, .harmonic_major => 7,
            .diminished => 2,
            .whole_tone => 1,
            .double_aug_hex => 2,
        };
    }

    pub fn numTranspositions(self: ScaleType) u4 {
        return switch (self) {
            .diatonic, .acoustic, .harmonic_minor, .harmonic_major => 12,
            .diminished => 3,
            .whole_tone => 2,
            .double_aug_hex => 4,
        };
    }
};
```

### ModeType

One of the 17 (+14) canonical mode types from the jazz theory system.

```zig
pub const ModeType = struct {
    name: []const u8,
    scale_type: ScaleType,
    degree: u4,             // 0-based degree within parent scale
    formula: []const FormulaToken,  // interval formula from root

    pub fn toPitchClassSet(self: ModeType) PitchClassSet {
        var result: PitchClassSet = 0;
        for (self.formula) |token| {
            result |= @as(PitchClassSet, 1) << FORMULA_SEMITONES[@intFromEnum(token)];
        }
        return result;
    }
};

/// The 17 core mode types (diatonic + acoustic + diminished + whole-tone)
pub const CORE_MODES: [17]ModeType = .{
    // Diatonic
    .{ .name = "Ionian", .scale_type = .diatonic, .degree = 0, .formula = &.{ .root, .nat2, .nat3, .nat4, .nat5, .nat6, .nat7 } },
    .{ .name = "Dorian", .scale_type = .diatonic, .degree = 1, .formula = &.{ .root, .nat2, .flat3, .nat4, .nat5, .nat6, .flat7 } },
    .{ .name = "Phrygian", .scale_type = .diatonic, .degree = 2, .formula = &.{ .root, .flat2, .flat3, .nat4, .nat5, .flat6, .flat7 } },
    .{ .name = "Lydian", .scale_type = .diatonic, .degree = 3, .formula = &.{ .root, .nat2, .nat3, .sharp4, .nat5, .nat6, .nat7 } },
    .{ .name = "Mixolydian", .scale_type = .diatonic, .degree = 4, .formula = &.{ .root, .nat2, .nat3, .nat4, .nat5, .nat6, .flat7 } },
    .{ .name = "Aeolian", .scale_type = .diatonic, .degree = 5, .formula = &.{ .root, .nat2, .flat3, .nat4, .nat5, .flat6, .flat7 } },
    .{ .name = "Locrian", .scale_type = .diatonic, .degree = 6, .formula = &.{ .root, .flat2, .flat3, .nat4, .flat5, .flat6, .flat7 } },
    // Acoustic/Melodic Minor
    .{ .name = "Melodic Minor", .scale_type = .acoustic, .degree = 0, .formula = &.{ .root, .nat2, .flat3, .nat4, .nat5, .nat6, .nat7 } },
    .{ .name = "Dorian b2", .scale_type = .acoustic, .degree = 1, .formula = &.{ .root, .flat2, .flat3, .nat4, .nat5, .nat6, .flat7 } },
    .{ .name = "Lydian Augmented", .scale_type = .acoustic, .degree = 2, .formula = &.{ .root, .nat2, .nat3, .sharp4, .sharp5, .nat6, .nat7 } },
    .{ .name = "Lydian Dominant", .scale_type = .acoustic, .degree = 3, .formula = &.{ .root, .nat2, .nat3, .sharp4, .nat5, .nat6, .flat7 } },
    .{ .name = "Mixolydian b6", .scale_type = .acoustic, .degree = 4, .formula = &.{ .root, .nat2, .nat3, .nat4, .nat5, .flat6, .flat7 } },
    .{ .name = "Locrian nat2", .scale_type = .acoustic, .degree = 5, .formula = &.{ .root, .nat2, .flat3, .nat4, .flat5, .flat6, .flat7 } },
    .{ .name = "Super Locrian", .scale_type = .acoustic, .degree = 6, .formula = &.{ .root, .flat2, .flat3, .flat3, .flat5, .sharp5, .flat7 } },
    // Diminished
    .{ .name = "Half-Whole Dim", .scale_type = .diminished, .degree = 0, .formula = &.{ .root, .flat2, .sharp2, .nat3, .sharp4, .nat5, .nat6, .flat7 } },
    .{ .name = "Whole-Half Dim", .scale_type = .diminished, .degree = 1, .formula = &.{ .root, .nat2, .flat3, .nat4, .flat5, .sharp5, .nat6, .nat7 } },
    // Whole-Tone
    .{ .name = "Whole-Tone", .scale_type = .whole_tone, .degree = 0, .formula = &.{ .root, .nat2, .nat3, .sharp4, .sharp5, .flat7 } },
};
```

### Scale

A specific transposition of a scale type.

```zig
pub const Scale = struct {
    scale_type: ScaleType,
    tonic: PitchClass,       // transposition
    pitch_classes: PitchClassSet,

    pub fn init(scale_type: ScaleType, tonic: PitchClass) Scale {
        return .{
            .scale_type = scale_type,
            .tonic = tonic,
            .pitch_classes = pcs.transpose(scale_type.primeForm(), tonic),
        };
    }

    pub fn mode(self: Scale, degree: u4) Mode {
        var buf: [12]PitchClass = undefined;
        const notes = pcs.toList(self.pitch_classes, &buf);
        return .{
            .parent_scale = self,
            .degree = degree,
            .root = notes[degree],
            .pitch_classes = pcs.transposeDown(self.pitch_classes, notes[degree]),
        };
    }
};
```

### Mode

A scale with a designated root (determines the interval pattern character).

```zig
pub const Mode = struct {
    parent_scale: Scale,
    degree: u4,
    root: PitchClass,
    pitch_classes: PitchClassSet,  // normalized: root at pc 0

    pub fn modeType(self: Mode) ?*const ModeType {
        for (&CORE_MODES) |*mt| {
            if (mt.scale_type == self.parent_scale.scale_type and
                mt.degree == self.degree) {
                return mt;
            }
        }
        return null;
    }
};
```

### Key

A key = a diatonic scale + tonic. The organizing unit for tonal music.

```zig
pub const KeyQuality = enum { major, minor };

pub const Key = struct {
    tonic: PitchClass,
    quality: KeyQuality,
    signature: KeySignature,
    scale: Scale,

    pub fn init(tonic: PitchClass, quality: KeyQuality) Key {
        const scale_type: ScaleType = .diatonic;
        const offset: u4 = if (quality == .minor) 9 else 0; // Aeolian starts at degree 5
        return .{
            .tonic = tonic,
            .quality = quality,
            .signature = KeySignature.fromTonic(tonic, quality),
            .scale = Scale.init(scale_type, (tonic + 12 - offset) % 12),
        };
    }

    pub fn relativeMajor(self: Key) Key {
        return Key.init((self.tonic + 3) % 12, .major);
    }

    pub fn relativeMinor(self: Key) Key {
        return Key.init((self.tonic + 9) % 12, .minor);
    }

    pub fn parallelKey(self: Key) Key {
        return Key.init(self.tonic, if (self.quality == .major) .minor else .major);
    }
};
```

### KeySignature

The set of sharps or flats for a key.

```zig
pub const KeySignatureType = enum { sharps, flats, natural };

pub const KeySignature = struct {
    sig_type: KeySignatureType,
    count: u3,                    // 0-7 sharps or flats
    accidentals: [7]NoteName,     // which notes are modified

    /// Sharps order: F C G D A E B
    pub const SHARP_ORDER = [7]Letter{ .F, .C, .G, .D, .A, .E, .B };
    /// Flats order: B E A D G C F (reverse of sharps)
    pub const FLAT_ORDER = [7]Letter{ .B, .E, .A, .D, .G, .C, .F };

    pub fn fromTonic(tonic: PitchClass, quality: KeyQuality) KeySignature {
        // Map tonic to number of sharps (positive) or flats (negative)
        const major_tonic = if (quality == .minor) (tonic + 3) % 12 else tonic;
        // Circle of fifths position
        const cof_pos = [12]i4{ 0, -5, 2, -3, 4, -1, 6, 1, -4, 3, -2, 5 };
        const pos = cof_pos[major_tonic];
        // ... construct signature from position
    }
};
```

### NoteSpellingMap

Maps pitch classes to spelled note names for a specific key/scale context.

```zig
pub const NoteSpellingMap = struct {
    context_name: []const u8,        // e.g., "C Major", "F# Melodic Minor"
    spellings: [12]?NoteName,        // null if pc not in this key/scale

    pub fn spell(self: NoteSpellingMap, pc: PitchClass) ?NoteName {
        return self.spellings[pc];
    }
};

/// Precomputed spelling maps for all key/scale contexts
/// 15 major + 15 melodic minor + 15 harmonic minor + 15 harmonic major
/// + 4 octatonic + 2 whole-tone + 4 double aug hex = ~70 maps
pub const ALL_SPELLING_MAPS: [70]NoteSpellingMap = comptime blk: {
    // ... precompute all spelling maps
};
```

## Relationships

```
ScaleType (enum, 7 values)
  \-- Scale (type + transposition)
        \-- Mode (scale + degree)
              \-- ModeType (17 canonical types)

Key (tonic + quality)
  |-- KeySignature (sharps/flats)
  |-- Scale (the key's diatonic scale)
  \-- NoteSpellingMap (how to spell notes in this key)
```
