# 0008 — Keys and Key Signatures

> Dependencies: 0007 (Scales/Modes)
> Blocks: 0009 (Chord Construction via note context), 0010 (Harmony), 0013 (Keyboard), 0015 (Staff Notation)

## Objective

Implement key signatures, note spelling from key context, circle of fifths navigation, and relative/parallel key computation.

## Research References

- [Keys, Harmony and Progressions](../../research/keys-harmony-and-progressions.md)
- [Scale, Mode, Key](../../research/algorithms/scale-mode-key.md)
- [Note Spelling](../../research/algorithms/note-spelling.md)
- [Scales, Modes, Keys](../../research/data-structures/scales-modes-keys.md)

## Implementation Steps

### 1. Key Signature (`src/key_signature.zig`)

- `KeySignature` struct with type (sharps/flats/natural), count, accidental list
- `fromTonic(PitchClass, KeyQuality) → KeySignature`
- Sharp order: F C G D A E B; Flat order: B E A D G C F

### 2. Key (`src/key.zig`)

- `Key` struct with tonic, quality, signature, scale
- `relativeMajor()`, `relativeMinor()`, `parallelKey()`
- Circle of fifths: `nextKeySharp()`, `nextKeyFlat()`

### 3. Note Spelling (`src/note_spelling.zig`)

- 70+ `NoteSpellingMap` tables (15 major + 15 melodic minor + 15 harmonic minor + 15 harmonic major + 4 octatonic + 2 whole-tone + 4 double aug hex)
- `spellNote(PitchClass, Key) → NoteName`
- `autoSpell([]PitchClass) → (Key, []NoteName)` — best key detection
- `spellWithPreference(PitchClass, AccidentalPreference) → NoteName`

### 4. URL Conversion

- `convertScaleToKeyboardUrl(PitchClassSet, NoteName) → []const u8`

### 5. Tests

- All 15 major key signatures have correct sharps/flats
- Relative key: C major ↔ A minor, G major ↔ E minor
- Parallel key: C major ↔ C minor
- Circle of fifths: C → G → D → A → E → B → F# → Db → Ab → Eb → Bb → F → C
- Note spelling: pitch class 6 = F# in G major, Gb in Db major
- Auto-spell: {0,4,7} in sharp context → C E G

## Validation

- `tmp/harmoniousapp.net/p/a7/Keys.html`: all key information
- `tmp/harmoniousapp.net/p/d9/Circle-of-Fifths-Keys.html`: circle of fifths
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `justKeys`, `moreScales`, `keysMOM`, `numToNameList`, `numsToNoteOctaveNames`

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes, `zig build verify` passes.
- All 15 major key signatures have correct sharps/flats count.
- Circle of fifths completes a full cycle of 12 keys.
- Note spelling for pitch class 6 = F# in G major and Gb in Db major.

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/p/a7/Keys.html`, `tmp/harmoniousapp.net/p/d9/Circle-of-Fifths-Keys.html`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `justKeys`, `numToNameList`)

## Implementation History (Point-in-Time)

- `cdc9349` (2026-02-15):
  - Shipped behavior: Added key signature derivation, key relations and circle-of-fifths navigation, key-aware note spelling, and auto-spell support across `src/key_signature.zig`, `src/key.zig`, and `src/note_spelling.zig`.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~400 lines of Zig code (heavy static data) + ~200 lines of tests
