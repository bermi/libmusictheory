# 0080 — Gallery Scene Expansion And Curation

> Dependencies: 0077, 0078, 0079

Status: Completed

## Summary

Expand the standalone gallery into a stronger creative showcase with curated scenes and presets that demonstrate concrete musical-discovery workflows.

## Goals

- Add at least two new gallery scenes beyond the current four
- Improve the existing scenes so each has a clear musical use case
- Curate presets so the gallery feels authored rather than random
- Keep the gallery strictly on public stable APIs

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require a minimum gallery scene count and preset manifest presence once this plan begins
- `./verify.sh` must fail if gallery code imports compat/proof APIs or local Harmonious data

## Exit Criteria

- gallery scene count increases
- presets are explicit and documented
- Playwright covers the new representative scenes
- root README or gallery docs explain what each scene is for
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - expanded the standalone gallery from four scenes to six in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
  - replaced hidden JS preset constants with the authored manifest `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery-presets.json`
  - added `Progression Drift` and `Constellation Delta` as new public-API-only gallery scenes in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
  - updated `/Users/bermi/code/libmusictheory/build.zig` to install the preset manifest into `zig-out/wasm-gallery/`
  - strengthened `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs` and `/Users/bermi/code/libmusictheory/verify.sh` so scene count, manifest presence, and representative scene rendering are enforced
  - documented the gallery scenes in `/Users/bermi/code/libmusictheory/README.md`

## Implementation History (Point-in-Time)

- Commit: `99ab521`
- Date: `2026-03-21`
- Shipped behavior:
  - turned the standalone gallery into a curated six-scene surface with authored presets and explicit musical-use-case framing
  - kept the gallery strictly on the stable public API while adding two new scenes, manifest-driven preset loading, and stronger browser validation
  - made `./verify.sh` fail if the gallery drops below the minimum scene count or loses its curated manifest/install wiring
- Verification commands:
  - `zig build wasm-gallery`
  - `node scripts/validate_wasm_gallery_playwright.mjs`
  - `./verify.sh`
