# 0029 — Rendering IR and Dual-Backend Foundation (SVG + Raster)

> Dependencies: 0024 (compat foundation), 0028 (integrity guardrails)
> Blocks: 0030
> Does not block: 0026, 0027

## Objective

Introduce a deterministic rendering intermediate representation (IR) that decouples music-notation geometry/layout from output serialization.

Primary purpose:
- keep exact SVG parity as the authoritative compatibility target,
- enable a future raster backend for native/mobile/VST3 usage without duplicating layout logic.

## Non-Goals

- Do not replace byte-exact SVG verification with visual similarity.
- Do not relax `0028` guardrails (`wasm < 1MB`, anti-embed checks, API-driven generation).
- Do not change completion criteria for `0026` / `0027`.

## Research Phase

### 1. Output Contract Inventory

- Inventory all compatibility kinds and identify required scene primitives:
  - text/clock/mode/evenness kinds (`0025` complete),
  - staff/fret kinds (`0026`),
  - majmin tessellation kinds (`0027`).
- Document elements that must be preserved for parity:
  - deterministic node ordering,
  - precise numeric formatting,
  - group/id/class/link structure (`<g>`, `<a href>`, `vf-*` groups),
  - header/prolog/doctypes and whitespace behavior where required.

### 2. IR Capability Definition

- Define minimal but sufficient primitive set:
  - path, rect, circle/ellipse, line/polyline/polygon,
  - group containers and transform stacks,
  - style payload (fill/stroke/opacity/dash/join/cap),
  - metadata fields (id/class/custom attributes),
  - optional link wrappers for clickable regions.
- Specify deterministic emission rules independent of backend.

### 3. Build and Artifact Boundaries

- Define build-time boundaries so wasm compatibility artifacts remain lightweight:
  - raster backend excluded from `wasm-demo` compatibility build by default,
  - shared layout + SVG serializer retained in wasm path.

## Implementation Steps

### 1. Add Rendering IR Module

- Add a new module namespace (e.g., `src/render/`) containing:
  - IR node types,
  - deterministic append/order helpers,
  - bounded-memory writers compatible with existing buffer patterns.

### 2. Add SVG Serializer from IR

- Add serializer that converts IR to SVG bytes while preserving exact formatting controls needed by compatibility kinds.
- Provide configurable formatting modes:
  - strict compatibility mode (byte-sensitive),
  - normal mode (human-friendly) for non-compat outputs.

### 3. Migrate One Completed Kind as Pilot

- Migrate one already-passing kind (`optc` recommended) from direct string assembly to IR+serializer.
- Gate migration on zero byte-diff regressions in strict compatibility tests.

### 4. Migration Pattern for Remaining Kinds

- Define a per-kind migration checklist:
  - parser/args unchanged,
  - output byte-parity preserved,
  - Playwright and strict test results unchanged,
  - wasm size unchanged or reduced.

### 5. Verification Integration

- Add focused tests for IR determinism and serializer stability.
- Keep current compatibility checks unchanged as source-of-truth gates.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- Existing exact-match compatible kinds remain exact after IR integration.
- No change to parity authority: byte-exact checks remain required.
- `zig-out/wasm-demo/libmusictheory.wasm` remains `< 1MB`.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5` (when refs exist)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
