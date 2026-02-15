# 0010 — Harmony Analysis

> Dependencies: 0008 (Keys/Signatures), 0009 (Chord Construction)
> Blocks: 0018 (Misc SVGs), 0019 (Key Slider)

## Objective

Implement diatonic harmony analysis: Roman numeral assignment, chord-scale compatibility, avoid notes, extensions, and reharmonization tools.

## Research References

- [Keys, Harmony and Progressions](../../research/keys-harmony-and-progressions.md)
- [Chord Construction and Naming](../../research/algorithms/chord-construction-and-naming.md)

## Implementation Steps

### 1. Diatonic Chord Construction (`src/harmony.zig`)

- `diatonicTriad(Key, degree) → ChordInstance`
- `diatonicSeventh(Key, degree) → ChordInstance`
- `DiatonicHarmony.init(Key) → DiatonicHarmony` (all 7 triads + 7ths)

### 2. Roman Numeral Assignment

- `romanNumeral(ChordInstance, Key) → RomanNumeral`
- Format: uppercase/lowercase, quality suffix (°, +, ø), extension (7, 9, etc.)

### 3. Chord-Scale Compatibility

- `chordScaleCompatibility(chord, mode) → ChordScaleMatch`
- Returns: compatible (bool), avoid notes (PCS), available tensions (PCS)

### 4. Avoid Note Detection

A scale tone one semitone above a chord tone:
- Identify for all 7 diatonic modes × their chord types
- Verify: Lydian has NO avoid notes

### 5. Tritone Substitution

- `tritoneSub(dom7) → ChordInstance` — transpose by 6 semitones

### 6. Diatonic Voice-Leading Circuits

- Circle of fifths order: vii-iii-vi-ii-V-I-IV
- Circle of thirds order: I-vi-IV-ii-vii-V-iii

### 7. Tests

- C major diatonic triads: C, Dm, Em, F, G, Am, Bdim
- Roman numerals: I, ii, iii, IV, V, vi, vii°
- Avoid notes: F is avoid in Ionian (I), C is avoid in Mixolydian (V)
- Lydian: zero avoid notes
- Tritone sub of G7 = Db7
- Chord-scale: Dm7 compatible with D Dorian

## Validation

- `tmp/harmoniousapp.net/p/b9/Diatonic-Modes-Chords.html`: all diatonic chords
- `tmp/harmoniousapp.net/p/05/Extensions-Avoid-Notes.html`: complete avoid note table
- `tmp/harmoniousapp.net/p/bc/Top-Down-View.html`: 17 modes overview

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
- C major diatonic triads = C Dm Em F G Am Bdim.
- Lydian has zero avoid notes.
- Tritone sub of G7 = Db7.
- Roman numeral assignment correct for all 7 degrees in major and minor keys.

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/p/b9/Diatonic-Modes-Chords.html`, `tmp/harmoniousapp.net/p/05/Extensions-Avoid-Notes.html`, `tmp/harmoniousapp.net/p/bc/Top-Down-View.html`)

## Implementation History (Point-in-Time)

- `f203d0c` (2026-02-15):
  - Shipped behavior: Added `src/harmony.zig` with diatonic triad/seventh construction for major and natural minor keys, `DiatonicHarmony` snapshots, Roman numeral formatting with quality suffixes and seventh extensions, chord-scale compatibility with avoid-note and available-tension extraction, tritone substitution, and diatonic circuit degree orders.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~350 lines of Zig code + ~300 lines of tests
