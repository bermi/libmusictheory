# 0059 — Project-Level Scaled Render Parity Closure

> Dependencies: 0056, 0057, 0058

Status: Completed

## Objective

Close the all-kind scaled-render-parity lane across required scales (`55%` and `200%`) without overstating that parity as native proof.

## Scope

This plan exists to ensure that every compatibility kind participates in target-size bitmap comparison, even while some kinds still rely on generated SVG as the candidate source.

Allowed candidate sources in this lane:

- `native-rgba`
- `generated-svg`

Native-RGBA rows must also report their actual backend subtype so direct primitive rendering, path rendering, markup-template rasterization, and generated-SVG rasterization are not flattened into one misleading label.

Completion of this plan does not imply visual project completion.

## Exit Criteria

- every compatibility kind participates in scaled-render-parity at `55%` and `200%`
- all parity rows report candidate source explicitly
- all native-RGBA rows report candidate backend explicitly
- all parity runs have `0` drift failures
- completion of this plan alone must not be presented as project completion

## Completed Slices

- Split the old mixed bitmap lane into explicit `Scaled Render Parity` and `Native RGBA Proof` surfaces, with separate pages, build targets, and Playwright validators.
- Added per-row candidate source reporting and tightened parity validation so generated-SVG rows are treated as parity only, never proof.
- Added per-row native backend subtype reporting from Zig/WASM through the browser pages and Playwright validators so `native-rgba` rows no longer collapse direct primitives, path geometry, markup templates, and Zig-side generated-SVG rasterization into a single misleading bucket.
- Closed all-kind parity at both canonical scales with `0` drift failures across the full 15-kind corpus while preserving exact SVG parity and keeping the project-level completion gate blocked on `0060`.

## Verification Commands

- `./verify.sh`
- `zig build wasm-scaled-render-parity`
- `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `61c199c` — 2026-03-15
- `c1e38f9` — 2026-03-16
- Completion state shipped in this plan:
  - renamed the all-kind bitmap lane to `Scaled Render Parity` and split it from `Native RGBA Proof` across `/Users/bermi/code/libmusictheory/build.zig`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/scaled-render-parity.html`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/scaled-render-parity.js`, and `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_scaled_render_parity_playwright.mjs`
  - exposed native candidate backend subtype truth from `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, and `/Users/bermi/code/libmusictheory/src/wasm_scaled_render_api.zig`
  - updated browser/UI reporting in `/Users/bermi/code/libmusictheory/examples/wasm-demo/scaled-render-parity.js`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/render-compare-common.js`, and `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_scaled_render_parity_playwright.mjs` so every row now reports `candidateSource` and every native row reports `candidateBackend`
  - completed all-kind sampled parity at `55%` and `200%` with `0` drift failures while keeping `NATIVE_RGBA_PROOF_COMPLETE=no` until `0060` is satisfied
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
