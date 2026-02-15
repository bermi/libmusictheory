# 0016 — SVG Fret Diagram Generation

> Dependencies: 0012 (Guitar Fretboard)
> Blocks: None (output layer)

## Objective

Generate guitar fret diagram SVGs (100×100px) matching the site's Inkscape-patterned output.

## Research References

- [Fret Diagrams](../../research/visualizations/fret-diagrams.md)
- [Guitar and Keyboard](../../research/guitar-and-keyboard.md)

## Implementation Steps

### 1. Grid Drawing (`src/svg/fret.zig`)

- 6 vertical string lines, 4-5 horizontal fret lines
- Nut (thick line) for open position chords
- Position number for non-open positions

### 2. Dot Placement

- Filled circles between fret lines for fretted notes
- "O" above nut for open strings, "X" for muted strings
- Barre indication (thick bar across strings)

### 3. Fret Window Computation

- Determine visible fret range from voicing data
- Show enough context (4-5 frets typically)

### 4. Batch Generation

- Generate for all CAGED positions × common chord types × 12 roots

### 5. Tests

- Valid SVG output
- Dot positions match expected grid coordinates
- Barre detection works for barre chords

## Validation

- Compare against `tmp/harmoniousapp.net/eadgbe/` directory (2,278 SVGs)

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
- Dot positions match expected grid coordinates
- Barre detection works for barre chords
- Dimensions are 100x100px

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/eadgbe/` directory — 2,278 fret diagram SVGs for comparison)

## Implementation History (Point-in-Time)

- `daa4930` (2026-02-15):
  - Shipped behavior: Added `src/svg/fret.zig` with 100x100 fret-diagram SVG rendering, fret-window computation, dot/open/muted marker placement, and barre detection/rendering for contiguous barred spans.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~200 lines of Zig SVG code + ~100 lines of tests
