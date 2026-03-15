# 0056 — Simple Families Native-RGBA Proof Lane

> Dependencies: 0055

Status: In Progress

## Objective

Close the native-RGBA proof lane for the simple compatibility families with strict drift gates and explicit source reporting at both `55%` and `200%`.

## Current Scope

The currently supported native subset is:

- `opc`
- `optc`
- `oc`
- `center-square-text`
- `vert-text-black`
- `vert-text-b2t-black`

`even` is not considered closed until its candidate source is `native-rgba` and the anti-replay intent remains intact.

## Remaining Work

- add deterministic native candidate and reference handling for `even`, including its gradient case
- expand the native-proof Playwright run beyond the current six supported kinds once additional support is real

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity remains green
- exact SVG parity remains green
- anti-cheat rules remain green
- Playwright native-proof validation passes with `0` failures and no unsupported rows for the supported simple-family set

## Verification Commands

- `./verify.sh`
- `node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds opc,optc,oc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100`
