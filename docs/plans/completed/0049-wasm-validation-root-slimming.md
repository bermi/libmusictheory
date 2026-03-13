# 0049 — WASM Validation Root Slimming

> Dependencies: 0048
> Follow-up: algorithmic compatibility payload reductions

Status: Completed

## Objective

Build `zig-out/wasm-demo/libmusictheory.wasm` from a dedicated validation-only Zig root so the shipped bundle keeps only the compatibility API surface and drops the full library entrypoint from the wasm link graph.

## Non-Goals

- Do not move compatibility generation or parity logic into runtime JS.
- Do not change the native static/shared library roots.
- Do not relax strict compatibility verification.

## Research Phase

1. Audit the current wasm build root and exported surface.
2. Identify the minimal imports/state required for `validation.js`.
3. Measure whether a dedicated validation root gets the installed bundle under strict decimal `500000` bytes.

## Pre-Implementation Verification Changes

- Add `verify.sh` guardrails for:
  - dedicated validation wasm root wiring in `build.zig`,
  - strict installed bundle budget `wasm + js < 500000`,
  - validation export profile remains present.

## Implementation Slices

1. Add `src/wasm_validation_api.zig` with only scratch + compatibility exports.
2. Switch wasm build in `build.zig` to use the dedicated validation root.
3. Convert exact `even` segmented payloads from gzip to xz so the validation wasm reuses the already-linked xz decoder and drops the extra gzip decode path.
4. Harden Playwright validation scripts to use a free localhost port by default, removing false negatives from `8000` collisions.
5. Re-run full validation and record the new bundle size.

## Exit Criteria

- installed `zig-out/wasm-demo` bundle is below `500000` bytes combined (`wasm + js`),
- full Playwright compatibility remains `8634/8634` exact matches,
- `./verify.sh` passes.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-13 — `d8ed9f8`
  - Added `src/wasm_validation_api.zig` and switched the wasm-demo target in `build.zig` to root at that dedicated validation-only ABI instead of `src/root.zig`.
  - Extended `verify.sh` with `0049` guardrails for:
    - dedicated validation wasm-root wiring,
    - strict installed validation bundle budget (`wasm + installed js < 500000`).
  - Replaced `even` exact segmented gzip assets with segmented xz assets:
    - added `scripts/generate_harmonious_even_segment_xz.py`,
    - generated `src/generated/harmonious_even_segment_xz.zig`,
    - removed legacy `scripts/generate_harmonious_even_segment_gzip.py`,
    - removed legacy `src/generated/harmonious_even_segment_gzip.zig`,
    - updated `src/svg/evenness_chart.zig` to decode xz segments.
  - Hardened Playwright validation infrastructure by making:
    - `scripts/validate_harmonious_playwright.mjs`,
    - `scripts/validate_harmonious_visual_diff.mjs`
    choose an ephemeral free localhost port unless `LMT_VALIDATION_PORT` is explicitly set.
  - Verified strict compatibility remains exact:
    - Playwright sampled: pass (`0` mismatches),
    - Playwright full: `8634/8634` exact matches (`0` mismatches).
  - Post-cutover installed validation bundle footprint:
    - wasm: `481,724` bytes,
    - js total: `15,714` bytes,
    - combined: `497,438` bytes (`< 500,000`).
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
