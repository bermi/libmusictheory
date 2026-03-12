# 0048 — WASM Validation Bundle Budget

> Dependencies: 0047
> Follow-up: optional dual-artifact split for full interactive demo

Status: Completed

## Objective

Enforce a strict validation-bundle budget where installed `zig-out/wasm-demo` assets satisfy:
- `libmusictheory.wasm + all installed .js <= 512 KiB`

while preserving full harmonious compatibility validation behavior and exact SVG parity.

## Non-Goals

- Do not move rendering/compatibility logic from wasm into runtime JS.
- Do not relax full Playwright parity checks.

## Research Phase

1. Measure current wasm + js totals in `zig-out/wasm-demo`.
2. Identify required wasm exports for `validation.html` only.
3. Confirm validation asset install set can be narrowed without impacting compatibility harness.

## Pre-Implementation Verification Changes

- Add `verify.sh` guardrails for:
  - validation wasm export surface,
  - installed js footprint,
  - combined wasm+js budget (`<= 524288`).

## Implementation Slices

1. Narrow wasm export roots to validation-required C ABI only.
2. Install validation-focused wasm-demo assets only.
3. Add combined bundle-size guardrail and keep full parity verification unchanged.

## Exit Criteria

- `zig-out/wasm-demo/libmusictheory.wasm + js_total <= 524288` bytes.
- `node scripts/check_wasm_exports.mjs` passes for validation-required exports.
- full Playwright compatibility remains `8634/8634` exact matches.
- `./verify.sh` passes.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-12 — `0522936`
  - Switched wasm export roots in `build.zig` to validation-required C ABI only (`lmt_svg_compat_*` + scratch + memory export).
  - Kept `rdynamic = false` and retained parity-critical wasm logic entirely in Zig/WASM.
  - Made installed `zig-out/wasm-demo` assets validation-focused:
    - installs `validation.html`, `validation.js`, `styles.css`,
    - writes tiny stubs for `index.html` and `app.js` in output to avoid stale large assets inflating bundle totals.
  - Extended wasm export check script with profile support:
    - `scripts/check_wasm_exports.mjs --profile validation`.
  - Added hard bundle budget gate in `verify.sh`:
    - installed `wasm + js <= 524288`.
  - Verified strict parity remains exact:
    - Playwright sampled: pass (`0` mismatches),
    - Playwright full: `8634/8634` exact matches (`0` mismatches).
  - Post-cutover installed bundle footprint:
    - wasm: `499,854` bytes,
    - js total: `15,714` bytes,
    - combined: `515,568` bytes (`<= 524,288`).
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
