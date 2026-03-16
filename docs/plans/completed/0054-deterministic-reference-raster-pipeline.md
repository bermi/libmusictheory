# 0054 — Deterministic Reference Raster Pipeline

> Dependencies: 0052, 0053

Status: Completed

## Objective

Provide a deterministic native-RGBA reference lane for harmonious SVGs at canonical target scales, with machine-checkable drift metrics.

## Completed Scope

- harmonious references for all 15 compatibility kinds are rasterized inside Zig/WASM at `55%` and `200%`
- the reference lane supports the SVG features required by the full compatibility corpus, including transformed groups, gradients, text-outline path data, and majmin quadratic path commands
- reference raster output participates directly in both `Scaled Render Parity` and `Native RGBA Proof`
- drift metrics remain machine-checkable through the Playwright validators and `./verify.sh`

## Verification Commands

- `./verify.sh`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `4e01095` — 2026-03-15
- `8a22f12` — 2026-03-16
- Completion state shipped in this plan:
  - extended the Zig-side SVG rasterizer in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig` from the initial simple-family subset to the full harmonious compatibility corpus
  - added deterministic handling for gradients, transformed containers, transformed rects, ellipses, complex filled/stroked paths, and majmin quadratic path commands
  - validated the full reference raster lane through `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs` and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
