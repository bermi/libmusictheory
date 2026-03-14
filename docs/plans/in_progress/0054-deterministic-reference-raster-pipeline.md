# 0054 — Deterministic Reference Raster Pipeline

> Dependencies: 0052, 0053

Status: In Progress

## Objective

Provide a deterministic native-RGBA reference lane for harmonious SVGs at canonical target scales, with machine-checkable drift metrics.

## Current Scope

The current honest support set is still narrow:

- `opc`, `center-square-text`, `vert-text-black`, and `vert-text-b2t-black` are currently native-RGBA proof supported
- harmonious references for those families are rasterized inside wasm through the proof ABI
- candidate bitmaps for those families are generated directly to RGBA in Zig/WASM at native target size
- unsupported families remain explicit in the native-proof lane and do not count as proven

## Remaining Work

- expand reference rasterization beyond the current `rect`/`circle` plus filled-path subset
- add deterministic handling for `even` gradient fills
- add deterministic text/arc handling required by `eadgbe`
- broaden native-proof Playwright coverage as additional families become truly supported

## Verification Commands

- `./verify.sh`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds opc --scales 55:100,200:100`
