# 0089 — Live MIDI Context And Snapshot UX

> Dependencies: 0088
> Follow-up: none

Status: Completed

## Summary

Tune the `Live MIDI Compass` gallery scene so its theory reading is driven by an explicit selected tonic and mode instead of unstable auto-fit heuristics. The selected context must influence note spelling, set interpretation, suggestion ranking, and saved snapshots.

## Goals

- add explicit tonic and mode controls to the live MIDI scene
- make suggestion ranking and labels derive from the selected context
- make note spelling and summary text derive from the selected context
- save snapshot context together with the sounding notes
- recall snapshot context when a snapshot is selected
- prove with Playwright that changing tonic/mode changes the scene output

## Scope

- gallery UI controls and rendering logic in `examples/wasm-gallery/`
- fake-MIDI verification updates
- screenshot/reviewer docs updates
- `./verify.sh` guardrails for the new context-driven behavior

## Non-Goals

- C ABI changes
- audio/MIDI output
- DAW/plugin integration

## Exit Criteria

- live MIDI suggestions respond to selected tonic/mode
- snapshot recall restores both notes and context
- Playwright proves the scene changes when tonic/mode changes
- release screenshot capture still passes
- `./verify.sh` passes

## Implementation History (Point-in-Time)

- Commit: `TBD`
- Date: 2026-03-24
- Shipped behavior:
  - added explicit tonic and mode controls to `Live MIDI Compass`
  - made note spelling, set summary, orbit display, and next-step suggestion ranking derive from the selected context instead of auto-fit key guessing
  - saved tonic/mode alongside each snapshot and restored both context controls when a snapshot is recalled
  - extended gallery Playwright coverage so fake MIDI now proves tonic/mode changes alter the rendered scene and snapshot recall restores the saved context
  - updated standalone docs so the gallery and reviewer path describe the context-driven composer workflow
- Verification commands:
  - `node scripts/validate_wasm_gallery_playwright.mjs`
  - `node scripts/capture_wasm_gallery_screenshots.mjs`
  - `./verify.sh`
