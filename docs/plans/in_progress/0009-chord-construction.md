# 0009 — Chord Construction and The Game

> Dependencies: 0006 (Cluster/Evenness), 0007 (Scales/Modes)
> Blocks: 0010 (Harmony), 0012 (Guitar), 0015 (Staff Notation)

## Objective

Implement chord types, chord formula parsing, chord naming, shell/slash chords, and The Game algorithm for exhaustive chord-mode cataloging.

## Research References

- [Chords and Voicings](../../research/chords-and-voicings.md)
- [Chord Construction and Naming](../../research/algorithms/chord-construction-and-naming.md)
- [Chords and Harmony](../../research/data-structures/chords-and-harmony.md)

## Implementation Steps

### 1. Chord Types (`src/chord_type.zig`)

Define ~100 chord types with name, abbreviation, formula, PCS:
- 6 triads, 9 seventh chords, extended (9th, 11th, 13th), add chords, altered, augmented 6th

### 2. Formula Parsing

- `formulaToPCS(formula: []const u8) → PitchClassSet`
- `formulaToMidi(formula, root_midi) → []MidiNote`

### 3. Chord Naming (Reverse Lookup)

- `pcsToChordName(PitchClassSet) → ?[]const u8` — lookup PCS in chord type table
- Handle root normalization (rotate to pc 0)

### 4. The Game Algorithm

```
1. Enumerate 2048 OTC objects (PCS including pc 0)
2. Filter card 3-9 → 1,969
3. Filter cluster-free → 560
4. Match against 17 modes → 479 objects with ~1,000 combinations
5. Name each chord from mode context
```

Store as compile-time table: `[~1000]GameResult`

### 5. Chord Inversions

- `detectInversion(bass_pc, chord_pcs) → Inversion`

### 6. Shell Chords

- `shellChord(chord_pcs, root) → PitchClassSet` (root + 3rd + 7th)

### 7. Slash Chords

- `SlashChord` struct, decomposition and naming

### 8. Leave-One-Out

- `leaveOneOut(PitchClassSet) → set of PitchClassSet` (parent set classes)

### 9. Tests

- All triad types produce correct PCS values
- Chord naming: {0,4,7} → "Major", {0,3,7} → "Minor"
- The Game: verify 560 cluster-free OTC objects, 479 mode subsets
- Shell chord: Cmaj7 → {C, E, B}
- Inversions: C/E = first inversion, C/G = second inversion
- Formula parsing round-trip

## Validation

- `tmp/harmoniousapp.net/p/fc/Chords.html`: chord catalog
- `tmp/harmoniousapp.net/p/69/The-Game.html`: exhaustive algorithm
- `tmp/harmoniousapp.net/p/e7/Leave-Out-Notes.html`: shell chords, slash chords
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `formToList`, `formToNum`, `strToPC`

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
- All chord types match tonal-ts `chords.json` interval arrays.
- The Game produces exactly 560 cluster-free OTC objects and ~479 mode subsets.
- Shell chord extraction correct.
- Inversion detection correct.

## Verification Data Sources

- tonal-ts (`/Users/bermi/tmp/tonal-ts/packages/dictionary/data/chords.json` — 116 chord types)
- music21 (`/Users/bermi/tmp/music21/music21/chord/tables.py` — chord quality mapping)
- harmoniousapp.net (`tmp/harmoniousapp.net/p/fc/Chords.html`, `tmp/harmoniousapp.net/p/69/The-Game.html`)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~500 lines of Zig code + ~400 lines of tests
