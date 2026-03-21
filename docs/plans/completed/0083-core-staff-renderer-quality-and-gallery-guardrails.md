# 0083 — Core Staff Renderer Quality And Gallery Guardrails

> Dependencies: 0065, 0077, 0081
> Follow-up: 0082

Status: In progress

## Summary

Raise the public core staff renderer from a docs-grade placeholder to a gallery-grade notation surface, and make the release-candidate gallery validator fail unless those quality features are present.

## Problem

The standalone gallery currently exposes the public `lmt_svg_chord_staff` output, but that renderer still behaves like a lightweight docs helper:

- no clef glyph
- chord tones laid out like a short melody instead of a simultaneous chord cluster
- no shared-stem cluster layout
- no explicit gallery verification for engraving features

That leaves the gallery technically functional but visually weak, which is not acceptable for a release-candidate surface.

## Goals

- render single-staff chords as simultaneous vertical clusters
- add algorithmic treble/bass clef glyphs to the public core renderer
- improve accidentals, stem placement, and notehead collision handling enough for clean gallery presentation
- strengthen gallery verification so screenshot generation is tied to staff-quality features, not only size/framing

## Verification-First Guardrails

Before renderer changes are considered complete:

- `./verify.sh` must assert that the gallery validator checks chord staff features beyond dimensions
- the gallery Playwright path must fail if the chord staff preview lacks:
  - a clef glyph
  - a shared cluster stem
  - simultaneous chord-notehead layout
- `src/tests/svg_staff_test.zig` must verify the public SVG structure for the new cluster/clef classes

## Implementation Slices

### 1. Verification hardening

- extend the gallery Playwright common snapshot with structured `staffFeatures`
- make `waitForGalleryReady()` require clef and cluster layout features for the chord scene
- wire `./verify.sh` guardrails to those checks

### 2. Core staff renderer upgrade

- add vector treble/bass clef glyphs
- replace single-staff chord note sequencing with simultaneous cluster layout
- add shared stem calculation and basic second-interval displacement
- improve grand-staff and scale rendering margins so clefs and key signatures fit cleanly

### 3. Documentation refresh

- update staff-notation research/architecture docs to reflect the new public renderer behavior
- update gallery/release docs if screenshot expectations or scene notes change

## Exit Criteria

- gallery chord staff renders with visible clef glyphs and simultaneous chord layout
- gallery screenshot/capture validation fails if those features regress
- public staff SVG tests cover the new structure
- `./verify.sh` passes

## Implementation History (Point-in-Time)

- Commit hash: `e32e11c`
- Date: 2026-03-21
- Shipped behavior:
  - replaced the public core staff renderer with simultaneous chord clustering, shared stems, and algorithmic clef glyphs
  - added gallery screenshot/Playwright guardrails that require clef presence, chord clustering, and shared-stem structure
  - updated public staff tests and gallery capture documentation to reflect the stronger notation-quality contract
- Verification commands:
  - `zig build test`
  - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
  - `node /Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs`
  - `./verify.sh`
