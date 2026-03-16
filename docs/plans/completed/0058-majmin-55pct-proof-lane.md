# 0058 — Majmin Native-RGBA Proof Lane

> Dependencies: 0055, 0056, 0057

Status: Completed

## Objective

Close native-RGBA proof for the majmin compatibility families without reintroducing replay-style payloads.

## Target Families

- `majmin/modes`
- `majmin/scales`

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity still green
- exact SVG parity still green
- anti-cheat rules still green
- Playwright native-proof validation passes with `0` failures and no unsupported rows for both majmin kinds at `55%` and `200%`

## Completed Slices

- moved both majmin kinds into the strict native-proof lane in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig` with `generated-svg-bitmap` backend reporting inside Zig/WASM
- expanded the deterministic document rasterizer to accept `<a>` containers so the majmin scene markup is traversed correctly
- fixed the majmin native renderer throughput bug by replacing the non-advancing unsupported-command path loop with explicit quadratic path support (`Q/q/T/t`)
- reduced majmin bitmap render cost by moving the large compat SVG scratch off the wasm stack and tightening the path fill/number parsing hot paths
- tightened `/Users/bermi/code/libmusictheory/verify.sh` and `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs` so both majmin kinds are now required in the strict proof lane

## Verification Commands

- `./verify.sh`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds majmin/modes,majmin/scales --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- Completion state shipped in this plan:
  - added majmin native-proof kind support, target sizing, and reference/candidate raster wiring in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - fixed quadratic path handling for majmin text-outline paths in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - updated `/Users/bermi/code/libmusictheory/examples/wasm-demo/native-rgba-proof.js`, `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs`, and `/Users/bermi/code/libmusictheory/verify.sh` so majmin is enforced in the strict proof lane
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds majmin/modes,majmin/scales --scales 55:100,200:100`
