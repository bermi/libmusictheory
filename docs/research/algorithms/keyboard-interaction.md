# Keyboard Interaction and MIDI Mapping

> References: [Guitar and Keyboard](../guitar-and-keyboard.md)
> Source: `tmp/harmoniousapp.net/js-client/kb.js`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`
> Source: `tmp/harmoniousapp.net/p/f2/Chords-for-Keyboard.html`

## Overview

Algorithms for the interactive piano keyboard: key toggling, selection state management, note highlighting with octave equivalence, and URL state persistence.

## Static Data

### Keyboard Layout

```
KEYBOARD_RANGE = (36, 83)  // MIDI C2 to B5, 4 octaves
NUM_KEYS = 48
MIDDLE_C = 60

// One-octave key pattern
// '_' = white key position, ':' = black key position
KEY_PATTERN = "_:_:__:_:_:_"  // C C# D D# E F F# G G# A A# B
WHITE_KEY_PCS = [0, 2, 4, 5, 7, 9, 11]  // C D E F G A B
BLACK_KEY_PCS = [1, 3, 6, 8, 10]  // C# D# F# G# A#
```

## Algorithms

### 1. Toggle Key Selection

**Input**: MIDI note number, current selection set
**Output**: Updated selection set

```
toggle_key(midi_note, selected):
    if midi_note in selected:
        selected.remove(midi_note)
    else:
        selected.add(midi_note)
    return selected
```

### 2. Update Key Visual State

**Input**: Set of selected MIDI notes, accidental preference
**Output**: Visual state for each key (opacity, label)

```
FULL_OPACITY = 1.0
HALF_OPACITY = 0.5  // octave equivalents
NORMAL_OPACITY = 0.0  // unselected

update_key_visuals(selected_notes, accid_pref):
    selected_pcs = {midi % 12 for midi in selected_notes}
    visuals = []
    for midi in KEYBOARD_RANGE[0]..KEYBOARD_RANGE[1]:
        pc = midi % 12
        if midi in selected_notes:
            visuals.append({
                midi: midi,
                opacity: FULL_OPACITY,
                label: spell_with_preference(pc, accid_pref),
            })
        elif pc in selected_pcs:
            visuals.append({
                midi: midi,
                opacity: HALF_OPACITY,
                label: spell_with_preference(pc, accid_pref),
            })
        else:
            visuals.append({
                midi: midi,
                opacity: NORMAL_OPACITY,
                label: null,
            })
    return visuals
```

### 3. MIDI Notes to URL State

**Input**: Set of selected MIDI notes
**Output**: URL-encoded string

```
notes_to_url(selected_notes):
    // Sort ascending
    sorted_notes = sorted(selected_notes)
    // Format as spelled names with octave
    names = [midi_to_name(n) for n in sorted_notes]
    return "-".join(names)

// Example: {60, 64, 67} → "C4-E4-G4"
```

### 4. URL State to MIDI Notes

**Input**: URL-encoded string
**Output**: Set of MIDI notes

```
url_to_notes(url_str):
    notes = set()
    for name in url_str.split("-"):
        midi = name_to_midi(name)
        notes.add(midi)
    return notes
```

### 5. Playback Style Detection

**Input**: Set of MIDI notes
**Output**: Playback mode ("solo" | "sequential" | "simultaneous")

```
playback_style(selected_notes, pcs):
    if len(selected_notes) == 1:
        return "solo"
    if is_scaley(pcs):
        return "sequential"  // play notes one at a time, ascending
    return "simultaneous"  // play all at once as chord
```

### 6. Pitch Class Set from Keyboard Selection

**Input**: Set of selected MIDI notes
**Output**: 12-bit PCS (octave-collapsed)

```
selection_to_pcs(selected_notes):
    result = 0
    for midi in selected_notes:
        result |= (1 << (midi % 12))
    return result
```

## Data Structures Used

- `KeyboardState`: struct { selected_notes: bounded set of MIDI notes, accid_pref: AccidentalPreference }
- `KeyVisual`: struct { midi: u8, opacity: f32, label: ?NoteName }

## Dependencies

- [Note Spelling](note-spelling.md)
- [Scale, Mode, and Key](scale-mode-key.md) (for `is_scaley`)
