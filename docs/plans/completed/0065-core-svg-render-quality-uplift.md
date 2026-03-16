# 0065 — Core SVG Render Quality Uplift

Status: Completed

## Summary

Improve the visual quality of the core API SVG renderers used by the interactive docs. The exact harmonious compatibility lane already has high-fidelity outputs, but the generic API renderers remain visually crude and, in the staff case, semantically under-specified.

## Goals

- Make `lmt_svg_fret` and `lmt_svg_fret_n` render as deliberate vector diagrams rather than placeholder line art.
- Make `lmt_svg_chord_staff` use spelled-note placement and explicit accidental glyphs instead of semitone-only placement and literal text placeholders.
- Add renderer-quality guardrails so the docs surface cannot silently regress to the current low-grade styling.

## Scope

- `src/svg/fret.zig`
- `src/svg/staff.zig`
- `src/tests/svg_fret_test.zig`
- `src/tests/svg_staff_test.zig`
- `src/tests/c_api_test.zig`
- `verify.sh`

## Non-Goals

- No harmonious compatibility SVG parity changes.
- No public C ABI changes.
- No bundle/verification lane renaming.

## Exit Criteria

- Core fret diagrams use vector mute/open markers and explicit stroke styling.
- Core staff diagrams use spelled-note staff placement and vector accidental glyphs.
- Focused Zig tests cover the new renderer traits.
- `./verify.sh` passes.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `node scripts/validate_wasm_docs_playwright.mjs`

## Implementation History (Point-in-Time)

- `1b697e4` — 2026-03-16
- Shipped behavior:
  - upgraded `/Users/bermi/code/libmusictheory/src/svg/fret.zig` so the core fret API emits vector open/muted markers, rounded barre shapes, explicit SVG classes, and geometric precision rendering hints instead of text placeholders
  - rewrote `/Users/bermi/code/libmusictheory/src/svg/staff.zig` so the core staff API places notes from spelled letter+octave positions, emits vector accidental glyphs and key signatures, and renders explicit notehead/stem/ledger primitives rather than placeholder text accidentals
  - expanded `/Users/bermi/code/libmusictheory/src/tests/svg_fret_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/svg_staff_test.zig`, and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig` to guard the new renderer traits
  - tightened `/Users/bermi/code/libmusictheory/verify.sh` so the renderer-quality traits are programmatically checked
  - updated `/Users/bermi/code/libmusictheory/docs/research/visualizations/staff-notation.md`, `/Users/bermi/code/libmusictheory/docs/research/visualizations/fret-diagrams.md`, `/Users/bermi/code/libmusictheory/docs/architecture/graphs/staff.md`, and `/Users/bermi/code/libmusictheory/docs/architecture/graphs/fretboard.md` so the docs describe the upgraded core renderers accurately
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
  - `node scripts/validate_wasm_docs_playwright.mjs`
