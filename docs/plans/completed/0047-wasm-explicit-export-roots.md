# 0047 — WASM Explicit Export Roots

> Dependencies: 0046
> Follow-up: additional algorithmic payload reduction slices

Status: Completed

## Objective

Replace wasm `rdynamic` linkage with explicit export roots so `libmusictheory.wasm` only retains the required C ABI surface and memory export, reducing wasm size without changing behavior.

## Non-Goals

- Do not remove any C ABI function currently required by `examples/wasm-demo/app.js` and `examples/wasm-demo/validation.js`.
- Do not relax strict compatibility parity verification.

## Research Phase

1. Enumerate all `export fn` symbols in `src/c_api.zig`.
2. Verify which symbols are required by wasm demo clients.
3. Validate that explicit export roots preserve compatibility and demo initialization.

## Pre-Implementation Verification Changes

- Add `verify.sh` checks that:
  - wasm build uses explicit export list wiring for module roots,
  - `rdynamic` is disabled for wasm executable,
  - wasm binary exports all required demo symbols.

## Implementation Slices

1. Add wasm export-check script (`scripts/check_wasm_exports.mjs`).
2. Switch wasm build wiring in `build.zig` to explicit `export_symbol_names` and `rdynamic = false`.
3. Validate wasm demo + compatibility page behavior and exact-match parity.

## Exit Criteria

- wasm initializes in demo and validation pages with required symbols present.
- full Playwright compatibility remains `8634/8634` exact matches.
- wasm size drops further from 0046 baseline.
- `./verify.sh` passes.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-12 — `<pending commit>`
  - Added wasm export-surface verification script:
    - `scripts/check_wasm_exports.mjs`
  - Added `0047` guardrails to `verify.sh` for:
    - explicit wasm export root wiring in `build.zig`,
    - `rdynamic = false` on wasm executable,
    - required demo/compat export presence in final wasm binary.
  - Updated wasm build wiring in `build.zig`:
    - introduced explicit `wasm_mod.export_symbol_names` list,
    - switched wasm linkage from `rdynamic = true` to `rdynamic = false`.
  - Verified strict compatibility remains exact:
    - Playwright sampled: pass (`0` mismatches),
    - Playwright full: `8634/8634` exact matches (`0` mismatches).
  - wasm size after cutover:
    - `517,164` bytes (`zig-out/wasm-demo/libmusictheory.wasm`).
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
