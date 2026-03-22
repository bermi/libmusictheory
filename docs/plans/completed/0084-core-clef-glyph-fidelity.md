# 0084 — Core Clef Glyph Fidelity

> Dependencies: 0083
> Follow-up: 0082

Status: Completed

## Summary

Replace the public staff renderer's placeholder clef drawing with accurate compat-derived treble and bass glyph outlines, and add verification guardrails so the placeholder spline cannot silently return.

## Problem

The public core staff renderer in `src/svg/staff.zig` still uses a hand-drawn placeholder clef. That makes the gallery and docs look amateurish even after the chord-cluster/layout fixes from `0083`.

The repo already contains correct clef glyph outlines inside the exact compat assets. Not using them in the public renderer is unnecessary quality debt.

## Goals

- replace the placeholder treble and bass clef paths with accurate glyph outlines
- align those glyphs correctly on the public single-staff and grand-staff renderers
- add tests and guardrails that fail if the old placeholder returns

## Verification-First Guardrails

Before implementation is complete:

- `./verify.sh` must assert that `src/svg/staff.zig` contains named clef path constants and no longer contains the placeholder spline
- `src/tests/svg_staff_test.zig` must verify the new `clef-glyph` structure and the absence of the old stroke-based placeholder classes
- gallery/docs Playwright validation must still pass after the clef change

## Exit Criteria

- public treble and bass clefs use compat-derived glyph paths
- the placeholder `clef-stroke`/`clef-hole` path structure is removed
- `zig build test`, docs/gallery Playwright, and `./verify.sh` pass

## Implementation History (Point-in-Time)

- Commit hash: `PENDING`
- Date: 2026-03-22
- Shipped behavior:
  - replaced the public placeholder treble and bass clefs in `/Users/bermi/code/libmusictheory/src/svg/staff.zig` with compat-derived glyph outlines anchored against the staff instead of the previous hand-drawn spline
  - expanded public staff and C ABI coverage so `lmt_svg_chord_staff` emits full chord clusters with the new clef structure across major, minor, diminished, and augmented chords
  - fixed the wasm docs scratch allocation path in `/Users/bermi/code/libmusictheory/examples/wasm-demo/app.js` so the standalone docs surface still renders correctly after the larger public staff SVG output
  - added verification guardrails that ban the placeholder clef spline from the public renderer and require the new `clef-glyph` structure in tests
- Verification commands:
  - `zig build test`
  - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
  - `node /Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs`
  - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_playwright.mjs`
  - `./verify.sh`
