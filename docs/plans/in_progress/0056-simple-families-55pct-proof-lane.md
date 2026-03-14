# 0056 — Simple Families 55% Proof Lane

> Dependencies: 0055

Status: In Progress

## Objective

Close the bitmap-proof lane for the simple compatibility families with strict drift gates and explicit support reporting.

## Current Scope

This plan is being executed in honest sub-slices. The first supported set beyond `opc` is the reusable glyph family:

- `center-square-text`
- `vert-text-black`
- `vert-text-b2t-black`
- `opc` remains covered

Families such as `optc`, `oc`, and `even` are not considered closed until their candidate path is proven algorithmic enough to satisfy the anti-replay intent of the bitmap-proof track.

## Remaining Work

- Add honest bitmap-proof support for `optc` without regressing the anti-replay intent of the track.
- Decide whether `oc` can be supported from an algorithmic candidate path or needs a deeper renderer/data reduction cutover first.
- Add deterministic reference and candidate handling for `even`, including its gradient case.
- Expand the Playwright proof run from the current four supported kinds to the remaining simple-family set once support is real.

## Exit Criteria For The Current Slice

- The proof lane reports support for `opc`, `center-square-text`, `vert-text-black`, and `vert-text-b2t-black`.
- Playwright sampled proof passes for those families with `0` failures and no unsupported rows.
- Existing exact SVG parity remains green.

## Verification Commands

- `./verify.sh`
- `node scripts/validate_harmonious_bitmap_playwright.mjs --sample-per-kind 5 --kinds opc,center-square-text,vert-text-black,vert-text-b2t-black`
