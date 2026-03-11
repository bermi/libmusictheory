# 0046 — WASM Compat Name-Pack Cutover

> Dependencies: 0045
> Follow-up: algorithmic enumerators by kind (future slices)

Status: Completed

## Objective

Remove `src/generated/harmonious_manifest.zig` from the WASM compatibility runtime path and replace it with a compact decoded name-pack so the compatibility API still enumerates all images while materially reducing wasm size toward the ~0.5MB baseline.

## Non-Goals

- Do not relax strict SVG byte-parity requirements (`0` mismatches remains mandatory).
- Do not remove strict native compatibility checks.
- Do not claim this slice is full algorithmic enumeration for all kinds.

## Research Phase

1. Audit all imports and call-sites that pull `harmonious_manifest` into `libmusictheory.wasm`.
2. Verify each compatibility kind can keep `generateByName` unchanged while `imageCount`/`imageName` are served from a compact pack.
3. Measure reachable generated footprint before/after via `scripts/wasm_size_audit.py`.

## Pre-Implementation Verification Changes

- Add guardrails in `./verify.sh` that fail if runtime compat path imports `harmonious_manifest.zig`.
- Tighten wasm size budget for this slice beyond prior `<1MB` gate.
- Keep full Playwright validation gates unchanged (sampled + full pass).

## Implementation Slices

1. Add generated compact name-pack module (`src/generated/harmonious_name_pack_xz.zig`) plus generator script.
2. Rework `src/harmonious_svg_compat.zig` to use compact kind metadata + name-pack decode path for non-majmin kinds.
3. Keep majmin scene names/indexing on existing algorithmic `svg_majmin_scene` path.
4. Add/adjust tests for kind metadata and name enumeration stability.

## Exit Criteria

- `harmonious_manifest.zig` is no longer reachable from wasm runtime compatibility path.
- Compatibility API still enumerates all required image names and renders exact matches.
- Full Playwright run reports `0` mismatches across all 8634 images.
- wasm size drops materially and is below new guardrail.
- `./verify.sh` passes.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-11 — `b3d9e8c`
  - Added compact packed image-name generation pipeline:
    - `scripts/generate_harmonious_name_pack.py`
    - `src/generated/harmonious_name_pack_xz.zig`
    - `src/harmonious_name_pack.zig` runtime xz decode/index module.
  - Reworked `src/harmonious_svg_compat.zig` to remove runtime dependency on `src/generated/harmonious_manifest.zig` and serve non-majmin `imageCount`/`imageName` from name-pack while preserving existing render logic.
  - Added focused decode/index tests in `src/tests/harmonious_name_pack_test.zig` and wired them in `src/root.zig`.
  - Added `0046` verify guardrails in `verify.sh`:
    - runtime path forbidden from importing `generated/harmonious_manifest.zig`,
    - compact name-pack wiring checks,
    - tightened wasm size budgets (`<512KiB` total, stricter data/reachable-generated budgets).
  - Updated coordinator + wasm footprint research docs with post-cutover metrics.
  - Completion gates executed:
    - `./verify.sh` (Playwright sampled + full pass, `8634/8634` exact matches)
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
