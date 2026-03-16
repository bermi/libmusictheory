# 0057 — Staff And Fret Native-RGBA Proof Lane

> Dependencies: 0055, 0056

Status: Completed

## Objective

Close native-RGBA proof for the staff and fret compatibility families while preserving exact SVG parity and scaled-render-parity at both `55%` and `200%`.

## Target Families

- `scale`
- `eadgbe`
- `chord`
- `wide-chord`
- `chord-clipped`
- `grand-chord`

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity still green
- exact SVG parity still green
- anti-cheat rules still green

## Completed Slices

- Tightened `./verify.sh` so `eadgbe` is required in the sampled native-RGBA proof lane and added deterministic native candidate/reference bitmap support for `eadgbe`.
- Tightened `./verify.sh` so `wide-chord` and `chord-clipped` are required in the sampled native-RGBA proof lane and added native SVG-document bitmap support for both at `55%` and `200%`.
- Tightened `./verify.sh` so `chord` and `grand-chord` are required in the sampled native-RGBA proof lane and added native SVG-document bitmap support for both at `55%` and `200%`.
- Tightened `./verify.sh` so `scale` is required in the sampled native-RGBA proof lane, added deterministic native candidate/reference bitmap support for `scale`, and reset proof/parity wasm scratch allocation per kind/scale batch so the browser validators remain honest under the expanded proof subset.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds scale,opc,optc,oc,eadgbe,wide-chord,chord-clipped,grand-chord,chord,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `b1778f6` — 2026-03-16
- `99f0dc9` — 2026-03-16
- `702c7b6` — 2026-03-16
- Completion state shipped in this plan:
  - added strict native-RGBA proof support for `wide-chord`, `chord-clipped`, `grand-chord`, and `chord` through Zig-side document rasterization in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - added strict native-RGBA proof support for `scale` through deterministic candidate generation plus Zig-side reference rasterization in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - tightened `/Users/bermi/code/libmusictheory/verify.sh` and `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs` so sampled proof validation now requires `scale`, `eadgbe`, and the full chord/staff subset at both canonical scales
  - fixed `/Users/bermi/code/libmusictheory/examples/wasm-demo/native-rgba-proof.js` and `/Users/bermi/code/libmusictheory/examples/wasm-demo/scaled-render-parity.js` to reset wasm scratch allocation per kind/scale batch, preventing false failures from arena exhaustion during honest browser validation
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds scale,opc,optc,oc,eadgbe,wide-chord,chord-clipped,grand-chord,chord,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`
