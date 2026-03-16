# 0065 — Core SVG Render Quality Uplift

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
