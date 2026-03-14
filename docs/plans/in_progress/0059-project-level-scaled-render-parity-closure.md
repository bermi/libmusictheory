# 0059 — Project-Level Scaled Render Parity Closure

> Dependencies: 0056, 0057, 0058

Status: In Progress

## Objective

Close the all-kind scaled-render-parity lane across required scales (`55%` and `200%`) without overstating that parity as native proof.

## Scope

This plan exists to ensure that every compatibility kind participates in target-size bitmap comparison, even while some kinds still rely on generated SVG as the candidate source.

Allowed candidate sources in this lane:

- `native-rgba`
- `generated-svg`

This plan does not imply visual project completion.

## Constraints

- exact SVG parity remains green
- native-supported kinds must continue to report `native-rgba`
- generated-SVG rows must rasterize directly at target dimensions
- parity UI and Playwright must report candidate source per kind/scale row
- no legacy generated-SVG terminology in user-facing text

## Exit Criteria

- every compatibility kind participates in scaled-render-parity at `55%` and `200%`
- all parity rows report candidate source explicitly
- all parity runs have `0` drift failures
- completion of this plan alone must not be presented as project completion

## Verification Commands

- `./verify.sh`
- `zig build wasm-scaled-render-parity`
- `node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100`
