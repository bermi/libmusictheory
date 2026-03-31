# 0098 — Orbifold Ribbon And Common-Tone Constellation

> Dependencies: 0097
> Follow-up: none

Status: Completed

## Summary

Extend the live counterpoint gallery with two linked visuals that make harmonic identity and retained voices legible over time:

- `Orbifold Ribbon`: place the current sonority and its strongest candidate continuations onto an orbifold-style harmonic map, with connectors that emphasize smooth vs distant voiced motion
- `Common-Tone Constellation`: show which voices remain fixed, which move, and how much of the texture is preserved across the current state, recent history, and hovered next-step candidates

## Why

`0095`, `0096`, and `0097` made motion, pressure, cadence, and suspension readable. The remaining missing intuition is:

- where the current voiced harmony sits in a broader harmonic geometry
- how much of the texture is truly changing versus staying fixed
- whether a suggested next move is smooth because of retained common tones, because of small displacement, or because it reclassifies the harmony while preserving anchors

These visuals should stay local and explanatory rather than turning into a dense global theory graph.

## Scope

### Orbifold Ribbon

Render a compact harmonic geometry view for the live counterpoint scene.

The ribbon should expose:

- current harmonic anchor
- several ranked next-step anchors
- connector emphasis driven by voice-leading cost and profile pressure
- local labels near anchors, not only in summary text
- compatibility with both SVG and bitmap preview modes

The first version may stay triad/tetrad-oriented as long as unsupported textures degrade gracefully and remain informative.

### Common-Tone Constellation

Render a retained-voice and moving-voice view for the same live scene.

The constellation should expose:

- retained common tones as stable stars/anchors
- moving tones as directional marks or vectors
- hovered-candidate changes in retained-vs-moving emphasis
- recent-history awareness so the view is not only current-chord static analysis

### Gallery Integration

Expose both visuals in the live MIDI counterpoint scene and keep them synchronized with:

- live MIDI updates
- counterpoint profile changes
- hovered next-step candidates
- snapshot recall
- global mini instrument mode
- global SVG / bitmap preview-mode toggle

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain explicit checks for the orbifold-ribbon and common-tone-constellation gallery hosts, runtime wiring, styles, and validation coverage
- gallery Playwright must assert that:
  - the orbifold ribbon renders at least one current anchor plus multiple candidate anchors
  - hovered next-step candidates change the highlighted target in the orbifold ribbon
  - the common-tone constellation renders both retained and moving structures when motion is present
  - both visuals remain coherent under SVG and bitmap preview modes and snapshot recall

## Exit Criteria

- the live counterpoint gallery renders `Orbifold Ribbon`
- the live counterpoint gallery renders `Common-Tone Constellation`
- both are driven by library-owned counterpoint/voice-leading data, not JS-only geometry hacks
- gallery validation proves they respond coherently to live MIDI, hover, profile changes, and snapshot recall
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`
- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`

## Implementation History (Point-in-Time)

- `f6db5c6d12607e614bc859878a44861ad6dc023a` — `2026-03-31T03:49:55+02:00`
  - shipped the experimental orbifold triad metadata ABI and gallery runtime needed for live orbifold anchors and common-tone constellation rendering
  - added live MIDI `Orbifold Ribbon` and `Common-Tone Constellation` cards, synchronized with ranked next-step hover, snapshot recall, and preview-mode toggles
  - hardened `./verify.sh` and gallery Playwright so the new visuals must expose anchors, edges, retained stars, and moving vectors under active live-state flows
  - verification gates: `./verify.sh`, `./zigw build test`, `./zigw build wasm-gallery`, `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
