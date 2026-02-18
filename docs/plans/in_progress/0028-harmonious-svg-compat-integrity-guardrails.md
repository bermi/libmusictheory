# 0028 — Harmonious SVG Compatibility Integrity Guardrails

> Dependencies: 0024 (foundation)
> Blocks: 0025, 0026, 0027 completion

## Objective

Guarantee that harmoniousapp.net compatibility is achieved algorithmically, not by embedding or replaying reference SVG files, while preserving fast and trustworthy verification.

This plan defines non-negotiable constraints, anti-cheating checks, and a phased execution strategy so we cannot accidentally (or intentionally) fool ourselves.

## Non-Negotiable Principles

1. Generated SVGs must come from Zig algorithms and deterministic rendering logic.
2. Compatibility reference files (`tmp/harmoniousapp.net/**/*.svg`) are test fixtures only, never generation inputs.
3. Validation input arguments and image names must come from public/internal compatibility APIs, not ad-hoc frontend parsing.
4. WASM demo artifact must stay lightweight and algorithmic:
   - hard gate: `zig-out/wasm-demo/libmusictheory.wasm < 1 MB`.
5. A passing compatibility run means:
   - all images generated,
   - zero mismatches,
   - zero missing references,
   - mismatch preview persists when a mismatch exists.

## Do / Don't

### Do

- Do use harmoniousapp sources (`js-client`, HTML pages, naming patterns) to infer rendering behavior and parameter grammars.
- Do write focused per-kind exact-match tests and run them through `zig build test` and Playwright validation.
- Do keep a clear provenance trail for each implemented kind (where behavior was researched and how mapped to Zig).
- Do fail verification early when guardrails are violated.

### Don't

- Don't use `@embedFile` (or any equivalent) to load reference SVGs for output generation.
- Don't read reference SVG files at runtime from `src/` generation code or C API generation paths.
- Don't generate expected output in JavaScript and compare against itself.
- Don't relax byte-exact checks into semantic checks for completion criteria.

## Research Phase (Mandatory Before Each Kind Group)

For each kind group (`0025`, `0026`, `0027`):

1. Locate original generation code paths under `tmp/harmoniousapp.net/js-client/` and related page assets.
2. Document filename grammar and parameter derivation rules.
3. Map grammar to explicit Zig API methods:
   - kind enumeration,
   - image name enumeration,
   - argument derivation,
   - SVG generation.
4. Record known differences between current Zig output and reference output.
5. Define small reproducible fixtures for first mismatch debugging.

## Implementation Slices

### Slice 0 — Integrity Reset

- Remove any non-algorithmic generation shortcuts introduced in compatibility path.
- Ensure compatibility generators no longer embed or read reference SVG content.
- Restore package/build layout to normal algorithmic generation assumptions.

### Slice 1 — Hard Guardrails in Verification

- Update `verify.sh` with explicit checks:
  - WASM size gate (`< 1 MB`).
  - Static scan gate: fail if generation paths reference `tmp/harmoniousapp.net` SVG payloads or use `@embedFile` for compat outputs.
  - Playwright compatibility gate requiring 0 mismatches and 0 missing refs when references exist.
- Add clear fail messages that explain which guardrail was violated.

### Slice 2 — Harness Trustworthiness

- Keep/extend headless Playwright validation runner:
  - must wait for wasm readiness,
  - must complete full run,
  - must fail on any mismatch/missing ref,
  - must assert mismatch UI preview persistence when mismatch count > 0.
- Add timeout/progress reporting and deterministic exit behavior.

### Slice 3 — Kind-by-Kind Algorithmic Parity (No Shortcuts)

- Complete compatibility in strict order:
  1. `0025`: text/clock/mode/evenness kinds
  2. `0026`: staff/fret/chord families
  3. `0027`: majmin families
- For each kind, do not proceed to next kind until all files for current kind are exact-match and represented in validation UI summary.

### Slice 4 — Closure and Regression Lock

- Add regression tests that sample known previously failing files across all kinds.
- Ensure strict mode test and Playwright run are both part of normal verification when references exist.
- Update completed plan histories with commit hashes and gate commands.

## Anti-Self-Deception Checklist (Run Before Declaring Success)

1. Can generated output still succeed if `tmp/harmoniousapp.net/**/*.svg` files are absent at runtime? (it must)
2. Does generation code avoid reading reference SVG file contents? (must be yes)
3. Is wasm artifact below 1 MB? (must be yes)
4. Does Playwright report `mismatches=0` and `missing_ref=0`? (must be yes)
5. If a mismatch is intentionally injected, does UI retain mismatch preview? (must be yes)
6. Are all filenames/arguments coming from API enumeration methods? (must be yes)

## Exit Criteria

- `./verify.sh` passes with all integrity guardrails.
- `zig build verify` passes.
- `zig-out/wasm-demo/libmusictheory.wasm` is `< 1 MB`.
- Playwright compatibility validation passes with `mismatches=0` and `missing_ref=0`.
- No generation code path embeds or reads reference SVG files.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs` (when `tmp/harmoniousapp.net/` exists)

## Implementation History (Point-in-Time)

_To be filled when this plan is completed._
