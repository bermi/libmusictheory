# 0012 — Guitar Fretboard

> Dependencies: 0009 (Chord Construction)
> Blocks: 0016 (Fret Diagram SVGs)

## Objective

Implement guitar-specific algorithms: tuning, fret-MIDI mapping, CAGED system, voicing generation, and pitch-class guide overlay.

## Research References

- [Guitar and Keyboard](../../research/guitar-and-keyboard.md)
- [Guitar Voicing](../../research/algorithms/guitar-voicing.md)
- [Guitar and Keyboard](../../research/data-structures/guitar-and-keyboard.md)

## Implementation Steps

### 1. Tuning and Fret Mapping (`src/guitar.zig`)

- `Tuning` type: [6]MidiNote
- Standard + 4 alternative tunings
- `fretToMidi(string, fret, tuning) → MidiNote`
- `midiToFretPositions(MidiNote, tuning) → []FretPosition`
- `pcToFretPositions(PitchClass, fret_range, tuning) → []FretPosition`

### 2. Voicing Generation

- `generateVoicings(PitchClassSet, tuning, max_span) → []GuitarVoicing`
- Constraints: ≥3 sounding strings, all chord PCs present, hand span ≤ 4 frets
- Pruning for practical playability

### 3. CAGED System

- 5 open shapes (C, A, G, E, D) as base templates
- `cagedPositions(root_pc, quality) → [5]CAGEDPosition`
- Shift shapes up the neck based on root pitch class offset

### 4. Pitch-Class Guide Overlay

- `pitchClassGuide(selected_positions, tuning) → []GuideDot`
- Show same pitch class at opacity 0.35 on other strings

### 5. URL Format

- `fretsToUrl(GuitarVoicing) → []const u8` — comma-separated format
- `urlToFrets([]const u8) → GuitarVoicing` — parse URL back

### 6. Tests

- Standard tuning: string 0 fret 0 = MIDI 40 (E2)
- Inverse map: MIDI 60 (C4) → positions on strings 1-5
- CAGED: C major has 5 positions spanning fretboard
- Voicing: C major open = [x,3,2,0,1,0] or similar
- Guide overlay: selecting E on string 0 shows E positions everywhere

## Validation

- `tmp/harmoniousapp.net/js-client/frets.js`: all fretboard interaction logic
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `stringMidinotes` = [40,45,50,55,59,64]
- `tmp/harmoniousapp.net/eadgbe/` directory: 2,278 fret diagram SVGs for visual verification

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
- Standard tuning string 0 fret 0 = MIDI 40 (E2).
- Inverse map for MIDI 60 produces positions on strings 1-5.
- CAGED C major has 5 valid positions.
- Generated voicings are playable (hand span <= 4 frets).

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/js-client/frets.js`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `stringMidinotes` = [40,45,50,55,59,64], `tmp/harmoniousapp.net/eadgbe/` directory: 2,278 fret diagram SVGs)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~350 lines of Zig code + ~200 lines of tests
