# 0040 — MajMin Scales Geometry Procedural Cutover

> Dependencies: 0039 (scene-driven majmin renderer), 0038 (majmin structural audits), 0028 (integrity guardrails)
> Blocks: 0041+ (majmin text/link fully procedural migration)
> Does not block: strict compatibility verification

Status: In progress

## Objective

Replace `majmin/scales` regular-scene polygon geometry path replay with deterministic procedural emission while preserving strict byte parity.

Scope for this plan:

- `majmin/scales,*` regular scenes only (48 files),
- geometry path layer only (the invariant polygon tile layer),
- retain current scene-pack path for non-geometry layers in this slice.

## Non-Goals

- Do not weaken byte-exact parity requirements.
- Do not remove `modes` scene-pack replay in this plan.
- Do not claim full procedural migration for text/glyph/href layers in this plan.

## Research Phase

1. Validate geometry-slot invariants needed for cutover:
- path slots `0..75` are geometry layer in regular scales scenes,
- geometry slot order is stable across all transpositions and families,
- geometry `d` payload is invariant across regular scales scenes.

2. Confirm renderer ordering constraints:
- generated output must preserve original skeleton ordering and spacing,
- geometry `d` values must remain byte-identical.

3. Define guardrails:
- procedural geometry module presence + wiring in `majmin_compat`,
- invariant-audit script for scales geometry slot assumptions.

## Implementation Slices

### Slice A: Geometry Slot Audit + Guardrails

- Add a dedicated audit script for scales geometry-slot invariants.
- Wire script into `./verify.sh` (conditional on local harmonious references).

### Slice B: Procedural Geometry Renderer Integration

- Add `src/svg/majmin_scales_geometry.zig` with deterministic geometry path emission for the 76 scales geometry slots.
- Integrate into `src/svg/majmin_compat.zig` `renderScales` path dispatch:
- geometry slots emitted from procedural module,
- non-geometry slots continue through scene-pack template replay.

### Slice C: Verification + Stability

- Run full `./verify.sh` including sampled + full Playwright compatibility validation.
- Ensure no mismatch regressions and no wasm size regression.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- `zig build test` passes.
- Playwright sampled and full compatibility remain `0` mismatches.
- `majmin/scales` geometry slots are no longer emitted through template replay.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled at completion._
