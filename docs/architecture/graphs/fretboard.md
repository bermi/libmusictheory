# Fretboard Graphs

## Methods

- Core fret diagram logic: `src/svg/fret.zig`
- Parametric helper surface: `src/guitar.zig`, `src/c_api.zig` (`lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, `lmt_svg_fret_n`)
- Compatibility renderer: `src/svg/fret_compat.zig`
- Compatibility routing: `src/harmonious_svg_compat.zig` (`eadgbe/*`)

## Current Approach

- Core logic computes fret geometry, visible fret windows, and barre markers algorithmically from caller-provided fret slices.
- The public API now has two layers:
  - a parametric fretboard surface for arbitrary string counts and custom visible fret windows
  - a six-string compatibility wrapper that preserves harmonious `eadgbe` behavior
- CAGED remains a six-string standard-guitar concept and is not used as the generic fretboard abstraction.
- Compatibility output uses a large structured SVG scaffold with deterministic node insertion to match legacy output formatting and metadata shape.

## Alternative Programmatic Approaches Studied

- Fretboard graph generation with generic graph libs (nodes=strings/frets, edges=interval relations).
- Canvas/SVG chord diagram libraries with procedural dot/barre/label composition.
- Constraint-based voicing visualization from pitch-set + tuning graph.

Decision:

- Keep algorithmic voicing model in Zig.
- Incrementally replace static scaffold segments with generated primitives while preserving compat checks.

## Swappable Backend Plan

IR blocks:

- `FretGrid`, `StringLine`, `FretLine`, `FingerDot`, `BarreArc`, `MuteMark`, `OpenStringMark`, `PositionLabel`

Backend mapping:

- SVG backend serializes full diagram tree.
- Bitmap backend draws same primitives to texture/canvas for plugin UIs.

## Path to Fully Algorithmic

1. Keep the parametric renderer as the source of geometric truth for arbitrary string-count chord diagrams.
2. Replace static compatibility prefix metadata block with deterministic generated SVG header.
3. Convert fixed glyph snippets (parenthesis/position markers) to primitive/vector glyph components.
4. Keep API-level parity tests across `eadgbe` family while reducing static template mass.

## Samples

- ![Compat EADGBE](samples/compat-eadgbe.svg)
