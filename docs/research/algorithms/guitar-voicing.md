# Guitar Voicing and Fretboard Algorithms

> References: [Guitar and Keyboard](../guitar-and-keyboard.md)
> Source: `tmp/harmoniousapp.net/js-client/frets.js`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` (stringMidinotes)
> Source: `tmp/harmoniousapp.net/p/62/Chords-for-Guitar.html`, `tmp/harmoniousapp.net/p/*/CAGED-Fretboard-System.html`, `tmp/harmoniousapp.net/p/*/Fret-Diagrams.html`

## Overview

Algorithms for mapping between MIDI notes and guitar fret positions, generating playable voicings, and implementing the CAGED fretboard system.

## Static Data

### Standard Tuning

```
STRING_OPEN_MIDI = [40, 45, 50, 55, 59, 64]
// String 0 (lowest) = E2 = MIDI 40
// String 1 = A2 = MIDI 45
// String 2 = D3 = MIDI 50
// String 3 = G3 = MIDI 55
// String 4 = B3 = MIDI 59
// String 5 (highest) = E4 = MIDI 64

STRING_INTERVALS = [5, 5, 5, 4, 5]  // intervals between adjacent strings in semitones
MAX_FRET = 24
MAX_HAND_SPAN = 4  // frets
```

### Alternative Tunings

```
TUNINGS = {
    "Standard":  [40, 45, 50, 55, 59, 64],
    "Drop D":    [38, 45, 50, 55, 59, 64],
    "DADGAD":    [38, 45, 50, 55, 57, 62],
    "Open G":    [38, 43, 50, 55, 59, 62],
    "Open D":    [38, 45, 50, 54, 57, 62],
}
```

## Algorithms

### 1. Fret Position to MIDI Note

**Input**: String index (0-5), fret number (0-24)
**Output**: MIDI note number

```
fret_to_midi(string_idx, fret, tuning=STANDARD):
    return tuning[string_idx] + fret
```

**Complexity**: O(1)

### 2. MIDI Note to All Fret Positions (Inverse Map)

**Input**: MIDI note number
**Output**: Array of (string, fret) pairs

```
midi_to_fret_positions(midi_note, tuning=STANDARD):
    positions = []
    for i in 0..5:
        fret = midi_note - tuning[i]
        if fret >= 0 and fret <= MAX_FRET:
            positions.append((i, fret))
    return positions
```

**Complexity**: O(6) = O(1)

### 3. Pitch Class to All Fret Positions

**Input**: Pitch class (0-11), optional fret range
**Output**: Array of (string, fret) pairs for all octaves

```
pc_to_fret_positions(pc, min_fret=0, max_fret=MAX_FRET, tuning=STANDARD):
    positions = []
    for string_idx in 0..5:
        open_pc = tuning[string_idx] % 12
        // First fret with this pitch class on this string
        first_fret = (pc - open_pc + 12) % 12
        // Generate all octaves
        fret = first_fret
        while fret <= max_fret:
            if fret >= min_fret:
                positions.append((string_idx, fret))
            fret += 12
    return positions
```

**Complexity**: O(6 * MAX_FRET/12) ≈ O(12)

### 4. Playable Voicing Generation

**Input**: Pitch class set (chord to voice), tuning
**Output**: Array of playable 6-string voicings (fret per string, or muted)

```
generate_voicings(chord_pcs, tuning=STANDARD, max_span=4):
    target_pcs = tolist(chord_pcs)
    voicings = []

    // For each possible fret position window
    for base_fret in 0..MAX_FRET:
        // Try all combinations of fret positions per string
        // Each string: muted (-1) or one of the chord PCs within hand span
        candidates_per_string = []
        for string_idx in 0..5:
            options = [-1]  // muted is always an option
            for fret in max(0, base_fret)..min(MAX_FRET, base_fret + max_span):
                midi = tuning[string_idx] + fret
                pc = midi % 12
                if pc in target_pcs:
                    options.append(fret)
            // Also consider open string (fret 0) even if outside span
            if base_fret > 0:
                midi = tuning[string_idx]
                if (midi % 12) in target_pcs:
                    options.append(0)
            candidates_per_string.append(options)

        // Generate all combinations
        for combo in cartesian_product(candidates_per_string):
            voicing = list(combo)
            // Validate: at least 3 notes sounding
            sounding = [f for f in voicing if f >= 0]
            if len(sounding) < 3: continue
            // Validate: all chord PCs present in voicing
            voiced_pcs = {(tuning[i] + voicing[i]) % 12
                          for i in 0..5 if voicing[i] >= 0}
            if not all(pc in voiced_pcs for pc in target_pcs): continue
            // Validate: no muted strings between sounding strings
            if has_interior_muted(voicing): continue  // optional constraint
            // Validate: hand span
            fretted = [f for f in voicing if f > 0]
            if len(fretted) > 0 and max(fretted) - min(fretted) > max_span:
                continue
            voicings.append(voicing)

    return deduplicate(voicings)
```

Note: Exhaustive generation is expensive. Practical implementations use CAGED shapes as templates.

**Complexity**: O(MAX_FRET * 6^MAX_SPAN) — bounded but large; pruning essential

### 5. CAGED System Position Computation

**Input**: Root pitch class, chord quality (major/minor/7th etc.)
**Output**: 5 CAGED positions (each a 6-element fret array)

```
CAGED_SHAPES = {
    "C": {
        "major": [-1, 3, 2, 0, 1, 0],  // C major open shape
        "root_string": 1,  // A string
        "root_fret": 3,
    },
    "A": {
        "major": [-1, 0, 2, 2, 2, 0],
        "root_string": 1,
        "root_fret": 0,
    },
    "G": {
        "major": [3, 2, 0, 0, 0, 3],
        "root_string": 0,
        "root_fret": 3,
    },
    "E": {
        "major": [0, 2, 2, 1, 0, 0],
        "root_string": 0,
        "root_fret": 0,
    },
    "D": {
        "major": [-1, -1, 0, 2, 3, 2],
        "root_string": 2,
        "root_fret": 0,
    },
}

caged_positions(root_pc, quality):
    positions = []
    for shape_name in ["C", "A", "G", "E", "D"]:
        shape = CAGED_SHAPES[shape_name][quality]
        // Compute offset: how far to shift shape up the neck
        shape_root_midi = STRING_OPEN_MIDI[shape.root_string] + shape.root_fret
        shape_root_pc = shape_root_midi % 12
        offset = (root_pc - shape_root_pc + 12) % 12
        // Shift all fretted positions by offset
        shifted = []
        for i in 0..5:
            if shape[i] < 0:
                shifted.append(-1)  // muted
            elif shape[i] == 0 and offset > 0:
                shifted.append(offset)  // open becomes barred
            else:
                shifted.append(shape[i] + offset)
        positions.append({
            shape: shape_name,
            frets: shifted,
            position: offset,
        })
    return positions
```

### 6. Pitch Class Guide Overlay

**Input**: Current fretboard selection (set of (string, fret) pairs)
**Output**: Guide dots showing same pitch class on other strings

```
GUIDE_OPACITY = 0.35
MUTED_OPACITY = 0.4

pitch_class_guide(selected_positions, tuning=STANDARD):
    // Get pitch classes of selected notes
    selected_pcs = set()
    for (string, fret) in selected_positions:
        pc = (tuning[string] + fret) % 12
        selected_pcs.add(pc)

    // Find all positions with matching pitch classes
    guide_dots = []
    for string in 0..5:
        for fret in 0..MAX_FRET:
            pos = (string, fret)
            if pos in selected_positions: continue
            pc = (tuning[string] + fret) % 12
            if pc in selected_pcs:
                guide_dots.append({
                    position: pos,
                    opacity: GUIDE_OPACITY,
                    pitch_class: pc,
                })
    return guide_dots
```

### 7. Fret Array to URL Format

**Input**: 6-element fret array
**Output**: Comma-separated string for URL

```
frets_to_url(frets):
    parts = []
    for f in frets:
        if f < 0:
            parts.append("x")  // muted
        else:
            parts.append(str(f))
    return ",".join(parts)

// Example: [0,3,2,0,1,0] → "0,3,2,0,1,0" (C major open)
// Example: [-1,0,2,2,2,0] → "x,0,2,2,2,0" (A major open)
```

### 8. Fret Array to MIDI Notes

**Input**: 6-element fret array, tuning
**Output**: Array of MIDI notes (excluding muted strings)

```
frets_to_midi(frets, tuning=STANDARD):
    notes = []
    for i in 0..5:
        if frets[i] >= 0:
            notes.append(tuning[i] + frets[i])
    return notes
```

## Data Structures Used

- `FretPosition`: struct { string: u3, fret: u5 }
- `GuitarVoicing`: struct { frets: [6]i8, tuning: [6]u8 } (-1 = muted, 0-24 = fret)
- `CAGEDPosition`: struct { shape: enum{C,A,G,E,D}, frets: [6]i8, position: u5 }
- `GuideDot`: struct { position: FretPosition, opacity: f32, pitch_class: u4 }
- `Tuning`: [6]u8 (MIDI note numbers of open strings)

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
