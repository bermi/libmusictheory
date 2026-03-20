# 0077 — Standalone Gallery And Example Bundle

> Dependencies: 0073, 0074, 0076, 0066

Status: Completed

## Summary

Build a local-only gallery bundle that demonstrates creative uses of `libmusictheory` using only the stable public APIs.

This gallery is the outward-facing replacement for relying on Harmonious reproduction as the only visual proof that the library is useful.

## Goals

- Add a `wasm-gallery` bundle.
- Keep it single-entry and locally servable.
- Use only public standalone APIs.
- Show multiple distinct musical-discovery experiences, not just API widgets.

## Candidate Gallery Scenes

- pitch-class set explorer
- chord/color clock playground
- parametric fretboard/tuning explorer
- progression or key-neighborhood explorer
- geometry-driven harmony scene using the public rendering APIs

## Scope

- gallery HTML/JS/CSS bundle
- curated example scenes
- local serving instructions
- Playwright smoke coverage for the gallery shell and representative scenes

## Non-Goals

- No Harmonious content mirroring
- No dependency on exact-compat APIs
- No production deployment work

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require that gallery code does not import Harmonious SPA or compat-only browser scripts
- `./verify.sh` must require a Playwright smoke path for the gallery bundle

## Exit Criteria

- `zig build wasm-gallery` exists
- gallery scenes render using public APIs only
- gallery has Playwright smoke coverage
- gallery is documented from the root README
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - added a standalone `wasm-gallery` bundle in `/Users/bermi/code/libmusictheory/build.zig`
  - added a single-entry creative gallery shell in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
  - added a public-API-only gallery runtime in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
  - added dedicated gallery styling in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
  - added a Playwright smoke validator in `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
  - extended `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs` and `/Users/bermi/code/libmusictheory/verify.sh` with gallery-specific export and anti-compat guardrails
  - updated `/Users/bermi/code/libmusictheory/README.md` to document `zig build wasm-gallery` as a standalone bundle

## Implementation History (Point-in-Time)

- Commit: `2530cb5`
- Date: `2026-03-20`
- Shipped behavior:
  - shipped a local-only `wasm-gallery` bundle that demonstrates four public-API scenes: pitch-class constellation analysis, key-degree bloom, chord identity/staff views, and parametric fretboard exploration
  - kept the gallery on the stable public ABI only, with no Harmonious compat/proof imports, no compat scratch helpers, and no dependency on local `tmp/harmoniousapp.net` data
  - added a dedicated gallery Playwright smoke test and export-profile validation so the bundle is checked independently from the internal Harmonious regression surfaces
- Verification commands:
  - `zig build wasm-gallery`
  - `node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm`
  - `node scripts/validate_wasm_gallery_playwright.mjs`
  - `./verify.sh`
