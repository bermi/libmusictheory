# Chord Construction and Naming

> References: [Chords and Voicings](../chords-and-voicings.md), [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` functions: `formToList`, `formToNum`, `strToPC`, `baseInterval`
> Source: `tmp/harmoniousapp.net/p/fc/Chords.html`, `tmp/harmoniousapp.net/p/69/The-Game.html`, `tmp/harmoniousapp.net/p/e7/Leave-Out-Notes.html`

## Overview

Algorithms for constructing chords from formulas, naming pitch class sets as chords, and the exhaustive "Game" algorithm that catalogs all chord-mode relationships.

## Static Data

### Interval Formula to Semitone Mapping

```
FORMULA_TO_PC = {
    "R": 0,  "1": 0,
    "b2": 1, "2": 2,  "#2": 3,
    "b3": 3, "3": 4,  "#3": 5,
    "4": 5,  "#4": 6, "b5": 6,
    "5": 7,  "#5": 8, "b6": 8,
    "6": 9,  "#6": 10, "bb7": 9,
    "b7": 10, "7": 11,
    "b9": 1,  "9": 2,  "#9": 3,
    "b11": 4, "11": 5, "#11": 6,
    "b13": 8, "13": 9, "#13": 10,
}
```

### Base Interval Array (for compound intervals)

```
BASE_INTERVAL = [_, 0, 2, 4, 5, 7, 9, 11, _, 14, _, 17, _, 21]
//               1  2  3  4  5  6  7      9     11     13
```

## Algorithms

### 1. Chord Formula to Pitch Class Set

**Input**: Formula string (e.g., "R 3 5 7")
**Output**: 12-bit PCS

```
formula_to_pcs(formula):
    result = 0
    for token in formula.split(" "):
        pc = FORMULA_TO_PC[token]
        result |= (1 << pc)
    return result
```

**Complexity**: O(n) where n = number of formula tokens

### 2. Chord Formula to MIDI Notes (Voiced)

**Input**: Formula string, root MIDI note
**Output**: Array of MIDI notes (in register, compound intervals preserved)

```
formula_to_midi(formula, root_midi):
    notes = []
    for token in formula.split(" "):
        semitones = FORMULA_TO_PC[token]
        // For compound intervals (9, 11, 13), add octave
        if token in ["9", "b9", "#9"]:
            semitones = BASE_INTERVAL[9]  // 14
        elif token in ["11", "b11", "#11"]:
            semitones = BASE_INTERVAL[11]  // 17
        elif token in ["13", "b13", "#13"]:
            semitones = BASE_INTERVAL[13]  // 21
        notes.append(root_midi + semitones)
    return notes
```

### 3. Pitch Class Set to Chord Name (Reverse Lookup)

**Input**: 12-bit PCS (with designated root at pc 0)
**Output**: Chord type name

```
CHORD_TYPE_TABLE = {
    // Triads
    0b000010010001: "Major",          // R 3 5 = {0,4,7}
    0b000010001001: "Minor",          // R b3 5 = {0,3,7}
    0b000001001001: "Diminished",     // R b3 b5 = {0,3,6}
    0b000100010001: "Augmented",      // R 3 #5 = {0,4,8}
    0b000010000101: "Suspended 2nd",  // R 2 5 = {0,2,7}
    0b000010100001: "Suspended 4th",  // R 4 5 = {0,5,7}

    // Seventh chords
    0b100010010001: "Major 7th",       // R 3 5 7
    0b010010010001: "Dominant 7th",    // R 3 5 b7
    0b010010001001: "Minor 7th",       // R b3 5 b7
    // ... (all chord types from the site's catalog)
}

pcs_to_chord_name(x):
    // Normalize to root at pc 0
    normalized = rightshift(x, lowest_set_bit(x))
    if normalized in CHORD_TYPE_TABLE:
        return CHORD_TYPE_TABLE[normalized]
    return null
```

### 4. The Game Algorithm (Exhaustive Chord-Mode Catalog)

**Input**: The 17 mode formulas
**Output**: All valid chord-mode combinations

```
the_game():
    results = []

    // Step 1: Enumerate all OTC objects containing pc 0
    otc_objects = []
    for x in 0..4095:
        if not (x & 1): continue  // must include pc 0 (root)
        card = popcount(x)
        if card < 3 or card > 9: continue
        otc_objects.append(x)  // 1,969 objects

    // Step 2: Filter to cluster-free
    cluster_free = [x for x in otc_objects if not has_cluster(x)]
    // 560 objects

    // Step 3: Match against 17 modes
    for obj in cluster_free:
        for mode in MODES:
            mode_pcs = formula_to_pcs(mode.formula)
            if is_subset(obj, mode_pcs):
                // Step 4: Derive chord name from mode context
                chord_name = name_from_mode_context(obj, mode)
                results.append({
                    pcs: obj,
                    mode: mode,
                    chord_name: chord_name,
                    formula: derive_formula(obj, mode),
                })

    return results  // ~1,000 combinations from 479 unique objects
```

### 5. Chord Naming from Mode Context

**Input**: Chord PCS (with root at 0), parent mode
**Output**: Unambiguous chord formula using mode's interval names

```
name_from_mode_context(chord_pcs, mode):
    mode_formula = mode.interval_names  // e.g., ["R","2","3","#4","5","6","7"]
    mode_pcs_list = tolist(formula_to_pcs(mode.formula))
    chord_pcs_list = tolist(chord_pcs)

    formula_parts = []
    for pc in chord_pcs_list:
        // Find which mode degree this pc corresponds to
        idx = mode_pcs_list.index(pc)
        formula_parts.append(mode_formula[idx])

    return " ".join(formula_parts)
```

This solves the ambiguity problem: is 6 semitones "#4" or "b5"? The answer depends on the parent mode (Lydian → #4, Locrian → b5).

### 6. Diatonic Chord Construction (Stack Thirds)

**Input**: Key (tonic + scale), degree (1-7)
**Output**: Chord PCS and Roman numeral

```
diatonic_triad(key, degree):
    scale_pcs = tolist(key.scale)
    root_idx = degree - 1
    // Stack every other scale note: root, 3rd, 5th
    notes = [
        scale_pcs[root_idx],
        scale_pcs[(root_idx + 2) % 7],
        scale_pcs[(root_idx + 4) % 7],
    ]
    return fromlist(notes)

diatonic_seventh(key, degree):
    scale_pcs = tolist(key.scale)
    root_idx = degree - 1
    notes = [
        scale_pcs[root_idx],
        scale_pcs[(root_idx + 2) % 7],
        scale_pcs[(root_idx + 4) % 7],
        scale_pcs[(root_idx + 6) % 7],
    ]
    return fromlist(notes)
```

### 7. Roman Numeral Assignment

**Input**: Chord PCS, key
**Output**: Roman numeral string

```
roman_numeral(chord_pcs, key):
    // Find the degree of the chord root within the key
    chord_root = lowest_pc(chord_pcs)
    scale_pcs = tolist(key.scale)
    degree = scale_pcs.index(chord_root) + 1

    // Determine quality
    quality = chord_quality(chord_pcs)
    numerals = ["I","II","III","IV","V","VI","VII"]
    rn = numerals[degree - 1]

    if quality in [MINOR, DIMINISHED, HALF_DIM]:
        rn = rn.lower()
    if quality == DIMINISHED:
        rn += "°"
    if quality == AUGMENTED:
        rn += "+"
    if quality == HALF_DIM:
        rn += "ø"
    // Add 7 for seventh chords
    if popcount(chord_pcs) >= 4:
        rn += "7"

    return rn
```

### 8. Chord Inversion Detection

**Input**: Voiced chord (MIDI notes, lowest note specified)
**Output**: Inversion type (root, 1st, 2nd, 3rd)

```
detect_inversion(bass_pc, chord_pcs):
    pcs = sorted(tolist(chord_pcs))
    if bass_pc == pcs[0]: return ROOT_POSITION
    if bass_pc == pcs[1]: return FIRST_INVERSION   // 3rd in bass
    if bass_pc == pcs[2]: return SECOND_INVERSION   // 5th in bass
    if len(pcs) > 3 and bass_pc == pcs[3]:
        return THIRD_INVERSION   // 7th in bass
    return SLASH_CHORD  // bass note not in chord
```

### 9. Shell Chord Extraction

**Input**: Full chord PCS (typically 4+ notes)
**Output**: Shell chord (root + 3rd + 7th)

```
shell_chord(chord_pcs, root_pc):
    pcs = tolist(chord_pcs)
    // Root is at pc 0 (normalized)
    third = null
    seventh = null
    for pc in pcs:
        if pc == root_pc: continue
        interval = (pc - root_pc + 12) % 12
        if interval in [3, 4]:  // minor or major 3rd
            third = pc
        if interval in [9, 10, 11]:  // bb7, b7, 7
            seventh = pc
    if third and seventh:
        return fromlist([root_pc, third, seventh])
    return chord_pcs  // fallback: return original
```

### 10. Slash Chord Decomposition

**Input**: Bass note PC, upper chord PCS
**Output**: Full chord name "Upper/Bass"

```
slash_chord_name(bass_pc, upper_pcs):
    upper_name = pcs_to_chord_name(upper_pcs)
    bass_name = pc_to_note_name(bass_pc)
    combined = upper_pcs | (1 << bass_pc)
    // Check if the combination is a known chord type
    full_name = pcs_to_chord_name(combined)
    if full_name:
        inv = detect_inversion(bass_pc, combined)
        return full_name + " (" + inv.name + ")"
    return upper_name + "/" + bass_name
```

### 11. Chord-Scale Compatibility Test

**Input**: Chord PCS, mode PCS
**Output**: Boolean + list of available tensions + list of avoid notes

```
chord_scale_compatibility(chord_pcs, mode_pcs):
    // Test 1: Is chord a subset of mode?
    if not is_subset(chord_pcs, mode_pcs):
        return {compatible: false}

    // Test 2: Find avoid notes
    chord_list = tolist(chord_pcs)
    mode_list = tolist(mode_pcs)
    avoid_notes = []
    available = []

    for scale_pc in mode_list:
        if scale_pc in chord_list: continue
        // Is this scale tone one semitone above any chord tone?
        is_avoid = false
        for chord_pc in chord_list:
            if (scale_pc - chord_pc + 12) % 12 == 1:
                is_avoid = true
                break
        if is_avoid:
            avoid_notes.append(scale_pc)
        else:
            available.append(scale_pc)

    return {
        compatible: true,
        avoid_notes: avoid_notes,
        available_tensions: available,
    }
```

### 12. Tritone Substitution

**Input**: Dominant 7th chord PCS
**Output**: Tritone substitute chord PCS

```
tritone_sub(dom7_pcs):
    // Transpose by 6 semitones (tritone)
    return leftshift(dom7_pcs, 6)
```

The tritone substitute shares the same tritone interval (3rd and 7th swap roles).

### 13. Leave-One-Out (Parent Set Classes)

**Input**: 12-bit PCS
**Output**: All unique set classes obtainable by removing one note

```
leave_one_out(x):
    parents = set()
    for pc in tolist(x):
        reduced = x & ~(1 << pc)
        parents.add(prime_form(reduced))
    return parents
```

## Data Structures Used

- `ChordType`: struct { name: []const u8, formula: []const u8, pcs: u12 }
- `ChordInstance`: struct { root: PitchClass, chord_type: *ChordType }
- `RomanNumeral`: struct { degree: u4, quality: ChordQuality, extensions: []const u8 }
- `SlashChord`: struct { upper: ChordInstance, bass: PitchClass }
- `ChordModeMatch`: struct { chord: u12, mode: ModeType, formula: []const u8 }
- Static table: ~100 chord types, ~1000 chord-mode matches

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Prime Form and Set Class](prime-form-and-set-class.md)
- [Chromatic Cluster Detection](chromatic-cluster-detection.md)
- [Scale, Mode, and Key](scale-mode-key.md)
