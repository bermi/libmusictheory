# 0054 — Deterministic Reference Raster Pipeline

> Dependencies: 0052, 0053

Status: In Progress

## Objective

Provide a deterministic bitmap reference lane for harmonious SVGs at canonical `55%` target size, with artifact emission and machine-checkable drift metrics.

## Current Scope

The current cut is intentionally narrow and honest:

- `opc`, `center-square-text`, `vert-text-black`, and `vert-text-b2t-black` are currently marked bitmap-proof supported.
- Harmonious references for those families are rasterized inside wasm through the proof ABI, not through browser `drawImage()`.
- Candidate bitmaps for those families are generated directly to RGBA in Zig/WASM at native `55%` target size.
- The proof UI and Playwright harness report unsupported families explicitly and do not count them as proven.

## Remaining Work

- Expand reference rasterization beyond the current `rect`/`circle` plus filled-path subset.
- Add deterministic handling for `even` gradient fills.
- Add deterministic text/arc handling required by `eadgbe`.
- Broaden Playwright proof runs beyond text-glyph families and `opc` as additional families become truly supported.

## Verification Commands

- `./verify.sh`
- `zig build wasm-bitmap-proof`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc`
