# Changelog

All notable changes to `libmusictheory` will be documented in this file.

The format is based on Keep a Changelog and the project uses Semantic Versioning for the standalone public surface.

## [0.1.0] - 2026-04-05

### Added
- stable public C ABI contract in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- standalone docs bundle in `/Users/bermi/code/libmusictheory/zig-out/wasm-docs`
- standalone gallery bundle in `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery`
- gallery screenshot capture pipeline in `/Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs`
- release smoke matrix in `/Users/bermi/code/libmusictheory/scripts/release_smoke.sh`
- explicit stability classification in `/Users/bermi/code/libmusictheory/docs/release/stability-matrix.md`
- explicit image review interpretation in `/Users/bermi/code/libmusictheory/docs/release/image-review-matrix.md`
- explicit stable go decision in `/Users/bermi/code/libmusictheory/docs/release/stable-review-decision.md`

### Changed
- split standalone public APIs from internal Harmonious compatibility/proof APIs
- generalized fret rendering and semantics for arbitrary tunings and string counts
- upgraded public SVG quality for fret, staff, clock, and text-driven generated scenes
- replaced the public placeholder clef with compat-derived treble and bass glyph outlines
- clarified stable versus experimental browser review boundaries for docs, gallery, and direct bitmap helpers

### Verified
- `./verify.sh` passes with `RELEASE_SURFACE_SMOKE=yes`
- `./scripts/release_smoke.sh` passes
- standalone docs Playwright smoke passes
- standalone gallery Playwright smoke passes
- release gallery captures regenerate deterministically
