# 0043 — MajMin Scales Geometry Analytic Coordinates

> Dependencies: 0042
> Blocks: 0044

Status: Completed

## Objective

Replace compact coordinate token replay in `majmin/scales` geometry renderer with computed coordinates and deterministic decimal emission.

## Non-Goals

- Do not modify scene-pack payload schema in this milestone.
- Do not migrate modes geometry in this milestone.

## Pre-Implementation Verification Changes

- Add `verify.sh` guardrails that reject coordinate token replay tables in `src/svg/majmin_scales_geometry.zig`.
- Require analytic coordinate constants/functions (start/step/wrap + slot mapping).

## Implementation Slices

1. Implement analytic center/vertex generation from slot index.
2. Implement deterministic decimal formatter that preserves byte parity for reference coordinates.
3. Update tests with broader slot snapshot coverage to prevent formatting regressions.

## Exit Criteria

- No coordinate token replay tables in scales geometry module.
- Strict parity still `0` mismatches across full compatibility validation.
- `./verify.sh`, `zig build verify`, `zig build test` pass.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-11 — `2c93650`
  - Replaced scales geometry coordinate token dictionaries (`X_TOKENS`, `Y_TOKENS`) and per-cluster token-index maps (`CLUSTERS_X`, `CLUSTERS_Y`) with analytic coordinate contexts in `src/svg/majmin_scales_geometry.zig`.
  - Added explicit analytic coordinate constants/functions (`SCALE_GEOMETRY_STEP_X`, `SCALE_GEOMETRY_STEP_Y`, `xCoordFor`, `yCoordFor`) and preserved byte-identical geometry path emission through deterministic `f64` formatting.
  - Added `0043` verify guardrails in `verify.sh` that reject coordinate-token replay dictionaries and require analytic coordinate constants/functions.
  - Updated `src/tests/majmin_scales_geometry_test.zig` with analytic step-constant assertions while preserving slot-level path snapshot checks.
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
