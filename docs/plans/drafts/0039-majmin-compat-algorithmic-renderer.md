# 0039 — MajMin Compatibility Pure Algorithmic Renderer

> Dependencies: 0038 (majmin structural audit), 0028 (compat integrity guardrails), 0029 (render IR foundation)
> Blocks: 0040+ (majmin payload retirement and further graph migrations)
> Does not block: current strict compatibility validation

Status: Draft

## Objective

Replace packed `majmin` compatibility reconstruction (`src/generated/harmonious_majmin_compat_xz.zig`) with a fully algorithmic renderer that preserves strict byte-exact SVG parity.

## Non-Goals

- Do not ship visual-only parity (byte-exact parity remains required).
- Do not weaken wasm size or anti-embed guardrails.
- Do not introduce per-file coordinate replay tables as a substitute for generation logic.

## Research Phase

### 1. Topology Model Extraction

- Map `majmin/modes` and `majmin/scales` stems to explicit topology parameters:
  - transposition,
  - family (`dntri`, `hex`, `rhomb`, `uptri`, legacy empty-shape variants),
  - rotation/variant semantics.
- Relate these parameters to the existing algorithmic tessellation model in `src/svg/tessellation.zig`.

### 2. Primitive Model Derivation

- Derive reusable path/anchor/style primitives from audited structure and symbolic rules.
- Define deterministic ordering rules matching compatibility output emission order.

### 3. Migration and Guardrails

- Add verify checks that ensure algorithmic path is used for migrated subsets.
- Add progressive payload reduction gates to ensure packed majmin data decreases across slices.

## Implementation Slices

### Slice A: Modes/Scales Shared Scene Model

- Build an explicit scene generator from topology parameters.
- Keep renderer backend swappable (SVG now, raster-ready via IR).

### Slice B: `scales,*` Exact Parity Cutover

- Cut over `majmin/scales` first with strict parity verification.
- Preserve `modes` on compatibility payload until scales are fully stable.

### Slice C: `modes,*` Exact Parity Cutover

- Cut over `majmin/modes` using the same scene rules.
- Remove packed majmin reconstruction dependency after full parity.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- `zig build test` passes.
- Playwright strict compatibility passes with `0` mismatches.
- `src/generated/harmonious_majmin_compat_xz.zig` is removed from reachable wasm path.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
