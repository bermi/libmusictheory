# 0045 — MajMin Modes Geometry Numeric Cutover

> Dependencies: 0044
> Follow-up: additional payload-prune slices as needed

Status: Completed

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

- 2026-03-11 — `9ccb68c`
  - Added grouped modes geometry-slot invariant audit (`scripts/audit_majmin_modes_geometry_slots.py`) and wired it into `verify.sh`.
  - Updated `scripts/generate_harmonious_majmin_scene_pack.py` to:
    - detect per-group modes geometry prefix slots,
    - pack only non-geometry modes `d` replay maps,
    - emit dedicated grouped modes geometry refs module (`src/generated/harmonious_majmin_modes_geometry_refs.zig`).
  - Regenerated `src/generated/harmonious_majmin_scene_pack_xz.zig` with reduced modes replay dimensions (`MODE_MAX_D_SLOT_COUNT: 374 -> 248`, `MODE_MAX_D_BASE_COUNT: 223 -> 148`) and reduced raw pack payload (`PACK_RAW_LEN: 6488900 -> 6373012`).
  - Updated `src/svg/majmin_compat.zig` to render modes geometry prefix slots from grouped refs while using scene-pack replay only for non-geometry mode slots.
  - Added `0045` verify guardrails in `verify.sh` for:
    - reduced raw scene-pack baseline (`PACK_RAW_LEN < 6488900`),
    - grouped modes geometry module wiring (`harmonious_majmin_modes_geometry_refs`, `MODE_GEOMETRY_SLOT_COUNTS`),
    - reduced mode replay max slots (`MODE_MAX_D_SLOT_COUNT` no longer baseline `374`).
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
