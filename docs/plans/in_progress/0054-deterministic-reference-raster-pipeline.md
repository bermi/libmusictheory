# 0054 — Deterministic Reference Raster Pipeline

> Dependencies: 0052, 0053

Status: In Progress

## Objective

Provide a deterministic bitmap reference lane for harmonious SVGs at canonical `55%` target size, with artifact emission and machine-checkable drift metrics.

## Current Scope

The first cut is intentionally narrow and honest:

- `opc` is the only family currently marked bitmap-proof supported.
- Harmonious `opc` SVG references are rasterized inside wasm through the new proof ABI, not through browser `drawImage()`.
- Candidate `opc` bitmaps are generated directly to RGBA in Zig/WASM at native `55%` size.
- The proof UI and Playwright harness report unsupported families explicitly and do not count them as proven.

## Remaining Work

- Expand reference rasterization beyond the current `rect`/`circle` subset.
- Add deterministic support for path-heavy families.
- Add deterministic handling for `even` gradient fills.
- Add deterministic text/arc handling required by `eadgbe`.
- Broaden Playwright proof runs from `opc` to additional families as they become truly supported.

## Verification Commands

- `./verify.sh`
- `zig build wasm-bitmap-proof`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc`
