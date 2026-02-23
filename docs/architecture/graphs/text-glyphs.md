# Text and Glyph Graph Layers

## Methods

- `src/svg/text_misc.zig:11` `renderVerticalLabel`
- `src/svg/text_misc.zig:46` `renderCenterSquareGlyph`

Kinds covered:

- `vert-text-black`, `vert-text-b2t-black`, `center-square-text`

## Current Approach

- Path glyphs are selected from generated template tables (`src/generated/harmonious_text_templates.zig`).
- Rendering is deterministic but template-driven rather than algorithmic glyph construction.

## Audited Primitive Invariants

`scripts/audit_text_compat_primitives.py` validates reference decomposition for:

- `tmp/harmoniousapp.net/vert-text-black/*.svg` (115)
- `tmp/harmoniousapp.net/vert-text-b2t-black/*.svg` (115)

Script-verified facts:

- All 230 labels are composed from exactly **17 unique subpath bodies**.
- Label alphabet is fixed to **12 symbols**: `-`, `0..9`, `Z`.
- Deterministic primitive count per symbol:
  - `-`: 1
  - `0`: 2
  - `1`: 1
  - `2`: 1
  - `3`: 1
  - `4`: 1
  - `5`: 1
  - `6`: 2
  - `7`: 1
  - `8`: 3
  - `9`: 2
  - `Z`: 1
- Every reference stem is segmentable left-to-right into those symbol primitive sequences with no ambiguity.

This establishes that current per-stem paths are representable as a compact symbol/primitive grammar.

## Alternative Programmatic Approaches Studied

- Font outline extraction at build-time with deterministic subset embedding.
- Signed distance field (SDF) text rendering for bitmap backends.
- Parametric symbol construction for small fixed glyph vocabularies.

Decision:

- For exact compatibility, keep template path lookup currently.
- For long-term algorithmic path, move to deterministic symbol composition (first) and then build-time font subset extraction for broader text coverage.

## Swappable Backend Plan

IR blocks:

- `GlyphRun`, `Anchor`, `Direction`, `Transform`

Backend mapping:

- SVG backend writes path outlines or canonical text nodes.
- Bitmap backend uses vector outlines or SDF raster path with deterministic metrics.

## Path to Fully Algorithmic

1. Replace per-stem lookup with symbol-level composition using audited primitive grammar.
2. Replace stem-specific alignment constants with deterministic text metric/layout model.
3. Extend to generic font subset extraction pipeline for non-compat graph text.
4. Share text metrics engine across all graph families requiring labels.
