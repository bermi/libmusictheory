# 0002 — Core Types

> Dependencies: None (foundation plan)
> Blocked by: Nothing
> Blocks: 0003 (Set Operations)

## Objective

Implement the fundamental data types that represent pitch, intervals, and note names in 12-TET.

## Research References

- [Pitch and Intervals](../../research/pitch-and-intervals.md)
- [Pitch and Pitch Class](../../research/data-structures/pitch-and-pitch-class.md)
- [Intervals and Vectors](../../research/data-structures/intervals-and-vectors.md)

## Implementation Steps

### 1. Create `src/pitch.zig`

Define core types:
```zig
pub const PitchClass = u4;      // 0-11
pub const MidiNote = u7;        // 0-127
pub const Interval = u7;        // 0-127 semitones
pub const IntervalClass = u3;   // 1-6
```

Constants:
```zig
pub const pc = struct {
    pub const C = 0;
    pub const Cs = 1;
    // ... all 12
};
```

Conversion functions:
- `midiToPC(MidiNote) → PitchClass`
- `midiToOctave(MidiNote) → i4`
- `pcToMidi(PitchClass, octave) → MidiNote`
- `midiToFrequency(MidiNote) → f64`
- `toIntervalClass(u4) → IntervalClass`

### 2. Create `src/note_name.zig`

```zig
pub const Letter = enum(u3) { A, B, C, D, E, F, G };
pub const Accidental = enum(i3) { double_flat, flat, natural, sharp, double_sharp };
pub const NoteName = struct { letter: Letter, accidental: Accidental };
pub const SpelledNote = struct { name: NoteName, octave: i4 };
```

Functions:
- `NoteName.toPitchClass() → PitchClass`
- `SpelledNote.toMidi() → MidiNote`
- `NoteName.format() → []const u8`

Static data:
- 35 note name spellings
- Sharp names array, flat names array
- `AccidentalPreference` enum

### 3. Create `src/interval.zig`

Named interval constants and the formula-to-semitone mapping table.

```zig
pub const FormulaToken = enum { root, flat2, nat2, ... };
pub const FORMULA_SEMITONES: array of u4
pub const BASE_INTERVALS: array for compound intervals (9th, 11th, 13th)
```

### 4. Write tests in `src/tests/pitch_test.zig`

- All 12 pitch class constants correct
- MIDI ↔ pitch class round-trip
- MIDI ↔ frequency (verify A4 = 440Hz = MIDI 69)
- Note name ↔ pitch class (all 35 spellings)
- Interval class symmetry (1+11=6, 2+10=6, etc.)
- Formula token ↔ semitone values

## Validation Against Site Data

- `tmp/harmoniousapp.net/p/ca/Pitch-Intervals.html`: interval table, mnemonic songs
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `fromNoteName` map (35 entries), `strToPC` map, `baseInterval` array

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

All of the following must pass before this plan is considered complete:

- [x] `./verify.sh` passes
- [x] `zig build verify` passes
- [x] All 12 pitch class constants correct
- [x] MIDI↔PC round-trip for all 128 values
- [x] A4=440Hz=MIDI 69
- [x] All 35 note name spellings ↔ pitch class
- [x] Formula token ↔ semitone values for all tokens

## Verification Data Sources

- **harmoniousapp.net** (`tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `fromNoteName` map, `strToPC` map, `baseInterval` array)

## Implementation History (Point-in-Time)

- `e0275e9` (2026-02-15):
  - Shipped behavior: Added `pitch`, `note_name`, and `interval` modules; implemented MIDI/pitch-class conversion, note spelling support (35 spellings), formula token semitone mappings, and focused unit tests in `src/tests/pitch_test.zig`.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~200 lines of Zig code
- ~150 lines of tests
- 3 source files + 1 test file
