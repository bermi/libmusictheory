# 0081 — Gallery Presentation And Capture Pipeline

> Dependencies: 0077, 0079

Status: Completed

## Summary

Make the standalone gallery suitable for release-candidate review by improving presentation quality and adding a reproducible local capture workflow for representative screenshots.

## Goals

- strengthen gallery information hierarchy and copy
- define a stable set of showcase presets
- add a local script or documented flow that captures representative gallery screenshots
- verify that the capture flow still works as the gallery evolves

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require the presence of gallery capture docs and capture scripts once this plan begins
- `./verify.sh` must enforce that capture targets only use public gallery routes and not internal Harmonious bundles

## Exit Criteria

- release-candidate screenshots can be regenerated locally
- representative scenes are documented and stable
- gallery presentation is improved without weakening the public-API-only rule
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - rebuilt the standalone gallery presentation in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html` and `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css` so scenes read as large release-candidate compositions instead of small smoke-test widgets
  - upgraded `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js` to crop SVG previews to their real content bounds and size them intentionally per scene family
  - strengthened `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs` and `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs` so Playwright fails if the core gallery diagrams are not normalized and visibly large
  - added reproducible screenshot capture via `/Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs` and documented it in `/Users/bermi/code/libmusictheory/docs/release/gallery-capture.md`
  - promoted screenshot regeneration into the standalone release path through `/Users/bermi/code/libmusictheory/scripts/release_smoke.sh`, `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`, `/Users/bermi/code/libmusictheory/docs/release/smoke-matrix.md`, and `/Users/bermi/code/libmusictheory/README.md`
  - updated `/Users/bermi/code/libmusictheory/verify.sh` so screenshot capture, release-doc linkage, and gallery visual-scale assertions are mandatory

## Implementation History (Point-in-Time)

- Commit: `7f43bb9`
- Date: `2026-03-21`
- Shipped behavior:
  - turned the standalone gallery into a visually legible release-candidate surface with cropped large SVG art, stronger hierarchy, and reproducible capture outputs
  - made screenshot generation a first-class verified workflow by capturing `gallery-overview.png`, `gallery-hero.png`, and per-scene images into `zig-out/wasm-gallery-captures/`
  - hardened browser validation so the gallery can no longer pass while rendering tiny uncropped diagrams inside oversized panels
- Verification commands:
  - `zig build wasm-gallery`
  - `node scripts/validate_wasm_gallery_playwright.mjs`
  - `node scripts/capture_wasm_gallery_screenshots.mjs`
  - `./verify.sh`
