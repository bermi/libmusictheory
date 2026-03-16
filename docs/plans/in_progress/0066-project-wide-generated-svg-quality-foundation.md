# 0066 — Project-Wide Generated SVG Quality Foundation

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
