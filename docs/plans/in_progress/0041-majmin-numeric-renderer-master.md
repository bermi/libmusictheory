# 0041 — MajMin Numeric Renderer Master Plan

> Dependencies: 0040, 0039, 0028
> Parent track: strict harmonious SVG parity
> Scope: `majmin/modes` + `majmin/scales` regular scenes (legacy overview files stay compatibility-routed until explicitly replaced)

Status: In progress

## Objective

Migrate majmin regular-scene geometry rendering from replay-style payload usage to numeric/procedural rendering, without regressing byte parity, Playwright validation, or wasm size constraints.

## Why This Plan Exists

- 0040 removed scene-pack template replay from `majmin/scales` geometry slots, but still uses full-path replay strings.
- We need verifiable milestones that progressively remove replay-style dependency and keep anti-self-deception guardrails active.

## Milestone Subplans

### 0042 — Scales Geometry Template Renderer

- Replace 76 full `d` strings with:
- slot/cluster/shape decomposition,
- compact coordinate token topology,
- deterministic path template emitter.
- Verification:
- strict byte parity unchanged,
- no full-path replay array remains.

### 0043 — Scales Geometry Analytic Coordinates

- Replace coordinate token topology tables with computed coordinate generation.
- Keep exact string parity by deterministic decimal formatting strategy.
- Verification:
- no coordinate replay tables for scales geometry module,
- strict parity unchanged.

### 0044 — Scales Scene-Pack Geometry Prune

- Remove scales-geometry payload from scene-pack generator/parser path.
- Keep only non-geometry payload needed by current renderer slice.
- Verification:
- scene-pack size reduction,
- strict parity unchanged,
- wasm budgets remain green.

### 0045 — Modes Geometry Numeric Cutover

- Apply the same geometry migration strategy to modes groups.
- Prune modes geometry replay payload after parity stability.
- Verification:
- strict parity unchanged for all kinds,
- scene-pack footprint reduced further.

## Global Constraints

- No reference SVG embedding.
- No placeholder visual-only parity.
- `./verify.sh` remains the release gate.
- Playwright sampled and full compatibility checks remain mandatory.
- Each milestone must add verify guardrails before code changes.

## Exit Criteria

- Scales and modes regular-scene geometry are rendered from numeric/procedural logic.
- Scene-pack no longer carries replay-style geometry payload for migrated slices.
- `./verify.sh`, `zig build verify`, `zig build test`, and both Playwright validations pass.

## Implementation History (Point-in-Time)

_To be filled when milestone chain is complete._
