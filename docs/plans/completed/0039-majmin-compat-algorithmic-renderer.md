# 0039 — MajMin Compatibility Pure Algorithmic Renderer

> Dependencies: 0038 (majmin structural audit), 0028 (compat integrity guardrails), 0029 (render IR foundation)
> Blocks: 0040+ (majmin payload retirement and further graph migrations)
> Does not block: current strict compatibility validation

Status: Completed

## Objective

Replace packed `majmin` compatibility reconstruction (`src/generated/harmonious_majmin_compat_xz.zig`) with deterministic scene-driven rendering that preserves strict byte-exact SVG parity and removes the old payload from the wasm reachability path.

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
- Progress:
  - scene parser + canonical scene/index mapping is implemented and verified;
  - compatibility `imageCount`/`imageName`/`generateByIndex` now enumerate majmin images via `majmin_scene` (no majmin filename manifest tables in wasm path).
  - polygon geometry invariants are now audited by group (`modes`: family+rotation, `scales`: family), confirming geometry templates are transposition-invariant where expected.
  - `majmin/scales` parametric decomposition invariants are now audited (`scripts/audit_majmin_scales_parametric.py`): one skeleton per family, stable static-vs-dynamic slot partition (`href/style/path`), and constrained cross-family path divergence for a fixed transposition.

### Slice B: `scales,*` Exact Parity Cutover

- Cut over `majmin/scales` first with strict parity verification.
- Preserve `modes` on compatibility payload until scales are fully stable.
- Progress:
  - `majmin/scales` regular scenes are now rendered via a family/transposition model in `src/svg/majmin_compat.zig` (slot-base arrays + transposition remap tables), rather than direct per-file dispatch.
  - legacy overview files (`scales,-1,,0,1|2`) remain routed through compatibility payload while regular family scenes are composed algorithmically from parsed primitives.
  - strict compatibility remains green (`0` mismatches) across sampled and full Playwright validation.

### Slice C: `modes,*` Exact Parity Cutover

- Cut over `majmin/modes` using the same scene rules.
- Remove packed majmin reconstruction dependency after full parity.
- Progress:
  - `majmin/modes` regular scenes are now rendered through grouped scene decomposition (`family + rotation` groups across canonical transpositions) in `src/svg/majmin_compat.zig`.
  - legacy overview files (`modes,-1,,-3,1|2`) remain routed through compatibility payload while regular groups are composed algorithmically from parsed primitives.

### Slice D: Payload Retirement + Reachability Enforcement

- Replace old compat payload import path with compact scene-pack asset and parser.
- Keep exact parity, strict verify gates, and wasm budgets intact.
- Progress:
  - `src/svg/majmin_compat.zig` now imports `src/generated/harmonious_majmin_scene_pack_xz.zig` (`MJM3` format) and parses:
    - shared skeleton/style/href/path template primitives,
    - grouped `modes` transposition remaps,
    - family `scales` transposition remaps,
    - raw legacy overview payloads.
  - `src/generated/harmonious_majmin_compat_xz.zig` is no longer referenced from wasm-reachable modules.
  - `verify.sh` now enforces:
    - scene-pack import guardrail,
    - no legacy-compat import reachability in `majmin_compat` / compat entrypoints,
    - scene-pack source-size envelope.

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
- 2026-03-07 — `4ad4431`
  - Added `scripts/audit_majmin_scales_parametric.py` and wired `0039` verify gate for family decomposition + transposition slot invariants.

- 2026-03-10 — `899e13c`
  - Cut over `majmin/scales` regular scenes to scene-driven rendering in `src/svg/majmin_compat.zig`.
  - Retained strict parity (`0` mismatches) with legacy overview files preserved.

- 2026-03-10 — `b89897c`
  - Cut over `majmin/modes` regular scenes to grouped (`family + rotation`) scene-driven rendering in `src/svg/majmin_compat.zig`.
  - Retained strict parity (`0` mismatches) with legacy overview files preserved.

- 2026-03-10 — `f90bef4`
  - Replaced old majmin compat payload import with `src/generated/harmonious_majmin_scene_pack_xz.zig` and `MJM3` parser path.
  - Added generator `scripts/generate_harmonious_majmin_scene_pack.py`.
  - Hardened `verify.sh` guardrails to ensure old payload is not reachable.
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
