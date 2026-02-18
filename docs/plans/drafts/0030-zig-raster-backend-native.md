# 0030 — Zig Raster Backend for Native Targets (Optional Path)

> Dependencies: 0029 (rendering IR)
> Blocks: None
> Does not block: 0026, 0027

## Objective

Implement an optional pure-Zig raster backend that renders the shared IR to RGBA buffers for native/mobile/plugin environments.

This plan is additive:
- SVG exact parity remains the compatibility goal for harmoniousapp.net outputs.
- Raster output is a runtime capability for non-browser consumers.

## Non-Goals

- Do not route harmonious compatibility verification through bitmap similarity.
- Do not include heavy raster code paths in wasm compatibility build if they risk the `<1MB` limit.
- Do not duplicate layout logic outside the shared IR pipeline.

## Research Phase

### 1. Raster Requirements by Kind

- Quantify primitive and path complexity per failing visual families (`scale`, `chord*`, `grand-chord`, `eadgbe`, `majmin`).
- Define minimum feature support:
  - path fill/stroke with joins/caps/dashes,
  - transforms and clipping,
  - alpha compositing,
  - deterministic anti-aliasing behavior.

### 2. Numeric Stability and Determinism

- Decide deterministic raster rules:
  - fixed algorithm and epsilon policy for path flattening,
  - deterministic scanline ordering,
  - deterministic alpha rounding.
- Document behavior across target architectures (x86_64, arm64).

### 3. API and Memory Model

- Define C ABI and Zig APIs for raster output:
  - input: kind/index or explicit IR scene, output size/scale,
  - output: RGBA8 buffer + stride metadata,
  - memory ownership: caller-provided buffer where feasible.
- Ensure no allocations in core theory algorithms remain unaffected.

### 4. Build Partitioning

- Add build options to include/exclude raster backend by target:
  - enabled for native library builds,
  - disabled in wasm compatibility artifact by default.

## Implementation Steps

### 1. Add Raster Module

- Add `src/render/raster.zig` (and supporting files) for IR -> RGBA rendering.
- Implement deterministic path tessellation/scan conversion.

### 2. Add ABI Surface (Native-Focused)

- Add explicit native-friendly C exports for raster generation (separate from compatibility SVG exports).
- Keep compatibility SVG exports unchanged.

### 3. Add Raster Tests

- Add deterministic pixel-hash tests for representative scenes.
- Add cross-platform tolerances only where mathematically unavoidable and documented.

### 4. Integrate with Build

- Add build flags/options to keep wasm demo lean.
- Confirm compatibility wasm still satisfies size and export requirements.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- Raster backend renders deterministic RGBA output for representative scenes.
- Existing SVG compatibility results do not regress.
- `zig-out/wasm-demo/libmusictheory.wasm` remains `< 1MB`.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs` (when refs exist)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
