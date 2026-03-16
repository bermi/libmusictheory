# 0066 — Project-Wide Generated SVG Quality Foundation

Status: Completed

## Goal

Raise the visual quality of all non-compat generated SVG images through a shared quality prelude and shared typography/stroke conventions, while preserving exact harmonious compatibility output as a frozen contract.

## Scope

- Add a shared non-compat SVG quality module for:
  - canonical SVG prelude
  - geometric precision flags
  - shared font stacks
  - shared label/stroke helper classes
- Adopt that shared prelude across the core generated SVG families:
  - `clock`
  - `staff`
  - `fret`
  - `mode_icon`
  - `circle_of_fifths`
  - `evenness_chart` (non-compat chart)
  - `tessellation`
  - `orbifold`
  - `key_sig`
  - `n_tet_chart`
  - `text_misc`
- Keep exact harmonious compat renderers visually frozen.

## Non-Goals

- No change to byte-for-byte harmonious compatibility output.
- No change to the scaled render parity or native RGBA proof contracts.
- No font embedding or runtime asset loading.

## Guardrails

- `verify.sh` must fail if the shared quality module is not wired through the non-compat SVG modules.
- `verify.sh` must fail if the exact compat renderers are moved onto the shared quality prelude.
- Existing exact harmonious parity, scaled render parity, and native RGBA proof checks must remain green.

## Exit Criteria

- Shared quality module exists and is used across the non-compat SVG generators.
- Existing core SVG tests are expanded to assert the quality prelude is present where applicable.
- Documentation explicitly states:
  - exact compat output is frozen
  - non-compat generated SVGs share the upgraded quality layer
- `./verify.sh` passes.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `zig build wasm-demo`

## Implementation History (Point-in-Time)

- `44ef7f0` — 2026-03-16
- Shipped behavior:
  - added `/Users/bermi/code/libmusictheory/src/svg/quality.zig` as the shared non-compat SVG quality prelude for typography, outline, and geometric-precision styling
  - split exact harmonious clock, evenness, and text renderers into `/Users/bermi/code/libmusictheory/src/svg/clock_compat.zig`, `/Users/bermi/code/libmusictheory/src/svg/evenness_compat.zig`, and `/Users/bermi/code/libmusictheory/src/svg/text_misc_compat.zig` so the exact parity lane stays visually frozen
  - kept `/Users/bermi/code/libmusictheory/src/svg/clock.zig`, `/Users/bermi/code/libmusictheory/src/svg/evenness_chart.zig`, and `/Users/bermi/code/libmusictheory/src/svg/text_misc.zig` as the upgraded public/core generators, and wired the rest of the non-compat SVG families onto the shared quality prelude
  - updated `/Users/bermi/code/libmusictheory/src/harmonious_svg_compat.zig` and `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig` to depend on the new exact compat modules instead of the upgraded core renderers
  - added `enable_harmonious_generic_fallbacks` build gating in `/Users/bermi/code/libmusictheory/build.zig` so the minimal compat wasm bundles exclude generic fallback branches and stay below the installed validation bundle budget while the full library/docs builds keep the broader behavior
  - expanded `/Users/bermi/code/libmusictheory/verify.sh`, `/Users/bermi/code/libmusictheory/src/tests/svg_clock_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/svg_misc_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/render_ir_test.zig`, and `/Users/bermi/code/libmusictheory/src/tests/integration_test.zig` so the split is programmatically guarded
  - documented the contract split in `/Users/bermi/code/libmusictheory/docs/architecture/graphs.md`, `/Users/bermi/code/libmusictheory/examples/wasm-demo/README.md`, and `/Users/bermi/code/libmusictheory/docs/research/visualizations/render-quality.md`
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `zig build wasm-demo`
