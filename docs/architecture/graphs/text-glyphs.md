# Text and Glyph Graph Layers

## Methods

- `src/svg/text_misc.zig:11` `renderVerticalLabel`
- `src/svg/text_misc.zig:46` `renderCenterSquareGlyph`

Kinds covered:

- `vert-text-black`, `vert-text-b2t-black`, `center-square-text`

## Current Approach

- Path glyphs are selected from generated template tables (`src/generated/harmonious_text_templates.zig`).
- Rendering is deterministic but template-driven rather than algorithmic glyph construction.

## Alternative Programmatic Approaches Studied

- Font outline extraction at build-time with deterministic subset embedding.
- Signed distance field (SDF) text rendering for bitmap backends.
- Parametric symbol construction for small fixed glyph vocabularies.

Decision:

- For exact compatibility, keep template path lookup currently.
- For long-term algorithmic path, move to build-time font subset compiler + deterministic text layout model.

## Swappable Backend Plan

IR blocks:

- `GlyphRun`, `Anchor`, `Direction`, `Transform`

Backend mapping:

- SVG backend writes path outlines or canonical text nodes.
- Bitmap backend uses vector outlines or SDF raster path with deterministic metrics.

## Path to Fully Algorithmic

1. Replace static template map with deterministic font subset extraction pipeline.
2. Keep path canonicalization for compatibility outputs.
3. Share text metrics engine across all graph families requiring labels.
