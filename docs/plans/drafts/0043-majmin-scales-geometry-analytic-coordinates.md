# 0043 — MajMin Scales Geometry Analytic Coordinates

> Dependencies: 0042
> Blocks: 0044

Status: Draft

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

_To be filled when completed._
