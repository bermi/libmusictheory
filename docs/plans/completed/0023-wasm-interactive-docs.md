# 0023 — WASM Interactive Documentation Demo

> Dependencies: 0020 (C ABI), 0022 (test/documentation validation)
> Blocks: None

## Objective

Create an interactive browser demo backed entirely by the WebAssembly build of `libmusictheory`, so users can exercise all exposed C ABI APIs and visualize SVG outputs produced by WASM.

## Constraints

- No music theory logic in JavaScript.
- No SVG/music rendering logic in JavaScript.
- JavaScript may only handle UI wiring, memory marshalling, and display of WASM return values.

## Implementation Steps

### 1. Build Target

- Add `zig build wasm-demo` to emit a browser-loadable `.wasm` artifact.
- Copy demo assets (`index.html`, `app.js`, `styles.css`) to a runnable output directory.

### 2. Demo UI

- Add `examples/wasm-demo/` app shell.
- Provide controls for all current C ABI functions:
  - Pitch class set operations
  - Set classification
  - Scale/mode/key spelling
  - Chord naming and roman numerals
  - Guitar mapping
  - SVG outputs (`clock`, `fret`, `staff`)

### 3. WASM Bridge

- Implement JS memory bridge for pointers/buffers/strings.
- Route every interactive operation through WASM exports.
- Keep all computed outputs sourced from WASM return values only.

### 4. Verification

- Update `verify.sh` gate for `0023` using `zig build wasm-demo`.
- Ensure `./verify.sh` and `zig build verify` still pass.

## Exit Criteria

- `zig build wasm-demo` succeeds
- `./verify.sh` passes
- Demo loads in browser and can invoke all ABI functions
- SVG previews are produced exclusively from WASM-returned SVG strings

## Implementation History (Point-in-Time)

- `b6a7e9e` (2026-02-16):
  - Shipped behavior: added `zig build wasm-demo` target, browser demo assets in `examples/wasm-demo/`, WASM-safe key-context helper exports, and `verify.sh` gate for interactive demo build (`0023`).
  - Verification: `./verify.sh` passes, `zig build verify` passes.
