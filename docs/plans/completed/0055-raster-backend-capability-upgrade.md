# 0055 — Raster Backend Capability Upgrade

> Dependencies: 0053, 0054

Status: Completed

## Objective

Extend the raster stack until the proof lane can faithfully represent the primitive set required by the compatibility families.

## Completed Slice

This slice delivered the smallest honest capability jump that unlocks new proof families:

- filled SVG path rasterization,
- `translate` and `rotate` transform support for path-backed glyph groups,
- deterministic winding-based fills at canonical `55%` target size,
- reference-side parsing for the same primitive subset.

This slice is deliberately scoped to the text-glyph families and the path primitives they actually use (`M/m`, `L/l`, `C/c`, `S/s`, `Z/z`).

## Exit Criteria

- The proof backend can rasterize filled glyph paths with transforms deterministically in Zig/WASM.
- Focused tests cover transformed path rendering and reference-vs-candidate equivalence for at least one glyph-backed family.
- `./verify.sh` runs Playwright bitmap-proof validation against more than `opc` alone.

## Verification Commands

- `./verify.sh`
- `zig build test`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc,center-square-text,vert-text-black,vert-text-b2t-black`

## Implementation History (Point-in-Time)

- `4e01095` (`2026-03-14`)
- Shipped behavior:
- Added deterministic filled-path rasterization with `translate`/`rotate` transform support in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`.
- Added direct candidate RGBA proof rendering for `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net/center-square-text/*.svg`, `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net/vert-text-black/*.svg`, and `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net/vert-text-b2t-black/*.svg` using reusable glyph primitives from `/Users/bermi/code/libmusictheory/src/svg/text_misc.zig`.
- Tightened the proof Playwright gate in `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_bitmap_playwright.mjs` and `/Users/bermi/code/libmusictheory/verify.sh` so the run now fails unless all requested proof kinds are actually supported.
- Guardrail/completion verification:
- `./verify.sh`
- `zig build test`
- `zig build wasm-bitmap-proof`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc,center-square-text,vert-text-black,vert-text-b2t-black`
