# 0050 — WASM Docs Bundle And Installed Validation

> Dependencies: 0049
> Follow-up: optional richer docs/examples coverage

Status: Completed

## Objective

Make the documented local browser workflows actually work:

- `zig-out/wasm-demo/validation.html` must validate successfully when served directly from `zig-out/wasm-demo`,
- full interactive API docs with rendered examples must be available in a separate installed wasm bundle with the required exports.

## Non-Goals

- Do not bloat the validation-focused `zig-out/wasm-demo` wasm+js bundle past the strict `< 500000` budget.
- Do not relax Playwright verification for validation parity.
- Do not move runtime music-theory logic from wasm into JS.

## Research Phase

1. Audit why `validation.html` fails when served from `zig-out/wasm-demo`.
2. Audit why `examples/wasm-demo/index.html` fails against the slim validation wasm.
3. Define a split between:
   - validation-focused installed bundle,
   - full docs installed bundle.

## Pre-Implementation Verification Changes

- Add `verify.sh` guardrails for:
  - a `wasm-docs` build target,
  - installed reference mirroring into `zig-out/wasm-demo`,
  - full-demo wasm export verification,
  - Playwright smoke validation of the full docs bundle.

## Implementation Slices

1. Install local harmonious reference files into installed browser bundles when `tmp/harmoniousapp.net` exists.
2. Add a dedicated `wasm-docs` installed bundle that ships the full interactive docs surface and full wasm export set.
3. Update Playwright validation scripts to exercise the installed validation bundle exactly as documented.
4. Add a docs Playwright smoke test that loads the full docs page and verifies rendered examples.

## Exit Criteria

- `zig-out/wasm-demo/validation.html` works when served from `zig-out/wasm-demo` with local references present.
- `zig-out/wasm-docs/index.html` loads without missing-export failures and renders example outputs from wasm.
- `./verify.sh` passes, including Playwright validation and docs smoke checks.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `zig build wasm-demo`
- `zig build wasm-docs`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`
- `node scripts/validate_wasm_docs_playwright.mjs`

## Implementation History (Point-in-Time)

- 2026-03-13 — `ab8ccb5`
  - Updated `build.zig` to produce two installed browser outputs:
    - `zig-out/wasm-demo`: validation-focused slim bundle using `src/wasm_validation_api.zig`,
    - `zig-out/wasm-docs`: full interactive docs bundle using `src/root.zig` with the full demo export surface.
  - Added conditional install-directory mirroring for local harmonious references when `tmp/harmoniousapp.net` exists:
    - `zig-out/wasm-demo/tmp/harmoniousapp.net`,
    - `zig-out/wasm-docs/tmp/harmoniousapp.net`.
  - Updated installed validation/browser verification to match documented usage:
    - `scripts/validate_harmonious_playwright.mjs` now serves `zig-out/wasm-demo`,
    - `scripts/validate_harmonious_visual_diff.mjs` now serves `zig-out/wasm-demo`.
  - Added full docs Playwright smoke verification:
    - `scripts/validate_wasm_docs_playwright.mjs`
    - validates `zig-out/wasm-docs/index.html` initializes wasm and renders example outputs/SVGs.
  - Updated `examples/wasm-demo/README.md` to document the split workflow:
    - `wasm-demo` for validation,
    - `wasm-docs` for full interactive API docs.
  - Verified results:
    - installed validation bundle still passes full exact parity (`8634/8634`, `0` mismatches, `0` missing refs),
    - installed validation bundle remains under strict budget (`497,438` bytes combined wasm+js),
    - installed full docs bundle loads without missing exports and renders example outputs from wasm.
  - Completion gates executed:
    - `./verify.sh`
    - `zig build verify`
    - `zig build test`
    - `zig build wasm-demo`
    - `zig build wasm-docs`
    - `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
    - `node scripts/validate_harmonious_playwright.mjs`
    - `node scripts/validate_wasm_docs_playwright.mjs`
