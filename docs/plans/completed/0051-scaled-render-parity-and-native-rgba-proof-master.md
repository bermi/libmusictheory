# 0051 — Scaled Render Parity And Native-RGBA Proof Master

> Dependencies: 0030, 0031, 0050
> Follow-up: 0052-0060 staged slice plans

Status: Completed

## Objective

Rebase the visual validation track so the repo makes only truthful claims:

- `proof` is reserved for `native-rgba` only.
- `scaled-render-parity` is the all-kind target-size bitmap diff lane.
- full visual completion remains blocked until all 15 compatibility kinds pass both scales (`55%` and `200%`) through direct `native-rgba` generation.

## Lane Model

### 1. Exact SVG Parity

- authoritative site-reproduction lane
- byte-for-byte SVG match against harmoniousapp.net
- all 15 kinds

### 2. Scaled Render Parity

- compares candidate and harmonious reference at the same target bitmap size
- valid for all 15 kinds
- candidate source may be either:
  - `native-rgba`
  - `generated-svg`
- this lane is necessary, but insufficient, for project completion

### 3. Native-RGBA Proof

- candidate pixels come directly from Zig/WASM RGBA output
- JS only paints bytes into `ImageData`
- no candidate SVG decode-and-raster shortcut
- no post-render scaling
- this is the only lane allowed to use the word `proof`

## Delivered Outcome

- `Exact SVG Parity` is green for all 15 kinds
- `Scaled Render Parity` is green for all 15 kinds at `55%` and `200%`
- `Native-RGBA Proof` is green for all 15 kinds at `55%` and `200%`
- `./verify.sh` now reports `NATIVE_RGBA_PROOF_COMPLETE=yes`
- the repo no longer conflates parity-only candidate paths with strict proof claims

## Bundle Split

- `zig-out/wasm-demo`
  - exact SVG parity lane only
- `zig-out/wasm-scaled-render-parity`
  - all-kind target-size bitmap diff lane
- `zig-out/wasm-native-rgba-proof`
  - strict native-only proof lane
- `zig-out/wasm-docs`
  - full interactive examples

## Verification Commands

- `./verify.sh`
- `zig build wasm-scaled-render-parity`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `61c199c` — 2026-03-15
- `90cc334` — 2026-03-16
- `65855c4` — 2026-03-16
- Completion state shipped in this plan:
  - split the old mixed bitmap lane into `Scaled Render Parity` and `Native RGBA Proof`
  - tightened terminology and guardrails so parity-only lanes are not mislabeled as proof
  - closed the family slices `0056`, `0057`, and `0058`, the parity closure `0059`, and the project-level proof closure `0060`
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
