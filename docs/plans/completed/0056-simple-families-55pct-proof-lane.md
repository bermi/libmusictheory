# 0056 — Simple Families Native-RGBA Proof Lane

> Dependencies: 0055

Status: Completed

## Objective

Close the native-RGBA proof lane for the simple compatibility families with strict drift gates and explicit source reporting at both `55%` and `200%`.

## Target Families

- `even`
- `opc`
- `optc`
- `oc`
- `center-square-text`
- `vert-text-black`
- `vert-text-b2t-black`

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity remains green
- exact SVG parity remains green
- anti-cheat rules remain green
- Playwright native-proof validation passes with `0` failures and no unsupported rows for the supported simple-family set

## Completed Slices

- Added strict native-RGBA proof support for `optc` with direct primitive rendering and tightened the sampled proof validator so `optc` is required.
- Added strict native-RGBA proof support for `oc` with Zig-side markup template rasterization and tightened the sampled proof validator so `oc` is required.
- Codified the `even` compatibility domain model so the audited chart population and marker-family semantics are explicit instead of inferred ad hoc.
- Added strict native-RGBA proof support for `even` by extending the Zig-side document rasterizer to handle nested groups, transformed rects, lines, ellipses, RGB/RGBA colors, opacity, and linear-gradient fills, and tightened the sampled proof validator so `even` is required.
- Reused a single WASM scratch RGBA slot in the parity/proof browser pages so large `even @ 200%` bitmaps fit within the existing scratch contract without hiding allocator failures.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds even,opc,optc,oc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `f46d43d` — 2026-03-16
- `8a22f12` — 2026-03-16
- `870ba04` — 2026-03-16
- Completion state shipped in this plan:
  - added `optc` native-RGBA proof support in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - added `oc` native-RGBA proof support in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - codified the `even` compat domain in `/Users/bermi/code/libmusictheory/src/even_compat_model.zig`
  - added `even` native-RGBA proof support through extended SVG document rasterization in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - updated `/Users/bermi/code/libmusictheory/examples/wasm-demo/native-rgba-proof.js`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/scaled-render-parity.js`, `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs`, and `/Users/bermi/code/libmusictheory/verify.sh` so the browser and CLI gates now require `even` in the simple-family proof subset
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds even,opc,optc,oc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`
