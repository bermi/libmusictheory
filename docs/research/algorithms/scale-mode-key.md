# Scale, Mode, and Key Algorithms

> References: [Scales and Modes](../scales-and-modes.md), [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` (key data, moreScales, isScaley),
> `tmp/harmoniousapp.net/p/34/Scales.html`, `tmp/harmoniousapp.net/p/39/Modes.html`, `tmp/harmoniousapp.net/p/a7/Keys.html`

## Overview

Algorithms for constructing, identifying, and navigating scales, modes, and keys — the organizational layers above pitch class sets.

## Static Data

### The 4 (+3) Scale Types as Prime Forms

```
DIATONIC       = 0b101010110101  // 7-35 [013568t] = 2741
ACOUSTIC       = 0b101010110011  // 7-34 [013568a] = 2733 (melodic minor parent)
DIMINISHED     = 0b011011011011  // 8-28 [0134679t] = 1755
WHOLE_TONE     = 0b010101010101  // 6-35 [02468t] = 1365

HARMONIC_MINOR = 0b100110110011  // 7-32 [013468a]
HARMONIC_MAJOR = 0b101010110011  // 7-32 [013568a] (involution of harm. minor)
DOUBLE_AUG_HEX = 0b000100110011  // 6-20 [01458a]
```

### The 17 Mode Types

Each mode is a (scale_type, degree) pair. The degree determines which rotation of the parent scale is used.

```
MODES = [
    // Diatonic (7 modes)
    (DIATONIC, 0, "Ionian"),       (DIATONIC, 1, "Dorian"),
    (DIATONIC, 2, "Phrygian"),     (DIATONIC, 3, "Lydian"),
    (DIATONIC, 4, "Mixolydian"),   (DIATONIC, 5, "Aeolian"),
    (DIATONIC, 6, "Locrian"),
    // Acoustic (7 modes)
    (ACOUSTIC, 0, "Melodic Minor"),  (ACOUSTIC, 1, "Dorian b2"),
    (ACOUSTIC, 2, "Lydian Aug"),     (ACOUSTIC, 3, "Lydian Dom"),
    (ACOUSTIC, 4, "Mixolydian b6"),  (ACOUSTIC, 5, "Locrian nat2"),
    (ACOUSTIC, 6, "Super Locrian"),
    // Diminished (2 modes)
    (DIMINISHED, 0, "Half-Whole"),   (DIMINISHED, 1, "Whole-Half"),
    // Whole-Tone (1 mode)
    (WHOLE_TONE, 0, "Whole-Tone"),
]
```

## Algorithms

### 1. Mode from Scale + Degree

**Input**: Parent scale (12-bit PCS), degree index (0-based)
**Output**: Mode as 12-bit PCS (rotated so degree is at position 0)

```
mode_from_scale(scale, degree):
    pcs = tolist(scale)
    root_pc = pcs[degree]
    return rightshift(scale, root_pc)
```

**Complexity**: O(1)

### 2. Scale Type Identification

**Input**: 12-bit PCS
**Output**: Scale type name (or "unknown")

```
identify_scale_type(x):
    pf = prime_form(x)
    for (scale_pcs, name) in SCALE_TYPES:
        if prime_form(scale_pcs) == pf:
            return name
    return "unknown"
```

**Complexity**: O(7 * 12) = O(1)

### 3. Mode Identification

**Input**: 12-bit PCS (rooted mode — includes pitch class 0)
**Output**: (scale_type, degree, mode_name)

```
identify_mode(x):
    for k in 0..11:
        parent = leftshift(x, k)
        for (scale, degree, name) in MODES:
            if prime_form(parent) == prime_form(scale):
                // Found parent scale; degree is k
                return (scale_type_name(scale), k, name)
    return unknown
```

**Complexity**: O(12 * 17) = O(1)

### 4. Key Signature Generation

**Input**: Tonic pitch class, mode type
**Output**: Key signature (set of sharps or flats)

```
KEY_SIGNATURES = {
    // Major keys — sharps
    "C":  [],        "G":  ["F#"],     "D":  ["F#","C#"],
    "A":  ["F#","C#","G#"],  "E":  ["F#","C#","G#","D#"],
    "B":  ["F#","C#","G#","D#","A#"],
    "F#": ["F#","C#","G#","D#","A#","E#"],
    "C#": ["F#","C#","G#","D#","A#","E#","B#"],
    // Major keys — flats
    "F":  ["Bb"],    "Bb": ["Bb","Eb"],  "Eb": ["Bb","Eb","Ab"],
    "Ab": ["Bb","Eb","Ab","Db"],  "Db": ["Bb","Eb","Ab","Db","Gb"],
    "Gb": ["Bb","Eb","Ab","Db","Gb","Cb"],
    "Cb": ["Bb","Eb","Ab","Db","Gb","Cb","Fb"],
}

key_signature(tonic_pc, mode):
    // For major: look up directly
    // For minor: use relative major (3 semitones up)
    // For other modes: compute from parent major key
    relative_major_pc = (tonic_pc + mode_to_major_offset(mode)) % 12
    return KEY_SIGNATURES[pc_to_letter(relative_major_pc)]
```

### 5. Note Spelling from Key Context

**Input**: Array of MIDI notes, key context (optional)
**Output**: Array of spelled note names (e.g., "C#4" not "Db4")

```
spell_notes(midi_notes, key_context):
    if key_context:
        // Use the note name map for this key
        return [key_context.spell(midi % 12) + octave_str(midi) for midi in midi_notes]

    // Auto-detect best key
    pitch_classes = {midi % 12 for midi in midi_notes}
    // Search all key signatures for best coverage
    best_key = null
    best_coverage = 0
    for key in ALL_KEYS:
        coverage = len(pitch_classes & key.pitch_classes)
        if coverage > best_coverage:
            best_coverage = coverage
            best_key = key
    return [best_key.spell(midi % 12) + octave_str(midi) for midi in midi_notes]
```

This is the `numsToNoteOctaveNames` function from pitch-class-sets.js, which searches through `justKeys` and `moreScales` dictionaries.

**Complexity**: O(n * K) where n = note count, K = number of key signatures

### 6. Scale Heuristic (isScaley)

**Input**: 12-bit PCS
**Output**: Boolean — does this look like a scale (vs a chord)?

```
is_scaley(x):
    C = popcount(x)
    if C >= 7: return true
    if C >= 5:
        // Check if notes are spread out (no large gaps)
        pcs = tolist(x)
        max_gap = max((pcs[(i+1)%C] - pcs[i]) % 12 for i in 0..C-1)
        return max_gap <= 4  // No gap larger than a major 3rd
    return false
```

Used to determine playback style: scales play sequentially, chords play simultaneously.

**Complexity**: O(C) = O(1)

### 7. Circle of Fifths Navigation

**Input**: Current key index (0-11)
**Output**: Adjacent keys (±1 in circle of fifths)

```
CIRCLE_OF_FIFTHS = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5]
// Index: position in CoF. Value: pitch class.
// C=0, G=7, D=2, A=9, E=4, B=11, F#=6, Db=1, Ab=8, Eb=3, Bb=10, F=5

next_key_sharp(pc):
    return (pc + 7) % 12  // up a fifth

next_key_flat(pc):
    return (pc + 5) % 12  // up a fourth (= down a fifth)

cof_position(pc):
    return (pc * 7) % 12  // maps chromatic to CoF ordering
```

### 8. Relative and Parallel Key Computation

```
relative_minor(major_pc):
    return (major_pc + 9) % 12  // = major_pc - 3 mod 12

relative_major(minor_pc):
    return (minor_pc + 3) % 12

parallel_minor(major_pc):
    // Same tonic, different mode
    return major_pc  // same pitch class, switch scale type

parallel_major(minor_pc):
    return minor_pc
```

### 9. Scale Voice-Leading Distance (Adjacency Map)

**Input**: Two 7-note scales (12-bit PCS)
**Output**: Voice-leading distance (counting changed notes)

```
scale_vl_distance(scale_a, scale_b):
    // For 7-note scales, voice-leading distance = Hamming distance
    // when cardinalities are equal
    return popcount(scale_a ^ scale_b)
```

Adjacent scales in the hexagonal tessellation differ by exactly 1 note (Hamming distance = 2: one note leaves, one enters).

For the tessellation map:
- Hexagons = diatonic (6 neighbors)
- Squares = acoustic (4 neighbors)
- Triangles = harmonic minor/major (fewer neighbors)

## Data Structures Used

- `ScaleType`: enum { Diatonic, Acoustic, Diminished, WholeTone, HarmonicMinor, HarmonicMajor, DoubleAugHex }
- `ModeType`: struct { scale_type: ScaleType, degree: u4, name: []const u8 }
- `Key`: struct { tonic: PitchClass, mode: ModeType, signature: KeySignature }
- `KeySignature`: struct { sharps_or_flats: enum, accidentals: []NoteName }
- Static tables: 17 mode types, 15 key signatures (expandable to all scale types)

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Prime Form and Set Class](prime-form-and-set-class.md)
