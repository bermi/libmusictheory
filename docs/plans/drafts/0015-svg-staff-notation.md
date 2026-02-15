# 0015 — SVG Staff Notation Generation

> Dependencies: 0008 (Keys/Signatures), 0009 (Chord Construction)
> Blocks: None (output layer)

## Objective

Generate chord, grand-chord, and scale staff notation SVGs matching the site's VexFlow-generated output.

## Research References

- [Staff Notation](../../research/visualizations/staff-notation.md)
- [Pitch and Intervals](../../research/pitch-and-intervals.md)

## Implementation Steps

### 1. Staff Position Computation (`src/svg/staff.zig`)

- MIDI note → staff position (line/space number, clef)
- Grand staff split: notes ≥ MIDI 60 → treble, < 60 → bass
- Ledger line detection

### 2. Accidental Determination

- Key signature context determines which accidentals to display
- Notes already covered by key signature need no accidental
- Courtesy accidentals for clarity

### 3. Layout Engine

- Notehead positioning (handle seconds/clusters with offsets)
- Stem direction (majority rule)
- Accidental placement (avoid collisions)

### 4. Music Font Glyphs

- Embed glyph outlines for: noteheads, stems, clefs, accidentals, key signatures
- Source: Extract from SMuFL-compliant font or procedurally generate

### 5. Three Output Formats

- `tmp/harmoniousapp.net/chord/`: treble clef, 170×110.77px
- `tmp/harmoniousapp.net/grand-chord/`: treble + bass, 170×216px
- `tmp/harmoniousapp.net/scale/`: treble clef horizontal, 363×113px

### 6. Batch Generation

- All chord types × 12 roots
- All scale types × modes × roots

### 7. Tests

- Valid SVG output
- Correct note placement on staff lines/spaces
- Key signatures have correct number and placement of sharps/flats
- Accidentals appear only when needed

## Validation

- Compare against `tmp/harmoniousapp.net/chord/`, `tmp/harmoniousapp.net/grand-chord/`, `tmp/harmoniousapp.net/scale/` directories

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Generated SVGs are valid XML
- Note placement correct on staff lines/spaces
- Key signatures have correct sharps/flats count and placement
- Dimensions match (chord: 170x110.77, grand-chord: 170x216, scale: 363x113)

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/chord/` directory — 1,698 SVGs, `tmp/harmoniousapp.net/grand-chord/` directory — 2,032 SVGs, `tmp/harmoniousapp.net/scale/` directory — 494 SVGs)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~500 lines of Zig SVG code (most complex SVG generator) + ~200 lines of tests
