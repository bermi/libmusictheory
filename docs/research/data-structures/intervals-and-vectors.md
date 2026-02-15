# Interval, Interval Class, and Vector Data Structures

> References: [Pitch and Intervals](../pitch-and-intervals.md), [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Used by: interval-vector-and-fc-components, chord-construction-and-naming

## Types

### Interval

A directed distance between two pitches, measured in semitones.

```zig
pub const Interval = u7; // 0-127 (covers full MIDI range span)

pub const interval = struct {
    // Simple intervals (within one octave)
    pub const UNISON: Interval = 0;
    pub const MINOR_2ND: Interval = 1;
    pub const MAJOR_2ND: Interval = 2;
    pub const MINOR_3RD: Interval = 3;
    pub const MAJOR_3RD: Interval = 4;
    pub const PERFECT_4TH: Interval = 5;
    pub const TRITONE: Interval = 6;
    pub const PERFECT_5TH: Interval = 7;
    pub const MINOR_6TH: Interval = 8;
    pub const MAJOR_6TH: Interval = 9;
    pub const MINOR_7TH: Interval = 10;
    pub const MAJOR_7TH: Interval = 11;
    pub const OCTAVE: Interval = 12;

    // Compound intervals
    pub const MINOR_9TH: Interval = 13;
    pub const MAJOR_9TH: Interval = 14;
    pub const AUG_9TH: Interval = 15;
    pub const PERFECT_11TH: Interval = 17;
    pub const AUG_11TH: Interval = 18;
    pub const MINOR_13TH: Interval = 20;
    pub const MAJOR_13TH: Interval = 21;
};
```

### IntervalClass

Octave-reduced, direction-neutral interval (1-6). Pairs that sum to 12 are equivalent.

```zig
pub const IntervalClass = u3; // 1-6

pub fn toIntervalClass(semitones: u4) IntervalClass {
    const diff = semitones % 12;
    return @intCast(@min(diff, 12 - diff));
}

/// 6 interval class colors used throughout the site
pub const IC_COLORS = [6][]const u8{
    "#0073F2", // IC1: Blue (semitone/major 7th)
    "#2CD6F9", // IC2: Cyan (whole tone/minor 7th)
    "#2CBE86", // IC3: Teal (minor 3rd/major 6th)
    "#74C937", // IC4: Green (major 3rd/minor 6th)
    "#E8C745", // IC5: Yellow (perfect 4th/5th)
    "#FB7A3D", // IC6: Orange (tritone)
};
```

### IntervalVector (Forte)

6-element count of interval class pairs in a pitch class set.

```zig
pub const IntervalVector = [6]u8;

pub fn computeIntervalVector(set: PitchClassSet) IntervalVector {
    var iv = [6]u8{ 0, 0, 0, 0, 0, 0 };
    var buf: [12]PitchClass = undefined;
    const pcs_list = pcs.toList(set, &buf);
    for (0..pcs_list.len) |i| {
        for (i + 1..pcs_list.len) |j| {
            const diff = @as(u4, @intCast(pcs_list[j])) - @as(u4, @intCast(pcs_list[i]));
            const ic = @min(diff, 12 - diff);
            iv[ic - 1] += 1;
        }
    }
    return iv;
}
```

### FCComponents (Lewin-Quinn Fourier)

6 floating-point magnitudes measuring imbalance per interval class.

```zig
pub const FCComponents = [6]f32;

pub fn computeFCComponents(set: PitchClassSet) FCComponents {
    var fc = [6]f32{ 0, 0, 0, 0, 0, 0 };
    var buf: [12]PitchClass = undefined;
    const pcs_list = pcs.toList(set, &buf);

    for (1..7) |k| {
        var sum_x: f32 = 0;
        var sum_y: f32 = 0;
        for (pcs_list) |p| {
            const angle = @as(f32, @floatFromInt(p)) *
                          @as(f32, @floatFromInt(k)) *
                          (std.math.pi / 6.0);
            sum_x += @cos(angle);
            sum_y += @sin(angle);
        }
        fc[k - 1] = @sqrt(sum_x * sum_x + sum_y * sum_y);
    }
    return fc;
}
```

### ChordFormula

Maps interval degree names to semitone offsets. Used for chord construction.

```zig
pub const FormulaToken = enum {
    root,
    flat2, nat2, sharp2,
    flat3, nat3, sharp3,
    nat4, sharp4,
    flat5, nat5, sharp5,
    flat6, nat6, sharp6,
    double_flat7, flat7, nat7,
    flat9, nat9, sharp9,
    flat11, nat11, sharp11,
    flat13, nat13, sharp13,
};

pub const FORMULA_SEMITONES = [_]u4{
    0,          // root
    1, 2, 3,    // b2, 2, #2
    3, 4, 5,    // b3, 3, #3
    5, 6,       // 4, #4
    6, 7, 8,    // b5, 5, #5
    8, 9, 10,   // b6, 6, #6
    9, 10, 11,  // bb7, b7, 7
    1, 2, 3,    // b9, 9, #9  (same pc as b2, 2, #2)
    4, 5, 6,    // b11, 11, #11
    8, 9, 10,   // b13, 13, #13
};

/// Base intervals for compound voicings (above the root octave)
pub const BASE_INTERVALS = [14]u5{
    0,  // placeholder (index 0)
    0,  // 1 = unison
    2,  // 2
    4,  // 3
    5,  // 4
    7,  // 5
    9,  // 6
    11, // 7
    0,  // placeholder
    14, // 9 = octave + 2
    0,  // placeholder
    17, // 11 = octave + 5
    0,  // placeholder
    21, // 13 = octave + 9
};
```

## Relationships to Other Types

- `IntervalClass` <- derived from two `PitchClass` values
- `IntervalVector` <- computed from `PitchClassSet`
- `FCComponents` <- computed from `PitchClassSet`
- `ChordFormula` -> produces `PitchClassSet` + voiced `MidiNote` arrays
- `IntervalVector` feeds -> Z-relation detection, interval content analysis
- `FCComponents` feeds -> M-relation detection, complement verification, evenness correlation
