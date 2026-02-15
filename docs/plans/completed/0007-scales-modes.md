# 0007 — Scales and Modes

> Dependencies: 0003 (Set Operations)
> Blocks: 0008 (Keys/Signatures), 0009 (Chord Construction), 0017 (Tessellation)

## Objective

Implement the 7 scale types, 17 core mode types, mode identification, and scale heuristics.

## Research References

- [Scales and Modes](../../research/scales-and-modes.md)
- [Scale, Mode, Key](../../research/algorithms/scale-mode-key.md)
- [Scales, Modes, Keys](../../research/data-structures/scales-modes-keys.md)

## Implementation Steps

### 1. Scale Types (`src/scale.zig`)

Define the 7 scale types as PitchClassSet constants with metadata:
- Diatonic (7-35), Acoustic (7-34), Diminished (8-28), Whole-Tone (6-35)
- Harmonic Minor (7-32), Harmonic Major (7-32), Double Augmented Hexatonic (6-20)

### 2. Mode Types (`src/mode.zig`)

Define 17 core modes with:
- Name, parent scale type, degree index
- Interval formula (as FormulaToken array)
- PitchClassSet representation

### 3. Mode Identification

- `identifyMode(PitchClassSet) → ?ModeType` — given a rooted PCS, identify which mode it is
- `identifyScaleType(PitchClassSet) → ?ScaleType` — identify parent scale type

### 4. Scale Construction

- `Scale.init(ScaleType, PitchClass) → Scale` — construct specific transposition
- `Scale.mode(degree) → Mode` — extract mode at given degree

### 5. Scale Heuristic

- `isScaley(PitchClassSet) → bool` — does this look like a scale (vs chord)?

### 6. Tests

- All 17 modes produce correct PCS values
- Mode identification round-trips: construct → identify → match
- Each diatonic scale has exactly 7 modes
- Scale type identification for known scales
- isScaley: true for diatonic, false for major triad

## Validation

- `tmp/harmoniousapp.net/p/34/Scales.html`: scale catalog
- `tmp/harmoniousapp.net/p/39/Modes.html`: mode catalog with parent scale relationships
- `tmp/harmoniousapp.net/p/bc/Top-Down-View.html`: 17 mode tessellation
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `isScaley`

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
- All 17 modes produce correct PCS values for C root.
- Mode identification round-trips for all 17 modes.
- tonal-ts scale interval sequences match for all 102 scale types where applicable.

## Verification Data Sources

- tonal-ts (`/Users/bermi/tmp/tonal-ts/packages/dictionary/data/scales.json` — 102 scale types)
- harmoniousapp.net (`tmp/harmoniousapp.net/p/34/Scales.html`, `tmp/harmoniousapp.net/p/39/Modes.html`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `isScaley`)

## Implementation History (Point-in-Time)

- `9c71bcb` (2026-02-15):
  - Shipped behavior: Added 7 scale type constants and scale construction in `src/scale.zig`, 17 mode definitions and identification in `src/mode.zig`, plus `isScaley` heuristics and end-to-end mode round-trip tests.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~300 lines of Zig code + ~250 lines of tests
