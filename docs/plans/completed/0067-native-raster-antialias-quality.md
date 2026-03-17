# 0067 — Native Raster Antialias Quality

Status: Completed

## Goal

Remove visibly jagged edges from the native RGBA validation surfaces by improving the Zig raster backends themselves rather than hiding the defect in the browser UI.

## Scope

- Add coverage-based antialiasing to the native proof/parity raster backend in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`.
- Apply the same edge-quality discipline to the shared demo raster backend in `/Users/bermi/code/libmusictheory/src/render/raster.zig`.
- Add focused tests that prove curved, diagonal, and polygon edges produce partial coverage instead of hard-threshold stair steps.
- Keep exact harmonious SVG parity unchanged.

## Non-Goals

- No browser-only smoothing workaround.
- No CSS scaling trick to mask jagged pixels.
- No change to byte-for-byte SVG compatibility output.

## Guardrails

- `./verify.sh` must fail if the coverage-based raster helpers disappear.
- `./verify.sh` must fail if the focused antialias tests disappear.
- Exact SVG parity, scaled render parity, and native RGBA proof must remain green.

## Exit Criteria

- Native RGBA proof samples render with coverage-based antialiasing for primitive and path edges.
- Focused tests prove partially covered edge pixels exist where expected.
- `./verify.sh` passes.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `zig build test`

## Implementation History (Point-in-Time)

- `<pending-finalization>` — 2026-03-17
- Shipped behavior:
  - added coverage-based edge antialiasing helpers in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig` so native proof/parity raster output no longer relies on hard-threshold circles, lines, and polygon fills
  - applied the same coverage-based edge treatment to `/Users/bermi/code/libmusictheory/src/render/raster.zig` so the shared raster demo path follows the same quality discipline
  - added focused edge-quality tests in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig` and `/Users/bermi/code/libmusictheory/src/tests/raster_test.zig`
  - tightened `/Users/bermi/code/libmusictheory/verify.sh` so the anti-aliased raster helpers and focused tests are mandatory
  - documented the raster-quality contract in `/Users/bermi/code/libmusictheory/docs/research/visualizations/render-quality.md` and `/Users/bermi/code/libmusictheory/examples/wasm-demo/README.md`
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `zig build test`
