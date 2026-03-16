# 0060 — Project-Level Native-RGBA Proof Closure

> Dependencies: 0056, 0057, 0058, 0059

Status: Completed

## Objective

Define the only acceptable project-level completion gate for visual rendering: all 15 compatibility kinds must pass native-RGBA proof at `55%` and `200%`.

## Completion Contract

The project may not be called visually complete until all of the following are true:

- exact SVG parity is green for all 15 kinds
- scaled render parity is green for all 15 kinds at `55%` and `200%`
- native-RGBA proof is green for all 15 kinds at `55%` and `200%`
- every proof row reports `candidateSource = native-rgba`
- no page, script, doc, or summary claims project completion before that state exists

## Exit Criteria

- `NATIVE_RGBA_PROOF_COMPLETE=yes` in `./verify.sh`
- all-family Playwright native-proof validation passes at both scales
- `0056`, `0057`, `0058`, and `0059` are complete

## Verification Commands

- `./verify.sh`
- `zig build wasm-native-rgba-proof`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`

## Implementation History (Point-in-Time)

- `61c199c` — 2026-03-15
- `90cc334` — 2026-03-16
- Completion state shipped in this plan:
  - closed the full-corpus strict proof lane so `/Users/bermi/code/libmusictheory/verify.sh` now reports `NATIVE_RGBA_PROOF_COMPLETE=yes`
  - completed all-kind strict proof through `/Users/bermi/code/libmusictheory/scripts/validate_harmonious_native_rgba_proof_playwright.mjs`
  - preserved `exact-svg parity` and `scaled render parity` while moving the last two majmin kinds into the strict native-proof set
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
