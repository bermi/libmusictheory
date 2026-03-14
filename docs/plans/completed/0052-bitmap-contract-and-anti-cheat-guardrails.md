# 0052 — Bitmap Contract And Anti-Cheat Guardrails

> Dependencies: 0051
> Blocks: 0053, 0054, 0055, 0056, 0057, 0058, 0059

Status: Completed

## Objective

Lock the new bitmap-proof lane behind explicit structural constraints so visual similarity cannot be faked with browser SVG raster shortcuts, CSS scaling, or embedded harmonious payloads.

## Scope

- Add proof-lane verification gates to `./verify.sh`.
- Introduce a dedicated proof bundle target and explicit export profile.
- Enforce browser-side restrictions for candidate rendering in proof mode.
- Establish per-kind support reporting so unsupported families do not silently count as proven.

## Required Guardrails

- Candidate proof rendering must not call `drawImage()` on generated SVG content.
- Candidate proof rendering must not use canvas `scale()` or CSS transforms to resize the generated image.
- Candidate proof rendering must only paint wasm-provided RGBA into `ImageData`.
- Proof UI must distinguish `supported`, `unsupported`, and `failed` families.
- Proof bundle must not import harmonious reference payloads into wasm.

## Exit Criteria

- `./verify.sh` programmatically checks the proof-lane anti-cheat rules.
- Proof bundle builds with explicit export checks.
- Playwright can run the proof page and fail on drift/support violations.

## Verification Commands

- `./verify.sh`
- `zig build wasm-bitmap-proof`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc`

## Implementation History (Point-in-Time)

- `TBD` (`2026-03-14`)
- Shipped behavior:
- Added the dedicated bitmap-proof browser bundle target in `/Users/bermi/code/libmusictheory/build.zig` and mirrored harmonious references into `zig-out/wasm-bitmap-proof`.
- Added proof-lane anti-cheat verification gates in `/Users/bermi/code/libmusictheory/verify.sh` that reject browser-side `drawImage()`/scale shortcuts and require `putImageData()` painting from wasm RGBA.
- Added the proof UI in `/Users/bermi/code/libmusictheory/examples/wasm-demo/bitmap-proof.html` and `/Users/bermi/code/libmusictheory/examples/wasm-demo/bitmap-proof.js` with explicit per-kind support reporting.
- Guardrail/completion verification:
- `./verify.sh`
- `zig build wasm-bitmap-proof`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc`
