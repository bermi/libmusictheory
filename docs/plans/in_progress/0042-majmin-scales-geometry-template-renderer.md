# 0042 — MajMin Scales Geometry Template Renderer

> Dependencies: 0041, 0040
> Blocks: 0043

Status: In progress

## Objective

Replace the 76 replay-style scales geometry `d` strings with a deterministic template renderer driven by:

- slot decomposition (`cluster_idx`, `shape_idx`),
- compact coordinate token dictionaries,
- fixed shape path templates.

## Non-Goals

- Do not yet remove coordinate token tables (that is 0043).
- Do not yet change scene-pack payload structure (that is 0044).

## Pre-Implementation Verification Changes

- Add guardrails in `verify.sh`:
- reject full per-slot `SCALE_GEOMETRY_PATHS` replay array in geometry module,
- require template-renderer entrypoint and cluster/shape topology constants.

## Implementation Slices

1. Replace per-slot path array with topology + template emitter in `src/svg/majmin_scales_geometry.zig`.
2. Keep `src/svg/majmin_compat.zig` wiring unchanged except for new renderer call shape if needed.
3. Update tests to assert template renderer behavior and spot-check stable slots.

## Exit Criteria

- `SCALE_GEOMETRY_PATHS` full replay array removed.
- Strict byte parity remains `0` mismatches across sampled + full Playwright runs.
- `./verify.sh`, `zig build verify`, `zig build test` pass.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled when completed._
