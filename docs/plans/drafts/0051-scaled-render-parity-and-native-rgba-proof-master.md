# 0051 — Scaled Render Parity And Native-RGBA Proof Master

> Dependencies: 0030, 0031, 0050
> Follow-up: 0052-0060 staged slice plans

Status: Draft

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

## Do Not Fool Ourselves

A family is not visually complete unless all of the following are true:

1. exact SVG parity stays green
2. scaled render parity stays green at `55%` and `200%`
3. native-RGBA proof stays green at `55%` and `200%`
4. anti-cheat rules still ban replay shortcuts and browser-side scaling shortcuts

If a family only passes scaled render parity through `generated-svg`, it is not proven.

## Naming Rules

- do not use `proof` for generated-SVG or browser-raster candidate paths
- do not use the legacy generated-SVG label in user-facing text
- report candidate source as:
  - `native-rgba`
  - `generated-svg`

## Bundle Split

- `zig-out/wasm-demo`
  - exact SVG parity lane only
- `zig-out/wasm-scaled-render-parity`
  - all-kind target-size bitmap diff lane
- `zig-out/wasm-native-rgba-proof`
  - strict native-only proof lane
- `zig-out/wasm-docs`
  - full interactive examples

## Coordinated Slice Roles

- `0052` and `0053` define proof-lane guardrails and RGBA ABI/export surface
- `0054` and `0055` improve deterministic raster support for native proof work
- `0056`, `0057`, and `0058` are native-proof closure slices by family group
- `0059` is scaled-render-parity closure only
- `0060` is the only project-level visual completion plan

## Completion Policy

The visual rendering project is complete only when:

- exact SVG parity passes for all 15 kinds
- scaled render parity passes for all 15 kinds at `55%` and `200%`
- native-RGBA proof passes for all 15 kinds at `55%` and `200%`

## Verification Commands

- `./verify.sh`
- `zig build wasm-scaled-render-parity`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds opc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`
