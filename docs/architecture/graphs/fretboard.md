# Fretboard Graphs (EADGBE)

## Methods

- Core fret diagram logic: `src/svg/fret.zig`
- Compatibility renderer: `src/svg/fret_compat.zig`
- Compatibility routing: `src/harmonious_svg_compat.zig` (`eadgbe/*`)

## Current Approach

- Core logic computes playable positions and barre markers algorithmically.
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

1. Replace static compatibility prefix metadata block with deterministic generated SVG header.
2. Convert fixed glyph snippets (parenthesis/position markers) to primitive/vector glyph components.
3. Keep API-level parity tests across `eadgbe` family while reducing static template mass.

## Samples

- ![Compat EADGBE](samples/compat-eadgbe.svg)
