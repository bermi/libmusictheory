# 0061 — Parametric Fret Renderer And API

> Dependencies: 0012, 0016, 0020, 0050

Status: Completed

## Objective

Add a genuinely parameterized fret diagram surface that captures the fretboard concept instead of one hard-coded six-string guitar preset.

The existing `lmt_svg_fret` surface remains as a six-string compatibility wrapper. New `*_n` APIs expose:

- arbitrary string counts
- caller-provided tunings for fret/midi semantics
- caller-controlled visible fret windows for diagram layout

## Scope

Completed in this slice:

- generic Zig fret helper functions over slices
- generic fret SVG renderer over slices
- new C/WASM ABI:
  - `lmt_fret_to_midi_n`
  - `lmt_midi_to_fret_positions_n`
  - `lmt_svg_fret_n`
- wasm docs/demo updates so the interactive surface no longer implies six-string-only support

Out of scope:

- replacing six-string guitar-specific CAGED/voicing generation
- changing harmonious `eadgbe` compatibility behavior

## Constraints

- keep `lmt_fret_to_midi`, `lmt_midi_to_fret_positions`, and `lmt_svg_fret` working as six-string compatibility wrappers
- no allocations in core algorithms
- `./verify.sh` must gate the new API surface before implementation is declared complete
- docs must distinguish the compatibility wrapper from the parametric API

## Exit Criteria

- generic fret helpers accept arbitrary tuning/string counts through slice-based Zig APIs
- `lmt_svg_fret_n` renders diagrams for non-six-string inputs
- explicit fret-window control exists for the generic renderer
- full docs wasm exports include the new `*_n` API surface
- focused unit tests and C ABI tests cover non-six-string examples
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `zig build test`
- `node scripts/validate_wasm_docs_playwright.mjs`

## Implementation History (Point-in-Time)

- `168f321` — 2026-03-15
- Shipped behavior:
  - added generic fret helper functions in `/Users/bermi/code/libmusictheory/src/guitar.zig` for arbitrary tuning/string-count inputs
  - added generalized fret SVG rendering in `/Users/bermi/code/libmusictheory/src/svg/fret.zig` with explicit visible fret-window control
  - added public C/WASM symbols `lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, and `lmt_svg_fret_n`
  - preserved `lmt_fret_to_midi`, `lmt_midi_to_fret_positions`, and `lmt_svg_fret` as six-string compatibility wrappers
  - updated the wasm docs bundle to drive the new generic API surface and tightened the docs Playwright smoke to require it
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
