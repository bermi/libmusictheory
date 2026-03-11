# 0045 — MajMin Modes Geometry Numeric Cutover

> Dependencies: 0044
> Follow-up: additional payload-prune slices as needed

Status: Draft

## Objective

Apply the numeric geometry renderer strategy used for scales to `majmin/modes` grouped scenes and retire corresponding modes geometry replay payload.

## Non-Goals

- Do not migrate non-geometry text/link layers in this milestone.
- Do not alter legacy overview (`modes,-1,,-3,*`) compatibility routing.

## Pre-Implementation Verification Changes

- Add modes geometry-slot invariant audit (grouped by family/rotation) with explicit slot contracts.
- Add `verify.sh` guardrails for numeric modes geometry module presence and wiring.

## Implementation Slices

1. Build modes geometry topology model (`group + transposition + slot -> geometry shape`).
2. Integrate numeric modes geometry emission into `src/svg/majmin_compat.zig`.
3. Prune modes geometry replay payload in scene-pack generation.

## Exit Criteria

- Modes regular-scene geometry no longer depends on replay-style path payload.
- Scene-pack footprint shrinks further.
- Full strict compatibility remains `0` mismatches.
- `./verify.sh`, `zig build verify`, `zig build test` pass.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled when completed._
