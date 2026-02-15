# Note Spelling and Key-Context-Aware Naming

> References: [Guitar and Keyboard](../guitar-and-keyboard.md), [Scales and Modes](../scales-and-modes.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` functions: `numsToNoteOctaveNames`, `convertScaleToKeyboardUrl`
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` data: `justKeys`, `moreScales`, `keysMOM`, `numToNameList`

## Overview

Note spelling converts pitch class integers into human-readable note names (e.g., pitch class 1 → "C#" or "Db"). The correct spelling depends on key context. This is one of the most complex algorithms due to the 35 possible spellings and multiple key/scale contexts.

## Static Data

### Note Name Spellings (35 total → 12 pitch classes)

```
PC_TO_NAMES = {
    0:  ["C", "B#", "Dbb"],
    1:  ["C#", "Db"],
    2:  ["D", "C##", "Ebb"],
    3:  ["D#", "Eb"],
    4:  ["E", "D##", "Fb"],
    5:  ["F", "E#", "Gbb"],
    6:  ["F#", "Gb", "E##"],
    7:  ["G", "F##", "Abb"],
    8:  ["G#", "Ab"],
    9:  ["A", "G##", "Bbb"],
    10: ["A#", "Bb"],
    11: ["B", "A##", "Cb"],
}
```

### Key Signature Note Spellings

```
JUST_KEYS = {
    "C":  {0:"C", 2:"D", 4:"E", 5:"F", 7:"G", 9:"A", 11:"B"},
    "G":  {0:"C", 2:"D", 4:"E", 6:"F#", 7:"G", 9:"A", 11:"B"},
    "D":  {1:"C#", 2:"D", 4:"E", 6:"F#", 7:"G", 9:"A", 11:"B"},
    "A":  {1:"C#", 2:"D", 4:"E", 6:"F#", 8:"G#", 9:"A", 11:"B"},
    "E":  {1:"C#", 4:"E", 6:"F#", 8:"G#", 9:"A", 11:"B", 3:"D#"},
    "B":  {1:"C#", 3:"D#", 4:"E", 6:"F#", 8:"G#", 9:"A#", 11:"B"},
    "F#": {0:"B#", 1:"C#", 3:"D#", 5:"E#", 6:"F#", 8:"G#", 10:"A#"},
    "C#": {0:"B#", 1:"C#", 3:"D#", 5:"E#", 6:"F#", 8:"G#", 10:"A#"},
    "F":  {0:"C", 2:"D", 4:"E", 5:"F", 7:"G", 9:"A", 10:"Bb"},
    "Bb": {0:"C", 2:"D", 3:"Eb", 5:"F", 7:"G", 9:"A", 10:"Bb"},
    "Eb": {0:"C", 2:"D", 3:"Eb", 5:"F", 7:"G", 8:"Ab", 10:"Bb"},
    "Ab": {0:"C", 1:"Db", 3:"Eb", 5:"F", 7:"G", 8:"Ab", 10:"Bb"},
    "Db": {0:"C", 1:"Db", 3:"Eb", 5:"F", 6:"Gb", 8:"Ab", 10:"Bb"},
    "Gb": {0:"Cb", 1:"Db", 3:"Eb", 4:"Fb", 6:"Gb", 8:"Ab", 10:"Bb"},
    "Cb": {0:"Cb", 1:"Db", 3:"Eb", 4:"Fb", 6:"Gb", 8:"Ab", 10:"Bb"},
}

// Additional scales: melodic minor, harmonic minor, harmonic major,
// octatonic, whole-tone, double augmented hexatonic
// Each has its own spelling table per transposition
```

## Algorithms

### 1. MIDI Note to Spelled Name (with Key Context)

**Input**: MIDI note number, key context (optional)
**Output**: Spelled note name with octave (e.g., "C#4", "Db4")

```
midi_to_name(midi, key=null):
    pc = midi % 12
    octave = (midi / 12) - 1

    if key:
        letter = key.spell(pc)
    else:
        letter = default_spelling(pc)  // sharps by default

    return letter + str(octave)
```

### 2. Accidental Preference Mode

**Input**: Pitch class, preference ("sharp" | "flat" | "auto")
**Output**: Spelled note name

```
spell_with_preference(pc, preference):
    if preference == "sharp":
        SHARP_NAMES = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        return SHARP_NAMES[pc]
    elif preference == "flat":
        FLAT_NAMES = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]
        return FLAT_NAMES[pc]
    else:  // auto
        return auto_spell(pc)
```

### 3. Auto-Spell: Best Key Signature Detection

**Input**: Array of pitch classes (the notes to spell)
**Output**: Best matching key signature and spelled names

```
auto_spell_notes(pitch_classes):
    best_key = null
    best_score = -1

    // Search through all key signature note maps
    for key_name, note_map in ALL_KEY_MAPS:  // justKeys + moreScales
        // Score = how many of the input PCs this key can spell
        score = 0
        for pc in pitch_classes:
            if pc in note_map:
                score += 1
        if score > best_score:
            best_score = score
            best_key = key_name

    // Use the best key's spelling
    return {key: best_key, spellings: [best_key.spell(pc) for pc in pitch_classes]}
```

The site's `numToNameList` precomputes this for all keys: for each key, a dict mapping pc → spelled name. The algorithm searches through this list.

### 4. Scale URL to Keyboard URL Conversion

**Input**: Scale URL (e.g., `/p/34/C-Major.html`)
**Output**: Keyboard URL with correct note spellings

```
convert_scale_to_keyboard_url(scale_pcs, tonic_name):
    // Determine key from tonic
    key = find_key(tonic_name)
    // Spell each pitch class in the scale
    note_names = []
    for pc in tolist(scale_pcs):
        name = key.spell(pc)
        note_names.append(name)
    // Build keyboard URL
    return "/keyboard/" + "-".join(note_names) + ".html"
```

### 5. Grand Staff Distribution

**Input**: Array of MIDI notes
**Output**: Two arrays — treble clef notes and bass clef notes

```
MIDDLE_C = 60  // MIDI note for C4

split_for_grand_staff(midi_notes):
    treble = [n for n in midi_notes if n >= MIDDLE_C]
    bass = [n for n in midi_notes if n < MIDDLE_C]
    return (treble, bass)
```

### 6. Octave Name Computation

**Input**: MIDI note number
**Output**: Scientific pitch notation octave (e.g., C4 for MIDI 60)

```
midi_to_octave(midi):
    return (midi / 12) - 1

// MIDI 60 → octave 4 (C4)
// MIDI 69 → octave 5 (A4 = 440Hz)
// MIDI 21 → octave 0 (A0, lowest piano key)
```

## Edge Cases

- **Enharmonic ambiguity**: Pitch class 6 is F# in sharp keys, Gb in flat keys
- **Double accidentals**: B# = C, Cb = B, E# = F, Fb = E (needed for proper key signature spelling in C#/Cb major)
- **Mixed contexts**: When a chord spans notes from different keys (chromatic alterations), fall back to sharp/flat preference
- **Non-diatonic scales**: Octatonic, whole-tone, harmonic minor all have their own spelling conventions stored in `moreScales`

## Data Structures Used

- `NoteName`: struct { letter: u3 (A-G), accidental: enum{DoubleFlat, Flat, Natural, Sharp, DoubleSharp} }
- `SpelledNote`: struct { name: NoteName, octave: i8 }
- `NoteSpellingMap`: [12]NoteName — maps pitch class to name for a given key/scale
- `AccidentalPreference`: enum { Sharp, Flat, Auto }
- Static tables: 15 major + 15 melodic minor + 15 harmonic minor + 15 harmonic major + 4 octatonic + 2 whole-tone + 4 double augmented = ~70 spelling maps

## Dependencies

- [Scale, Mode, and Key](scale-mode-key.md)
