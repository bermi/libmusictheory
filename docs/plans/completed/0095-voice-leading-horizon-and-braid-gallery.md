# 0095 — Voice-Leading Horizon And Braid Gallery

> Dependencies: 0094
> Follow-up: none

Status: Completed

## Summary

Extend the live counterpoint gallery with two linked visualizations that turn ranked next-step data into something composers can read at a glance:

- `Voice-Leading Horizon`: current voiced state plus the best next moves in a local motion field
- `Voice Braid`: recent voice history plus ghosted continuation strands for the strongest candidates

## Why

`0094` made the counterpoint engine available in the gallery, but the live scene still read mostly as text, chips, and independent diagrams. This slice adds a true counterpoint picture:

- current state first
- next options visibly related to the current state
- motion legible through time, not only as score/reason text

## Scope

- add a `Voice-Leading Horizon` visualization to the live MIDI scene
- add a `Voice Braid` visualization to the live MIDI scene
- derive both from the existing counterpoint ABI, not a second JS-only ranking policy
- keep them as local-slice views rather than giant totalizing graphs
- preserve existing mini instrument views and next-step cards

## Exit Criteria

- the live MIDI gallery scene renders a `Voice-Leading Horizon`
- the live MIDI gallery scene renders a `Voice Braid`
- both are fed by library-owned voiced history and ranked next-step data
- gallery validation proves they update coherently under live MIDI and profile changes
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`

## Implementation History (Point-in-Time)

- `331d97b` — 2026-03-27
- Shipped behavior:
  - added `Voice-Leading Horizon` and `Voice Braid` cards to the live MIDI gallery scene in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html` and `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
  - rendered current-state nodes, ranked candidate nodes, connectors, warning rings, history columns, ghost continuations, and reason tags from library-owned counterpoint state in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
  - tightened gallery validation and repo guardrails so horizon and braid structure must be present and remain coherent under live MIDI, context, and profile changes in `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`, `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build wasm-gallery`
  - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
