# 0088 — Live MIDI Composer Scene

> Dependencies: 0077, 0080, 0081, 0087
> Follow-up: none

Status: Completed

## Summary

Add a first-class interactive gallery scene that listens to all browser MIDI inputs, tracks sustained/sounding notes correctly, renders a live musical snapshot above the fold, and suggests compatible next note/chord directions using only the public `libmusictheory` surface plus browser MIDI.

The scene must remain additive:

- no Harmonious-specific tooling
- no compat/proof APIs
- no hidden reviewer-only logic
- real Web MIDI in the runtime
- fake MIDI injection only in Playwright verification

## Goals

- read note on/off from all connected MIDI inputs
- honor sustain pedal (`CC64`) for sounding-note state
- use middle pedal / sostenuto (`CC66`) to save a snapshot of the current sounding state
- let the user recall any saved snapshot by clicking it
- render the current state in a single, above-the-fold composer-facing scene
- show what the player is currently sounding and suggest compatible next steps
- keep the scene on stable public APIs only

## Scope

- a new gallery scene card placed above the fold
- live MIDI device attachment and state tracking in browser JS
- a public-API visual stack for the live scene:
  - clock view
  - note/chord naming
  - optional staff view when the current set maps cleanly to the public staff renderer
- compatible-next-step suggestions derived from public theory functions
- snapshot persistence for the current browser session
- Playwright verification with fake MIDI input and pedal events
- screenshot capture coverage for the new scene

## Non-Goals

- MIDI output
- DAW/plugin hosting
- audio rendering
- extending the stable C/WASM ABI unless a real blocker is discovered

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must enforce the new gallery scene, its fake-MIDI validation path, and screenshot capture presence
- Playwright must prove:
  - all-MIDI-input attachment works through a fake Web MIDI implementation
  - sustain changes sounding-note state correctly
  - middle pedal stores snapshots
  - clicking a snapshot recalls it into the scene
  - the live scene updates summary and imagery above the fold

## Exit Criteria

- the gallery has a verified live MIDI scene
- the scene uses only public APIs plus browser MIDI
- snapshots can be saved with middle pedal and recalled by click
- release smoke still passes
- screenshot capture includes the new live scene
- `./verify.sh` passes

## Implementation History (Point-in-Time)

- Commit: `1e0df85`
- Date: 2026-03-24
- Shipped behavior:
  - added a new above-the-fold `Live MIDI Compass` scene to the standalone gallery
  - connected the runtime to browser Web MIDI across all visible MIDI inputs
  - tracked note on/off state with sustain-pedal (`CC64`) support and middle-pedal (`CC66`) snapshot capture
  - persisted and recalled snapshots from the gallery UI without using Harmonious-specific surfaces
  - added fake-MIDI Playwright coverage plus screenshot capture for the live scene
- Verification commands:
  - `node scripts/validate_wasm_gallery_playwright.mjs`
  - `node scripts/capture_wasm_gallery_screenshots.mjs`
  - `./verify.sh`
