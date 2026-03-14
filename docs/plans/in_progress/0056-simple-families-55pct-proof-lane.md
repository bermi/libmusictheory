# 0056 — Simple Families Native-RGBA Proof Lane

> Dependencies: 0055

Status: In Progress

## Objective

Close the native-RGBA proof lane for the simple compatibility families with strict drift gates and explicit source reporting at both `55%` and `200%`.

## Current Scope

The currently supported native subset is:

- `opc`
- `center-square-text`
- `vert-text-black`
- `vert-text-b2t-black`

Families such as `optc`, `oc`, and `even` are not considered closed until their candidate source is `native-rgba` and the anti-replay intent remains intact.

## Remaining Work

- add honest `native-rgba` support for `optc`
- determine whether `oc` needs a deeper renderer or data reduction cutover before native proof is realistic
- add deterministic native candidate and reference handling for `even`, including its gradient case
- expand the native-proof Playwright run beyond the current four supported kinds once support is real

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity remains green
- exact SVG parity remains green
- anti-cheat rules remain green
- Playwright native-proof validation passes with `0` failures and no unsupported rows for the supported simple-family set

## Verification Commands

- `./verify.sh`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds opc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`
