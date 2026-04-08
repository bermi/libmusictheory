# 0128 - Gallery Overlays And Hand Outline Visualizations

Status: Completed

## Summary

Expose the playability engine visually in the standalone gallery and documentation surfaces.

This slice is presentation-driven, but it should remain strictly downstream of the underlying geometry and assessment layers. The gallery should visualize computed facts, not invent new playability heuristics in JS.

## Why

The value of this lane is not only for embeddings. The gallery should make the new reasoning legible:
- where the hand is
- which fingers are implicated
- what the current constraint is
- why a next step is easy or blocked

## Deliverables

1. Optional overlay system for fretboards and keyboard views
2. Overlay modes:
- `off`
- `basic`
- `detailed`
3. Visual elements:
- finger numbers
- current hand-position box
- pivot and shift arrows
- stretch heat or blocked span markers
- optional stylized hand outline anchors or wireframe
4. Next-step cards that show playability status and key reasons

## Recommended file work

Create or modify:
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`
- `/Users/bermi/code/libmusictheory/verify.sh`

Optional library helper work:
- `/Users/bermi/code/libmusictheory/src/playability/overlay.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_overlay_test.zig`

## Critical review guardrail

Do not ship decorative pseudo-realistic hands disconnected from the computed state. If we render hand outlines at all, they should be derived from anchor points and finger assignments returned by the library.

## Explainability check

A user should be able to see and say:
- "The red span marker shows the next chord exceeds the comfort window."
- "The shift arrow shows the hand must jump two positions to keep this line playable."

## Scope

M

## Verification gates

- Playwright coverage for overlay toggles and next-step statuses
- no JS-only playability facts
- `./verify.sh`

## Verification Commands

- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `0dcc8e4` - 2026-04-08
  - Shipped the gallery-side playability overlay system with global `off` / `basic` / `detailed` modes, keyboard and fret mini-preview overlays, reason and warning chips, hand-box and finger-marker rendering, and synchronized next-step playability rows in the live MIDI scene.
  - Tightened gallery validation and readiness logic so overlay SVGs do not pollute preview normalization checks, and fixed the live staff fallback path so the post-snapshot SVG readiness seam remains valid when the live note set is empty.
  - Completion gates: `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
