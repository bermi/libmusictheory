# 0017 — SVG Scale Tessellation Maps

> Dependencies: 0007 (Scales/Modes), 0011 (Voice Leading)
> Blocks: None (output layer)

## Objective

Generate scale tessellation SVGs (300×360px) showing voice-leading relationships between all transpositions of the 4 main scale types as geometric tiles.

## Research References

- [Tessellation Maps](../../research/visualizations/tessellation-maps.md)
- [Scales and Modes](../../research/scales-and-modes.md)
- [Voice Leading](../../research/algorithms/voice-leading.md)

## Implementation Steps

### 1. Scale Adjacency Graph

- Enumerate all scales (12×4 main types + harmonics)
- Compute pairwise Hamming distance = 2 for single-semitone VL adjacency
- Build adjacency edges

### 2. Tile Shape Assignment

- Diatonic → hexagon (6 edges)
- Acoustic → square (4 edges)
- Harmonic minor/major → triangle/diamond (3 edges)

### 3. Tessellation Layout

- Honeycomb layout for hexagons
- Squares fill gaps
- Triangles fill interstices

### 4. Color Assignment

- Each tile colored by tonic's pitch-class color
- Highlight modes for selection states

### 5. SVG Generation (`src/svg/tessellation.zig`)

- Polygon vertices for each tile shape
- Text labels inside tiles
- Stroke lines for adjacency edges

### 6. Tests

- Correct neighbor counts per scale type
- Diatonic scales have exactly 6 neighbors each
- Valid SVG output

## Validation

- Compare against `tmp/harmoniousapp.net/majmin/` directory (416 SVGs)

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
- Diatonic scales have exactly 6 neighbors each
- Tile shapes match scale types (hexagons for diatonic, squares for acoustic)
- Dimensions are 300x360px

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/majmin/` directory — 416 tessellation SVGs for comparison)

## Implementation History (Point-in-Time)

- `1d93888a442b80887d7ef5e10dab48bbe2403939` (2026-02-15):
  - Shipped behavior: added `src/svg/tessellation.zig` with 48-tile (12x4 scale families) tessellation enumeration, Hamming-2 voice-leading adjacency with harmonic cross-edge pruning to 3-neighbor harmonic tiles, shape assignment (hexagon/square/triangle/diamond), and 300x360 SVG rendering with tonic-color fills, labels, and VL edge lines. Added `src/tests/svg_tessellation_test.zig` covering neighbor-count contracts, shape mapping, and SVG validity/dimensions. Added `0017` gate to `./verify.sh`.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~350 lines of Zig SVG code + ~150 lines of tests
