# 0063 — Generic Fret Semantic C ABI And WASM Docs

> Dependencies: 0020, 0023, 0062

Status: Completed

## Objective

Expose the generic fret semantic model through the public C ABI and the wasm docs surface so arbitrary-string fret reasoning is usable outside Zig.

This slice covers:

- bounded generic voicing generation through the public ABI
- bounded generic pitch-class guide generation through the public ABI
- generic fret URL encode/decode through the public ABI
- wasm docs coverage proving the symbols are exported and callable from JavaScript

## Constraints

- no heap allocation in core algorithms
- caller-owned buffers only; no opaque handles
- keep existing six-string compatibility wrappers intact
- `./verify.sh` must gate the new ABI surface before the implementation is declared complete
- docs must demonstrate the generic ABI explicitly instead of implying six-string-only semantics

## Exit Criteria

- `include/libmusictheory.h` declares:
  - `lmt_guide_dot`
  - `lmt_generate_voicings_n`
  - `lmt_pitch_class_guide_n`
  - `lmt_frets_to_url_n`
  - `lmt_url_to_frets_n`
- `src/c_api.zig` exports those symbols with caller-owned buffer contracts
- full docs wasm exports include the new symbols
- wasm docs UI runs the new generic ABI methods successfully
- focused C ABI tests cover non-six-string voicing, guide, and URL round-trip behavior
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `zig build test`
- `node scripts/validate_wasm_docs_playwright.mjs`

## Implementation History (Point-in-Time)

- `217d462` — 2026-03-15
- Shipped behavior:
  - added public C/WASM ABI surface in `/Users/bermi/code/libmusictheory/include/libmusictheory.h` for generic fret voicing generation, pitch-class guide overlays, and fret URL encode/decode
  - exported `lmt_generate_voicings_n`, `lmt_pitch_class_guide_n`, `lmt_frets_to_url_n`, and `lmt_url_to_frets_n` from `/Users/bermi/code/libmusictheory/src/c_api.zig` using caller-owned buffers and no opaque handles
  - updated `/Users/bermi/code/libmusictheory/build.zig` and `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs` so the wasm docs bundle roots and verifies the new symbols explicitly
  - expanded `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig` with non-six-string ABI tests for voicing generation, guide overlays, and URL round-trips
  - updated `/Users/bermi/code/libmusictheory/examples/wasm-demo/app.js`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/index.html`, and `/Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_playwright.mjs` so the docs surface exercises the new generic ABI directly
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_wasm_docs_playwright.mjs`
