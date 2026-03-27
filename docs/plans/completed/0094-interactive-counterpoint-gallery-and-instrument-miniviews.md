# 0094 — Interactive Counterpoint Gallery And Instrument Miniviews

> Dependencies: 0077, 0087, 0093
> Follow-up: none

Status: Completed

## Summary

Expose the counterpoint/voice-leading system in the standalone gallery with an above-the-fold interactive scene and optional linked instrument mini visualizations on every relevant gallery scene.

## Scope

### Live Counterpoint Scene

Add a gallery surface that shows:

- current voiced state
- recent temporal context
- ranked next moves with reasons
- linked harmonic/counterpoint views
- MIDI-driven updates where applicable
- progressive disclosure from local to global:
  - default view: current state + 3-5 best next moves
  - expanded view: wider motion field / graph neighborhood only on demand

### Optional Mini Instrument Visualization

All gallery scenes that present a selected note set or voiced state support an optional compact linked instrument pane.

Global setting:

- `mini instrument: off | piano | fret`

Requirements:

- mini views render the selected notes from the same underlying state as the main graph
- current-state and next-step suggestions both render through the chosen mini instrument where relevant
- fret notes use the same pitch-class color coding as clocks, keyboard, and other set graphics
- the mini view remains optional on scenes where it would add clutter

## Anti-Slop UX Constraints

- no giant unreadable dashboard
- always show `current` before `next`
- reasons remain visible near suggestions
- mini instrument panes clarify rather than decorate
- the same state stays legible from graph + instrument simultaneously
- default to the relevant local slice instead of the total graph

## Exit Criteria

- gallery exposes a counterpoint/voice-leading scene backed by library state/ranking
- gallery scenes support an optional `piano` or `fret` mini-view setting where relevant
- fret mini views and piano mini views share the same pitch-class palette logic
- verification proves both modes render and stay in sync with the main graph state
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`

## Implementation History (Point-in-Time)

- `5b0a7ef` — 2026-03-27
- Shipped behavior:
  - added the live counterpoint scene, profile selector, temporal history view, current-state plus ranked-next-step presentation, and global mini instrument mode in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`, `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`, and `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
  - rendered scene-linked piano/fret miniviews across the gallery, including current and next-step fret previews and a generic tuned-fret fallback for nonstandard selected sets, while keeping pitch-class color parity in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`, `/Users/bermi/code/libmusictheory/src/svg/fret.zig`, and `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`
  - tightened gallery verification for live MIDI counterpoint, preview-mode switching, and miniview coherence in `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`, `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`
  - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
